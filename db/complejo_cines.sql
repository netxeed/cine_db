-- ============================================================
-- Complejo de cines - Esquema SQLite
-- Ejecutar sobre una base vacia.
-- Convenciones: fechas 'YYYY-MM-DD', horas 'HH:MM', precios en pesos enteros.
-- Los nombres genericos (estado, numero, fecha, nombre, descripcion, tipo...) llevan
-- el sufijo de su entidad: estado_sala, fecha_funcion, nombre_genero, etc.
-- ============================================================
PRAGMA foreign_keys = ON;
BEGIN TRANSACTION;

-- ---------- Tablas ----------

CREATE TABLE Ubicaciones (
    ID_Ubicacion      INTEGER PRIMARY KEY AUTOINCREMENT,
    nombre_ubicacion  TEXT NOT NULL UNIQUE
);

CREATE TABLE Cines (
    ID_Cine         INTEGER PRIMARY KEY AUTOINCREMENT,
    nombre_cine     TEXT NOT NULL UNIQUE,
    correo          TEXT NOT NULL CHECK (correo LIKE '%_@_%._%'),
    telefono        TEXT NOT NULL,
    cantidad_salas  INTEGER NOT NULL DEFAULT 0 CHECK (cantidad_salas >= 0),
    ID_Ubicacion    INTEGER NOT NULL REFERENCES Ubicaciones(ID_Ubicacion)
);

CREATE TABLE Tipo_sala (
    ID_Tipo_sala  INTEGER PRIMARY KEY AUTOINCREMENT,
    tipo_sala     TEXT NOT NULL UNIQUE      -- 2D, 3D, IMAX, 4DX
);

CREATE TABLE Salas (
    ID_Sala       INTEGER PRIMARY KEY AUTOINCREMENT,
    estado_sala   INTEGER NOT NULL DEFAULT 1 CHECK (estado_sala IN (0, 1)),  -- 1 = activa, 0 = fuera de servicio
    numero_sala   INTEGER NOT NULL CHECK (numero_sala > 0),
    capacidad     INTEGER NOT NULL CHECK (capacidad > 0),
    ID_Cine       INTEGER NOT NULL REFERENCES Cines(ID_Cine),
    ID_Tipo_sala  INTEGER NOT NULL REFERENCES Tipo_sala(ID_Tipo_sala),
    UNIQUE (ID_Cine, numero_sala)
);

CREATE TABLE Clasificaciones (
    ID_Clasificacion           INTEGER PRIMARY KEY AUTOINCREMENT,
    edad_minima                INTEGER NOT NULL CHECK (edad_minima >= 0),
    nombre_clasificacion       TEXT NOT NULL UNIQUE,
    descripcion_clasificacion  TEXT
);

CREATE TABLE Peliculas (
    ID_Pelicula          INTEGER PRIMARY KEY AUTOINCREMENT,
    titulo               TEXT NOT NULL,
    sinopsis             TEXT,
    fecha_estreno        TEXT CHECK (date(fecha_estreno) IS fecha_estreno),
    fecha_carga_pelicula TEXT NOT NULL CHECK (date(fecha_carga_pelicula) IS fecha_carga_pelicula),
    duracion             INTEGER NOT NULL CHECK (duracion > 0),  -- minutos
    ID_Clasificacion     INTEGER NOT NULL REFERENCES Clasificaciones(ID_Clasificacion)
);

CREATE TABLE Generos (
    ID_Genero     INTEGER PRIMARY KEY AUTOINCREMENT,
    nombre_genero TEXT NOT NULL,
    ID_Pelicula   INTEGER NOT NULL REFERENCES Peliculas(ID_Pelicula),
    UNIQUE (nombre_genero, ID_Pelicula)
);

CREATE TABLE Idioma (
    ID_Idioma      INTEGER PRIMARY KEY AUTOINCREMENT,
    nombre_idioma  TEXT NOT NULL UNIQUE,
    codigo_iso     TEXT NOT NULL UNIQUE
);

CREATE TABLE Pelicula_idioma (
    ID_Pelicula_idioma  INTEGER PRIMARY KEY AUTOINCREMENT,
    ID_Pelicula         INTEGER NOT NULL REFERENCES Peliculas(ID_Pelicula),
    ID_Idioma           INTEGER NOT NULL REFERENCES Idioma(ID_Idioma),
    UNIQUE (ID_Pelicula, ID_Idioma)
);

CREATE TABLE Programaciones (
    ID_Programacion          INTEGER PRIMARY KEY AUTOINCREMENT,
    fecha_inicio             TEXT NOT NULL CHECK (date(fecha_inicio) IS fecha_inicio),
    fecha_fin                TEXT NOT NULL CHECK (date(fecha_fin) IS fecha_fin),
    fecha_carga_programacion TEXT NOT NULL CHECK (date(fecha_carga_programacion) IS fecha_carga_programacion),
    CHECK (fecha_inicio <= fecha_fin)
);

CREATE TABLE Tipo_funcion (
    ID_Tipo_funcion           INTEGER PRIMARY KEY AUTOINCREMENT,
    nombre_tipo_funcion       TEXT NOT NULL UNIQUE,
    descripcion_tipo_funcion  TEXT
);

CREATE TABLE Funciones (
    ID_Funcion       INTEGER PRIMARY KEY AUTOINCREMENT,
    estado_funcion   INTEGER NOT NULL DEFAULT 0 CHECK (estado_funcion IN (0, 1, 2)),  -- 0 = deshabilitada, 1 = habilitada, 2 = cancelada
    fecha_funcion    TEXT NOT NULL CHECK (date(fecha_funcion) IS fecha_funcion),
    hora_inicio      TEXT NOT NULL CHECK (hora_inicio GLOB '[0-2][0-9]:[0-5][0-9]'),
    hora_fin         TEXT NOT NULL CHECK (hora_fin    GLOB '[0-2][0-9]:[0-5][0-9]'),
    ID_Sala          INTEGER NOT NULL REFERENCES Salas(ID_Sala),
    ID_Programacion  INTEGER NOT NULL REFERENCES Programaciones(ID_Programacion),
    ID_Tipo_funcion  INTEGER NOT NULL REFERENCES Tipo_funcion(ID_Tipo_funcion),
    ID_Pelicula      INTEGER NOT NULL REFERENCES Peliculas(ID_Pelicula),
    UNIQUE (ID_Sala, fecha_funcion, hora_inicio)
);

CREATE TABLE Tipo_entrada (
    ID_Tipo_entrada           INTEGER PRIMARY KEY AUTOINCREMENT,
    nombre_tipo_entrada       TEXT NOT NULL UNIQUE,
    descripcion_tipo_entrada  TEXT
);

-- Tipos de entrada que admite cada clasificacion (N:M)
CREATE TABLE Clasificaciones_tipo_entrada (
    ID_Clasificacion_tipo_entrada  INTEGER PRIMARY KEY AUTOINCREMENT,
    ID_Clasificacion               INTEGER NOT NULL REFERENCES Clasificaciones(ID_Clasificacion),
    ID_Tipo_entrada                INTEGER NOT NULL REFERENCES Tipo_entrada(ID_Tipo_entrada),
    UNIQUE (ID_Clasificacion, ID_Tipo_entrada)
);

CREATE TABLE Dia_semana (
    ID_Dia_semana  INTEGER PRIMARY KEY AUTOINCREMENT,
    dia_semana     TEXT NOT NULL UNIQUE
);

CREATE TABLE Tarifas (
    ID_Tarifa        INTEGER PRIMARY KEY AUTOINCREMENT,
    hora_desde       TEXT NOT NULL CHECK (hora_desde GLOB '[0-2][0-9]:[0-5][0-9]'),
    hora_hasta       TEXT NOT NULL CHECK (hora_hasta GLOB '[0-2][0-9]:[0-5][0-9]'),
    precio           INTEGER NOT NULL CHECK (precio >= 0),
    ID_Dia_semana    INTEGER NOT NULL REFERENCES Dia_semana(ID_Dia_semana),
    ID_Cine          INTEGER NOT NULL REFERENCES Cines(ID_Cine),
    ID_Tipo_entrada  INTEGER NOT NULL REFERENCES Tipo_entrada(ID_Tipo_entrada),
    CHECK (hora_desde < hora_hasta),
    UNIQUE (ID_Cine, ID_Tipo_entrada, ID_Dia_semana, hora_desde)
);

-- ---------- Usuarios y roles (login de la pagina) ----------

CREATE TABLE Roles (
    ID_Rol           INTEGER PRIMARY KEY AUTOINCREMENT,
    nombre_rol       TEXT NOT NULL UNIQUE,
    descripcion_rol  TEXT
);

CREATE TABLE Usuarios (
    ID_Usuario      INTEGER PRIMARY KEY AUTOINCREMENT,
    nombre_usuario  TEXT NOT NULL CHECK (length(nombre_usuario) >= 3),   -- nombre y apellido pueden repetirse
    correo_usuario  TEXT NOT NULL UNIQUE COLLATE NOCASE CHECK (correo_usuario LIKE '%_@_%._%'),
    password_hash   TEXT NOT NULL,   -- generado con password_hash() de PHP, nunca la contrasena en texto
    estado_usuario  INTEGER NOT NULL DEFAULT 1 CHECK (estado_usuario IN (0, 1)),  -- 1 = activo, 0 = inactivo
    fecha_registro  TEXT NOT NULL DEFAULT (date('now')) CHECK (date(fecha_registro) IS fecha_registro),
    ID_Rol          INTEGER NOT NULL REFERENCES Roles(ID_Rol)
);

-- Comprobante de venta: ID_Entrada cumple el rol de "nro. de venta".
-- La distribucion de butacas se calcula en la aplicacion (PHP) a partir de Salas.capacidad;
-- la ocupacion se guarda aqui (fila + numero_butaca).
CREATE TABLE Entradas (
    ID_Entrada       INTEGER PRIMARY KEY AUTOINCREMENT,
    fecha_venta      TEXT NOT NULL CHECK (date(fecha_venta) IS fecha_venta),
    precio_cobrado   INTEGER NOT NULL CHECK (precio_cobrado >= 0),
    estado_entrada   INTEGER NOT NULL DEFAULT 1 CHECK (estado_entrada IN (0, 1)),  -- 1 = vendida, 0 = anulada
    fila             TEXT NOT NULL CHECK (fila GLOB '[A-Z]'),
    numero_butaca    INTEGER NOT NULL CHECK (numero_butaca > 0),
    ID_Funcion       INTEGER NOT NULL REFERENCES Funciones(ID_Funcion),
    ID_Tipo_entrada  INTEGER NOT NULL REFERENCES Tipo_entrada(ID_Tipo_entrada),
    ID_Usuario       INTEGER NOT NULL REFERENCES Usuarios(ID_Usuario)
);

-- Una butaca solo puede estar vendida una vez por funcion: el primero en comprar se la queda
CREATE UNIQUE INDEX ux_entrada_butaca
    ON Entradas (ID_Funcion, fila, numero_butaca) WHERE estado_entrada = 1;

-- ---------- Datos de prueba ----------

INSERT INTO Ubicaciones (nombre_ubicacion) VALUES ('Shopping Centro'), ('Shopping Norte');

INSERT INTO Cines (nombre_cine, correo, telefono, cantidad_salas, ID_Ubicacion) VALUES
    ('Cine Centro', 'centro@cines.com', '+54 11 4000-0001', 2, 1),
    ('Cine Norte',  'norte@cines.com',  '+54 11 4000-0002', 2, 2);

INSERT INTO Tipo_sala (tipo_sala) VALUES ('2D'), ('3D'), ('IMAX'), ('4DX');

INSERT INTO Salas (estado_sala, numero_sala, capacidad, ID_Cine, ID_Tipo_sala) VALUES
    (1, 1, 120, 1, 1), (1, 2,  80, 1, 2),
    (1, 1, 200, 2, 3), (1, 2,  60, 2, 4);

INSERT INTO Clasificaciones (edad_minima, nombre_clasificacion, descripcion_clasificacion) VALUES
    (0,  'ATP',  'Apta para todo publico'),
    (13, '+13',  'Mayores de 13 anios'),
    (16, '+16',  'Mayores de 16 anios'),
    (18, '+18',  'Mayores de 18 anios');

INSERT INTO Peliculas (titulo, sinopsis, fecha_carga_pelicula, duracion, ID_Clasificacion) VALUES
    ('Aventura en el Sur', 'Una familia recorre la Patagonia.',     '2026-11-10', 130, 1),
    ('La Noche Larga',     'Un thriller policial en Buenos Aires.', '2026-11-10', 120, 3),
    ('Historias Ocultas',  'Drama para adultos sobre secretos.',    '2026-11-12', 135, 4);

INSERT INTO Generos (nombre_genero, ID_Pelicula) VALUES
    ('Aventura', 1), ('Familiar', 1), ('Thriller', 2), ('Drama', 3);

INSERT INTO Idioma (nombre_idioma, codigo_iso) VALUES ('Espanol', 'es'), ('Ingles', 'en');
INSERT INTO Pelicula_idioma (ID_Pelicula, ID_Idioma) VALUES (1, 1), (2, 1), (3, 1), (3, 2);

INSERT INTO Tipo_entrada (nombre_tipo_entrada, descripcion_tipo_entrada) VALUES
    ('Mayor', 'Entrada general'), ('Menor', 'Menores de edad'), ('Jubilado', 'Jubilados y pensionados');

-- Tipos de entrada permitidos por clasificacion (+16 y +18 no admiten Menor)
INSERT INTO Clasificaciones_tipo_entrada (ID_Clasificacion, ID_Tipo_entrada) VALUES
    (1, 1), (1, 2), (1, 3),
    (2, 1), (2, 2), (2, 3),
    (3, 1), (3, 3),
    (4, 1), (4, 3);

INSERT INTO Dia_semana (dia_semana) VALUES
    ('Lunes'), ('Martes'), ('Miercoles'), ('Jueves'), ('Viernes'), ('Sabado'), ('Domingo');

-- Tarifa simple: una franja por dia, mas cara el fin de semana y distinta por cine
INSERT INTO Tarifas (hora_desde, hora_hasta, precio, ID_Dia_semana, ID_Cine, ID_Tipo_entrada)
SELECT '00:00', '23:59',
       CASE te.nombre_tipo_entrada WHEN 'Mayor' THEN 6000 WHEN 'Menor' THEN 4500 ELSE 4000 END
       + CASE WHEN d.dia_semana IN ('Sabado', 'Domingo') THEN 1000 ELSE 0 END
       + CASE WHEN c.ID_Cine = 2 THEN 500 ELSE 0 END,
       d.ID_Dia_semana, c.ID_Cine, te.ID_Tipo_entrada
FROM Cines c CROSS JOIN Tipo_entrada te CROSS JOIN Dia_semana d;

INSERT INTO Programaciones (fecha_inicio, fecha_fin, fecha_carga_programacion) VALUES ('2026-11-19', '2026-11-25', '2026-11-16');

INSERT INTO Tipo_funcion (nombre_tipo_funcion, descripcion_tipo_funcion) VALUES
    ('Preestreno', 'Funcion previa al estreno'), ('Estreno', 'Primera semana en cartelera'), ('Normal', 'Funcion regular');

INSERT INTO Funciones (estado_funcion, fecha_funcion, hora_inicio, hora_fin, ID_Sala, ID_Programacion, ID_Tipo_funcion, ID_Pelicula) VALUES
    (1, '2026-11-19', '18:00', '20:10', 1, 1, 2, 1),
    (1, '2026-11-19', '21:00', '23:00', 2, 1, 2, 2),
    (0, '2026-11-20', '20:00', '22:15', 3, 1, 1, 3),
    (1, '2026-11-21', '16:00', '18:10', 4, 1, 3, 1);

INSERT INTO Roles (nombre_rol, descripcion_rol) VALUES
    ('admin',   'Responsable de programacion: disena y habilita funciones'),
    ('usuario', 'Cliente: consulta la cartelera y compra entradas');

-- Usuarios de demostracion bloqueados: el hash '*' no coincide con ninguna contrasena,
-- asi que nadie puede iniciar sesion con ellos. Las cuentas reales se crean en la base
-- local (el administrador con su contrasena propia) y nunca se suben al repositorio.
INSERT INTO Usuarios (nombre_usuario, correo_usuario, password_hash, ID_Rol) VALUES
    ('admin',    'admin@cines.com',     '*', 1),
    ('cliente1', 'cliente1@correo.com', '*', 2);

INSERT INTO Entradas (fecha_venta, precio_cobrado, estado_entrada, fila, numero_butaca, ID_Funcion, ID_Tipo_entrada, ID_Usuario) VALUES
    ('2026-11-19', 6000, 1, 'A', 1, 1, 1, 2),
    ('2026-11-19', 4500, 1, 'A', 2, 1, 2, 2),
    ('2026-11-19', 4000, 1, 'B', 5, 2, 3, 2),
    ('2026-11-21', 7500, 1, 'C', 3, 4, 1, 2);

COMMIT;
