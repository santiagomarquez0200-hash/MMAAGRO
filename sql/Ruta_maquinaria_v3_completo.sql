-- #############################################################################
-- #                                                                           #
-- #   RUTAS DE MAQUINARIA — MODELO v3 COMPLETO                                #
-- #   Script único y unificado. Ejecutar de principio a fin.                   #
-- #                                                                           #
-- #############################################################################
--
-- QUÉ ES ESTO
--   Todo el modelo de trazabilidad GPS de maquinaria en un solo archivo:
--   tablas, índices, constraints, el SP de sincronización, los SPs de consulta
--   y exportación KML, y las vistas para QGIS.
--
--   Reemplaza a los 6 archivos que antes vivían sueltos en sql/
--   (Ruta_maquinaria_v3, _analytics, _sublotes, SINCRONIZAR_OFFLINE_v3,
--    _export_kml, _vistas_qgis). Ya no existen: este es el único.
--
-- MODELO v3 EN UNA FRASE
--   El APK captura puntos GPS cada 5 s en SQLite, los clasifica contra los
--   polígonos de sublote (point-in-polygon offline), y al CERRAR TURNO envía
--   la jornada entera como UNA sola geometría WKT (LINESTRING) más sus métricas
--   ya calculadas. El servidor guarda una fila por jornada en
--   CLI547_AGM_Ruta_maquinaria como tipo GEOGRAPHY.
--
--   El modelo v2 (una fila por punto, tabla CLI547_AGM_Punto_gps_maquinaria,
--   SP CLI547_AGMSP_MMA_REGISTRAR_PUNTOS_GPS) está RETIRADO. Si esa tabla
--   todavía existe en el servidor, ya no recibe datos y puede eliminarse.
--
-- ORDEN INTERNO (las secciones dependen unas de otras — no reordenar)
--   1. Tabla CLI547_AGM_Ruta_maquinaria + índices + FK
--   2. Columnas de analytics + CHECK constraints
--   3. Tabla normalizada de sublotes + backfill del JSON histórico
--   4. SP CLI547_AGMSP_MMA_SINCRONIZAR_OFFLINE  (sincronización desde el APK)
--   5. SPs de consulta para mapa y exportación KML
--   6. Vistas para QGIS (rutas y sublotes)
--   7. Modelo de eventos: visitas a sublote, paradas y tramos + ancho de labor
--   8. SP de cálculo de cobertura (hectáreas trabajadas y % de avance)
--   9. Capas de eventos para QGIS + timeline de jornada
--
-- REQUISITO DE VERSIÓN
--   SQL Server 2016 o superior (usa OPENJSON, ISJSON y JSON_QUERY).
--
-- DESPUÉS DE INSTALAR
--   · Poblar dbo.CLI547_AGM_MMA_IMPLEMENTOS_ANCHO (sección 7.4) o el cálculo
--     de cobertura no podrá correr.
--   · Ejecutar CLI547_AGMSP_MMA_CALCULAR_COBERTURA después de cada sync
--     (a mano o como job de SQL Agent).
--
-- IDEMPOTENTE
--   Todo el script se puede re-ejecutar sin efectos secundarios: las tablas
--   usan IF NOT EXISTS, las columnas y constraints verifican antes de crearse,
--   el backfill no duplica, y los SPs/vistas son CREATE OR ALTER.
--
-- ⚠️ AVISO IMPORTANTE — DUPLICIDAD CON EL SCRIPT MAESTRO
--   El SP de la SECCIÓN 4 (CLI547_AGMSP_MMA_SINCRONIZAR_OFFLINE) también está
--   definido dentro de tablasyprocedimientos_produccion.sql. Ambas copias son
--   idénticas hoy. Como SQL Server solo conserva la ÚLTIMA versión ejecutada,
--   si se modifica una hay que modificar la otra, o la versión desplegada
--   dependerá de cuál script se corrió al final.
--
-- =============================================================================


-- #############################################################################
-- #  SECCIÓN 1 · TABLA DE RUTAS + ÍNDICES + FOREIGN KEY
-- #############################################################################

-- =============================================================================
-- Tabla: CLI547_AGM_Ruta_maquinaria  (v3 — ruta WKT por jornada)
-- Propósito: almacenar la ruta completa de cada registro como una sola fila
--            con tipo GEOGRAPHY (LineString o Point cuando solo hay 1 punto).
--            Es el único destino de sincronización de rutas; el modelo v2 de
--            puntos individuales (CLI547_AGM_Punto_gps_maquinaria) fue retirado.
-- Idempotente: se puede ejecutar N veces sin efectos secundarios.
-- =============================================================================

IF NOT EXISTS (
    SELECT 1 FROM sys.tables WHERE name = 'CLI547_AGM_Ruta_maquinaria'
)
BEGIN
    CREATE TABLE dbo.CLI547_AGM_Ruta_maquinaria (
        id                  UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID(),
        registro_id         UNIQUEIDENTIFIER NOT NULL,
        ruta_geog           GEOGRAPHY        NULL,
        total_puntos        INT              NULL,        -- STNumPoints()
        longitud_km         DECIMAL(10,3)    NULL,        -- STLength() / 1000
        operador_id_erp     INT              NULL,
        fecha               DATE             NULL,
        tractor_id_erp      INT              NULL,
        proceso_id          INT              NULL,
        -- OJO: esta columna es UTC (SYSUTCDATETIME), a diferencia de las tablas
        -- hermanas del módulo MMA que usan GETDATE() (hora local del servidor).
        -- No mezclar ambas en comparaciones de fecha/hora sin convertir primero.
        sincronizado_at     DATETIME2(0)     NOT NULL DEFAULT SYSUTCDATETIME(),
        CONSTRAINT PK_CLI547_AGM_Ruta_maquinaria PRIMARY KEY (id),
        CONSTRAINT UQ_CLI547_AGM_Ruta_registro    UNIQUE (registro_id)
    );

    -- Índice espacial para consultas de proximidad / bounding box
    CREATE SPATIAL INDEX SX_CLI547_AGM_Ruta_maquinaria_geog
        ON dbo.CLI547_AGM_Ruta_maquinaria (ruta_geog)
        USING GEOGRAPHY_GRID
        WITH (GRIDS = (MEDIUM, MEDIUM, MEDIUM, MEDIUM));

    PRINT '>>> Tabla CLI547_AGM_Ruta_maquinaria creada correctamente.';
END
ELSE
BEGIN
    PRINT '>>> Tabla CLI547_AGM_Ruta_maquinaria ya existe — se aplican solo los ajustes.';
END
GO

-- =============================================================================
-- Índices de reporte (no espaciales)
-- El índice espacial solo acelera predicados geométricos. Las consultas del
-- dashboard filtran por fecha / tractor / operador, que sin esto hacen scan.
-- =============================================================================
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = 'IX_RutaMaquinaria_Fecha_Tractor'
      AND object_id = OBJECT_ID('dbo.CLI547_AGM_Ruta_maquinaria')
)
BEGIN
    CREATE INDEX IX_RutaMaquinaria_Fecha_Tractor
        ON dbo.CLI547_AGM_Ruta_maquinaria (fecha, tractor_id_erp)
        INCLUDE (operador_id_erp, proceso_id, total_puntos, longitud_km);
    PRINT '>>> Índice IX_RutaMaquinaria_Fecha_Tractor creado.';
END
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = 'IX_RutaMaquinaria_Operador_Fecha'
      AND object_id = OBJECT_ID('dbo.CLI547_AGM_Ruta_maquinaria')
)
BEGIN
    CREATE INDEX IX_RutaMaquinaria_Operador_Fecha
        ON dbo.CLI547_AGM_Ruta_maquinaria (operador_id_erp, fecha);
    PRINT '>>> Índice IX_RutaMaquinaria_Operador_Fecha creado.';
END
GO

-- =============================================================================
-- Foreign Key hacia el registro diario
-- La tabla v2 sí tenía este FK con ON DELETE CASCADE; la v3 nació sin él, lo
-- que permite rutas huérfanas si se borra un registro diario.
--
-- No se fuerza el FK si ya existen huérfanos: el script reporta el problema y
-- se salta la creación, para no fallar a mitad de un despliegue. Revisar con la
-- consulta que imprime el PRINT y decidir si borrar esas filas.
-- =============================================================================
IF NOT EXISTS (
    SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_RutaMaquinaria_Registro'
)
BEGIN
    DECLARE @v_huerfanos INT;

    SELECT @v_huerfanos = COUNT(*)
    FROM dbo.CLI547_AGM_Ruta_maquinaria r
    WHERE NOT EXISTS (
        SELECT 1 FROM dbo.CLI547_AGM_MMA_REGISTROS_DIARIOS d WHERE d.id = r.registro_id
    );

    IF @v_huerfanos = 0
    BEGIN
        ALTER TABLE dbo.CLI547_AGM_Ruta_maquinaria
            ADD CONSTRAINT FK_RutaMaquinaria_Registro
            FOREIGN KEY (registro_id)
            REFERENCES dbo.CLI547_AGM_MMA_REGISTROS_DIARIOS(id)
            ON DELETE CASCADE;
        PRINT '>>> FK_RutaMaquinaria_Registro creado (ON DELETE CASCADE).';
    END
    ELSE
    BEGIN
        PRINT '*** FK NO creado: hay ' + CAST(@v_huerfanos AS VARCHAR(10))
            + ' ruta(s) sin registro diario asociado.';
        PRINT '*** Inspeccionar con:';
        PRINT '***   SELECT r.* FROM dbo.CLI547_AGM_Ruta_maquinaria r';
        PRINT '***   WHERE NOT EXISTS (SELECT 1 FROM dbo.CLI547_AGM_MMA_REGISTROS_DIARIOS d WHERE d.id = r.registro_id);';
        PRINT '*** Luego borrar esas filas y volver a ejecutar este script.';
    END
END
GO


-- #############################################################################
-- #  SECCIÓN 2 · COLUMNAS DE ANALYTICS + CHECK CONSTRAINTS
-- #############################################################################

-- =============================================================================
-- ALTER TABLE: CLI547_AGM_Ruta_maquinaria — columnas de analytics GPS
-- Idempotente (verifica existencia antes de agregar).
-- Complementa la SECCIÓN 1 — no la reemplaza.
-- =============================================================================

-- km recorridos en modo TRABAJO (dentro de sublotes, vel 1–8 km/h)
IF NOT EXISTS (
    SELECT 1 FROM sys.columns
    WHERE object_id = OBJECT_ID('dbo.CLI547_AGM_Ruta_maquinaria') AND name = 'km_trabajo'
)
    ALTER TABLE dbo.CLI547_AGM_Ruta_maquinaria ADD km_trabajo DECIMAL(10,3) NULL;

-- km recorridos en modo TRASLADO (fuera de sublotes o vel > 8 km/h)
IF NOT EXISTS (
    SELECT 1 FROM sys.columns
    WHERE object_id = OBJECT_ID('dbo.CLI547_AGM_Ruta_maquinaria') AND name = 'km_traslado'
)
    ALTER TABLE dbo.CLI547_AGM_Ruta_maquinaria ADD km_traslado DECIMAL(10,3) NULL;

-- Minutos en movimiento activo (TRABAJO)
IF NOT EXISTS (
    SELECT 1 FROM sys.columns
    WHERE object_id = OBJECT_ID('dbo.CLI547_AGM_Ruta_maquinaria') AND name = 'tiempo_trabajo_min'
)
    ALTER TABLE dbo.CLI547_AGM_Ruta_maquinaria ADD tiempo_trabajo_min INT NULL;

-- Minutos detenido (suma de todas las paradas)
IF NOT EXISTS (
    SELECT 1 FROM sys.columns
    WHERE object_id = OBJECT_ID('dbo.CLI547_AGM_Ruta_maquinaria') AND name = 'tiempo_parado_min'
)
    ALTER TABLE dbo.CLI547_AGM_Ruta_maquinaria ADD tiempo_parado_min INT NULL;

-- Velocidad promedio (km/h) — solo en puntos TRABAJO
IF NOT EXISTS (
    SELECT 1 FROM sys.columns
    WHERE object_id = OBJECT_ID('dbo.CLI547_AGM_Ruta_maquinaria') AND name = 'velocidad_prom_kmh'
)
    ALTER TABLE dbo.CLI547_AGM_Ruta_maquinaria ADD velocidad_prom_kmh DECIMAL(5,2) NULL;

-- Velocidad máxima registrada (km/h)
IF NOT EXISTS (
    SELECT 1 FROM sys.columns
    WHERE object_id = OBJECT_ID('dbo.CLI547_AGM_Ruta_maquinaria') AND name = 'velocidad_max_kmh'
)
    ALTER TABLE dbo.CLI547_AGM_Ruta_maquinaria ADD velocidad_max_kmh DECIMAL(5,2) NULL;

-- Número total de eventos de parada
IF NOT EXISTS (
    SELECT 1 FROM sys.columns
    WHERE object_id = OBJECT_ID('dbo.CLI547_AGM_Ruta_maquinaria') AND name = 'total_paradas'
)
    ALTER TABLE dbo.CLI547_AGM_Ruta_maquinaria ADD total_paradas INT NULL;

-- Eficiencia: tiempo_trabajo / tiempo_jornada * 100
IF NOT EXISTS (
    SELECT 1 FROM sys.columns
    WHERE object_id = OBJECT_ID('dbo.CLI547_AGM_Ruta_maquinaria') AND name = 'eficiencia_pct'
)
    ALTER TABLE dbo.CLI547_AGM_Ruta_maquinaria ADD eficiencia_pct DECIMAL(5,2) NULL;

-- JSON array con sublotes trabajados: [{sublote_id, nombre, minutos}]
-- Se conserva como payload crudo de auditoría. La fuente consultable/agregable
-- es la tabla normalizada CLI547_AGM_Ruta_maquinaria_Sublotes, que el SP de
-- sincronización llena a partir de este mismo JSON.
IF NOT EXISTS (
    SELECT 1 FROM sys.columns
    WHERE object_id = OBJECT_ID('dbo.CLI547_AGM_Ruta_maquinaria') AND name = 'sublotes_trabajados'
)
    ALTER TABLE dbo.CLI547_AGM_Ruta_maquinaria ADD sublotes_trabajados NVARCHAR(MAX) NULL;
GO

-- =============================================================================
-- CHECK constraints — barrera contra cálculos erróneos del APK
--
-- Se agregan WITH NOCHECK: no validan las filas ya existentes (para que el
-- script nunca falle en un despliegue), pero sí bloquean cualquier escritura
-- futura fuera de rango. Para auditar filas legacy que violen los rangos:
--
--   SELECT * FROM dbo.CLI547_AGM_Ruta_maquinaria
--   WHERE eficiencia_pct NOT BETWEEN 0 AND 100
--      OR km_trabajo < 0 OR km_traslado < 0
--      OR velocidad_prom_kmh < 0 OR velocidad_max_kmh < 0
--      OR tiempo_trabajo_min < 0 OR tiempo_parado_min < 0 OR total_paradas < 0;
-- =============================================================================

IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_RutaMaquinaria_Eficiencia')
BEGIN
    ALTER TABLE dbo.CLI547_AGM_Ruta_maquinaria WITH NOCHECK
        ADD CONSTRAINT CK_RutaMaquinaria_Eficiencia
        CHECK (eficiencia_pct IS NULL OR eficiencia_pct BETWEEN 0 AND 100);
    PRINT '>>> CK_RutaMaquinaria_Eficiencia creado.';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_RutaMaquinaria_Kilometros')
BEGIN
    ALTER TABLE dbo.CLI547_AGM_Ruta_maquinaria WITH NOCHECK
        ADD CONSTRAINT CK_RutaMaquinaria_Kilometros
        CHECK ((km_trabajo  IS NULL OR km_trabajo  >= 0)
           AND (km_traslado IS NULL OR km_traslado >= 0)
           AND (longitud_km IS NULL OR longitud_km >= 0));
    PRINT '>>> CK_RutaMaquinaria_Kilometros creado.';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_RutaMaquinaria_Velocidades')
BEGIN
    ALTER TABLE dbo.CLI547_AGM_Ruta_maquinaria WITH NOCHECK
        ADD CONSTRAINT CK_RutaMaquinaria_Velocidades
        CHECK ((velocidad_prom_kmh IS NULL OR velocidad_prom_kmh >= 0)
           AND (velocidad_max_kmh  IS NULL OR velocidad_max_kmh  >= 0)
           AND (velocidad_prom_kmh IS NULL OR velocidad_max_kmh IS NULL
                OR velocidad_prom_kmh <= velocidad_max_kmh));
    PRINT '>>> CK_RutaMaquinaria_Velocidades creado.';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_RutaMaquinaria_Tiempos')
BEGIN
    ALTER TABLE dbo.CLI547_AGM_Ruta_maquinaria WITH NOCHECK
        ADD CONSTRAINT CK_RutaMaquinaria_Tiempos
        CHECK ((tiempo_trabajo_min IS NULL OR tiempo_trabajo_min >= 0)
           AND (tiempo_parado_min  IS NULL OR tiempo_parado_min  >= 0)
           AND (total_paradas      IS NULL OR total_paradas      >= 0)
           AND (total_puntos       IS NULL OR total_puntos       >= 0));
    PRINT '>>> CK_RutaMaquinaria_Tiempos creado.';
END
GO

PRINT '✅ CLI547_AGM_Ruta_maquinaria: columnas analytics y CHECKs aplicados.';
GO


-- #############################################################################
-- #  SECCIÓN 3 · TABLA NORMALIZADA DE SUBLOTES + BACKFILL
-- #############################################################################

-- =============================================================================
-- Tabla: CLI547_AGM_Ruta_maquinaria_Sublotes
-- Propósito: versión normalizada y consultable del JSON `sublotes_trabajados`
--            de CLI547_AGM_Ruta_maquinaria.
--
-- Por qué existe: el JSON [{sublote_id, nombre, minutos}] no se puede indexar
-- ni agregar sin parsearlo en cada consulta. Con esta tabla, preguntas como
-- "minutos trabajados por sublote en el mes" o "qué máquinas entraron al lote X"
-- son un GROUP BY normal.
--
-- El APK no cambia: el SP de sincronización llena esta tabla a partir del mismo
-- JSON que ya envía.
--
-- Depende de la SECCIÓN 1 (constraint UQ_CLI547_AGM_Ruta_registro). Idempotente.
-- =============================================================================

IF NOT EXISTS (
    SELECT 1 FROM sys.tables WHERE name = 'CLI547_AGM_Ruta_maquinaria_Sublotes'
)
BEGIN
    CREATE TABLE dbo.CLI547_AGM_Ruta_maquinaria_Sublotes (
        registro_id  UNIQUEIDENTIFIER NOT NULL,
        sublote_id   INT              NOT NULL,   -- id_erp del sublote (ERPHispatec Cultivos.Id)
        nombre       NVARCHAR(200)    NULL,       -- snapshot del nombre al momento de la jornada
        minutos      INT              NULL,       -- minutos de trabajo dentro de ese polígono

        CONSTRAINT PK_RutaMaquinariaSublotes
            PRIMARY KEY (registro_id, sublote_id),

        CONSTRAINT FK_RutaMaquinariaSublotes_Ruta
            FOREIGN KEY (registro_id)
            REFERENCES dbo.CLI547_AGM_Ruta_maquinaria(registro_id)
            ON DELETE CASCADE,

        CONSTRAINT CK_RutaMaquinariaSublotes_Minutos
            CHECK (minutos IS NULL OR minutos >= 0)
    );

    -- Reportes por lote: "todo lo trabajado en el sublote X"
    CREATE INDEX IX_RutaMaquinariaSublotes_Sublote
        ON dbo.CLI547_AGM_Ruta_maquinaria_Sublotes (sublote_id)
        INCLUDE (minutos);

    PRINT '>>> Tabla CLI547_AGM_Ruta_maquinaria_Sublotes creada correctamente.';
END
ELSE
BEGIN
    PRINT '>>> Tabla CLI547_AGM_Ruta_maquinaria_Sublotes ya existe — omitida.';
END
GO

-- =============================================================================
-- Backfill: poblar la tabla con el JSON ya guardado en jornadas anteriores.
-- Solo inserta lo que falta; se puede re-ejecutar sin duplicar.
-- =============================================================================
INSERT INTO dbo.CLI547_AGM_Ruta_maquinaria_Sublotes (registro_id, sublote_id, nombre, minutos)
SELECT
    r.registro_id,
    j.sublote_id,
    MAX(j.nombre)   AS nombre,
    SUM(j.minutos)  AS minutos
FROM dbo.CLI547_AGM_Ruta_maquinaria r
CROSS APPLY OPENJSON(r.sublotes_trabajados)
    WITH (
        sublote_id INT           '$.sublote_id',
        nombre     NVARCHAR(200) '$.nombre',
        minutos    INT           '$.minutos'
    ) AS j
WHERE r.sublotes_trabajados IS NOT NULL
  AND ISJSON(r.sublotes_trabajados) = 1
  AND j.sublote_id IS NOT NULL
  AND NOT EXISTS (
      SELECT 1 FROM dbo.CLI547_AGM_Ruta_maquinaria_Sublotes s
      WHERE s.registro_id = r.registro_id AND s.sublote_id = j.sublote_id
  )
GROUP BY r.registro_id, j.sublote_id;

PRINT '>>> Backfill de sublotes: ' + CAST(@@ROWCOUNT AS VARCHAR(10)) + ' fila(s) insertada(s).';
GO


-- #############################################################################
-- #  SECCIÓN 4 · SP DE SINCRONIZACIÓN DESDE EL APK
-- #############################################################################

-- =============================================================================
-- SP: CLI547_AGMSP_MMA_SINCRONIZAR_OFFLINE  — versión v3 (ruta WKT)
-- Cambios v3 respecto a v2:
--   + Declara @v_ruta_wkt (NVARCHAR) leído de $.ruta_wkt en el payload JSON
--   + Si @v_ruta_wkt es NULL (APK sin GPS o jornada sin puntos) → bloque
--     GPS omitido completamente; el resto del registro se guarda igual
--   + Si @v_ruta_wkt tiene valor → MERGE INTO CLI547_AGM_Ruta_maquinaria
--     con GEOGRAPHY::STGeomFromText (LINESTRING o POINT, SRID 4326)
--   + Bloque de puntos individuales (ruta_gps / CLI547_AGM_Punto_gps_maquinaria)
--     ELIMINADO — tabla v2 ya no existe en producción
--   + gps_sublotes se valida con ISJSON y se normaliza en
--     CLI547_AGM_Ruta_maquinaria_Sublotes
-- Depende de las SECCIONES 1 a 3 (tabla de rutas, columnas de analytics y
-- tabla normalizada de sublotes).
--
-- ─────────────────────────────────────────────────────────────────────────────
-- RETROCOMPATIBILIDAD — un APK viejo SIEMPRE debe poder sincronizar
-- ─────────────────────────────────────────────────────────────────────────────
-- El SP es dirigido por el payload: cada bloque opcional está detrás de un
-- IF @v_xxx IS NOT NULL. Si la clave no viene en el JSON, JSON_QUERY devuelve
-- NULL y el bloque entero se omite. Comportamiento por versión de APK:
--
--   APK sin gps_visitas/paradas/tramos → esos bloques se omiten; el registro,
--       la ruta y las analíticas se guardan igual.
--   APK sin ruta_wkt (anterior a v3)   → se omite TODO el bloque GPS; el
--       registro diario se guarda igual. La ruta no se captura, pero no falla.
--   APK que aún manda ruta_gps (v2)    → se ignora en silencio. El registro
--       sincroniza; la ruta de esa jornada no queda almacenada.
--
-- Edición por parte del supervisor: su dispositivo no tiene los puntos GPS del
-- operador, así que ruta_wkt llega NULL y el bloque GPS se salta completo. La
-- ruta y los eventos ya guardados NO se tocan. Los DELETE de eventos están
-- DENTRO de cada IF justamente por esto: un payload sin eventos no los borra.
--
-- REGLA DE ORO: las métricas GPS son datos secundarios. Ninguna puede abortar
-- la sincronización de la jornada. Por eso se sanean antes de escribir (ver el
-- bloque de saneamiento) en lugar de dejar que un CHECK reviente la
-- transacción — con XACT_ABORT ON eso haría perder la jornada completa.
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.CLI547_AGMSP_MMA_SINCRONIZAR_OFFLINE
    @p_payload      NVARCHAR(MAX),
    @p_success      BIT              OUTPUT,
    @p_mensaje      NVARCHAR(MAX)    OUTPUT,
    @p_registro_id  UNIQUEIDENTIFIER OUTPUT,
    @p_ya_existia   BIT              OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @v_numero VARCHAR(30), @v_fecha DATE, @v_turno VARCHAR(10), @v_tipo_registro VARCHAR(20),
            @v_proceso_id INT, @v_proceso_vehiculo VARCHAR(50),
            @v_subproceso_id INT, @v_subproceso_nombre NVARCHAR(200),
            @v_cultivo_id_erp INT, @v_nombre_cultivo_snapshot VARCHAR(150),
            @v_operador_id_erp INT, @v_nombre_operador_snapshot VARCHAR(300),
            @v_supervisor_id_erp INT, @v_nombre_supervisor_snapshot VARCHAR(300),
            @v_tractor_id_erp INT, @v_codigo_tractor_snapshot VARCHAR(100),
            @v_implemento_id_erp INT, @v_codigo_implemento_snapshot VARCHAR(100),
            @v_caja_cambios_id INT,
            @v_tractor_inicio DECIMAL(10,1), @v_tractor_final DECIMAL(10,1),
            @v_implemento_inicio DECIMAL(10,1), @v_implemento_final DECIMAL(10,1),
            @v_hora_salida_taller TIME, @v_hora_llegada_punto TIME,
            @v_hora_salida_punto TIME, @v_hora_llegada_taller TIME,
            @v_hora_refrigerio VARCHAR(30), @v_cantidad_tancadas INT,
            @v_observaciones_maq VARCHAR(MAX), @v_firma_operador NVARCHAR(MAX),
            @v_dispositivo_id VARCHAR(150),
            @v_created_by_erp INT, @v_id_json UNIQUEIDENTIFIER,
            @v_combustibles NVARCHAR(MAX), @v_paros NVARCHAR(MAX),
            @v_checklist NVARCHAR(MAX), @v_lotes NVARCHAR(MAX),
            @v_bines NVARCHAR(MAX), @v_sublabores NVARCHAR(MAX),
            @v_marchas NVARCHAR(MAX),
            @v_ruta_wkt NVARCHAR(MAX),  -- WKT LineString/Point (v3+). NULL = sin GPS → omitir
            -- Analytics GPS (v4+) — calculados en el APK desde los puntos locales
            @v_gps_km_trabajo        DECIMAL(10,3),
            @v_gps_km_traslado       DECIMAL(10,3),
            @v_gps_tiempo_trabajo_min INT,
            @v_gps_tiempo_parado_min  INT,
            @v_gps_vel_prom_kmh      DECIMAL(5,2),
            @v_gps_vel_max_kmh       DECIMAL(5,2),
            @v_gps_total_paradas     INT,
            @v_gps_eficiencia_pct    DECIMAL(5,2),
            @v_gps_sublotes          NVARCHAR(MAX),
            -- Eventos derivados en el APK (v5+) — ver SECCIÓN 7
            @v_gps_visitas           NVARCHAR(MAX),
            @v_gps_paradas           NVARCHAR(MAX),
            @v_gps_tramos            NVARCHAR(MAX);

    BEGIN TRY
        -- ── Extracción JSON ────────────────────────────────────────────────────
        SET @v_numero = JSON_VALUE(@p_payload, '$.numero_registro');
        SET @v_fecha = TRY_CAST(JSON_VALUE(@p_payload, '$.fecha') AS DATE);
        SET @v_turno = JSON_VALUE(@p_payload, '$.turno');
        SET @v_tipo_registro = COALESCE(JSON_VALUE(@p_payload, '$.tipo_registro'), 'tractor');
        SET @v_operador_id_erp = TRY_CAST(JSON_VALUE(@p_payload, '$.operador_id_erp') AS INT);
        SET @v_nombre_operador_snapshot = JSON_VALUE(@p_payload, '$.operador_nombre');
        SET @v_supervisor_id_erp = TRY_CAST(JSON_VALUE(@p_payload, '$.supervisor_id_erp') AS INT);
        SET @v_nombre_supervisor_snapshot = JSON_VALUE(@p_payload, '$.supervisor_nombre');
        SET @v_tractor_id_erp = TRY_CAST(JSON_VALUE(@p_payload, '$.tractor_id_erp') AS INT);
        SET @v_codigo_tractor_snapshot = JSON_VALUE(@p_payload, '$.tractor_codigo');
        SET @v_implemento_id_erp = TRY_CAST(JSON_VALUE(@p_payload, '$.implemento_id_erp') AS INT);
        SET @v_codigo_implemento_snapshot = JSON_VALUE(@p_payload, '$.implemento_codigo');
        SET @v_dispositivo_id = JSON_VALUE(@p_payload, '$.dispositivo_id');
        SET @v_created_by_erp = COALESCE(TRY_CAST(JSON_VALUE(@p_payload, '$.created_by_erp') AS INT), @v_operador_id_erp);
        SET @v_observaciones_maq = JSON_VALUE(@p_payload, '$.observaciones_maq');
        SELECT @v_firma_operador = value FROM OPENJSON(@p_payload) WHERE [key] = 'firma_operador';
        SET @v_cantidad_tancadas = TRY_CAST(JSON_VALUE(@p_payload, '$.cantidad_tancadas') AS INT);
        SET @v_id_json = TRY_CONVERT(UNIQUEIDENTIFIER, JSON_VALUE(@p_payload, '$.id'));

        SET @v_proceso_id = TRY_CAST(JSON_VALUE(@p_payload, '$.proceso_id') AS INT);
        SET @v_proceso_vehiculo = COALESCE(JSON_VALUE(@p_payload, '$.proceso_vehiculo'), JSON_VALUE(@p_payload, '$.proceso_nombre'));
        SET @v_cultivo_id_erp = TRY_CAST(JSON_VALUE(@p_payload, '$.cultivo_id_erp') AS INT);
        SET @v_nombre_cultivo_snapshot = COALESCE(JSON_VALUE(@p_payload, '$.cultivo_nombre'), JSON_VALUE(@p_payload, '$.cultivo_nombre_especie'));
        SET @v_caja_cambios_id = TRY_CAST(JSON_VALUE(@p_payload, '$.caja_cambios_id') AS INT);
        SET @v_subproceso_id = TRY_CAST(JSON_VALUE(@p_payload, '$.subproceso_id') AS INT);
        SET @v_subproceso_nombre = JSON_VALUE(@p_payload, '$.subproceso_nombre');

        IF @v_tipo_registro = 'vehiculo'
        BEGIN
            IF ISNULL(@v_proceso_id, 0) = 0 SET @v_proceso_id = NULL;
            SET @v_cultivo_id_erp = NULL;
        END

        SET @v_tractor_inicio = COALESCE(TRY_CAST(JSON_VALUE(@p_payload, '$.tractor_inicio') AS DECIMAL(10,1)), TRY_CAST(JSON_VALUE(@p_payload, '$.km_camion_inicio') AS DECIMAL(10,1)));
        SET @v_tractor_final = COALESCE(TRY_CAST(JSON_VALUE(@p_payload, '$.tractor_final') AS DECIMAL(10,1)), TRY_CAST(JSON_VALUE(@p_payload, '$.km_camion_final') AS DECIMAL(10,1)));
        SET @v_implemento_inicio = COALESCE(TRY_CAST(JSON_VALUE(@p_payload, '$.implemento_inicio') AS DECIMAL(10,1)), TRY_CAST(JSON_VALUE(@p_payload, '$.km_implemento_inicio') AS DECIMAL(10,1)));
        SET @v_implemento_final = COALESCE(TRY_CAST(JSON_VALUE(@p_payload, '$.implemento_final') AS DECIMAL(10,1)), TRY_CAST(JSON_VALUE(@p_payload, '$.km_implemento_final') AS DECIMAL(10,1)));

        SET @v_hora_salida_taller = COALESCE(TRY_CAST(JSON_VALUE(@p_payload, '$.hora_salida_taller') AS TIME), TRY_CAST(JSON_VALUE(@p_payload, '$.hora_salida_base_td') AS TIME));
        SET @v_hora_llegada_punto = COALESCE(TRY_CAST(JSON_VALUE(@p_payload, '$.hora_llegada_punto') AS TIME), TRY_CAST(JSON_VALUE(@p_payload, '$.hora_llegada_zona') AS TIME));
        SET @v_hora_salida_punto = COALESCE(TRY_CAST(JSON_VALUE(@p_payload, '$.hora_salida_punto') AS TIME), TRY_CAST(JSON_VALUE(@p_payload, '$.hora_retorno_base') AS TIME));
        SET @v_hora_llegada_taller = TRY_CAST(JSON_VALUE(@p_payload, '$.hora_llegada_taller') AS TIME);
        SET @v_hora_refrigerio = NULLIF(LTRIM(RTRIM(JSON_VALUE(@p_payload, '$.hora_refrigerio'))), '');
        IF @v_hora_refrigerio = '-' SET @v_hora_refrigerio = NULL;

        SET @v_combustibles = JSON_QUERY(@p_payload, '$.combustibles');
        SET @v_paros        = JSON_QUERY(@p_payload, '$.paros');
        SET @v_checklist    = JSON_QUERY(@p_payload, '$.checklist');
        SET @v_lotes        = JSON_QUERY(@p_payload, '$.lotes');
        SET @v_bines        = JSON_QUERY(@p_payload, '$.bines');
        SET @v_sublabores   = JSON_QUERY(@p_payload, '$.sublabores');
        SET @v_marchas      = JSON_QUERY(@p_payload, '$.marchas');
        -- ruta_wkt: LINESTRING o POINT en WKT. NULL cuando APK sin GPS o jornada
        -- sin puntos grabados → el bloque GPS se omite y no se inserta nada.
        -- JSON_VALUE limita el resultado a 4000 caracteres; una ruta normal
        -- puede superar ese tamaño. OPENJSON con NVARCHAR(MAX) conserva todo el WKT.
        SELECT @v_ruta_wkt = NULLIF(LTRIM(RTRIM(ruta_wkt)), '')
        FROM OPENJSON(@p_payload)
        WITH (ruta_wkt NVARCHAR(MAX) '$.ruta_wkt');
        -- Analytics GPS (v4+) — calculados en el APK desde los puntos locales
        SET @v_gps_km_trabajo         = TRY_CAST(JSON_VALUE(@p_payload, '$.gps_km_trabajo')         AS DECIMAL(10,3));
        SET @v_gps_km_traslado        = TRY_CAST(JSON_VALUE(@p_payload, '$.gps_km_traslado')        AS DECIMAL(10,3));
        SET @v_gps_tiempo_trabajo_min = TRY_CAST(JSON_VALUE(@p_payload, '$.gps_tiempo_trabajo_min') AS INT);
        SET @v_gps_tiempo_parado_min  = TRY_CAST(JSON_VALUE(@p_payload, '$.gps_tiempo_parado_min')  AS INT);
        SET @v_gps_vel_prom_kmh       = TRY_CAST(JSON_VALUE(@p_payload, '$.gps_velocidad_prom_kmh') AS DECIMAL(5,2));
        SET @v_gps_vel_max_kmh        = TRY_CAST(JSON_VALUE(@p_payload, '$.gps_velocidad_max_kmh')  AS DECIMAL(5,2));
        SET @v_gps_total_paradas      = TRY_CAST(JSON_VALUE(@p_payload, '$.gps_total_paradas')      AS INT);
        SET @v_gps_eficiencia_pct     = TRY_CAST(JSON_VALUE(@p_payload, '$.gps_eficiencia_pct')     AS DECIMAL(5,2));
        SET @v_gps_sublotes           = JSON_QUERY(@p_payload, '$.gps_sublotes');
        -- Mismo criterio que el resto de campos JSON del SP: si llega mal formado
        -- se descarta, para no guardar basura que rompa a los consumidores.
        IF @v_gps_sublotes IS NOT NULL AND ISJSON(@v_gps_sublotes) = 0
            SET @v_gps_sublotes = NULL;

        -- Eventos derivados (v5+). Cada uno se descarta por separado si llega
        -- mal formado: un array corrupto no debe impedir guardar los otros.
        SET @v_gps_visitas = JSON_QUERY(@p_payload, '$.gps_visitas');
        IF @v_gps_visitas IS NOT NULL AND ISJSON(@v_gps_visitas) = 0 SET @v_gps_visitas = NULL;
        SET @v_gps_paradas = JSON_QUERY(@p_payload, '$.gps_paradas');
        IF @v_gps_paradas IS NOT NULL AND ISJSON(@v_gps_paradas) = 0 SET @v_gps_paradas = NULL;
        SET @v_gps_tramos  = JSON_QUERY(@p_payload, '$.gps_tramos');
        IF @v_gps_tramos  IS NOT NULL AND ISJSON(@v_gps_tramos)  = 0 SET @v_gps_tramos  = NULL;

        -- ── Saneamiento de métricas GPS ───────────────────────────────────────
        -- REGLA: una métrica de analítica NUNCA debe impedir que la jornada
        -- sincronice. Si un valor viene fuera de rango (APK de otra versión,
        -- error de cálculo en campo), se descarta ESE valor, no el registro.
        --
        -- Sin esto, un CHECK violado aborta la transacción completa por
        -- XACT_ABORT ON y el operador pierde la jornada entera.
        -- Los CHECK de la tabla quedan como última barrera para escrituras
        -- manuales, no como validador del payload.
        --
        -- Comparar contra NULL da NULL, así que los IF no se disparan cuando la
        -- métrica no vino: los campos ausentes quedan intactos.
        IF @v_gps_km_trabajo         < 0 SET @v_gps_km_trabajo         = NULL;
        IF @v_gps_km_traslado        < 0 SET @v_gps_km_traslado        = NULL;
        IF @v_gps_tiempo_trabajo_min < 0 SET @v_gps_tiempo_trabajo_min = NULL;
        IF @v_gps_tiempo_parado_min  < 0 SET @v_gps_tiempo_parado_min  = NULL;
        IF @v_gps_total_paradas      < 0 SET @v_gps_total_paradas      = NULL;
        IF @v_gps_vel_prom_kmh       < 0 SET @v_gps_vel_prom_kmh       = NULL;
        IF @v_gps_vel_max_kmh        < 0 SET @v_gps_vel_max_kmh        = NULL;
        IF @v_gps_eficiencia_pct < 0 OR @v_gps_eficiencia_pct > 100
            SET @v_gps_eficiencia_pct = NULL;
        -- El CHECK exige prom <= max. Si una versión del APK las calculó con
        -- criterios distintos, se eleva el máximo en vez de rechazar la fila.
        IF @v_gps_vel_prom_kmh IS NOT NULL AND @v_gps_vel_max_kmh IS NOT NULL
           AND @v_gps_vel_prom_kmh > @v_gps_vel_max_kmh
            SET @v_gps_vel_max_kmh = @v_gps_vel_prom_kmh;

        -- ── Validaciones obligatorias ──────────────────────────────────────────
        IF @v_numero IS NULL THROW 50000, 'numero_registro es obligatorio', 1;
        IF @v_fecha IS NULL THROW 50001, 'fecha es obligatoria y debe ser una fecha válida (yyyy-MM-dd)', 1;
        IF @v_operador_id_erp IS NULL THROW 50002, 'operador_id_erp es obligatorio', 1;
        IF @v_tractor_id_erp IS NULL THROW 50003, 'tractor_id_erp es obligatorio', 1;
        IF @v_turno NOT IN ('dia', 'noche') THROW 50004, 'turno debe ser ''dia'' o ''noche''', 1;
        IF @v_created_by_erp IS NULL THROW 50005, 'created_by_erp es obligatorio', 1;

        BEGIN TRANSACTION;

        -- ── Buscar registro existente ──────────────────────────────────────────
        SET @p_registro_id = NULL;
        IF @v_id_json IS NOT NULL
            SELECT @p_registro_id = id
            FROM CLI547_AGM_MMA_REGISTROS_DIARIOS
            WHERE id = @v_id_json;

        IF @p_registro_id IS NULL
            SELECT @p_registro_id = id
            FROM CLI547_AGM_MMA_REGISTROS_DIARIOS
            WHERE numero_registro = @v_numero
              AND operador_id_erp = @v_operador_id_erp;

        -- ── INSERT o UPDATE del registro principal ─────────────────────────────
        IF @p_registro_id IS NOT NULL
        BEGIN
            UPDATE CLI547_AGM_MMA_REGISTROS_DIARIOS
            SET fecha = @v_fecha,
                turno = @v_turno,
                proceso_id = @v_proceso_id,
                proceso_vehiculo = @v_proceso_vehiculo,
                subproceso_id = @v_subproceso_id,
                subproceso_nombre = @v_subproceso_nombre,
                cultivo_id_erp = @v_cultivo_id_erp,
                nombre_cultivo_snapshot = @v_nombre_cultivo_snapshot,
                operador_id_erp = @v_operador_id_erp,
                nombre_operador_snapshot = @v_nombre_operador_snapshot,
                supervisor_id_erp = @v_supervisor_id_erp,
                nombre_supervisor_snapshot = @v_nombre_supervisor_snapshot,
                tractor_id_erp = @v_tractor_id_erp,
                codigo_tractor_snapshot = @v_codigo_tractor_snapshot,
                implemento_id_erp = @v_implemento_id_erp,
                codigo_implemento_snapshot = @v_codigo_implemento_snapshot,
                caja_cambios_id = @v_caja_cambios_id,
                observaciones_maq = @v_observaciones_maq,
                firma_operador = ISNULL(@v_firma_operador, firma_operador),
                cantidad_tancadas = @v_cantidad_tancadas,
                dispositivo_id = @v_dispositivo_id,
                sincronizado_erp = 1,
                sincronizado_at = GETDATE(),
                updated_at = GETDATE()
            WHERE id = @p_registro_id;
            SET @p_ya_existia = 1;
        END
        ELSE
        BEGIN
            SET @p_registro_id = COALESCE(@v_id_json, NEWID());
            INSERT INTO CLI547_AGM_MMA_REGISTROS_DIARIOS (
                id, numero_registro, fecha, turno, tipo_registro,
                proceso_id, proceso_vehiculo, subproceso_id, subproceso_nombre,
                cultivo_id_erp, nombre_cultivo_snapshot,
                operador_id_erp, nombre_operador_snapshot,
                supervisor_id_erp, nombre_supervisor_snapshot,
                tractor_id_erp, codigo_tractor_snapshot,
                implemento_id_erp, codigo_implemento_snapshot,
                caja_cambios_id,
                observaciones_maq, firma_operador, cantidad_tancadas,
                estado, dispositivo_id,
                sincronizado_erp, sincronizado_at, created_by_erp
            ) VALUES (
                @p_registro_id, @v_numero, @v_fecha, @v_turno, @v_tipo_registro,
                @v_proceso_id, @v_proceso_vehiculo, @v_subproceso_id, @v_subproceso_nombre,
                @v_cultivo_id_erp, @v_nombre_cultivo_snapshot,
                @v_operador_id_erp, @v_nombre_operador_snapshot,
                @v_supervisor_id_erp, @v_nombre_supervisor_snapshot,
                @v_tractor_id_erp, @v_codigo_tractor_snapshot,
                @v_implemento_id_erp, @v_codigo_implemento_snapshot,
                @v_caja_cambios_id,
                @v_observaciones_maq, @v_firma_operador, @v_cantidad_tancadas,
                'borrador', @v_dispositivo_id,
                1, GETDATE(), @v_created_by_erp
            );
            SET @p_ya_existia = 0;
        END

        -- ── Horómetros — HOLDLOCK evita race condition ─────────────────────────
        MERGE CLI547_AGM_MMA_HOROMETROS WITH (HOLDLOCK) AS target
        USING (SELECT @p_registro_id AS rid) AS source ON target.registro_id = source.rid
        WHEN MATCHED THEN UPDATE SET
            tractor_inicio    = COALESCE(@v_tractor_inicio,    target.tractor_inicio),
            tractor_final     = COALESCE(@v_tractor_final,     target.tractor_final),
            implemento_inicio = COALESCE(@v_implemento_inicio, target.implemento_inicio),
            implemento_final  = COALESCE(@v_implemento_final,  target.implemento_final),
            updated_at = GETDATE()
        WHEN NOT MATCHED THEN
            INSERT (registro_id, tractor_inicio, tractor_final, implemento_inicio, implemento_final)
            VALUES (@p_registro_id, @v_tractor_inicio, @v_tractor_final, @v_implemento_inicio, @v_implemento_final);

        -- ── Tiempos turno — HOLDLOCK ───────────────────────────────────────────
        MERGE CLI547_AGM_MMA_TIEMPOS_TURNO WITH (HOLDLOCK) AS target
        USING (SELECT @p_registro_id AS rid) AS source ON target.registro_id = source.rid
        WHEN MATCHED THEN UPDATE SET
            hora_salida_taller  = COALESCE(@v_hora_salida_taller,  target.hora_salida_taller),
            hora_llegada_punto  = COALESCE(@v_hora_llegada_punto,  target.hora_llegada_punto),
            hora_salida_punto   = COALESCE(@v_hora_salida_punto,   target.hora_salida_punto),
            hora_llegada_taller = COALESCE(@v_hora_llegada_taller, target.hora_llegada_taller),
            hora_refrigerio     = COALESCE(@v_hora_refrigerio,     target.hora_refrigerio),
            updated_at = GETDATE()
        WHEN NOT MATCHED THEN
            INSERT (registro_id, hora_salida_taller, hora_llegada_punto, hora_salida_punto, hora_llegada_taller, hora_refrigerio)
            VALUES (@p_registro_id, @v_hora_salida_taller, @v_hora_llegada_punto, @v_hora_salida_punto, @v_hora_llegada_taller, @v_hora_refrigerio);

        -- ── Checklist ──────────────────────────────────────────────────────────
        IF @v_checklist IS NOT NULL AND ISJSON(@v_checklist) = 1
        BEGIN
            DELETE FROM CLI547_AGM_MMA_CHECKLIST_RESULTADOS WHERE registro_id = @p_registro_id;
            ;WITH ChecklistDedup AS (
                SELECT item_id, resultado, observacion, foto_url,
                       ROW_NUMBER() OVER (PARTITION BY item_id ORDER BY (SELECT NULL)) AS rn
                FROM OPENJSON(@v_checklist)
                WITH (item_id INT '$.item_id', resultado VARCHAR(4) '$.resultado',
                      observacion NVARCHAR(MAX) '$.observacion', foto_url NVARCHAR(MAX) '$.foto_url')
            )
            INSERT INTO CLI547_AGM_MMA_CHECKLIST_RESULTADOS (id, registro_id, item_id, resultado, observacion, foto_url)
            SELECT NEWID(), @p_registro_id, item_id, resultado, observacion, foto_url
            FROM ChecklistDedup WHERE rn = 1;
        END

        -- ── Paros ──────────────────────────────────────────────────────────────
        IF @v_paros IS NOT NULL AND ISJSON(@v_paros) = 1
        BEGIN
            IF @v_tipo_registro = 'tractor'
            BEGIN
                DELETE FROM CLI547_AGM_MMA_PAROS_EQUIPOS WHERE registro_id = @p_registro_id;
                INSERT INTO CLI547_AGM_MMA_PAROS_EQUIPOS
                    (id, registro_id, tipo_paro_id, motivo, equipo, hora_inicio, hora_final, galones, falla_mecanica_id, falla_mecanica_nombre)
                SELECT
                    COALESCE(TRY_CAST(JSON_VALUE(value, '$.id') AS UNIQUEIDENTIFIER), NEWID()),
                    @p_registro_id,
                    TRY_CAST(JSON_VALUE(value, '$.tipo_paro_id') AS INT),
                    JSON_VALUE(value, '$.motivo'),
                    JSON_VALUE(value, '$.equipo'),
                    TRY_CAST(JSON_VALUE(value, '$.hora_inicio') AS TIME),
                    TRY_CAST(JSON_VALUE(value, '$.hora_final')  AS TIME),
                    TRY_CAST(JSON_VALUE(value, '$.galones')     AS DECIMAL(8,2)),
                    TRY_CAST(JSON_VALUE(value, '$.falla_mecanica_id')  AS INT),
                    JSON_VALUE(value, '$.falla_mecanica_nombre')
                FROM OPENJSON(@v_paros);
            END
            ELSE IF @v_tipo_registro = 'vehiculo'
            BEGIN
                DELETE FROM CLI547_AGM_MMA_PAROS_VEHICULO WHERE registro_id = @p_registro_id;
                INSERT INTO CLI547_AGM_MMA_PAROS_VEHICULO (registro_id, motivo, hora_inicio, hora_final)
                SELECT @p_registro_id,
                       JSON_VALUE(value, '$.motivo'),
                       TRY_CAST(JSON_VALUE(value, '$.hora_inicio') AS TIME),
                       TRY_CAST(JSON_VALUE(value, '$.hora_final')  AS TIME)
                FROM OPENJSON(@v_paros);
            END
        END

        -- ── Lotes — HOLDLOCK en MERGE ──────────────────────────────────────────
        IF @v_tipo_registro = 'tractor'
        BEGIN
            IF @v_lotes IS NOT NULL AND ISJSON(@v_lotes) = 1
            BEGIN
                ;WITH src AS (
                    SELECT
                        TRY_CAST(JSON_VALUE(value, '$.lote_id_erp')       AS INT)          AS lote_id_erp,
                        TRY_CAST(JSON_VALUE(value, '$.finca_id_erp')      AS INT)          AS finca_id_erp,
                        COALESCE(JSON_VALUE(value, '$.lote_codigo_snapshot'),
                                 JSON_VALUE(value, '$.lote_codigo'))                        AS lote_codigo_snapshot,
                        COALESCE(JSON_VALUE(value, '$.sublote_snapshot'),
                                 JSON_VALUE(value, '$.sublote'))                            AS sublote_snapshot,
                        TRY_CAST(JSON_VALUE(value, '$.area_trabajada_ha') AS DECIMAL(8,4)) AS area_trabajada_ha,
                        JSON_VALUE(value, '$.observacion')                                  AS observacion
                    FROM OPENJSON(@v_lotes)
                    WHERE TRY_CAST(JSON_VALUE(value, '$.lote_id_erp') AS INT) IS NOT NULL
                )
                MERGE INTO CLI547_AGM_MMA_REGISTROS_LOTES WITH (HOLDLOCK) AS target
                USING src ON target.registro_id = @p_registro_id
                          AND target.lote_id_erp = src.lote_id_erp
                WHEN MATCHED THEN UPDATE SET
                    finca_id_erp         = COALESCE(src.finca_id_erp, target.finca_id_erp),
                    lote_codigo_snapshot = COALESCE(src.lote_codigo_snapshot, target.lote_codigo_snapshot),
                    sublote_snapshot     = COALESCE(src.sublote_snapshot, target.sublote_snapshot),
                    area_trabajada_ha    = src.area_trabajada_ha,
                    observacion          = src.observacion
                WHEN NOT MATCHED BY TARGET AND src.finca_id_erp IS NOT NULL THEN
                    INSERT (id, registro_id, lote_id_erp, finca_id_erp, lote_codigo_snapshot, sublote_snapshot, area_trabajada_ha, observacion)
                    VALUES (NEWID(), @p_registro_id, src.lote_id_erp, src.finca_id_erp,
                            src.lote_codigo_snapshot, src.sublote_snapshot, src.area_trabajada_ha, src.observacion)
                WHEN NOT MATCHED BY SOURCE AND target.registro_id = @p_registro_id THEN DELETE;
            END

            IF @v_bines IS NOT NULL AND ISJSON(@v_bines) = 1
            BEGIN
                DELETE FROM CLI547_AGM_MMA_COSECHA_BINES WHERE registro_id = @p_registro_id;
                INSERT INTO CLI547_AGM_MMA_COSECHA_BINES (id, registro_id, franja_horaria, turno_franja, cantidad)
                SELECT NEWID(), @p_registro_id,
                       JSON_VALUE(value, '$.franja_horaria'), JSON_VALUE(value, '$.turno_franja'),
                       TRY_CAST(JSON_VALUE(value, '$.cantidad') AS SMALLINT)
                FROM OPENJSON(@v_bines);
            END

            IF @v_sublabores IS NOT NULL AND ISJSON(@v_sublabores) = 1
            BEGIN
                DELETE FROM CLI547_AGM_MMA_REGISTROS_SUBLABORES WHERE registro_id = @p_registro_id;
                INSERT INTO CLI547_AGM_MMA_REGISTROS_SUBLABORES (registro_id, sublabor_nombre)
                SELECT @p_registro_id, JSON_VALUE(value, '$.sublabor_nombre')
                FROM OPENJSON(@v_sublabores) WHERE JSON_VALUE(value, '$.sublabor_nombre') IS NOT NULL;
            END

            IF @v_marchas IS NOT NULL AND ISJSON(@v_marchas) = 1
            BEGIN
                DELETE FROM CLI547_AGM_MMA_REGISTROS_MARCHAS WHERE registro_id = @p_registro_id;
                INSERT INTO CLI547_AGM_MMA_REGISTROS_MARCHAS (registro_id, marcha_codigo, horas_uso)
                SELECT @p_registro_id,
                       JSON_VALUE(value, '$.marcha_codigo'),
                       TRY_CAST(JSON_VALUE(value, '$.horas_uso') AS DECIMAL(6,2))
                FROM OPENJSON(@v_marchas) WHERE JSON_VALUE(value, '$.marcha_codigo') IS NOT NULL;
            END
        END

        -- ── Ruta GPS v3 — WKT → GEOGRAPHY (una fila por jornada) ──────────────
        -- Condición de entrada: @v_ruta_wkt debe ser no-nulo y tener al menos
        -- "POINT(x y)" que son 10+ caracteres. Si el APK no envía ruta_wkt
        -- (campo ausente en el JSON o jornada sin puntos GPS grabados) esta
        -- variable queda NULL y el bloque entero se salta → nada se inserta
        -- en CLI547_AGM_Ruta_maquinaria, el registro se guarda igual.
        IF @v_ruta_wkt IS NOT NULL AND LEN(@v_ruta_wkt) > 10
        BEGIN
            DECLARE @v_geog      GEOGRAPHY;
            DECLARE @v_n_puntos  INT;
            DECLARE @v_long_km   DECIMAL(10,3);

            -- Parseo tolerante: si el WKT está mal formado no rompe la transacción
            BEGIN TRY
                SET @v_geog     = GEOGRAPHY::STGeomFromText(@v_ruta_wkt, 4326);
                SET @v_n_puntos = @v_geog.STNumPoints();
                SET @v_long_km  = CAST(@v_geog.STLength() / 1000.0 AS DECIMAL(10,3));
            END TRY
            BEGIN CATCH
                SET @v_geog     = NULL;
                SET @v_n_puntos = NULL;
                SET @v_long_km  = NULL;
            END CATCH;

            MERGE INTO dbo.CLI547_AGM_Ruta_maquinaria WITH (HOLDLOCK) AS target
            USING (SELECT @p_registro_id AS registro_id) AS src
                ON target.registro_id = src.registro_id
            WHEN MATCHED THEN UPDATE SET
                ruta_geog            = ISNULL(@v_geog,     target.ruta_geog),
                total_puntos         = ISNULL(@v_n_puntos, target.total_puntos),
                longitud_km          = ISNULL(@v_long_km,  target.longitud_km),
                operador_id_erp      = @v_operador_id_erp,
                fecha                = @v_fecha,
                tractor_id_erp       = @v_tractor_id_erp,
                proceso_id           = @v_proceso_id,
                -- Analytics GPS (v4+): COALESCE para no pisar un valor ya existente con NULL
                km_trabajo           = COALESCE(@v_gps_km_trabajo,         target.km_trabajo),
                km_traslado          = COALESCE(@v_gps_km_traslado,        target.km_traslado),
                tiempo_trabajo_min   = COALESCE(@v_gps_tiempo_trabajo_min, target.tiempo_trabajo_min),
                tiempo_parado_min    = COALESCE(@v_gps_tiempo_parado_min,  target.tiempo_parado_min),
                velocidad_prom_kmh   = COALESCE(@v_gps_vel_prom_kmh,       target.velocidad_prom_kmh),
                velocidad_max_kmh    = COALESCE(@v_gps_vel_max_kmh,        target.velocidad_max_kmh),
                total_paradas        = COALESCE(@v_gps_total_paradas,      target.total_paradas),
                eficiencia_pct       = COALESCE(@v_gps_eficiencia_pct,     target.eficiencia_pct),
                sublotes_trabajados  = COALESCE(@v_gps_sublotes,           target.sublotes_trabajados),
                sincronizado_at      = SYSUTCDATETIME()
            WHEN NOT MATCHED THEN INSERT (
                registro_id, ruta_geog, total_puntos, longitud_km,
                operador_id_erp, fecha, tractor_id_erp, proceso_id,
                km_trabajo, km_traslado, tiempo_trabajo_min, tiempo_parado_min,
                velocidad_prom_kmh, velocidad_max_kmh, total_paradas, eficiencia_pct,
                sublotes_trabajados
            ) VALUES (
                @p_registro_id, @v_geog, @v_n_puntos, @v_long_km,
                @v_operador_id_erp, @v_fecha, @v_tractor_id_erp, @v_proceso_id,
                @v_gps_km_trabajo, @v_gps_km_traslado, @v_gps_tiempo_trabajo_min, @v_gps_tiempo_parado_min,
                @v_gps_vel_prom_kmh, @v_gps_vel_max_kmh, @v_gps_total_paradas, @v_gps_eficiencia_pct,
                @v_gps_sublotes
            );

            -- Sublotes trabajados → tabla normalizada (consultable y agregable).
            -- El JSON crudo se conserva en sublotes_trabajados para auditoría.
            -- Va después del MERGE: el FK exige que exista la fila padre.
            IF @v_gps_sublotes IS NOT NULL
            BEGIN
                DELETE FROM dbo.CLI547_AGM_Ruta_maquinaria_Sublotes
                WHERE registro_id = @p_registro_id;

                INSERT INTO dbo.CLI547_AGM_Ruta_maquinaria_Sublotes
                    (registro_id, sublote_id, nombre, minutos)
                SELECT @p_registro_id, j.sublote_id, MAX(j.nombre),
                       CASE WHEN SUM(j.minutos) >= 0 THEN SUM(j.minutos) END
                FROM OPENJSON(@v_gps_sublotes)
                    WITH (
                        sublote_id INT           '$.sublote_id',
                        nombre     NVARCHAR(200) '$.nombre',
                        minutos    INT           '$.minutos'
                    ) AS j
                WHERE j.sublote_id IS NOT NULL
                GROUP BY j.sublote_id;
            END

            -- ── Eventos derivados (v5+) ───────────────────────────────────────
            -- Todos van DELETE + INSERT por registro: una re-sincronización
            -- reemplaza los eventos anteriores en vez de duplicarlos.
            --
            -- Las marcas de tiempo llegan como epoch ms (UTC) y se convierten a
            -- DATETIME2. Las geometrías se filtran por prefijo en vez de usar
            -- TRY/CATCH: con XACT_ABORT ON un error capturado deja la
            -- transacción en estado no confirmable, así que conviene no
            -- provocarlo. El APK genera el WKT de forma determinista.

            IF @v_gps_visitas IS NOT NULL
            BEGIN
                DELETE FROM dbo.CLI547_AGM_Ruta_visitas_sublote WHERE registro_id = @p_registro_id;

                INSERT INTO dbo.CLI547_AGM_Ruta_visitas_sublote
                    (registro_id, sublote_id, nombre, entrada_at, salida_at,
                     minutos, km, vel_prom_kmh, vel_max_kmh, puntos)
                SELECT @p_registro_id, j.sublote_id, NULLIF(j.nombre, ''),
                       DATEADD(SECOND, j.entrada_at / 1000, CAST('1970-01-01' AS DATETIME2(0))),
                       DATEADD(SECOND, j.salida_at  / 1000, CAST('1970-01-01' AS DATETIME2(0))),
                       -- Saneamiento: valores negativos van a NULL en vez de
                       -- violar el CHECK y tumbar toda la sincronización.
                       CASE WHEN j.minutos >= 0 THEN j.minutos END,
                       CASE WHEN j.km      >= 0 THEN j.km      END,
                       CASE WHEN j.vel_prom_kmh >= 0 THEN j.vel_prom_kmh END,
                       CASE WHEN j.vel_max_kmh  >= 0 THEN j.vel_max_kmh  END,
                       j.puntos
                FROM OPENJSON(@v_gps_visitas)
                    WITH (
                        sublote_id   INT           '$.sublote_id',
                        nombre       NVARCHAR(200) '$.nombre',
                        entrada_at   BIGINT        '$.entrada_at',
                        salida_at    BIGINT        '$.salida_at',
                        minutos      INT           '$.minutos',
                        km           DECIMAL(10,3) '$.km',
                        vel_prom_kmh DECIMAL(5,2)  '$.vel_prom_kmh',
                        vel_max_kmh  DECIMAL(5,2)  '$.vel_max_kmh',
                        puntos       INT           '$.puntos'
                    ) AS j
                WHERE j.sublote_id IS NOT NULL
                  AND j.entrada_at IS NOT NULL AND j.salida_at IS NOT NULL
                  AND j.salida_at >= j.entrada_at;
            END

            IF @v_gps_paradas IS NOT NULL
            BEGIN
                DELETE FROM dbo.CLI547_AGM_Ruta_paradas WHERE registro_id = @p_registro_id;

                INSERT INTO dbo.CLI547_AGM_Ruta_paradas
                    (registro_id, orden, latitud, longitud, punto, inicio_at, fin_at, minutos, sublote_id)
                SELECT @p_registro_id, j.orden, j.latitud, j.longitud,
                       geography::Point(j.latitud, j.longitud, 4326),
                       DATEADD(SECOND, j.inicio_at / 1000, CAST('1970-01-01' AS DATETIME2(0))),
                       DATEADD(SECOND, j.fin_at    / 1000, CAST('1970-01-01' AS DATETIME2(0))),
                       CASE WHEN j.minutos >= 0 THEN j.minutos END, j.sublote_id
                FROM OPENJSON(@v_gps_paradas)
                    WITH (
                        orden      INT    '$.orden',
                        latitud    FLOAT  '$.lat',
                        longitud   FLOAT  '$.lon',
                        inicio_at  BIGINT '$.inicio_at',
                        fin_at     BIGINT '$.fin_at',
                        minutos    INT    '$.minutos',
                        sublote_id INT    '$.sublote_id'
                    ) AS j
                WHERE j.orden IS NOT NULL
                  AND j.latitud  BETWEEN  -90 AND  90
                  AND j.longitud BETWEEN -180 AND 180
                  AND j.inicio_at IS NOT NULL AND j.fin_at IS NOT NULL
                  AND j.fin_at >= j.inicio_at;
            END

            IF @v_gps_tramos IS NOT NULL
            BEGIN
                DELETE FROM dbo.CLI547_AGM_Ruta_tramos WHERE registro_id = @p_registro_id;

                INSERT INTO dbo.CLI547_AGM_Ruta_tramos
                    (registro_id, orden, tipo, geom, inicio_at, fin_at,
                     minutos, km, vel_prom_kmh, vel_max_kmh, puntos, sublote_id)
                SELECT @p_registro_id, j.orden, j.tipo,
                       geography::STGeomFromText(j.wkt, 4326),
                       DATEADD(SECOND, j.inicio_at / 1000, CAST('1970-01-01' AS DATETIME2(0))),
                       DATEADD(SECOND, j.fin_at    / 1000, CAST('1970-01-01' AS DATETIME2(0))),
                       j.minutos, j.km, j.vel_prom_kmh, j.vel_max_kmh, j.puntos, j.sublote_id
                FROM OPENJSON(@v_gps_tramos)
                    WITH (
                        orden        INT            '$.orden',
                        tipo         VARCHAR(10)    '$.tipo',
                        wkt          NVARCHAR(MAX)  '$.wkt',
                        inicio_at    BIGINT         '$.inicio_at',
                        fin_at       BIGINT         '$.fin_at',
                        minutos      INT            '$.minutos',
                        km           DECIMAL(10,3)  '$.km',
                        vel_prom_kmh DECIMAL(5,2)   '$.vel_prom_kmh',
                        vel_max_kmh  DECIMAL(5,2)   '$.vel_max_kmh',
                        puntos       INT            '$.puntos',
                        sublote_id   INT            '$.sublote_id'
                    ) AS j
                WHERE j.orden IS NOT NULL
                  AND j.tipo IN ('TRABAJO','TRASLADO','PARADO')
                  AND j.inicio_at IS NOT NULL AND j.fin_at IS NOT NULL
                  AND j.fin_at >= j.inicio_at
                  AND (j.wkt LIKE 'LINESTRING%' OR j.wkt LIKE 'POINT%')
                  AND LEN(j.wkt) > 10;
            END
        END
        -- Si @v_ruta_wkt es NULL → bloque GPS omitido, registro guardado igual

        -- ── Combustible vehículo ───────────────────────────────────────────────
        IF @v_tipo_registro = 'vehiculo' AND @v_combustibles IS NOT NULL AND ISJSON(@v_combustibles) = 1
        BEGIN
            DELETE FROM CLI547_AGM_MMA_COMBUSTIBLE_VEHICULO WHERE registro_id = @p_registro_id;
            INSERT INTO CLI547_AGM_MMA_COMBUSTIBLE_VEHICULO (registro_id, glns, hora_inicio, hora_final)
            SELECT @p_registro_id,
                   TRY_CAST(JSON_VALUE(value, '$.glns')        AS DECIMAL(10,2)),
                   TRY_CAST(JSON_VALUE(value, '$.hora_inicio') AS TIME),
                   TRY_CAST(JSON_VALUE(value, '$.hora_final')  AS TIME)
            FROM OPENJSON(@v_combustibles);
        END

        -- ── Cierre de turno ────────────────────────────────────────────────────
        IF @v_tractor_final IS NOT NULL OR @v_hora_salida_punto IS NOT NULL
        BEGIN
            UPDATE CLI547_AGM_MMA_REGISTROS_DIARIOS
            SET estado = CASE
                            WHEN estado IN ('aprobado', 'rechazado') THEN estado
                            ELSE 'completado'
                         END,
                observaciones_maq = COALESCE(@v_observaciones_maq, observaciones_maq),
                updated_at = GETDATE()
            WHERE id = @p_registro_id;
        END

        COMMIT TRANSACTION;

        SET @p_success = 1;
        SET @p_mensaje = CASE @p_ya_existia
                            WHEN 1 THEN 'Registro actualizado exitosamente.'
                            ELSE        'Registro insertado exitosamente.'
                         END;
        SELECT
            @p_success                           AS success,
            @p_mensaje                           AS mensaje,
            CAST(@p_registro_id AS NVARCHAR(36)) AS registro_id,
            @p_ya_existia                        AS ya_existia;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        SET @p_success    = 0;
        SET @p_mensaje    = 'Error [' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + ']: ' + ERROR_MESSAGE();
        SET @p_registro_id = NULL;
        SET @p_ya_existia  = 0;
        SELECT
            @p_success        AS success,
            @p_mensaje        AS mensaje,
            NULL              AS registro_id,
            CAST(0 AS BIT)    AS ya_existia;
    END CATCH
END;
GO

PRINT '✅ CLI547_AGMSP_MMA_SINCRONIZAR_OFFLINE v3 actualizado.';
PRINT '   ruta_wkt = NULL  → bloque GPS omitido (APK sin rutas = OK)';
PRINT '   ruta_wkt = WKT   → MERGE en CLI547_AGM_Ruta_maquinaria';
GO


-- #############################################################################
-- #  SECCIÓN 5 · SPs DE CONSULTA PARA MAPA Y EXPORTACIÓN KML
-- #############################################################################

-- =============================================================================
-- SPs de consulta y exportación de rutas de maquinaria (modelo v3)
--
--   1. CLI547_AGMSP_MMA_GET_RUTAS_MAQUINARIA  → datos para pintar el mapa
--   2. CLI547_AGMSP_MMA_EXPORT_RUTA_KML       → documento KML descargable
--
-- Reemplazan al antiguo CLI547_AGMSP_MMA_RUTA_GPS_MAQUINARIA, que leía la
-- tabla de puntos individuales v2 (ya retirada). Ambos leen la ruta consolidada
-- GEOGRAPHY de CLI547_AGM_Ruta_maquinaria.
--
-- Depende de las SECCIONES 1 a 3.
-- =============================================================================

CREATE OR ALTER PROCEDURE dbo.CLI547_AGMSP_MMA_GET_RUTAS_MAQUINARIA
    @p_registro_id      UNIQUEIDENTIFIER = NULL,
    @p_fecha_desde      DATE             = NULL,
    @p_fecha_hasta      DATE             = NULL,
    @p_tractor_id_erp   INT              = NULL,
    @p_operador_id_erp  INT              = NULL,
    -- Tolerancia de simplificación en metros para el WKT devuelto.
    -- Una jornada de 8 h a 5 s/punto son ~5 760 puntos; para dibujar en pantalla
    -- 2 m de tolerancia reduce el payload drásticamente sin cambio visible.
    -- 0 = devolver la geometría completa.
    @p_simplificar_m    FLOAT            = 2.0
AS
BEGIN
    SET NOCOUNT ON;

    IF @p_registro_id IS NULL AND @p_fecha_desde IS NULL
        THROW 50020, 'Proporcione @p_fecha_desde o @p_registro_id.', 1;

    IF @p_fecha_hasta IS NULL SET @p_fecha_hasta = @p_fecha_desde;
    IF @p_simplificar_m IS NULL OR @p_simplificar_m < 0 SET @p_simplificar_m = 0;

    -- ── RS-1: una fila por jornada ───────────────────────────────────────────
    SELECT
        r.registro_id,
        d.numero_registro,
        r.fecha,
        d.turno,
        d.estado,
        d.tipo_registro,

        r.operador_id_erp,
        d.nombre_operador_snapshot          AS operador,
        r.tractor_id_erp,
        d.codigo_tractor_snapshot           AS tractor,
        d.codigo_implemento_snapshot        AS implemento,
        r.proceso_id,
        COALESCE(p.nombre, d.proceso_vehiculo) AS proceso,
        d.nombre_cultivo_snapshot           AS cultivo,

        -- Geometría de la ruta, lista para dibujar (WKT lon lat)
        CASE WHEN @p_simplificar_m > 0
             THEN r.ruta_geog.Reduce(@p_simplificar_m).STAsText()
             ELSE r.ruta_geog.STAsText()
        END                                 AS ruta_wkt,
        r.ruta_geog.STGeometryType()        AS geometria_tipo,
        r.total_puntos,
        CASE WHEN @p_simplificar_m > 0
             THEN r.ruta_geog.Reduce(@p_simplificar_m).STNumPoints()
             ELSE r.total_puntos
        END                                 AS puntos_devueltos,

        -- Analytics calculados en el APK
        r.longitud_km,
        r.km_trabajo,
        r.km_traslado,
        r.tiempo_trabajo_min,
        r.tiempo_parado_min,
        r.total_paradas,
        r.velocidad_prom_kmh,
        r.velocidad_max_kmh,
        r.eficiencia_pct,
        -- Control de calidad: la longitud geométrica y la suma de km del APK
        -- se calculan por métodos distintos; una diferencia grande delata un
        -- problema de tracking o de cálculo en el dispositivo.
        CASE
            WHEN r.longitud_km IS NULL
              OR COALESCE(r.km_trabajo, 0) + COALESCE(r.km_traslado, 0) = 0 THEN NULL
            ELSE CAST(ABS(r.longitud_km - (COALESCE(r.km_trabajo,0) + COALESCE(r.km_traslado,0)))
                      AS DECIMAL(10,3))
        END                                 AS desviacion_km,

        -- Centrado del mapa (EnvelopeCenter/EnvelopeAngle evitan recorrer puntos)
        r.ruta_geog.EnvelopeCenter().Lat    AS lat_centro,
        r.ruta_geog.EnvelopeCenter().Long   AS lng_centro,
        r.ruta_geog.EnvelopeAngle()         AS radio_grados,
        CASE
            WHEN r.ruta_geog.EnvelopeAngle() < 0.0025 THEN 16   -- < ~250 m
            WHEN r.ruta_geog.EnvelopeAngle() < 0.01   THEN 14   -- < ~1 km
            WHEN r.ruta_geog.EnvelopeAngle() < 0.05   THEN 12   -- < ~5 km
            ELSE 10
        END                                 AS zoom_sugerido,

        r.sincronizado_at                   AS sincronizado_at_utc

    FROM dbo.CLI547_AGM_Ruta_maquinaria r
    INNER JOIN dbo.CLI547_AGM_MMA_REGISTROS_DIARIOS d ON d.id = r.registro_id
    LEFT  JOIN dbo.CLI547_AGM_MMA_PROCESOS p          ON p.id = r.proceso_id
    WHERE r.ruta_geog IS NOT NULL
      AND (@p_registro_id     IS NULL OR r.registro_id     = @p_registro_id)
      AND (@p_fecha_desde     IS NULL OR r.fecha          >= @p_fecha_desde)
      AND (@p_fecha_hasta     IS NULL OR r.fecha          <= @p_fecha_hasta)
      AND (@p_tractor_id_erp  IS NULL OR r.tractor_id_erp  = @p_tractor_id_erp)
      AND (@p_operador_id_erp IS NULL OR r.operador_id_erp = @p_operador_id_erp)
    ORDER BY r.fecha DESC, d.turno;

    -- ── RS-2: sublotes trabajados por jornada (tabla normalizada) ────────────
    SELECT
        s.registro_id,
        s.sublote_id,
        s.nombre        AS sublote_nombre,
        s.minutos,
        CAST(s.minutos / 60.0 AS DECIMAL(6,2)) AS horas
    FROM dbo.CLI547_AGM_Ruta_maquinaria_Sublotes s
    INNER JOIN dbo.CLI547_AGM_Ruta_maquinaria r ON r.registro_id = s.registro_id
    WHERE (@p_registro_id     IS NULL OR r.registro_id     = @p_registro_id)
      AND (@p_fecha_desde     IS NULL OR r.fecha          >= @p_fecha_desde)
      AND (@p_fecha_hasta     IS NULL OR r.fecha          <= @p_fecha_hasta)
      AND (@p_tractor_id_erp  IS NULL OR r.tractor_id_erp  = @p_tractor_id_erp)
      AND (@p_operador_id_erp IS NULL OR r.operador_id_erp = @p_operador_id_erp)
    ORDER BY s.registro_id, s.minutos DESC;
END;
GO

-- =============================================================================
-- Exportación KML
-- Devuelve un único documento KML con un Placemark por jornada. El cliente lo
-- guarda como .kml (o lo comprime como .kmz) y se abre en Google Earth / QGIS.
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.CLI547_AGMSP_MMA_EXPORT_RUTA_KML
    @p_registro_id      UNIQUEIDENTIFIER = NULL,
    @p_fecha_desde      DATE             = NULL,
    @p_fecha_hasta      DATE             = NULL,
    @p_tractor_id_erp   INT              = NULL,
    @p_operador_id_erp  INT              = NULL,
    @p_simplificar_m    FLOAT            = 2.0
AS
BEGIN
    SET NOCOUNT ON;

    IF @p_registro_id IS NULL AND @p_fecha_desde IS NULL
        THROW 50021, 'Proporcione @p_fecha_desde o @p_registro_id.', 1;

    IF @p_fecha_hasta IS NULL SET @p_fecha_hasta = @p_fecha_desde;
    IF @p_simplificar_m IS NULL OR @p_simplificar_m < 0 SET @p_simplificar_m = 0;

    CREATE TABLE #rutas (
        registro_id     UNIQUEIDENTIFIER,
        titulo          NVARCHAR(400),
        descripcion     NVARCHAR(MAX),
        es_punto        BIT,
        wkt             NVARCHAR(MAX),
        coords          NVARCHAR(MAX)
    );

    INSERT INTO #rutas (registro_id, titulo, descripcion, es_punto, wkt)
    SELECT
        r.registro_id,
        CONCAT(d.numero_registro,
               ' · ', ISNULL(d.codigo_tractor_snapshot, 's/tractor'),
               ' · ', CONVERT(VARCHAR(10), r.fecha, 23),
               ' (', ISNULL(d.turno, '-'), ')'),
        CONCAT(
            'Operador: ',   ISNULL(d.nombre_operador_snapshot, '-'), CHAR(10),
            'Proceso: ',    ISNULL(COALESCE(p.nombre, d.proceso_vehiculo), '-'), CHAR(10),
            'Cultivo: ',    ISNULL(d.nombre_cultivo_snapshot, '-'), CHAR(10),
            'Distancia: ',  ISNULL(CAST(r.longitud_km AS VARCHAR(20)), '-'), ' km', CHAR(10),
            'Trabajo: ',    ISNULL(CAST(r.km_trabajo  AS VARCHAR(20)), '-'), ' km / ',
                            ISNULL(CAST(r.tiempo_trabajo_min AS VARCHAR(10)), '-'), ' min', CHAR(10),
            'Traslado: ',   ISNULL(CAST(r.km_traslado AS VARCHAR(20)), '-'), ' km', CHAR(10),
            'Parado: ',     ISNULL(CAST(r.tiempo_parado_min AS VARCHAR(10)), '-'), ' min en ',
                            ISNULL(CAST(r.total_paradas AS VARCHAR(10)), '-'), ' parada(s)', CHAR(10),
            'Velocidad: ',  ISNULL(CAST(r.velocidad_prom_kmh AS VARCHAR(10)), '-'), ' km/h prom, ',
                            ISNULL(CAST(r.velocidad_max_kmh  AS VARCHAR(10)), '-'), ' km/h máx', CHAR(10),
            'Eficiencia: ', ISNULL(CAST(r.eficiencia_pct AS VARCHAR(10)), '-'), ' %', CHAR(10),
            'Puntos: ',     ISNULL(CAST(r.total_puntos AS VARCHAR(10)), '-')
        ),
        CASE WHEN r.ruta_geog.STGeometryType() = 'Point' THEN 1 ELSE 0 END,
        CASE WHEN @p_simplificar_m > 0
             THEN r.ruta_geog.Reduce(@p_simplificar_m).STAsText()
             ELSE r.ruta_geog.STAsText()
        END
    FROM dbo.CLI547_AGM_Ruta_maquinaria r
    INNER JOIN dbo.CLI547_AGM_MMA_REGISTROS_DIARIOS d ON d.id = r.registro_id
    LEFT  JOIN dbo.CLI547_AGM_MMA_PROCESOS p          ON p.id = r.proceso_id
    WHERE r.ruta_geog IS NOT NULL
      AND (@p_registro_id     IS NULL OR r.registro_id     = @p_registro_id)
      AND (@p_fecha_desde     IS NULL OR r.fecha          >= @p_fecha_desde)
      AND (@p_fecha_hasta     IS NULL OR r.fecha          <= @p_fecha_hasta)
      AND (@p_tractor_id_erp  IS NULL OR r.tractor_id_erp  = @p_tractor_id_erp)
      AND (@p_operador_id_erp IS NULL OR r.operador_id_erp = @p_operador_id_erp);

    -- WKT  → "LINESTRING (lon lat, lon lat)"   (pares separados por coma)
    -- KML  → "lon,lat lon,lat"                 (pares separados por espacio)
    -- El intercambio se hace con un separador temporal para no pisar los valores.
    UPDATE #rutas
    SET coords =
        REPLACE(
            REPLACE(
                REPLACE(
                    REPLACE(
                        LTRIM(RTRIM(
                            REPLACE(REPLACE(REPLACE(REPLACE(wkt,
                                'LINESTRING', ''), 'POINT', ''), '(', ''), ')', '')
                        )),
                    ', ', ','),      -- normaliza el separador de pares
                ' ', '|'),           -- lon|lat,lon|lat
            ',', ' '),               -- lon|lat lon|lat
        '|', ',');                   -- lon,lat lon,lat

    DECLARE @body NVARCHAR(MAX);

    SELECT @body = (
        SELECT
            CHAR(10) + '  <Placemark>' +
            CHAR(10) + '    <name>' +
                REPLACE(REPLACE(REPLACE(titulo, '&', '&amp;'), '<', '&lt;'), '>', '&gt;') +
                '</name>' +
            CHAR(10) + '    <description><![CDATA[' + descripcion + ']]></description>' +
            CHAR(10) + '    <styleUrl>#rutaMaquinaria</styleUrl>' +
            CASE WHEN es_punto = 1 THEN
                CHAR(10) + '    <Point><coordinates>' + coords + '</coordinates></Point>'
            ELSE
                CHAR(10) + '    <LineString>' +
                CHAR(10) + '      <tessellate>1</tessellate>' +
                CHAR(10) + '      <coordinates>' + coords + '</coordinates>' +
                CHAR(10) + '    </LineString>'
            END +
            CHAR(10) + '  </Placemark>'
        FROM #rutas
        ORDER BY titulo
        FOR XML PATH(''), TYPE
    ).value('.', 'NVARCHAR(MAX)');

    DECLARE @total INT = (SELECT COUNT(*) FROM #rutas);

    SELECT
        @total AS rutas_exportadas,
        CASE WHEN @total = 0 THEN NULL ELSE
            '<?xml version="1.0" encoding="UTF-8"?>' + CHAR(10) +
            '<kml xmlns="http://www.opengis.net/kml/2.2">' + CHAR(10) +
            '<Document>' + CHAR(10) +
            '  <name>Rutas de maquinaria</name>' + CHAR(10) +
            '  <Style id="rutaMaquinaria">' + CHAR(10) +
            '    <LineStyle><color>ff0078ff</color><width>3</width></LineStyle>' + CHAR(10) +
            '    <IconStyle><scale>0.9</scale></IconStyle>' + CHAR(10) +
            '  </Style>' +
            ISNULL(@body, '') + CHAR(10) +
            '</Document>' + CHAR(10) +
            '</kml>'
        END AS kml;

    DROP TABLE #rutas;
END;
GO

PRINT '✅ CLI547_AGMSP_MMA_GET_RUTAS_MAQUINARIA y CLI547_AGMSP_MMA_EXPORT_RUTA_KML creados.';
GO

/*
-- Ejemplos de uso
-- 1. Rutas de un día para el mapa del dashboard
EXEC dbo.CLI547_AGMSP_MMA_GET_RUTAS_MAQUINARIA @p_fecha_desde = '2026-09-19';

-- 2. Detalle de una jornada, sin simplificar la geometría
EXEC dbo.CLI547_AGMSP_MMA_GET_RUTAS_MAQUINARIA
     @p_registro_id   = 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx',
     @p_simplificar_m = 0;

-- 3. KML de todo un tractor en un mes (guardar la columna kml como .kml)
EXEC dbo.CLI547_AGMSP_MMA_EXPORT_RUTA_KML
     @p_fecha_desde    = '2026-09-01',
     @p_fecha_hasta    = '2026-09-30',
     @p_tractor_id_erp = 7;

-- 4. Minutos por sublote en un rango (usa la tabla normalizada)
SELECT s.sublote_id, MAX(s.nombre) AS sublote, SUM(s.minutos) AS minutos_totales,
       COUNT(DISTINCT r.tractor_id_erp) AS maquinas
FROM dbo.CLI547_AGM_Ruta_maquinaria_Sublotes s
JOIN dbo.CLI547_AGM_Ruta_maquinaria r ON r.registro_id = s.registro_id
WHERE r.fecha BETWEEN '2026-09-01' AND '2026-09-30'
GROUP BY s.sublote_id
ORDER BY minutos_totales DESC;
*/


-- #############################################################################
-- #  SECCIÓN 6 · VISTAS PARA QGIS
-- #############################################################################

-- =============================================================================
-- Vistas para consumo directo desde QGIS (proveedor nativo "MS SQL Server")
--
-- Por qué vistas y no las tablas directas:
--   QGIS carga una capa = una tabla/vista. Si apunta a CLI547_AGM_Ruta_maquinaria
--   sola, la tabla de atributos solo muestra IDs (operador_id_erp, tractor_id_erp)
--   y no se puede etiquetar ni filtrar por nombre. Estas vistas ya traen la
--   geometría junto con los atributos legibles, en una sola capa.
--
-- Por qué se expone `geometry` y no `geography`:
--   El proveedor SQL Server de QGIS es más consistente con el tipo `geometry`.
--   Las vistas hacen el cast conservando el orden lon/lat y el SRID 4326
--   (EPSG:4326 — WGS84), que es lo que QGIS espera por defecto.
--
-- Cómo conectar en QGIS:
--   1. Explorador → MS SQL Server → Nueva conexión (servidor, BD, credenciales).
--   2. Expandir la conexión → aparecen las vistas con geometría como capas.
--   3. Al cargar, elegir como clave única: registro_id (rutas) o clave_qgis (sublotes).
--   4. Si el rango de fechas es grande, usar el filtro del proveedor
--      (clic derecho en la capa → Filtrar) en vez de cargar todo:
--      las vistas calculan la geometría al vuelo y no usan el índice espacial.
--
-- Idempotente (CREATE OR ALTER VIEW).
-- =============================================================================

-- =============================================================================
-- Capa 1: rutas de maquinaria (líneas)
-- Una jornada = una línea, con todas las métricas como atributos.
-- Ideas de simbología en QGIS:
--   · Color graduado por eficiencia_pct  → ver de un vistazo qué jornadas rinden
--   · Grosor graduado por longitud_km
--   · Etiqueta = tractor + turno
-- =============================================================================
CREATE OR ALTER VIEW dbo.VW_MMA_RUTAS_QGIS
AS
SELECT
    r.registro_id,
    d.numero_registro,
    r.fecha,
    d.turno,
    d.estado,
    d.tipo_registro,

    -- Atributos legibles (snapshots guardados al sincronizar)
    r.operador_id_erp,
    d.nombre_operador_snapshot              AS operador,
    d.nombre_supervisor_snapshot            AS supervisor,
    r.tractor_id_erp,
    d.codigo_tractor_snapshot               AS tractor,
    d.codigo_implemento_snapshot            AS implemento,
    r.proceso_id,
    COALESCE(p.nombre, d.proceso_vehiculo)  AS proceso,
    d.subproceso_nombre                     AS subproceso,
    d.nombre_cultivo_snapshot               AS cultivo,

    -- Métricas de la jornada
    r.total_puntos,
    r.longitud_km,
    r.km_trabajo,
    r.km_traslado,
    r.tiempo_trabajo_min,
    r.tiempo_parado_min,
    r.total_paradas,
    r.velocidad_prom_kmh,
    r.velocidad_max_kmh,
    r.eficiencia_pct,

    -- Control de calidad: longitud geométrica (servidor) vs. suma de km (APK).
    -- Una desviación alta delata puntos perdidos o error de cálculo en campo.
    CASE
        WHEN r.longitud_km IS NULL
          OR COALESCE(r.km_trabajo, 0) + COALESCE(r.km_traslado, 0) = 0 THEN NULL
        ELSE CAST(ABS(r.longitud_km - (COALESCE(r.km_trabajo, 0) + COALESCE(r.km_traslado, 0)))
                  AS DECIMAL(10,3))
    END                                     AS desviacion_km,

    r.sincronizado_at                       AS sincronizado_at_utc,

    -- Geometría para QGIS
    geometry::STGeomFromText(r.ruta_geog.STAsText(), 4326) AS geom
FROM dbo.CLI547_AGM_Ruta_maquinaria r
INNER JOIN dbo.CLI547_AGM_MMA_REGISTROS_DIARIOS d ON d.id = r.registro_id
LEFT  JOIN dbo.CLI547_AGM_MMA_PROCESOS p          ON p.id = r.proceso_id
WHERE r.ruta_geog IS NOT NULL;
GO

-- =============================================================================
-- Capa 2: sublotes trabajados (polígonos) — mapa de calor de trabajo por lote
--
-- Cruza la tabla normalizada de sublotes con la geometría del polígono que vive
-- en el ERP. Permite responder visualmente "¿qué lotes se trabajaron, cuánto
-- tiempo y con qué máquina?" sin mirar una sola tabla.
--
-- Ideas de simbología en QGIS:
--   · Color graduado por minutos → mapa de calor de intensidad de trabajo
--   · Filtrar por fecha para ver la cobertura de un día
--
-- Requiere permiso de lectura sobre ERPHispatec (mismo acceso que ya usa el SP
-- de catálogos para traer lotes_kmz). Si esa vista falla por permisos, la
-- Capa 1 sigue funcionando: son independientes.
-- =============================================================================
CREATE OR ALTER VIEW dbo.VW_MMA_SUBLOTES_TRABAJADOS_QGIS
AS
SELECT
    -- Clave única para QGIS (la vista no tiene PK propia)
    CONCAT(CAST(s.registro_id AS NVARCHAR(36)), '_', CAST(s.sublote_id AS NVARCHAR(20))) AS clave_qgis,

    s.registro_id,
    s.sublote_id,
    s.nombre                                AS sublote,
    s.minutos,
    CAST(s.minutos / 60.0 AS DECIMAL(6,2))  AS horas,

    r.fecha,
    d.turno,
    r.tractor_id_erp,
    d.codigo_tractor_snapshot               AS tractor,
    r.operador_id_erp,
    d.nombre_operador_snapshot              AS operador,
    COALESCE(p.nombre, d.proceso_vehiculo)  AS proceso,
    d.nombre_cultivo_snapshot               AS cultivo,

    -- Superficie del sublote en hectáreas (SuperficieCultivada viene en m²)
    CAST(cu.SuperficieCultivada / 10000.0 AS DECIMAL(10,2)) AS hectareas,

    -- Productividad aproximada: ha del sublote / horas dentro de ese polígono.
    -- OJO: asume que la máquina cubrió el sublote completo. Si solo trabajó una
    -- parte, sobrestima. Para área realmente cubierta habría que bufferizar la
    -- ruta con el ancho del implemento e intersecar con el polígono.
    CASE WHEN s.minutos > 0
         THEN CAST((cu.SuperficieCultivada / 10000.0) / (s.minutos / 60.0) AS DECIMAL(10,3))
         ELSE NULL
    END                                     AS ha_por_hora,

    geometry::STGeomFromText(geo.Geometria.STAsText(), 4326) AS geom
FROM dbo.CLI547_AGM_Ruta_maquinaria_Sublotes s
INNER JOIN dbo.CLI547_AGM_Ruta_maquinaria r        ON r.registro_id = s.registro_id
INNER JOIN dbo.CLI547_AGM_MMA_REGISTROS_DIARIOS d  ON d.id          = s.registro_id
LEFT  JOIN dbo.CLI547_AGM_MMA_PROCESOS p           ON p.id          = r.proceso_id
INNER JOIN ERPHispatec.dbo.Cultivos cu WITH (NOLOCK) ON cu.Id = s.sublote_id
OUTER APPLY (
    SELECT TOP 1 g.Geometria
    FROM ERPHispatec.dbo.Cultivos_Coordenadas cc WITH (NOLOCK)
    JOIN ERPHispatec.dbo.CoordenadaGPS g WITH (NOLOCK)
        ON g.Id = cc.Id_Coordenadas AND g.Geometria IS NOT NULL
    WHERE cc.Id_Cultivos = cu.Id
) geo
WHERE geo.Geometria IS NOT NULL;
GO

PRINT '✅ Vistas QGIS creadas: VW_MMA_RUTAS_QGIS y VW_MMA_SUBLOTES_TRABAJADOS_QGIS.';
GO

/*
-- Verificación rápida antes de conectar QGIS
SELECT TOP 10 registro_id, fecha, tractor, operador, longitud_km, eficiencia_pct,
       geom.STGeometryType() AS tipo, geom.STNumPoints() AS puntos
FROM dbo.VW_MMA_RUTAS_QGIS
ORDER BY fecha DESC;

SELECT TOP 10 sublote, fecha, tractor, minutos, hectareas, ha_por_hora
FROM dbo.VW_MMA_SUBLOTES_TRABAJADOS_QGIS
ORDER BY fecha DESC, minutos DESC;
*/


-- #############################################################################
-- #  SECCIÓN 7 · MODELO DE EVENTOS (visitas, paradas, tramos)
-- #############################################################################
--
-- POR QUÉ EXISTE ESTA SECCIÓN
--   La ruta consolidada de la SECCIÓN 1 es una LINESTRING: una lista de
--   coordenadas SIN tiempo ni velocidad por vértice. Sirve para dibujar el
--   recorrido y sacar totales, pero no puede responder:
--     · ¿a qué hora entró y salió de cada sublote?
--     · ¿dónde se quedó estacionado y cuánto tiempo?
--     · ¿a qué velocidad iba en cada tramo?
--
--   El APK sí conoce todo eso punto por punto. Estas tablas guardan los EVENTOS
--   que el APK deriva de sus puntos locales al cerrar turno. Son pocas filas por
--   jornada (~10 visitas, ~15 paradas, ~40 tramos) en vez de ~5 000 puntos.
--
-- ZONA HORARIA
--   Todos los *_at de esta sección son UTC (vienen como epoch ms del dispositivo
--   y se convierten con DATEADD sobre 1970-01-01). Para mostrar hora local de
--   Perú restar 5 horas: DATEADD(HOUR, -5, entrada_at).
--
-- =============================================================================

-- ─────────────────────────────────────────────────────────────────────────────
-- 7.1 Visitas a sublote — "en qué lotes estuvo, cuándo entró y cuándo salió"
-- ─────────────────────────────────────────────────────────────────────────────
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'CLI547_AGM_Ruta_visitas_sublote')
BEGIN
    CREATE TABLE dbo.CLI547_AGM_Ruta_visitas_sublote (
        id              UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID(),
        registro_id     UNIQUEIDENTIFIER NOT NULL,
        sublote_id      INT              NOT NULL,   -- id_erp (ERPHispatec Cultivos.Id)
        nombre          NVARCHAR(200)    NULL,       -- snapshot del nombre
        entrada_at      DATETIME2(0)     NOT NULL,   -- UTC
        salida_at       DATETIME2(0)     NOT NULL,   -- UTC
        minutos         INT              NULL,
        km              DECIMAL(10,3)    NULL,       -- recorrido DENTRO del sublote
        vel_prom_kmh    DECIMAL(5,2)     NULL,
        vel_max_kmh     DECIMAL(5,2)     NULL,
        puntos          INT              NULL,

        -- Cobertura — la llena CLI547_AGMSP_MMA_CALCULAR_COBERTURA (sección 8),
        -- no el SP de sincronización. Quedan NULL hasta que se ejecute.
        ha_cubiertas            DECIMAL(10,4) NULL,
        pct_avance              DECIMAL(5,2)  NULL,
        cobertura_calculada_at  DATETIME2(0)  NULL,

        CONSTRAINT PK_RutaVisitas PRIMARY KEY (id),
        -- Una máquina puede entrar y salir del mismo lote varias veces al día,
        -- por eso la clave natural incluye la hora de entrada.
        CONSTRAINT UQ_RutaVisitas UNIQUE (registro_id, sublote_id, entrada_at),
        CONSTRAINT FK_RutaVisitas_Ruta FOREIGN KEY (registro_id)
            REFERENCES dbo.CLI547_AGM_Ruta_maquinaria(registro_id) ON DELETE CASCADE,
        CONSTRAINT CK_RutaVisitas_Rango CHECK (salida_at >= entrada_at),
        CONSTRAINT CK_RutaVisitas_Valores CHECK (
            (minutos IS NULL OR minutos >= 0) AND (km IS NULL OR km >= 0)
            AND (pct_avance IS NULL OR pct_avance >= 0))
    );

    CREATE INDEX IX_RutaVisitas_Sublote ON dbo.CLI547_AGM_Ruta_visitas_sublote (sublote_id, entrada_at);
    CREATE INDEX IX_RutaVisitas_Registro ON dbo.CLI547_AGM_Ruta_visitas_sublote (registro_id);
    PRINT '>>> Tabla CLI547_AGM_Ruta_visitas_sublote creada.';
END
ELSE PRINT '>>> Tabla CLI547_AGM_Ruta_visitas_sublote ya existe — omitida.';
GO

-- ─────────────────────────────────────────────────────────────────────────────
-- 7.2 Paradas — "dónde se quedó estacionado y cuánto tiempo"
-- ─────────────────────────────────────────────────────────────────────────────
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'CLI547_AGM_Ruta_paradas')
BEGIN
    CREATE TABLE dbo.CLI547_AGM_Ruta_paradas (
        id              UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID(),
        registro_id     UNIQUEIDENTIFIER NOT NULL,
        orden           INT              NOT NULL,   -- cronológico dentro de la jornada
        latitud         FLOAT            NOT NULL,
        longitud        FLOAT            NOT NULL,
        punto           GEOGRAPHY        NULL,       -- derivado de lat/lon al insertar
        inicio_at       DATETIME2(0)     NOT NULL,   -- UTC
        fin_at          DATETIME2(0)     NOT NULL,   -- UTC
        minutos         INT              NULL,
        -- NULL = la parada ocurrió FUERA de todo sublote (tiempo muerto en ruta).
        -- Es la señal más útil de la tabla: paradas largas fuera de lote.
        sublote_id      INT              NULL,

        CONSTRAINT PK_RutaParadas PRIMARY KEY (id),
        CONSTRAINT UQ_RutaParadas UNIQUE (registro_id, orden),
        CONSTRAINT FK_RutaParadas_Ruta FOREIGN KEY (registro_id)
            REFERENCES dbo.CLI547_AGM_Ruta_maquinaria(registro_id) ON DELETE CASCADE,
        CONSTRAINT CK_RutaParadas_Rango CHECK (fin_at >= inicio_at),
        CONSTRAINT CK_RutaParadas_Minutos CHECK (minutos IS NULL OR minutos >= 0)
    );

    CREATE INDEX IX_RutaParadas_Registro ON dbo.CLI547_AGM_Ruta_paradas (registro_id, orden);
    CREATE SPATIAL INDEX SX_RutaParadas_Punto ON dbo.CLI547_AGM_Ruta_paradas (punto)
        USING GEOGRAPHY_GRID WITH (GRIDS = (MEDIUM, MEDIUM, MEDIUM, MEDIUM));
    PRINT '>>> Tabla CLI547_AGM_Ruta_paradas creada.';
END
ELSE PRINT '>>> Tabla CLI547_AGM_Ruta_paradas ya existe — omitida.';
GO

-- ─────────────────────────────────────────────────────────────────────────────
-- 7.3 Tramos — la ruta partida por tipo de actividad, para pintarla por color
-- ─────────────────────────────────────────────────────────────────────────────
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'CLI547_AGM_Ruta_tramos')
BEGIN
    CREATE TABLE dbo.CLI547_AGM_Ruta_tramos (
        id              UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID(),
        registro_id     UNIQUEIDENTIFIER NOT NULL,
        orden           INT              NOT NULL,
        tipo            VARCHAR(10)      NOT NULL,   -- TRABAJO | TRASLADO | PARADO
        geom            GEOGRAPHY        NULL,
        inicio_at       DATETIME2(0)     NOT NULL,   -- UTC
        fin_at          DATETIME2(0)     NOT NULL,   -- UTC
        minutos         INT              NULL,
        km              DECIMAL(10,3)    NULL,
        vel_prom_kmh    DECIMAL(5,2)     NULL,
        vel_max_kmh     DECIMAL(5,2)     NULL,
        puntos          INT              NULL,
        -- Sublote en el que ocurre el tramo (NULL fuera de lote). Permite unir
        -- la geometría de trabajo por lote sin cruzar por rangos de tiempo.
        sublote_id      INT              NULL,

        CONSTRAINT PK_RutaTramos PRIMARY KEY (id),
        CONSTRAINT UQ_RutaTramos UNIQUE (registro_id, orden),
        CONSTRAINT FK_RutaTramos_Ruta FOREIGN KEY (registro_id)
            REFERENCES dbo.CLI547_AGM_Ruta_maquinaria(registro_id) ON DELETE CASCADE,
        CONSTRAINT CK_RutaTramos_Tipo CHECK (tipo IN ('TRABAJO','TRASLADO','PARADO')),
        CONSTRAINT CK_RutaTramos_Rango CHECK (fin_at >= inicio_at)
    );

    CREATE INDEX IX_RutaTramos_Registro ON dbo.CLI547_AGM_Ruta_tramos (registro_id, orden);
    CREATE INDEX IX_RutaTramos_Tipo ON dbo.CLI547_AGM_Ruta_tramos (tipo) INCLUDE (km, minutos);
    PRINT '>>> Tabla CLI547_AGM_Ruta_tramos creada.';
END
ELSE PRINT '>>> Tabla CLI547_AGM_Ruta_tramos ya existe — omitida.';
GO

-- ─────────────────────────────────────────────────────────────────────────────
-- 7.4 Ancho de labor por implemento — necesario para calcular cobertura real
--
-- El APK NO envía este dato: el servidor lo resuelve desde implemento_id_erp
-- del registro diario. Por eso no hace falta tocar la app para usarlo.
--
-- Esta tabla es un puente temporal. Cuando el ancho exista como campo propio
-- en el catálogo del ERP, se puede reemplazar por una vista:
--     DROP TABLE dbo.CLI547_AGM_MMA_IMPLEMENTOS_ANCHO;
--     CREATE VIEW dbo.CLI547_AGM_MMA_IMPLEMENTOS_ANCHO AS
--     SELECT Id AS implemento_id_erp, <campo_ancho> AS ancho_labor_m, ...
--     FROM ERPHispatec.dbo.<tabla_implementos>;
-- y todo lo demás sigue funcionando sin cambios.
-- ─────────────────────────────────────────────────────────────────────────────
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'CLI547_AGM_MMA_IMPLEMENTOS_ANCHO')
BEGIN
    CREATE TABLE dbo.CLI547_AGM_MMA_IMPLEMENTOS_ANCHO (
        implemento_id_erp INT           NOT NULL,
        ancho_labor_m     DECIMAL(6,2)  NOT NULL,   -- ancho efectivo de trabajo en metros
        descripcion       NVARCHAR(200) NULL,
        actualizado_at    DATETIME2(0)  NOT NULL DEFAULT SYSUTCDATETIME(),
        CONSTRAINT PK_ImplementosAncho PRIMARY KEY (implemento_id_erp),
        CONSTRAINT CK_ImplementosAncho CHECK (ancho_labor_m > 0 AND ancho_labor_m < 100)
    );
    PRINT '>>> Tabla CLI547_AGM_MMA_IMPLEMENTOS_ANCHO creada — POBLARLA antes de calcular cobertura.';
    PRINT '    Ejemplo: INSERT INTO dbo.CLI547_AGM_MMA_IMPLEMENTOS_ANCHO';
    PRINT '             (implemento_id_erp, ancho_labor_m, descripcion)';
    PRINT '             VALUES (123, 3.20, ''Rastra 12 discos'');';
END
ELSE PRINT '>>> Tabla CLI547_AGM_MMA_IMPLEMENTOS_ANCHO ya existe — omitida.';
GO


-- #############################################################################
-- #  SECCIÓN 8 · CÁLCULO DE COBERTURA (hectáreas trabajadas y % de avance)
-- #############################################################################
--
-- CÓMO FUNCIONA
--   Por cada visita a sublote:
--     1. Une la geometría de los tramos de TRABAJO de ese sublote  → línea
--     2. La engrosa con el ancho del implemento (STBuffer ancho/2) → franja
--     3. La intersecta con el polígono real del sublote            → área útil
--     4. STArea() da m²; entre 10 000 da hectáreas
--        Los pases superpuestos NO se cuentan dos veces: el buffer los fusiona.
--
-- POR QUÉ NO VA DENTRO DEL SP DE SINCRONIZACIÓN
--   Las operaciones espaciales (buffer + intersección) son costosas. Meterlas en
--   la transacción de sync alargaría los bloqueos en un momento en que puede
--   haber muchos dispositivos sincronizando a la vez. Se ejecuta aparte: a mano,
--   o como job de SQL Agent cada N minutos.
--
-- IDEMPOTENTE: solo procesa visitas sin cobertura, salvo @p_recalcular = 1.
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.CLI547_AGMSP_MMA_CALCULAR_COBERTURA
    @p_registro_id  UNIQUEIDENTIFIER = NULL,  -- NULL = todas las pendientes
    @p_recalcular   BIT              = 0      -- 1 = recalcular aunque ya tengan valor
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @v_id          UNIQUEIDENTIFIER,
            @v_registro    UNIQUEIDENTIFIER,
            @v_sublote     INT,
            @v_entrada     DATETIME2(0),
            @v_salida      DATETIME2(0),
            @v_ancho       DECIMAL(6,2),
            @v_trabajo     GEOGRAPHY,
            @v_lote        GEOGRAPHY,
            @v_ha_lote     DECIMAL(10,4),
            @v_ha_cub      DECIMAL(10,4),
            @v_pct         DECIMAL(5,2),
            @v_ok          INT = 0,
            @v_sin_ancho   INT = 0,
            @v_sin_geom    INT = 0,
            @v_error       INT = 0;

    DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
        SELECT v.id, v.registro_id, v.sublote_id, v.entrada_at, v.salida_at
        FROM dbo.CLI547_AGM_Ruta_visitas_sublote v
        WHERE (@p_registro_id IS NULL OR v.registro_id = @p_registro_id)
          AND (@p_recalcular = 1 OR v.cobertura_calculada_at IS NULL);

    OPEN cur;
    FETCH NEXT FROM cur INTO @v_id, @v_registro, @v_sublote, @v_entrada, @v_salida;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        BEGIN TRY
            SET @v_trabajo = NULL; SET @v_lote = NULL;
            SET @v_ha_cub = NULL;  SET @v_pct  = NULL;

            -- 1. Ancho del implemento usado en esa jornada
            SELECT @v_ancho = a.ancho_labor_m
            FROM dbo.CLI547_AGM_MMA_REGISTROS_DIARIOS d
            JOIN dbo.CLI547_AGM_MMA_IMPLEMENTOS_ANCHO a ON a.implemento_id_erp = d.implemento_id_erp
            WHERE d.id = @v_registro;

            IF @v_ancho IS NULL
            BEGIN
                SET @v_sin_ancho = @v_sin_ancho + 1;
            END
            ELSE
            BEGIN
                -- 2. Geometría de trabajo dentro de ese sublote en esa visita
                SELECT @v_trabajo = geography::UnionAggregate(t.geom)
                FROM dbo.CLI547_AGM_Ruta_tramos t
                WHERE t.registro_id = @v_registro
                  AND t.tipo        = 'TRABAJO'
                  AND t.geom IS NOT NULL
                  AND (t.sublote_id = @v_sublote
                       OR (t.sublote_id IS NULL
                           AND t.inicio_at >= @v_entrada AND t.fin_at <= @v_salida));

                -- 3. Polígono del sublote desde el ERP.
                --    Geometria es tipo `geometry`; al pasarlo a geography hay que
                --    cuidar la orientación del anillo: si queda invertido, SQL Server
                --    entiende "todo el planeta menos el lote" y el área sale absurda.
                SELECT TOP 1
                    @v_lote    = geography::STGeomFromText(g.Geometria.STAsText(), 4326).MakeValid(),
                    @v_ha_lote = CAST(cu.SuperficieCultivada / 10000.0 AS DECIMAL(10,4))
                FROM ERPHispatec.dbo.Cultivos cu WITH (NOLOCK)
                JOIN ERPHispatec.dbo.Cultivos_Coordenadas cc WITH (NOLOCK) ON cc.Id_Cultivos = cu.Id
                JOIN ERPHispatec.dbo.CoordenadaGPS g WITH (NOLOCK)
                     ON g.Id = cc.Id_Coordenadas AND g.Geometria IS NOT NULL
                WHERE cu.Id = @v_sublote;

                -- Corrección de orientación: media Tierra son ~2.5e14 m²
                IF @v_lote IS NOT NULL AND @v_lote.STArea() > 250000000000000.0
                    SET @v_lote = @v_lote.ReorientObject();

                IF @v_trabajo IS NULL OR @v_lote IS NULL
                BEGIN
                    SET @v_sin_geom = @v_sin_geom + 1;
                END
                ELSE
                BEGIN
                    -- 4. Franja cubierta ∩ lote
                    SET @v_ha_cub = CAST(
                        @v_trabajo.STBuffer(@v_ancho / 2.0).STIntersection(@v_lote).STArea() / 10000.0
                        AS DECIMAL(10,4));

                    IF @v_ha_lote > 0
                        SET @v_pct = CAST(
                            CASE WHEN @v_ha_cub / @v_ha_lote > 1 THEN 100.0
                                 ELSE @v_ha_cub / @v_ha_lote * 100.0 END
                            AS DECIMAL(5,2));

                    SET @v_ok = @v_ok + 1;
                END
            END

            UPDATE dbo.CLI547_AGM_Ruta_visitas_sublote
            SET ha_cubiertas           = @v_ha_cub,
                pct_avance             = @v_pct,
                cobertura_calculada_at = SYSUTCDATETIME()
            WHERE id = @v_id;
        END TRY
        BEGIN CATCH
            -- Un polígono corrupto no debe abortar el lote completo
            SET @v_error = @v_error + 1;
            UPDATE dbo.CLI547_AGM_Ruta_visitas_sublote
            SET cobertura_calculada_at = SYSUTCDATETIME()
            WHERE id = @v_id;
        END CATCH

        FETCH NEXT FROM cur INTO @v_id, @v_registro, @v_sublote, @v_entrada, @v_salida;
    END

    CLOSE cur; DEALLOCATE cur;

    SELECT @v_ok        AS calculadas,
           @v_sin_ancho AS sin_ancho_implemento,
           @v_sin_geom  AS sin_geometria,
           @v_error     AS con_error;
END;
GO

PRINT '✅ Modelo de eventos y cálculo de cobertura instalados.';
GO


-- #############################################################################
-- #  SECCIÓN 9 · CAPAS Y CONSULTAS DE EVENTOS
-- #############################################################################
--
-- Complementa la SECCIÓN 6. Aquí van las capas que solo existen gracias al
-- modelo de eventos: recorrido coloreado por actividad, paradas como puntos,
-- y visitas a lote con su cobertura.
--
-- Todas las horas se exponen en hora local de Perú (UTC-5) además de UTC,
-- porque es lo que el usuario final espera ver en pantalla.
-- =============================================================================

-- ─────────────────────────────────────────────────────────────────────────────
-- 9.1 Capa: recorrido coloreado por actividad
--     En QGIS: simbología categorizada por el campo `tipo`
--       TRABAJO  → verde   TRASLADO → azul   PARADO → rojo
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR ALTER VIEW dbo.VW_MMA_TRAMOS_QGIS
AS
SELECT
    t.id,
    t.registro_id,
    d.numero_registro,
    r.fecha,
    d.turno,
    t.orden,
    t.tipo,
    t.sublote_id,
    d.codigo_tractor_snapshot       AS tractor,
    d.nombre_operador_snapshot      AS operador,
    d.codigo_implemento_snapshot    AS implemento,
    t.inicio_at                     AS inicio_utc,
    t.fin_at                        AS fin_utc,
    DATEADD(HOUR, -5, t.inicio_at)  AS inicio_local,
    DATEADD(HOUR, -5, t.fin_at)     AS fin_local,
    t.minutos,
    t.km,
    t.vel_prom_kmh,
    t.vel_max_kmh,
    t.puntos,
    geometry::STGeomFromText(t.geom.STAsText(), 4326) AS geom
FROM dbo.CLI547_AGM_Ruta_tramos t
INNER JOIN dbo.CLI547_AGM_Ruta_maquinaria r       ON r.registro_id = t.registro_id
INNER JOIN dbo.CLI547_AGM_MMA_REGISTROS_DIARIOS d ON d.id          = t.registro_id
WHERE t.geom IS NOT NULL;
GO

-- ─────────────────────────────────────────────────────────────────────────────
-- 9.2 Capa: paradas (puntos)
--     En QGIS: tamaño graduado por `minutos`, color por `fuera_de_lote`.
--     Una parada larga con fuera_de_lote = 1 es la señal operativa más valiosa
--     de todo el modelo: tiempo muerto que nadie declaró.
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR ALTER VIEW dbo.VW_MMA_PARADAS_QGIS
AS
SELECT
    p.id,
    p.registro_id,
    d.numero_registro,
    r.fecha,
    d.turno,
    p.orden,
    d.codigo_tractor_snapshot       AS tractor,
    d.nombre_operador_snapshot      AS operador,
    p.inicio_at                     AS inicio_utc,
    p.fin_at                        AS fin_utc,
    DATEADD(HOUR, -5, p.inicio_at)  AS inicio_local,
    DATEADD(HOUR, -5, p.fin_at)     AS fin_local,
    p.minutos,
    p.sublote_id,
    CASE WHEN p.sublote_id IS NULL THEN 1 ELSE 0 END AS fuera_de_lote,
    CASE
        WHEN p.minutos >= 60 THEN 'LARGA'
        WHEN p.minutos >= 15 THEN 'MEDIA'
        ELSE 'CORTA'
    END                             AS duracion_clase,
    geometry::Point(p.longitud, p.latitud, 4326) AS geom
FROM dbo.CLI547_AGM_Ruta_paradas p
INNER JOIN dbo.CLI547_AGM_Ruta_maquinaria r       ON r.registro_id = p.registro_id
INNER JOIN dbo.CLI547_AGM_MMA_REGISTROS_DIARIOS d ON d.id          = p.registro_id;
GO

-- ─────────────────────────────────────────────────────────────────────────────
-- 9.3 Capa: visitas a sublote con cobertura (polígonos)
--     En QGIS: color graduado por pct_avance → mapa de avance por lote.
--     Requiere lectura sobre ERPHispatec (igual que la vista de la sección 6).
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR ALTER VIEW dbo.VW_MMA_VISITAS_QGIS
AS
SELECT
    v.id,
    v.registro_id,
    d.numero_registro,
    r.fecha,
    d.turno,
    v.sublote_id,
    COALESCE(NULLIF(v.nombre, ''), cu.Descripcion) AS sublote,
    d.codigo_tractor_snapshot       AS tractor,
    d.nombre_operador_snapshot      AS operador,
    d.codigo_implemento_snapshot    AS implemento,
    d.nombre_cultivo_snapshot       AS cultivo,
    v.entrada_at                    AS entrada_utc,
    v.salida_at                     AS salida_utc,
    DATEADD(HOUR, -5, v.entrada_at) AS entrada_local,
    DATEADD(HOUR, -5, v.salida_at)  AS salida_local,
    v.minutos,
    CAST(v.minutos / 60.0 AS DECIMAL(6,2)) AS horas,
    v.km,
    v.vel_prom_kmh,
    v.vel_max_kmh,
    CAST(cu.SuperficieCultivada / 10000.0 AS DECIMAL(10,2)) AS hectareas_lote,
    v.ha_cubiertas,
    v.pct_avance,
    geometry::STGeomFromText(geo.Geometria.STAsText(), 4326) AS geom
FROM dbo.CLI547_AGM_Ruta_visitas_sublote v
INNER JOIN dbo.CLI547_AGM_Ruta_maquinaria r       ON r.registro_id = v.registro_id
INNER JOIN dbo.CLI547_AGM_MMA_REGISTROS_DIARIOS d ON d.id          = v.registro_id
INNER JOIN ERPHispatec.dbo.Cultivos cu WITH (NOLOCK) ON cu.Id = v.sublote_id
OUTER APPLY (
    SELECT TOP 1 g.Geometria
    FROM ERPHispatec.dbo.Cultivos_Coordenadas cc WITH (NOLOCK)
    JOIN ERPHispatec.dbo.CoordenadaGPS g WITH (NOLOCK)
        ON g.Id = cc.Id_Coordenadas AND g.Geometria IS NOT NULL
    WHERE cc.Id_Cultivos = cu.Id
) geo
WHERE geo.Geometria IS NOT NULL;
GO

-- ─────────────────────────────────────────────────────────────────────────────
-- 9.4 Timeline de una jornada — la cronología completa de la máquina
--     Es la consulta que alimenta la vista "tipo Google Maps" con línea de
--     tiempo: qué hizo la máquina, en qué orden, dónde y por cuánto tiempo.
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR ALTER PROCEDURE dbo.CLI547_AGMSP_MMA_GET_TIMELINE_JORNADA
    @p_registro_id UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    ;WITH Eventos AS (
        -- Entradas y salidas de sublote
        SELECT v.entrada_at AS momento_utc, 1 AS prioridad,
               'ENTRADA_LOTE' AS evento,
               CONCAT('Entrada a ', COALESCE(NULLIF(v.nombre,''), CAST(v.sublote_id AS VARCHAR(20)))) AS descripcion,
               v.minutos, v.km, v.vel_prom_kmh, v.sublote_id,
               v.pct_avance, NULL AS latitud, NULL AS longitud
        FROM dbo.CLI547_AGM_Ruta_visitas_sublote v
        WHERE v.registro_id = @p_registro_id

        UNION ALL
        SELECT v.salida_at, 3,
               'SALIDA_LOTE',
               CONCAT('Salida de ', COALESCE(NULLIF(v.nombre,''), CAST(v.sublote_id AS VARCHAR(20))),
                      ' · ', v.minutos, ' min · ', ISNULL(CAST(v.km AS VARCHAR(20)),'-'), ' km'),
               v.minutos, v.km, v.vel_prom_kmh, v.sublote_id,
               v.pct_avance, NULL, NULL
        FROM dbo.CLI547_AGM_Ruta_visitas_sublote v
        WHERE v.registro_id = @p_registro_id

        UNION ALL
        -- Paradas
        SELECT p.inicio_at, 2,
               CASE WHEN p.sublote_id IS NULL THEN 'PARADA_FUERA' ELSE 'PARADA_EN_LOTE' END,
               CONCAT('Parada ', p.minutos, ' min',
                      CASE WHEN p.sublote_id IS NULL THEN ' (fuera de lote)' ELSE '' END),
               p.minutos, NULL, NULL, p.sublote_id,
               NULL, p.latitud, p.longitud
        FROM dbo.CLI547_AGM_Ruta_paradas p
        WHERE p.registro_id = @p_registro_id

        UNION ALL
        -- Traslados
        SELECT t.inicio_at, 2,
               'TRASLADO',
               CONCAT('Traslado ', t.minutos, ' min · ',
                      ISNULL(CAST(t.km AS VARCHAR(20)),'-'), ' km · ',
                      ISNULL(CAST(t.vel_prom_kmh AS VARCHAR(10)),'-'), ' km/h prom'),
               t.minutos, t.km, t.vel_prom_kmh, t.sublote_id,
               NULL, NULL, NULL
        FROM dbo.CLI547_AGM_Ruta_tramos t
        WHERE t.registro_id = @p_registro_id AND t.tipo = 'TRASLADO'
    )
    SELECT
        momento_utc,
        DATEADD(HOUR, -5, momento_utc) AS momento_local,
        evento,
        descripcion,
        minutos,
        km,
        vel_prom_kmh,
        sublote_id,
        pct_avance,
        latitud,
        longitud
    FROM Eventos
    ORDER BY momento_utc, prioridad;
END;
GO

PRINT '✅ Capas de eventos y timeline creados.';
GO

/*
-- Timeline de una jornada
EXEC dbo.CLI547_AGMSP_MMA_GET_TIMELINE_JORNADA
     @p_registro_id = 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx';

-- Calcular cobertura de todo lo pendiente (correr después de sincronizar)
EXEC dbo.CLI547_AGMSP_MMA_CALCULAR_COBERTURA;

-- Tiempo muerto: paradas largas fuera de lote del mes
SELECT d.codigo_tractor_snapshot AS tractor, r.fecha,
       COUNT(*) AS paradas, SUM(p.minutos) AS minutos_muertos
FROM dbo.CLI547_AGM_Ruta_paradas p
JOIN dbo.CLI547_AGM_Ruta_maquinaria r       ON r.registro_id = p.registro_id
JOIN dbo.CLI547_AGM_MMA_REGISTROS_DIARIOS d ON d.id          = p.registro_id
WHERE p.sublote_id IS NULL AND p.minutos >= 15
  AND r.fecha BETWEEN '2026-09-01' AND '2026-09-30'
GROUP BY d.codigo_tractor_snapshot, r.fecha
ORDER BY minutos_muertos DESC;

-- Avance acumulado por lote
SELECT v.sublote_id, MAX(v.nombre) AS lote,
       SUM(v.ha_cubiertas) AS ha_trabajadas, MAX(v.pct_avance) AS ultimo_pct
FROM dbo.CLI547_AGM_Ruta_visitas_sublote v
GROUP BY v.sublote_id ORDER BY ha_trabajadas DESC;
*/
