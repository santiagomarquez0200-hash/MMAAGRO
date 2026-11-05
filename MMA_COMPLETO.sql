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
    -- 2.24 Ruta GPS de trazabilidad de maquinaria — ver sql/Ruta_maquinaria_v3.sql
    -- y sql/Ruta_maquinaria_analytics.sql (tabla CLI547_AGM_Ruta_maquinaria, GEOGRAPHY).
    -- La tabla v2 CLI547_AGM_Punto_gps_maquinaria fue retirada de este script maestro.
    -- =============================================================================
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
        MERGE CLI547_AGM_MMA_HOROMETROS WITH (HOLDLOCK) AS target    
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
        MERGE CLI547_AGM_MMA_TIEMPOS_TURNO WITH (HOLDLOCK) AS target    
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
                MERGE INTO CLI547_AGM_MMA_REGISTROS_LOTES WITH (HOLDLOCK) AS target
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

    -- Categorías adicionales de inspección por prefijo de implemento.
    IF NOT EXISTS (SELECT 1 FROM dbo.CLI547_AGM_MMA_CHECKLIST_CATEGORIAS WHERE nombre = 'Inspeccionar azufradora')
        INSERT INTO dbo.CLI547_AGM_MMA_CHECKLIST_CATEGORIAS (nombre, orden) VALUES ('Inspeccionar azufradora', 30);
    IF NOT EXISTS (SELECT 1 FROM dbo.CLI547_AGM_MMA_CHECKLIST_CATEGORIAS WHERE nombre = 'Inspeccionar electroestática agrícola')
        INSERT INTO dbo.CLI547_AGM_MMA_CHECKLIST_CATEGORIAS (nombre, orden) VALUES ('Inspeccionar electroestática agrícola', 40);
    IF NOT EXISTS (SELECT 1 FROM dbo.CLI547_AGM_MMA_CHECKLIST_CATEGORIAS WHERE nombre = 'Inspeccionar picadora agrícola')
        INSERT INTO dbo.CLI547_AGM_MMA_CHECKLIST_CATEGORIAS (nombre, orden) VALUES ('Inspeccionar picadora agrícola', 50);
    IF NOT EXISTS (SELECT 1 FROM dbo.CLI547_AGM_MMA_CHECKLIST_CATEGORIAS WHERE nombre = 'Inspeccionar carreta viñatera')
        INSERT INTO dbo.CLI547_AGM_MMA_CHECKLIST_CATEGORIAS (nombre, orden) VALUES ('Inspeccionar carreta viñatera', 60);
    IF NOT EXISTS (SELECT 1 FROM dbo.CLI547_AGM_MMA_CHECKLIST_CATEGORIAS WHERE nombre = 'Inspeccionar carreta hidráulica')
        INSERT INTO dbo.CLI547_AGM_MMA_CHECKLIST_CATEGORIAS (nombre, orden) VALUES ('Inspeccionar carreta hidráulica', 70);
    IF NOT EXISTS (SELECT 1 FROM dbo.CLI547_AGM_MMA_CHECKLIST_CATEGORIAS WHERE nombre = 'Inspeccionar rotocultor')
        INSERT INTO dbo.CLI547_AGM_MMA_CHECKLIST_CATEGORIAS (nombre, orden) VALUES ('Inspeccionar rotocultor', 80);

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

    -- 12. SPs ADICIONALES: SESIÓN DISPOSITIVO Y LECTURA PORTERO
    -- =============================================================================

    -- 12.1 Actualizar status de jornada (UPSERT desde el APK)
    -- Recibe un JSON con la jornada del operador y hace un UPSERT.
    -- La clave única es usuario_erp_id + turno + fecha (NO el dispositivo):
    -- así el mismo operador puede cambiar de equipo sin duplicar la jornada.
    -- Ver migracion_status_jornada.sql, que hizo ese cambio de clave.
    -- Devuelve: success y mensaje.
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

-----------------------------------------
-----------------------------------------
--TPM Y REPORTERIA UNIFICADA 

CREATE   VIEW dbo.v_mma_tiempos_tpm  
AS  
WITH turnos AS (  
    SELECT  
        r.id                AS registro_id,  
        r.fecha,  
        r.turno,  
        r.proceso_id,  
        r.tractor_id_erp,  
        r.operador_id_erp,  
  
        -- ✅ [FIX-7 RESUELTO] Constantes fijas del turno teórico — confirmadas con el área,  
        -- NO se obtienen de ninguna tabla. Único punto de edición si el turno cambia.  
        cfg.HoraInicioReal, cfg.HoraFinReal,  
        DATEDIFF(MINUTE, cfg.HoraInicioReal, cfg.HoraFinReal) AS T_TC_min,  
  
        -- ---- Refrigerio (parte 1 de T_PP) ----------------------------------------------------  
        -- hora_refrigerio viene de CLI547_AGM_MMA_TIEMPOS_TURNO en  
        -- formato "HH:MM - HH:MM" en una sola columna.  
        -- [BUG CORREGIDO] El SUBSTRING de la segunda hora usaba un largo fijo de 5 caracteres,  
        -- pero cuando el guion tiene espacio a los dos lados ("12:00 - 12:45"), el texto después  
        -- del guion es " 12:45" (6 caracteres) — al cortar solo 5 se perdía el último dígito  
        -- (" 12:4" -> 12:04 en vez de 12:45). Se reemplaza el largo fijo por LEN(...) para tomar  
        -- todo lo que queda, y LTRIM/RTRIM limpia el espacio sobrante.  
        CASE  
            WHEN tt.hora_refrigerio IS NOT NULL AND CHARINDEX('-', tt.hora_refrigerio) > 0  
            THEN DATEDIFF(  
                    MINUTE,  
                    CAST(LTRIM(RTRIM(SUBSTRING(tt.hora_refrigerio, 1, CHARINDEX('-', tt.hora_refrigerio) - 1))) AS TIME),  
                    CAST(LTRIM(RTRIM(SUBSTRING(tt.hora_refrigerio, CHARINDEX('-', tt.hora_refrigerio) + 1, LEN(tt.hora_refrigerio)))) AS TIME)  
                 )  
            ELSE 45  
        END AS T_PP_refrigerio_raw,  
  
        -- ---- [FIX-4 / Ecuación 2.3] Paradas programadas por eventos — separadas en INTERNAS  
        -- al plan de producción (i) y EXTERNAS al plan (e), tal como pide la ecuación 2.3 de la  
        -- guía (T_PP = ΣT_PPi(i) + ΣT_PPi(e)). [ACTUALIZADO 29-ago-2026, confirmado con el Excel  
        -- real del área] CALIBRACION se mueve aquí (interna) — su fórmula real de TPP es  
        -- ALI(refrigerio)+CLI(clima)+CAP(capacitación)+CAL(calibración)+VESTUARIO.  
        -- AJUSTAR AQUÍ: agregar 'MANT_PREV' y 'REUNION_SEG' (interna) cuando se confirmen.  
        ISNULL((  
            SELECT SUM(pe.duracion_min)  
            FROM dbo.CLI547_AGM_MMA_PAROS_EQUIPOS pe  
            INNER JOIN dbo.CLI547_AGM_MMA_TIPOS_PARO tp ON tp.id = pe.tipo_paro_id  
            WHERE pe.registro_id = r.id  
              AND tp.codigo IN ('CAPACITACION', 'CALIBRACION' /* , 'MANT_PREV', 'REUNION_SEG' */)  
        ), 0) AS T_PP_interna_eventos_min,  
  
        ISNULL((  
            SELECT SUM(pe.duracion_min)  
            FROM dbo.CLI547_AGM_MMA_PAROS_EQUIPOS pe  
            INNER JOIN dbo.CLI547_AGM_MMA_TIPOS_PARO tp ON tp.id = pe.tipo_paro_id  
            WHERE pe.registro_id = r.id  
              AND tp.codigo IN ('CLIMA')  
        ), 0) AS T_PP_externa_eventos_min,  
  
        -- ---- [NUEVO] Cierre anticipado del turno (parte 3 de T_PP) ---------------------------  
        -- Diferencia entre la hora real de llegada del equipo al taller y la hora fija de fin  
        -- de turno (14:00), cuando el equipo regresó ANTES de esa hora.  
        CASE WHEN tt.hora_llegada_taller IS NOT NULL AND cfg.HoraFinReal > tt.hora_llegada_taller  
             THEN DATEDIFF(MINUTE, tt.hora_llegada_taller, cfg.HoraFinReal)  
             ELSE 0 END AS T_PP_cierre_raw,  
  
        -- ---- [NUEVO] T_DEM_SALIDA: demora entre la hora fija de inicio y la salida real ------  
        -- del taller. Según Anexo 1 de la guía, "tardanza de operador al salir de base" es un  
        -- evento de 1ª pérdida (T_PI).  
        CASE WHEN tt.hora_salida_taller IS NOT NULL AND tt.hora_salida_taller > cfg.HoraInicioReal  
             THEN DATEDIFF(MINUTE, cfg.HoraInicioReal, tt.hora_salida_taller)  
             ELSE 0 END AS T_DEM_SALIDA_raw,  
  
        -- [FIX-15] Documentado: dentro de un turno activo no aplica "tiempo de no uso".  
        0 AS T_NU_min,  
  
        -- ---- Traslados (T_TR) ------------------------------------------------------------------  
        ISNULL(DATEDIFF(MINUTE, tt.hora_salida_taller, tt.hora_llegada_punto), 0)  
      + ISNULL(DATEDIFF(MINUTE, tt.hora_salida_punto, tt.hora_llegada_taller), 0) AS T_TR_raw,  
  
        -- ---- [ACTUALIZADO 29-ago-2026] T_PE ya NO se mide de eventos — confirmado con el Excel  
        -- real del área: TPE es un RESIDUO (TDO - TT - TRASLADO), no una suma de eventos.  
        -- Se calcula más abajo (con_pe CTE). Aquí solo se deja, como diagnóstico aparte,  
        -- el tiempo real de eventos COMBUSTIBLE (CALIBRACION ya se movió a T_PP arriba) —  
        -- no se usa para el cálculo oficial de T_PE, solo para comparar.  
        ISNULL((  
            SELECT SUM(pe.duracion_min)  
            FROM dbo.CLI547_AGM_MMA_PAROS_EQUIPOS pe  
            INNER JOIN dbo.CLI547_AGM_MMA_TIPOS_PARO tp ON tp.id = pe.tipo_paro_id  
            WHERE pe.registro_id = r.id  
              AND tp.codigo IN ('COMBUSTIBLE')  
        ), 0) AS T_PE_combustible_directo_min,  
  
        -- ---- Paradas internas mecánicas (parte 1 de T_PI) — sin cambios ------------------------  
        ISNULL((  
            SELECT SUM(pe.duracion_min)  
            FROM dbo.CLI547_AGM_MMA_PAROS_EQUIPOS pe  
            INNER JOIN dbo.CLI547_AGM_MMA_TIPOS_PARO tp ON tp.id = pe.tipo_paro_id  
            WHERE pe.registro_id = r.id  
              AND tp.codigo IN ('MECANICO')  
        ), 0) AS T_PI_mecanico_raw,  
  
        -- ---- Tiempo de operación (T_O) — horómetro de implemento, con fallback a tractor -----  
        ISNULL(ISNULL(h.horas_implemento, h.horas_tractor) * 60, 0) AS T_O_min,  
  
        -- ---- Producción real (Q) ----------------------------------------------------------------  
        ISNULL((SELECT SUM(cantidad) FROM dbo.CLI547_AGM_MMA_COSECHA_BINES WHERE registro_id = r.id), 0) AS Q_bines,  
        ISNULL((SELECT SUM(area_trabajada_ha) FROM dbo.CLI547_AGM_MMA_REGISTROS_LOTES WHERE registro_id = r.id), 0) AS Q_ha,  
  
        -- ---- [FIX-8] Capacidad Nominal: ya NO se inventa un valor por defecto -----------------  
        p.rendimiento_teorico AS capacidad_nominal_raw,  
        CASE WHEN p.rendimiento_teorico IS NOT NULL AND p.rendimiento_teorico > 0 THEN 1 ELSE 0 END  
            AS capacidad_nominal_valida,  
  
        CASE WHEN p.codigo = 'COSEC' THEN 'bines' ELSE 'ha' END AS unidad_medida,  
        p.codigo AS proceso_codigo   -- [NUEVO] necesario para condicionar R por proceso (ver v_mma_indicadores_tpm)  
  
    FROM dbo.CLI547_AGM_MMA_REGISTROS_DIARIOS r  
    CROSS APPLY (SELECT CAST('06:00' AS TIME) AS HoraInicioReal, CAST('14:00' AS TIME) AS HoraFinReal) cfg  
    LEFT JOIN dbo.CLI547_AGM_MMA_HOROMETROS h      ON h.registro_id = r.id  
    LEFT JOIN dbo.CLI547_AGM_MMA_TIEMPOS_TURNO tt  ON tt.registro_id = r.id  
    LEFT JOIN dbo.CLI547_AGM_MMA_PROCESOS p        ON p.id = r.proceso_id  
    WHERE r.estado IN ('completado', 'aprobado')  
),  
limpios AS (  
    SELECT  
        registro_id, fecha, turno, proceso_id, tractor_id_erp, operador_id_erp,  
        T_TC_min,  
  
        -- Refrigerio limpio: expuesto aparte como diagnóstico (ver hallazgo 2026-08-28 abajo)  
        CASE WHEN T_PP_refrigerio_raw < 0 OR T_PP_refrigerio_raw > 120 THEN 45 ELSE T_PP_refrigerio_raw END  
            AS T_PP_refrigerio_min,  
  
        -- [Ecuación 2.3] T_PP_interna: eventos internos (capacitación) + cierre anticipado  
        -- (clasificado como interno: lo controla producción, no es un factor climático externo).  
        -- Es la que resta de T_DO per ecuación 2.4 LITERAL: T_DO=(T_F-T_I)-ΣT_PPi(i), solo "i".  
        -- [AJUSTADO — hallazgo 2026-08-28] SIN el refrigerio: validado con datos reales del  
        -- 17-ago-2026 (TRC08) que sumarlo rompía la reconciliación con el área (hipótesis: el  
        -- horómetro ya no corre durante el refrigerio, restarlo también de T_DO lo contaba dos  
        -- veces). El refrigerio se deja expuesto aparte como diagnóstico (T_PP_refrigerio_min).  
        (T_PP_interna_eventos_min  
         + CASE WHEN T_PP_cierre_raw > 240 THEN 240 ELSE T_PP_cierre_raw END  
        ) AS T_PP_interna_min,  
  
        -- [Ecuación 2.3] T_PP_externa: eventos externos al plan (factores climáticos). Per  
        -- ecuación 2.4 LITERAL, NO resta de T_DO (la guía solo resta la "i", no la "e") — se  
        -- expone para el total T_PP (ecuación 2.2) y como diagnóstico de clima.  
        T_PP_externa_eventos_min AS T_PP_externa_min,  
  
        T_NU_min,  
  
        -- Límite de razonabilidad de T_DEM_SALIDA (ver pendiente #3)  
        CASE WHEN T_DEM_SALIDA_raw > 240 THEN 240 ELSE T_DEM_SALIDA_raw END AS T_DEM_SALIDA_min,  
  
        -- Límite de razonabilidad de T_TR (ver pendiente #3)  
        CASE WHEN T_TR_raw < 0 THEN 0  
             WHEN T_TR_raw > 180 THEN 180  
             ELSE T_TR_raw END AS T_TR_min,  
  
        -- Diagnóstico de combustible (ya NO alimenta el T_PE oficial — ver con_pe más abajo)  
        T_PE_combustible_directo_min,  
  
        -- [NUEVO] T_PI = fallas mecánicas + demora en la salida (Anexo 1: ambas son 1ª pérdida)  
        T_PI_mecanico_raw AS T_PI_mecanico_min,  
  
        T_O_min, Q_bines, Q_ha,  
        capacidad_nominal_raw, capacidad_nominal_valida, unidad_medida, proceso_codigo   -- [NUEVO]  
    FROM turnos  
),  
con_do AS (  
    SELECT *,  
        -- [Ecuación 2.3] T_PP total = interna + externa  
        (T_PP_interna_min + T_PP_externa_min) AS T_PP_min,  
        -- [Ecuación 2.4, LITERAL] T_DO = (T_F-T_I) - ΣT_PPi(i) -> solo se resta la parte INTERNA  
        CASE WHEN (T_TC_min - T_PP_interna_min) < 0 THEN 0 ELSE T_TC_min - T_PP_interna_min END AS T_DO_min,  
        (T_PI_mecanico_min + T_DEM_SALIDA_min) AS T_PI_min   -- [NUEVO] T_PI total  
    FROM limpios  
),  
con_tt AS (  
    -- [ACTUALIZADO 29-ago-2026 — confirmado con el Excel real del área]  
    -- T_T = T_O + T_PI (ecuación 3.1.11 reordenada). NO es T_DO - T_PE como se tenía antes —  
    -- esa dirección estaba invertida: T_O y T_PI son los datos primarios (horómetro + eventos  
    -- reales), T_T se arma a partir de ellos, y T_PE sale como residuo (ver con_pe). Validado  
    -- exacto contra el Excel real (TT=T_O+T_PI+DEMORA_SALIDA, con T_PI aquí ya incluyendo  
    -- DEMORA_SALIDA) para el registro TRC08 2026-08-17: 240+62=302min=5.03h ✓.  
    SELECT *,  
        (T_O_min + T_PI_min) AS T_T_min  
    FROM con_do  
),  
con_pe AS (  
    -- [NUEVO 29-ago-2026] T_PE = T_DO - T_T - T_TR — RESIDUO, confirmado con el Excel real del  
    -- área (su celda TPE es literalmente "=TDO-(TT+TRASLADO)", no una suma de eventos de paro).  
    -- Por eso nunca se encontró en CLI547_AGM_MMA_PAROS_EQUIPOS: no sale de ahí.  
    -- Validado exacto: 399-302-37=60min=1.00h contra el TPE=1.00h real del área.  
    SELECT *,  
        CASE WHEN (T_DO_min - T_T_min - T_TR_min) < 0 THEN 0  
             ELSE T_DO_min - T_T_min - T_TR_min END AS T_PE_min,  
  
        -- [NUEVO] T.INTERNOS y T.ABASTECIMIENTO — factores FIJOS de negocio aplicados sobre el  
        -- residuo T_PE (confirmados con el Excel real: T.INTERNOS=TPE×0.6 siempre;  
        -- T.ABASTECIMIENTO=TPE×0.25 SOLO si el proceso es Aplicación). No son categorías medidas  
        -- — son una partición estimada/convencional del residuo, no eventos reales.  
        ROUND((CASE WHEN (T_DO_min - T_T_min - T_TR_min) < 0 THEN 0 ELSE T_DO_min - T_T_min - T_TR_min END) * 0.6, 2)  
            AS T_internos_estimado_min,  
        -- AJUSTAR AQUÍ: confirmar el código real de "Aplicación" en CLI547_AGM_MMA_PROCESOS  
        -- (se usa 'APLIC' como supuesto, igual que en el condicional de R).  
        CASE WHEN proceso_codigo = 'APLIC'  
             THEN ROUND((CASE WHEN (T_DO_min - T_T_min - T_TR_min) < 0 THEN 0 ELSE T_DO_min - T_T_min - T_TR_min END) * 0.25, 2)  
             ELSE 0 END AS T_abastecimiento_estimado_min  
    FROM con_tt  
)  
SELECT  
    registro_id, fecha, turno, proceso_id, tractor_id_erp, operador_id_erp,  
    T_TC_min, T_PP_min, T_PP_interna_min, T_PP_externa_min, T_PP_refrigerio_min,   -- [NUEVO] desglose ecuación 2.3  
    T_NU_min, T_DO_min, T_TR_min, T_PE_min,  
    T_PE_combustible_directo_min,                                                   -- [NUEVO] diagnóstico, ya no oficial  
    T_internos_estimado_min, T_abastecimiento_estimado_min,                         -- [NUEVO]  
    T_PI_min, T_PI_mecanico_min, T_DEM_SALIDA_min,   -- [NUEVO] se expone el detalle además del total  
    T_T_min,   -- [NUEVO] ya viene calculado (T_O+T_PI), no hace falta derivarlo de nuevo abajo  
    T_O_min,  
    Q_bines, Q_ha,  
    capacidad_nominal_raw AS capacidad_nominal,  
    capacidad_nominal_valida,  
    unidad_medida,  
    proceso_codigo,   -- [NUEVO] necesario para condicionar R por proceso en v_mma_indicadores_tpm  
  
    -- Derivados (ecuaciones 3.1.2, 2.2 de la guía) — T_T_min YA NO se deriva aquí, ver con_tt  
    T_PE_min + T_PI_min      AS T_TPNP_min,  
    T_PP_min + T_NU_min      AS T_TPP_min,  
    CASE WHEN unidad_medida = 'bines' THEN Q_bines ELSE Q_ha END AS Q  
FROM con_pe;  
GO
CREATE   VIEW dbo.v_mma_indicadores_tpm  
AS  
WITH lotes_agregados AS (  
    SELECT registro_id, MIN(finca_id_erp) AS lote_id, MIN(lote_id_erp) AS sublote_id  
    FROM dbo.CLI547_AGM_MMA_REGISTROS_LOTES  
    GROUP BY registro_id  
),  
base AS (  
    SELECT  
        v.*,  
        l.lote_id, l.sublote_id,  
  
        CASE WHEN v.T_TC_min > 0 THEN ROUND(CAST(v.T_DO_min AS FLOAT) / v.T_TC_min, 4) ELSE 0 END AS GU,  
        CASE WHEN v.T_DO_min > 0 THEN ROUND(CAST(v.T_T_min AS FLOAT) / v.T_DO_min, 4) ELSE 0 END AS D_PR,  
        CASE WHEN v.T_T_min > 0  THEN ROUND(CAST(v.T_O_min AS FLOAT) / v.T_T_min, 4) ELSE 0 END AS D_MA,  
        CASE WHEN v.T_DO_min > 0 THEN ROUND(CAST(v.T_O_min AS FLOAT) / v.T_DO_min, 4) ELSE 0 END AS D,  
  
        -- [Ecuación 3.1.8, LITERAL de la guía] T_PE = T_DO - (T_O + T_PI), SIN restar T_TR.  
        -- [ACTUALIZADO 29-ago-2026] Ya NO es el método "alternativo/no usado" — el T_PE_min  
        -- OFICIAL de v_mma_tiempos_tpm ahora SÍ es un residuo (confirmado con el Excel real del  
        -- área), pero resta T_TR además de T_O+T_PI. Este diagnóstico queda para comparar contra  
        -- la guía literal: T_PE_indirecto_min - T_PE_min = T_TR_min, siempre, por construcción.  
        (v.T_DO_min - (v.T_O_min + v.T_PI_min)) AS T_PE_indirecto_min,  
  
        -- [Ecuación 3.1.11] T_O = T_T - T_PI. [ACTUALIZADO 29-ago-2026] Ya NO es un método  
        -- alternativo: T_T_min en v_mma_tiempos_tpm AHORA SE CALCULA como T_O_min+T_PI_min (la  
        -- dirección real confirmada con el Excel del área), así que esta columna siempre da  
        -- exactamente T_O_min — queda como verificación de identidad, no como diagnóstico de un  
        -- método distinto.  
        (v.T_T_min - v.T_PI_min) AS T_O_derivado_min,  
  
        -- [ACTUALIZADO 29-ago-2026 — Opción A, aplicada a pedido] Se replica la fórmula real del  
        -- Excel del área, confirmada celda por celda:  
        --   DATA!AF (AVANCE REAL) = Q / CAPAC.NOM.        <- 1ª división entre capacidad_nominal  
        --   TPM!K   (TNO)         = AVANCE_REAL / CAPAC.NOM. <- 2ª división entre la MISMA capacidad  
        -- Combinando ambos pasos: R = Q / (T_O × capacidad_nominal²). NO es la ecuación 3.2.3  
        -- literal de la guía (que divide una sola vez) — es la convención real que usa el área,  
        -- replicada a propósito para que R/TNO/TMVO/TEP/OEE/PTE coincidan con su reporte.  
        -- Si en algún momento el área confirma que la doble división era un bug de su Excel y lo  
        -- corrigen, revertir aquí a "* v.capacidad_nominal" (una sola vez) — Opción B, ya discutida.  
        CASE WHEN v.capacidad_nominal_valida = 1 AND v.T_O_min > 0  
             THEN ROUND(CAST(v.Q AS FLOAT) / ((v.T_O_min / 60.0) * v.capacidad_nominal * v.capacidad_nominal), 4)  
             ELSE NULL END AS R_sin_topar,  
  
        -- [NUEVO — condicional por proceso, aplicado 29-ago-2026] Para 'Aplicaciones' se pidió  
        -- usar la ecuación 3.2.1 (R = T_NO/T_O) en vez de la 3.2.3 (R = Q/(T_O×C_N)).  
        -- ⚠️ AJUSTAR AQUÍ (2 cosas pendientes de confirmar):  
        --   1) El código real de "Aplicaciones" en CLI547_AGM_MMA_PROCESOS — se usa 'APLIC' como  
        --      supuesto (el formulario fuente lo llama "Aplicación"); confirmar con:  
        --      SELECT id, codigo, nombre FROM dbo.CLI547_AGM_MMA_PROCESOS;  
        --   2) La fuente de T_NO medido de forma INDEPENDIENTE para Aplicaciones (no derivado de  
        --      R). Hoy no se conoce ninguna — se deja NULL a propósito. Mientras sea NULL, el  
        --      CASE de más abajo cae automáticamente al método 3.2.3 (ningún número cambia hoy;  
        --      ver explicación en el chat). En cuanto exista la columna real, reemplazar el NULL  
        --      por la referencia a esa columna y el cambio se activa solo, sin tocar el resto.  
        CAST(NULL AS DECIMAL(10,2)) AS T_NO_independiente_min  
    FROM dbo.v_mma_tiempos_tpm v  
    LEFT JOIN lotes_agregados l ON l.registro_id = v.registro_id  
),  
con_r AS (  
    SELECT *,  
        -- [ACTUALIZADO 30-ago-2026 — FIX-2 REVERTIDO, confirmado con datos reales del día 20]  
        -- Antes se topaba R a 100% para evitar T_MVO negativo (T_MVO=T_O-T_NO). El registro  
        -- TRC08/2026-08-20 del Excel real del área tiene R=104.20% (SIN topar) y T_MVO=-0.15h  
        -- (negativo, aceptado tal cual en su sistema como "sobre-rendimiento" frente a la  
        -- capacidad nominal) — su EGE/OEE=66.79% solo cierra usando R sin topar (con tope daría  
        -- 64.09%, no coincide). Se quita el tope: R ya NO se acota a 1.0. T_MVO/T_NO pueden  
        -- reflejar sobre-rendimiento (T_NO>T_O, T_MVO<0) cuando corresponda — ya no se trata  
        -- como error, es el comportamiento real confirmado.  
        CASE  
            WHEN proceso_codigo = 'APLIC' AND T_NO_independiente_min IS NOT NULL AND T_O_min > 0  
                THEN ROUND(T_NO_independiente_min * 1.0 / T_O_min, 4)  
            ELSE R_sin_topar  
        END AS R  
    FROM base  
)  
SELECT  
    registro_id, fecha, turno, proceso_id, tractor_id_erp, operador_id_erp,  
    lote_id, sublote_id,  
    T_TC_min, T_PP_min, T_PP_interna_min, T_PP_externa_min,   -- [NUEVO] desglose ecuación 2.3  
    T_NU_min, T_DO_min, T_TR_min, T_PE_min, T_PE_indirecto_min,   -- [NUEVO] ecuación 3.1.8  
    T_PE_combustible_directo_min,                                 -- [NUEVO] diagnóstico, ya no oficial  
    T_internos_estimado_min, T_abastecimiento_estimado_min,       -- [NUEVO] estimados (factor fijo x T_PE)  
    T_PI_min, T_PI_mecanico_min, T_DEM_SALIDA_min,  
    T_O_min, T_O_derivado_min, T_T_min,   -- [NUEVO] ecuación 3.1.11  
    T_TPNP_min, T_TPP_min, Q, capacidad_nominal, capacidad_nominal_valida,  
  
    GU, D_PR, D_MA, D,  
    ROUND(D_PR * D_MA, 4) AS D_PR_x_D_MA,   -- [NUEVO] ecuación 3.1.4: debe coincidir con D  
    R_sin_topar,  
    R,  
  
    1.0 AS C,  
  
    CASE WHEN R IS NULL THEN NULL ELSE ROUND(T_O_min * R, 2) END AS T_NO_min,  
    CASE WHEN R IS NULL THEN NULL ELSE ROUND(T_O_min - (T_O_min * R), 2) END AS T_MVO_min,  
    CASE WHEN R IS NULL THEN NULL ELSE ROUND(T_O_min * R, 2) END AS T_EP_min,  
  
    -- [NUEVO] ecuación 3.2.1 (R=T_NO/T_O) y 3.3.1 (C=T_EP/T_NO), calculadas explícitamente  
    -- como verificación — deben coincidir con R y con el C=1.0 fijo de arriba (dado que  
    -- T_EP=T_NO siempre bajo el supuesto T_R=0, ecuación 3.3.5, esta división da 1.0 por  
    -- construcción — se calcula igual, en vez de asumirlo, para que quede como paso propio).  
    CASE WHEN R IS NULL OR T_O_min = 0 THEN NULL ELSE ROUND(ROUND(T_O_min * R, 2) / T_O_min, 4) END AS R_verif_TNO_TO,  
    CASE WHEN R IS NULL OR ROUND(T_O_min * R, 2) = 0 THEN NULL  
         ELSE ROUND(ROUND(T_O_min * R, 2) / ROUND(T_O_min * R, 2), 4) END AS C_calculado,  
  
    CASE WHEN R IS NULL THEN NULL ELSE ROUND(D * R * 1.0, 4) END AS EGE,  
    CASE WHEN R IS NULL THEN NULL ELSE ROUND(GU * D * R * 1.0, 4) END AS PTE,  
  
    CASE WHEN T_DO_min > 0 THEN ROUND(1 - CAST(T_TR_min AS FLOAT) / T_DO_min, 4) ELSE 0 END AS I_TR  
  
FROM con_r;  
GO
CREATE   PROCEDURE dbo.CLI547_AGM_SP_TPM_UNIFICADO  
    @p_reporte          VARCHAR(30),          -- obligatorio, ver lista de valores arriba  
    @p_fecha_desde       DATE,  
    @p_fecha_hasta       DATE,  
    @p_turno             VARCHAR(10) = NULL,  
    @p_proceso_id        INT         = NULL,  
    @p_cultivo_id        INT         = NULL,  -- reservado (no todos los reportes lo usan aún)  
    @p_tractor_id_erp    INT         = NULL,  
    @p_top               INT         = 10,  
    @p_order             VARCHAR(10) = 'DESC'  
AS  
BEGIN  
    SET NOCOUNT ON;  
  
    ----------------------------------------------------------------------------------------------  
    -- Validación de parámetros  
    ----------------------------------------------------------------------------------------------  
    IF @p_fecha_desde IS NULL OR @p_fecha_hasta IS NULL  
    BEGIN  
        RAISERROR('CLI547_AGM_SP_TPM_UNIFICADO: @p_fecha_desde y @p_fecha_hasta son obligatorios.', 16, 1);  
        RETURN;  
    END  
  
    IF @p_fecha_desde > @p_fecha_hasta  
    BEGIN  
        DECLARE @v_err_fdesde VARCHAR(10) = CONVERT(VARCHAR(10), @p_fecha_desde, 23);  
        DECLARE @v_err_fhasta VARCHAR(10) = CONVERT(VARCHAR(10), @p_fecha_hasta, 23);  
        RAISERROR('CLI547_AGM_SP_TPM_UNIFICADO: @p_fecha_desde (%s) no puede ser posterior a @p_fecha_hasta (%s).',  
                   16, 1, @v_err_fdesde, @v_err_fhasta);  
        RETURN;  
    END  
  
    IF @p_order IS NULL OR UPPER(@p_order) NOT IN ('ASC', 'DESC')  
    BEGIN  
        PRINT 'ℹ️  @p_order recibido no es "ASC" ni "DESC" — se usa "DESC" por defecto.';  
        SET @p_order = 'DESC';  
    END  
    ELSE  
        SET @p_order = UPPER(@p_order);  
  
    DECLARE @v_reporte VARCHAR(30) = UPPER(LTRIM(RTRIM(ISNULL(@p_reporte, ''))));  
    DECLARE @v_rango   VARCHAR(60) = CONCAT(CONVERT(VARCHAR(10), @p_fecha_desde, 23), ' a ', CONVERT(VARCHAR(10), @p_fecha_hasta, 23));  
  
    PRINT '================================================================================';  
    PRINT 'CLI547_AGM_SP_TPM_UNIFICADO';  
    PRINT '  Reporte solicitado : ' + ISNULL(NULLIF(@v_reporte, ''), '(vacío)');  
    PRINT '  Rango de fechas    : ' + @v_rango;  
    PRINT '  Filtros            : turno=' + ISNULL(@p_turno, '(todos)')  
        + ' | proceso_id=' + ISNULL(CAST(@p_proceso_id AS VARCHAR), '(todos)')  
        + ' | cultivo_id=' + ISNULL(CAST(@p_cultivo_id AS VARCHAR), '(todos)')  
        + ' | tractor_id_erp=' + ISNULL(CAST(@p_tractor_id_erp AS VARCHAR), '(todos)');  
    PRINT '================================================================================';  
  
    ----------------------------------------------------------------------------------------------  
    -- 1) DASHBOARD_OPERADOR  
    ----------------------------------------------------------------------------------------------  
    IF @v_reporte = 'DASHBOARD_OPERADOR'  
    BEGIN  
        PRINT '→ Generando Dashboard de Rendimiento por Operador.';  
        PRINT '  Fuente  : dbo.v_mma_indicadores_tpm, agregado por operador_id_erp.';  
        PRINT '  Fórmulas: GU=T_DO/T_TC · D=T_O/T_DO · R=T_NO/T_O (T_NO=T_O×R, SIN tope desde el';  
        PRINT '            30-ago-2026 — sobre-rendimiento es válido) · OEE=T_NO/T_DO · PTE=T_NO/T_TC · I_TR=1-T_TR/T_DO.';  
        PRINT '  [FIX-12] Capacidad_Nominal_Ponderada = promedio real ponderado por T_O.';  
        PRINT '  [FIX-13] Desviacion_Rendimiento_Porcentaje = R_Promedio - 100 (ya no se recalcula';  
        PRINT '           con otra fórmula independiente).';  
        PRINT '  [FIX-8]  "Registros_Sin_CN_Valida" muestra cuántos turnos del operador no tienen';  
        PRINT '           Capacidad Nominal configurada (su R/T_NO/EGE quedan en NULL, no en un';  
        PRINT '           valor inventado).';  
  
        WITH agregado AS (  
            SELECT  
                i.operador_id_erp,  
                MAX(r.nombre_operador_snapshot) AS Operador,  
                COUNT(DISTINCT i.registro_id)     AS Total_Registros,  
      SUM(i.T_DO_min)                    AS s_T_DO,  
                SUM(i.T_TC_min)                    AS s_T_TC,  
                SUM(i.T_O_min)                     AS s_T_O,  
                SUM(i.T_NO_min)                    AS s_T_NO,  
                SUM(i.T_TR_min)                    AS s_T_TR,  
                SUM(i.Q)                           AS s_Q,  
                SUM(i.capacidad_nominal * i.T_O_min)                          AS s_CN_ponderada, -- [FIX-12]  
                SUM(CASE WHEN i.capacidad_nominal_valida = 0 THEN 1 ELSE 0 END) AS Registros_Sin_CN_Valida -- [FIX-8]  
            FROM dbo.v_mma_indicadores_tpm i  
            INNER JOIN dbo.CLI547_AGM_MMA_REGISTROS_DIARIOS r ON r.id = i.registro_id  
            WHERE i.fecha BETWEEN @p_fecha_desde AND @p_fecha_hasta  
              AND i.operador_id_erp IS NOT NULL  
              AND (@p_proceso_id IS NULL OR i.proceso_id = @p_proceso_id)  
            GROUP BY i.operador_id_erp  
        ),  
        calculado AS (  
            SELECT *,  
                ROUND(CASE WHEN s_T_TC > 0 THEN s_T_DO * 1.0 / s_T_TC * 100 ELSE 0 END, 2) AS GU_Promedio,  
                ROUND(CASE WHEN s_T_DO > 0 THEN s_T_O  * 1.0 / s_T_DO * 100 ELSE 0 END, 2) AS D_Promedio,  
                ROUND(CASE WHEN s_T_O  > 0 THEN s_T_NO * 1.0 / s_T_O  * 100 ELSE 0 END, 2) AS R_Promedio,  
                ROUND(CASE WHEN s_T_DO > 0 THEN s_T_NO * 1.0 / s_T_DO * 100 ELSE 0 END, 2) AS OEE_Promedio,  
                ROUND(CASE WHEN s_T_TC > 0 THEN s_T_NO * 1.0 / s_T_TC * 100 ELSE 0 END, 2) AS PTE_Promedio,  
                ROUND(CASE WHEN s_T_DO > 0 THEN (1 - s_T_TR * 1.0 / s_T_DO) * 100 ELSE 0 END, 2) AS I_TR_Promedio  
            FROM agregado  
        )  
        SELECT  
            operador_id_erp,  
            Operador,  
            Total_Registros,  
            GU_Promedio, D_Promedio, R_Promedio, OEE_Promedio, PTE_Promedio, I_TR_Promedio,  
            ROUND(s_T_O / 60.0, 2) AS Horas_Operativas_Totales,  
            ROUND(s_Q, 2)          AS Produccion_Total,  
            ROUND(CASE WHEN s_T_O > 0 THEN s_CN_ponderada / s_T_O ELSE NULL END, 2) AS Capacidad_Nominal_Ponderada, -- [FIX-12]  
            ROUND(CASE WHEN s_T_O > 0 THEN s_Q / (s_T_O / 60.0) ELSE 0 END, 2)      AS Rendimiento_Real_Promedio,  
            (R_Promedio - 100.0)   AS Desviacion_Rendimiento_Porcentaje, -- [FIX-13]  
            Registros_Sin_CN_Valida,                                     -- [FIX-8]  
            CASE WHEN OEE_Promedio >= 85 THEN '🌟 Excelente'  
                 WHEN OEE_Promedio >= 60 THEN '✅ Bueno'  
                 WHEN OEE_Promedio >= 40 THEN '⚠️ Regular'  
                 ELSE '🔴 Crítico' END AS Desempeno_General,  
            CASE WHEN OEE_Promedio >= 85 THEN 'green'  
                 WHEN OEE_Promedio >= 60 THEN 'yellow'  
                 WHEN OEE_Promedio >= 40 THEN 'orange'  
                 ELSE 'red' END AS color_semaphore -- [FIX-19]  
        FROM calculado  
        ORDER BY OEE_Promedio DESC;  
  
        RETURN;  
    END  
  
    ----------------------------------------------------------------------------------------------  
    -- 2) SEIS_PERDIDAS  
    ----------------------------------------------------------------------------------------------  
    IF @v_reporte = 'SEIS_PERDIDAS'  
    BEGIN  
        PRINT '→ Generando Análisis de las Seis Grandes Pérdidas (Anexo 1 de la guía TPM).';  
        PRINT '  Fuente  : dbo.v_mma_indicadores_tpm.';  
        PRINT '  [FIX-3] 1ª/2ª pérdida ya NO incluyen clima/capacitación en la 2ª (se movieron a';  
        PRINT '          T_PP, fuera del alcance de "pérdidas no programadas").';  
        PRINT '  [NUEVO] La 1ª pérdida (T_PI) ahora incluye también T_DEM_SALIDA (demora del';  
        PRINT '          operador en salir del taller respecto a la hora fija de inicio de turno),';  
        PRINT '          tal como lo clasifica el Anexo 1 de la guía — antes solo contaba fallas';  
        PRINT '          mecánicas puras.';  
        PRINT '  [ACTUALIZADO 30-ago-2026] 3ª/4ª pérdida (T_MVO) SÍ puede salir negativa cuando hay';  
        PRINT '          sobre-rendimiento (R>100%) — confirmado con datos reales del área; ya no se';  
        PRINT '          trata como error, representa producir por encima de la capacidad nominal.';  
        PRINT '  [FIX-11] La fila "3." ahora dice "3-4." para dejar explícito que agrupa Ralentí+';  
        PRINT '           Paradas Menores (3ª) y Velocidad Reducida (4ª) en un solo T_MVO, tal';  
        PRINT '           como la guía lo define (ecuación 3.2.2 / Figura 03).';  
        PRINT '  5ª/6ª pérdida siguen en 0.00 h: fiel al supuesto T_R=0 de la guía (ecuación 3.3.3,';  
        PRINT '           "actualmente no se rechazan ni reprocesan hectáreas/bines/podas/';  
        PRINT '           triturados"). Si el negocio empieza a registrar reprocesos, este bloque';  
        PRINT '           debe modificarse en CÓDIGO — no basta con cargar datos nuevos.';  
  
        WITH perdidas AS (  
            SELECT  
                SUM(ISNULL(T_PI_min,  0)) / 60.0 AS P1_Fallas_Internas_Horas,  
                SUM(ISNULL(T_PE_min,  0)) / 60.0 AS P2_Externas_Ajustes_Horas,  
                SUM(ISNULL(T_MVO_min, 0)) / 60.0 AS P3_P4_Velocidad_Microparadas_Horas,  
                0.00 AS P5_Defectos_Horas,  
                0.00 AS P6_Rendimiento_Reducido_Horas,  
                SUM(ISNULL(T_DO_min, 0)) / 60.0 AS Total_Disponible_Horas,  
                SUM(ISNULL(T_O_min,  0)) / 60.0 AS Total_Operacion_Horas,  
                SUM(ISNULL(T_NO_min, 0)) / 60.0 AS Total_Neto_Horas  
            FROM dbo.v_mma_indicadores_tpm  
            WHERE fecha BETWEEN @p_fecha_desde AND @p_fecha_hasta  
              AND (@p_proceso_id IS NULL OR proceso_id = @p_proceso_id)  
              AND (@p_tractor_id_erp IS NULL OR tractor_id_erp = @p_tractor_id_erp)  
        )  
        SELECT '1. Fallas Internas (1ª pérdida)' AS Categoria_Perdida,  
               ROUND(P1_Fallas_Internas_Horas, 2) AS Horas_Perdidas,  
               ROUND(CASE WHEN Total_Disponible_Horas > 0 THEN P1_Fallas_Internas_Horas / Total_Disponible_Horas * 100 ELSE 0 END, 2) AS Porcentaje_Disponible  
        FROM perdidas  
        UNION ALL  
        SELECT '2. Paradas Externas / Ajustes (2ª pérdida)',  
               ROUND(P2_Externas_Ajustes_Horas, 2),  
               ROUND(CASE WHEN Total_Disponible_Horas > 0 THEN P2_Externas_Ajustes_Horas / Total_Disponible_Horas * 100 ELSE 0 END, 2)  
        FROM perdidas  
        UNION ALL  
        SELECT '3-4. Ralentí y Velocidad Reducida (3ª+4ª pérdida)', -- [FIX-11]  
               ROUND(P3_P4_Velocidad_Microparadas_Horas, 2),  
               ROUND(CASE WHEN Total_Operacion_Horas > 0 THEN P3_P4_Velocidad_Microparadas_Horas / Total_Operacion_Horas * 100 ELSE 0 END, 2)  
        FROM perdidas  
        UNION ALL  
        SELECT '5. Defectos de Proceso (5ª pérdida)',  
               ROUND(P5_Defectos_Horas, 2),  
               ROUND(CASE WHEN Total_Neto_Horas > 0 THEN P5_Defectos_Horas / Total_Neto_Horas * 100 ELSE 0 END, 2)  
        FROM perdidas  
        UNION ALL  
        SELECT '6. Rendimiento Reducido (6ª pérdida)',  
               ROUND(P6_Rendimiento_Reducido_Horas, 2),  
               ROUND(CASE WHEN Total_Neto_Horas > 0 THEN P6_Rendimiento_Reducido_Horas / Total_Neto_Horas * 100 ELSE 0 END, 2)  
        FROM perdidas  
        ORDER BY Horas_Perdidas DESC;  
  
        RETURN;  
    END  
  
    ----------------------------------------------------------------------------------------------  
    -- 3) RANKING_MAQUINAS  
    ----------------------------------------------------------------------------------------------  
    IF @v_reporte = 'RANKING_MAQUINAS'  
    BEGIN  
        PRINT '→ Generando Ranking de Máquinas por OEE (EGE).';  
        PRINT '  Fuente  : dbo.v_mma_indicadores_tpm, agregado por tractor_id_erp.';  
        PRINT '  [FIX-6] R/OEE/PTE ahora coinciden exactamente con el resto de reportes (T_NO=T_O×R,';  
        PRINT '          sin tope desde el 30-ago-2026 — puede reflejar sobre-rendimiento).';  
        PRINT '  [FIX-14] El semáforo se calcula una sola vez, no 3-4 veces por fila.';  
        PRINT '  [NUEVO]  "Horas Paradas Internas" = T_PI (fallas mecánicas + demora en la salida';  
        PRINT '           del taller) — ya no es solo fallas mecánicas puras.';  
        PRINT '  @p_order = ' + @p_order + ' (si venía inválido/NULL, ya se corrigió a DESC arriba).';  
  
        WITH agregado AS (  
            SELECT  
                i.tractor_id_erp,  
                MAX(r.codigo_tractor_snapshot) AS maquina,  
                COUNT(*)        AS total_registros,  
                SUM(i.T_O_min)  AS s_T_O,  
                SUM(i.T_PI_min) AS s_T_PI,  
                SUM(i.T_PE_min) AS s_T_PE,  
                SUM(i.T_DO_min) AS s_T_DO,  
                SUM(i.T_TC_min) AS s_T_TC,  
                SUM(i.T_NO_min) AS s_T_NO,  
                SUM(i.T_TR_min) AS s_T_TR  
            FROM dbo.v_mma_indicadores_tpm i  
            INNER JOIN dbo.CLI547_AGM_MMA_REGISTROS_DIARIOS r ON r.id = i.registro_id  
            WHERE i.fecha BETWEEN @p_fecha_desde AND @p_fecha_hasta  
              AND (@p_turno IS NULL OR i.turno = @p_turno)  
              AND (@p_proceso_id IS NULL OR i.proceso_id = @p_proceso_id)  
              AND (@p_tractor_id_erp IS NULL OR i.tractor_id_erp = @p_tractor_id_erp)  
            GROUP BY i.tractor_id_erp  
            HAVING SUM(i.T_DO_min) > 0   -- evita división por cero (COUNT(*)>0 era redundante tras GROUP BY)  
        ),  
        calculado AS (  
            SELECT *,  
                ROUND(CASE WHEN s_T_TC > 0 THEN s_T_DO * 1.0 / s_T_TC * 100 ELSE 0 END, 2) AS GU,  
                ROUND(CASE WHEN s_T_DO > 0 THEN s_T_O  * 1.0 / s_T_DO * 100 ELSE 0 END, 2) AS D,  
                ROUND(CASE WHEN s_T_O  > 0 THEN s_T_NO * 1.0 / s_T_O  * 100 ELSE 0 END, 2) AS R,  
                ROUND(CASE WHEN s_T_DO > 0 THEN s_T_NO * 1.0 / s_T_DO * 100 ELSE 0 END, 2) AS OEE,  
                ROUND(CASE WHEN s_T_TC > 0 THEN s_T_NO * 1.0 / s_T_TC * 100 ELSE 0 END, 2) AS PTE,  
                ROUND(CASE WHEN s_T_DO > 0 THEN (1 - s_T_TR * 1.0 / s_T_DO) * 100 ELSE 0 END, 2) AS I_TR  
            FROM agregado  
        )  
        SELECT TOP (@p_top)  
            maquina,  
            total_registros,  
            ROUND(s_T_O / 60.0, 2)  AS [Horas Op.],  
            ROUND(s_T_PI / 60.0, 2) AS [Horas Paradas Internas], -- [NUEVO] renombrado: ya no es solo "fallas" mecánicas, incluye T_DEM_SALIDA  
            ROUND(s_T_PE / 60.0, 2) AS [Horas Paro Prod.],  
            GU, D, R, OEE, PTE,  
            I_TR AS [I.TR],  
            CASE WHEN OEE >= 85 THEN '🌟 Excelente'  
                 WHEN OEE >= 60 THEN '✅ Bueno'  
                 WHEN OEE >= 40 THEN '⚠️ Regular'  
                 ELSE '🔴 Crítico' END AS desempeno,  
            CASE WHEN OEE >= 85 THEN 'green'  
                 WHEN OEE >= 60 THEN 'yellow'  
                 WHEN OEE >= 40 THEN 'orange'  
                 ELSE 'red' END AS color_semaphore -- [FIX-19]  
        FROM calculado  
        ORDER BY CASE WHEN @p_order = 'ASC'  THEN OEE END ASC,  
                 CASE WHEN @p_order = 'DESC' THEN OEE END DESC;  
  
        RETURN;  
    END  
  
    ----------------------------------------------------------------------------------------------  
    -- 4) PARETO_FALLAS  
    ----------------------------------------------------------------------------------------------  
    IF @v_reporte = 'PARETO_FALLAS'  
    BEGIN  
        PRINT '→ Generando Pareto de Fallas Mecánicas (1ª pérdida — tipo_paro = MECANICO).'; -- [FIX-10]  
        PRINT '  Fuente  : CLI547_AGM_MMA_PAROS_EQUIPOS + CLI547_AGM_MMA_TIPOS_PARO, filtrado a';  
        PRINT '            tipo_paro.codigo = ''MECANICO'' (mismo criterio que T_PI en la vista de';  
        PRINT '            tiempos). Este reporte NO cubre las demás pérdidas — para eso usar';  
        PRINT '            @p_reporte = ''SEIS_PERDIDAS''.';  
        PRINT '  [FIX-5] El porcentaje acumulado se calcula con una función de ventana';  
        PRINT '          (SUM() OVER ORDER BY ... ROWS UNBOUNDED PRECEDING), NO con el patrón';  
        PRINT '          "quirky update" anterior, cuyo orden de acumulación NO estaba';  
        PRINT '          garantizado por SQL Server.';  
  
        WITH fallas AS (  
            SELECT  
                tp.id AS tipo_paro_id, tp.codigo AS tipo_paro_codigo, tp.nombre AS tipo_paro_nombre,  
                COUNT(*) AS total_ocurrencias,  
                SUM(ISNULL(pe.duracion_min, 0)) AS total_duracion_minutos  
            FROM dbo.CLI547_AGM_MMA_REGISTROS_DIARIOS r  
            INNER JOIN dbo.CLI547_AGM_MMA_PAROS_EQUIPOS pe ON pe.registro_id = r.id  
            INNER JOIN dbo.CLI547_AGM_MMA_TIPOS_PARO tp    ON tp.id = pe.tipo_paro_id  
            WHERE r.fecha BETWEEN @p_fecha_desde AND @p_fecha_hasta  
              AND r.estado IN ('completado', 'aprobado')  
              AND tp.codigo IN ('MECANICO')  
              AND (@p_turno IS NULL OR r.turno = @p_turno)  
              AND (@p_proceso_id IS NULL OR r.proceso_id = @p_proceso_id)  
              AND (@p_tractor_id_erp IS NULL OR r.tractor_id_erp = @p_tractor_id_erp)  
            GROUP BY tp.id, tp.codigo, tp.nombre  
            HAVING SUM(ISNULL(pe.duracion_min, 0)) > 0  
        ),  
        con_acumulado AS (  
            SELECT *,  
                SUM(total_duracion_minutos) OVER (ORDER BY total_duracion_minutos DESC  
                    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS acumulado_min, -- [FIX-5]  
                SUM(total_duracion_minutos) OVER () AS total_general_min  
            FROM fallas  
        )  
        SELECT TOP (@p_top)  
            tipo_paro_codigo AS codigo,  
            tipo_paro_nombre AS tipo_falla,  
            total_ocurrencias AS ocurrencias,  
            ROUND(total_duracion_minutos / 60.0, 2) AS horas_perdidas,  
            ROUND(CASE WHEN total_general_min > 0 THEN acumulado_min * 1.0 / total_general_min * 100 ELSE 0 END, 1) AS porcentaje_acumulado,  
            CASE WHEN (CASE WHEN total_general_min > 0 THEN acumulado_min * 1.0 / total_general_min * 100 ELSE 0 END) <= 80 THEN 'Critical'  
                 WHEN (CASE WHEN total_general_min > 0 THEN acumulado_min * 1.0 / total_general_min * 100 ELSE 0 END) <= 95 THEN 'Important'  
                 ELSE 'Minor' END AS prioridad  
        FROM con_acumulado  
        ORDER BY total_duracion_minutos DESC;  
  
        RETURN;  
    END  
  
    ----------------------------------------------------------------------------------------------  
    -- 5) TIEMPOS_PRODUCTIVOS  
    ----------------------------------------------------------------------------------------------  
    IF @v_reporte = 'TIEMPOS_PRODUCTIVOS'  
    BEGIN  
        PRINT '→ Generando glosario de Tiempos Productivos (Anexo 2 de la guía TPM).';  
        PRINT '  Fuente  : dbo.v_mma_indicadores_tpm.';  
        PRINT '  [FIX-17] C_N_prom ahora es un promedio ponderado por T_O_min (no un AVG() simple),';  
        PRINT '           para no distorsionar el dato cuando hay tractores con horas muy distintas.';  
        PRINT '  [ACTUALIZADO 30-ago-2026] T_NO/T_MVO/T_EP pueden reflejar sobre-rendimiento';  
        PRINT '           (T_NO>T_O, T_MVO<0) cuando R supera 100% — confirmado con datos reales.';  
        PRINT '  [FIX-8]  Se agrega una fila informativa con el n° de registros sin Capacidad';  
        PRINT '           Nominal configurada (excluidos del promedio de T_NO/T_MVO/T_EP).';  
        PRINT '  [NUEVO]  Se agrega la fila T_DEM_SALIDA (demora entre la hora fija de inicio de';  
        PRINT '           turno y la salida real del taller) — ya está sumada dentro de T_PI,';  
        PRINT '           esta fila solo la desglosa para trazabilidad.';  
        PRINT '  [ACTUALIZADO 29-ago-2026, confirmado con Excel real del área] T_PE ahora es un';  
        PRINT '           residuo (T_DO-T_T-T_TR), no una suma de eventos — se agrega T_PE_COMB';  
        PRINT '           como diagnóstico (solo eventos COMBUSTIBLE, ya no alimenta el T_PE';  
      PRINT '           oficial). Se agregan T_INTERNOS y T_ABASTECIMIENTO (factores fijos';  
        PRINT '           0.6 y 0.25 sobre el residuo T_PE, no eventos medidos) y TTT.';  
  
        WITH tiempos_agregados AS (  
            SELECT  
                SUM(T_TC_min)   AS T_TC_min,   SUM(T_PP_min) AS T_PP_min,   SUM(T_NU_min) AS T_NU_min,  
                SUM(T_PP_interna_min) AS T_PP_interna_min, SUM(T_PP_externa_min) AS T_PP_externa_min,   -- [NUEVO]  
                SUM(T_DO_min)   AS T_DO_min,   SUM(T_TR_min) AS T_TR_min,   SUM(T_PE_min) AS T_PE_min,  
                SUM(T_PE_combustible_directo_min) AS T_PE_comb_min,                                     -- [NUEVO] diagnóstico  
                SUM(T_internos_estimado_min) AS T_internos_min,                                          -- [NUEVO]  
                SUM(T_abastecimiento_estimado_min) AS T_abastecimiento_min,                              -- [NUEVO]  
                SUM(T_PI_min)   AS T_PI_min,   SUM(T_PI_mecanico_min) AS T_PI_mecanico_min,  
                SUM(T_DEM_SALIDA_min) AS T_DEM_SALIDA_min,                                          -- [NUEVO]  
                SUM(T_O_min)  AS T_O_min,    SUM(T_T_min)  AS T_T_min,  
                SUM(T_TPNP_min) AS T_TPNP_min, SUM(T_TPP_min) AS T_TPP_min,  
                SUM(Q)          AS Q_total,  
                CASE WHEN SUM(T_O_min) > 0 THEN SUM(capacidad_nominal * T_O_min) / SUM(T_O_min) ELSE NULL END AS C_N_prom, -- [FIX-17]  
                SUM(T_NO_min)   AS T_NO_min,   SUM(T_MVO_min) AS T_MVO_min, SUM(T_EP_min) AS T_EP_min,  
                SUM(T_TC_min) - SUM(T_NU_min) AS T_U_min,  
                SUM(T_DO_min) - SUM(T_DEM_SALIDA_min) AS TTT_min                                         -- [NUEVO]  
            FROM dbo.v_mma_indicadores_tpm  
            WHERE fecha BETWEEN @p_fecha_desde AND @p_fecha_hasta  
              AND (@p_turno IS NULL OR turno = @p_turno)  
              AND (@p_proceso_id IS NULL OR proceso_id = @p_proceso_id)  
              AND (@p_tractor_id_erp IS NULL OR tractor_id_erp = @p_tractor_id_erp)  
        )  
        SELECT 'T_TC' codigo, 'Tiempo Total Calendario' descripcion, ROUND(T_TC_min/60.0,2) horas, T_TC_min minutos FROM tiempos_agregados  
        UNION ALL SELECT 'T_U','Tiempo de Uso', ROUND(T_U_min/60.0,2), T_U_min FROM tiempos_agregados  
        UNION ALL SELECT 'T_NU','Tiempo de No Uso', ROUND(T_NU_min/60.0,2), T_NU_min FROM tiempos_agregados  
        UNION ALL SELECT 'T_PP','Tiempo de Paradas Programadas (total)', ROUND(T_PP_min/60.0,2), T_PP_min FROM tiempos_agregados  
        UNION ALL SELECT 'T_PP_INT','  · de las cuales, INTERNAS al plan (resta de T_DO, ec. 2.4)', ROUND(T_PP_interna_min/60.0,2), T_PP_interna_min FROM tiempos_agregados   -- [NUEVO]  
        UNION ALL SELECT 'T_PP_EXT','  · de las cuales, EXTERNAS al plan (clima, NO resta de T_DO)', ROUND(T_PP_externa_min/60.0,2), T_PP_externa_min FROM tiempos_agregados -- [NUEVO]  
        UNION ALL SELECT 'T_TPP','Tiempo Total Paradas Programadas', ROUND(T_TPP_min/60.0,2), T_TPP_min FROM tiempos_agregados  
        UNION ALL SELECT 'T_DO','Tiempo Disponible para Operar', ROUND(T_DO_min/60.0,2), T_DO_min FROM tiempos_agregados  
        UNION ALL SELECT 'T_PE','Tiempo de Paradas Externas (RESIDUO: T_DO-T_T-T_TR)', ROUND(T_PE_min/60.0,2), T_PE_min FROM tiempos_agregados     -- [ACTUALIZADO]  
        UNION ALL SELECT 'T_PE_COMB','  · diagnóstico: solo eventos COMBUSTIBLE (ya NO alimenta T_PE)', ROUND(T_PE_comb_min/60.0,2), T_PE_comb_min FROM tiempos_agregados -- [NUEVO]  
        UNION ALL SELECT 'T_INTERNOS','  · estimado: T_PE x 0.6 (factor fijo, no evento medido)', ROUND(T_internos_min/60.0,2), T_internos_min FROM tiempos_agregados -- [NUEVO]  
        UNION ALL SELECT 'T_ABASTEC','  · estimado: T_PE x 0.25 si Aplicación (factor fijo, no evento medido)', ROUND(T_abastecimiento_min/60.0,2), T_abastecimiento_min FROM tiempos_agregados -- [NUEVO]  
        UNION ALL SELECT 'T_PI','Tiempo de Paradas Internas (total: mecánico + demora salida)', ROUND(T_PI_min/60.0,2), T_PI_min FROM tiempos_agregados  
        UNION ALL SELECT 'T_PI_MEC','  · de las cuales, Fallas Mecánicas', ROUND(T_PI_mecanico_min/60.0,2), T_PI_mecanico_min FROM tiempos_agregados          -- [NUEVO]  
        UNION ALL SELECT 'T_DEM_SALIDA','  · de las cuales, Demora en la Salida', ROUND(T_DEM_SALIDA_min/60.0,2), T_DEM_SALIDA_min FROM tiempos_agregados     -- [NUEVO]  
        UNION ALL SELECT 'T_TPNP','Tiempo Total Paradas No Programadas', ROUND(T_TPNP_min/60.0,2), T_TPNP_min FROM tiempos_agregados  
        UNION ALL SELECT 'T_T','Tiempo de Trabajo (T_O + T_PI, ver ec. 3.1.11)', ROUND(T_T_min/60.0,2), T_T_min FROM tiempos_agregados   -- [ACTUALIZADO]  
        UNION ALL SELECT 'T_O','Tiempo de Operación', ROUND(T_O_min/60.0,2), T_O_min FROM tiempos_agregados  
        UNION ALL SELECT 'T_TR','Tiempo de Traslado', ROUND(T_TR_min/60.0,2), T_TR_min FROM tiempos_agregados  
        UNION ALL SELECT 'T_MVO','Tiempo por Menor Velocidad', ROUND(T_MVO_min/60.0,2), T_MVO_min FROM tiempos_agregados  
        UNION ALL SELECT 'T_NO','Tiempo Neto de Operación', ROUND(T_NO_min/60.0,2), T_NO_min FROM tiempos_agregados  
        UNION ALL SELECT 'T_EP','Tiempo Efectivo de Producción', ROUND(T_EP_min/60.0,2), T_EP_min FROM tiempos_agregados  
        UNION ALL SELECT 'T_R','Tiempo para Retrabajos', 0.0, 0 FROM tiempos_agregados  
        UNION ALL SELECT 'Q','Cantidad Producida', ROUND(Q_total,2), Q_total FROM tiempos_agregados  
        UNION ALL SELECT 'C_N','Capacidad Nominal Ponderada (nota: R usa C_N al cuadrado, ver 3.2.3 en FORMULAS_GUIA)', ROUND(C_N_prom,2), NULL FROM tiempos_agregados  
        UNION ALL SELECT 'TTT','Tiempo Total de Trabajo (T_DO - T_DEM_SALIDA)', ROUND(TTT_min/60.0,2), TTT_min FROM tiempos_agregados   -- [NUEVO]  
        UNION ALL  
        SELECT 'INFO_CN',  
               'Registros con Capacidad Nominal no configurada (excluidos de T_NO/T_MVO/T_EP — ver FIX-8)',  
               CAST((SELECT COUNT(*) FROM dbo.v_mma_indicadores_tpm  
                     WHERE fecha BETWEEN @p_fecha_desde AND @p_fecha_hasta  
                       AND capacidad_nominal_valida = 0  
                       AND (@p_turno IS NULL OR turno = @p_turno)  
                       AND (@p_proceso_id IS NULL OR proceso_id = @p_proceso_id)  
                       AND (@p_tractor_id_erp IS NULL OR tractor_id_erp = @p_tractor_id_erp)) AS DECIMAL(18,2)),  
               CAST(NULL AS INT);  
  
        RETURN;  
    END  
  
    ----------------------------------------------------------------------------------------------  
    -- 6) TABLA_DIARIA  
    ----------------------------------------------------------------------------------------------  
    IF @v_reporte = 'TABLA_DIARIA'  
    BEGIN  
        PRINT '→ Generando Tabla Diaria de Indicadores TPM.';  
        PRINT '  Fuente  : dbo.v_mma_indicadores_tpm, agregado por fecha.';  
        PRINT '  [FIX-6] R/OEE ahora consistentes con el resto de reportes (T_NO=T_O×R, sin tope).';  
  
        WITH agregado AS (  
            SELECT  
                i.fecha,  
                COUNT(*)        AS total_registros,  
                SUM(i.T_TC_min) AS s_T_TC, SUM(i.T_DO_min) AS s_T_DO, SUM(i.T_T_min) AS s_T_T,  
                SUM(i.T_O_min)  AS s_T_O,  SUM(i.T_NO_min) AS s_T_NO, SUM(i.T_TR_min) AS s_T_TR,  
                SUM(i.Q)        AS s_Q  
            FROM dbo.v_mma_indicadores_tpm i  
            WHERE i.fecha BETWEEN @p_fecha_desde AND @p_fecha_hasta  
              AND (@p_turno IS NULL OR i.turno = @p_turno)  
              AND (@p_proceso_id IS NULL OR i.proceso_id = @p_proceso_id)  
              AND (@p_tractor_id_erp IS NULL OR i.tractor_id_erp = @p_tractor_id_erp)  
            GROUP BY i.fecha  
        )  
        SELECT  
            fecha AS Dia,  
            ROUND(CASE WHEN s_T_TC > 0 THEN s_T_DO * 1.0 / s_T_TC * 100 ELSE 0 END, 2) AS GU,  
            ROUND(CASE WHEN s_T_DO > 0 THEN s_T_T  * 1.0 / s_T_DO * 100 ELSE 0 END, 2) AS [D.PR],  
            ROUND(CASE WHEN s_T_T  > 0 THEN s_T_O  * 1.0 / s_T_T  * 100 ELSE 0 END, 2) AS [D.MA],  
            ROUND(CASE WHEN s_T_DO > 0 THEN s_T_O  * 1.0 / s_T_DO * 100 ELSE 0 END, 2) AS D,  
            ROUND(CASE WHEN s_T_O  > 0 THEN s_T_NO * 1.0 / s_T_O  * 100 ELSE 0 END, 2) AS R,  
            100.0 AS C,  
            ROUND(CASE WHEN s_T_DO > 0 THEN s_T_NO * 1.0 / s_T_DO * 100 ELSE 0 END, 2) AS OEE,  
            ROUND(CASE WHEN s_T_TC > 0 THEN s_T_NO * 1.0 / s_T_TC * 100 ELSE 0 END, 2) AS PTE,  
            ROUND(CASE WHEN s_T_DO > 0 THEN (1 - s_T_TR * 1.0 / s_T_DO) * 100 ELSE 0 END, 2) AS [I.TR],  
            total_registros AS Registros,  
            ROUND(s_T_O / 60.0, 2)  AS [Horas Op.],  
            ROUND(s_T_DO / 60.0, 2) AS [Horas Plan.],  
            ROUND(s_Q, 2)           AS Produccion  
        FROM agregado  
        ORDER BY fecha;  
  
        RETURN;  
    END  
  
    ----------------------------------------------------------------------------------------------  
    -- 7) METRICAS_RESUMEN  
    ----------------------------------------------------------------------------------------------  
    IF @v_reporte = 'METRICAS_RESUMEN'  
    BEGIN  
        PRINT '→ Generando Métricas Resumen (conteos generales del periodo).';  
        PRINT '  Fuente  : CLI547_AGM_MMA_REGISTROS_DIARIOS + CLI547_AGM_MMA_PAROS_EQUIPOS.';  
        PRINT '  [FIX-10] "N° Fallas" se etiqueta explícitamente como "Mecánicas (1ª pérdida)"';  
        PRINT '           porque solo cuenta tipo_paro.codigo = ''MECANICO''.';  
  
        DECLARE @v_fallas INT, @v_dias INT, @v_maquinas INT;  
  
        SELECT @v_fallas = COUNT(*)  
        FROM dbo.CLI547_AGM_MMA_REGISTROS_DIARIOS r  
        INNER JOIN dbo.CLI547_AGM_MMA_PAROS_EQUIPOS pe ON pe.registro_id = r.id  
        INNER JOIN dbo.CLI547_AGM_MMA_TIPOS_PARO tp    ON tp.id = pe.tipo_paro_id  
        WHERE r.fecha BETWEEN @p_fecha_desde AND @p_fecha_hasta  
          AND r.estado IN ('completado', 'aprobado')  
          AND tp.codigo IN ('MECANICO')  
          AND (@p_turno IS NULL OR r.turno = @p_turno)  
          AND (@p_proceso_id IS NULL OR r.proceso_id = @p_proceso_id)  
          AND (@p_tractor_id_erp IS NULL OR r.tractor_id_erp = @p_tractor_id_erp);  
  
        SELECT @v_dias = COUNT(DISTINCT r.fecha)  
        FROM dbo.CLI547_AGM_MMA_REGISTROS_DIARIOS r  
        WHERE r.fecha BETWEEN @p_fecha_desde AND @p_fecha_hasta  
          AND r.estado IN ('completado', 'aprobado')  
          AND (@p_turno IS NULL OR r.turno = @p_turno)  
          AND (@p_proceso_id IS NULL OR r.proceso_id = @p_proceso_id)  
          AND (@p_tractor_id_erp IS NULL OR r.tractor_id_erp = @p_tractor_id_erp);  
  
        SELECT @v_maquinas = COUNT(DISTINCT r.tractor_id_erp)  
        FROM dbo.CLI547_AGM_MMA_REGISTROS_DIARIOS r  
        WHERE r.fecha BETWEEN @p_fecha_desde AND @p_fecha_hasta  
          AND r.estado IN ('completado', 'aprobado')  
          AND (@p_turno IS NULL OR r.turno = @p_turno)  
          AND (@p_proceso_id IS NULL OR r.proceso_id = @p_proceso_id)  
          AND (@p_tractor_id_erp IS NULL OR r.tractor_id_erp = @p_tractor_id_erp);  
  
        SELECT 'N° Fallas Mecánicas (1ª pérdida)' AS metrica, @v_fallas AS valor, 'eventos' AS unidad -- [FIX-10]  
        UNION ALL SELECT 'Días Proceso', @v_dias, 'días'  
        UNION ALL SELECT '# Máquinas', @v_maquinas, 'máquinas';  
  
        RETURN;  
    END  
  
    ----------------------------------------------------------------------------------------------  
    -- 8) KPI_RESUMEN  
    ----------------------------------------------------------------------------------------------  
    IF @v_reporte = 'KPI_RESUMEN'  
    BEGIN  
        PRINT '→ Generando KPI Resumen (semáforo por indicador).';  
        PRINT '  Fuente  : dbo.v_mma_indicadores_tpm.';  
        PRINT '  [FIX-1] Antes este era el ÚNICO SP que apuntaba a esta vista (los otros 7';  
        PRINT '          apuntaban a "v_mma_indicadores_tpm_2", nunca compartida) — ahora TODO';  
        PRINT '          el sistema usa la misma fuente, así que este reporte ya coincide con';  
        PRINT '          los demás para el mismo periodo/filtro.';  
        PRINT '  ⚠️ Los umbrales de semáforo (GU≥90, D≥85, R≥90, etc.) son reglas de negocio';  
        PRINT '     internas — NO provienen de la guía TPM (que no define metas numéricas) — y';  
        PRINT '     son distintos de la escala única (Excelente/Bueno/Regular/Crítico sobre OEE)';  
        PRINT '     usada en DASHBOARD_OPERADOR/RANKING_MAQUINAS. Es intencional: aquí se evalúa';  
        PRINT '     cada KPI por separado; allá se resume el desempeño general en una sola escala.';  
        PRINT '     Confirmar con el negocio que ambas escalas siguen vigentes.';  
  
        DECLARE @v_GU DECIMAL(10,2), @v_D_PR DECIMAL(10,2), @v_D_MA DECIMAL(10,2), @v_D DECIMAL(10,2),  
                @v_R DECIMAL(10,2), @v_C DECIMAL(10,2), @v_EGE DECIMAL(10,2), @v_PTE DECIMAL(10,2), @v_I_TR DECIMAL(10,2);  
  
        SELECT  
            @v_GU   = ROUND(CASE WHEN SUM(T_TC_min) > 0 THEN SUM(T_DO_min) * 1.0 / SUM(T_TC_min) * 100 ELSE 0 END, 2),  
            @v_D_PR = ROUND(CASE WHEN SUM(T_DO_min) > 0 THEN SUM(T_T_min)  * 1.0 / SUM(T_DO_min) * 100 ELSE 0 END, 2),  
            @v_D_MA = ROUND(CASE WHEN SUM(T_T_min)  > 0 THEN SUM(T_O_min) * 1.0 / SUM(T_T_min)  * 100 ELSE 0 END, 2),  
            @v_D    = ROUND(CASE WHEN SUM(T_DO_min) > 0 THEN SUM(T_O_min) * 1.0 / SUM(T_DO_min) * 100 ELSE 0 END, 2),  
            @v_R    = ROUND(CASE WHEN SUM(T_O_min)  > 0 THEN SUM(T_NO_min) * 1.0 / SUM(T_O_min) * 100 ELSE 0 END, 2),  
            @v_C    = 100.0,  
            @v_EGE  = ROUND(CASE WHEN SUM(T_DO_min) > 0 THEN SUM(T_NO_min) * 1.0 / SUM(T_DO_min) * 100 ELSE 0 END, 2),  
            @v_PTE  = ROUND(CASE WHEN SUM(T_TC_min) > 0 THEN SUM(T_NO_min) * 1.0 / SUM(T_TC_min) * 100 ELSE 0 END, 2),  
            @v_I_TR = ROUND(CASE WHEN SUM(T_DO_min) > 0 THEN (1 - SUM(T_TR_min) * 1.0 / SUM(T_DO_min)) * 100 ELSE 0 END, 2)  
        FROM dbo.v_mma_indicadores_tpm  -- [FIX-1] vista única, no más "_2"  
        WHERE fecha BETWEEN @p_fecha_desde AND @p_fecha_hasta  
          AND (@p_turno IS NULL OR turno = @p_turno)  
          AND (@p_proceso_id IS NULL OR proceso_id = @p_proceso_id)  
          AND (@p_tractor_id_erp IS NULL OR tractor_id_erp = @p_tractor_id_erp);  
  
        DECLARE @v_kpis TABLE (metric_key VARCHAR(50) PRIMARY KEY, metric_value DECIMAL(10,2), metric_label VARCHAR(100), color_semaphore VARCHAR(10));  
  
        INSERT INTO @v_kpis VALUES  
            ('GU',   @v_GU,   'Grado de Utilización',             CASE WHEN @v_GU  >= 90 THEN 'green' WHEN @v_GU  >= 75 THEN 'yellow' ELSE 'red' END),  
            ('D_PR', @v_D_PR, 'Disponibilidad por Producción',    CASE WHEN @v_D_PR>= 85 THEN 'green' WHEN @v_D_PR>= 70 THEN 'yellow' ELSE 'red' END),  
            ('D_MA', @v_D_MA, 'Disponibilidad por Mantenimiento', CASE WHEN @v_D_MA>= 90 THEN 'green' WHEN @v_D_MA>= 75 THEN 'yellow' ELSE 'red' END),  
            ('D',    @v_D,    'Disponibilidad Global',            CASE WHEN @v_D   >= 85 THEN 'green' WHEN @v_D   >= 65 THEN 'yellow' ELSE 'red' END),  
            ('R',    @v_R,    'Rendimiento',                      CASE WHEN @v_R   >= 90 THEN 'green' WHEN @v_R   >= 75 THEN 'yellow' ELSE 'red' END),  
            ('C',    @v_C,    'Calidad',                          CASE WHEN @v_C   >= 95 THEN 'green' WHEN @v_C   >= 85 THEN 'yellow' ELSE 'red' END),  
            ('OEE',  @v_EGE,  'Efectividad Global del Equipo',    CASE WHEN @v_EGE >= 85 THEN 'green' WHEN @v_EGE >= 60 THEN 'yellow' ELSE 'red' END),  
            ('PTE',  @v_PTE,  'Productividad Total del Equipo',   CASE WHEN @v_PTE >= 70 THEN 'green' WHEN @v_PTE >= 50 THEN 'yellow' ELSE 'red' END),  
            ('I_TR', @v_I_TR, 'Índice de Traslado',               CASE WHEN @v_I_TR>= 90 THEN 'green' WHEN @v_I_TR>= 75 THEN 'yellow' ELSE 'red' END);  
  
        SELECT metric_key, metric_value, metric_label, color_semaphore  
        FROM @v_kpis  
        ORDER BY CASE metric_key  
            WHEN 'GU' THEN 1 WHEN 'D_PR' THEN 2 WHEN 'D_MA' THEN 3 WHEN 'D' THEN 4  
            WHEN 'R'  THEN 5 WHEN 'C'    THEN 6 WHEN 'OEE'  THEN 7 WHEN 'PTE' THEN 8 WHEN 'I_TR' THEN 9 END;  
  
        RETURN;  
    END  
  
    ----------------------------------------------------------------------------------------------  
    -- 9) FORMULAS_GUIA — las 28 ecuaciones de la guía TPM, una por una, con sus variables y su  
    --    resultado calculado para el rango/filtro pedido. Pensado para auditoría/trazabilidad,  
    --    no para un dashboard — muestra tanto las fórmulas "oficiales" (las que sí alimentan  
    --    GU/D/R/EGE/PTE) como los métodos alternativos/diagnósticos de la guía que no se usan  
    --    para calcular nada (3.1.8, 3.1.11) y las verificaciones algebraicas (3.1.3/3.1.4,  
    --    3.2.1, 3.3.1/3.3.2) que deben coincidir con el resultado "oficial" si todo está bien.  
    ----------------------------------------------------------------------------------------------  
    IF @v_reporte = 'FORMULAS_GUIA'  
    BEGIN  
        PRINT '→ Generando detalle de las 28 ecuaciones de la Guía TPM.';  
        PRINT '  Fuente : dbo.v_mma_indicadores_tpm, agregado para el rango/filtro pedido.';  
        PRINT '  [ACTUALIZADO 29-ago-2026] T_PE ya NO es la fórmula directa (3.1.7) — es un residuo';  
        PRINT '  (T_DO-T_T-T_TR), confirmado con el Excel real del área. T_T ya NO se deriva de';  
        PRINT '  T_DO-T_PE (3.1.6) — se arma como T_O+T_PI (3.1.11 reordenada), confirmado también';  
        PRINT '  con la fórmula real del área ("TO=TT-TPI"). R (3.2.3) usa capacidad_nominal DOS';  
        PRINT '  VECES (Q/(T_O×C_N²)) por decisión de negocio, para coincidir con el Excel del área';  
        PRINT '  — no es la ecuación literal de la guía (una sola división). D_PR sigue sin ninguna';  
        PRINT '  fórmula de referencia confirmada por el área — pendiente.';  
  
        WITH agg AS (  
            SELECT  
                SUM(T_TC_min) AS T_TC, SUM(T_PP_min) AS T_PP, SUM(T_PP_interna_min) AS T_PPi,  
                SUM(T_PP_externa_min) AS T_PPe, SUM(T_NU_min) AS T_NU, SUM(T_DO_min) AS T_DO,  
                SUM(T_TR_min) AS T_TR, SUM(T_PE_min) AS T_PE, SUM(T_PE_indirecto_min) AS T_PE_ind,  
                SUM(T_PE_combustible_directo_min) AS T_PE_combustible,   -- [NUEVO] para fila 13 (diagnóstico)  
                SUM(T_PI_min) AS T_PI, SUM(T_O_min) AS T_O, SUM(T_O_derivado_min) AS T_O_der,  
                SUM(T_T_min) AS T_T, SUM(T_TPNP_min) AS T_TPNP, SUM(T_TPP_min) AS T_TPP,  
                SUM(Q) AS Q,  
                CASE WHEN SUM(T_O_min) > 0 THEN SUM(capacidad_nominal * T_O_min) / SUM(T_O_min) ELSE NULL END AS C_N,  
                SUM(T_NO_min) AS T_NO, SUM(T_MVO_min) AS T_MVO, SUM(T_EP_min) AS T_EP,  
                0 AS T_R  
            FROM dbo.v_mma_indicadores_tpm  
            WHERE fecha BETWEEN @p_fecha_desde AND @p_fecha_hasta  
              AND (@p_turno IS NULL OR turno = @p_turno)  
              AND (@p_proceso_id IS NULL OR proceso_id = @p_proceso_id)  
              AND (@p_tractor_id_erp IS NULL OR tractor_id_erp = @p_tractor_id_erp)  
        ),  
        calc AS (  
            SELECT *,  
                CASE WHEN T_TC > 0 THEN T_DO * 1.0 / T_TC ELSE 0 END AS GU,  
                CASE WHEN T_DO > 0 THEN T_T  * 1.0 / T_DO ELSE 0 END AS D_PR,  
                CASE WHEN T_T  > 0 THEN T_O  * 1.0 / T_T  ELSE 0 END AS D_MA,  
                CASE WHEN T_DO > 0 THEN T_O  * 1.0 / T_DO ELSE 0 END AS D,  
                CASE WHEN T_O  > 0 THEN T_NO * 1.0 / T_O  ELSE 0 END AS R,  
                1.0 AS C,  
                CASE WHEN T_DO > 0 THEN 1 - T_TR * 1.0 / T_DO ELSE 0 END AS I_TR  
            FROM agg  
        )  
        SELECT 1 AS N, '1.1'   AS Ecuacion, 'PTE = GU x EGE' AS Formula,  
               CONCAT('GU=', ROUND(GU*100,2), '%, EGE=', ROUND(D*R*C*100,2), '%') AS Variables,  
               ROUND(GU*D*R*C*100,2) AS Valor, '%' AS Unidad, 'Productividad Total del Equipo — confirmado exacto contra el Excel real del área (29-ago-2026)' AS Descripcion FROM calc  
   UNION ALL SELECT 2, '2.1', 'GU = T_DO / T_TC', CONCAT('T_DO=',T_DO,' min, T_TC=',T_TC,' min'), ROUND(GU*100,2), '%', 'Grado de Utilización — confirmado exacto contra el Excel real del área' FROM calc  
        UNION ALL SELECT 3, '2.2', 'T_TPP = T_PP + T_NU', CONCAT('T_PP=',T_PP,' min, T_NU=',T_NU,' min'), CAST(T_TPP AS DECIMAL(18,2)), 'min', 'Tiempo Total de Paradas Programadas' FROM calc  
        UNION ALL SELECT 4, '2.3', 'T_PP = SUM(T_PPi interna) + SUM(T_PPi externa)', CONCAT('interna=',T_PPi,' min, externa=',T_PPe,' min'), CAST(T_PP AS DECIMAL(18,2)), 'min', 'Composición de T_PP (Anexo 3) — confirmado exacto (TPP=CAP+CAL+CLI+VESTUARIO
 en el Excel real)' FROM calc  
        UNION ALL SELECT 5, '2.4', 'T_DO = (T_F - T_I) - SUM(T_PPi interna)', CONCAT('T_TC=',T_TC,' min, T_PP_interna=',T_PPi,' min'), CAST(T_DO AS DECIMAL(18,2)), 'min', 'Tiempo Disponible para Operar' FROM calc  
        UNION ALL SELECT 6, '3.1', 'EGE = D x R x C', CONCAT('D=',ROUND(D*100,2),'%, R=',ROUND(R*100,2),'%, C=',ROUND(C*100,2),'%'), ROUND(D*R*C*100,2), '%', 'Eficacia Global del Equipo (OEE) — confirmado exacto contra el Excel real del área' FROM calc  
        UNION ALL SELECT 7, '3.1.1', 'D = T_O / T_DO', CONCAT('T_O=',T_O,' min, T_DO=',T_DO,' min'), ROUND(D*100,2), '%', 'Disponibilidad (fórmula oficial, directa) — confirmado exacto contra el Excel real del área' FROM calc  
        UNION ALL SELECT 8, '3.1.2', 'T_TPNP = T_PI + T_PE', CONCAT('T_PI=',T_PI,' min, T_PE=',T_PE,' min'), CAST(T_TPNP AS DECIMAL(18,2)), 'min', 'Tiempo Total de Paradas No Programadas' FROM calc  
        UNION ALL SELECT 9, '3.1.3', 'D = (T_T/T_DO) x (T_O/T_T)  [identidad algebraica]', CONCAT('D_PR=',ROUND(D_PR*100,2),'%, D_MA=',ROUND(D_MA*100,2),'%'), ROUND(D_PR*D_MA*100,2), '%', 'Descomposición de D — debe coincidir con 3.1.1' FROM calc  
        UNION ALL SELECT 10, '3.1.4', 'D = D_PR x D_MA', CONCAT('D_PR=',ROUND(D_PR*100,2),'%, D_MA=',ROUND(D_MA*100,2),'%'), ROUND(D_PR*D_MA*100,2), '%', 'Verificación — debe coincidir con D (fila 7)' FROM calc  
        UNION ALL SELECT 11, '3.1.5', 'D_PR = T_T / T_DO', CONCAT('T_T=',T_T,' min, T_DO=',T_DO,' min'), ROUND(D_PR*100,2), '%', '⚠️ Disponibilidad por Producción — SIN fórmula de referencia confirmada por el área (pendiente)' FROM calc  
        UNION ALL SELECT 12, '3.1.6', 'T_T = T_DO - T_PE  [YA NO SE USA ASÍ]', CONCAT('T_DO=',T_DO,' min, T_PE=',T_PE,' min'), CAST(T_T AS DECIMAL(18,2)), 'min', 'Tiempo de Trabajo — desde 29-ago-2026 T_T se arma como T_O+T_PI (ver fila 17); esta fila que
da solo para mostrar que la identidad sigue cerrando' FROM calc  
        UNION ALL SELECT 13, '3.1.7', 'T_PE = SUM(T_PEi)  [método directo, YA NO OFICIAL]', 'Solo eventos COMBUSTIBLE (CALIBRACION se movió a T_PP)', CAST(T_PE_combustible AS DECIMAL(18,2)), 'min', 'Diagnóstico — confirmado con el Excel real del área que 
T_PE NO se mide así, ver fila 14' FROM calc  
        UNION ALL SELECT 14, '3.1.8', 'T_PE = T_DO - (T_T) - T_TR  [MÉTODO OFICIAL desde 29-ago-2026]', CONCAT('T_DO=',T_DO,' min, T_T=',T_T,' min, T_TR=',T_TR,' min'), CAST(T_PE AS DECIMAL(18,2)), 'min', 'Paradas Externas — confirmado exacto contra el Ex
cel real del área: TPE es un residuo, no un dato medido' FROM calc  
        UNION ALL SELECT 15, '3.1.9', 'I_TR = 1 - T_TR/T_DO', CONCAT('T_TR=',T_TR,' min, T_DO=',T_DO,' min'), ROUND(I_TR*100,2), '%', 'Índice de Traslado — confirmado exacto contra el Excel real del área' FROM calc  
        UNION ALL SELECT 16, '3.1.10', 'D_MA = T_O / T_T', CONCAT('T_O=',T_O,' min, T_T=',T_T,' min'), ROUND(D_MA*100,2), '%', 'Disponibilidad por Mantenimiento — confirmado exacto contra el Excel real del área (fórmula "DMA=TO/TT" vista tal cual)' FROM c
alc  
        UNION ALL SELECT 17, '3.1.11', 'T_O = T_T - T_PI  [reordenada: T_T = T_O + T_PI, MÉTODO OFICIAL]', CONCAT('T_T=',T_T,' min, T_PI=',T_PI,' min'), CAST(T_O_der AS DECIMAL(18,2)), 'min', 'Confirmado con el Excel real del área ("TO=TT-TPI" tal cual) —
 T_T ahora se arma desde aquí, no al revés' FROM calc  
        UNION ALL SELECT 18, '3.1.12', 'T_PI = SUM(T_PIi)', 'Suma de eventos MECANICO + T_DEM_SALIDA', CAST(T_PI AS DECIMAL(18,2)), 'min', 'Paradas Internas (total)' FROM calc  
        UNION ALL SELECT 19, '3.2.1', 'R = T_NO / T_O', CONCAT('T_NO=',T_NO,' min, T_O=',T_O,' min'), ROUND(CASE WHEN T_O>0 THEN T_NO*1.0/T_O*100 ELSE 0 END,2), '%', 'Rendimiento — verificación, debe coincidir con 3.2.3' FROM calc  
        UNION ALL SELECT 20, '3.2.2', 'T_O = T_NO + T_MVO', CONCAT('T_NO=',T_NO,' min, T_MVO=',T_MVO,' min'), ROUND(T_NO+T_MVO,2), 'min', 'Verificación — debe coincidir con T_O medido' FROM calc  
        UNION ALL SELECT 21, '3.2.3', 'R = Q / (T_O x C_N x C_N)  [Opción A: doble división, decisión de negocio 29-ago-2026]', CONCAT('Q=',ROUND(Q,2),', T_O=',ROUND(T_O/60.0,2),'h, C_N=',ROUND(C_N,2),' (aplicado dos veces)'), ROUND(R*100,2), '%', 'Rendim
iento — replica la fórmula real del Excel del área (divide entre C_N dos veces), NO la ecuación 3.2.3 literal de la guía (una sola división) — ver nota en el encabezado de la vista' FROM calc  
        UNION ALL SELECT 22, '3.2.4', 'T_NO = T_O x R', CONCAT('T_O=',T_O,' min, R=',ROUND(R*100,2),'%'), CAST(T_NO AS DECIMAL(18,2)), 'min', 'Tiempo Neto de Operación' FROM calc  
        UNION ALL SELECT 23, '3.2.5', 'T_MVO = T_O - T_NO  [signo corregido, ver FIX-2]', CONCAT('T_O=',T_O,' min, T_NO=',T_NO,' min'), CAST(T_MVO AS DECIMAL(18,2)), 'min', 'Tiempo por Menor Velocidad' FROM calc  
        UNION ALL SELECT 24, '3.3.1', 'C = T_EP / T_NO', CONCAT('T_EP=',T_EP,' min, T_NO=',T_NO,' min'), CASE WHEN T_NO>0 THEN ROUND(T_EP*1.0/T_NO*100,2) ELSE NULL END, '%', 'Calidad — verificación, debe dar 100%' FROM calc  
        UNION ALL SELECT 25, '3.3.2', 'T_NO = T_EP + T_R', CONCAT('T_EP=',T_EP,' min, T_R=',T_R,' min'), ROUND(T_EP+T_R,2), 'min', 'Verificación — debe coincidir con T_NO' FROM calc  
        UNION ALL SELECT 26, '3.3.3', 'T_R = 0  [supuesto vigente de la guía]', 'Sin reprocesos registrados (política actual de la empresa)', CAST(T_R AS DECIMAL(18,2)), 'min', 'Tiempo para Retrabajos' FROM calc  
        UNION ALL SELECT 27, '3.3.4', 'T_NO = T_EP  [consecuencia de T_R=0]', CONCAT('T_EP=',T_EP,' min'), CAST(T_EP AS DECIMAL(18,2)), 'min', 'Verificación — T_NO debe = T_EP' FROM calc  
        UNION ALL SELECT 28, '3.3.5', 'C = T_EP/T_NO = 1  [resultado final bajo T_R=0]', CONCAT('T_EP=',T_EP,' min, T_NO=',T_NO,' min'), 100.00, '%', 'Calidad (resultado consistente con fila 24) — confirmado exacto contra el Excel real del área' FROM calc
  
        ORDER BY N;  
  
        RETURN;  
    END  
  
    ----------------------------------------------------------------------------------------------  
    -- @p_reporte no reconocido  
    ----------------------------------------------------------------------------------------------  
    RAISERROR('CLI547_AGM_SP_TPM_UNIFICADO: @p_reporte "%s" no es válido. Valores permitidos: DASHBOARD_OPERADOR, SEIS_PERDIDAS, RANKING_MAQUINAS, PARETO_FALLAS, TIEMPOS_PRODUCTIVOS, TABLA_DIARIA, METRICAS_RESUMEN, KPI_RESUMEN, FORMULAS_GUIA.', 16, 1, @p_
reporte);  
END  
GO
CREATE   PROCEDURE dbo.CLI547_AGM_SP_REPORTES_UNIFICADO  
    @p_modo              VARCHAR(30),  -- 'DASHBOARD_GENERAL','FALLAS_MECANICAS','OPERATIVO_CONSOLIDADO','TRACTORES_DETALLADO','RUTAS_MAQUINARIA','ALERTAS_TEMPRANAS','PERSONAL_ACTIVO'  
    @p_fecha_desde       DATE = NULL,  
    @p_fecha_hasta       DATE = NULL,  
    @p_turno             VARCHAR(10) = NULL,  
    @p_proceso_id        INT = NULL,  
    @p_tractor_id_erp    INT = NULL,  
    @p_operador_id_erp   INT = NULL,  
    @p_top               INT = 10,  
    @p_order             VARCHAR(10) = 'DESC'  
AS  
BEGIN  
    SET NOCOUNT ON;  
  
    ----------------------------------------------------------------------------------------------  
    -- VALIDACIÓN DE PARÁMETROS  
    ----------------------------------------------------------------------------------------------  
    IF @p_modo NOT IN ('DASHBOARD_GENERAL','FALLAS_MECANICAS','OPERATIVO_CONSOLIDADO','TRACTORES_DETALLADO','RUTAS_MAQUINARIA','ALERTAS_TEMPRANAS','PERSONAL_ACTIVO')  
    BEGIN  
        RAISERROR('@p_modo inválido. Valores permitidos: DASHBOARD_GENERAL, FALLAS_MECANICAS, OPERATIVO_CONSOLIDADO, TRACTORES_DETALLADO, RUTAS_MAQUINARIA, ALERTAS_TEMPRANAS, PERSONAL_ACTIVO.', 16, 1);  
        RETURN;  
    END  
  
    IF @p_fecha_desde IS NULL SET @p_fecha_desde = DATEADD(DAY, -30, CAST(GETDATE() AS DATE));  
    IF @p_fecha_hasta IS NULL SET @p_fecha_hasta = CAST(GETDATE() AS DATE);  
  
    IF @p_fecha_desde > @p_fecha_hasta  
    BEGIN  
        RAISERROR('@p_fecha_desde no puede ser mayor que @p_fecha_hasta.', 16, 1);  
        RETURN;  
    END  
  
    IF @p_order IS NULL OR UPPER(@p_order) NOT IN ('ASC', 'DESC') SET @p_order = 'DESC';  
  
    ----------------------------------------------------------------------------------------------  
    -- 1) DASHBOARD_GENERAL — KPI de alto nivel + resumen de integridad de dato  
    ----------------------------------------------------------------------------------------------  
    IF @p_modo = 'DASHBOARD_GENERAL'  
    BEGIN  
        PRINT '→ Generando Dashboard General de Indicadores TPM y Operativos.';  
        PRINT '  Fuente : dbo.v_mma_indicadores_tpm.';  
        PRINT '  GU/D/R/OEE/PTE/I_TR se calculan con SUM()-luego-dividir sobre T_xx_min (no AVG';  
        PRINT '  de porcentajes por fila) — es seguro desde [FIX-2] del SP TPM: T_NO ya es T_O×R';  
        PRINT '  capado, así que estas razones agregadas coinciden con las de la vista.';  
  
        WITH tpm_agg AS (  
            SELECT  
                SUM(T_TC_min) AS s_T_TC, SUM(T_DO_min) AS s_T_DO, SUM(T_T_min) AS s_T_T,  
                SUM(T_O_min) AS s_T_O, SUM(T_NO_min) AS s_T_NO, SUM(T_TR_min) AS s_T_TR,  
                SUM(T_PE_min) AS s_T_PE, SUM(T_PI_min) AS s_T_PI,  
                SUM(T_PP_interna_min) AS s_T_PP_int, SUM(T_PP_externa_min) AS s_T_PP_ext,   -- [AMPLIACIÓN]  
                SUM(T_DEM_SALIDA_min) AS s_T_DEM_SALIDA,                                      -- [AMPLIACIÓN]  
                SUM(T_PE_indirecto_min) AS s_T_PE_indirecto,                                  -- [AMPLIACIÓN] diagnóstico  
                SUM(CASE WHEN capacidad_nominal_valida = 0 THEN 1 ELSE 0 END) AS Registros_Sin_CN_Valida  
            FROM dbo.v_mma_indicadores_tpm  
            WHERE fecha BETWEEN @p_fecha_desde AND @p_fecha_hasta  
              AND (@p_turno IS NULL OR turno = @p_turno)  
              AND (@p_proceso_id IS NULL OR proceso_id = @p_proceso_id)  
              AND (@p_tractor_id_erp IS NULL OR tractor_id_erp = @p_tractor_id_erp)  
              AND (@p_operador_id_erp IS NULL OR operador_id_erp = @p_operador_id_erp)  
        )  
        SELECT  
            ROUND(CASE WHEN s_T_TC > 0 THEN s_T_DO * 1.0 / s_T_TC * 100 ELSE 0 END, 2) AS GU,  
            ROUND(CASE WHEN s_T_DO > 0 THEN s_T_O  * 1.0 / s_T_DO * 100 ELSE 0 END, 2) AS D,  
            ROUND(CASE WHEN s_T_O  > 0 THEN s_T_NO * 1.0 / s_T_O  * 100 ELSE 0 END, 2) AS R,  
            ROUND(CASE WHEN s_T_DO > 0 THEN s_T_NO * 1.0 / s_T_DO * 100 ELSE 0 END, 2) AS OEE,  
    ROUND(CASE WHEN s_T_TC > 0 THEN s_T_NO * 1.0 / s_T_TC * 100 ELSE 0 END, 2) AS PTE,  
            ROUND(CASE WHEN s_T_DO > 0 THEN (1 - s_T_TR * 1.0 / s_T_DO) * 100 ELSE 0 END, 2) AS I_TR,  
            ROUND(s_T_DO / 60.0, 2) AS Disponible_Hrs,  
            ROUND(s_T_O  / 60.0, 2) AS Operacion_Hrs,  
            ROUND(s_T_PE / 60.0, 2) AS Paro_Externo_Hrs,  
            ROUND(s_T_PI / 60.0, 2) AS Paro_Interno_Hrs,  
            ROUND(s_T_PP_int / 60.0, 2) AS Paro_Programado_Interno_Hrs,      -- [AMPLIACIÓN]  
            ROUND(s_T_PP_ext / 60.0, 2) AS Paro_Programado_Externo_Hrs,      -- [AMPLIACIÓN]  
            ROUND(s_T_DEM_SALIDA / 60.0, 2) AS Demora_Salida_Hrs,            -- [AMPLIACIÓN]  
            ROUND(s_T_PE_indirecto / 60.0, 2) AS Paro_Externo_Indirecto_Hrs, -- [AMPLIACIÓN] diagnóstico  
            Registros_Sin_CN_Valida  
        FROM tpm_agg;  
  
        RETURN;  
    END  
  
    ----------------------------------------------------------------------------------------------  
    -- 2) FALLAS_MECANICAS — Dashboard de fallas (1ª pérdida)  
    ----------------------------------------------------------------------------------------------  
    IF @p_modo = 'FALLAS_MECANICAS'  
    BEGIN  
        PRINT '→ Generando Dashboard de Fallas Mecánicas (1ª pérdida).';  
        PRINT '  [BUG-4] Filtro de fecha cambiado a rd.fecha (fecha operativa del turno), no';  
        PRINT '          pe.created_at (fecha de carga en el sistema).';  
        PRINT '  [BUG-1] Corregido el cálculo de TiempoPromedio (SET...FROM no es válido en T-SQL).';  
  
        CREATE TABLE #fallas_mec (  
            id                  UNIQUEIDENTIFIER,  
            registro_id         UNIQUEIDENTIFIER,  
            falla_nombre        VARCHAR(200),  
            estado_falla        VARCHAR(30),  
            created_at          DATETIME2,  
            completado_at       DATETIME2,  
            hora_inicio         TIME,  
            hora_fin            TIME,  
            duracion_min        INT,  
            tractor_id          INT,  
            tractor_codigo      VARCHAR(100),  
            operador_nombre     VARCHAR(300),  
            supervisor_nombre   VARCHAR(300),  
            mecanico_nombre     VARCHAR(300),  
            categoria           VARCHAR(30),  
            aplicacion          VARCHAR(200),  
            fecha               DATE          -- [BUG-4] ahora es rd.fecha, no CAST(created_at)  
        );  
  
        INSERT INTO #fallas_mec  
        SELECT  
            pe.id, pe.registro_id,  
            COALESCE(fm.nombre, pe.falla_mecanica_nombre) AS falla_nombre,  
            pe.estado_falla, pe.created_at, pe.completado_at,  
            pe.hora_inicio_real, pe.hora_fin_real, pe.duracion_min,  
            rd.tractor_id_erp, rd.codigo_tractor_snapshot,  
            rd.nombre_operador_snapshot, rd.nombre_supervisor_snapshot, pe.mecanico_nombre,  
            fm.categoria, fm.aplicacion,  
            rd.fecha   -- [BUG-4]  
        FROM dbo.CLI547_AGM_MMA_PAROS_EQUIPOS pe  
        INNER JOIN dbo.CLI547_AGM_MMA_TIPOS_PARO tp ON tp.id = pe.tipo_paro_id  
        LEFT JOIN dbo.CLI547_AGM_MMA_FALLAS_MECANICAS fm ON fm.id = pe.falla_mecanica_id  
        LEFT JOIN dbo.CLI547_AGM_MMA_REGISTROS_DIARIOS rd ON rd.id = pe.registro_id  
        WHERE tp.codigo = 'MECANICO'  
          AND rd.fecha BETWEEN @p_fecha_desde AND @p_fecha_hasta   -- [BUG-4]  
          AND (@p_turno IS NULL OR rd.turno = @p_turno)  
          AND (@p_proceso_id IS NULL OR rd.proceso_id = @p_proceso_id)  
          AND (@p_tractor_id_erp IS NULL OR rd.tractor_id_erp = @p_tractor_id_erp)  
          AND (@p_operador_id_erp IS NULL OR rd.operador_id_erp = @p_operador_id_erp);  
  
        DECLARE @TotalFallas INT, @Pendientes INT, @Resueltas INT;  
        DECLARE @TasaResolucion DECIMAL(10,2), @TiempoPromedio DECIMAL(10,2);  
  
        SELECT  
            @TotalFallas = COUNT(*),  
            @Pendientes  = SUM(CASE WHEN estado_falla = 'pendiente' THEN 1 ELSE 0 END),  
            @Resueltas   = SUM(CASE WHEN estado_falla = 'resuelto'  THEN 1 ELSE 0 END)  
        FROM #fallas_mec;  
  
        SET @TasaResolucion = ROUND(100.0 * @Resueltas / NULLIF(@TotalFallas, 0), 2);  
  
        -- [BUG-1] corregido: SELECT @var = ... FROM tabla (no "SET ... FROM")  
        SELECT @TiempoPromedio = ROUND(AVG(CASE WHEN estado_falla = 'resuelto' AND duracion_min IS NOT NULL THEN duracion_min * 1.0 ELSE NULL END), 2)  
        FROM #fallas_mec;  
  
        -- 2.1 Métricas generales  
        SELECT 'TotalFallas' AS Clave, @TotalFallas AS Valor, NULL AS Extra  
        UNION ALL SELECT 'Pendientes', @Pendientes, NULL  
        UNION ALL SELECT 'Resueltas', @Resueltas, NULL  
        UNION ALL SELECT 'TasaResolucion', @TasaResolucion, NULL  
        UNION ALL SELECT 'TiempoPromedio_min', @TiempoPromedio, NULL;  
  
        -- 2.2 Pareto de causas (Top N) — con % acumulado (ver [FIX-5] del SP TPM: SUM() OVER,  
        -- no "quirky update", para que el acumulado esté garantizado en el orden correcto)  
        WITH causas AS (  
            SELECT  
                COALESCE(falla_nombre, 'Sin clasificar') AS Causa,  
                COUNT(*) AS Ocurrencias  
            FROM #fallas_mec  
            GROUP BY COALESCE(falla_nombre, 'Sin clasificar')  
        ),  
        con_acumulado AS (  
            SELECT *,  
                SUM(Ocurrencias) OVER (ORDER BY Ocurrencias DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS Acumulado,  
                SUM(Ocurrencias) OVER () AS Total  
            FROM causas  
        )  
        SELECT TOP (@p_top)  
            Causa, Ocurrencias,  
            ROUND(Ocurrencias * 100.0 / NULLIF(Total, 0), 2) AS Porcentaje,  
            ROUND(Acumulado * 100.0 / NULLIF(Total, 0), 1) AS Porcentaje_Acumulado  
        FROM con_acumulado  
        ORDER BY Ocurrencias DESC;  
  
        -- 2.3 Ranking de equipos (Top N)  
        SELECT TOP (@p_top)  
            COALESCE(tractor_codigo, 'N/A') AS Tractor,  
            COUNT(*) AS TotalFallas,  
            ROUND(SUM(ISNULL(duracion_min, 0)) / 60.0, 2) AS HorasParadas  
        FROM #fallas_mec  
        GROUP BY COALESCE(tractor_codigo, 'N/A')  
        ORDER BY TotalFallas DESC;  
  
        -- 2.4 Detalle de fallas  
        SELECT  
            id, falla_nombre AS Falla, estado_falla AS Estado, fecha AS Fecha,  
            hora_inicio AS HoraInicio, hora_fin AS HoraFin, duracion_min AS DuracionMin,  
            tractor_codigo AS Tractor, operador_nombre AS Operador,  
            supervisor_nombre AS Supervisor, mecanico_nombre AS Mecanico,  
            categoria AS Categoria, aplicacion AS Aplicacion,  
            created_at AS FechaCarga   -- se conserva para auditoría (cuándo se registró vs. cuándo ocurrió)  
        FROM #fallas_mec  
        ORDER BY created_at DESC;  
  
        DROP TABLE #fallas_mec;  
        RETURN;  
    END  
  
    ----------------------------------------------------------------------------------------------  
    -- 3) OPERATIVO_CONSOLIDADO — Detalle diario con indicadores TPM completos  
    ----------------------------------------------------------------------------------------------  
    IF @p_modo = 'OPERATIVO_CONSOLIDADO'  
    BEGIN  
        PRINT '→ Generando Análisis Operativo Consolidado con indicadores TPM.';  
        PRINT '  [AMPLIACIÓN] Se agregan las columnas de detalle que ya calcula la vista:';  
        PRINT '  T_PP_interna/externa, T_PI_mecanico/T_DEM_SALIDA, T_PE_indirecto (diagnóstico)';  
        PRINT '  y capacidad_nominal_valida — nivel de detalle propio de un reporte de auditoría.';  
  
        SELECT  
            i.fecha, i.turno, i.proceso_id, p.nombre AS Proceso,  
            i.tractor_id_erp, r.codigo_tractor_snapshot AS Tractor,  
            i.operador_id_erp, r.nombre_operador_snapshot AS Operador,  
            r.nombre_supervisor_snapshot AS Supervisor, r.estado AS EstadoRegistro,  
  
            i.T_TC_min, i.T_PP_min, i.T_PP_interna_min, i.T_PP_externa_min,   -- [AMPLIACIÓN]  
            i.T_DO_min, i.T_TR_min,  
            i.T_PE_min, i.T_PE_indirecto_min,                                  -- [AMPLIACIÓN] diagnóstico  
            i.T_PI_min, i.T_PI_mecanico_min, i.T_DEM_SALIDA_min,               -- [AMPLIACIÓN]  
            i.T_O_min, i.T_NO_min, i.T_MVO_min,  
  
            ROUND(i.GU * 100, 2)    AS GU,  
            ROUND(i.D_PR * 100, 2)  AS D_PR,  
            ROUND(i.D_MA * 100, 2)  AS D_MA,  
            ROUND(i.D * 100, 2)     AS D,  
            ROUND(i.R * 100, 2)     AS R,  
            ROUND(i.EGE * 100, 2)   AS OEE,  
            ROUND(i.PTE * 100, 2)   AS PTE,  
            ROUND(i.I_TR * 100, 2)  AS I_TR,  
  
            i.Q AS Produccion,  
            i.capacidad_nominal AS C_N,  
            i.capacidad_nominal_valida,                                        -- [AMPLIACIÓN]  
            ROUND(i.Q / NULLIF(i.T_O_min / 60.0, 0), 2) AS Rendimiento_Real,  
            ROUND(((i.Q / NULLIF(i.T_O_min / 60.0, 0)) / NULLIF(i.capacidad_nominal, 0) - 1) * 100, 2) AS Desviacion_Rendimiento,  
  
            -- Alertas — umbrales de NEGOCIO (no de la guía TPM, que solo dice "tender a 100%")  
            CASE  
                WHEN i.capacidad_nominal_valida = 0 THEN 'Sin Capacidad Nominal configurada'  
                WHEN ROUND(i.R * 100, 2) < 80 THEN 'Rendimiento Bajo'  
                WHEN ROUND(i.I_TR * 100, 2) < 80 THEN 'Alto Traslado'  
                WHEN i.T_PI_min > 60 THEN 'Paros Internos > 1h'  
                ELSE 'OK'  
            END AS Alerta  
        FROM dbo.v_mma_indicadores_tpm i  
        LEFT JOIN dbo.CLI547_AGM_MMA_REGISTROS_DIARIOS r ON r.id = i.registro_id  
        LEFT JOIN dbo.CLI547_AGM_MMA_PROCESOS p ON p.id = r.proceso_id  
        WHERE i.fecha BETWEEN @p_fecha_desde AND @p_fecha_hasta  
          AND (@p_turno IS NULL OR i.turno = @p_turno)  
          AND (@p_proceso_id IS NULL OR i.proceso_id = @p_proceso_id)  
          AND (@p_tractor_id_erp IS NULL OR i.tractor_id_erp = @p_tractor_id_erp)  
          AND (@p_operador_id_erp IS NULL OR i.operador_id_erp = @p_operador_id_erp)  
        ORDER BY i.fecha DESC;  
  
        RETURN;  
    END  
  
    ----------------------------------------------------------------------------------------------  
    -- 4) TRACTORES_DETALLADO — Checklist, horómetros y tiempos de turno por tractor  
    ----------------------------------------------------------------------------------------------  
    IF @p_modo = 'TRACTORES_DETALLADO'  
    BEGIN  
        PRINT '→ Generando Reporte Detallado de Tractores.';  
        PRINT '  [BUG-2] Ya no se inventa Capacidad Nominal=1.0 cuando falta el dato — se toma';  
        PRINT '          capacidad_nominal / capacidad_nominal_valida directo de la vista TPM.';  
        PRINT '  [BUG-3] I_TR ya no se recalcula a mano — se usa i.I_TR (mismo que el resto de';  
        PRINT '          reportes, ya validado contra el reporte del área).';  
        PRINT '  [BUG-5] Se agregan los filtros @p_turno y @p_proceso_id, que antes no aplicaban.';  
  
        CREATE TABLE #base_tractores (  
            registro_id         UNIQUEIDENTIFIER,  
            numero_registro     VARCHAR(50),  
            fecha               DATE,  
            turno               VARCHAR(10),  
            estado              VARCHAR(20),  
            proceso_id          INT,  
            proceso_nombre      VARCHAR(100),  
            cultivo_nombre      VARCHAR(100),  
            operador_id         INT,  
            operador_nombre     VARCHAR(300),  
            supervisor_nombre   VARCHAR(300),  
            tractor_id          INT,  
            tractor_codigo      VARCHAR(100),  
            implemento_codigo   VARCHAR(100),  
            horas_tractor       DECIMAL(10,2),  
            horas_implemento    DECIMAL(10,2),  
            hectareas           DECIMAL(10,2)  
        );  
  
        INSERT INTO #base_tractores  
        SELECT  
            rd.id, rd.numero_registro, rd.fecha, rd.turno, rd.estado, rd.proceso_id, p.nombre,  
            rd.nombre_cultivo_snapshot, rd.operador_id_erp, rd.nombre_operador_snapshot,  
            rd.nombre_supervisor_snapshot, rd.tractor_id_erp, rd.codigo_tractor_snapshot,  
            rd.codigo_implemento_snapshot,  
            ISNULL(h.horas_tractor, 0), ISNULL(h.horas_implemento, 0),  
            ISNULL((SELECT SUM(area_trabajada_ha) FROM dbo.CLI547_AGM_MMA_REGISTROS_LOTES WHERE registro_id = rd.id), 0)  
            -- [BUG-2] Se elimina "ISNULL(p.rendimiento_teorico, 1.0)" de aquí — ver capacidad_nominal  
            -- tomado de la vista en el SELECT final.  
        FROM dbo.CLI547_AGM_MMA_REGISTROS_DIARIOS rd  
        LEFT JOIN dbo.CLI547_AGM_MMA_PROCESOS p ON p.id = rd.proceso_id  
        LEFT JOIN dbo.CLI547_AGM_MMA_HOROMETROS h ON h.registro_id = rd.id  
        WHERE rd.tipo_registro = 'tractor'  
          AND rd.fecha BETWEEN @p_fecha_desde AND @p_fecha_hasta  
          AND (@p_turno IS NULL OR rd.turno = @p_turno)                 -- [BUG-5]  
          AND (@p_proceso_id IS NULL OR rd.proceso_id = @p_proceso_id)  -- [BUG-5]  
          AND (@p_tractor_id_erp IS NULL OR rd.tractor_id_erp = @p_tractor_id_erp)  
          AND (@p_operador_id_erp IS NULL OR rd.operador_id_erp = @p_operador_id_erp);  
  
        SELECT  
            b.*,  
            CONVERT(VARCHAR(8), tt.hora_salida_taller, 108) AS Hora_Salida_Taller,  
            CONVERT(VARCHAR(8), tt.hora_llegada_punto, 108) AS Hora_Llegada_Punto,  
            CONVERT(VARCHAR(8), tt.hora_salida_punto, 108) AS Hora_Salida_Punto,  
            CONVERT(VARCHAR(8), tt.hora_llegada_taller, 108) AS Hora_Llegada_Taller,  
            ISNULL(tt.minutos_efectivos, 0) AS Minutos_Efectivos,  
            i.T_DO_min, i.T_TR_min,  
            i.T_DEM_SALIDA_min,                                    -- [AMPLIACIÓN]  
            i.capacidad_nominal AS C_N,                            -- [BUG-2] desde la vista, NULL-safe  
            i.capacidad_nominal_valida,                            -- [BUG-2]  
            ROUND(i.I_TR * 100, 2) AS I_TR                         -- [BUG-3] directo de la vista  
        FROM #base_tractores b  
        LEFT JOIN dbo.CLI547_AGM_MMA_TIEMPOS_TURNO tt ON tt.registro_id = b.registro_id  
        LEFT JOIN dbo.v_mma_indicadores_tpm i ON i.registro_id = b.registro_id  
        ORDER BY b.fecha DESC;  
  
        DROP TABLE #base_tractores;  
        RETURN;  
    END  
  
    ----------------------------------------------------------------------------------------------  
    -- 5) RUTAS_MAQUINARIA — Trazabilidad de rutas GPS  
    ----------------------------------------------------------------------------------------------  
    IF @p_modo = 'RUTAS_MAQUINARIA'  
    BEGIN  
        PRINT '→ Generando Reporte de Rutas de Maquinaria.';  
        PRINT '  [BUG-6] ruta_geog convertido a texto (.STAsText()) para que sea consumible por';  
        PRINT '          el frontend/Excel — AJUSTAR AQUÍ si la columna no es tipo GEOGRAPHY.';  
        PRINT '  [BUG-5] Se agregan los filtros @p_turno y @p_proceso_id.';  
  
        SELECT  
            rm.id, rm.registro_id, rm.fecha, rm.operador_id_erp, rm.tractor_id_erp, rm.proceso_id,  
            rm.total_puntos, rm.longitud_km,  
            rm.ruta_geog.STAsText() AS Ruta_WKT,   -- [BUG-6] AJUSTAR AQUÍ si no es GEOGRAPHY  
            rm.sincronizado_at,  
            r.codigo_tractor_snapshot AS Tractor,  
            r.nombre_operador_snapshot AS Operador,  
            p.nombre AS Proceso  
        FROM dbo.CLI547_AGM_Ruta_maquinaria rm  
        LEFT JOIN dbo.CLI547_AGM_MMA_REGISTROS_DIARIOS r ON r.id = rm.registro_id  
        LEFT JOIN dbo.CLI547_AGM_MMA_PROCESOS p ON p.id = r.proceso_id  
        WHERE rm.fecha BETWEEN @p_fecha_desde AND @p_fecha_hasta  
          AND (@p_turno IS NULL OR r.turno = @p_turno)              -- [BUG-5]  
          AND (@p_proceso_id IS NULL OR rm.proceso_id = @p_proceso_id) -- [BUG-5]  
          AND (@p_tractor_id_erp IS NULL OR rm.tractor_id_erp = @p_tractor_id_erp)  
          AND (@p_operador_id_erp IS NULL OR rm.operador_id_erp = @p_operador_id_erp)  
        ORDER BY rm.fecha DESC, rm.sincronizado_at DESC;  
  
        RETURN;  
    END  
  
    ----------------------------------------------------------------------------------------------  
    -- 6) ALERTAS_TEMPRANAS — Cuellos de botella para acción temprana (con responsable sugerido)  
    ----------------------------------------------------------------------------------------------  
    IF @p_modo = 'ALERTAS_TEMPRANAS'  
    BEGIN  
        PRINT '→ Generando Alertas Tempranas de Cuellos de Botella.';  
        PRINT '  [AMPLIACIÓN] Se agrega Responsable_Sugerido (GIM/GAG/Conjunto), consistente con';  
        PRINT '  el mapeo de responsabilidad usado en la pestaña TPM — para que la alerta diga';  
        PRINT '  no solo "qué está mal" sino "a quién avisar".';  
  
        WITH alertas AS (  
            SELECT  
                i.fecha, r.codigo_tractor_snapshot AS Tractor, r.nombre_operador_snapshot AS Operador,  
                p.nombre AS Proceso,  
                ROUND(i.R * 100, 2) AS R, ROUND(i.I_TR * 100, 2) AS I_TR, ROUND(i.D * 100, 2) AS D,  
                i.T_PI_min / 60.0 AS Horas_PI, i.T_PE_min / 60.0 AS Horas_PE,  
                i.capacidad_nominal_valida,  
                CASE  
                    WHEN i.capacidad_nominal_valida = 0 THEN 'Capacidad Nominal no configurada'  
                    WHEN ROUND(i.R * 100, 2) < 80 THEN 'Rendimiento Bajo (<80%)'  
                    WHEN ROUND(i.I_TR * 100, 2) < 80 THEN 'Índice de Traslado Bajo (<80%)'  
                    WHEN ROUND(i.D * 100, 2) < 70 THEN 'Disponibilidad Baja (<70%)'  
                    WHEN i.T_PI_min > 60 THEN 'Paros Internos > 1 hora'  
                    WHEN i.T_PE_min > 60 THEN 'Paros Externos > 1 hora'  
                    ELSE NULL  
                END AS Alerta,  
                CASE  
                    WHEN i.capacidad_nominal_valida = 0 THEN 'GIM (Mantenimiento) — dato de catálogo'  
                    WHEN ROUND(i.R * 100, 2) < 80 THEN 'Conjunto (Producción + Mantenimiento)'  
                    WHEN ROUND(i.I_TR * 100, 2) < 80 THEN 'GAG (Producción)'  
                    WHEN ROUND(i.D * 100, 2) < 70 THEN 'Conjunto'  
                    WHEN i.T_PI_min > 60 THEN 'GIM (Mantenimiento)'  
                    WHEN i.T_PE_min > 60 THEN 'GAG (Producción)'  
                    ELSE NULL  
                END AS Responsable_Sugerido,   -- [AMPLIACIÓN]  
                i.registro_id  
            FROM dbo.v_mma_indicadores_tpm i  
            INNER JOIN dbo.CLI547_AGM_MMA_REGISTROS_DIARIOS r ON r.id = i.registro_id  
            LEFT JOIN dbo.CLI547_AGM_MMA_PROCESOS p ON p.id = r.proceso_id  
            WHERE i.fecha BETWEEN @p_fecha_desde AND @p_fecha_hasta  
              AND (@p_turno IS NULL OR i.turno = @p_turno)  
              AND (@p_proceso_id IS NULL OR i.proceso_id = @p_proceso_id)  
              AND (@p_tractor_id_erp IS NULL OR i.tractor_id_erp = @p_tractor_id_erp)  
              AND (@p_operador_id_erp IS NULL OR i.operador_id_erp = @p_operador_id_erp)  
        )  
        SELECT fecha, Tractor, Operador, Proceso, R, I_TR, D, Horas_PI, Horas_PE,  
               Alerta, Responsable_Sugerido  
        FROM alertas  
        WHERE Alerta IS NOT NULL  
        ORDER BY fecha DESC;  
  
        RETURN;  
    END  
  
    ----------------------------------------------------------------------------------------------  
    -- 7) PERSONAL_ACTIVO — [NUEVO] Operadores, supervisores y mecánicos activos en el período,  
    --    extraídos de las jornadas (CLI547_AGM_MMA_REGISTROS_DIARIOS) y de las fallas atendidas.  
    ----------------------------------------------------------------------------------------------  
    IF @p_modo = 'PERSONAL_ACTIVO'  
    BEGIN  
        PRINT '→ Generando Personal Activo del período (operadores, supervisores, mecánicos).';  
        PRINT '  Fuente : CLI547_AGM_MMA_REGISTROS_DIARIOS (operadores/supervisores) +';  
        PRINT '           CLI547_AGM_MMA_PAROS_EQUIPOS (mecánicos que atendieron fallas).';  
        PRINT '  LIMITACIÓN: no hay columnas de id para supervisor ni mecánico en el esquema';  
        PRINT '  visto hasta ahora — se identifican por nombre (snapshot), no por id. Si existe';  
        PRINT '  un id real, reemplazar el agrupamiento por nombre por el id correspondiente.';  
  
        SELECT  
            'Operador' AS Rol,  
            operador_id_erp AS PersonaId,  
            MAX(nombre_operador_snapshot) AS Nombre,  
            COUNT(DISTINCT id) AS Turnos,  
            COUNT(DISTINCT tractor_id_erp) AS TractoresDistintos,  
            COUNT(DISTINCT proceso_id) AS ProcesosDistintos,  
            COUNT(DISTINCT fecha) AS DiasActivos  
        FROM dbo.CLI547_AGM_MMA_REGISTROS_DIARIOS  
        WHERE fecha BETWEEN @p_fecha_desde AND @p_fecha_hasta  
          AND estado IN ('completado', 'aprobado')  
          AND operador_id_erp IS NOT NULL  
          AND (@p_turno IS NULL OR turno = @p_turno)  
          AND (@p_proceso_id IS NULL OR proceso_id = @p_proceso_id)  
          AND (@p_tractor_id_erp IS NULL OR tractor_id_erp = @p_tractor_id_erp)  
          AND (@p_operador_id_erp IS NULL OR operador_id_erp = @p_operador_id_erp)  
        GROUP BY operador_id_erp  
  
        UNION ALL  
  
        SELECT  
            'Supervisor', NULL, nombre_supervisor_snapshot,  
            COUNT(DISTINCT id), COUNT(DISTINCT tractor_id_erp),  
            COUNT(DISTINCT proceso_id), COUNT(DISTINCT fecha)  
        FROM dbo.CLI547_AGM_MMA_REGISTROS_DIARIOS  
        WHERE fecha BETWEEN @p_fecha_desde AND @p_fecha_hasta  
          AND estado IN ('completado', 'aprobado')  
          AND nombre_supervisor_snapshot IS NOT NULL  
          AND (@p_turno IS NULL OR turno = @p_turno)  
          AND (@p_proceso_id IS NULL OR proceso_id = @p_proceso_id)  
          AND (@p_tractor_id_erp IS NULL OR tractor_id_erp = @p_tractor_id_erp)  
          AND (@p_operador_id_erp IS NULL OR operador_id_erp = @p_operador_id_erp)  
        GROUP BY nombre_supervisor_snapshot  
  
        UNION ALL  
  
        SELECT  
            'Mecánico', NULL, pe.mecanico_nombre,  
            COUNT(DISTINCT pe.id), COUNT(DISTINCT rd.tractor_id_erp),  
            COUNT(DISTINCT rd.proceso_id), COUNT(DISTINCT rd.fecha)  
        FROM dbo.CLI547_AGM_MMA_PAROS_EQUIPOS pe  
        INNER JOIN dbo.CLI547_AGM_MMA_TIPOS_PARO tp ON tp.id = pe.tipo_paro_id AND tp.codigo = 'MECANICO'  
        LEFT JOIN dbo.CLI547_AGM_MMA_REGISTROS_DIARIOS rd ON rd.id = pe.registro_id  
        WHERE pe.mecanico_nombre IS NOT NULL  
          AND rd.fecha BETWEEN @p_fecha_desde AND @p_fecha_hasta  
          AND (@p_turno IS NULL OR rd.turno = @p_turno)  
          AND (@p_proceso_id IS NULL OR rd.proceso_id = @p_proceso_id)  
          AND (@p_tractor_id_erp IS NULL OR rd.tractor_id_erp = @p_tractor_id_erp)  
        GROUP BY pe.mecanico_nombre  
  
        ORDER BY Rol, Nombre;  
  
        RETURN;  
    END  
END;  
GO


















































-- #############################################################################
-- #                                                                           #
-- #   BLOQUE GPS · TRAZABILIDAD DE RUTAS DE MAQUINARIA (modelo v3)            #
-- #                                                                           #
-- #############################################################################
--
-- QUÉ AGREGA ESTE BLOQUE
--   Todo el modelo de trazabilidad GPS: tablas de ruta y eventos, cálculo de
--   cobertura, SPs de consulta/exportación KML y vistas para QGIS.
--
--   El SP CLI547_AGMSP_MMA_SINCRONIZAR_OFFLINE que consume estas tablas ya está
--   definido más arriba en este mismo archivo (sección de procedimientos). Aquí
--   NO se repite: una sola definición por objeto.
--
-- POR QUÉ ESTÁ AL FINAL
--   SQL Server usa resolución diferida de nombres: un procedimiento se crea
--   aunque las tablas que referencia todavía no existan, y solo falla al
--   ejecutarse. Por eso el SP de sincronización puede estar antes que estas
--   tablas sin problema. Las vistas, en cambio, sí validan al crearse, y por
--   eso van al final del bloque.
--
-- MODELO EN UNA FRASE
--   El APK captura puntos GPS cada 5 s en SQLite, los clasifica contra los
--   polígonos de sublote (point-in-polygon offline) y, al CERRAR TURNO, envía
--   la jornada como UNA geometría WKT más sus métricas y eventos ya derivados.
--   El servidor guarda una fila por jornada en CLI547_AGM_Ruta_maquinaria como
--   tipo GEOGRAPHY, más los eventos en sus tablas hijas.
--
--   El modelo v2 (una fila por punto, tabla CLI547_AGM_Punto_gps_maquinaria,
--   SP CLI547_AGMSP_MMA_REGISTRAR_PUNTOS_GPS) está RETIRADO. Si esa tabla
--   todavía existe en el servidor, ya no recibe datos y puede eliminarse.
--
-- ORDEN INTERNO (no reordenar: hay dependencias)
--   1. Tabla CLI547_AGM_Ruta_maquinaria + índices + FK
--   2. Columnas de analytics + CHECK constraints
--   3. Tabla normalizada de sublotes + backfill del JSON histórico
--   5. SPs de consulta para mapa y exportación KML
--   6. Vistas para QGIS (rutas y sublotes)
--   7. Modelo de eventos: visitas, paradas, tramos + ancho de labor
--   8. SP de cálculo de cobertura (hectáreas trabajadas y % de avance)
--   9. Capas de eventos para QGIS + timeline de jornada
--
--   (La sección 4 era el SP de sincronización, que vive más arriba. Se conserva
--    la numeración original para que los comentarios internos que se refieren a
--    "la SECCIÓN N" sigan siendo correctos.)
--
-- REQUISITO DE VERSIÓN
--   SQL Server 2016 o superior (OPENJSON, ISJSON, JSON_QUERY).
--
-- DESPUÉS DE INSTALAR
--   · Poblar dbo.CLI547_AGM_MMA_IMPLEMENTOS_ANCHO (sección 7.4) o el cálculo
--     de cobertura no podrá correr.
--   · Ejecutar CLI547_AGMSP_MMA_CALCULAR_COBERTURA después de cada sync
--     (a mano o como job de SQL Agent).
--
-- IDEMPOTENTE
--   Todo el bloque se puede re-ejecutar sin efectos secundarios.
--
-- #############################################################################

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
