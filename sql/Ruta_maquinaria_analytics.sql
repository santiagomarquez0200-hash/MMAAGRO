-- =============================================================================
-- ALTER TABLE: CLI547_AGM_Ruta_maquinaria — columnas de analytics GPS
-- Ejecutar UNA sola vez. Idempotente (verifica existencia antes de agregar).
-- Complementa Ruta_maquinaria_v3.sql — no la reemplaza.
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
IF NOT EXISTS (
    SELECT 1 FROM sys.columns
    WHERE object_id = OBJECT_ID('dbo.CLI547_AGM_Ruta_maquinaria') AND name = 'sublotes_trabajados'
)
    ALTER TABLE dbo.CLI547_AGM_Ruta_maquinaria ADD sublotes_trabajados NVARCHAR(MAX) NULL;

PRINT 'CLI547_AGM_Ruta_maquinaria: columnas analytics agregadas correctamente.';
GO
