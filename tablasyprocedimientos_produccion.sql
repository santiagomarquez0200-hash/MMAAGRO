    -- =============================================================================
    -- AGROMETRICS - MMA APK (Módulo Maquinaria Agrícola)
    -- SCRIPT ÚNICO PARA PRODUCCIÓN - VERSIÓN 8.0.0 (Enterprise)
    -- Esquema : dbo  (SQL Server — base de datos del ERP)
    -- Prefijo tablas  : CLI547_MMA_*
    -- Prefijo SPs     : CLI547_AGMSP_MMA_*
    -- Incluye:
    --   - Tablas estructurales (tractor + vehículo)
    --   - Sublabores y Marchas
    --   - Incumplimientos y auditoría
    --   - SP unificado para sincronización (con sublabores/marchas)
    --   - SP de cierre extendido, dashboard admin, etc.
    --   - SP sesiones dispositivo y lectura portero
    --   - Índices, vistas, triggers, datos de catálogo
    -- =============================================================================

    -- 2. TABLAS ESTRUCTURALES (con IF NOT EXISTS)
    -- 2.1 Procesos
    IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA='dbo' AND TABLE_NAME='CLI547_MMA_PROCESOS')
    BEGIN
        CREATE TABLE dbo.CLI547_AGM_MMA_PROCESOS (
            id                      INT IDENTITY(1,1) PRIMARY KEY,
            codigo                  VARCHAR(20)  NOT NULL UNIQUE,
            nombre                  VARCHAR(100) NOT NULL UNIQUE,
            descripcion             VARCHAR(MAX),
            requiere_bines          BIT          NOT NULL DEFAULT 0,
            especie_botanica_erp_id INT,
            activo                  BIT          NOT NULL DEFAULT 1,
            created_at              DATETIME2    NOT NULL DEFAULT GETDATE(),
            updated_at              DATETIME2    NOT NULL DEFAULT GETDATE()
        );
    END

    -- 2.2 Subprocesos
    IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA='dbo' AND TABLE_NAME='CLI547_MMA_SUBPROCESOS')
    BEGIN
        CREATE TABLE dbo.CLI547_AGM_MMA_SUBPROCESOS (
            id           INT IDENTITY(1,1) PRIMARY KEY,
            proceso_id   INT NOT NULL REFERENCES dbo.CLI547_MMA_PROCESOS(id),
            nombre       NVARCHAR(200) NOT NULL,
            codigo       VARCHAR(50) NOT NULL,
            descripcion  NVARCHAR(500) NULL,
            activo       BIT NOT NULL DEFAULT 1,
            created_at   DATETIME2 NOT NULL DEFAULT GETUTCDATE()
        );
    END

    -- 2.3 Cajas de cambios
    IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA='dbo' AND TABLE_NAME='CLI547_MMA_CAJAS_CAMBIOS')
    BEGIN
        CREATE TABLE dbo.CLI547_AGM_MMA_CAJAS_CAMBIOS (
            id      INT IDENTITY(1,1) PRIMARY KEY,
            nombre  VARCHAR(50) NOT NULL UNIQUE
        );
    END

    -- Marchas de trabajo: T=Tractor, H=Hidráulico, L=Lento
    INSERT INTO dbo.CLI547_AGM_MMA_CAJAS_CAMBIOS (nombre)
    SELECT v.nombre FROM (VALUES
        ('T-1'),('T-2'),('T-3'),('T-4'),
        ('H-1'),('H-2'),('H-3'),('H-4'),
        ('L-1'),('L-2'),('L-3'),('L-4')
    ) v(nombre)
    WHERE NOT EXISTS (
        SELECT 1 FROM dbo.CLI547_AGM_MMA_CAJAS_CAMBIOS WHERE nombre = v.nombre
    );

    -- 2.4 Tipos de paro
    IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA='dbo' AND TABLE_NAME='CLI547_MMA_TIPOS_PARO')
    BEGIN
        CREATE TABLE dbo.CLI547_AGM_MMA_TIPOS_PARO (
            id               INT IDENTITY(1,1) PRIMARY KEY,
            codigo           VARCHAR(30) NOT NULL UNIQUE,
            nombre           VARCHAR(100) NOT NULL,
            requiere_galones BIT NOT NULL DEFAULT 0,
            requiere_equipo  BIT NOT NULL DEFAULT 0,
            activo           BIT NOT NULL DEFAULT 1
        );
    END

    -- 2.5 Checklist categorías
    IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA='dbo' AND TABLE_NAME='CLI547_MMA_CHECKLIST_CATEGORIAS')
    BEGIN
        CREATE TABLE dbo.CLI547_AGM_MMA_CHECKLIST_CATEGORIAS (
            id      INT IDENTITY(1,1) PRIMARY KEY,
            nombre  VARCHAR(100) NOT NULL UNIQUE,
            orden   SMALLINT     NOT NULL DEFAULT 0
        );
    END

    -- 2.6 Checklist items (con tipo_registro)
    IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA='dbo' AND TABLE_NAME='CLI547_MMA_CHECKLIST_ITEMS_CATALOGO')
    BEGIN
        CREATE TABLE dbo.CLI547_AGM_MMA_CHECKLIST_ITEMS_CATALOGO (
            id           INT IDENTITY(1,1) PRIMARY KEY,
            categoria_id INT NOT NULL REFERENCES dbo.CLI547_AGM_MMA_CHECKLIST_CATEGORIAS(id),
            nombre       VARCHAR(200) NOT NULL,
            descripcion  VARCHAR(MAX),
            orden        SMALLINT     NOT NULL DEFAULT 0,
            activo       BIT          NOT NULL DEFAULT 1,
            tipo_registro VARCHAR(20) NOT NULL DEFAULT 'tractor' CHECK (tipo_registro IN ('tractor', 'vehiculo'))
        );
    END

    -- 2.7 Registros diarios (cabecera tractor+vehículo)
    IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA='dbo' AND TABLE_NAME='CLI547_AGM_MMA_REGISTROS_DIARIOS')
    BEGIN
        CREATE TABLE dbo.CLI547_AGM_MMA_REGISTROS_DIARIOS (
            id                          UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
            numero_registro             VARCHAR(30) NOT NULL UNIQUE,
            fecha                       DATE        NOT NULL,
            turno                       VARCHAR(10) NOT NULL DEFAULT 'dia' CHECK (turno IN ('dia','noche')),
            proceso_id                  INT NULL REFERENCES dbo.CLI547_AGM_MMA_PROCESOS(id),
            subproceso_id               INT NULL REFERENCES dbo.CLI547_AGM_MMA_SUBPROCESOS(id),
            subproceso_nombre           NVARCHAR(200) NULL,
            cultivo_id_erp              INT NULL,
            nombre_cultivo_snapshot     VARCHAR(150),
            operador_id_erp             INT NOT NULL,
            nombre_operador_snapshot    VARCHAR(300),
            supervisor_id_erp           INT,
            nombre_supervisor_snapshot  VARCHAR(300),
            tractor_id_erp              INT NOT NULL,
            codigo_tractor_snapshot     VARCHAR(100),
            implemento_id_erp           INT,
            codigo_implemento_snapshot  VARCHAR(100),
            caja_cambios_id             INT REFERENCES dbo.CLI547_AGM_MMA_CAJAS_CAMBIOS(id),
            estado                      VARCHAR(20) NOT NULL DEFAULT 'borrador' CHECK (estado IN ('borrador','completado','aprobado','rechazado')),
            tipo_registro               VARCHAR(20) NOT NULL DEFAULT 'tractor' CHECK (tipo_registro IN ('tractor', 'vehiculo')),
            observaciones_maq           VARCHAR(MAX),
            firma_operador              NVARCHAR(MAX) NULL,
            aprobado_por_erp            INT,
            aprobado_at                 DATETIME2,
            motivo_rechazo              VARCHAR(MAX),
            dispositivo_id              VARCHAR(150),
            sincronizado_erp            BIT NOT NULL DEFAULT 0,
            sincronizado_at             DATETIME2,
            jornada_inicio_at           DATETIME2 NULL,
            jornada_fin_at              DATETIME2 NULL,
            created_by_erp              INT NOT NULL,
            created_at                  DATETIME2 NOT NULL DEFAULT GETDATE(),
            updated_at                  DATETIME2 NOT NULL DEFAULT GETDATE(),
            proceso_vehiculo            VARCHAR(50) NULL,
            cantidad_tancadas           INT NULL
        );
    END
    ELSE
    BEGIN
        IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='dbo' AND TABLE_NAME='CLI547_AGM_MMA_REGISTROS_DIARIOS' AND COLUMN_NAME='proceso_vehiculo')
            ALTER TABLE dbo.CLI547_AGM_MMA_REGISTROS_DIARIOS ADD proceso_vehiculo VARCHAR(50) NULL;
        IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='dbo' AND TABLE_NAME='CLI547_AGM_MMA_REGISTROS_DIARIOS' AND COLUMN_NAME='cantidad_tancadas')
            ALTER TABLE dbo.CLI547_AGM_MMA_REGISTROS_DIARIOS ADD cantidad_tancadas INT NULL;
        IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='dbo' AND TABLE_NAME='CLI547_AGM_MMA_REGISTROS_DIARIOS' AND COLUMN_NAME='subproceso_id')
            ALTER TABLE dbo.CLI547_AGM_MMA_REGISTROS_DIARIOS ADD subproceso_id INT NULL REFERENCES dbo.CLI547_AGM_MMA_SUBPROCESOS(id);
        IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='dbo' AND TABLE_NAME='CLI547_AGM_MMA_REGISTROS_DIARIOS' AND COLUMN_NAME='subproceso_nombre')
            ALTER TABLE dbo.CLI547_AGM_MMA_REGISTROS_DIARIOS ADD subproceso_nombre NVARCHAR(200) NULL;
        IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='dbo' AND TABLE_NAME='CLI547_AGM_MMA_REGISTROS_DIARIOS' AND COLUMN_NAME='firma_operador')
            ALTER TABLE dbo.CLI547_AGM_MMA_REGISTROS_DIARIOS ADD firma_operador NVARCHAR(MAX) NULL;
        IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='dbo' AND TABLE_NAME='CLI547_AGM_MMA_REGISTROS_DIARIOS' AND COLUMN_NAME='proceso_id' AND IS_NULLABLE='NO')
            ALTER TABLE dbo.CLI547_AGM_MMA_REGISTROS_DIARIOS ALTER COLUMN proceso_id INT NULL;
        IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='dbo' AND TABLE_NAME='CLI547_AGM_MMA_REGISTROS_DIARIOS' AND COLUMN_NAME='cultivo_id_erp' AND IS_NULLABLE='NO')
            ALTER TABLE dbo.CLI547_AGM_MMA_REGISTROS_DIARIOS ALTER COLUMN cultivo_id_erp INT NULL;
    END

    -- 2.8 Status jornada
    -- NOTA: SQL Server no permite expresiones (CAST/funciones) directamente en
    -- CONSTRAINT UNIQUE dentro de CREATE TABLE. La solución es una columna
    -- calculada PERSISTED (determinista) y el índice único sobre esa columna.
    IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA='dbo' AND TABLE_NAME='CLI547_AGM_MMA_STATUS_JORNADA')
    BEGIN
        CREATE TABLE dbo.CLI547_AGM_MMA_STATUS_JORNADA (
            id                 INT IDENTITY(1,1) PRIMARY KEY,
            usuario_erp_id     INT NOT NULL,
            dispositivo_id     VARCHAR(100) NOT NULL,
            turno              VARCHAR(10) NOT NULL,
            jornada_inicio_at  DATETIME2 NOT NULL,
            -- Columna calculada para indexar solo la parte de fecha (sin hora)
            jornada_fecha      AS CAST(jornada_inicio_at AS DATE) PERSISTED,
            jornada_fin_at     DATETIME2 NULL,
            created_at         DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
            updated_at         DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
            CONSTRAINT uq_status_jornada_dispositivo_turno UNIQUE (dispositivo_id, turno, jornada_fecha)
        );
    END

    -- Migración para tablas existentes que no tengan jornada_fecha ni el índice único.
    -- Si la tabla ya existía (creada con el script anterior defectuoso), se agrega
    -- la columna calculada y el índice único sin tocar los datos.
    IF NOT EXISTS (
        SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
        WHERE TABLE_SCHEMA = 'dbo'
          AND TABLE_NAME   = 'CLI547_AGM_MMA_STATUS_JORNADA'
          AND COLUMN_NAME  = 'jornada_fecha'
    )
    BEGIN
        ALTER TABLE dbo.CLI547_AGM_MMA_STATUS_JORNADA
            ADD jornada_fecha AS CAST(jornada_inicio_at AS DATE) PERSISTED;
    END

    IF NOT EXISTS (
        SELECT 1 FROM sys.indexes
        WHERE name      = 'uq_status_jornada_dispositivo_turno'
          AND object_id = OBJECT_ID('dbo.CLI547_AGM_MMA_STATUS_JORNADA')
    )
    BEGIN
        CREATE UNIQUE INDEX uq_status_jornada_dispositivo_turno
            ON dbo.CLI547_AGM_MMA_STATUS_JORNADA (dispositivo_id, turno, jornada_fecha);
    END

    -- 2.9 Horómetros
    IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA='dbo' AND TABLE_NAME='CLI547_AGM_MMA_HOROMETROS')
    BEGIN
        CREATE TABLE dbo.CLI547_AGM_MMA_HOROMETROS (
            id                  UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
            registro_id         UNIQUEIDENTIFIER NOT NULL UNIQUE REFERENCES dbo.CLI547_AGM_MMA_REGISTROS_DIARIOS(id) ON DELETE CASCADE,
            tractor_inicio      DECIMAL(10,1),
            tractor_final       DECIMAL(10,1),
            horas_tractor       AS (CASE WHEN tractor_final IS NOT NULL AND tractor_inicio IS NOT NULL THEN tractor_final - tractor_inicio ELSE NULL END) PERSISTED,
            implemento_inicio   DECIMAL(10,1),
            implemento_final    DECIMAL(10,1),
            horas_implemento    AS (CASE WHEN implemento_final IS NOT NULL AND implemento_inicio IS NOT NULL THEN implemento_final - implemento_inicio ELSE NULL END) PERSISTED,
            created_at          DATETIME2 NOT NULL DEFAULT GETDATE(),
            updated_at          DATETIME2 NOT NULL DEFAULT GETDATE()
        );
    END

    -- 2.10 Tiempos de turno (con hora_refrigerio VARCHAR)
    IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA='dbo' AND TABLE_NAME='CLI547_AGM_MMA_TIEMPOS_TURNO')
    BEGIN
        CREATE TABLE dbo.CLI547_AGM_MMA_TIEMPOS_TURNO (
            id                      UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
            registro_id             UNIQUEIDENTIFIER NOT NULL UNIQUE REFERENCES dbo.CLI547_AGM_MMA_REGISTROS_DIARIOS(id) ON DELETE CASCADE,
            hora_salida_taller      TIME,
            hora_llegada_punto      TIME,
            hora_salida_punto       TIME,
            hora_llegada_taller     TIME,
            hora_refrigerio         VARCHAR(30) NULL,
            minutos_efectivos       AS (CASE WHEN hora_salida_punto IS NOT NULL AND hora_llegada_punto IS NOT NULL THEN DATEDIFF(MINUTE, hora_llegada_punto, hora_salida_punto) ELSE NULL END) PERSISTED,
            created_at              DATETIME2 NOT NULL DEFAULT GETDATE(),
            updated_at              DATETIME2 NOT NULL DEFAULT GETDATE()
        );
    END

    -- 2.11 Lotes
    IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA='dbo' AND TABLE_NAME='CLI547_AGM_MMA_REGISTROS_LOTES')
    BEGIN
        CREATE TABLE dbo.CLI547_AGM_MMA_REGISTROS_LOTES (
            id                  UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
            registro_id         UNIQUEIDENTIFIER NOT NULL REFERENCES dbo.CLI547_AGM_MMA_REGISTROS_DIARIOS(id) ON DELETE CASCADE,
            lote_id_erp         INT NOT NULL,
            finca_id_erp        INT NOT NULL,
            lote_codigo_snapshot  VARCHAR(50),
            sublote_snapshot    VARCHAR(200),
            area_trabajada_ha   DECIMAL(8,4),
            observacion         VARCHAR(MAX),
            CONSTRAINT UQ_registro_lote UNIQUE(registro_id, lote_id_erp)
        );
    END

    -- 2.12 Bines
    IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA='dbo' AND TABLE_NAME='CLI547_AGM_MMA_COSECHA_BINES')
    BEGIN
        CREATE TABLE dbo.CLI547_AGM_MMA_COSECHA_BINES (
            id              UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
            registro_id     UNIQUEIDENTIFIER NOT NULL REFERENCES dbo.CLI547_AGM_MMA_REGISTROS_DIARIOS(id) ON DELETE CASCADE,
            franja_horaria  VARCHAR(10) NOT NULL,
            turno_franja    VARCHAR(5)  NOT NULL CHECK (turno_franja IN ('am','pm')),
            cantidad        SMALLINT    NOT NULL DEFAULT 0 CHECK (cantidad >= 0),
            CONSTRAINT UQ_bines_franja UNIQUE(registro_id, franja_horaria)
        );
    END

    -- 2.13 Paros de tractor
    IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA='dbo' AND TABLE_NAME='CLI547_AGM_MMA_PAROS_EQUIPOS')
    BEGIN
        CREATE TABLE dbo.CLI547_AGM_MMA_PAROS_EQUIPOS (
            id              UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
            registro_id     UNIQUEIDENTIFIER NOT NULL REFERENCES dbo.CLI547_AGM_MMA_REGISTROS_DIARIOS(id) ON DELETE CASCADE,
            tipo_paro_id    INT NOT NULL REFERENCES dbo.CLI547_AGM_MMA_TIPOS_PARO(id),
            motivo          VARCHAR(MAX),
            equipo          VARCHAR(150),
            hora_inicio     TIME NOT NULL,
            hora_final      TIME,
            galones         DECIMAL(8,2),
            duracion_min    AS (CASE WHEN hora_final IS NOT NULL THEN DATEDIFF(MINUTE, hora_inicio, hora_final) ELSE NULL END) PERSISTED,
            created_at      DATETIME2 NOT NULL DEFAULT GETDATE()
        );
    END

    -- 2.14 Checklist resultados
    IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA='dbo' AND TABLE_NAME='CLI547_AGM_MMA_CHECKLIST_RESULTADOS')
    BEGIN
        CREATE TABLE dbo.CLI547_AGM_MMA_CHECKLIST_RESULTADOS (
            id          UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
            registro_id UNIQUEIDENTIFIER NOT NULL REFERENCES dbo.CLI547_AGM_MMA_REGISTROS_DIARIOS(id) ON DELETE CASCADE,
            item_id     INT NOT NULL REFERENCES dbo.CLI547_AGM_MMA_CHECKLIST_ITEMS_CATALOGO(id),
            resultado   VARCHAR(4)  NOT NULL CHECK (resultado IN ('bien','mal','na')),
            observacion VARCHAR(MAX),
            foto_url    VARCHAR(MAX),
            CONSTRAINT UQ_checklist_item UNIQUE(registro_id, item_id)
        );
    END

    -- 2.15 Combustible vehículo
    IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA='dbo' AND TABLE_NAME='CLI547_AGM_MMA_COMBUSTIBLE_VEHICULO')
    BEGIN
        CREATE TABLE dbo.CLI547_AGM_MMA_COMBUSTIBLE_VEHICULO (
            id           INT IDENTITY(1,1) PRIMARY KEY,
            registro_id  UNIQUEIDENTIFIER NOT NULL REFERENCES dbo.CLI547_AGM_MMA_REGISTROS_DIARIOS(id) ON DELETE CASCADE,
            glns         DECIMAL(10,2) NULL,
            hora_inicio  TIME NULL,
            hora_final   TIME NULL
        );
    END

    -- 2.16 Paros vehículo
    IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA='dbo' AND TABLE_NAME='CLI547_AGM_MMA_PAROS_VEHICULO')
    BEGIN
        CREATE TABLE dbo.CLI547_AGM_MMA_PAROS_VEHICULO (
            id           INT IDENTITY(1,1) PRIMARY KEY,
            registro_id  UNIQUEIDENTIFIER NOT NULL REFERENCES dbo.CLI547_AGM_MMA_REGISTROS_DIARIOS(id) ON DELETE CASCADE,
            motivo       NVARCHAR(250) NULL,
            hora_inicio  TIME NULL,
            hora_final   TIME NULL
        );
    END

    -- 2.17 Sublabores (solo tractor)
    IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA='dbo' AND TABLE_NAME='CLI547_AGM_MMA_REGISTROS_SUBLABORES')
    BEGIN
        CREATE TABLE dbo.CLI547_AGM_MMA_REGISTROS_SUBLABORES (
            id              INT IDENTITY(1,1) PRIMARY KEY,
            registro_id     UNIQUEIDENTIFIER NOT NULL REFERENCES dbo.CLI547_AGM_MMA_REGISTROS_DIARIOS(id) ON DELETE CASCADE,
            sublabor_nombre NVARCHAR(200) NOT NULL,
            created_at      DATETIME2 NOT NULL DEFAULT GETDATE()
        );
        CREATE INDEX idx_sublabores_registro ON dbo.CLI547_AGM_MMA_REGISTROS_SUBLABORES(registro_id);
    END

    -- 2.18 Marchas (solo tractor)
    IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA='dbo' AND TABLE_NAME='CLI547_AGM_MMA_REGISTROS_MARCHAS')
    BEGIN
        CREATE TABLE dbo.CLI547_AGM_MMA_REGISTROS_MARCHAS (
            id            INT IDENTITY(1,1) PRIMARY KEY,
            registro_id   UNIQUEIDENTIFIER NOT NULL REFERENCES dbo.CLI547_AGM_MMA_REGISTROS_DIARIOS(id) ON DELETE CASCADE,
            marcha_codigo VARCHAR(10) NOT NULL,
            horas_uso     DECIMAL(6,2) NULL,
            created_at    DATETIME2 NOT NULL DEFAULT GETDATE()
        );
        CREATE INDEX idx_marchas_registro ON dbo.CLI547_AGM_MMA_REGISTROS_MARCHAS(registro_id);
    END

    -- 2.19 Incumplimientos (para admin)
    IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA='dbo' AND TABLE_NAME='CLI547_AGM_MMA_INCUMPLIMIENTOS')
    BEGIN
        CREATE TABLE dbo.CLI547_AGM_MMA_INCUMPLIMIENTOS (
            id                   INT IDENTITY(1,1) PRIMARY KEY,
            usuario_erp_id       INT              NOT NULL,
            nombre_usuario       NVARCHAR(300)    NOT NULL,
            fecha_jornada        DATE             NOT NULL,
            turno                VARCHAR(10)      NOT NULL,
            tipo_incumplimiento  VARCHAR(80)      NOT NULL,
            detalle              NVARCHAR(MAX)    NULL,
            dispositivo_id       VARCHAR(150)     NULL,
            firestore_doc_id     VARCHAR(200)     NULL,
            created_at           DATETIME2        NOT NULL DEFAULT GETDATE()
        );
        CREATE INDEX idx_incumplimientos_usuario ON dbo.CLI547_AGM_MMA_INCUMPLIMIENTOS(usuario_erp_id, fecha_jornada);
    END

    -- 2.20 Portero lecturas
    IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA='dbo' AND TABLE_NAME='CLI547_AGM_MMA_PORTERO_LECTURAS')
    BEGIN
        CREATE TABLE dbo.CLI547_AGM_MMA_PORTERO_LECTURAS (
            id                   UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID() PRIMARY KEY,
            portero_id_erp       INT NOT NULL,
            tractor_id_erp       INT NULL,
            tractor_codigo       VARCHAR(50) NULL,
            tractor_leido_at     DATETIME2 NULL,
            implemento_id_erp    INT NULL,
            implemento_codigo    VARCHAR(50) NULL,
            implemento_leido_at  DATETIME2 NULL,
            trabajador_id_erp    INT NULL,
            trabajador_codigo    VARCHAR(50) NULL,
            operador_leido_at    DATETIME2 NULL,
            cultivo_id_erp       INT NULL,
            cultivo_nombre       NVARCHAR(200) NULL,
            comentario           NVARCHAR(500) NULL,
            dispositivo_id       VARCHAR(100) NULL,
            hora_sincronizacion  DATETIME2 NULL,
            created_at           DATETIME2 NOT NULL DEFAULT GETUTCDATE()
        );
    END

    -- 2.21 Notificaciones
    IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA='dbo' AND TABLE_NAME='CLI547_AGM_MMA_NOTIFICACIONES')
    BEGIN
        CREATE TABLE dbo.CLI547_AGM_MMA_NOTIFICACIONES (
            id              INT IDENTITY(1,1) PRIMARY KEY,
            usuario_erp_id  INT NOT NULL,
            tipo            VARCHAR(50) NOT NULL,
            titulo          NVARCHAR(200) NOT NULL,
            cuerpo          NVARCHAR(500) NULL,
            leida           BIT NOT NULL DEFAULT 0,
            created_at      DATETIME2 NOT NULL DEFAULT GETUTCDATE()
        );
    END

    -- 2.22 Sesiones dispositivo
    IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA='dbo' AND TABLE_NAME='CLI547_AGM_MMA_SESIONES_DISPOSITIVO')
    BEGIN
        CREATE TABLE dbo.CLI547_AGM_MMA_SESIONES_DISPOSITIVO (
            id              UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
            usuario_erp_id  INT NOT NULL,
            dispositivo_id  VARCHAR(150) NOT NULL,
            token           VARCHAR(500) NOT NULL UNIQUE,
            activo          BIT NOT NULL DEFAULT 1,
            creado_at       DATETIME2 NOT NULL DEFAULT GETDATE(),
            expira_at       DATETIME2 NOT NULL DEFAULT DATEADD(DAY, 30, GETDATE()),
            ultimo_uso      DATETIME2
        );
    END

    -- 2.23 Auditoría
    IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA='dbo' AND TABLE_NAME='CLI547_AGM_MMA_AUDIT_LOG')
    BEGIN
        CREATE TABLE dbo.CLI547_AGM_MMA_AUDIT_LOG (
            id          BIGINT IDENTITY(1,1) PRIMARY KEY,
            tabla       VARCHAR(80) NOT NULL,
            registro_pk VARCHAR(100) NOT NULL,
            accion      VARCHAR(10) NOT NULL CHECK (accion IN ('INSERT','UPDATE','DELETE')),
            datos_old   NVARCHAR(MAX),
            datos_new   NVARCHAR(MAX),
            usuario_erp_id  INT,
            ip          VARCHAR(45),
            created_at  DATETIME2 NOT NULL DEFAULT GETDATE()
        );
    END

    -- =============================================================================
    -- 2.24 Puntos GPS de trazabilidad de maquinaria
    -- Nombre físico: CLI547_AGM_Punto_gps_maquinaria  (definido por el cliente)
    -- Alimentado por: CLI547_AGMSP_MMA_SINCRONIZAR_OFFLINE  (campo ruta_gps del JSON)
    -- Captura: cada 2 minutos durante la jornada  → ~240 puntos por registro (8 h)
    -- Permite: reconstruir ruta del tractor, detectar paradas, calcular cobertura
    -- =============================================================================
    IF NOT EXISTS (
        SELECT 1 FROM INFORMATION_SCHEMA.TABLES
        WHERE TABLE_SCHEMA = 'dbo' AND TABLE_NAME = 'CLI547_AGM_Punto_gps_maquinaria'
    )
    BEGIN
        CREATE TABLE dbo.CLI547_AGM_Punto_gps_maquinaria (
            id           UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID(),
            registro_id  UNIQUEIDENTIFIER NOT NULL,           -- FK → CLI547_AGM_MMA_REGISTROS_DIARIOS
            latitud      FLOAT            NOT NULL,
            longitud     FLOAT            NOT NULL,
            precision_m  FLOAT            NULL,               -- Precisión GPS en metros
            altitud_m    FLOAT            NULL,               -- Altitud sobre el nivel del mar
            velocidad_ms INT              NULL,               -- Velocidad en m/s al momento de captura
            secuencia    INT              NOT NULL DEFAULT 0, -- Orden cronológico dentro del registro
            captured_at  DATETIME2(0)     NOT NULL,           -- Hora UTC exacta de captura en campo
            created_at   DATETIME2(0)     NOT NULL DEFAULT GETUTCDATE(),

            CONSTRAINT PK_GpsMaquinaria
                PRIMARY KEY CLUSTERED (id),

            CONSTRAINT FK_GpsMaquinaria_Registro
                FOREIGN KEY (registro_id)
                REFERENCES dbo.CLI547_AGM_MMA_REGISTROS_DIARIOS(id)
                ON DELETE CASCADE
        );

        -- Índice principal: reconstruir ruta de un registro (ORDER BY secuencia)
        CREATE INDEX IX_GpsMaquinaria_RegistroSecuencia
            ON dbo.CLI547_AGM_Punto_gps_maquinaria (registro_id, secuencia);

        -- Índice temporal: consultas de mapas por fecha/hora (admin dashboard)
        CREATE INDEX IX_GpsMaquinaria_CapturedAt
            ON dbo.CLI547_AGM_Punto_gps_maquinaria (captured_at);

        PRINT '>>> Tabla CLI547_AGM_Punto_gps_maquinaria creada correctamente.';
    END
    ELSE
        PRINT '>>> Tabla CLI547_AGM_Punto_gps_maquinaria ya existe — sin cambios.';
    GO

    -- 3. AGREGAR COLUMNAS A PROCESOS
    IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='dbo' AND TABLE_NAME='CLI547_AGM_MMA_PROCESOS' AND COLUMN_NAME='requiere_sublabores')
        ALTER TABLE dbo.CLI547_AGM_MMA_PROCESOS ADD requiere_sublabores BIT NOT NULL DEFAULT 0;
    UPDATE dbo.CLI547_AGM_MMA_PROCESOS SET requiere_sublabores = 1 WHERE codigo IN ('APLICACION', 'APLICACIONES');

    -- Distinguir procesos de tractor vs vehículo para filtrar el catálogo del APK
    IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='dbo' AND TABLE_NAME='CLI547_AGM_MMA_PROCESOS' AND COLUMN_NAME='tipo_registro')
        ALTER TABLE dbo.CLI547_AGM_MMA_PROCESOS ADD tipo_registro VARCHAR(20) NOT NULL DEFAULT 'tractor';

    -- Marcar los procesos exclusivos de vehículo
    UPDATE dbo.CLI547_AGM_MMA_PROCESOS
    SET tipo_registro = 'vehiculo'
    WHERE codigo IN ('REGADO_CAMINOS','TRASLADO_MANGUERAS','TRASLADO_MATERIALES',
                    'ABASTECIMIENTO','OTRO','CULTIVO','APLICACION');
    GO

    -- 4. ÍNDICES ADICIONALES
    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'idx_mma_rd_fecha')
        CREATE INDEX idx_mma_rd_fecha ON dbo.CLI547_AGM_MMA_REGISTROS_DIARIOS(fecha DESC);
    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'idx_mma_rd_estado')
        CREATE INDEX idx_mma_rd_estado ON dbo.CLI547_AGM_MMA_REGISTROS_DIARIOS(estado);
    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'idx_mma_rd_operador')
        CREATE INDEX idx_mma_rd_operador ON dbo.CLI547_AGM_MMA_REGISTROS_DIARIOS(operador_id_erp);
    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'idx_mma_rd_numero')
        CREATE INDEX idx_mma_rd_numero ON dbo.CLI547_AGM_MMA_REGISTROS_DIARIOS(numero_registro);
    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'idx_mma_rd_tipo')
        CREATE INDEX idx_mma_rd_tipo ON dbo.CLI547_AGM_MMA_REGISTROS_DIARIOS(tipo_registro);
    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'idx_mma_checklist_tipo')
        CREATE INDEX idx_mma_checklist_tipo ON dbo.CLI547_AGM_MMA_CHECKLIST_ITEMS_CATALOGO(tipo_registro);
    GO

    -- 5. MIGRACIONES DE COLUMNAS (idempotentes — se pueden ejecutar N veces)

    -- 5.1 hora_refrigerio: migrar TIME → VARCHAR(30) para soportar rangos "HH:mm - HH:mm"
    --     El IF NOT EXISTS de la tabla CREATE no altera columnas en tablas ya existentes.
    IF EXISTS (
        SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
        WHERE TABLE_SCHEMA='dbo' AND TABLE_NAME='CLI547_AGM_MMA_TIEMPOS_TURNO'
        AND COLUMN_NAME='hora_refrigerio' AND DATA_TYPE='time'
    )
    BEGIN
        ALTER TABLE dbo.CLI547_AGM_MMA_TIEMPOS_TURNO
            ALTER COLUMN hora_refrigerio VARCHAR(30) NULL;
    END
    GO

    -- 6. FUNCIÓN GENERAR NÚMERO REGISTRO
    CREATE OR ALTER FUNCTION dbo.CLI547_AGMSP_MMA_FN_GENERAR_NUMERO_REGISTRO (@p_fecha DATE, @p_tipo VARCHAR(20))
    RETURNS VARCHAR(30)
    AS
    BEGIN
        DECLARE @v_prefijo VARCHAR(20);
        IF @p_tipo = 'vehiculo' SET @v_prefijo = 'RV-' + FORMAT(@p_fecha, 'yyyyMMdd') + '-';
        ELSE SET @v_prefijo = 'RD-' + FORMAT(@p_fecha, 'yyyyMMdd') + '-';
        DECLARE @v_seq INT;
        SELECT @v_seq = COUNT(*) + 1 FROM dbo.CLI547_AGM_MMA_REGISTROS_DIARIOS WHERE numero_registro LIKE @v_prefijo + '%';
        RETURN @v_prefijo + RIGHT('000' + CAST(@v_seq AS VARCHAR(3)), 3);
    END;
    GO

    -- 7. PROCEDIMIENTOS ALMACENADOS (con soporte completo para sublabores y marchas)
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
            @v_ruta_gps NVARCHAR(MAX);  -- Array JSON de puntos GPS de trazabilidad
    
    BEGIN TRY    
        -- Extracción JSON    
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
        SET @v_paros = JSON_QUERY(@p_payload, '$.paros');    
        SET @v_checklist = JSON_QUERY(@p_payload, '$.checklist');    
        SET @v_lotes = JSON_QUERY(@p_payload, '$.lotes');    
        SET @v_bines = JSON_QUERY(@p_payload, '$.bines');    
        SET @v_sublabores = JSON_QUERY(@p_payload, '$.sublabores');
        SET @v_marchas = JSON_QUERY(@p_payload, '$.marchas');
        SET @v_ruta_gps  = JSON_QUERY(@p_payload, '$.ruta_gps');   -- Ruta GPS (opcional; ausente en registros sin GPS)

        IF @v_numero IS NULL THROW 50000, 'numero_registro es obligatorio', 1;    
        IF @v_fecha IS NULL THROW 50001, 'fecha es obligatoria y debe ser una fecha válida (yyyy-MM-dd)', 1;    
        IF @v_operador_id_erp IS NULL THROW 50002, 'operador_id_erp es obligatorio', 1;    
        IF @v_tractor_id_erp IS NULL THROW 50003, 'tractor_id_erp es obligatorio', 1;    
        IF @v_turno NOT IN ('dia', 'noche') THROW 50004, 'turno debe ser ''dia'' o ''noche''', 1;    
        IF @v_created_by_erp IS NULL THROW 50005, 'created_by_erp es obligatorio', 1;    
    
        BEGIN TRANSACTION;    
    
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
    
        -- Horómetros    
        MERGE CLI547_AGM_MMA_HOROMETROS AS target    
        USING (SELECT @p_registro_id AS rid) AS source ON target.registro_id = source.rid    
        WHEN MATCHED THEN UPDATE SET    
            tractor_inicio = COALESCE(@v_tractor_inicio, target.tractor_inicio),    
            tractor_final = COALESCE(@v_tractor_final, target.tractor_final),    
            implemento_inicio = COALESCE(@v_implemento_inicio, target.implemento_inicio),    
            implemento_final = COALESCE(@v_implemento_final, target.implemento_final),    
            updated_at = GETDATE()    
        WHEN NOT MATCHED THEN INSERT (registro_id, tractor_inicio, tractor_final, implemento_inicio, implemento_final)    
            VALUES (@p_registro_id, @v_tractor_inicio, @v_tractor_final, @v_implemento_inicio, @v_implemento_final);    
    
        -- Tiempos turno    
        MERGE CLI547_AGM_MMA_TIEMPOS_TURNO AS target    
        USING (SELECT @p_registro_id AS rid) AS source ON target.registro_id = source.rid    
        WHEN MATCHED THEN UPDATE SET    
            hora_salida_taller = COALESCE(@v_hora_salida_taller, target.hora_salida_taller),    
            hora_llegada_punto = COALESCE(@v_hora_llegada_punto, target.hora_llegada_punto),    
            hora_salida_punto = COALESCE(@v_hora_salida_punto, target.hora_salida_punto),    
            hora_llegada_taller = COALESCE(@v_hora_llegada_taller, target.hora_llegada_taller),    
            hora_refrigerio = COALESCE(@v_hora_refrigerio, target.hora_refrigerio),    
            updated_at = GETDATE()    
        WHEN NOT MATCHED THEN INSERT (registro_id, hora_salida_taller, hora_llegada_punto, hora_salida_punto, hora_llegada_taller, hora_refrigerio)    
            VALUES (@p_registro_id, @v_hora_salida_taller, @v_hora_llegada_punto, @v_hora_salida_punto, @v_hora_llegada_taller, @v_hora_refrigerio);    
    
        -- Checklist    
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
    
        -- Paros    
        IF @v_paros IS NOT NULL AND ISJSON(@v_paros) = 1    
        BEGIN    
            IF @v_tipo_registro = 'tractor'    
            BEGIN    
                DELETE FROM CLI547_AGM_MMA_PAROS_EQUIPOS WHERE registro_id = @p_registro_id;
                INSERT INTO CLI547_AGM_MMA_PAROS_EQUIPOS (id, registro_id, tipo_paro_id, motivo, equipo, hora_inicio, hora_final, galones, falla_mecanica_id, falla_mecanica_nombre)
                SELECT COALESCE(TRY_CAST(JSON_VALUE(value, '$.id') AS UNIQUEIDENTIFIER), NEWID()), @p_registro_id,
                       TRY_CAST(JSON_VALUE(value, '$.tipo_paro_id') AS INT),
                       JSON_VALUE(value, '$.motivo'), JSON_VALUE(value, '$.equipo'),
                       TRY_CAST(JSON_VALUE(value, '$.hora_inicio') AS TIME), TRY_CAST(JSON_VALUE(value, '$.hora_final') AS TIME),
                       TRY_CAST(JSON_VALUE(value, '$.galones') AS DECIMAL(8,2)),
                       TRY_CAST(JSON_VALUE(value, '$.falla_mecanica_id') AS INT),
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
                       TRY_CAST(JSON_VALUE(value, '$.hora_final') AS TIME)    
                FROM OPENJSON(@v_paros);    
            END    
        END    
    
        -- Lotes, bines, sublabores, marchas (solo tractor)    
        IF @v_tipo_registro = 'tractor'    
        BEGIN    
            IF @v_lotes IS NOT NULL AND ISJSON(@v_lotes) = 1
            BEGIN
                -- MERGE en lugar de DELETE+INSERT para tolerar re-sincronizaciones
                -- desde el editor de administrador/supervisor, donde finca_id_erp
                -- puede llegar NULL porque la tabla local SQLite no lo almacena.
                -- COALESCE(source.finca_id_erp, target.finca_id_erp) preserva el
                -- valor ya guardado en el servidor cuando el APK no lo envía.
                -- También acepta 'lote_codigo_snapshot' O 'lote_codigo' (alias de
                -- compatibilidad) para cubrir ambas rutas de serialización del APK.
                ;WITH src AS (
                    SELECT
                        TRY_CAST(JSON_VALUE(value, '$.lote_id_erp')       AS INT)          AS lote_id_erp,
                        TRY_CAST(JSON_VALUE(value, '$.finca_id_erp')      AS INT)          AS finca_id_erp,
                        COALESCE(
                            JSON_VALUE(value, '$.lote_codigo_snapshot'),
                            JSON_VALUE(value, '$.lote_codigo')
                        )                                                                    AS lote_codigo_snapshot,
                        COALESCE(
                            JSON_VALUE(value, '$.sublote_snapshot'),
                            JSON_VALUE(value, '$.sublote')
                        )                                                                    AS sublote_snapshot,
                        TRY_CAST(JSON_VALUE(value, '$.area_trabajada_ha') AS DECIMAL(8,4)) AS area_trabajada_ha,
                        JSON_VALUE(value, '$.observacion')                                  AS observacion
                    FROM OPENJSON(@v_lotes)
                    WHERE TRY_CAST(JSON_VALUE(value, '$.lote_id_erp') AS INT) IS NOT NULL
                )
                MERGE INTO CLI547_AGM_MMA_REGISTROS_LOTES AS target
                USING src ON target.registro_id = @p_registro_id
                          AND target.lote_id_erp = src.lote_id_erp
                WHEN MATCHED THEN
                    UPDATE SET
                        -- finca_id_erp: preservar si el APK no lo envió (NULL)
                        finca_id_erp       = COALESCE(src.finca_id_erp, target.finca_id_erp),
                        lote_codigo_snapshot = COALESCE(src.lote_codigo_snapshot, target.lote_codigo_snapshot),
                        sublote_snapshot    = COALESCE(src.sublote_snapshot, target.sublote_snapshot),
                        area_trabajada_ha  = src.area_trabajada_ha,
                        observacion        = src.observacion
                WHEN NOT MATCHED BY TARGET AND src.finca_id_erp IS NOT NULL THEN
                    INSERT (id, registro_id, lote_id_erp, finca_id_erp, lote_codigo_snapshot, sublote_snapshot, area_trabajada_ha, observacion)
                    VALUES (NEWID(), @p_registro_id, src.lote_id_erp, src.finca_id_erp,
                            src.lote_codigo_snapshot, src.sublote_snapshot, src.area_trabajada_ha, src.observacion)
                WHEN NOT MATCHED BY SOURCE AND target.registro_id = @p_registro_id THEN
                    -- Eliminar lotes que ya no vienen en el JSON (se desmarcaron)
                    DELETE;
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
    
        -- ── Ruta GPS de maquinaria (opcional — retrocompatible) ─────────────────
        -- Aplica a ambos tipos (tractor y vehículo).
        -- Si el APK no envía GPS (versión anterior o permiso denegado),
        -- @v_ruta_gps llega NULL → bloque omitido, sync continúa sin error.
        --
        -- MERGE idempotente: compatible con GpsSyncService que envía puntos
        -- al SP dedicado CLI547_AGMSP_MMA_REGISTRAR_PUNTOS_GPS en paralelo.
        -- Solo inserta puntos nuevos (WHEN NOT MATCHED), nunca elimina ni duplica.
        --
        -- Claves JSON correctas del APK Flutter:
        --   id, latitud, longitud, precision, altitud, velocidad, secuencia, captured_at
        -- Columnas reales de CLI547_AGM_Punto_gps_maquinaria:
        --   id NVARCHAR(50), [precision] FLOAT, altitud FLOAT, velocidad INT,
        --   captured_at BIGINT (epoch ms), registro_id NVARCHAR(50)
        IF @v_ruta_gps IS NOT NULL AND ISJSON(@v_ruta_gps) = 1
        BEGIN
            ;WITH src AS (
                SELECT
                    LTRIM(RTRIM(JSON_VALUE(value, '$.id')))                     AS id,
                    TRY_CAST(JSON_VALUE(value, '$.latitud')    AS FLOAT)        AS latitud,
                    TRY_CAST(JSON_VALUE(value, '$.longitud')   AS FLOAT)        AS longitud,
                    TRY_CAST(JSON_VALUE(value, '$.precision')  AS FLOAT)        AS [precision],
                    TRY_CAST(JSON_VALUE(value, '$.altitud')    AS FLOAT)        AS altitud,
                    TRY_CAST(JSON_VALUE(value, '$.velocidad')  AS INT)          AS velocidad,
                    ISNULL(TRY_CAST(JSON_VALUE(value, '$.secuencia') AS INT),0) AS secuencia,
                    TRY_CAST(JSON_VALUE(value, '$.captured_at') AS BIGINT)      AS captured_at
                FROM OPENJSON(@v_ruta_gps)
                WHERE TRY_CAST(JSON_VALUE(value, '$.latitud')  AS FLOAT) IS NOT NULL
                  AND TRY_CAST(JSON_VALUE(value, '$.longitud') AS FLOAT) IS NOT NULL
                  AND ISNULL(LTRIM(RTRIM(JSON_VALUE(value, '$.id'))), '') <> ''
            )
            MERGE INTO dbo.CLI547_AGM_Punto_gps_maquinaria AS target
            USING src ON target.id = src.id
            WHEN NOT MATCHED BY TARGET THEN
                INSERT (id, registro_id, latitud, longitud, [precision], altitud, velocidad, secuencia, captured_at)
                VALUES (src.id, CAST(@p_registro_id AS NVARCHAR(50)),
                        src.latitud, src.longitud, src.[precision], src.altitud,
                        src.velocidad, src.secuencia, src.captured_at);
            -- WHEN MATCHED: no actualizar — el punto ya fue registrado correctamente
        END

        -- Combustible vehículo
        IF @v_tipo_registro = 'vehiculo' AND @v_combustibles IS NOT NULL AND ISJSON(@v_combustibles) = 1    
        BEGIN    
            DELETE FROM CLI547_AGM_MMA_COMBUSTIBLE_VEHICULO WHERE registro_id = @p_registro_id;    
            INSERT INTO CLI547_AGM_MMA_COMBUSTIBLE_VEHICULO (registro_id, glns, hora_inicio, hora_final)    
            SELECT @p_registro_id,    
                   TRY_CAST(JSON_VALUE(value, '$.glns') AS DECIMAL(10,2)),    
                   TRY_CAST(JSON_VALUE(value, '$.hora_inicio') AS TIME),    
                   TRY_CAST(JSON_VALUE(value, '$.hora_final') AS TIME)    
            FROM OPENJSON(@v_combustibles);    
        END    
    
        -- Cierre de turno    
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
            @p_success                       AS success,    
            @p_mensaje                       AS mensaje,    
            CAST(@p_registro_id AS NVARCHAR(36)) AS registro_id,    
            @p_ya_existia                    AS ya_existia;    
    END TRY    
    BEGIN CATCH    
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;    
        SET @p_success  = 0;    
        SET @p_mensaje  = 'Error [' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + ']: ' + ERROR_MESSAGE();    
        SET @p_registro_id = NULL;    
        SET @p_ya_existia  = 0;    
        SELECT    
            @p_success  AS success,    
            @p_mensaje  AS mensaje,    
            NULL        AS registro_id,    
            CAST(0 AS BIT) AS ya_existia;    
    END CATCH    
END;    
GO



    -- 6.2 Guardar Checklist (unificado)
    CREATE OR ALTER PROCEDURE dbo.CLI547_AGMSP_MMA_GUARDAR_CHECKLIST
        @p_registro_id     NVARCHAR(36) = NULL,
        @p_numero_registro VARCHAR(30)  = NULL,
        @p_resultados      NVARCHAR(MAX),
        @p_success         BIT              OUTPUT,
        @p_mensaje         NVARCHAR(MAX)    OUTPUT,
        @p_total           INT              OUTPUT
    AS
    BEGIN
        SET NOCOUNT ON;
        DECLARE @v_rid UNIQUEIDENTIFIER;
        IF @p_numero_registro IS NOT NULL SELECT @v_rid = id FROM dbo.CLI547_AGM_MMA_REGISTROS_DIARIOS WHERE numero_registro = @p_numero_registro;
        ELSE SET @v_rid = TRY_CONVERT(UNIQUEIDENTIFIER, @p_registro_id);
        IF @v_rid IS NULL BEGIN SET @p_success=0; SET @p_mensaje='Registro no encontrado'; SELECT @p_success AS success, @p_mensaje AS mensaje; RETURN; END
        DECLARE @v_resultado VARCHAR(4), @v_obs NVARCHAR(MAX), @v_item_id INT, @v_foto NVARCHAR(MAX);
        SET @p_total = 0;
        BEGIN TRY
            DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
                SELECT item_id, resultado, observacion, foto_url FROM OPENJSON(@p_resultados)
                WITH (item_id INT '$.item_id', resultado VARCHAR(4) '$.resultado', observacion NVARCHAR(MAX) '$.observacion', foto_url NVARCHAR(MAX) '$.foto_url');
            OPEN cur; FETCH NEXT FROM cur INTO @v_item_id, @v_resultado, @v_obs, @v_foto;
            WHILE @@FETCH_STATUS = 0
            BEGIN
                MERGE INTO dbo.CLI547_AGM_MMA_CHECKLIST_RESULTADOS AS target
                USING (SELECT @v_rid AS rid, @v_item_id AS iid) AS source
                ON target.registro_id = source.rid AND target.item_id = source.iid
                WHEN MATCHED THEN UPDATE SET resultado = @v_resultado, observacion = @v_obs, foto_url = @v_foto
                WHEN NOT MATCHED THEN INSERT (id, registro_id, item_id, resultado, observacion, foto_url) VALUES (NEWID(), @v_rid, @v_item_id, @v_resultado, @v_obs, @v_foto);
                SET @p_total = @p_total + 1;
                FETCH NEXT FROM cur INTO @v_item_id, @v_resultado, @v_obs, @v_foto;
            END
            CLOSE cur; DEALLOCATE cur;
            SET @p_success = 1; SET @p_mensaje = 'Checklist guardado: ' + CAST(@p_total AS VARCHAR) + ' ítems';
            SELECT @p_success AS success, @p_mensaje AS mensaje, @p_total AS total;
        END TRY
        BEGIN CATCH
            IF CURSOR_STATUS('local','cur') >= 0 BEGIN CLOSE cur; DEALLOCATE cur; END
            SET @p_success = 0; SET @p_mensaje = ERROR_MESSAGE();
            SELECT @p_success AS success, @p_mensaje AS mensaje;
        END CATCH
    END;
    GO

    -- 6.3 Guardar Checklist Vehículo (wrapper)
    CREATE OR ALTER PROCEDURE dbo.CLI547_AGMSP_MMA_GUARDAR_CHECKLIST_VEHICULO
        @p_registro_id     NVARCHAR(36) = NULL,
        @p_numero_registro VARCHAR(30)  = NULL,
        @p_resultados      NVARCHAR(MAX),
        @p_success         BIT              OUTPUT,
        @p_mensaje         NVARCHAR(MAX)    OUTPUT,
        @p_total           INT              OUTPUT
    AS
    BEGIN
        EXEC dbo.CLI547_AGMSP_MMA_GUARDAR_CHECKLIST @p_registro_id, @p_numero_registro, @p_resultados, @p_success OUTPUT, @p_mensaje OUTPUT, @p_total OUTPUT;
    END;
    GO

    -- 6.4 Registrar Paro (tractor)
    CREATE OR ALTER PROCEDURE dbo.CLI547_AGMSP_MMA_REGISTRAR_PARO
        @p_registro_id     NVARCHAR(36) = NULL,
        @p_numero_registro VARCHAR(30)  = NULL,
        @p_tipo_paro_id    INT,
        @p_motivo          NVARCHAR(MAX),
        @p_equipo          VARCHAR(150),
        @p_hora_inicio     TIME,
        @p_hora_final      TIME,
        @p_galones         DECIMAL(8,2),
        @p_paro_id         UNIQUEIDENTIFIER OUTPUT,
        @p_success         BIT              OUTPUT,
        @p_mensaje         NVARCHAR(MAX)    OUTPUT
    AS
    BEGIN
        SET NOCOUNT ON;
        DECLARE @v_rid UNIQUEIDENTIFIER;
        IF @p_numero_registro IS NOT NULL SELECT @v_rid = id FROM dbo.CLI547_AGM_MMA_REGISTROS_DIARIOS WHERE numero_registro = @p_numero_registro;
        ELSE SET @v_rid = TRY_CONVERT(UNIQUEIDENTIFIER, @p_registro_id);
        IF @v_rid IS NULL BEGIN SET @p_success=0; SET @p_mensaje='Registro no encontrado'; SELECT @p_success AS success, @p_mensaje AS mensaje; RETURN; END
        BEGIN TRY
            SET @p_paro_id = NEWID();
            INSERT INTO dbo.CLI547_AGM_MMA_PAROS_EQUIPOS (id, registro_id, tipo_paro_id, motivo, equipo, hora_inicio, hora_final, galones)
            VALUES (@p_paro_id, @v_rid, @p_tipo_paro_id, @p_motivo, @p_equipo, @p_hora_inicio, @p_hora_final, @p_galones);
            SET @p_success = 1; SET @p_mensaje = 'Paro registrado correctamente';
            SELECT @p_success AS success, @p_mensaje AS mensaje, @p_paro_id AS paro_id;
        END TRY
        BEGIN CATCH
            SET @p_success = 0; SET @p_mensaje = ERROR_MESSAGE();
            SELECT @p_success AS success, @p_mensaje AS mensaje;
        END CATCH
    END;
    GO

    -- 6.5 Cerrar Turno (tractor, con soporte para sublabores y marchas)
    CREATE OR ALTER PROCEDURE dbo.CLI547_AGMSP_MMA_CERRAR_TURNO
        @p_registro_id           NVARCHAR(36) = NULL,
        @p_numero_registro       VARCHAR(30)  = NULL,
        @p_tractor_final         DECIMAL(10,1),
        @p_implemento_final      DECIMAL(10,1),
        @p_hora_salida_punto     TIME,
        @p_hora_llegada_taller   TIME,
        @p_hora_refrigerio       VARCHAR(30) = NULL,
        @p_lotes                 NVARCHAR(MAX) = NULL,
        @p_sublabores            NVARCHAR(MAX) = NULL,
        @p_marchas               NVARCHAR(MAX) = NULL,
        @p_observaciones_maq     NVARCHAR(MAX) = NULL,
        @p_success               BIT             OUTPUT,
        @p_mensaje               NVARCHAR(MAX)   OUTPUT
    AS
    BEGIN
        SET NOCOUNT ON;
        DECLARE @v_rid UNIQUEIDENTIFIER;
        IF @p_numero_registro IS NOT NULL SELECT @v_rid = id FROM dbo.CLI547_AGM_MMA_REGISTROS_DIARIOS WHERE numero_registro = @p_numero_registro;
        ELSE SET @v_rid = TRY_CONVERT(UNIQUEIDENTIFIER, @p_registro_id);
        IF @v_rid IS NULL BEGIN SET @p_success=0; SET @p_mensaje='Registro no encontrado'; SELECT @p_success AS success, @p_mensaje AS mensaje; RETURN; END
        BEGIN TRY
            UPDATE dbo.CLI547_AGM_MMA_HOROMETROS SET tractor_final = @p_tractor_final, implemento_final = @p_implemento_final, updated_at = GETDATE() WHERE registro_id = @v_rid;
            UPDATE dbo.CLI547_AGM_MMA_TIEMPOS_TURNO SET hora_salida_punto = @p_hora_salida_punto, hora_llegada_taller = @p_hora_llegada_taller, hora_refrigerio = @p_hora_refrigerio, updated_at = GETDATE() WHERE registro_id = @v_rid;
            IF @p_lotes IS NOT NULL AND ISJSON(@p_lotes)=1
            BEGIN
                -- DELETE antes de INSERT: idempotente en reintentos (evita UNIQUE constraint violation)
                DELETE FROM dbo.CLI547_AGM_MMA_REGISTROS_LOTES WHERE registro_id = @v_rid;
                INSERT INTO dbo.CLI547_AGM_MMA_REGISTROS_LOTES (id, registro_id, lote_id_erp, finca_id_erp, lote_codigo_snapshot, sublote_snapshot, area_trabajada_ha, observacion)
                SELECT NEWID(), @v_rid, lote_id_erp, finca_id_erp, lote_codigo_snapshot, sublote_snapshot, area_ha, observacion
                FROM OPENJSON(@p_lotes) WITH (lote_id_erp INT '$.lote_id_erp', finca_id_erp INT '$.finca_id_erp', lote_codigo_snapshot VARCHAR(50) '$.lote_codigo_snapshot', sublote_snapshot VARCHAR(200) '$.sublote_snapshot', area_ha DECIMAL(8,4) '$.area_ha', observacion NVARCHAR(MAX) '$.observacion');
            END
            IF @p_sublabores IS NOT NULL AND ISJSON(@p_sublabores)=1
            BEGIN
                DELETE FROM dbo.CLI547_AGM_MMA_REGISTROS_SUBLABORES WHERE registro_id = @v_rid;
                INSERT INTO dbo.CLI547_AGM_MMA_REGISTROS_SUBLABORES (registro_id, sublabor_nombre)
                SELECT @v_rid, JSON_VALUE(value, '$.sublabor_nombre') FROM OPENJSON(@p_sublabores) WHERE JSON_VALUE(value, '$.sublabor_nombre') IS NOT NULL;
            END
            IF @p_marchas IS NOT NULL AND ISJSON(@p_marchas)=1
            BEGIN
                DELETE FROM dbo.CLI547_AGM_MMA_REGISTROS_MARCHAS WHERE registro_id = @v_rid;
                INSERT INTO dbo.CLI547_AGM_MMA_REGISTROS_MARCHAS (registro_id, marcha_codigo, horas_uso)
                SELECT @v_rid, JSON_VALUE(value, '$.marcha_codigo'), TRY_CAST(JSON_VALUE(value, '$.horas_uso') AS DECIMAL(6,2))
                FROM OPENJSON(@p_marchas) WHERE JSON_VALUE(value, '$.marcha_codigo') IS NOT NULL;
            END
            UPDATE dbo.CLI547_AGM_MMA_REGISTROS_DIARIOS SET estado = 'completado', observaciones_maq = @p_observaciones_maq, updated_at = GETDATE() WHERE id = @v_rid;
            SET @p_success = 1; SET @p_mensaje = 'Turno cerrado correctamente.';
            SELECT @p_success AS success, @p_mensaje AS mensaje;
        END TRY
        BEGIN CATCH
            SET @p_success = 0; SET @p_mensaje = ERROR_MESSAGE();
            SELECT @p_success AS success, @p_mensaje AS mensaje;
        END CATCH
    END;
    GO

    -- 6.6 Cerrar Turno Vehículo (sin lotes, sin sublabores/marchas)
    CREATE OR ALTER PROCEDURE dbo.CLI547_AGMSP_MMA_CERRAR_TURNO_VEHICULO
        @p_registro_id           NVARCHAR(36) = NULL,
        @p_numero_registro       VARCHAR(30)  = NULL,
        @p_km_camion_final       DECIMAL(10,2),
        @p_km_implemento_final   DECIMAL(10,2) = NULL,
        @p_hora_salida_punto     TIME,
        @p_hora_llegada_taller   TIME,
        @p_hora_refrigerio       VARCHAR(30) = NULL,
        @p_observaciones_maq     NVARCHAR(MAX) = NULL,
        @p_success               BIT             OUTPUT,
        @p_mensaje               NVARCHAR(MAX)   OUTPUT
    AS
    BEGIN
        SET NOCOUNT ON;
        DECLARE @v_rid UNIQUEIDENTIFIER;
        IF @p_numero_registro IS NOT NULL SELECT @v_rid = id FROM dbo.CLI547_AGM_MMA_REGISTROS_DIARIOS WHERE numero_registro = @p_numero_registro;
        ELSE SET @v_rid = TRY_CONVERT(UNIQUEIDENTIFIER, @p_registro_id);
        IF @v_rid IS NULL BEGIN SET @p_success=0; SET @p_mensaje='Registro no encontrado'; SELECT @p_success AS success, @p_mensaje AS mensaje; RETURN; END
        BEGIN TRY
            UPDATE dbo.CLI547_AGM_MMA_HOROMETROS SET tractor_final = @p_km_camion_final, implemento_final = @p_km_implemento_final, updated_at = GETDATE() WHERE registro_id = @v_rid;
            UPDATE dbo.CLI547_AGM_MMA_TIEMPOS_TURNO SET hora_salida_punto = @p_hora_salida_punto, hora_llegada_taller = @p_hora_llegada_taller, hora_refrigerio = @p_hora_refrigerio, updated_at = GETDATE() WHERE registro_id = @v_rid;
            UPDATE dbo.CLI547_AGM_MMA_REGISTROS_DIARIOS SET estado = 'completado', observaciones_maq = @p_observaciones_maq, updated_at = GETDATE() WHERE id = @v_rid;
            SET @p_success = 1; SET @p_mensaje = 'Turno de vehículo cerrado correctamente.';
            SELECT @p_success AS success, @p_mensaje AS mensaje;
        END TRY
        BEGIN CATCH
            SET @p_success = 0; SET @p_mensaje = ERROR_MESSAGE();
            SELECT @p_success AS success, @p_mensaje AS mensaje;
        END CATCH
    END;
    GO

    -- 6.7 Registrar Bin (tractor)
    CREATE OR ALTER PROCEDURE dbo.CLI547_AGMSP_MMA_REGISTRAR_BIN
        @p_registro_id     NVARCHAR(36) = NULL,
        @p_numero_registro VARCHAR(30)  = NULL,
        @p_franja_horaria  VARCHAR(10),
        @p_turno_franja    VARCHAR(5),
        @p_cantidad        SMALLINT,
        @p_success         BIT            OUTPUT,
        @p_mensaje         NVARCHAR(MAX)  OUTPUT
    AS
    BEGIN
        SET NOCOUNT ON;
        DECLARE @v_rid UNIQUEIDENTIFIER;
        IF @p_numero_registro IS NOT NULL SELECT @v_rid = id FROM dbo.CLI547_AGM_MMA_REGISTROS_DIARIOS WHERE numero_registro = @p_numero_registro;
        ELSE SET @v_rid = TRY_CONVERT(UNIQUEIDENTIFIER, @p_registro_id);
        IF @v_rid IS NULL BEGIN SET @p_success=0; SET @p_mensaje='Registro no encontrado'; SELECT @p_success AS success, @p_mensaje AS mensaje; RETURN; END
        BEGIN TRY
            MERGE INTO dbo.CLI547_AGM_MMA_COSECHA_BINES AS target
            USING (SELECT @v_rid AS rid, @p_franja_horaria AS fh) AS source
            ON target.registro_id = source.rid AND target.franja_horaria = source.fh
            WHEN MATCHED THEN UPDATE SET cantidad = @p_cantidad
            WHEN NOT MATCHED THEN INSERT (registro_id, franja_horaria, turno_franja, cantidad) VALUES (@v_rid, @p_franja_horaria, @p_turno_franja, @p_cantidad);
            SET @p_success=1; SET @p_mensaje='Bin registrado correctamente';
            SELECT @p_success AS success, @p_mensaje AS mensaje;
        END TRY
        BEGIN CATCH
            SET @p_success=0; SET @p_mensaje=ERROR_MESSAGE();
            SELECT @p_success AS success, @p_mensaje AS mensaje;
        END CATCH
    END;
    GO

    -- 6.8 Registrar Incumplimiento (para admin)
    CREATE OR ALTER PROCEDURE dbo.CLI547_AGMSP_MMA_REGISTRAR_INCUMPLIMIENTO
        @p_usuario_erp_id    INT,
        @p_nombre_usuario    NVARCHAR(300),
        @p_fecha_jornada     DATE,
        @p_turno             VARCHAR(10),
        @p_tipo              VARCHAR(80),
        @p_detalle           NVARCHAR(MAX)  = NULL,
        @p_dispositivo_id    VARCHAR(150)   = NULL,
        @p_firestore_doc_id  VARCHAR(200)   = NULL,
        @p_id_generado       INT            OUTPUT
    AS
    BEGIN
        SET NOCOUNT ON;
        INSERT INTO dbo.CLI547_AGM_MMA_INCUMPLIMIENTOS (usuario_erp_id, nombre_usuario, fecha_jornada, turno, tipo_incumplimiento, detalle, dispositivo_id, firestore_doc_id)
        VALUES (@p_usuario_erp_id, @p_nombre_usuario, @p_fecha_jornada, @p_turno, @p_tipo, @p_detalle, @p_dispositivo_id, @p_firestore_doc_id);
        SET @p_id_generado = SCOPE_IDENTITY();
        SELECT @p_id_generado AS id_generado, 1 AS success, 'Incumplimiento registrado' AS mensaje;
    END;
    GO

    -- 6.9 Dashboard Administrador
    CREATE OR ALTER PROCEDURE dbo.CLI547_AGMSP_MMA_ADMIN_DASHBOARD
        @p_fecha_desde DATE = NULL,
        @p_fecha_hasta DATE = NULL
    AS
    BEGIN
        SET NOCOUNT ON;
        IF @p_fecha_desde IS NULL SET @p_fecha_desde = DATEADD(DAY, -30, CAST(GETDATE() AS DATE));
        IF @p_fecha_hasta IS NULL SET @p_fecha_hasta = CAST(GETDATE() AS DATE);
        SELECT 'registros_por_dia' AS seccion,
            (SELECT CAST(rd.fecha AS DATE) AS fecha, COUNT(*) AS total, SUM(CASE WHEN rd.estado='completado' THEN 1 ELSE 0 END) AS completados,
                    SUM(CASE WHEN rd.estado='aprobado' THEN 1 ELSE 0 END) AS aprobados, SUM(CASE WHEN rd.estado='rechazado' THEN 1 ELSE 0 END) AS rechazados
            FROM dbo.CLI547_AGM_MMA_REGISTROS_DIARIOS rd WHERE rd.fecha BETWEEN @p_fecha_desde AND @p_fecha_hasta GROUP BY CAST(rd.fecha AS DATE) ORDER BY CAST(rd.fecha AS DATE) FOR JSON PATH) AS datos;
        SELECT 'incumplimientos_recientes' AS seccion,
            (SELECT TOP 50 i.id, i.nombre_usuario, i.fecha_jornada, i.turno, i.tipo_incumplimiento, i.detalle, i.created_at
            FROM dbo.CLI547_AGM_MMA_INCUMPLIMIENTOS i WHERE i.fecha_jornada BETWEEN @p_fecha_desde AND @p_fecha_hasta ORDER BY i.created_at DESC FOR JSON PATH) AS datos;
        SELECT 'productividad_operadores' AS seccion,
            (SELECT rd.nombre_operador_snapshot AS operador, COUNT(*) AS total_registros,
                    AVG(ISNULL((SELECT SUM(cb.cantidad) FROM dbo.CLI547_AGM_MMA_COSECHA_BINES cb WHERE cb.registro_id = rd.id),0)) AS bines_promedio,
                    SUM(CASE WHEN rd.estado IN ('completado','aprobado') THEN 1 ELSE 0 END) AS completados
            FROM dbo.CLI547_AGM_MMA_REGISTROS_DIARIOS rd WHERE rd.fecha BETWEEN @p_fecha_desde AND @p_fecha_hasta AND rd.tipo_registro='tractor'
            GROUP BY rd.nombre_operador_snapshot ORDER BY total_registros DESC FOR JSON PATH) AS datos;
    END;
    GO

    -- 7. TRIGGER DE AUDITORÍA
    IF EXISTS (SELECT 1 FROM sys.triggers WHERE name = 'trg_mma_audit_registros_diarios')
        DROP TRIGGER dbo.trg_mma_audit_registros_diarios;
    GO
    CREATE TRIGGER dbo.trg_mma_audit_registros_diarios ON dbo.CLI547_AGM_MMA_REGISTROS_DIARIOS AFTER INSERT, UPDATE, DELETE
    AS
    BEGIN
        SET NOCOUNT ON;
        IF EXISTS (SELECT 1 FROM inserted) AND NOT EXISTS (SELECT 1 FROM deleted)
            INSERT INTO dbo.CLI547_AGM_MMA_AUDIT_LOG (tabla, registro_pk, accion, datos_new)
            SELECT 'CLI547_AGM_MMA_REGISTROS_DIARIOS', CAST(i.id AS VARCHAR(100)), 'INSERT', (SELECT * FROM inserted x WHERE x.id=i.id FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) FROM inserted i;
        ELSE IF EXISTS (SELECT 1 FROM inserted) AND EXISTS (SELECT 1 FROM deleted)
            INSERT INTO dbo.CLI547_AGM_MMA_AUDIT_LOG (tabla, registro_pk, accion, datos_old, datos_new)
            SELECT 'CLI547_AGM_MMA_REGISTROS_DIARIOS', CAST(d.id AS VARCHAR(100)), 'UPDATE',
                (SELECT * FROM deleted x WHERE x.id=d.id FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
                (SELECT * FROM inserted x WHERE x.id=d.id FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) FROM deleted d;
        ELSE IF NOT EXISTS (SELECT 1 FROM inserted) AND EXISTS (SELECT 1 FROM deleted)
            INSERT INTO dbo.CLI547_AGM_MMA_AUDIT_LOG (tabla, registro_pk, accion, datos_old)
            SELECT 'CLI547_AGM_MMA_REGISTROS_DIARIOS', CAST(d.id AS VARCHAR(100)), 'DELETE', (SELECT * FROM deleted x WHERE x.id=d.id FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) FROM deleted d;
    END;
    GO

    -- 8. VISTAS
    CREATE OR ALTER VIEW dbo.v_mma_registros_resumen AS
    SELECT rd.id, rd.numero_registro, rd.fecha, rd.turno, rd.estado, p.nombre AS proceso, rd.nombre_cultivo_snapshot AS cultivo,
        rd.nombre_operador_snapshot AS operador, rd.codigo_tractor_snapshot AS tractor, h.horas_tractor, tt.minutos_efectivos,
        ISNULL((SELECT SUM(cantidad) FROM dbo.CLI547_AGM_MMA_COSECHA_BINES WHERE registro_id=rd.id),0) AS total_bines,
        (SELECT COUNT(*) FROM dbo.CLI547_AGM_MMA_CHECKLIST_RESULTADOS WHERE registro_id=rd.id) AS total_checklist,
        (SELECT COUNT(*) FROM dbo.CLI547_AGM_MMA_PAROS_EQUIPOS WHERE registro_id=rd.id) AS total_paros,
        (SELECT COUNT(*) FROM dbo.CLI547_AGM_MMA_REGISTROS_LOTES WHERE registro_id=rd.id) AS total_lotes
    FROM dbo.CLI547_AGM_MMA_REGISTROS_DIARIOS rd
    INNER JOIN dbo.CLI547_AGM_MMA_PROCESOS p ON p.id = rd.proceso_id
    LEFT JOIN dbo.CLI547_AGM_MMA_HOROMETROS h ON h.registro_id = rd.id
    LEFT JOIN dbo.CLI547_AGM_MMA_TIEMPOS_TURNO tt ON tt.registro_id = rd.id
    WHERE rd.tipo_registro = 'tractor';
    GO

    CREATE OR ALTER VIEW dbo.v_mma_registros_vehiculo_resumen AS
    SELECT rd.id, rd.numero_registro, rd.fecha, rd.turno, rd.estado, rd.proceso_vehiculo AS proceso,
        rd.nombre_operador_snapshot AS operador, rd.nombre_supervisor_snapshot AS supervisor,
        rd.codigo_tractor_snapshot AS camion, rd.codigo_implemento_snapshot AS implemento,
        h.tractor_inicio AS km_camion_inicio, h.tractor_final AS km_camion_final, h.horas_tractor AS km_recorridos,
        h.implemento_inicio AS km_implemento_inicio, h.implemento_final AS km_implemento_final,
        tt.hora_salida_taller, tt.hora_llegada_punto, tt.hora_salida_punto, tt.hora_llegada_taller, tt.hora_refrigerio,
        rd.cantidad_tancadas,
        (SELECT COUNT(*) FROM dbo.CLI547_AGM_MMA_CHECKLIST_RESULTADOS WHERE registro_id=rd.id) AS total_checklist,
        (SELECT COUNT(*) FROM dbo.CLI547_AGM_MMA_COMBUSTIBLE_VEHICULO WHERE registro_id=rd.id) AS total_combustibles,
        (SELECT COUNT(*) FROM dbo.CLI547_AGM_MMA_PAROS_VEHICULO WHERE registro_id=rd.id) AS total_paros
    FROM dbo.CLI547_AGM_MMA_REGISTROS_DIARIOS rd
    LEFT JOIN dbo.CLI547_AGM_MMA_HOROMETROS h ON h.registro_id = rd.id
    LEFT JOIN dbo.CLI547_AGM_MMA_TIEMPOS_TURNO tt ON tt.registro_id = rd.id
    WHERE rd.tipo_registro = 'vehiculo';
    GO

    CREATE OR ALTER VIEW dbo.v_mma_incumplimientos_resumen AS
    SELECT i.id, i.usuario_erp_id, i.nombre_usuario, i.fecha_jornada, i.turno, i.tipo_incumplimiento, i.detalle, i.created_at,
        COUNT(rd.id) AS registros_dia,
        SUM(CASE WHEN rd.estado = 'completado' THEN 1 ELSE 0 END) AS completados,
        SUM(CASE WHEN rd.estado = 'borrador'   THEN 1 ELSE 0 END) AS borradores
    FROM dbo.CLI547_AGM_MMA_INCUMPLIMIENTOS i
    LEFT JOIN dbo.CLI547_AGM_MMA_REGISTROS_DIARIOS rd ON rd.operador_id_erp = i.usuario_erp_id AND rd.fecha = i.fecha_jornada AND rd.turno = i.turno
    GROUP BY i.id, i.usuario_erp_id, i.nombre_usuario, i.fecha_jornada, i.turno, i.tipo_incumplimiento, i.detalle, i.created_at;
    GO

    -- 9. CATÁLOGOS INICIALES
    -- =============================================================================

    -- 9.1 Tipos de paro (tractor)
    -- COMBUSTIBLE → requiere_galones; MECANICO → requiere_equipo
    INSERT INTO dbo.CLI547_AGM_MMA_TIPOS_PARO (codigo, nombre, requiere_galones, requiere_equipo, activo)
    SELECT v.codigo, v.nombre, v.rg, v.re, 1
    FROM (VALUES
        ('COMBUSTIBLE',    'Combustible / Abastecimiento',   1, 0),
        ('MECANICO',       'Falla mecánica',                 0, 1),
        ('HIDRAULICO',     'Falla hidráulica',               0, 1),
        ('ELECTRICO',      'Falla eléctrica',                0, 1),
        ('OPERATIVO',      'Paro operativo / Espera',        0, 0),
        ('CLIMATICO',      'Paro climático',                 0, 0),
        ('MANTENIMIENTO',  'Mantenimiento preventivo',       0, 1),
        ('OTROS',          'Otros',                          0, 0)
    ) v(codigo, nombre, rg, re)
    WHERE NOT EXISTS (
        SELECT 1 FROM dbo.CLI547_AGM_MMA_TIPOS_PARO WHERE codigo = v.codigo
    );
    GO

    -- 9.2 Procesos de TRACTOR
    IF NOT EXISTS (SELECT 1 FROM dbo.CLI547_AGM_MMA_PROCESOS WHERE codigo = 'APLIC')
        INSERT INTO dbo.CLI547_AGM_MMA_PROCESOS (codigo, nombre, requiere_bines, requiere_sublabores, tipo_registro, activo) VALUES
            ('APLIC',   'Aplicación',     0, 1, 'tractor', 1),
            ('COSEC',   'Cosecha',        1, 0, 'tractor', 1),
            ('PODA',    'Poda',           0, 0, 'tractor', 1),
            ('TRITU',   'Triturado',      0, 0, 'tractor', 1),
            ('RUFA',    'Rufa',           0, 0, 'tractor', 1),
            ('CARRE',   'Carreteo',       0, 0, 'tractor', 1),
            ('MELAZ',   'Melaza',         0, 0, 'tractor', 1),
            ('OTRO_T',  'Otro',           0, 0, 'tractor', 1);
    GO

    -- 9.3 Procesos de VEHÍCULO
    IF NOT EXISTS (SELECT 1 FROM dbo.CLI547_AGM_MMA_PROCESOS WHERE codigo = 'REGADO_CAMINOS')
        INSERT INTO dbo.CLI547_AGM_MMA_PROCESOS (codigo, nombre, requiere_bines, requiere_sublabores, tipo_registro, activo) VALUES
            ('REGADO_CAMINOS',     'Regado de caminos',       0, 0, 'vehiculo', 1),
            ('TRASLADO_MANGUERAS', 'Traslado de mangueras',   0, 0, 'vehiculo', 1),
            ('TRASLADO_MATERIALES','Traslado de materiales',  0, 0, 'vehiculo', 1),
            ('ABASTECIMIENTO',     'Abastecimiento',          0, 0, 'vehiculo', 1),
            ('CULTIVO',            'Cultivo',                 1, 0, 'vehiculo', 1),
            ('APLICACION',         'Aplicacion',              0, 0, 'vehiculo', 1),
            ('OTRO',               'Otro',                    0, 0, 'vehiculo', 1);
    GO

    -- Items checklist vehículo (24)
    IF NOT EXISTS (SELECT 1 FROM dbo.CLI547_AGM_MMA_CHECKLIST_ITEMS_CATALOGO WHERE tipo_registro = 'vehiculo')
    BEGIN
        DECLARE @cat_v INT;
        IF NOT EXISTS (SELECT 1 FROM dbo.CLI547_AGM_MMA_CHECKLIST_CATEGORIAS WHERE nombre = 'Vehículo')
            INSERT INTO dbo.CLI547_AGM_MMA_CHECKLIST_CATEGORIAS (nombre, orden) VALUES ('Vehículo', 100);
        SELECT @cat_v = id FROM dbo.CLI547_AGM_MMA_CHECKLIST_CATEGORIAS WHERE nombre = 'Vehículo';
        INSERT INTO dbo.CLI547_AGM_MMA_CHECKLIST_ITEMS_CATALOGO (categoria_id, nombre, orden, activo, tipo_registro) VALUES
            (@cat_v, 'Nivel de aceite de motor', 1, 1, 'vehiculo'),
            (@cat_v, 'Nivel de refrigerante de motor', 2, 1, 'vehiculo'),
            (@cat_v, 'Nivel de hidrolina de dirección', 3, 1, 'vehiculo'),
            (@cat_v, 'Nivel de líquido de frenos', 4, 1, 'vehiculo'),
            (@cat_v, 'Nivel de combustible', 5, 1, 'vehiculo'),
            (@cat_v, 'Nivel de aceite de los reductores posteriores', 6, 1, 'vehiculo'),
            (@cat_v, 'Estado de Batería y sus bornes', 7, 1, 'vehiculo'),
            (@cat_v, 'Estado de faja de alternador y templado', 8, 1, 'vehiculo'),
            (@cat_v, 'Estado del radiador, mangueras y su tapa', 9, 1, 'vehiculo'),
            (@cat_v, 'Estado de Llantas y ajuste de tuercas de rueda', 10, 1, 'vehiculo'),
            (@cat_v, 'Estado de cardán y soportes', 11, 1, 'vehiculo'),
            (@cat_v, 'Estado de freno de estacionamiento', 12, 1, 'vehiculo'),
            (@cat_v, 'Extintor instalado y operativo', 13, 1, 'vehiculo'),
            (@cat_v, 'Estado de Asiento y Cinturón de seguridad', 14, 1, 'vehiculo'),
            (@cat_v, 'Estado de cabina de operador', 15, 1, 'vehiculo'),
            (@cat_v, 'Estado de Puertas', 16, 1, 'vehiculo'),
            (@cat_v, 'Espejos', 17, 1, 'vehiculo'),
            (@cat_v, 'Luces', 18, 1, 'vehiculo'),
            (@cat_v, 'Tacos de seguridad', 19, 1, 'vehiculo'),
            (@cat_v, 'Alarma de retroceso', 20, 1, 'vehiculo'),
            (@cat_v, 'Claxon', 21, 1, 'vehiculo'),
            (@cat_v, 'Documentos del vehículo', 22, 1, 'vehiculo'),
            (@cat_v, 'Parabrisas y Limpia parabrisas', 23, 1, 'vehiculo'),
            (@cat_v, 'Horómetro y tacómetro', 24, 1, 'vehiculo');
    END
    GO

    -- Items checklist tractor (32): 2 categorías × 16 items
    IF NOT EXISTS (SELECT 1 FROM dbo.CLI547_AGM_MMA_CHECKLIST_ITEMS_CATALOGO WHERE tipo_registro = 'tractor')
    BEGIN
        DECLARE @cat_t1 INT, @cat_t2 INT;

        IF NOT EXISTS (SELECT 1 FROM dbo.CLI547_AGM_MMA_CHECKLIST_CATEGORIAS WHERE nombre = 'Inspeccionar Tractor')
            INSERT INTO dbo.CLI547_AGM_MMA_CHECKLIST_CATEGORIAS (nombre, orden) VALUES ('Inspeccionar Tractor', 10);
        SELECT @cat_t1 = id FROM dbo.CLI547_AGM_MMA_CHECKLIST_CATEGORIAS WHERE nombre = 'Inspeccionar Tractor';

        IF NOT EXISTS (SELECT 1 FROM dbo.CLI547_AGM_MMA_CHECKLIST_CATEGORIAS WHERE nombre = 'Inspeccionar Implemento')
            INSERT INTO dbo.CLI547_AGM_MMA_CHECKLIST_CATEGORIAS (nombre, orden) VALUES ('Inspeccionar Implemento', 20);
        SELECT @cat_t2 = id FROM dbo.CLI547_AGM_MMA_CHECKLIST_CATEGORIAS WHERE nombre = 'Inspeccionar Implemento';

        INSERT INTO dbo.CLI547_AGM_MMA_CHECKLIST_ITEMS_CATALOGO (categoria_id, nombre, orden, activo, tipo_registro) VALUES
            -- Categoría: Inspeccionar Tractor (16 items)
            (@cat_t1, 'Nivel de aceite del motor',                           1,  1, 'tractor'),
            (@cat_t1, 'Nivel de aceite hidráulico del tractor',              2,  1, 'tractor'),
            (@cat_t1, 'Nivel de refrigerante del motor',                     3,  1, 'tractor'),
            (@cat_t1, 'Nivel de aceite de la caja multiplicadora',           4,  1, 'tractor'),
            (@cat_t1, 'Nivel de aceite hidráulico del Implemento',           5,  1, 'tractor'),
            (@cat_t1, 'Llantas y ajuste de tuercas de rueda',                6,  1, 'tractor'),
            (@cat_t1, 'Batería y sus bornes',                                7,  1, 'tractor'),
            (@cat_t1, 'Barra de tiro, pines y seguro',                       8,  1, 'tractor'),
            (@cat_t1, 'Faja de alternador',                                  9,  1, 'tractor'),
            (@cat_t1, 'Tanque de productos',                                10,  1, 'tractor'),
            (@cat_t1, 'Espejos del tractor',                                11,  1, 'tractor'),
            (@cat_t1, 'Cardan y su Protector',                              12,  1, 'tractor'),
            (@cat_t1, 'Claxon',                                             13,  1, 'tractor'),
            (@cat_t1, 'Mangueras hidráulicas',                              14,  1, 'tractor'),
            (@cat_t1, 'Extintor',                                           15,  1, 'tractor'),
            (@cat_t1, 'Mangueras agroquímicas',                             16,  1, 'tractor'),
            -- Categoría: Inspeccionar Implemento (16 items)
            (@cat_t2, 'Nivel de aceite en los reductores delant. y post.',  17,  1, 'tractor'),
            (@cat_t2, 'Fajas de transmisión',                               18,  1, 'tractor'),
            (@cat_t2, 'Nivel de aceite del tren delantero',                 19,  1, 'tractor'),
            (@cat_t2, 'Bombines hidráulicos',                               20,  1, 'tractor'),
            (@cat_t2, 'Templadores de brazos de levante y pines/seguros',   21,  1, 'tractor'),
            (@cat_t2, 'Comando hidráulico',                                 22,  1, 'tractor'),
            (@cat_t2, 'Llantas y ajuste de tuercas de rueda (impl.)',       23,  1, 'tractor'),
            (@cat_t2, 'Comando eléctrico',                                  24,  1, 'tractor'),
            (@cat_t2, 'Cinturón de seguridad y Protección antivuelco',      25,  1, 'tractor'),
            (@cat_t2, 'Luces del Implemento',                               26,  1, 'tractor'),
            (@cat_t2, 'Luces del tractor',                                  27,  1, 'tractor'),
            (@cat_t2, 'Horómetro',                                          28,  1, 'tractor'),
            (@cat_t2, 'Alarma de retroceso',                                29,  1, 'tractor'),
            (@cat_t2, 'Techo y soportes',                                   30,  1, 'tractor'),
            (@cat_t2, 'Tacos de seguridad',                                 31,  1, 'tractor'),
            (@cat_t2, 'Soporte frontal y templadores',                      32,  1, 'tractor');
    END
    GO

    -- 10. SP de catálogos extendido (con requiere_sublabores y subprocesos)
    -- 10. SP de catálogos extendido (con requiere_sublabores y subprocesos)
     -- 10. SP de catálogos extendido (con requiere_sublabores y subprocesos)
          CREATE OR ALTER PROCEDURE [dbo].[CLI547_AGMSP_MMA_ERP_SYNC_PAYLOAD_COMPLETO]
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @zona_maq NVARCHAR(50) = 'PISCO';
    DECLARE @zona_per NVARCHAR(20) = 'PCO';
    
    -- Variables para el filtro de lotes_kmz (valores fijos para la zona PISCO)
    DECLARE @Id_Sede INT;
    DECLARE @Id_Cultivo INT = NULL;   -- NULL = todos los cultivos
    DECLARE @SinceVersion BIGINT = NULL;  -- NULL = todos los lotes

    -- Obtener el Id de la sede por defecto (PISCO)
    SELECT TOP 1 @Id_Sede = z.Id
    FROM ERPHispatec.dbo.Zonas z
    WHERE z.Nombre = @zona_maq;

    -- Si no se encuentra la sede, usar un valor por defecto
    IF @Id_Sede IS NULL SET @Id_Sede = 1;

    -- =========================================================================
    -- CATÁLOGO 1: CULTIVOS
    -- =========================================================================
    SELECT 'cultivos' AS catalogo, (
        SELECT
            eb.Id            AS cultivo_id_erp,
            eb.NombreComun   AS nombre_cultivo,
            eb.NombreEspecie AS nombre_especie,
            eb.NombreGenero  AS nombre_genero,
            eb.Grupo         AS grupo,
            eb.SubGrupo      AS sub_grupo
        FROM ERPHispatec.dbo.EspeciesBotanicas eb
        ORDER BY eb.NombreComun
        FOR JSON PATH
    ) AS datos;

    -- =========================================================================
    -- CATÁLOGO 2: TRACTORES (prefijo TR%)
    -- =========================================================================
    SELECT 'tractores' AS catalogo, (
        SELECT
            m.Id            AS tractor_id_erp,
            m.Identificacion AS codigo_tractor,
            m.Descripcion   AS descripcion,
            m.Marca         AS marca,
            m.Modelo        AS modelo,
            m.Matricula     AS matricula,
            m.Codigo        AS codigo_interno
        FROM ERPHispatec.dbo.Maquinaria m
        INNER JOIN ERPHispatec.dbo.Maquinaria_DatosComplementarios md ON m.Id = md.Id_Maquinaria
        INNER JOIN ERPHispatec.dbo.DatoComplementarioValor dc ON md.Id_DatosComplementarios = dc.Id
        INNER JOIN ERPHispatec.dbo.Zonas z ON dc.valor = z.Nombre
        WHERE z.Nombre = @zona_maq
          AND m.Identificacion LIKE 'TR%'
        ORDER BY m.Identificacion
        FOR JSON PATH
    ) AS datos;

    -- =========================================================================
    -- CATÁLOGO 3: IMPLEMENTOS (prefijo I%)
    -- =========================================================================
    SELECT 'implementos' AS catalogo, (
        SELECT
            m.Id            AS implemento_id_erp,
            m.Identificacion AS codigo_implemento,
            m.Descripcion   AS descripcion,
            m.Marca         AS marca,
            m.Modelo        AS modelo,
            m.Matricula     AS matricula,
            m.Codigo        AS codigo_interno
        FROM ERPHispatec.dbo.Maquinaria m
        INNER JOIN ERPHispatec.dbo.Maquinaria_DatosComplementarios md ON m.Id = md.Id_Maquinaria
        INNER JOIN ERPHispatec.dbo.DatoComplementarioValor dc ON md.Id_DatosComplementarios = dc.Id
        INNER JOIN ERPHispatec.dbo.Zonas z ON dc.valor = z.Nombre
        WHERE z.Nombre = @zona_maq
          AND m.Identificacion LIKE 'I%'
        ORDER BY m.Identificacion
        FOR JSON PATH
    ) AS datos;

    -- =========================================================================
    -- CATÁLOGO 4: VEHÍCULOS (prefijo V%)
    -- =========================================================================
    SELECT 'vehiculos' AS catalogo, (
        SELECT
            m.Id            AS implemento_id_erp,
            m.Identificacion AS codigo_implemento,
            m.Descripcion   AS descripcion,
            m.Marca         AS marca,
            m.Modelo        AS modelo,
            m.Matricula     AS matricula,
            m.Codigo        AS codigo_interno
        FROM ERPHispatec.dbo.Maquinaria m
        INNER JOIN ERPHispatec.dbo.Maquinaria_DatosComplementarios md ON m.Id = md.Id_Maquinaria
        INNER JOIN ERPHispatec.dbo.DatoComplementarioValor dc ON md.Id_DatosComplementarios = dc.Id
        INNER JOIN ERPHispatec.dbo.Zonas z ON dc.valor = z.Nombre
        WHERE z.Nombre = @zona_maq
          AND m.Identificacion LIKE 'V%'
        ORDER BY m.Identificacion
        FOR JSON PATH
    ) AS datos;

    -- =========================================================================
    -- CATÁLOGO 5: TRABAJADORES
    -- =========================================================================
    SELECT 'trabajadores' AS catalogo, (
        SELECT
            t.Id AS trabajador_id_erp,
            u.Id AS usuario_id_erp,
            u.Codigo AS CodigoUsuario,
            SUBSTRING(t.Codigo, 6, LEN(t.Codigo)) AS cod_trabajador,
            CONCAT(s.PrimerApellido, ' ', s.SegundoApellido, ' ', s.Nombre) AS nombre_completo
        FROM ERPHispatec.dbo.sujetos s
        INNER JOIN ERPHispatec.dbo.trabajadores t ON s.Id = t.Id_Sujeto
        INNER JOIN ERPHispatec.dbo.Usuarios u ON u.id_sujeto = s.Id
        INNER JOIN ERPHispatec.dbo.DireccionesSujeto ds ON ds.Id_Sujeto = s.Id
        INNER JOIN ERPHispatec.dbo.direcciones d ON ds.Id_Direccion = d.Id
        INNER JOIN ERPHispatec.dbo.Zonas z ON d.Id_Zona = z.Id
        WHERE z.Nombre = @zona_maq
        ORDER BY s.PrimerApellido, s.SegundoApellido, s.Nombre
        FOR JSON PATH
    ) AS datos;

    -- =========================================================================
    -- CATÁLOGO 6: LOTES (fincas + cultivos + sublotes)
    -- =========================================================================
    SELECT 'lotes' AS catalogo, (
        SELECT
            f.Id AS finca_id_erp,
            f.Codigo AS lote_codigo,
            CAST(f.SuperficieCultivable / 10000.0 AS DECIMAL(10,2)) AS hectareas_lote,
            c.Id AS lote_id_erp,
            TRIM(c.Descripcion) AS sublote,
            CAST(c.SuperficieCultivada / 10000.0 AS DECIMAL(10,2)) AS hectareas_sublote
        FROM ERPHispatec.dbo.Fincas f
        INNER JOIN ERPHispatec.dbo.Zonas z ON f.Id_zona = z.Id
        LEFT JOIN ERPHispatec.dbo.Cultivos c ON c.Id_finca = f.Id
        WHERE z.Codigo = @zona_per
          AND (f.Codigo LIKE 'U-%' OR f.Codigo LIKE '%P_A%' OR f.Id IN (440, 530, 640, 643))
        ORDER BY f.Codigo, TRIM(c.Descripcion)
        FOR JSON PATH
    ) AS datos;

    -- =========================================================================
    -- CATÁLOGO 7: PROCESOS (solo tractor)
    -- =========================================================================
    SELECT 'procesos' AS catalogo, (
        SELECT
            p.id                    AS proceso_id,
            p.codigo,
            p.nombre,
            p.requiere_bines,
            p.requiere_sublabores,
            p.tipo_registro
        FROM dbo.CLI547_AGM_MMA_PROCESOS p
        WHERE p.activo = 1
          AND p.tipo_registro = 'tractor'
        ORDER BY p.nombre
        FOR JSON PATH
    ) AS datos;

    -- =========================================================================
    -- CATÁLOGO 8: CAJAS DE CAMBIO (marchas de trabajo)
    -- =========================================================================
    SELECT 'cajas_cambios' AS catalogo, (
        SELECT id AS caja_id, nombre
        FROM dbo.CLI547_AGM_MMA_CAJAS_CAMBIOS
        ORDER BY id
        FOR JSON PATH
    ) AS datos;

    -- =========================================================================
    -- CATÁLOGO 9: TIPOS DE PARO
    -- =========================================================================
    SELECT 'tipos_paro' AS catalogo, (
        SELECT id AS tipo_paro_id, codigo, nombre, requiere_galones, requiere_equipo
        FROM dbo.CLI547_AGM_MMA_TIPOS_PARO
        WHERE activo = 1
        ORDER BY id
        FOR JSON PATH
    ) AS datos;

    -- =========================================================================
    -- CATÁLOGO 10: CHECKLIST ITEMS
    -- =========================================================================
    SELECT 'checklist_items' AS catalogo, (
        SELECT
            ci.id            AS item_id,
            ci.categoria_id,
            cc.nombre        AS categoria,
            ci.nombre        AS item_nombre,
            ci.orden,
            ci.tipo_registro
        FROM dbo.CLI547_AGM_MMA_CHECKLIST_ITEMS_CATALOGO ci
        INNER JOIN dbo.CLI547_AGM_MMA_CHECKLIST_CATEGORIAS cc ON cc.id = ci.categoria_id
        WHERE ci.activo = 1
        ORDER BY cc.orden, ci.orden
        FOR JSON PATH
    ) AS datos;

    -- =========================================================================
    -- CATÁLOGO 11: ÚLTIMO HORÓMETRO POR TRACTOR
    -- =========================================================================
    SELECT 'ultimo_horometro_tractores' AS catalogo, (
        SELECT
            t.tractor_id_erp,
            t.implemento_id_erp,
            t.codigo_tractor,
            t.codigo_implemento,
            t.ultimo_horometro_final,
            t.ultimo_implemento_final,
            t.ultima_fecha
        FROM
        (
            SELECT
                rd.tractor_id_erp,
                rd.implemento_id_erp,
                COALESCE(rd.codigo_tractor_snapshot COLLATE Modern_Spanish_CI_AS, m.Identificacion COLLATE Modern_Spanish_CI_AS) AS codigo_tractor,
                COALESCE(rd.codigo_implemento_snapshot COLLATE Modern_Spanish_CI_AS, m.Identificacion COLLATE Modern_Spanish_CI_AS) AS codigo_implemento,
                h.tractor_final                    AS ultimo_horometro_final,
                h.implemento_final                 AS ultimo_implemento_final,
                CONVERT(VARCHAR(10), rd.fecha, 23) AS ultima_fecha,
                ROW_NUMBER() OVER (PARTITION BY rd.tractor_id_erp ORDER BY rd.fecha DESC, h.updated_at DESC) AS rn
            FROM dbo.CLI547_AGM_MMA_REGISTROS_DIARIOS rd
            INNER JOIN dbo.CLI547_AGM_MMA_HOROMETROS h ON h.registro_id = rd.id
            LEFT JOIN ERPHispatec.dbo.Maquinaria m ON m.Id = rd.tractor_id_erp
            WHERE rd.tractor_id_erp IS NOT NULL
              AND h.tractor_final IS NOT NULL
              AND rd.estado IN ('completado','aprobado')
        ) t
        WHERE t.rn = 1
        ORDER BY t.tractor_id_erp, t.implemento_id_erp
        FOR JSON PATH
    ) AS datos;

    -- =========================================================================
    -- CATÁLOGO 12: FALLAS MECÁNICAS (con categoría y aplicación)
    -- =========================================================================
    SELECT 'fallas_mecanicas' AS catalogo, (
        SELECT
            id AS falla_id,
            codigo,
            nombre,
            categoria,
            aplicacion
        FROM dbo.CLI547_AGM_MMA_FALLAS_MECANICAS
        WHERE activo = 1
        ORDER BY nombre
        FOR JSON PATH
    ) AS datos;

    -- =========================================================================
    -- CATÁLOGO 13: LOTES_KMZ (con geometría) — CORREGIDO ESTRUCTURALMENTE
    -- =========================================================================
    SELECT 'lotes_kmz' AS catalogo, (
        SELECT
            cuLP.Id                                                         AS Id,
            (SELECT TOP 1 ca.Id FROM ERPHispatec.dbo.Campanyas ca
             WHERE ca.Componente = 1 ORDER BY ca.FechaInicial DESC)        AS Id_Campanya,
            @Id_Sede                                                        AS Id_Sede,
            fi.Id_Representante                                             AS Id_Fundo,
            eb.Id                                                           AS Id_Cultivo,
            ebv.Id                                                          AS Id_Variedad,
            fi.Id                                                           AS Id_Lote,
            cuLP.Id                                                         AS Id_Sublote,
            fi.Nombre                                                       AS Nombre_Lote,
            'BAJA'                                                          AS Prioridad,
            'CATALOGO'                                                      AS Estado,
            CONVERT(VARCHAR(10), GETDATE(), 120)                            AS FechaProgramada,
            NULL                                                            AS CoordenadasPoligono,
            NULL                                                            AS UsuarioAsignado,
            ISNULL(CAST(cuLP.SuperficieCultivada / 10000.0 AS DECIMAL(10,2)), 1.0) AS HectareasLote,
            CONVERT(INT, ROUND(
                ISNULL(CAST(cuLP.SuperficieCultivada / 10000.0 AS DECIMAL(10,2)), 1.0)
                * 10.0, 0
            ))                                                              AS TotalPlantas,
            eb.NombreComun                                                  AS NombreCultivo,
            ebv.Denominacion                                                AS NombreVariedad,
            z.Nombre                                                        AS NombreSede,
            cuLP.Descripcion                                                AS NombreSublote,
            CASE WHEN geo.Geometria IS NOT NULL
                 THEN geo.Geometria.STAsText()    ELSE NULL END              AS GeometriaWKT,
            CASE WHEN geo.Geometria IS NOT NULL
                 THEN geo.Geometria.STCentroid().STY ELSE NULL END           AS LatitudCentro,
            CASE WHEN geo.Geometria IS NOT NULL
                 THEN geo.Geometria.STCentroid().STX ELSE NULL END           AS LongitudCentro,
            CASE
                WHEN eb.NombreComun = 'UVA'       THEN '#8E44AD'
                WHEN eb.NombreComun = 'PALTO'     THEN '#27AE60'
                WHEN eb.NombreComun = 'ESPARRAGO' THEN '#E67E22'
                WHEN eb.NombreComun = 'ARANDANO'  THEN '#2980B9'
                ELSE '#95A5A6'
            END                                                             AS ColorCultivo,
            CAST(cuLP.Version AS BIGINT)                                    AS Version
        FROM ERPHispatec.dbo.Cultivos AS cuLP WITH (NOLOCK)
        INNER JOIN ERPHispatec.dbo.Fincas fi WITH (NOLOCK) ON fi.Id = cuLP.Id_Finca
        INNER JOIN ERPHispatec.dbo.Fincas_DatosComplementarios fdc WITH (NOLOCK) ON fi.Id = fdc.Id_Fincas
        INNER JOIN ERPHispatec.dbo.DatoComplementarioValor dcvc WITH (NOLOCK) ON dcvc.Id = fdc.Id_DatosComplementarios
        INNER JOIN ERPHispatec.dbo.DatosComplementarios dcc WITH (NOLOCK)
            ON dcc.Id = dcvc.Id_DatoComplementario AND dcc.Codigo = 'VAR'
        INNER JOIN ERPHispatec.dbo.EspecieBotanicaVariedad ebv WITH (NOLOCK) ON ebv.Id = dcvc.Valor
        INNER JOIN ERPHispatec.dbo.EspeciesBotanicas eb WITH (NOLOCK) ON eb.Id = ebv.Id_EspecieBotanica
        LEFT JOIN ERPHispatec.dbo.Zonas z ON z.Id = @Id_Sede
        OUTER APPLY (
            SELECT TOP 1 g.Geometria
            FROM ERPHispatec.dbo.Cultivos_Coordenadas cc2 WITH (NOLOCK)
            JOIN ERPHispatec.dbo.CoordenadaGPS g WITH (NOLOCK)
                ON g.Id = cc2.Id_Coordenadas AND g.Geometria IS NOT NULL
            WHERE cc2.Id_Cultivos = cuLP.Id
        ) geo
        WHERE TRY_CAST(dcvc.Valor AS FLOAT) IS NOT NULL
          AND fi.Id_Zona = @Id_Sede
        ORDER BY fi.Nombre, cuLP.Descripcion
        FOR JSON PATH
    ) AS datos;
END;
GO
    -- 11. PROCEDIMIENTOS DEL SUPERVISOR
    -- =============================================================================

    -- 11.1 Obtener registros para el supervisor (turno + aprobaciones + historial)
    -- Parámetros: @p_fecha DATE, @p_turno NVARCHAR(10) NULL (NULL = todos los turnos)
    -- Retorna un row por registro con sub-entidades como columnas JSON.
    CREATE OR ALTER PROCEDURE dbo.CLI547_AGMSP_MMA_GET_REGISTROS_SUPERVISOR
        @p_fecha DATE,
        @p_turno NVARCHAR(10) = NULL
    AS
    BEGIN
        SET NOCOUNT ON;
        SET XACT_ABORT ON;

        SELECT
            -- Identificación
            CAST(r.id AS NVARCHAR(36))              AS registro_id,
            r.numero_registro,
            CONVERT(VARCHAR(10), r.fecha, 23)       AS fecha,
            r.turno,
            r.estado,
            r.tipo_registro,

            -- Proceso y subproceso
            r.proceso_id,
            ISNULL(p.nombre, r.proceso_vehiculo)    AS proceso_nombre,
            ISNULL(p.codigo, r.proceso_vehiculo)    AS proceso_codigo,
            r.subproceso_id,
            r.subproceso_nombre,

            -- Cultivo (snapshot guardado al sincronizar)
            r.cultivo_id_erp,
            r.nombre_cultivo_snapshot               AS nombre_cultivo,

            -- Personas (snapshots guardados al sincronizar)
            r.operador_id_erp,
            r.nombre_operador_snapshot              AS nombre_operador,
            r.supervisor_id_erp,
            r.nombre_supervisor_snapshot            AS nombre_supervisor,

            -- Equipos (snapshots guardados al sincronizar)
            r.tractor_id_erp,
            r.codigo_tractor_snapshot               AS codigo_tractor,
            r.implemento_id_erp,
            r.codigo_implemento_snapshot            AS codigo_implemento,
            r.caja_cambios_id,
            cc.nombre                               AS caja_cambios_nombre,

            -- Campos adicionales
            r.observaciones_maq,
            r.firma_operador,
            r.motivo_rechazo,
            r.dispositivo_id,
            r.sincronizado_erp,
            r.sincronizado_at,
            r.created_at,
            r.jornada_inicio_at,
            r.jornada_fin_at,

            -- Sub-entidades embebidas como JSON para no hacer múltiples viajes al servidor.

            -- Horómetros / KM (tabla compartida; para vehículo estas columnas = km)
            (SELECT
                h.tractor_inicio,
                h.tractor_final,
                h.implemento_inicio,
                h.implemento_final
            FROM dbo.CLI547_AGM_MMA_HOROMETROS h
            WHERE h.registro_id = r.id
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)                          AS horometro_json,

            -- Tiempos de turno (tabla compartida; para vehículo = horas de ruta)
            (SELECT
                CONVERT(VARCHAR(8), tt.hora_salida_taller, 108)  AS hora_salida_taller,
                CONVERT(VARCHAR(8), tt.hora_llegada_punto, 108)  AS hora_llegada_punto,
                CONVERT(VARCHAR(8), tt.hora_salida_punto, 108)   AS hora_salida_punto,
                CONVERT(VARCHAR(8), tt.hora_llegada_taller, 108) AS hora_llegada_taller,
                tt.hora_refrigerio
            FROM dbo.CLI547_AGM_MMA_TIEMPOS_TURNO tt
            WHERE tt.registro_id = r.id
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)                          AS tiempos_turno_json,

            -- Datos específicos de vehículo (mismas tablas, campos renombrados)
            CASE WHEN r.tipo_registro = 'vehiculo' THEN
                (SELECT
                    h2.tractor_inicio                                AS km_camion_inicio,
                    h2.tractor_final                                 AS km_camion_final,
                    h2.implemento_inicio                             AS km_implemento_inicio,
                    h2.implemento_final                              AS km_implemento_final,
                    CONVERT(VARCHAR(8), tt2.hora_salida_taller, 108) AS hora_salida_base_td,
                    CONVERT(VARCHAR(8), tt2.hora_llegada_punto, 108) AS hora_llegada_zona,
                    CONVERT(VARCHAR(8), tt2.hora_salida_punto, 108)  AS hora_retorno_base,
                    CONVERT(VARCHAR(8), tt2.hora_llegada_taller, 108) AS hora_llegada_taller,
                    tt2.hora_refrigerio,
                    r.cantidad_tancadas
                FROM (SELECT 1 AS _) AS _d
                LEFT JOIN dbo.CLI547_AGM_MMA_HOROMETROS h2  ON h2.registro_id = r.id
                LEFT JOIN dbo.CLI547_AGM_MMA_TIEMPOS_TURNO tt2 ON tt2.registro_id = r.id
                FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)
            ELSE NULL END                                                   AS vehiculo_json,

            -- Paros de tractor
            (SELECT
                CAST(pe.id AS NVARCHAR(36))                      AS paro_id,
                pe.tipo_paro_id,
                tp.codigo                                         AS tipo_paro_codigo,
                tp.nombre                                         AS tipo_paro_nombre,
                pe.motivo,
                pe.equipo,
                CONVERT(VARCHAR(8), pe.hora_inicio, 108)         AS hora_inicio,
                CONVERT(VARCHAR(8), pe.hora_final, 108)          AS hora_final,
                pe.galones,
                pe.duracion_min
            FROM dbo.CLI547_AGM_MMA_PAROS_EQUIPOS pe
            LEFT JOIN dbo.CLI547_AGM_MMA_TIPOS_PARO tp ON tp.id = pe.tipo_paro_id
            WHERE pe.registro_id = r.id
            FOR JSON PATH)                                                  AS paros_json,

            -- Checklist
            (SELECT
                cr.item_id,
                ci.nombre                                         AS item_nombre,
                cc.nombre                                         AS categoria_nombre,
                cr.resultado,
                cr.observacion
            FROM dbo.CLI547_AGM_MMA_CHECKLIST_RESULTADOS cr
            INNER JOIN dbo.CLI547_AGM_MMA_CHECKLIST_ITEMS_CATALOGO ci ON ci.id = cr.item_id
            LEFT JOIN dbo.CLI547_AGM_MMA_CHECKLIST_CATEGORIAS cc ON cc.id = ci.categoria_id
            WHERE cr.registro_id = r.id
            ORDER BY ci.orden
            FOR JSON PATH)                                                  AS checklist_json,

            -- Bines de cosecha
            (SELECT
                b.franja_horaria,
                b.turno_franja,
                b.cantidad
            FROM dbo.CLI547_AGM_MMA_COSECHA_BINES b
            WHERE b.registro_id = r.id
            ORDER BY b.franja_horaria
            FOR JSON PATH)                                                  AS bines_json,

            -- Sectores / lotes trabajados
            (SELECT
                rl.lote_id_erp,
                rl.lote_codigo_snapshot                           AS lote_codigo,
                rl.sublote_snapshot                               AS lote_nombre,
                rl.finca_id_erp                                   AS finca_id,
                rl.area_trabajada_ha
            FROM dbo.CLI547_AGM_MMA_REGISTROS_LOTES rl
            WHERE rl.registro_id = r.id
            FOR JSON PATH)                                                  AS sectores_json,

            -- Combustible vehículo
            (SELECT
                cv.glns,
                CONVERT(VARCHAR(8), cv.hora_inicio, 108)         AS hora_inicio,
                CONVERT(VARCHAR(8), cv.hora_final, 108)          AS hora_final
            FROM dbo.CLI547_AGM_MMA_COMBUSTIBLE_VEHICULO cv
            WHERE cv.registro_id = r.id
            FOR JSON PATH)                                                  AS combustible_vehiculo_json,

            -- Paros vehículo
            (SELECT
                pv.motivo,
                CONVERT(VARCHAR(8), pv.hora_inicio, 108)         AS hora_inicio,
                CONVERT(VARCHAR(8), pv.hora_final, 108)          AS hora_final
            FROM dbo.CLI547_AGM_MMA_PAROS_VEHICULO pv
            WHERE pv.registro_id = r.id
            FOR JSON PATH)                                                  AS paros_vehiculo_json

        FROM dbo.CLI547_AGM_MMA_REGISTROS_DIARIOS r
        LEFT JOIN dbo.CLI547_AGM_MMA_PROCESOS p         ON p.id  = r.proceso_id
        LEFT JOIN dbo.CLI547_AGM_MMA_CAJAS_CAMBIOS cc   ON cc.id = r.caja_cambios_id

        WHERE r.fecha = @p_fecha
        AND (@p_turno IS NULL OR r.turno = @p_turno)
        AND r.estado <> 'permanently_failed'

        ORDER BY r.created_at DESC;
    END;
    GO

    -- 11.2 Jornadas activas para la vista del supervisor (tab Turno)
    -- Parámetros: @p_fecha DATE, @p_turno NVARCHAR(10) NULL
    -- Retorna una fila por jornada iniciada ese día, con conteo de registros y sync.
        CREATE OR ALTER PROCEDURE dbo.CLI547_AGMSP_MMA_GET_JORNADAS_SUPERVISOR
            @p_fecha DATE,
            @p_turno NVARCHAR(10) = NULL
    AS
    BEGIN
        SET NOCOUNT ON;
        SET XACT_ABORT ON;

        SELECT
            j.id,
            j.usuario_erp_id,
            LTRIM(RTRIM(CONCAT(s.PrimerApellido, ' ', s.SegundoApellido, ' ', s.Nombre))) AS nombre_usuario,
            j.dispositivo_id,
            j.turno,
            j.jornada_inicio_at,
            j.jornada_fin_at,
            CAST(CASE WHEN j.jornada_fin_at IS NOT NULL THEN 1 ELSE 0 END AS BIT) AS jornada_cerrada,

            -- Registros totales del operador para esa fecha/turno.
            -- operador_id_erp = Trabajadores.Id; t.Id viene del join Usuarios→Sujetos→Trabajadores.
            (SELECT COUNT(*)
            FROM dbo.CLI547_AGM_MMA_REGISTROS_DIARIOS r
            WHERE r.operador_id_erp = t.Id
            AND r.fecha = @p_fecha
            AND r.turno = j.turno)                                   AS total_registros,

            -- Registros ya sincronizados al ERP
            (SELECT COUNT(*)
            FROM dbo.CLI547_AGM_MMA_REGISTROS_DIARIOS r
            WHERE r.operador_id_erp = t.Id
            AND r.fecha = @p_fecha
            AND r.turno = j.turno
            AND r.sincronizado_erp = 1)                              AS registros_sincronizados,

            -- Registros con estado completado o aprobado
            (SELECT COUNT(*)
            FROM dbo.CLI547_AGM_MMA_REGISTROS_DIARIOS r
            WHERE r.operador_id_erp = t.Id
            AND r.fecha = @p_fecha
            AND r.turno = j.turno
            AND r.estado IN ('completado', 'aprobado', 'rechazado')) AS registros_completados

        FROM dbo.CLI547_AGM_MMA_STATUS_JORNADA j
        INNER JOIN Usuarios u     ON u.Id        = j.usuario_erp_id
        INNER JOIN Sujetos s      ON s.Id        = u.id_sujeto
        INNER JOIN trabajadores t ON t.Id_Sujeto = s.Id

        WHERE CAST(j.jornada_inicio_at AS DATE) = @p_fecha
        AND (@p_turno IS NULL OR j.turno = @p_turno)

        ORDER BY j.jornada_inicio_at ASC;
    END;
    GO

    -- 11.3 Aprobar o rechazar un registro
    -- Parámetros: @p_registro_id NVARCHAR(36), @p_supervisor_id_erp INT,
    --             @p_accion NVARCHAR(10) ('aprobar'|'rechazar'), @p_motivo NVARCHAR(MAX) NULL
    -- Retorna: @p_success BIT OUTPUT, @p_mensaje NVARCHAR(500) OUTPUT + SELECT success, mensaje, registro_id
    CREATE OR ALTER PROCEDURE dbo.CLI547_AGMSP_MMA_APROBAR_REGISTRO
        @p_registro_id       NVARCHAR(36),
        @p_supervisor_erp_id INT,
        @p_accion            NVARCHAR(10),
        @p_motivo            NVARCHAR(MAX) = NULL,
        @p_success           BIT             OUTPUT,
        @p_mensaje           NVARCHAR(500)   OUTPUT
    AS
    BEGIN
        SET NOCOUNT ON;
        SET XACT_ABORT ON;

        DECLARE @v_uid            UNIQUEIDENTIFIER;
        DECLARE @v_estado_actual  NVARCHAR(20);
        DECLARE @v_nuevo_estado   NVARCHAR(20);

        -- Validar y convertir el UUID
        SET @v_uid = TRY_CAST(@p_registro_id AS UNIQUEIDENTIFIER);
        IF @v_uid IS NULL
        BEGIN
            SET @p_success = 0; SET @p_mensaje = N'ID de registro inválido';
            SELECT @p_success AS success, @p_mensaje AS mensaje;
            RETURN;
        END;

        -- Verificar que el registro existe
        SELECT @v_estado_actual = estado
        FROM dbo.CLI547_AGM_MMA_REGISTROS_DIARIOS
        WHERE id = @v_uid;

        IF @v_estado_actual IS NULL
        BEGIN
            SET @p_success = 0; SET @p_mensaje = N'Registro no encontrado';
            SELECT @p_success AS success, @p_mensaje AS mensaje;
            RETURN;
        END;

        -- Mapear acción → nuevo estado (debe hacerse antes de las validaciones de estado)
        SET @v_nuevo_estado = CASE @p_accion
            WHEN 'aprobar'   THEN 'aprobado'
            WHEN 'rechazar'  THEN 'rechazado'
            ELSE NULL
        END;

        IF @v_nuevo_estado IS NULL
        BEGIN
            SET @p_success = 0; SET @p_mensaje = N'Acción inválida. Use "aprobar" o "rechazar"';
            SELECT @p_success AS success, @p_mensaje AS mensaje;
            RETURN;
        END;

        -- Idempotencia: si el registro ya está en el estado destino, retornar éxito sin modificar.
        -- Esto permite reintentos seguros en caso de fallo de red posterior al primer UPDATE.
        IF @v_estado_actual = @v_nuevo_estado
        BEGIN
            SET @p_success = 1;
            SET @p_mensaje = CONCAT(N'Registro ya estaba ', @v_nuevo_estado, N' (idempotente)');
            SELECT @p_success AS success, @p_mensaje AS mensaje, @p_registro_id AS registro_id;
            RETURN;
        END;

        -- Solo se puede aprobar/rechazar si está completado (o borrador como fallback)
        IF @v_estado_actual NOT IN ('completado', 'borrador')
        BEGIN
            SET @p_success = 0;
            SET @p_mensaje = CONCAT(N'El registro ya fue ', @v_estado_actual, N' y no puede modificarse');
            SELECT @p_success AS success, @p_mensaje AS mensaje;
            RETURN;
        END;

        BEGIN TRY
            UPDATE dbo.CLI547_AGM_MMA_REGISTROS_DIARIOS
            SET
                estado              = @v_nuevo_estado,
                supervisor_id_erp   = @p_supervisor_erp_id,
                aprobado_por_erp    = @p_supervisor_erp_id,
                aprobado_at         = GETDATE(),
                motivo_rechazo      = CASE WHEN @p_accion = 'rechazar' THEN @p_motivo ELSE NULL END,
                updated_at          = GETDATE()
            WHERE id = @v_uid;

            SET @p_success = 1;
            SET @p_mensaje = CONCAT(N'Registro ', @v_nuevo_estado, N' correctamente');
            SELECT @p_success AS success, @p_mensaje AS mensaje, @p_registro_id AS registro_id;
        END TRY
        BEGIN CATCH
            SET @p_success = 0;
            SET @p_mensaje = CONCAT(N'Error al actualizar: ', ERROR_MESSAGE());
            SELECT @p_success AS success, @p_mensaje AS mensaje;
        END CATCH;
    END;
    GO

    -- SP_MMA_ACTUALIZAR_STATUS_JORNADA
    -- Recibe un JSON con los datos de la jornada del operador y hace un UPSERT.
    -- La clave única es dispositivo + turno + fecha (no hora), así que
    -- si el operador manda el mismo JSON dos veces solo actualiza, no duplica.
    -- Devuelve success y un mensaje de texto.
    CREATE OR ALTER PROCEDURE dbo.CLI547_AGMSP_MMA_ACTUALIZAR_STATUS_JORNADA
        @p_payload NVARCHAR(MAX)
    AS
    BEGIN
        SET NOCOUNT ON;
        SET XACT_ABORT ON;

        DECLARE @v_usuario_id     INT;
        DECLARE @v_dispositivo_id VARCHAR(100);
        DECLARE @v_turno          VARCHAR(10);
        DECLARE @v_inicio_at      DATETIME2;
        DECLARE @v_fin_at         DATETIME2;

        BEGIN TRY
            -- Deserializar JSON
            SELECT
                @v_usuario_id     = CAST(JSON_VALUE(@p_payload, '$.usuario_id')       AS INT),
                @v_dispositivo_id =      JSON_VALUE(@p_payload, '$.dispositivo_id'),
                @v_turno          =      JSON_VALUE(@p_payload, '$.turno'),
                @v_inicio_at      = CAST(JSON_VALUE(@p_payload, '$.jornada_inicio_at') AS DATETIME2),
                @v_fin_at         = CAST(JSON_VALUE(@p_payload, '$.jornada_fin_at')    AS DATETIME2);

            IF @v_usuario_id IS NULL OR @v_usuario_id <= 0
            BEGIN
                SELECT CAST(0 AS BIT) AS success,
                    N'usuario_id inválido: debe ser un entero positivo del ERP (recibido: '
                    + ISNULL(CAST(@v_usuario_id AS NVARCHAR), 'NULL') + N')' AS mensaje;
                RETURN;
            END;
            IF @v_dispositivo_id IS NULL OR @v_turno IS NULL OR @v_inicio_at IS NULL
            BEGIN
                SELECT CAST(0 AS BIT) AS success, N'Payload inválido: faltan campos requeridos' AS mensaje;
                RETURN;
            END;

            -- UPSERT: si ya existe una fila para el mismo dispositivo+turno+día, actualizar;
            -- en caso contrario insertar.
            IF EXISTS (
                SELECT 1 FROM dbo.CLI547_AGM_MMA_STATUS_JORNADA
                WHERE dispositivo_id = @v_dispositivo_id
                AND turno           = @v_turno
                AND CAST(jornada_inicio_at AS DATE) = CAST(@v_inicio_at AS DATE)
            )
            BEGIN
                UPDATE dbo.CLI547_AGM_MMA_STATUS_JORNADA
                SET jornada_fin_at = @v_fin_at,
                    updated_at     = GETUTCDATE()
                WHERE dispositivo_id = @v_dispositivo_id
                AND turno           = @v_turno
                AND CAST(jornada_inicio_at AS DATE) = CAST(@v_inicio_at AS DATE);
            END
            ELSE
            BEGIN
                INSERT INTO dbo.CLI547_AGM_MMA_STATUS_JORNADA
                    (usuario_erp_id, dispositivo_id, turno, jornada_inicio_at, jornada_fin_at)
                VALUES
                    (@v_usuario_id, @v_dispositivo_id, @v_turno, @v_inicio_at, @v_fin_at);
            END;

            SELECT CAST(1 AS BIT) AS success, N'Status jornada actualizado correctamente' AS mensaje;
        END TRY
        BEGIN CATCH
            SELECT CAST(0 AS BIT) AS success,
                CONCAT(N'Error al actualizar status jornada: ', ERROR_MESSAGE()) AS mensaje;
        END CATCH;
    END;
    GO

    -- 12. SPs ADICIONALES: SESIÓN DISPOSITIVO Y LECTURA PORTERO
    -- =============================================================================

    -- 12.1 Crear sesión de dispositivo (login con PIN)
    -- Parámetros: @p_trabajador_id_erp INT, @p_dispositivo_id VARCHAR, @p_token VARCHAR
    -- Registra o renueva la sesión activa del dispositivo para el trabajador.
    -- Devuelve: success, mensaje, session_id (UNIQUEIDENTIFIER)
CREATE OR ALTER PROCEDURE dbo.CLI547_AGMSP_MMA_ACTUALIZAR_STATUS_JORNADA
    @p_payload NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @v_usuario_id INT, @v_dispositivo_id VARCHAR(100), @v_turno VARCHAR(10), 
            @v_inicio_at DATETIME2, @v_fin_at DATETIME2;

    BEGIN TRY
        SELECT
            @v_usuario_id = CAST(JSON_VALUE(@p_payload, '$.usuario_id') AS INT),
            @v_dispositivo_id = JSON_VALUE(@p_payload, '$.dispositivo_id'),
            @v_turno = JSON_VALUE(@p_payload, '$.turno'),
            @v_inicio_at = CAST(JSON_VALUE(@p_payload, '$.jornada_inicio_at') AS DATETIME2),
            @v_fin_at = CAST(JSON_VALUE(@p_payload, '$.jornada_fin_at') AS DATETIME2);

        IF @v_usuario_id IS NULL OR @v_usuario_id <= 0 OR @v_dispositivo_id IS NULL OR @v_turno IS NULL OR @v_inicio_at IS NULL
        BEGIN
            SELECT CAST(0 AS BIT) AS success, N'Payload inválido: faltan campos requeridos' AS mensaje;
            RETURN;
        END;

        -- BUSCAR POR USUARIO + TURNO + FECHA (no por dispositivo)
        IF EXISTS (
            SELECT 1 FROM dbo.CLI547_AGM_MMA_STATUS_JORNADA
            WHERE usuario_erp_id = @v_usuario_id
              AND turno = @v_turno
              AND CAST(jornada_inicio_at AS DATE) = CAST(@v_inicio_at AS DATE)
        )
        BEGIN
            UPDATE dbo.CLI547_AGM_MMA_STATUS_JORNADA
            SET 
                dispositivo_id = @v_dispositivo_id,  -- Se actualiza el dispositivo (puede cambiar)
                jornada_inicio_at = @v_inicio_at,    -- Se actualiza la hora de inicio
                jornada_fin_at = @v_fin_at,
                updated_at = GETUTCDATE()
            WHERE usuario_erp_id = @v_usuario_id
              AND turno = @v_turno
              AND CAST(jornada_inicio_at AS DATE) = CAST(@v_inicio_at AS DATE);
        END
        ELSE
        BEGIN
            INSERT INTO dbo.CLI547_AGM_MMA_STATUS_JORNADA 
                (usuario_erp_id, dispositivo_id, turno, jornada_inicio_at, jornada_fin_at, created_at, updated_at)
            VALUES 
                (@v_usuario_id, @v_dispositivo_id, @v_turno, @v_inicio_at, @v_fin_at, GETUTCDATE(), GETUTCDATE());
        END

        SELECT CAST(1 AS BIT) AS success, N'Status jornada actualizado correctamente' AS mensaje;
    END TRY
    BEGIN CATCH
        SELECT CAST(0 AS BIT) AS success, CONCAT(N'Error: ', ERROR_MESSAGE()) AS mensaje;
    END CATCH;
END;
GO

    -- 12.2 Registrar lectura del portero (control de ingreso de equipos)
    -- Parámetros: @p_payload NVARCHAR(MAX) — JSON con los datos de la lectura
    -- Hace UPSERT en la tabla de lecturas del portero.
    -- Devuelve: success, mensaje, lectura_id (UNIQUEIDENTIFIER)
    CREATE OR ALTER PROCEDURE dbo.CLI547_AGMSP_MMA_REGISTRAR_LECTURA_PORTERO
        @p_payload NVARCHAR(MAX)
    AS
    BEGIN
        SET NOCOUNT ON;
        SET XACT_ABORT ON;

        DECLARE
            @v_id                   UNIQUEIDENTIFIER,
            @v_portero_id_erp       INT,
            @v_tractor_id_erp       INT,
            @v_tractor_codigo       VARCHAR(50),
            @v_tractor_leido_at     DATETIME2,
            @v_implemento_id_erp    INT,
            @v_implemento_codigo    VARCHAR(50),
            @v_implemento_leido_at  DATETIME2,
            @v_trabajador_id_erp    INT,
            @v_trabajador_codigo    VARCHAR(50),
            @v_operador_leido_at    DATETIME2,
            @v_cultivo_id_erp       INT,
            @v_cultivo_nombre       NVARCHAR(200),
            @v_comentario           NVARCHAR(500),
            @v_dispositivo_id       VARCHAR(100);

        BEGIN TRY
            IF ISJSON(@p_payload) = 0
            BEGIN
                SELECT CAST(0 AS BIT) AS success, N'Payload JSON inválido' AS mensaje, NULL AS lectura_id;
                RETURN;
            END;

            -- Extraer campos del JSON
            SET @v_id               = COALESCE(TRY_CONVERT(UNIQUEIDENTIFIER, JSON_VALUE(@p_payload, '$.id')), NEWID());
            SET @v_portero_id_erp   = TRY_CAST(JSON_VALUE(@p_payload, '$.portero_id_erp')      AS INT);
            SET @v_tractor_id_erp   = TRY_CAST(JSON_VALUE(@p_payload, '$.tractor_id_erp')      AS INT);
            SET @v_tractor_codigo   =           JSON_VALUE(@p_payload, '$.tractor_codigo');
            SET @v_tractor_leido_at = TRY_CAST(JSON_VALUE(@p_payload, '$.tractor_leido_at')    AS DATETIME2);
            SET @v_implemento_id_erp= TRY_CAST(JSON_VALUE(@p_payload, '$.implemento_id_erp')   AS INT);
            SET @v_implemento_codigo=           JSON_VALUE(@p_payload, '$.implemento_codigo');
            SET @v_implemento_leido_at=TRY_CAST(JSON_VALUE(@p_payload, '$.implemento_leido_at') AS DATETIME2);
            SET @v_trabajador_id_erp= TRY_CAST(JSON_VALUE(@p_payload, '$.trabajador_id_erp')   AS INT);
            SET @v_trabajador_codigo=           JSON_VALUE(@p_payload, '$.trabajador_codigo');
            SET @v_operador_leido_at= TRY_CAST(JSON_VALUE(@p_payload, '$.operador_leido_at')   AS DATETIME2);
            SET @v_cultivo_id_erp   = TRY_CAST(JSON_VALUE(@p_payload, '$.cultivo_id_erp')      AS INT);
            SET @v_cultivo_nombre   =           JSON_VALUE(@p_payload, '$.cultivo_nombre');
            SET @v_comentario       =           JSON_VALUE(@p_payload, '$.comentario');
            SET @v_dispositivo_id   =           JSON_VALUE(@p_payload, '$.dispositivo_id');

            IF @v_portero_id_erp IS NULL
            BEGIN
                SELECT CAST(0 AS BIT) AS success, N'portero_id_erp es obligatorio' AS mensaje, NULL AS lectura_id;
                RETURN;
            END;

            -- UPSERT por id (idempotente en reintentos desde el mismo dispositivo)
            MERGE dbo.CLI547_AGM_MMA_PORTERO_LECTURAS AS target
            USING (SELECT @v_id AS lid) AS source ON target.id = source.lid
            WHEN MATCHED THEN UPDATE SET
                portero_id_erp       = @v_portero_id_erp,
                tractor_id_erp       = COALESCE(@v_tractor_id_erp,    target.tractor_id_erp),
                tractor_codigo       = COALESCE(@v_tractor_codigo,     target.tractor_codigo),
                tractor_leido_at     = COALESCE(@v_tractor_leido_at,   target.tractor_leido_at),
                implemento_id_erp    = COALESCE(@v_implemento_id_erp,  target.implemento_id_erp),
                implemento_codigo    = COALESCE(@v_implemento_codigo,   target.implemento_codigo),
                implemento_leido_at  = COALESCE(@v_implemento_leido_at,target.implemento_leido_at),
                trabajador_id_erp    = COALESCE(@v_trabajador_id_erp,  target.trabajador_id_erp),
                trabajador_codigo    = COALESCE(@v_trabajador_codigo,   target.trabajador_codigo),
                operador_leido_at    = COALESCE(@v_operador_leido_at,   target.operador_leido_at),
                cultivo_id_erp       = COALESCE(@v_cultivo_id_erp,     target.cultivo_id_erp),
                cultivo_nombre       = COALESCE(@v_cultivo_nombre,      target.cultivo_nombre),
                comentario           = COALESCE(@v_comentario,          target.comentario),
                dispositivo_id       = COALESCE(@v_dispositivo_id,      target.dispositivo_id),
                hora_sincronizacion  = GETUTCDATE()
            WHEN NOT MATCHED THEN INSERT (
                id, portero_id_erp, tractor_id_erp, tractor_codigo, tractor_leido_at,
                implemento_id_erp, implemento_codigo, implemento_leido_at,
                trabajador_id_erp, trabajador_codigo, operador_leido_at,
                cultivo_id_erp, cultivo_nombre, comentario, dispositivo_id, hora_sincronizacion
            ) VALUES (
                @v_id, @v_portero_id_erp, @v_tractor_id_erp, @v_tractor_codigo, @v_tractor_leido_at,
                @v_implemento_id_erp, @v_implemento_codigo, @v_implemento_leido_at,
                @v_trabajador_id_erp, @v_trabajador_codigo, @v_operador_leido_at,
                @v_cultivo_id_erp, @v_cultivo_nombre, @v_comentario, @v_dispositivo_id, GETUTCDATE()
            );

            SELECT
                CAST(1 AS BIT)                       AS success,
                N'Lectura registrada correctamente'   AS mensaje,
                CAST(@v_id AS NVARCHAR(36))           AS lectura_id;
        END TRY
        BEGIN CATCH
            SELECT
                CAST(0 AS BIT)                                                    AS success,
                CONCAT(N'Error al registrar lectura: ', ERROR_MESSAGE())          AS mensaje,
                NULL                                                              AS lectura_id;
        END CATCH;
    END;
    GO

    -- =============================================================================
    -- NOTA: dbo.CLI547_AGMSP_MMA_GetPerfilProfesional
    -- Este SP es nativo del ERP (preexistente en SQL Server) y NO se crea aquí.
    -- Parámetro de entrada: @UsuarioCodigo VARCHAR — código del trabajador (ej. "12345").
    -- Retorna los datos de perfil profesional para la pantalla de login del APK.
    -- Verificar que exista en la BD antes de ejecutar el APK en producción.
    -- =============================================================================

    -- =============================================================================
    -- 13. MENSAJES FINALES
    PRINT '====================================================================================================';
    PRINT '✅ SCRIPT ÚNICO v8.0.0 COMPLETADO EXITOSAMENTE – LISTO PARA PRODUCCIÓN';
    PRINT '   Esquema     : dbo';
    PRINT '   Prefijo tablas : CLI547_MMA_*';
    PRINT '   Prefijo SPs    : CLI547_AGMSP_MMA_*';
    PRINT '   - Tablas: tractor, vehículo, sublabores, marchas, incumplimientos, auditoría';
    PRINT '   - SP unificado de sincronización (con sublabores y marchas)';
    PRINT '   - SP de cierre extendido, dashboard admin, incumplimientos';
    PRINT '   - CLI547_AGMSP_MMA_CREAR_SESION: gestión de sesiones por dispositivo';
    PRINT '   - CLI547_AGMSP_MMA_REGISTRAR_LECTURA_PORTERO: control de ingreso equipos';
    PRINT '   - CLI547_AGMSP_MMA_GET_REGISTROS_SUPERVISOR + APROBAR_REGISTRO';
    PRINT '   - CLI547_AGMSP_MMA_ACTUALIZAR_STATUS_JORNADA: UPSERT status jornada';
    PRINT '   - Vistas, índices y trigger de auditoría';
    PRINT '   - Catálogos: procesos tractor + procesos vehículo + tipos_paro + checklist';
    PRINT '====================================================================================================';







    -------------------------------------------------------------------------------
    ------------------------------------------------------------------------------
    ------SP PARA INDICADORES PREVIOS A LA DOCUMENTACION 
    ------------------------------------------------------------------------------
    -------------------------------------------------------------------------------
    -- =====================================================================
    --  VISTA BASE 
    -- =====================================================================

    -- =============================================================================
-- 13. MÓDULO FALLAS MECÁNICAS
-- =============================================================================

-- 13.1 Catálogo de tipos de falla mecánica
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA='dbo' AND TABLE_NAME='CLI547_AGM_MMA_FALLAS_MECANICAS')
BEGIN
    CREATE TABLE dbo.CLI547_AGM_MMA_FALLAS_MECANICAS (
        id      INT IDENTITY(1,1) PRIMARY KEY,
        codigo  VARCHAR(30)  NOT NULL UNIQUE,
        nombre  VARCHAR(200) NOT NULL,
        activo  BIT          NOT NULL DEFAULT 1,
        created_at DATETIME2 NOT NULL DEFAULT GETDATE()
    );

    INSERT INTO dbo.CLI547_AGM_MMA_FALLAS_MECANICAS (codigo, nombre) VALUES
        ('MOTOR',           'Falla de motor'),
        ('HIDRAULICO',      'Falla hidráulica'),
        ('ELECTRICO',       'Falla eléctrica'),
        ('FRENOS',          'Falla de frenos'),
        ('TRANSMISION',     'Falla de transmisión'),
        ('SISTEMA_ENFR',    'Sistema de enfriamiento'),
        ('NEUMATICOS',      'Neumáticos / Ruedas'),
        ('IMPLEMENTO',      'Falla de implemento'),
        ('HIDRAULICO_IMP',  'Hidráulico de implemento'),
        ('OTRO',            'Otro');
END
GO

-- 13.2 Agregar columnas de falla mecánica y cierre mecánico a PAROS_EQUIPOS
-- (idempotente — usa IF NOT EXISTS por columna)
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='dbo' AND TABLE_NAME='CLI547_AGM_MMA_PAROS_EQUIPOS' AND COLUMN_NAME='falla_mecanica_id')
    ALTER TABLE dbo.CLI547_AGM_MMA_PAROS_EQUIPOS ADD falla_mecanica_id    INT NULL REFERENCES dbo.CLI547_AGM_MMA_FALLAS_MECANICAS(id);
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='dbo' AND TABLE_NAME='CLI547_AGM_MMA_PAROS_EQUIPOS' AND COLUMN_NAME='falla_mecanica_nombre')
    ALTER TABLE dbo.CLI547_AGM_MMA_PAROS_EQUIPOS ADD falla_mecanica_nombre VARCHAR(200) NULL;
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='dbo' AND TABLE_NAME='CLI547_AGM_MMA_PAROS_EQUIPOS' AND COLUMN_NAME='hora_inicio_real')
    ALTER TABLE dbo.CLI547_AGM_MMA_PAROS_EQUIPOS ADD hora_inicio_real      TIME NULL;
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='dbo' AND TABLE_NAME='CLI547_AGM_MMA_PAROS_EQUIPOS' AND COLUMN_NAME='hora_fin_real')
    ALTER TABLE dbo.CLI547_AGM_MMA_PAROS_EQUIPOS ADD hora_fin_real         TIME NULL;
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='dbo' AND TABLE_NAME='CLI547_AGM_MMA_PAROS_EQUIPOS' AND COLUMN_NAME='mecanico_id_erp')
    ALTER TABLE dbo.CLI547_AGM_MMA_PAROS_EQUIPOS ADD mecanico_id_erp       INT NULL;
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='dbo' AND TABLE_NAME='CLI547_AGM_MMA_PAROS_EQUIPOS' AND COLUMN_NAME='mecanico_nombre')
    ALTER TABLE dbo.CLI547_AGM_MMA_PAROS_EQUIPOS ADD mecanico_nombre       VARCHAR(300) NULL;
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='dbo' AND TABLE_NAME='CLI547_AGM_MMA_PAROS_EQUIPOS' AND COLUMN_NAME='trabajo_realizado')
    ALTER TABLE dbo.CLI547_AGM_MMA_PAROS_EQUIPOS ADD trabajo_realizado     NVARCHAR(MAX) NULL;
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='dbo' AND TABLE_NAME='CLI547_AGM_MMA_PAROS_EQUIPOS' AND COLUMN_NAME='estado_falla')
    ALTER TABLE dbo.CLI547_AGM_MMA_PAROS_EQUIPOS ADD estado_falla          VARCHAR(30) NULL DEFAULT 'pendiente';
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='dbo' AND TABLE_NAME='CLI547_AGM_MMA_PAROS_EQUIPOS' AND COLUMN_NAME='completado_at')
    ALTER TABLE dbo.CLI547_AGM_MMA_PAROS_EQUIPOS ADD completado_at         DATETIME2 NULL;
GO

-- 13.3 SP: Obtener paros mecánicos pendientes para el módulo mecánico
-- Retorna todos los paros con falla_mecanica_id registrada, filtrados por fecha.
-- El mecánico ve los paros de TODOS los operadores ese día.
CREATE OR ALTER PROCEDURE dbo.CLI547_AGMSP_MMA_GET_PAROS_MECANICO
    @p_fecha    DATE,
    @p_estado   VARCHAR(30) = NULL  -- NULL = todos; 'pendiente' | 'resuelto' | 'requiere_repuesto'
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        CAST(pe.id AS NVARCHAR(36))                              AS paro_id,
        CAST(rd.id AS NVARCHAR(36))                             AS registro_id,
        rd.numero_registro,
        CONVERT(VARCHAR(10), rd.fecha, 23)                      AS fecha,
        rd.turno,
        rd.operador_id_erp,
        rd.nombre_operador_snapshot                             AS operador_nombre,
        rd.tractor_id_erp,
        COALESCE(rd.codigo_tractor_snapshot, m.Identificacion)  AS tractor_codigo,
        tp.codigo                                               AS tipo_paro_codigo,
        tp.nombre                                               AS tipo_paro_nombre,
        pe.falla_mecanica_id,
        pe.falla_mecanica_nombre,
        pe.motivo                                               AS motivo_operador,
        CONVERT(VARCHAR(8), pe.hora_inicio, 108)                AS hora_inicio_operador,
        CONVERT(VARCHAR(8), pe.hora_fin_real, 108)              AS hora_fin_real,
        CONVERT(VARCHAR(8), pe.hora_inicio_real, 108)           AS hora_inicio_real,
        pe.mecanico_id_erp,
        pe.mecanico_nombre,
        pe.trabajo_realizado,
        ISNULL(pe.estado_falla, 'pendiente')                    AS estado_falla,
        pe.completado_at
    FROM dbo.CLI547_AGM_MMA_PAROS_EQUIPOS pe
    INNER JOIN dbo.CLI547_AGM_MMA_REGISTROS_DIARIOS rd ON rd.id = pe.registro_id
    INNER JOIN dbo.CLI547_AGM_MMA_TIPOS_PARO tp         ON tp.id = pe.tipo_paro_id
    LEFT  JOIN dbo.Maquinaria m                          ON m.Id  = rd.tractor_id_erp
    WHERE rd.fecha = @p_fecha
      AND pe.falla_mecanica_id IS NOT NULL
      AND (@p_estado IS NULL OR ISNULL(pe.estado_falla, 'pendiente') = @p_estado)
    ORDER BY rd.fecha DESC, pe.hora_inicio ASC;
END;
GO

-- 13.4 SP: Mecánico completa una falla (inserta horas reales + descripción trabajo)
CREATE OR ALTER PROCEDURE dbo.CLI547_AGMSP_MMA_COMPLETAR_FALLA_MECANICA
    @p_paro_id            NVARCHAR(36),
    @p_hora_inicio_real   NVARCHAR(8),   -- HH:mm o HH:mm:ss
    @p_hora_fin_real      NVARCHAR(8),   -- HH:mm o HH:mm:ss
    @p_mecanico_id_erp    INT,
    @p_trabajo_realizado  NVARCHAR(MAX)  = NULL,
    @p_estado_falla       VARCHAR(30)    = 'resuelto',
    @p_mecanico_nombre    NVARCHAR(300)  = NULL,  -- nombre enviado desde la app (override)
    @p_success            BIT            OUTPUT,
    @p_mensaje            NVARCHAR(500)  OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @v_paro_uid UNIQUEIDENTIFIER;
    DECLARE @v_mecanico_nombre VARCHAR(300);

    SET @v_paro_uid = TRY_CAST(@p_paro_id AS UNIQUEIDENTIFIER);
    IF @v_paro_uid IS NULL
    BEGIN
        SET @p_success = 0; SET @p_mensaje = N'ID de paro inválido';
        SELECT @p_success AS success, @p_mensaje AS mensaje; RETURN;
    END;

    IF NOT EXISTS (SELECT 1 FROM dbo.CLI547_AGM_MMA_PAROS_EQUIPOS WHERE id = @v_paro_uid)
    BEGIN
        SET @p_success = 0; SET @p_mensaje = N'Paro no encontrado';
        SELECT @p_success AS success, @p_mensaje AS mensaje; RETURN;
    END;

    -- Nombre del mecánico: usa el enviado por la app; si no viene, consulta el ERP
    IF @p_mecanico_nombre IS NOT NULL AND LEN(TRIM(@p_mecanico_nombre)) > 0
        SET @v_mecanico_nombre = @p_mecanico_nombre;
    ELSE
        SELECT TOP 1 @v_mecanico_nombre = CONCAT(s.PrimerApellido, ' ', s.SegundoApellido, ' ', s.Nombre)
        FROM trabajadores t
        INNER JOIN Sujetos s ON s.Id = t.Id_Sujeto
        WHERE t.Id = @p_mecanico_id_erp;

    BEGIN TRY
        UPDATE dbo.CLI547_AGM_MMA_PAROS_EQUIPOS
        SET
            -- Tiempos reales del mecánico (campos de control interno)
            hora_inicio_real   = TRY_CAST(@p_hora_inicio_real AS TIME),
            hora_fin_real      = TRY_CAST(@p_hora_fin_real    AS TIME),
            -- Actualizar también hora_inicio y hora_fin del operador
            -- para que el registro reflejeje los tiempos reales de la falla
            hora_inicio        = TRY_CAST(@p_hora_inicio_real AS TIME),
            hora_fin           = TRY_CAST(@p_hora_fin_real    AS TIME),
            -- Trabajo y mecánico
            mecanico_id_erp    = @p_mecanico_id_erp,
            mecanico_nombre    = @v_mecanico_nombre,
            trabajo_realizado  = @p_trabajo_realizado,
            estado_falla       = ISNULL(@p_estado_falla, 'resuelto'),
            completado_at      = GETDATE()
        WHERE id = @v_paro_uid;

        SET @p_success = 1;
        SET @p_mensaje = N'Falla mecánica completada correctamente';
        SELECT @p_success AS success, @p_mensaje AS mensaje;
    END TRY
    BEGIN CATCH
        SET @p_success = 0;
        SET @p_mensaje = CONCAT(N'Error: ', ERROR_MESSAGE());
        SELECT @p_success AS success, @p_mensaje AS mensaje;
    END CATCH;
END;
GO

-- =============================================================================
CREATE OR ALTER VIEW v_mma_tiempos_tpm AS
WITH turnos AS (
    SELECT 
        r.id AS registro_id,
        r.fecha,
        r.turno,
        r.proceso_id,
        r.tractor_id_erp,
        r.operador_id_erp,
        480 AS T_TC_min,
        30 AS T_PP_min,
        0 AS T_NU_min,
        480 - 30 AS T_DO_min,
        ISNULL(DATEDIFF(MINUTE, tt.hora_salida_taller, tt.hora_llegada_punto), 0) 
        + ISNULL(DATEDIFF(MINUTE, tt.hora_salida_punto, tt.hora_llegada_taller), 0) AS T_TR_min,
        -- T_PE: Paradas EXTERNAS (CLIMA, COMBUSTIBLE, CALIBRACION, CAPACITACION)
        ISNULL((
            SELECT SUM(pe.duracion_min)
            FROM CLI547_AGM_MMA_PAROS_EQUIPOS pe
            INNER JOIN CLI547_AGM_MMA_TIPOS_PARO tp ON tp.id = pe.tipo_paro_id
            WHERE pe.registro_id = r.id 
              AND tp.codigo IN ('CLIMA', 'COMBUSTIBLE', 'CALIBRACION', 'CAPACITACION')
        ), 0) AS T_PE_min,
        -- T_PI: Paradas INTERNAS (MECANICO)
        ISNULL((
            SELECT SUM(pe.duracion_min)
            FROM CLI547_AGM_MMA_PAROS_EQUIPOS pe
            INNER JOIN CLI547_AGM_MMA_TIPOS_PARO tp ON tp.id = pe.tipo_paro_id
            WHERE pe.registro_id = r.id 
              AND tp.codigo IN ('MECANICO')
        ), 0) AS T_PI_min,
        -- Horómetro según proceso (cosecha usa tractor, otros implemento)
        CASE 
            WHEN p.codigo = 'COSEC' THEN ISNULL(h.horas_tractor * 60, 0)
            ELSE ISNULL(h.horas_implemento * 60, 0)
        END AS T_O_min,
        ISNULL((SELECT SUM(cantidad) FROM CLI547_AGM_MMA_COSECHA_BINES WHERE registro_id = r.id), 0) AS Q_bines,
        ISNULL((SELECT SUM(area_trabajada_ha) FROM CLI547_AGM_MMA_REGISTROS_LOTES WHERE registro_id = r.id), 0) AS Q_ha,
        ISNULL(p.rendimiento_teorico, 1.0) AS capacidad_nominal,
        CASE WHEN p.codigo = 'COSEC' THEN 'bines' ELSE 'ha' END AS unidad_medida
    FROM CLI547_AGM_MMA_REGISTROS_DIARIOS r
    LEFT JOIN CLI547_AGM_MMA_HOROMETROS h ON h.registro_id = r.id
    LEFT JOIN CLI547_AGM_MMA_TIEMPOS_TURNO tt ON tt.registro_id = r.id
    LEFT JOIN CLI547_AGM_MMA_PROCESOS p ON p.id = r.proceso_id
    WHERE r.estado IN ('completado', 'aprobado')
)
SELECT 
    registro_id,
    fecha,
    turno,
    proceso_id,
    tractor_id_erp,
    operador_id_erp,
    T_TC_min,
    T_PP_min,
    T_NU_min,
    T_DO_min,
    T_TR_min,
    T_PE_min,
    T_PI_min,
    T_O_min,
    Q_bines,
    Q_ha,
    capacidad_nominal,
    unidad_medida,
    T_DO_min - T_PE_min AS T_T_min,
    T_PE_min + T_PI_min AS T_TPNP_min,
    T_PP_min + T_NU_min AS T_TPP_min,
    CASE WHEN unidad_medida = 'bines' THEN Q_bines ELSE Q_ha END AS Q
FROM turnos;
GO


    -- =====================================================================
    -- 3. VISTA DE INDICADORES
    -- =====================================================================


    CREATE VIEW v_mma_indicadores_tpm AS
    SELECT 
        v.registro_id,
        v.fecha,
        v.turno,
        v.proceso_id,
        v.tractor_id_erp,
        v.operador_id_erp,
        v.T_TC_min,
        v.T_PP_min,
        v.T_NU_min,
        v.T_DO_min,
        v.T_TR_min,
        v.T_PE_min,
        v.T_PI_min,
        v.T_O_min,
        v.T_T_min,
        v.T_TPNP_min,
        v.T_TPP_min,
        v.Q,
        v.capacidad_nominal,
        -- GU
        CASE WHEN v.T_TC_min > 0 THEN ROUND(CAST(v.T_DO_min AS FLOAT) / v.T_TC_min, 4) ELSE 0 END AS GU,
        -- D_PR
        CASE WHEN v.T_DO_min > 0 THEN ROUND(CAST(v.T_T_min AS FLOAT) / v.T_DO_min, 4) ELSE 0 END AS D_PR,
        -- D_MA
        CASE WHEN v.T_T_min > 0 THEN ROUND(CAST(v.T_O_min AS FLOAT) / v.T_T_min, 4) ELSE 0 END AS D_MA,
        -- D
        CASE WHEN v.T_DO_min > 0 THEN ROUND(CAST(v.T_O_min AS FLOAT) / v.T_DO_min, 4) ELSE 0 END AS D,
        -- R
        CASE 
            WHEN v.T_O_min > 0 AND v.capacidad_nominal > 0 THEN 
                ROUND(CAST(v.Q AS FLOAT) / ((v.T_O_min / 60.0) * v.capacidad_nominal), 4)
            ELSE 0 
        END AS R,
        1.0 AS C,
        -- EGE
        ROUND(
            (CASE WHEN v.T_DO_min > 0 THEN CAST(v.T_O_min AS FLOAT) / v.T_DO_min ELSE 0 END) *
            (CASE WHEN v.T_O_min > 0 AND v.capacidad_nominal > 0 THEN 
                CAST(v.Q AS FLOAT) / ((v.T_O_min / 60.0) * v.capacidad_nominal) 
            ELSE 0 END) * 1.0
        , 4) AS EGE,
        -- PTE
        ROUND(
            (CASE WHEN v.T_TC_min > 0 THEN CAST(v.T_DO_min AS FLOAT) / v.T_TC_min ELSE 0 END) *
            (CASE WHEN v.T_DO_min > 0 THEN CAST(v.T_O_min AS FLOAT) / v.T_DO_min ELSE 0 END) *
            (CASE WHEN v.T_O_min > 0 AND v.capacidad_nominal > 0 THEN 
                CAST(v.Q AS FLOAT) / ((v.T_O_min / 60.0) * v.capacidad_nominal) 
            ELSE 0 END) * 1.0
        , 4) AS PTE,
        -- I_TR
        CASE WHEN v.T_DO_min > 0 THEN ROUND(1 - CAST(v.T_TR_min AS FLOAT) / v.T_DO_min, 4) ELSE 0 END AS I_TR,
        -- T_NO
        CASE WHEN v.capacidad_nominal > 0 THEN ROUND((v.Q / v.capacidad_nominal) * 60, 2) ELSE 0 END AS T_NO_min,
        -- T_MVO
        CASE WHEN v.capacidad_nominal > 0 THEN ROUND(v.T_O_min - ((v.Q / v.capacidad_nominal) * 60), 2) ELSE 0 END AS T_MVO_min,
        -- T_EP
        CASE WHEN v.capacidad_nominal > 0 THEN ROUND((v.Q / v.capacidad_nominal) * 60, 2) ELSE 0 END AS T_EP_min
    FROM v_mma_tiempos_tpm v;
    GO

    -- =====================================================================
    -- 4. SP: TABLA DIARIA
    -- =====================================================================


    CREATE PROCEDURE CLI547_AGM_SP_MMA_TPM_TABLA_DIARIA
        @p_fecha_desde DATE,
        @p_fecha_hasta DATE,
        @p_turno VARCHAR(10) = NULL,
        @p_proceso_id INT = NULL,
        @p_cultivo_id INT = NULL,
        @p_tractor_id INT = NULL
    AS
    BEGIN
        SET NOCOUNT ON;
        CREATE TABLE #resultados (fecha DATE, GU DECIMAL(10,2), D_PR DECIMAL(10,2), D_MA DECIMAL(10,2),
                                D DECIMAL(10,2), R DECIMAL(10,2), C DECIMAL(10,2), EGE DECIMAL(10,2),
                                PTE DECIMAL(10,2), I_TR DECIMAL(10,2), total_registros INT,
                                horas_operativas DECIMAL(10,2), horas_planificadas DECIMAL(10,2),
                                produccion_total DECIMAL(12,2));

        INSERT INTO #resultados
        SELECT 
            i.fecha,
            ROUND(AVG(i.GU) * 100, 2) AS GU,
            ROUND(AVG(i.D_PR) * 100, 2) AS D_PR,
            ROUND(AVG(i.D_MA) * 100, 2) AS D_MA,
            ROUND(AVG(i.D) * 100, 2) AS D,
            ROUND(AVG(i.R) * 100, 2) AS R,
            100.0 AS C,
            ROUND(AVG(i.EGE) * 100, 2) AS EGE,
            ROUND(AVG(i.PTE) * 100, 2) AS PTE,
            ROUND(AVG(i.I_TR) * 100, 2) AS I_TR,
            COUNT(*) AS total_registros,
            ROUND(SUM(i.T_O_min) / 60.0, 2) AS horas_operativas,
            ROUND(SUM(i.T_DO_min) / 60.0, 2) AS horas_planificadas,
            ROUND(SUM(i.Q), 2) AS produccion_total
        FROM v_mma_indicadores_tpm i
        WHERE i.fecha BETWEEN @p_fecha_desde AND @p_fecha_hasta
            AND (@p_turno IS NULL OR i.turno = @p_turno)
            AND (@p_proceso_id IS NULL OR i.proceso_id = @p_proceso_id)
            AND (@p_tractor_id IS NULL OR i.tractor_id_erp = @p_tractor_id)
        GROUP BY i.fecha
        ORDER BY i.fecha;

        SELECT 
            fecha AS Dia, GU, D_PR AS [D.PR], D_MA AS [D.MA], D, R, C, EGE AS OEE, PTE, I_TR AS [I.TR],
            total_registros AS Registros, horas_operativas AS [Horas Op.], horas_planificadas AS [Horas Plan.],
            produccion_total AS Produccion
        FROM #resultados
        ORDER BY fecha;

        DROP TABLE #resultados;
    END;
    GO

    -- =====================================================================
    -- 5. SP: KPI RESUMEN
    -- =====================================================================


    CREATE PROCEDURE CLI547_AGM_SP_MMA_TPM_KPI_RESUMEN
        @p_fecha_desde DATE,
        @p_fecha_hasta DATE,
        @p_turno VARCHAR(10) = NULL,
        @p_proceso_id INT = NULL,
        @p_cultivo_id INT = NULL,
        @p_tractor_id INT = NULL
    AS
    BEGIN
        SET NOCOUNT ON;
        DECLARE @v_kpis TABLE (metric_key VARCHAR(50) PRIMARY KEY, metric_value DECIMAL(10,2),
                            metric_label VARCHAR(100), color_semaphore VARCHAR(10));

        DECLARE @v_GU DECIMAL(10,2), @v_D_PR DECIMAL(10,2), @v_D_MA DECIMAL(10,2),
                @v_D DECIMAL(10,2), @v_R DECIMAL(10,2), @v_C DECIMAL(10,2),
                @v_EGE DECIMAL(10,2), @v_PTE DECIMAL(10,2), @v_I_TR DECIMAL(10,2);

        SELECT 
            @v_GU   = ROUND(AVG(GU) * 100, 2),
            @v_D_PR = ROUND(AVG(D_PR) * 100, 2),
            @v_D_MA = ROUND(AVG(D_MA) * 100, 2),
            @v_D    = ROUND(AVG(D) * 100, 2),
            @v_R    = ROUND(AVG(R) * 100, 2),
            @v_C    = 100.0,
            @v_EGE  = ROUND(AVG(EGE) * 100, 2),
            @v_PTE  = ROUND(AVG(PTE) * 100, 2),
            @v_I_TR = ROUND(AVG(I_TR) * 100, 2)
        FROM v_mma_indicadores_tpm
        WHERE fecha BETWEEN @p_fecha_desde AND @p_fecha_hasta
            AND (@p_turno IS NULL OR turno = @p_turno)
            AND (@p_proceso_id IS NULL OR proceso_id = @p_proceso_id)
            AND (@p_tractor_id IS NULL OR tractor_id_erp = @p_tractor_id);

        INSERT INTO @v_kpis VALUES 
            ('GU', @v_GU, 'Grado de Utilización', CASE WHEN @v_GU >= 90 THEN 'green' WHEN @v_GU >= 75 THEN 'yellow' ELSE 'red' END),
            ('D_PR', @v_D_PR, 'Disponibilidad por Producción', CASE WHEN @v_D_PR >= 85 THEN 'green' WHEN @v_D_PR >= 70 THEN 'yellow' ELSE 'red' END),
            ('D_MA', @v_D_MA, 'Disponibilidad por Mantenimiento', CASE WHEN @v_D_MA >= 90 THEN 'green' WHEN @v_D_MA >= 75 THEN 'yellow' ELSE 'red' END),
            ('D', @v_D, 'Disponibilidad Global', CASE WHEN @v_D >= 85 THEN 'green' WHEN @v_D >= 65 THEN 'yellow' ELSE 'red' END),
            ('R', @v_R, 'Rendimiento', CASE WHEN @v_R >= 90 THEN 'green' WHEN @v_R >= 75 THEN 'yellow' ELSE 'red' END),
            ('C', @v_C, 'Calidad', CASE WHEN @v_C >= 95 THEN 'green' WHEN @v_C >= 85 THEN 'yellow' ELSE 'red' END),
            ('OEE', @v_EGE, 'Efectividad Global del Equipo', CASE WHEN @v_EGE >= 85 THEN 'green' WHEN @v_EGE >= 60 THEN 'yellow' ELSE 'red' END),
            ('PTE', @v_PTE, 'Productividad Total del Equipo', CASE WHEN @v_PTE >= 70 THEN 'green' WHEN @v_PTE >= 50 THEN 'yellow' ELSE 'red' END),
            ('I_TR', @v_I_TR, 'Índice de Traslado', CASE WHEN @v_I_TR >= 90 THEN 'green' WHEN @v_I_TR >= 75 THEN 'yellow' ELSE 'red' END);

        SELECT metric_key, metric_value, metric_label, color_semaphore
        FROM @v_kpis
        ORDER BY CASE metric_key 
            WHEN 'GU' THEN 1 WHEN 'D_PR' THEN 2 WHEN 'D_MA' THEN 3 WHEN 'D' THEN 4
            WHEN 'R' THEN 5 WHEN 'C' THEN 6 WHEN 'OEE' THEN 7 WHEN 'PTE' THEN 8 WHEN 'I_TR' THEN 9
        END;
    END;
    GO

    -- =====================================================================
    -- 6. SP: TIEMPOS PRODUCTIVOS
    -- =====================================================================

    CREATE OR ALTER PROCEDURE CLI547_AGM_SP_MMA_TPM_TIEMPOS_PRODUCTIVOS
        @p_fecha_desde DATE,
        @p_fecha_hasta DATE,
        @p_turno VARCHAR(10) = NULL,
        @p_proceso_id INT = NULL,
        @p_cultivo_id INT = NULL,
        @p_tractor_id INT = NULL
    AS
    BEGIN
        SET NOCOUNT ON;
        WITH tiempos_agregados AS (
            SELECT 
                SUM(i.T_TC_min) AS T_TC_min,
                SUM(i.T_PP_min) AS T_PP_min,
                SUM(i.T_NU_min) AS T_NU_min,
                SUM(i.T_DO_min) AS T_DO_min,
                SUM(i.T_TR_min) AS T_TR_min,
                SUM(i.T_PE_min) AS T_PE_min,
                SUM(i.T_PI_min) AS T_PI_min,
                SUM(i.T_O_min) AS T_O_min,
                SUM(i.T_T_min) AS T_T_min,
                SUM(i.T_TPNP_min) AS T_TPNP_min,
                SUM(i.T_TPP_min) AS T_TPP_min,
                SUM(i.Q) AS Q_total,
                AVG(i.capacidad_nominal) AS C_N_prom,
                CASE WHEN AVG(i.capacidad_nominal) > 0 THEN (SUM(i.Q) / AVG(i.capacidad_nominal)) * 60 ELSE 0 END AS T_NO_min,
                CASE WHEN AVG(i.capacidad_nominal) > 0 THEN SUM(i.T_O_min) - ((SUM(i.Q) / AVG(i.capacidad_nominal)) * 60) ELSE SUM(i.T_O_min) END AS T_MVO_min,
                CASE WHEN AVG(i.capacidad_nominal) > 0 THEN (SUM(i.Q) / AVG(i.capacidad_nominal)) * 60 ELSE 0 END AS T_EP_min,
                -- Cálculo de T_U y T_TPP (aunque ya existen, los mostramos)
                SUM(i.T_TC_min) - SUM(i.T_NU_min) AS T_U_min,
                SUM(i.T_PP_min) + SUM(i.T_NU_min) AS T_TPP_min_2
            FROM v_mma_indicadores_tpm i
            WHERE i.fecha BETWEEN @p_fecha_desde AND @p_fecha_hasta
                AND (@p_turno IS NULL OR i.turno = @p_turno)
                AND (@p_proceso_id IS NULL OR i.proceso_id = @p_proceso_id)
                AND (@p_tractor_id IS NULL OR i.tractor_id_erp = @p_tractor_id)
        )
        SELECT 
            'T_TC' AS codigo, 'Tiempo Total Calendario' AS descripcion, ROUND(T_TC_min / 60.0, 2) AS horas, T_TC_min AS minutos
        FROM tiempos_agregados
        UNION ALL SELECT 'T_U', 'Tiempo de Uso', ROUND(T_U_min / 60.0, 2), T_U_min FROM tiempos_agregados
        UNION ALL SELECT 'T_NU', 'Tiempo de No Uso', ROUND(T_NU_min / 60.0, 2), T_NU_min FROM tiempos_agregados
        UNION ALL SELECT 'T_PP', 'Tiempo de Paradas Programadas', ROUND(T_PP_min / 60.0, 2), T_PP_min FROM tiempos_agregados
        UNION ALL SELECT 'T_TPP', 'Tiempo Total Paradas Programadas', ROUND(T_TPP_min / 60.0, 2), T_TPP_min FROM tiempos_agregados
        UNION ALL SELECT 'T_DO', 'Tiempo Disponible para Operar', ROUND(T_DO_min / 60.0, 2), T_DO_min FROM tiempos_agregados
        UNION ALL SELECT 'T_PE', 'Tiempo de Paradas Externas', ROUND(T_PE_min / 60.0, 2), T_PE_min FROM tiempos_agregados
        UNION ALL SELECT 'T_PI', 'Tiempo de Paradas Internas', ROUND(T_PI_min / 60.0, 2), T_PI_min FROM tiempos_agregados
        UNION ALL SELECT 'T_TPNP', 'Tiempo Total Paradas No Programadas', ROUND(T_TPNP_min / 60.0, 2), T_TPNP_min FROM tiempos_agregados
        UNION ALL SELECT 'T_T', 'Tiempo de Trabajo', ROUND(T_T_min / 60.0, 2), T_T_min FROM tiempos_agregados
        UNION ALL SELECT 'T_O', 'Tiempo de Operación', ROUND(T_O_min / 60.0, 2), T_O_min FROM tiempos_agregados
        UNION ALL SELECT 'T_TR', 'Tiempo de Traslado', ROUND(T_TR_min / 60.0, 2), T_TR_min FROM tiempos_agregados
        UNION ALL SELECT 'T_MVO', 'Tiempo por Menor Velocidad', ROUND(T_MVO_min / 60.0, 2), T_MVO_min FROM tiempos_agregados
        UNION ALL SELECT 'T_NO', 'Tiempo Neto de Operación', ROUND(T_NO_min / 60.0, 2), T_NO_min FROM tiempos_agregados
        UNION ALL SELECT 'T_EP', 'Tiempo Efectivo de Producción', ROUND(T_EP_min / 60.0, 2), T_EP_min FROM tiempos_agregados
        UNION ALL SELECT 'T_R', 'Tiempo para Retrabajos', 0.0, 0 FROM tiempos_agregados
        UNION ALL SELECT 'Q', 'Cantidad Producida', ROUND(Q_total, 2), Q_total FROM tiempos_agregados
        UNION ALL SELECT 'C_N', 'Capacidad Nominal Promedio', ROUND(C_N_prom, 2), C_N_prom FROM tiempos_agregados;
    END;
    GO

    -- =====================================================================
    -- 7. SP: PARETO DE FALLAS
    -- =====================================================================


    CREATE PROCEDURE CLI547_AGM_SP_MMA_TPM_PARETO_FALLAS
        @p_fecha_desde DATE,
        @p_fecha_hasta DATE,
        @p_turno VARCHAR(10) = NULL,
        @p_proceso_id INT = NULL,
        @p_cultivo_id INT = NULL,
        @p_tractor_id INT = NULL,
        @p_top INT = 10
    AS
    BEGIN
        SET NOCOUNT ON;
        CREATE TABLE #fallas (tipo_paro_id INT, tipo_paro_codigo VARCHAR(30), tipo_paro_nombre VARCHAR(100),
                            total_ocurrencias INT, total_duracion_minutos DECIMAL(12,2), porcentaje_acumulado DECIMAL(5,2));

        INSERT INTO #fallas
        SELECT 
            tp.id, tp.codigo, tp.nombre,
            COUNT(*) AS ocurrencias,
            SUM(ISNULL(pe.duracion_min, 0)) AS duracion_minutos
        FROM CLI547_AGM_MMA_REGISTROS_DIARIOS r
        INNER JOIN CLI547_AGM_MMA_PAROS_EQUIPOS pe ON pe.registro_id = r.id
        INNER JOIN CLI547_AGM_MMA_TIPOS_PARO tp ON tp.id = pe.tipo_paro_id
        WHERE r.fecha BETWEEN @p_fecha_desde AND @p_fecha_hasta
            AND r.estado IN ('completado', 'aprobado')
            AND tp.codigo IN ('FALLA_MECANICA','FALLA_ELECTRICA','NEUMATICO','MECANICO','FALTA_OPERADOR','MANTENIMIENTO_CORRECTIVO')
            AND (@p_turno IS NULL OR r.turno = @p_turno)
            AND (@p_proceso_id IS NULL OR r.proceso_id = @p_proceso_id)
            AND (@p_tractor_id IS NULL OR r.tractor_id_erp = @p_tractor_id)
        GROUP BY tp.id, tp.codigo, tp.nombre
        ORDER BY duracion_minutos DESC;

        DECLARE @v_total DECIMAL(12,2), @v_acum DECIMAL(12,2) = 0;
        SELECT @v_total = SUM(total_duracion_minutos) FROM #fallas;

        UPDATE #fallas
        SET @v_acum = @v_acum + total_duracion_minutos,
            porcentaje_acumulado = CASE WHEN @v_total > 0 THEN (@v_acum / @v_total) * 100 ELSE 0 END;

        SELECT TOP (@p_top)
            tipo_paro_codigo AS codigo,
            tipo_paro_nombre AS tipo_falla,
            total_ocurrencias AS ocurrencias,
            ROUND(total_duracion_minutos / 60.0, 2) AS horas_perdidas,
            ROUND(porcentaje_acumulado, 1) AS porcentaje_acumulado,
            CASE WHEN porcentaje_acumulado <= 80 THEN 'Critical' WHEN porcentaje_acumulado <= 95 THEN 'Important' ELSE 'Minor' END AS prioridad
        FROM #fallas
        WHERE total_duracion_minutos > 0
        ORDER BY total_duracion_minutos DESC;

        DROP TABLE #fallas;
    END;
    GO

    -- =====================================================================
    -- 8. SP: RANKING DE MÁQUINAS (corregido, con ORDER BY fijo)
    -- =====================================================================
    -- =====================================================================
    -- CORRECCIÓN DEFINITIVA DEL SP DE RANKING DE MÁQUINAS
    -- =====================================================================


    CREATE PROCEDURE CLI547_AGM_SP_MMA_TPM_RANKING_MAQUINAS
        @p_fecha_desde DATE,
        @p_fecha_hasta DATE,
        @p_turno VARCHAR(10) = NULL,
        @p_proceso_id INT = NULL,
        @p_cultivo_id INT = NULL,
        @p_top INT = 10,
        @p_order VARCHAR(10) = 'DESC',
        @p_tractor_id_erp INT = NULL     -- <--- parámetro agregado
    AS
    BEGIN
        SET NOCOUNT ON;
        select * from CLI547_AGM_MMA_TIPOS_PARO
        -- Tabla temporal para resultados
        CREATE TABLE #ranking_maquinas (
            tractor_id_erp INT,
            tractor_codigo VARCHAR(100),
            total_registros INT,
            GU_prom DECIMAL(10,2),
            D_prom DECIMAL(10,2),
            R_prom DECIMAL(10,2),
            EGE_prom DECIMAL(10,2),
            PTE_prom DECIMAL(10,2),
            I_TR_prom DECIMAL(10,2),
            total_horas_operativas DECIMAL(12,2),
            total_horas_fallas DECIMAL(12,2),
            total_horas_paro_prod DECIMAL(12,2)
        );

        -- Insertar datos agregados por máquina
        INSERT INTO #ranking_maquinas
        SELECT 
            i.tractor_id_erp,
            MAX(r.codigo_tractor_snapshot) AS tractor_codigo,
            COUNT(*) AS total_registros,
            ROUND(AVG(i.GU) * 100, 2) AS GU_prom,
            ROUND(AVG(i.D) * 100, 2) AS D_prom,
            ROUND(AVG(i.R) * 100, 2) AS R_prom,
            ROUND(AVG(i.EGE) * 100, 2) AS EGE_prom,
            ROUND(AVG(i.PTE) * 100, 2) AS PTE_prom,
            ROUND(AVG(i.I_TR) * 100, 2) AS I_TR_prom,
            ROUND(SUM(i.T_O_min) / 60.0, 2) AS total_horas_operativas,
            ROUND(SUM(i.T_PI_min) / 60.0, 2) AS total_horas_fallas,
            ROUND(SUM(i.T_PE_min) / 60.0, 2) AS total_horas_paro_prod
        FROM v_mma_indicadores_tpm i   -- Asegúrate de que la vista existe con este nombre
        INNER JOIN CLI547_AGM_MMA_REGISTROS_DIARIOS r ON r.id = i.registro_id
        WHERE i.fecha BETWEEN @p_fecha_desde AND @p_fecha_hasta
            AND (@p_turno IS NULL OR i.turno = @p_turno)
            AND (@p_proceso_id IS NULL OR i.proceso_id = @p_proceso_id)
            AND (@p_tractor_id_erp IS NULL OR i.tractor_id_erp = @p_tractor_id_erp)   -- <--- aquí se usa el nuevo parámetro
        GROUP BY i.tractor_id_erp
        HAVING COUNT(*) > 0;

        -- Seleccionar resultados
        SELECT TOP (@p_top)
            tractor_codigo AS maquina,
            total_registros,
            total_horas_operativas AS [Horas Op.],
            total_horas_fallas AS [Horas Fallas],
            total_horas_paro_prod AS [Horas Paro Prod.],
            GU_prom AS GU,
            D_prom AS D,
            R_prom AS R,
            EGE_prom AS OEE,
            PTE_prom AS PTE,
            I_TR_prom AS [I.TR],
            CASE 
                WHEN EGE_prom >= 85 THEN '🌟 Excelente'
                WHEN EGE_prom >= 60 THEN '✅ Bueno'
                WHEN EGE_prom >= 40 THEN '⚠️ Regular'
                ELSE '🔴 Crítico'
            END AS desempeno
        FROM #ranking_maquinas
        WHERE EGE_prom > 0
        ORDER BY 
            CASE WHEN @p_order = 'DESC' THEN EGE_prom END DESC,
            CASE WHEN @p_order = 'ASC' THEN EGE_prom END ASC;

        DROP TABLE #ranking_maquinas;
    END;


    PRINT '✅ SP_MMA_TPM_RANKING_MAQUINAS recreado con el parámetro @p_tractor_id_erp.';
    -- =====================================================================
    -- 9. SP: MÉTRICAS RESUMEN
    -- =====================================================================


    CREATE PROCEDURE CLI547_AGM_SP_MMA_TPM_METRICAS_RESUMEN
        @p_fecha_desde DATE,
        @p_fecha_hasta DATE,
        @p_turno VARCHAR(10) = NULL,
        @p_proceso_id INT = NULL,
        @p_cultivo_id INT = NULL,
        @p_tractor_id INT = NULL
    AS
    BEGIN
        SET NOCOUNT ON;
        DECLARE @v_fallas INT, @v_dias INT, @v_maquinas INT;

        SELECT @v_fallas = COUNT(*)
        FROM CLI547_AGM_MMA_REGISTROS_DIARIOS r
        INNER JOIN CLI547_AGM_MMA_PAROS_EQUIPOS pe ON pe.registro_id = r.id
        INNER JOIN CLI547_AGM_MMA_TIPOS_PARO tp ON tp.id = pe.tipo_paro_id
        WHERE r.fecha BETWEEN @p_fecha_desde AND @p_fecha_hasta
            AND r.estado IN ('completado', 'aprobado')
            AND tp.codigo IN ('FALLA_MECANICA','FALLA_ELECTRICA','NEUMATICO','MECANICO','MANTENIMIENTO_CORRECTIVO')
            AND (@p_turno IS NULL OR r.turno = @p_turno)
            AND (@p_proceso_id IS NULL OR r.proceso_id = @p_proceso_id)
            AND (@p_tractor_id IS NULL OR r.tractor_id_erp = @p_tractor_id);

        SELECT @v_dias = COUNT(DISTINCT r.fecha)
        FROM CLI547_AGM_MMA_REGISTROS_DIARIOS r
        WHERE r.fecha BETWEEN @p_fecha_desde AND @p_fecha_hasta
            AND r.estado IN ('completado', 'aprobado')
            AND (@p_turno IS NULL OR r.turno = @p_turno)
            AND (@p_proceso_id IS NULL OR r.proceso_id = @p_proceso_id)
            AND (@p_tractor_id IS NULL OR r.tractor_id_erp = @p_tractor_id);

        SELECT @v_maquinas = COUNT(DISTINCT r.tractor_id_erp)
        FROM CLI547_AGM_MMA_REGISTROS_DIARIOS r
        WHERE r.fecha BETWEEN @p_fecha_desde AND @p_fecha_hasta
            AND r.estado IN ('completado', 'aprobado')
            AND (@p_turno IS NULL OR r.turno = @p_turno)
            AND (@p_proceso_id IS NULL OR r.proceso_id = @p_proceso_id)
            AND (@p_tractor_id IS NULL OR r.tractor_id_erp = @p_tractor_id);

        SELECT 'N° Fallas' AS metrica, @v_fallas AS valor, 'eventos' AS unidad
        UNION ALL SELECT 'Días Proceso', @v_dias, 'días'
        UNION ALL SELECT '# Máquinas', @v_maquinas, 'máquinas';
    END;
    GO

    PRINT '✅ Todos los objetos TPM fueron corregidos y creados exitosamente.';


-- =============================================================================
-- SP DE CONSULTA GPS  ·  CLI547_AGMSP_MMA_RUTA_GPS_MAQUINARIA
-- =============================================================================
-- Propósito : Devolver la ruta GPS de las jornadas de maquinaria para
--             visualización en mapa satelital (Google Maps, Leaflet, Mapbox…).
-- Audiencia : Administrador / dashboard de supervisión.
--
-- Filtros disponibles
--   @p_fecha_desde      Inicio del rango de fechas (obligatorio si no se da
--                       @p_registro_id).
--   @p_fecha_hasta      Fin del rango; si omites, se iguala a @p_fecha_desde.
--   @p_operador_id_erp  Filtra por operador (INT ERP).  NULL = todos.
--   @p_tractor_id_erp   Filtra por tractor (INT ERP).   NULL = todos.
--   @p_registro_id      Modo detalle: un registro exacto (GUID).
--                       Cuando se usa, se ignoran los filtros de fecha/operador.
--   @p_top_puntos       Cap de seguridad sobre el total de puntos devueltos
--                       en el RS-2.  Default 10 000.
--
-- Result Sets devueltos
--   RS-1  1 fila por registro:
--           · Datos del registro (operador, tractor, proceso, cultivo…)
--           · Estadísticas GPS (total_puntos, distancia_ruta_km, velocidades)
--           · Bounding-box + centroide para centrar el mapa automáticamente
--   RS-2  N filas — puntos GPS detallados (registro_id, secuencia, lat, lng…)
--           + columna "estado_velocidad" para color-coding de la polilínea.
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.CLI547_AGMSP_MMA_RUTA_GPS_MAQUINARIA
    @p_fecha_desde      DATE             = NULL,
    @p_fecha_hasta      DATE             = NULL,
    @p_operador_id_erp  INT              = NULL,
    @p_tractor_id_erp   INT              = NULL,
    @p_registro_id      UNIQUEIDENTIFIER = NULL,
    @p_top_puntos       INT              = 10000
AS
BEGIN
    SET NOCOUNT ON;

    -- ── Validaciones de entrada ────────────────────────────────────────────
    IF @p_registro_id IS NULL AND @p_fecha_desde IS NULL
        THROW 50010, 'Proporcione @p_fecha_desde o @p_registro_id.', 1;

    IF @p_top_puntos IS NULL OR @p_top_puntos <= 0
        SET @p_top_puntos = 10000;

    -- Si no se da fecha_hasta se asume el mismo día que fecha_desde
    IF @p_fecha_hasta IS NULL
        SET @p_fecha_hasta = @p_fecha_desde;

    IF @p_fecha_desde IS NOT NULL AND @p_fecha_desde > @p_fecha_hasta
        THROW 50011, '@p_fecha_desde no puede ser posterior a @p_fecha_hasta.', 1;

    -- ── CTE: distancia real de la ruta con Haversine (T-SQL puro) ───────────
    -- Error < 0.5 % para distancias < 500 km — suficiente para maquinaria
    -- agrícola que opera dentro de una misma finca o cuenca.
    ;WITH RegistrosFiltrados AS (
        -- Solo registros que tienen al menos 1 punto GPS y pasan los filtros
        SELECT r.id AS registro_id
        FROM dbo.CLI547_AGM_MMA_REGISTROS_DIARIOS r
        INNER JOIN dbo.CLI547_AGM_Punto_gps_maquinaria gx ON gx.registro_id = r.id
        WHERE
              (@p_registro_id     IS NULL OR r.id              = @p_registro_id)
          AND (@p_fecha_desde     IS NULL OR r.fecha           >= @p_fecha_desde)
          AND (@p_fecha_hasta     IS NULL OR r.fecha           <= @p_fecha_hasta)
          AND (@p_operador_id_erp IS NULL OR r.operador_id_erp = @p_operador_id_erp)
          AND (@p_tractor_id_erp  IS NULL OR r.tractor_id_erp  = @p_tractor_id_erp)
        GROUP BY r.id
    ),
    PuntosConLag AS (
        -- Une cada punto con el anterior para calcular el segmento entre ambos
        SELECT
            g.registro_id,
            g.latitud,
            g.longitud,
            g.secuencia,
            g.velocidad_ms,
            LAG(g.latitud)  OVER (PARTITION BY g.registro_id ORDER BY g.secuencia) AS lat_prev,
            LAG(g.longitud) OVER (PARTITION BY g.registro_id ORDER BY g.secuencia) AS lng_prev
        FROM dbo.CLI547_AGM_Punto_gps_maquinaria g
        INNER JOIN RegistrosFiltrados rf ON rf.registro_id = g.registro_id
    ),
    Segmentos AS (
        SELECT
            registro_id,
            velocidad_ms,
            CASE
                WHEN lat_prev IS NULL THEN 0.0
                ELSE 6371.0 * 2.0 * ATN2(
                    SQRT(
                        POWER(SIN(RADIANS((latitud  - lat_prev) / 2.0)), 2) +
                        COS(RADIANS(lat_prev)) * COS(RADIANS(latitud)) *
                        POWER(SIN(RADIANS((longitud - lng_prev) / 2.0)), 2)
                    ),
                    SQRT(1.0 - (
                        POWER(SIN(RADIANS((latitud  - lat_prev) / 2.0)), 2) +
                        COS(RADIANS(lat_prev)) * COS(RADIANS(latitud)) *
                        POWER(SIN(RADIANS((longitud - lng_prev) / 2.0)), 2)
                    ))
                )
            END AS segmento_km
        FROM PuntosConLag
    ),
    StatsGps AS (
        SELECT
            g.registro_id,
            COUNT(*)                                               AS total_puntos,
            MIN(g.captured_at)                                     AS primera_captura,
            MAX(g.captured_at)                                     AS ultima_captura,
            MIN(g.latitud)                                         AS lat_min,
            MAX(g.latitud)                                         AS lat_max,
            MIN(g.longitud)                                        AS lng_min,
            MAX(g.longitud)                                        AS lng_max,
            ROUND(AVG(CAST(s.velocidad_ms AS FLOAT)) * 3.6, 1)    AS velocidad_prom_kmh,
            ROUND(MAX(CAST(s.velocidad_ms AS FLOAT)) * 3.6, 1)    AS velocidad_max_kmh,
            ROUND(SUM(s.segmento_km), 3)                           AS distancia_ruta_km,
            SUM(CASE WHEN s.velocidad_ms > 0 THEN 1 ELSE 0 END)   AS puntos_en_movimiento,
            SUM(CASE WHEN ISNULL(s.velocidad_ms,0) = 0 THEN 1 ELSE 0 END) AS puntos_detenido
        FROM dbo.CLI547_AGM_Punto_gps_maquinaria g
        INNER JOIN Segmentos s ON s.registro_id = g.registro_id
        GROUP BY g.registro_id
    )

    -- ══════════════════════════════════════════════════════════════════════
    -- RS-1: 1 fila por registro (resumen para sidebar/listado del mapa)
    --   · Horas de jornada → CLI547_AGM_MMA_TIEMPOS_TURNO  (LEFT JOIN)
    --   · Nombre del proceso → CLI547_AGM_MMA_PROCESOS      (LEFT JOIN)
    -- ══════════════════════════════════════════════════════════════════════
    SELECT
        -- Identificación
        r.id                                       AS registro_id,
        r.numero_registro,
        r.fecha,
        r.turno,
        r.estado,
        r.tipo_registro,

        -- Operador / supervisor
        r.operador_id_erp,
        r.nombre_operador_snapshot                 AS operador,
        r.supervisor_id_erp,
        r.nombre_supervisor_snapshot               AS supervisor,

        -- Maquinaria
        r.tractor_id_erp,
        r.codigo_tractor_snapshot                  AS tractor,
        r.implemento_id_erp,
        r.codigo_implemento_snapshot               AS implemento,

        -- Proceso / cultivo
        r.proceso_id,
        COALESCE(p.nombre, r.proceso_vehiculo)     AS proceso,
        r.cultivo_id_erp,
        r.nombre_cultivo_snapshot                  AS cultivo,
        r.subproceso_nombre                        AS subproceso,

        -- Horario de jornada (columnas de CLI547_AGM_MMA_TIEMPOS_TURNO)
        tt.hora_salida_taller,
        tt.hora_llegada_punto,
        tt.hora_salida_punto,
        tt.hora_llegada_taller,
        tt.hora_refrigerio,
        tt.minutos_efectivos,

        -- Estadísticas GPS
        sg.total_puntos,
        sg.primera_captura                         AS gps_inicio_utc,
        sg.ultima_captura                          AS gps_fin_utc,
        DATEDIFF(MINUTE, sg.primera_captura, sg.ultima_captura)
                                                   AS duracion_rastreo_min,
        sg.distancia_ruta_km,
        sg.velocidad_prom_kmh,
        sg.velocidad_max_kmh,
        sg.puntos_en_movimiento,
        sg.puntos_detenido,
        CASE WHEN sg.total_puntos > 0
             THEN ROUND(100.0 * sg.puntos_en_movimiento / sg.total_puntos, 1)
             ELSE 0
        END                                        AS pct_tiempo_en_movimiento,

        -- Bounding-box para centrar el mapa automáticamente
        sg.lat_min,
        sg.lat_max,
        sg.lng_min,
        sg.lng_max,
        ROUND((sg.lat_min + sg.lat_max) / 2.0, 6) AS lat_centro,
        ROUND((sg.lng_min + sg.lng_max) / 2.0, 6) AS lng_centro,
        -- Zoom sugerido (Google Maps / Leaflet)
        CASE
            WHEN (sg.lat_max - sg.lat_min) < 0.005 THEN 16   -- < ~500 m
            WHEN (sg.lat_max - sg.lat_min) < 0.02  THEN 14   -- < ~2 km
            WHEN (sg.lat_max - sg.lat_min) < 0.1   THEN 12   -- < ~10 km
            ELSE 10
        END                                        AS zoom_sugerido

    FROM dbo.CLI547_AGM_MMA_REGISTROS_DIARIOS r
    INNER JOIN StatsGps sg
           ON sg.registro_id = r.id
    LEFT  JOIN dbo.CLI547_AGM_MMA_TIEMPOS_TURNO tt
           ON tt.registro_id = r.id
    LEFT  JOIN dbo.CLI547_AGM_MMA_PROCESOS p
           ON p.id = r.proceso_id
    ORDER BY r.fecha DESC, r.turno;

    -- ══════════════════════════════════════════════════════════════════════
    -- RS-2: Puntos GPS detallados para dibujar la polilínea en el mapa
    -- ══════════════════════════════════════════════════════════════════════
    SELECT TOP (@p_top_puntos)
        g.registro_id,
        g.secuencia,
        ROUND(g.latitud,  7)               AS latitud,
        ROUND(g.longitud, 7)               AS longitud,
        g.precision_m,
        g.altitud_m,
        ROUND(g.velocidad_ms * 3.6, 1)    AS velocidad_kmh,
        g.captured_at                      AS timestamp_utc,
        -- Color-coding de la polilínea:
        --   detenido → rojo | lento → naranja | moderado → amarillo
        --   normal   → verde | rapido → azul  | sin_dato → gris
        CASE
            WHEN g.velocidad_ms IS NULL        THEN 'sin_dato'
            WHEN g.velocidad_ms = 0            THEN 'detenido'
            WHEN g.velocidad_ms * 3.6 <  5.0  THEN 'lento'
            WHEN g.velocidad_ms * 3.6 < 15.0  THEN 'moderado'
            WHEN g.velocidad_ms * 3.6 < 25.0  THEN 'normal'
            ELSE                                    'rapido'
        END                                AS estado_velocidad

    FROM dbo.CLI547_AGM_Punto_gps_maquinaria g
    INNER JOIN dbo.CLI547_AGM_MMA_REGISTROS_DIARIOS r ON r.id = g.registro_id
    WHERE
          (@p_registro_id     IS NULL OR r.id              = @p_registro_id)
      AND (@p_fecha_desde     IS NULL OR r.fecha           >= @p_fecha_desde)
      AND (@p_fecha_hasta     IS NULL OR r.fecha           <= @p_fecha_hasta)
      AND (@p_operador_id_erp IS NULL OR r.operador_id_erp = @p_operador_id_erp)
      AND (@p_tractor_id_erp  IS NULL OR r.tractor_id_erp  = @p_tractor_id_erp)
    ORDER BY g.registro_id, g.secuencia;
END;
GO

-- =============================================================================
-- Ejemplos de uso de CLI547_AGMSP_MMA_RUTA_GPS_MAQUINARIA
-- (comentados — descomentar para probar)
-- =============================================================================

/*
-- 1. Todas las rutas del día de hoy
DECLARE @ok BIT;
EXEC dbo.CLI547_AGMSP_MMA_RUTA_GPS_MAQUINARIA
    @p_fecha_desde = '2026-08-25';

-- 2. Rutas de un operador específico en un rango de fechas
EXEC dbo.CLI547_AGMSP_MMA_RUTA_GPS_MAQUINARIA
    @p_fecha_desde     = '2026-08-01',
    @p_fecha_hasta     = '2026-08-31',
    @p_operador_id_erp = 42;

-- 3. Detalle de un registro exacto (modo mapa)
EXEC dbo.CLI547_AGMSP_MMA_RUTA_GPS_MAQUINARIA
    @p_registro_id = 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx';

-- 4. Rutas de un tractor específico hoy
EXEC dbo.CLI547_AGMSP_MMA_RUTA_GPS_MAQUINARIA
    @p_fecha_desde    = '2026-08-25',
    @p_tractor_id_erp = 7;
*/
















































