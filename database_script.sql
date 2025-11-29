-- 1. Crear la base de datos si no existe
CREATE DATABASE IF NOT EXISTS paquexpress_db;
USE paquexpress_db;

-- 2. Tabla de Usuarios (Agentes)
CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL
);

-- 3. Tabla de Paquetes
CREATE TABLE IF NOT EXISTS packages (
    id INT AUTO_INCREMENT PRIMARY KEY,
    tracking_code VARCHAR(50) NOT NULL UNIQUE,
    address VARCHAR(255) NOT NULL,
    description VARCHAR(255),
    
    -- Campos de Evidencia de Entrega
    is_delivered BOOLEAN DEFAULT FALSE,
    delivery_latitude FLOAT NULL,
    delivery_longitude FLOAT NULL,
    photo_path VARCHAR(255) NULL,
    delivery_time DATETIME NULL,

    -- Relación con Agente
    agent_id INT,
    CONSTRAINT fk_agent
        FOREIGN KEY (agent_id) 
        REFERENCES users(id)
        ON DELETE SET NULL
        ON UPDATE CASCADE
);

-- ==========================================
-- DATOS DE PRUEBA (Opcional)
-- ==========================================

-- Nota: Las contraseñas en 'users' deben estar hasheadas con Bcrypt.
-- Se recomienda crear usuarios usando la API (POST /admin/create_user/)
-- para asegurar que el login funcione correctamente.

-- Ejemplo de inserción manual solo si conoces el hash:
-- INSERT INTO users (username, password_hash) VALUES ('agente1', '$2b$12$...');

-- Paquete de ejemplo (se asignará al usuario con ID 1 una vez creado)
INSERT INTO packages (tracking_code, address, description, agent_id, is_delivered) 
VALUES 
('MX-8892', 'Av. Universidad 120, Centro', 'Caja frágil', 1, 0),
('MX-9921', 'Calle 5 de Mayo #45', 'Documentos urgentes', 1, 0);