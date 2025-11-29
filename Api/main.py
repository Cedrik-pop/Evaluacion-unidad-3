# Importaciones solicitadas
import os
import shutil
import aiofiles
import uvicorn
from datetime import datetime
from typing import List, Optional

# FastAPI y Pydantic
from fastapi import FastAPI, Depends, HTTPException, status, UploadFile, File, Form
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from pydantic import BaseModel

# Base de datos (SQLAlchemy + PyMySQL)
from sqlalchemy import create_engine, Column, Integer, String, Float, DateTime, ForeignKey, Boolean
from sqlalchemy.orm import sessionmaker, relationship, Session, declarative_base

# Seguridad (Passlib para cumplir requerimiento de encriptación)
from passlib.context import CryptContext

# ==========================================
# 1. CONFIGURACIÓN E INFRAESTRUCTURA
# ==========================================

# Configuración de Base de Datos MySQL
SQLALCHEMY_DATABASE_URL = "mysql+pymysql://root:@localhost/paquexpress_db"

engine = create_engine(SQLALCHEMY_DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

# Configuración de Directorio de Imágenes
UPLOAD_DIR = "uploads"
if not os.path.exists(UPLOAD_DIR):
    os.makedirs(UPLOAD_DIR)

# Configuración de Seguridad (Hashing de contraseñas)
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

# Instancia de la APP
app = FastAPI(title="Paquexpress API")

# Habilitar CORS para que Flutter pueda conectarse sin problemas
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Servir archivos estáticos (para ver las fotos subidas)
app.mount("/static", StaticFiles(directory="uploads"), name="static")

# ==========================================
# 2. MODELOS DE BASE DE DATOS (ORM)
# ==========================================

class User(Base):
    __tablename__ = "users"
    id = Column(Integer, primary_key=True, index=True)
    username = Column(String(50), unique=True, index=True)
    password_hash = Column(String(255))
    
    # Relación: Un agente tiene muchos paquetes
    packages = relationship("Package", back_populates="agent")

class Package(Base):
    __tablename__ = "packages"

    id = Column(Integer, primary_key=True, index=True)
    # [cite_start]ID único del paquete [cite: 6]
    tracking_code = Column(String(50), unique=True, index=True) 
    # [cite_start]Dirección de destino [cite: 6]
    address = Column(String(255)) 
    description = Column(String(255))
    
    # --- Campos para la evidencia de entrega ---
    is_delivered = Column(Boolean, default=False)
    # [cite_start]Ubicación GPS (Latitud) [cite: 8]
    delivery_latitude = Column(Float, nullable=True) 
    # [cite_start]Ubicación GPS (Longitud) [cite: 8]
    delivery_longitude = Column(Float, nullable=True) 
    # [cite_start]Ruta de la fotografía de evidencia [cite: 7]
    photo_path = Column(String(255), nullable=True) 
    delivery_time = Column(DateTime, nullable=True)

    # Relación con la tabla Users
    agent_id = Column(Integer, ForeignKey("users.id"))
    agent = relationship("User", back_populates="packages")

# ==========================================
# 3. ESQUEMAS PYDANTIC (Validación de datos)
# ==========================================

# Login
class UserLogin(BaseModel):
    username: str
    password: str

# Salida de datos del Paquete
class PackageOut(BaseModel):
    id: int
    tracking_code: str
    address: str
    description: str
    is_delivered: bool
    delivery_latitude: Optional[float] = None
    delivery_longitude: Optional[float] = None
    photo_path: Optional[str] = None
    
    class Config:
        from_attributes = True

# Creación de datos (para pruebas/semillas)
class UserCreate(BaseModel):
    username: str
    password: str

class PackageCreate(BaseModel):
    tracking_code: str
    address: str
    description: str

# ==========================================
# 4. FUNCIONES DE UTILIDAD
# ==========================================

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

def verify_password(plain_password, hashed_password):
    return pwd_context.verify(plain_password, hashed_password)

def get_password_hash(password):
    return pwd_context.hash(password)

# Crear tablas al iniciar si no existen
Base.metadata.create_all(bind=engine)

# ==========================================
# 5. ENDPOINTS (Rutas de la API)
# ==========================================

# [cite_start]--- A. Inicio de Sesión Seguro [cite: 12] ---
@app.post("/login/")
def login(user: UserLogin, db: Session = Depends(get_db)):
    db_user = db.query(User).filter(User.username == user.username).first()
    if not db_user or not verify_password(user.password, db_user.password_hash):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED, 
            detail="Credenciales incorrectas"
        )
    return {
        "message": "Login exitoso", 
        "user_id": db_user.id, 
        "username": db_user.username
    }

# [cite_start]--- B. Listar Paquetes Asignados (Pendientes) [cite: 6] ---
@app.get("/packages/{user_id}", response_model=List[PackageOut])
def get_pending_packages(user_id: int, db: Session = Depends(get_db)):
    packages = db.query(Package).filter(
        Package.agent_id == user_id,
        Package.is_delivered == False  # Solo mostrar los no entregados
    ).all()
    return packages

# [cite_start]--- C. Registrar Entrega (GPS + Foto) [cite: 7, 8, 9] ---
@app.post("/deliver/{package_id}")
async def deliver_package(
    package_id: int,
    latitude: float = Form(...),   # Recibir latitud
    longitude: float = Form(...),  # Recibir longitud
    file: UploadFile = File(...),  # Recibir archivo de foto
    db: Session = Depends(get_db)
):
    # 1. Verificar que el paquete existe
    package = db.query(Package).filter(Package.id == package_id).first()
    if not package:
        raise HTTPException(status_code=404, detail="Paquete no encontrado")

    # 2. Generar nombre único para la imagen
    file_extension = file.filename.split(".")[-1]
    filename = f"pkg_{package_id}_{datetime.now().strftime('%Y%m%d%H%M%S')}.{file_extension}"
    file_path = os.path.join(UPLOAD_DIR, filename)

    # 3. Guardar imagen usando aiofiles (asíncrono)
    async with aiofiles.open(file_path, 'wb') as out_file:
        content = await file.read()
        await out_file.write(content)

    # [cite_start]4. Actualizar Base de Datos [cite: 9]
    package.is_delivered = True
    package.delivery_latitude = latitude
    package.delivery_longitude = longitude
    package.photo_path = file_path
    package.delivery_time = datetime.now()
    
    db.commit()
    
    return {
        "status": "success",
        "message": "Paquete entregado correctamente",
        "evidence_url": f"/static/{filename}"
    }

# --- D. Endpoints Auxiliares (Para crear datos de prueba) ---

@app.post("/admin/create_user/")
def create_test_user(user: UserCreate, db: Session = Depends(get_db)):
    hashed_pw = get_password_hash(user.password)
    new_user = User(username=user.username, password_hash=hashed_pw)
    try:
        db.add(new_user)
        db.commit()
        return {"id": new_user.id, "username": new_user.username}
    except Exception as e:
        raise HTTPException(status_code=400, detail="Usuario ya existe")

@app.post("/admin/assign_package/{user_id}")
def assign_test_package(user_id: int, pkg: PackageCreate, db: Session = Depends(get_db)):
    new_pkg = Package(**pkg.dict(), agent_id=user_id)
    db.add(new_pkg)
    db.commit()
    return {"message": "Paquete asignado para entrega"}

# Para ejecutar: uvicorn main:app --reload --host 0.0.0.0 --port 8000
if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)