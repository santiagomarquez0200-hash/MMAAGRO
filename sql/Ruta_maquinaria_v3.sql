-- =============================================================================
-- Tabla: CLI547_AGM_Ruta_maquinaria  (v3 — ruta WKT por jornada)
-- Propósito: almacenar la ruta completa de cada registro como una sola fila
--            con tipo GEOGRAPHY (LineString o Point cuando solo hay 1 punto).
--            Reemplaza los N filas de CLI547_AGM_Punto_gps_maquinaria como
--            destino de sincronización; la tabla de puntos sigue existiendo
--            para compatibilidad con APKs anteriores.
-- Ejecutar UNA sola vez en la base de datos objetivo.
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
        sincronizado_at     DATETIME2(0)     NOT NULL DEFAULT SYSUTCDATETIME(),
        CONSTRAINT PK_CLI547_AGM_Ruta_maquinaria PRIMARY KEY (id),
        CONSTRAINT UQ_CLI547_AGM_Ruta_registro    UNIQUE (registro_id)
    );

    -- Índice espacial para consultas de proximidad / bounding box
    CREATE SPATIAL INDEX SX_CLI547_AGM_Ruta_maquinaria_geog
        ON dbo.CLI547_AGM_Ruta_maquinaria (ruta_geog)
        USING GEOGRAPHY_GRID
        WITH (GRIDS = (MEDIUM, MEDIUM, MEDIUM, MEDIUM));

    PRINT 'Tabla CLI547_AGM_Ruta_maquinaria creada correctamente.';
END
ELSE
BEGIN
    PRINT 'Tabla CLI547_AGM_Ruta_maquinaria ya existe — omitida.';
END
GO
