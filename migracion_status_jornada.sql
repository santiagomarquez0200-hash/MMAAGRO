-- ============================================================
-- MIGRACION: CLI547_AGM_MMA_STATUS_JORNADA
-- Renombra usuario_id -> usuario_erp_id
-- Reemplaza indice unico dispositivo+turno+fecha
--         por      usuario_erp_id+turno+fecha
-- ============================================================

-- 1. Agregar columna usuario_erp_id si no existe
IF NOT EXISTS (
    SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'dbo'
      AND TABLE_NAME   = 'CLI547_AGM_MMA_STATUS_JORNADA'
      AND COLUMN_NAME  = 'usuario_erp_id'
)
BEGIN
    ALTER TABLE dbo.CLI547_AGM_MMA_STATUS_JORNADA
        ADD usuario_erp_id INT NULL;

    -- Copiar valores desde usuario_id si esa columna existe
    IF EXISTS (
        SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
        WHERE TABLE_SCHEMA = 'dbo'
          AND TABLE_NAME   = 'CLI547_AGM_MMA_STATUS_JORNADA'
          AND COLUMN_NAME  = 'usuario_id'
    )
    BEGIN
        UPDATE dbo.CLI547_AGM_MMA_STATUS_JORNADA
           SET usuario_erp_id = usuario_id;
    END

    -- Hacer NOT NULL despues de poblar
    ALTER TABLE dbo.CLI547_AGM_MMA_STATUS_JORNADA
        ALTER COLUMN usuario_erp_id INT NOT NULL;

    PRINT 'usuario_erp_id agregado y poblado.';
END
ELSE
BEGIN
    PRINT 'usuario_erp_id ya existia, sin cambios.';
END
GO

-- 2. Agregar columna calculada jornada_fecha si no existe
IF NOT EXISTS (
    SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'dbo'
      AND TABLE_NAME   = 'CLI547_AGM_MMA_STATUS_JORNADA'
      AND COLUMN_NAME  = 'jornada_fecha'
)
BEGIN
    ALTER TABLE dbo.CLI547_AGM_MMA_STATUS_JORNADA
        ADD jornada_fecha AS CAST(jornada_inicio_at AS DATE) PERSISTED;
    PRINT 'jornada_fecha agregada.';
END
GO

-- 3. Quitar indice viejo basado en dispositivo_id (si existe)
IF EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name      = 'uq_status_jornada_dispositivo_turno'
      AND object_id = OBJECT_ID('dbo.CLI547_AGM_MMA_STATUS_JORNADA')
)
BEGIN
    DROP INDEX uq_status_jornada_dispositivo_turno
        ON dbo.CLI547_AGM_MMA_STATUS_JORNADA;
    PRINT 'Indice dispositivo_turno eliminado.';
END
GO

-- 4. Crear nuevo indice unico basado en usuario_erp_id (si no existe)
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name      = 'uq_status_jornada_usuario_turno'
      AND object_id = OBJECT_ID('dbo.CLI547_AGM_MMA_STATUS_JORNADA')
)
BEGIN
    CREATE UNIQUE INDEX uq_status_jornada_usuario_turno
        ON dbo.CLI547_AGM_MMA_STATUS_JORNADA (usuario_erp_id, turno, jornada_fecha);
    PRINT 'Indice usuario_turno creado.';
END
GO

-- 5. Verificar resultado
SELECT
    COLUMN_NAME, DATA_TYPE, IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'dbo'
  AND TABLE_NAME   = 'CLI547_AGM_MMA_STATUS_JORNADA'
ORDER BY ORDINAL_POSITION;

SELECT
    i.name AS indice,
    STRING_AGG(c.name, ', ') WITHIN GROUP (ORDER BY ic.key_ordinal) AS columnas
FROM sys.indexes i
JOIN sys.index_columns ic ON ic.object_id = i.object_id AND ic.index_id = i.index_id
JOIN sys.columns c        ON c.object_id  = ic.object_id AND c.column_id = ic.column_id
WHERE i.object_id = OBJECT_ID('dbo.CLI547_AGM_MMA_STATUS_JORNADA')
GROUP BY i.name;
