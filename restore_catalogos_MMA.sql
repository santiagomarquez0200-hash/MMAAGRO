-- =============================================================================
-- SCRIPT DE RESTAURACIÓN — CATÁLOGOS MMA (AgriControl APK)
-- Schema: AGKMMA  |  Motor: SQL Server 2019+
-- Generado: 2026-06-22  |  Basado en tablasyprocedimientos_produccion.sql
-- =============================================================================
-- INSTRUCCIONES:
--   1. Ejecutar en la misma base de datos donde están las tablas AGKMMA
--   2. El script es IDEMPOTENTE — se puede correr múltiples veces sin duplicar
--   3. Verificar al final con los SELECT de validación al final del script
-- =============================================================================

SET NOCOUNT ON;
GO

-- ─────────────────────────────────────────────────────────────────────────────
-- 1. CLI547_MMA_CAJAS_CAMBIOS (Marchas de trabajo)
--    Fuente: tablasyprocedimientos_produccion.sql § Marchas de trabajo
-- ─────────────────────────────────────────────────────────────────────────────
PRINT '>>> Restaurando CLI547_MMA_CAJAS_CAMBIOS...';

INSERT INTO AGKMMA.CLI547_MMA_CAJAS_CAMBIOS (nombre)
SELECT v.nombre FROM (VALUES
    ('T-1'), ('T-2'), ('T-3'), ('T-4'),
    ('H-1'), ('H-2'), ('H-3'), ('H-4'),
    ('L-1'), ('L-2'), ('L-3'), ('L-4')
) v(nombre)
WHERE NOT EXISTS (
    SELECT 1 FROM AGKMMA.CLI547_MMA_CAJAS_CAMBIOS WHERE nombre = v.nombre
);

PRINT '    OK — ' + CAST(@@ROWCOUNT AS VARCHAR) + ' fila(s) insertada(s).';
GO

-- ─────────────────────────────────────────────────────────────────────────────
-- 2. CLI547_MMA_TIPOS_PARO
--    Fuente: 01_schema.sql § CLI547_MMA_TIPOS_PARO + producción
-- ─────────────────────────────────────────────────────────────────────────────
PRINT '>>> Restaurando CLI547_MMA_TIPOS_PARO...';

INSERT INTO AGKMMA.CLI547_MMA_TIPOS_PARO (codigo, nombre, requiere_galones, requiere_equipo, activo)
SELECT v.codigo, v.nombre, v.rg, v.re, 1
FROM (VALUES
    ('CLIMA',        'Factor climático',              0, 0),
    ('COMBUSTIBLE',  'Abastecimiento de combustible', 1, 0),
    ('MECANICO',     'Falla mecánica',                0, 1),
    ('CALIBRACION',  'Calibración de equipos',        0, 0),
    ('CAPACITACION', 'Charlas o capacitaciones',      0, 0)
) v(codigo, nombre, rg, re)
WHERE NOT EXISTS (
    SELECT 1 FROM AGKMMA.CLI547_MMA_TIPOS_PARO WHERE codigo = v.codigo
);

PRINT '    OK — ' + CAST(@@ROWCOUNT AS VARCHAR) + ' fila(s) insertada(s).';
GO

-- ─────────────────────────────────────────────────────────────────────────────
-- 3. CLI547_MMA_PROCESOS
--    Fuente: tablasyprocedimientos_produccion.sql § 9. CATÁLOGOS INICIALES
--    tipo_registro:
--      'tractor'  → procesos del formulario tractor (MMA-FR-004)
--      'vehiculo' → procesos del formulario camión/camioneta
-- ─────────────────────────────────────────────────────────────────────────────
PRINT '>>> Restaurando CLI547_MMA_PROCESOS...';

-- 3a. Procesos de TRACTOR (tipo_registro = 'tractor')
INSERT INTO AGKMMA.CLI547_MMA_PROCESOS (codigo, nombre, requiere_bines, activo)
SELECT v.codigo, v.nombre, v.rb, 1
FROM (VALUES
    ('APLIC',  'Aplicación',  0),
    ('COSEC',  'Cosecha',     1),
    ('PODA',   'Poda',        0),
    ('TRITU',  'Triturado',   0),
    ('RUFA',   'Rufa',        0),
    ('CARRE',  'Carreteo',    0),
    ('MELAZ',  'Melaza',      0)
) v(codigo, nombre, rb)
WHERE NOT EXISTS (
    SELECT 1 FROM AGKMMA.CLI547_MMA_PROCESOS WHERE codigo = v.codigo
);

-- 3b. Procesos de VEHÍCULO (tipo_registro = 'vehiculo')
INSERT INTO AGKMMA.CLI547_MMA_PROCESOS (codigo, nombre, requiere_bines, activo)
SELECT v.codigo, v.nombre, v.rb, 1
FROM (VALUES
    ('REGADO_CAMINOS',    'Regado de caminos',      0),
    ('TRASLADO_MANGUERAS','Traslado de mangueras',  0),
    ('OTRO',              'Otro',                   0),
    ('CULTIVO',           'Cultivo',                1),
    ('TRASLADO_MATERIALES','Traslado de materiales',0),
    ('ABASTECIMIENTO',    'Abastecimiento',         0),
    ('APLICACION',        'Aplicacion',             0)
) v(codigo, nombre, rb)
WHERE NOT EXISTS (
    SELECT 1 FROM AGKMMA.CLI547_MMA_PROCESOS WHERE codigo = v.codigo
);

PRINT '    OK — procesos insertados (tractor + vehículo).';
GO

-- 3c. Asegurar columnas tipo_registro y requiere_sublabores (idempotente)
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
               WHERE TABLE_SCHEMA='AGKMMA' AND TABLE_NAME='CLI547_MMA_PROCESOS'
                 AND COLUMN_NAME='requiere_sublabores')
    ALTER TABLE AGKMMA.CLI547_MMA_PROCESOS ADD requiere_sublabores BIT NOT NULL DEFAULT 0;
GO
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
               WHERE TABLE_SCHEMA='AGKMMA' AND TABLE_NAME='CLI547_MMA_PROCESOS'
                 AND COLUMN_NAME='tipo_registro')
    ALTER TABLE AGKMMA.CLI547_MMA_PROCESOS ADD tipo_registro VARCHAR(20) NOT NULL DEFAULT 'tractor';
GO

-- 3d. Marcar procesos exclusivos de vehículo
UPDATE AGKMMA.CLI547_MMA_PROCESOS
SET tipo_registro = 'vehiculo'
WHERE codigo IN ('REGADO_CAMINOS','TRASLADO_MANGUERAS','TRASLADO_MATERIALES',
                 'ABASTECIMIENTO','OTRO','CULTIVO','APLICACION');
GO

-- 3e. Marcar proceso que requiere sublabores (Aplicacion de vehículo)
UPDATE AGKMMA.CLI547_MMA_PROCESOS
SET requiere_sublabores = 1
WHERE codigo IN ('APLICACION', 'APLICACIONES', 'APLIC');
GO

PRINT '    OK — tipo_registro y requiere_sublabores actualizados.';
GO

-- ─────────────────────────────────────────────────────────────────────────────
-- 4. CLI547_MMA_CHECKLIST_CATEGORIAS
--    Fuente: tablasyprocedimientos_produccion.sql § 2.5 + § 9
-- ─────────────────────────────────────────────────────────────────────────────
PRINT '>>> Restaurando CLI547_MMA_CHECKLIST_CATEGORIAS...';

IF NOT EXISTS (SELECT 1 FROM AGKMMA.CLI547_MMA_CHECKLIST_CATEGORIAS WHERE nombre = 'Inspeccionar Tractor')
    INSERT INTO AGKMMA.CLI547_MMA_CHECKLIST_CATEGORIAS (nombre, orden) VALUES ('Inspeccionar Tractor', 10);

IF NOT EXISTS (SELECT 1 FROM AGKMMA.CLI547_MMA_CHECKLIST_CATEGORIAS WHERE nombre = 'Inspeccionar Implemento')
    INSERT INTO AGKMMA.CLI547_MMA_CHECKLIST_CATEGORIAS (nombre, orden) VALUES ('Inspeccionar Implemento', 20);

IF NOT EXISTS (SELECT 1 FROM AGKMMA.CLI547_MMA_CHECKLIST_CATEGORIAS WHERE nombre = 'Vehículo')
    INSERT INTO AGKMMA.CLI547_MMA_CHECKLIST_CATEGORIAS (nombre, orden) VALUES ('Vehículo', 100);

PRINT '    OK — 3 categorías garantizadas.';
GO

-- ─────────────────────────────────────────────────────────────────────────────
-- 5. CLI547_MMA_CHECKLIST_ITEMS_CATALOGO
--    Fuente: tablasyprocedimientos_produccion.sql § 9
--    32 ítems tractor (2 cat) + 24 ítems vehículo (1 cat) = 56 total
-- ─────────────────────────────────────────────────────────────────────────────
PRINT '>>> Restaurando CLI547_MMA_CHECKLIST_ITEMS_CATALOGO...';

-- Items TRACTOR (32 ítems)
IF NOT EXISTS (SELECT 1 FROM AGKMMA.CLI547_MMA_CHECKLIST_ITEMS_CATALOGO WHERE tipo_registro = 'tractor')
BEGIN
    DECLARE @cat_t1 INT, @cat_t2 INT;
    SELECT @cat_t1 = id FROM AGKMMA.CLI547_MMA_CHECKLIST_CATEGORIAS WHERE nombre = 'Inspeccionar Tractor';
    SELECT @cat_t2 = id FROM AGKMMA.CLI547_MMA_CHECKLIST_CATEGORIAS WHERE nombre = 'Inspeccionar Implemento';

    INSERT INTO AGKMMA.CLI547_MMA_CHECKLIST_ITEMS_CATALOGO (categoria_id, nombre, orden, activo, tipo_registro) VALUES
        -- Categoría: Inspeccionar Tractor (16 ítems)
        (@cat_t1, 'Nivel de aceite del motor',                            1,  1, 'tractor'),
        (@cat_t1, 'Nivel de aceite hidráulico del tractor',               2,  1, 'tractor'),
        (@cat_t1, 'Nivel de refrigerante del motor',                      3,  1, 'tractor'),
        (@cat_t1, 'Nivel de aceite de la caja multiplicadora',            4,  1, 'tractor'),
        (@cat_t1, 'Nivel de aceite hidráulico del Implemento',            5,  1, 'tractor'),
        (@cat_t1, 'Llantas y ajuste de tuercas de rueda',                 6,  1, 'tractor'),
        (@cat_t1, 'Batería y sus bornes',                                 7,  1, 'tractor'),
        (@cat_t1, 'Barra de tiro, pines y seguro',                        8,  1, 'tractor'),
        (@cat_t1, 'Faja de alternador',                                   9,  1, 'tractor'),
        (@cat_t1, 'Tanque de productos',                                 10,  1, 'tractor'),
        (@cat_t1, 'Espejos del tractor',                                 11,  1, 'tractor'),
        (@cat_t1, 'Cardan y su Protector',                               12,  1, 'tractor'),
        (@cat_t1, 'Claxon',                                              13,  1, 'tractor'),
        (@cat_t1, 'Mangueras hidráulicas',                               14,  1, 'tractor'),
        (@cat_t1, 'Extintor',                                            15,  1, 'tractor'),
        (@cat_t1, 'Mangueras agroquímicas',                              16,  1, 'tractor'),
        -- Categoría: Inspeccionar Implemento (16 ítems)
        (@cat_t2, 'Nivel de aceite en los reductores delant. y post.',   17,  1, 'tractor'),
        (@cat_t2, 'Fajas de transmisión',                                18,  1, 'tractor'),
        (@cat_t2, 'Nivel de aceite del tren delantero',                  19,  1, 'tractor'),
        (@cat_t2, 'Bombines hidráulicos',                                20,  1, 'tractor'),
        (@cat_t2, 'Templadores de brazos de levante y pines/seguros',    21,  1, 'tractor'),
        (@cat_t2, 'Comando hidráulico',                                  22,  1, 'tractor'),
        (@cat_t2, 'Llantas y ajuste de tuercas de rueda (impl.)',        23,  1, 'tractor'),
        (@cat_t2, 'Comando eléctrico',                                   24,  1, 'tractor'),
        (@cat_t2, 'Cinturón de seguridad y Protección antivuelco',       25,  1, 'tractor'),
        (@cat_t2, 'Luces del Implemento',                                26,  1, 'tractor'),
        (@cat_t2, 'Luces del tractor',                                   27,  1, 'tractor'),
        (@cat_t2, 'Horómetro',                                           28,  1, 'tractor'),
        (@cat_t2, 'Alarma de retroceso',                                 29,  1, 'tractor'),
        (@cat_t2, 'Techo y soportes',                                    30,  1, 'tractor'),
        (@cat_t2, 'Tacos de seguridad',                                  31,  1, 'tractor'),
        (@cat_t2, 'Soporte frontal y templadores',                       32,  1, 'tractor');

    PRINT '    OK — 32 ítems de tractor insertados.';
END
ELSE
    PRINT '    SKIP — ítems de tractor ya existen.';
GO

-- Items VEHÍCULO (24 ítems)
IF NOT EXISTS (SELECT 1 FROM AGKMMA.CLI547_MMA_CHECKLIST_ITEMS_CATALOGO WHERE tipo_registro = 'vehiculo')
BEGIN
    DECLARE @cat_v INT;
    SELECT @cat_v = id FROM AGKMMA.CLI547_MMA_CHECKLIST_CATEGORIAS WHERE nombre = 'Vehículo';

    INSERT INTO AGKMMA.CLI547_MMA_CHECKLIST_ITEMS_CATALOGO (categoria_id, nombre, orden, activo, tipo_registro) VALUES
        (@cat_v, 'Nivel de aceite de motor',                             1,  1, 'vehiculo'),
        (@cat_v, 'Nivel de refrigerante de motor',                       2,  1, 'vehiculo'),
        (@cat_v, 'Nivel de hidrolina de dirección',                      3,  1, 'vehiculo'),
        (@cat_v, 'Nivel de líquido de frenos',                           4,  1, 'vehiculo'),
        (@cat_v, 'Nivel de combustible',                                 5,  1, 'vehiculo'),
        (@cat_v, 'Nivel de aceite de los reductores posteriores',        6,  1, 'vehiculo'),
        (@cat_v, 'Estado de Batería y sus bornes',                       7,  1, 'vehiculo'),
        (@cat_v, 'Estado de faja de alternador y templado',              8,  1, 'vehiculo'),
        (@cat_v, 'Estado del radiador, mangueras y su tapa',             9,  1, 'vehiculo'),
        (@cat_v, 'Estado de Llantas y ajuste de tuercas de rueda',      10,  1, 'vehiculo'),
        (@cat_v, 'Estado de cardán y soportes',                         11,  1, 'vehiculo'),
        (@cat_v, 'Estado de freno de estacionamiento',                  12,  1, 'vehiculo'),
        (@cat_v, 'Extintor instalado y operativo',                      13,  1, 'vehiculo'),
        (@cat_v, 'Estado de Asiento y Cinturón de seguridad',           14,  1, 'vehiculo'),
        (@cat_v, 'Estado de cabina de operador',                        15,  1, 'vehiculo'),
        (@cat_v, 'Estado de Puertas',                                   16,  1, 'vehiculo'),
        (@cat_v, 'Espejos',                                             17,  1, 'vehiculo'),
        (@cat_v, 'Luces',                                               18,  1, 'vehiculo'),
        (@cat_v, 'Tacos de seguridad',                                  19,  1, 'vehiculo'),
        (@cat_v, 'Alarma de retroceso',                                 20,  1, 'vehiculo'),
        (@cat_v, 'Claxon',                                              21,  1, 'vehiculo'),
        (@cat_v, 'Documentos del vehículo',                             22,  1, 'vehiculo'),
        (@cat_v, 'Parabrisas y Limpia parabrisas',                      23,  1, 'vehiculo'),
        (@cat_v, 'Horómetro y tacómetro',                               24,  1, 'vehiculo');

    PRINT '    OK — 24 ítems de vehículo insertados.';
END
ELSE
    PRINT '    SKIP — ítems de vehículo ya existen.';
GO

-- ─────────────────────────────────────────────────────────────────────────────
-- 6. CLI547_MMA_SUBPROCESOS
--    ⚠ No se encontró backup de estos datos.
--    Insertar manualmente los subprocesos que recuerdes.
--    Ejemplo de estructura para el proceso APLICACION (APLIC):
-- ─────────────────────────────────────────────────────────────────────────────
PRINT '>>> CLI547_MMA_SUBPROCESOS — REQUIERE CARGA MANUAL';
PRINT '    Estructura: (proceso_id, nombre, codigo, descripcion, activo)';
PRINT '    Reemplazar los valores de ejemplo con los reales de tu operación.';

/*
-- DESCOMENTA Y AJUSTA SEGÚN TUS SUBPROCESOS REALES:

DECLARE @proc_aplic INT;
SELECT @proc_aplic = id FROM AGKMMA.CLI547_MMA_PROCESOS WHERE codigo = 'APLIC';

INSERT INTO AGKMMA.CLI547_MMA_SUBPROCESOS (proceso_id, nombre, codigo, descripcion, activo)
SELECT @proc_aplic, v.nombre, v.codigo, NULL, 1
FROM (VALUES
    ('Nombre Sublabor 1', 'SUB01'),
    ('Nombre Sublabor 2', 'SUB02'),
    ('Nombre Sublabor 3', 'SUB03')
) v(nombre, codigo)
WHERE NOT EXISTS (
    SELECT 1 FROM AGKMMA.CLI547_MMA_SUBPROCESOS
    WHERE proceso_id = @proc_aplic AND nombre = v.nombre
);
*/
GO

-- ─────────────────────────────────────────────────────────────────────────────
-- 7. VALIDACIÓN FINAL
-- ─────────────────────────────────────────────────────────────────────────────
PRINT '';
PRINT '======== RESUMEN DE RESTAURACIÓN ========';
SELECT 'CLI547_MMA_CAJAS_CAMBIOS'           AS tabla, COUNT(*) AS total FROM AGKMMA.CLI547_MMA_CAJAS_CAMBIOS
UNION ALL
SELECT 'CLI547_MMA_TIPOS_PARO',               COUNT(*) FROM AGKMMA.CLI547_MMA_TIPOS_PARO
UNION ALL
SELECT 'CLI547_MMA_PROCESOS (tractor)',        COUNT(*) FROM AGKMMA.CLI547_MMA_PROCESOS WHERE tipo_registro = 'tractor'
UNION ALL
SELECT 'CLI547_MMA_PROCESOS (vehiculo)',       COUNT(*) FROM AGKMMA.CLI547_MMA_PROCESOS WHERE tipo_registro = 'vehiculo'
UNION ALL
SELECT 'CLI547_MMA_PROCESOS (total)',          COUNT(*) FROM AGKMMA.CLI547_MMA_PROCESOS
UNION ALL
SELECT 'CLI547_MMA_CHECKLIST_CATEGORIAS',     COUNT(*) FROM AGKMMA.CLI547_MMA_CHECKLIST_CATEGORIAS
UNION ALL
SELECT 'CLI547_MMA_CHECKLIST_ITEMS (tractor)',COUNT(*) FROM AGKMMA.CLI547_MMA_CHECKLIST_ITEMS_CATALOGO WHERE tipo_registro = 'tractor'
UNION ALL
SELECT 'CLI547_MMA_CHECKLIST_ITEMS (vehiculo)',COUNT(*) FROM AGKMMA.CLI547_MMA_CHECKLIST_ITEMS_CATALOGO WHERE tipo_registro = 'vehiculo'
UNION ALL
SELECT 'CLI547_MMA_SUBPROCESOS',              COUNT(*) FROM AGKMMA.CLI547_MMA_SUBPROCESOS;

PRINT '';   
PRINT 'ESPERADO:';
PRINT '  CLI547_MMA_CAJAS_CAMBIOS          : 12 filas (T-1..T-4, H-1..H-4, L-1..L-4)';
PRINT '  CLI547_MMA_TIPOS_PARO             :  5 filas (CLIMA, COMBUSTIBLE, MECANICO, CALIBRACION, CAPACITACION)';
PRINT '  CLI547_MMA_PROCESOS (tractor)     :  7 filas (APLIC, COSEC, PODA, TRITU, RUFA, CARRE, MELAZ)';
PRINT '  CLI547_MMA_PROCESOS (vehiculo)    :  7 filas (REGADO_CAMINOS, TRASLADO_MANGUERAS, OTRO, CULTIVO, ...)';
PRINT '  CLI547_MMA_CHECKLIST_CATEGORIAS   :  3 filas';
PRINT '  CLI547_MMA_CHECKLIST_ITEMS tractor: 32 filas';
PRINT '  CLI547_MMA_CHECKLIST_ITEMS vehiculo: 24 filas';
PRINT '  CLI547_MMA_SUBPROCESOS            :  CARGA MANUAL REQUERIDA';
GO
