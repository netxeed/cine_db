-- ============================================================
-- Consultas del complejo de cines (SQLite)
-- Base: consultas.txt del equipo, corregidas contra el esquema actual (con triggers.sql cargado)
-- y completadas con las que necesita la pagina (13 a 21).
--
-- Como usarlas:
--  * Cada consulta lleva valores de EJEMPLO para poder ejecutarla tal cual en DB Browser.
--  * El comentario /*:nombre*/ junto a un valor indica el PARAMETRO que la aplicacion debe
--    reemplazar. En PHP:  WHERE ID_Funcion = :id_funcion   y   $stmt->execute([':id_funcion' => $id]);
--    (siempre consultas preparadas, nunca pegar valores del usuario dentro del texto SQL).
--  * 'hoy' es la fecha actual en formato AAAA-MM-DD (en PHP: date('Y-m-d')).
--  * Orden pensado para ejecutar el archivo completo de arriba hacia abajo sobre los datos de prueba.
--  * Las escrituras (5, 5b, 6, 7, 8, 8b, 21) fallan con un mensaje claro si violan una regla (triggers.sql);
--    en PHP el mensaje llega como excepcion de PDO.
-- ============================================================
PRAGMA foreign_keys = ON;

-- ------------------------------------------------------------
-- 1) Peliculas con clasificacion, generos e idiomas (listado completo)
-- Pantalla: listado general / administracion.
-- ------------------------------------------------------------
SELECT
    p.ID_Pelicula,
    p.titulo,
    p.duracion,
    p.fecha_estreno,
    c.nombre_clasificacion AS clasificacion,
    GROUP_CONCAT(DISTINCT g.nombre_genero) AS generos,
    GROUP_CONCAT(DISTINCT i.nombre_idioma) AS idiomas,
    p.sinopsis
FROM Peliculas p
INNER JOIN Clasificaciones c ON p.ID_Clasificacion = c.ID_Clasificacion
LEFT JOIN Generos g ON p.ID_Pelicula = g.ID_Pelicula
LEFT JOIN Pelicula_idioma pi ON p.ID_Pelicula = pi.ID_Pelicula
LEFT JOIN Idioma i ON pi.ID_Idioma = i.ID_Idioma
GROUP BY p.ID_Pelicula
ORDER BY p.titulo;

-- ------------------------------------------------------------
-- 2) Funciones habilitadas desde hoy, con cine, ubicacion, sala y formato
-- Pantalla: cartelera / elegir funcion. Solo funciones habilitadas (estado_funcion = 1) que todavia no pasaron.
-- ------------------------------------------------------------
SELECT
    f.ID_Funcion,
    p.titulo AS pelicula,
    ci.nombre_cine AS cine,
    u.nombre_ubicacion AS ubicacion,
    s.numero_sala AS sala,
    ts.tipo_sala AS formato,
    tf.nombre_tipo_funcion AS tipo_funcion,
    f.fecha_funcion,
    f.hora_inicio,
    f.hora_fin
FROM Funciones f
INNER JOIN Peliculas p ON f.ID_Pelicula = p.ID_Pelicula
INNER JOIN Salas s ON f.ID_Sala = s.ID_Sala
INNER JOIN Tipo_sala ts ON s.ID_Tipo_sala = ts.ID_Tipo_sala
INNER JOIN Cines ci ON s.ID_Cine = ci.ID_Cine
INNER JOIN Ubicaciones u ON ci.ID_Ubicacion = u.ID_Ubicacion
INNER JOIN Tipo_funcion tf ON f.ID_Tipo_funcion = tf.ID_Tipo_funcion
WHERE f.estado_funcion = 1
  AND f.fecha_funcion >= '2026-11-19' /*:hoy*/
ORDER BY f.fecha_funcion, f.hora_inicio;

-- ------------------------------------------------------------
-- 3) Butacas ocupadas de una funcion
-- Pantalla: mapa de butacas. PHP arma la sala (10 por fila) y marca estas como ocupadas.
-- ------------------------------------------------------------
SELECT fila, numero_butaca
FROM Entradas
WHERE ID_Funcion = 1 /*:id_funcion*/ AND estado_entrada = 1
ORDER BY fila, numero_butaca;

-- ------------------------------------------------------------
-- 4) Tarifas por cine, dia de la semana y tipo de entrada
-- Pantalla: precios / administracion.
-- ------------------------------------------------------------
SELECT
    ci.nombre_cine,
    d.dia_semana,
    te.nombre_tipo_entrada,
    t.hora_desde,
    t.hora_hasta,
    t.precio
FROM Tarifas t
INNER JOIN Cines ci ON t.ID_Cine = ci.ID_Cine
INNER JOIN Dia_semana d ON t.ID_Dia_semana = d.ID_Dia_semana
INNER JOIN Tipo_entrada te ON t.ID_Tipo_entrada = te.ID_Tipo_entrada
ORDER BY ci.nombre_cine, d.ID_Dia_semana, te.ID_Tipo_entrada;

-- ------------------------------------------------------------
-- 5) Registrar la venta de una entrada (precio indicado por la aplicacion)
-- Los triggers validan: funcion habilitada, tipo de entrada permitido, butaca existente, tarifa y precio. Si algo falla, lanzan un error con el motivo.
-- ------------------------------------------------------------
INSERT INTO Entradas (fecha_venta, precio_cobrado, estado_entrada, fila, numero_butaca, ID_Funcion, ID_Tipo_entrada, ID_Usuario)
VALUES ('2026-11-19' /*:fecha_venta*/, 6000 /*:precio*/, 1, 'D' /*:fila*/, 8 /*:numero_butaca*/, 1 /*:id_funcion*/, 1 /*:id_tipo_entrada*/, 2 /*:id_usuario*/);

-- ------------------------------------------------------------
-- 5b) Registrar la venta de una entrada (el precio sale de la tarifa)
-- Variante recomendada: la base calcula el precio con la tarifa del cine, dia y horario. Si no hay tarifa o la funcion no existe, no inserta nada (rowCount = 0).
-- ------------------------------------------------------------
INSERT INTO Entradas (fecha_venta, precio_cobrado, estado_entrada, fila, numero_butaca, ID_Funcion, ID_Tipo_entrada, ID_Usuario)
SELECT '2026-11-19' /*:fecha_venta*/, t.precio, 1, 'E' /*:fila*/, 1 /*:numero_butaca*/, f.ID_Funcion, 2 /*:id_tipo_entrada*/, 2 /*:id_usuario*/
FROM Funciones f
INNER JOIN Salas s ON s.ID_Sala = f.ID_Sala
INNER JOIN Tarifas t ON t.ID_Cine = s.ID_Cine
    AND t.ID_Tipo_entrada = 2 /*:id_tipo_entrada*/
    AND t.ID_Dia_semana = ((CAST(strftime('%w', f.fecha_funcion) AS INTEGER) + 6) % 7) + 1
    AND f.hora_inicio >= t.hora_desde AND f.hora_inicio < t.hora_hasta
WHERE f.ID_Funcion = 1 /*:id_funcion*/;

-- ------------------------------------------------------------
-- 6) Anular una entrada vendida
-- No se borra: se marca como anulada y la butaca queda libre. Solo el usuario que la compro puede anularla.
-- ------------------------------------------------------------
UPDATE Entradas
SET estado_entrada = 0
WHERE ID_Entrada = 1 /*:id_entrada*/
  AND ID_Usuario = 2 /*:id_usuario*/
  AND estado_entrada = 1;

-- ------------------------------------------------------------
-- 7) Cargar una pelicula con su genero e idioma
-- Ejecutar las tres sentencias dentro de UNA transaccion (en PHP: beginTransaction / commit): asi MAX(ID_Pelicula) siempre es la pelicula recien cargada. En PHP tambien se puede usar lastInsertId().
-- Clasificaciones: 1 = ATP, 2 = +13, 3 = +16, 4 = +18.
-- ------------------------------------------------------------
INSERT INTO Peliculas (titulo, sinopsis, fecha_estreno, fecha_carga_pelicula, duracion, ID_Clasificacion)
VALUES ('Horizonte Perdido' /*:titulo*/, 'Un viaje inesperado por la cordillera.' /*:sinopsis*/, '2026-12-18' /*:fecha_estreno*/, '2026-11-19' /*:fecha_carga*/, 115 /*:duracion*/, 2 /*:id_clasificacion*/);

INSERT INTO Generos (nombre_genero, ID_Pelicula)
VALUES ('Aventura' /*:genero*/, (SELECT MAX(ID_Pelicula) FROM Peliculas));

INSERT INTO Pelicula_idioma (ID_Pelicula, ID_Idioma)
VALUES ((SELECT MAX(ID_Pelicula) FROM Peliculas), 1 /*:id_idioma*/);

-- ------------------------------------------------------------
-- 8) Programar una funcion nueva en una sala
-- Nace deshabilitada (estado_funcion = 0): el responsable la habilita despues (8b). Los triggers validan sala en servicio, fecha dentro de la programacion, duracion minima de la pelicula y que no se superponga con otra funcion de la sala.
-- Se quito el INSERT OR IGNORE: ocultaba los errores y la funcion no se cargaba sin avisar.
-- ------------------------------------------------------------
INSERT INTO Funciones (estado_funcion, fecha_funcion, hora_inicio, hora_fin, ID_Sala, ID_Programacion, ID_Tipo_funcion, ID_Pelicula)
VALUES (0, '2026-11-22' /*:fecha_funcion*/, '19:30' /*:hora_inicio*/, '21:40' /*:hora_fin*/, 1 /*:id_sala*/, 1 /*:id_programacion*/, 3 /*:id_tipo_funcion*/, 1 /*:id_pelicula*/);

-- ------------------------------------------------------------
-- 8b) Habilitar, deshabilitar o cancelar una funcion
-- estado_funcion: 1 = habilitada (se pueden vender entradas), 0 = deshabilitada, 2 = cancelada.
-- ------------------------------------------------------------
UPDATE Funciones
SET estado_funcion = 1 /*:estado*/
WHERE ID_Funcion = 5 /*:id_funcion*/;

-- ------------------------------------------------------------
-- 9) Entradas vendidas y recaudacion por pelicula
-- Pantalla: reportes. Solo cuenta entradas vendidas (no anuladas).
-- ------------------------------------------------------------
SELECT
    p.titulo,
    COUNT(e.ID_Entrada) AS entradas_vendidas,
    COALESCE(SUM(e.precio_cobrado), 0) AS total_recaudado
FROM Peliculas p
LEFT JOIN Funciones f ON p.ID_Pelicula = f.ID_Pelicula
LEFT JOIN Entradas e ON f.ID_Funcion = e.ID_Funcion AND e.estado_entrada = 1
GROUP BY p.ID_Pelicula
ORDER BY total_recaudado DESC;

-- ------------------------------------------------------------
-- 10) Butacas vendidas y disponibles por funcion (con filtro opcional por pelicula)
-- Falta del original: GROUP BY, sin el cual devolvia una sola fila. Con id_pelicula = NULL lista todas las funciones habilitadas.
-- ------------------------------------------------------------
SELECT
    f.ID_Funcion,
    p.titulo,
    f.fecha_funcion,
    f.hora_inicio,
    s.capacidad AS capacidad_sala,
    COUNT(e.ID_Entrada) AS vendidas,
    (s.capacidad - COUNT(e.ID_Entrada)) AS disponibles
FROM Funciones f
INNER JOIN Peliculas p ON f.ID_Pelicula = p.ID_Pelicula
INNER JOIN Salas s ON f.ID_Sala = s.ID_Sala
LEFT JOIN Entradas e ON f.ID_Funcion = e.ID_Funcion AND e.estado_entrada = 1
WHERE f.estado_funcion = 1
  AND f.fecha_funcion >= '2026-11-19' /*:hoy*/
  AND (1 /*:id_pelicula*/ IS NULL OR f.ID_Pelicula = 1 /*:id_pelicula*/)
GROUP BY f.ID_Funcion
ORDER BY f.fecha_funcion, f.hora_inicio;

-- ------------------------------------------------------------
-- 11) Borrar una entrada (SOLO PARA PRUEBAS)
-- Sirve para deshacer la consulta 5 mientras se prueba. En la aplicacion NUNCA se borran entradas: son comprobantes de venta; se anulan (consulta 6).
-- ------------------------------------------------------------
DELETE FROM Entradas
WHERE fila = 'D' /*:fila*/ AND numero_butaca = 8 /*:numero_butaca*/ AND ID_Funcion = 1 /*:id_funcion*/;

-- ------------------------------------------------------------
-- 12) Tipos de entrada que permite cada clasificacion
-- Regla del enunciado: por ejemplo, una pelicula +16 no admite entrada de tipo Menor.
-- ------------------------------------------------------------
SELECT
    c.nombre_clasificacion AS clasificacion,
    te.nombre_tipo_entrada AS entrada_permitida
FROM Clasificaciones_tipo_entrada cte
INNER JOIN Clasificaciones c ON cte.ID_Clasificacion = c.ID_Clasificacion
INNER JOIN Tipo_entrada te ON cte.ID_Tipo_entrada = te.ID_Tipo_entrada
ORDER BY c.ID_Clasificacion, te.ID_Tipo_entrada;

-- ------------------------------------------------------------
-- 13) Cartelera: peliculas con funciones habilitadas (filtros opcionales por genero y titulo)
-- Pantalla: 'En cartelera'. Con genero = NULL y texto = NULL no filtra. LIKE no ignora tildes ('orbita' no encuentra 'Orbita con tilde'); si se necesita, normalizar en PHP.
-- ------------------------------------------------------------
SELECT
    p.ID_Pelicula,
    p.titulo,
    p.duracion,
    p.fecha_estreno,
    c.nombre_clasificacion AS clasificacion,
    GROUP_CONCAT(DISTINCT g.nombre_genero) AS generos
FROM Peliculas p
INNER JOIN Clasificaciones c ON p.ID_Clasificacion = c.ID_Clasificacion
LEFT JOIN Generos g ON g.ID_Pelicula = p.ID_Pelicula
WHERE EXISTS (SELECT 1 FROM Funciones f
              WHERE f.ID_Pelicula = p.ID_Pelicula AND f.estado_funcion = 1 AND f.fecha_funcion >= '2026-11-19' /*:hoy*/)
  AND ('Aventura' /*:genero*/ IS NULL OR EXISTS (SELECT 1 FROM Generos g2
                                  WHERE g2.ID_Pelicula = p.ID_Pelicula AND g2.nombre_genero = 'Aventura' /*:genero*/))
  AND ('sur' /*:texto*/ IS NULL OR p.titulo LIKE '%' || 'sur' /*:texto*/ || '%')
GROUP BY p.ID_Pelicula
ORDER BY p.titulo;

-- ------------------------------------------------------------
-- 14) Proximos estrenos
-- Pantalla: 'Proximos estrenos'. Peliculas cuya fecha de estreno todavia no llego.
-- ------------------------------------------------------------
SELECT
    p.ID_Pelicula,
    p.titulo,
    p.duracion,
    p.fecha_estreno,
    c.nombre_clasificacion AS clasificacion,
    GROUP_CONCAT(DISTINCT g.nombre_genero) AS generos
FROM Peliculas p
INNER JOIN Clasificaciones c ON p.ID_Clasificacion = c.ID_Clasificacion
LEFT JOIN Generos g ON g.ID_Pelicula = p.ID_Pelicula
WHERE p.fecha_estreno > '2026-11-19' /*:hoy*/
GROUP BY p.ID_Pelicula
ORDER BY p.fecha_estreno, p.titulo;

-- ------------------------------------------------------------
-- 15) Ficha de una pelicula
-- Pantalla: informacion de la pelicula (equivale a pages/pelicula.html?id=...).
-- ------------------------------------------------------------
SELECT
    p.ID_Pelicula,
    p.titulo,
    p.sinopsis,
    p.duracion,
    p.fecha_estreno,
    c.nombre_clasificacion AS clasificacion,
    GROUP_CONCAT(DISTINCT g.nombre_genero) AS generos,
    GROUP_CONCAT(DISTINCT i.nombre_idioma) AS idiomas
FROM Peliculas p
INNER JOIN Clasificaciones c ON p.ID_Clasificacion = c.ID_Clasificacion
LEFT JOIN Generos g ON g.ID_Pelicula = p.ID_Pelicula
LEFT JOIN Pelicula_idioma pi ON pi.ID_Pelicula = p.ID_Pelicula
LEFT JOIN Idioma i ON i.ID_Idioma = pi.ID_Idioma
WHERE p.ID_Pelicula = 3 /*:id_pelicula*/
GROUP BY p.ID_Pelicula;

-- ------------------------------------------------------------
-- 16) Precio que corresponde a una entrada (tarifa aplicable)
-- Pantalla: elegir tipo de entrada. Sin filas = no hay tarifa definida para ese cine, tipo, dia y horario.
-- ------------------------------------------------------------
SELECT t.precio
FROM Funciones f
INNER JOIN Salas s ON s.ID_Sala = f.ID_Sala
INNER JOIN Tarifas t ON t.ID_Cine = s.ID_Cine
WHERE f.ID_Funcion = 1 /*:id_funcion*/
  AND t.ID_Tipo_entrada = 2 /*:id_tipo_entrada*/
  AND t.ID_Dia_semana = ((CAST(strftime('%w', f.fecha_funcion) AS INTEGER) + 6) % 7) + 1
  AND f.hora_inicio >= t.hora_desde AND f.hora_inicio < t.hora_hasta;

-- ------------------------------------------------------------
-- 17) Tipos de entrada permitidos para una funcion
-- Pantalla: elegir tipo de entrada. Solo muestra los tipos que admite la clasificacion de la pelicula.
-- ------------------------------------------------------------
SELECT te.ID_Tipo_entrada, te.nombre_tipo_entrada
FROM Funciones f
INNER JOIN Peliculas p ON p.ID_Pelicula = f.ID_Pelicula
INNER JOIN Clasificaciones_tipo_entrada cte ON cte.ID_Clasificacion = p.ID_Clasificacion
INNER JOIN Tipo_entrada te ON te.ID_Tipo_entrada = cte.ID_Tipo_entrada
WHERE f.ID_Funcion = 2 /*:id_funcion*/
ORDER BY te.ID_Tipo_entrada;

-- ------------------------------------------------------------
-- 18) Entrada (comprobante) con todos los datos que exige el enunciado
-- Pantalla: entrada. nro_venta es el ID de la entrada. Incluye nro. de venta, fecha de venta, funcion, sala, pelicula, fecha y hora, precio, tipo y calificacion.
-- ------------------------------------------------------------
SELECT
    e.ID_Entrada AS nro_venta,
    e.fecha_venta,
    f.ID_Funcion AS nro_funcion,
    ci.nombre_cine AS cine,
    s.numero_sala AS sala,
    p.titulo AS pelicula,
    f.fecha_funcion,
    f.hora_inicio,
    e.fila,
    e.numero_butaca,
    e.precio_cobrado AS precio,
    te.nombre_tipo_entrada AS tipo_entrada,
    c.nombre_clasificacion AS calificacion
FROM Entradas e
INNER JOIN Funciones f ON f.ID_Funcion = e.ID_Funcion
INNER JOIN Salas s ON s.ID_Sala = f.ID_Sala
INNER JOIN Cines ci ON ci.ID_Cine = s.ID_Cine
INNER JOIN Peliculas p ON p.ID_Pelicula = f.ID_Pelicula
INNER JOIN Clasificaciones c ON c.ID_Clasificacion = p.ID_Clasificacion
INNER JOIN Tipo_entrada te ON te.ID_Tipo_entrada = e.ID_Tipo_entrada
WHERE e.ID_Entrada = 2 /*:id_entrada*/
  AND e.estado_entrada = 1;

-- ------------------------------------------------------------
-- 19) Mis entradas (entradas de un usuario)
-- Pantalla: mis entradas. Las funciones mas proximas primero.
-- ------------------------------------------------------------
SELECT
    e.ID_Entrada,
    p.titulo AS pelicula,
    ci.nombre_cine AS cine,
    s.numero_sala AS sala,
    f.fecha_funcion,
    f.hora_inicio,
    e.fila,
    e.numero_butaca,
    te.nombre_tipo_entrada AS tipo_entrada,
    e.precio_cobrado AS precio,
    e.estado_entrada
FROM Entradas e
INNER JOIN Funciones f ON f.ID_Funcion = e.ID_Funcion
INNER JOIN Salas s ON s.ID_Sala = f.ID_Sala
INNER JOIN Cines ci ON ci.ID_Cine = s.ID_Cine
INNER JOIN Peliculas p ON p.ID_Pelicula = f.ID_Pelicula
INNER JOIN Tipo_entrada te ON te.ID_Tipo_entrada = e.ID_Tipo_entrada
WHERE e.ID_Usuario = 2 /*:id_usuario*/
ORDER BY f.fecha_funcion, f.hora_inicio, e.ID_Entrada;

-- ------------------------------------------------------------
-- 20) Inicio de sesion: buscar usuario por correo
-- La contrasena NO se compara en SQL: PHP hace password_verify(contrasena_ingresada, password_hash). Solo devuelve usuarios activos.
-- ------------------------------------------------------------
SELECT u.ID_Usuario, u.nombre_usuario, u.password_hash, r.nombre_rol
FROM Usuarios u
INNER JOIN Roles r ON r.ID_Rol = u.ID_Rol
WHERE u.correo_usuario = 'cliente1@correo.com' /*:correo*/
  AND u.estado_usuario = 1;

-- ------------------------------------------------------------
-- 21) Registro de un usuario nuevo
-- password_hash lo genera PHP con password_hash(); nunca se guarda la contrasena. El ejemplo usa '*' (cuenta bloqueada). El rol se busca por nombre. Si el correo ya existe, falla por UNIQUE.
-- ------------------------------------------------------------
INSERT INTO Usuarios (nombre_usuario, correo_usuario, password_hash, ID_Rol)
VALUES ('Maria Gomez' /*:nombre*/, 'maria@correo.com' /*:correo*/, '*' /*:password_hash*/, (SELECT ID_Rol FROM Roles WHERE nombre_rol = 'usuario'));
