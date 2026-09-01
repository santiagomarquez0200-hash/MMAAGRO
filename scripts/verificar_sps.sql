-- =============================================================================
-- verificar_sps.sql
-- Verifica que los SPs del esquema AGKMMA estén correctamente actualizados:
--   1. Parámetro @p_registro_id declarado como NVARCHAR(36)
--   2. Uso de TRY_CONVERT para validar el GUID
--   3. Presencia de SELECT final que devuelve el result set al proxy REST
-- Ejecutar en la base de datos donde reside el esquema AGKMMA.
-- =============================================================================

SET NOCOUNT ON;
GO

DECLARE @SPs TABLE (nombre NVARCHAR(200));
INSERT INTO @SPs VALUES
    ('AGKMMA.SP_MMA_REGISTRAR_BIN'),
    ('AGKMMA.SP_MMA_REGISTRAR_PARO'),
    ('AGKMMA.SP_MMA_GUARDAR_CHECKLIST'),
    ('AGKMMA.SP_MMA_CERRAR_TURNO'),
    ('AGKMMA.SP_MMA_APROBAR_REGISTRO');

-- =============================================================================
-- 1. Verificar que @p_registro_id es NVARCHAR(36) y NO UNIQUEIDENTIFIER
-- =============================================================================
PRINT '=== VERIFICACIÓN DE TIPO DE PARÁMETRO @p_registro_id ===';

SELECT
    SCHEMA_NAME(o.schema_id) + '.' + o.name   AS sp_nombre,
    p.name                                      AS param_nombre,
    TYPE_NAME(p.user_type_id)                   AS tipo_actual,
    p.max_length                                AS max_longitud,
    CASE
        WHEN TYPE_NAME(p.user_type_id) = 'nvarchar'
             AND p.max_length = 72   -- NVARCHAR(36) = 72 bytes en SQL Server
        THEN '✅ CORRECTO'
        WHEN TYPE_NAME(p.user_type_id) = 'uniqueidentifier'
        THEN '❌ DEBE SER NVARCHAR(36) — causará error en ERP'
        ELSE '⚠️ REVISAR MANUALMENTE'
    END AS estado
FROM sys.objects o
JOIN sys.parameters p ON p.object_id = o.object_id
WHERE o.type = 'P'
  AND SCHEMA_NAME(o.schema_id) + '.' + o.name IN (
      SELECT nombre FROM @SPs
  )
  AND p.name = '@p_registro_id'
ORDER BY sp_nombre;

-- =============================================================================
-- 2. Verificar presencia de TRY_CONVERT en la definición del SP
-- =============================================================================
PRINT '';
PRINT '=== VERIFICACIÓN DE TRY_CONVERT EN CUERPO DEL SP ===';

SELECT
    SCHEMA_NAME(o.schema_id) + '.' + o.name AS sp_nombre,
    CASE
        WHEN CHARINDEX('TRY_CONVERT', OBJECT_DEFINITION(o.object_id)) > 0
        THEN '✅ TRY_CONVERT presente'
        ELSE '❌ TRY_CONVERT AUSENTE — sin validación de GUID'
    END AS tiene_try_convert
FROM sys.objects o
WHERE o.type = 'P'
  AND SCHEMA_NAME(o.schema_id) + '.' + o.name IN (
      SELECT nombre FROM @SPs
  )
ORDER BY sp_nombre;

-- =============================================================================
-- 3. Verificar presencia de SELECT final (result set para el proxy)
-- =============================================================================
PRINT '';
PRINT '=== VERIFICACIÓN DE SELECT FINAL EN EL SP ===';

SELECT
    SCHEMA_NAME(o.schema_id) + '.' + o.name AS sp_nombre,
    CASE
        WHEN CHARINDEX('SELECT @p_success', OBJECT_DEFINITION(o.object_id)) > 0
          OR CHARINDEX('SELECT @p_success AS success', OBJECT_DEFINITION(o.object_id)) > 0
        THEN '✅ SELECT final presente'
        ELSE '❌ SELECT final AUSENTE — el proxy REST no recibirá resultado'
    END AS tiene_select_final
FROM sys.objects o
WHERE o.type = 'P'
  AND SCHEMA_NAME(o.schema_id) + '.' + o.name IN (
      SELECT nombre FROM @SPs
  )
ORDER BY sp_nombre;

-- =============================================================================
-- 4. Verificar que @v_registro_id se usa internamente (no @p_registro_id)
-- =============================================================================
PRINT '';
PRINT '=== VERIFICACIÓN DE USO DE @v_registro_id EN CUERPO ===';

SELECT
    SCHEMA_NAME(o.schema_id) + '.' + o.name AS sp_nombre,
    CASE
        WHEN CHARINDEX('@v_registro_id', OBJECT_DEFINITION(o.object_id)) > 0
        THEN '✅ Usa @v_registro_id (variable convertida)'
        ELSE '⚠️ No usa @v_registro_id — verificar si se usa @p_registro_id directamente'
    END AS usa_variable_convertida
FROM sys.objects o
WHERE o.type = 'P'
  AND SCHEMA_NAME(o.schema_id) + '.' + o.name IN (
      SELECT nombre FROM @SPs
  )
ORDER BY sp_nombre;

-- =============================================================================
-- 5. Resumen consolidado
-- =============================================================================
PRINT '';
PRINT '=== RESUMEN CONSOLIDADO ===';

SELECT
    SCHEMA_NAME(o.schema_id) + '.' + o.name AS sp_nombre,
    CASE
        WHEN TYPE_NAME(p.user_type_id) = 'nvarchar' AND p.max_length = 72
        THEN '✅' ELSE '❌'
    END AS param_nvarchar36,
    CASE
        WHEN CHARINDEX('TRY_CONVERT', OBJECT_DEFINITION(o.object_id)) > 0
        THEN '✅' ELSE '❌'
    END AS try_convert,
    CASE
        WHEN CHARINDEX('SELECT @p_success', OBJECT_DEFINITION(o.object_id)) > 0
        THEN '✅' ELSE '❌'
    END AS select_final,
    CASE
        WHEN CHARINDEX('@v_registro_id', OBJECT_DEFINITION(o.object_id)) > 0
        THEN '✅' ELSE '⚠️'
    END AS variable_interna,
    CASE
        WHEN TYPE_NAME(p.user_type_id) = 'nvarchar' AND p.max_length = 72
             AND CHARINDEX('TRY_CONVERT', OBJECT_DEFINITION(o.object_id)) > 0
             AND CHARINDEX('SELECT @p_success', OBJECT_DEFINITION(o.object_id)) > 0
             AND CHARINDEX('@v_registro_id', OBJECT_DEFINITION(o.object_id)) > 0
        THEN '✅ LISTO PARA PRODUCCIÓN'
        ELSE '❌ REQUIERE CORRECCIÓN'
    END AS estado_final
FROM sys.objects o
LEFT JOIN sys.parameters p
    ON p.object_id = o.object_id AND p.name = '@p_registro_id'
WHERE o.type = 'P'
  AND SCHEMA_NAME(o.schema_id) + '.' + o.name IN (
      SELECT nombre FROM @SPs
  )
ORDER BY sp_nombre;

PRINT '';
PRINT 'Verificación completada. Corregir cualquier fila con ❌ ejecutando spsactualizados.sql';
GO
