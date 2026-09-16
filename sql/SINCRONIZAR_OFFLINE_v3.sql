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
-- Ejecutar en orden:
--   1. cleanup_gps_v2.sql          (borra tabla + SPs v2)
--   2. Ruta_maquinaria_v3.sql      (crea tabla nueva)
--   3. SINCRONIZAR_OFFLINE_v3.sql  (este archivo — reemplaza el SP)
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
            @v_gps_sublotes          NVARCHAR(MAX);

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
