Paquexpress App 📦

Aplicación móvil desarrollada en Flutter con backend en FastAPI (Python) y base de datos MySQL, diseñada para la gestión logística de entregas de última milla.

Permite a los agentes visualizar sus paquetes asignados, ver la ubicación en el mapa y confirmar la entrega mediante evidencia fotográfica y coordenadas GPS.

Tecnologías Utilizadas

Frontend: Flutter (Dart), Flutter Map (OpenStreetMap), Geolocator, Image Picker.

Backend: Python, FastAPI, Uvicorn, SQLAlchemy.

Base de Datos: MySQL.

Seguridad: Encriptación de contraseñas con Passlib (Bcrypt).

Instrucciones de Instalación

Sigue estos pasos para ejecutar el proyecto en tu entorno local.

1. Configuración de Base de Datos

Asegúrate de tener MySQL instalado y corriendo (XAMPP/WAMP o servicio nativo).

Ejecuta el script database_script.sql en tu gestor de base de datos para crear la estructura.

Verifica que las credenciales en main.py coincidan con las tuyas:

SQLALCHEMY_DATABASE_URL = "mysql+pymysql://root:root@localhost/paquexpress_db"


2. Ejecutar el Backend (API)

Desde la terminal, navega a la carpeta del backend:

# 1. Instalar dependencias
pip install fastapi uvicorn sqlalchemy pymysql python-multipart aiofiles passlib[bcrypt] pydantic

# 2. Iniciar el servidor
python main.py
# O alternativamente: uvicorn main:app --reload --host 0.0.0.0 --port 8000


La API estará disponible en http://localhost:8000

3. Ejecutar la App Móvil (Flutter)

Desde la terminal, navega a la carpeta del proyecto Flutter:

# 1. Descargar librerías
flutter pub get

# 2. Ejecutar la aplicación
flutter run


📱 Guía de Uso

Crear Usuario (Primer Uso):

Como la base de datos inicia vacía, debes crear un agente.

Usa una herramienta como Postman o el Swagger de la API (http://localhost:8000/docs) y haz una petición POST a /admin/create_user/ con:

{ "username": "agente1", "password": "123" }


Asignar Paquetes:

Usa el endpoint POST /admin/assign_package/1 para crear paquetes de prueba.

Iniciar Sesión en la App:

Usa las credenciales creadas (agente1 / 123).

Verás la lista de paquetes pendientes.

Confirmar Entrega:

Selecciona un paquete.

Verifica tu ubicación en el mapa.

Toma una foto de evidencia y presiona "Confirmar Entrega".

⚠️ Notas Importantes para Pruebas

Emulador Android: La app está configurada para conectarse a http://10.0.2.2:8000 automáticamente.

Web / iOS: La app se conecta a http://127.0.0.1:8000.

Si pruebas en un dispositivo físico, debes cambiar la IP en el código de Flutter por la IP local de tu computadora (ej. 192.168.1.X).

Desarrollado por: [Tu Nombre]
Materia: Desarrollo de Aplicaciones Móviles