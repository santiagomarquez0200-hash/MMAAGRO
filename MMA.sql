------------DATOS MMA----------------
  -- =====================================================================
-- SCRIPT COMPLETO DE CREACIÓN DE TABLAS, ÍNDICES, FK Y DATOS MAESTROS
-- MÓDULO MMA (MAQUINARIA AGRÍCOLA) – ESQUEMA dbo
-- GENERADO A PARTIR DE LA ESTRUCTURA ACTUAL EN PRODUCCIÓN
-- =====================================================================
CREATE INDEX idx_paros_equipos_registro 
    ON dbo.CLI547_AGM_MMA_PAROS_EQUIPOS(registro_id);

CREATE INDEX idx_paros_vehiculo_registro 
    ON dbo.CLI547_AGM_MMA_PAROS_VEHICULO(registro_id);

USE ERPHispatec
UPDATE dbo.CLI547_AGM_MMA_CHECKLIST_ITEMS_CATALOGO
SET nombre = CASE id
    -- Categoría 1
    WHEN 1  THEN 'Nivel de aceite del motor'
    WHEN 2  THEN 'Nivel de refrigerante del motor'
    WHEN 3  THEN 'Nivel de aceite hidráulico del tractor'
    WHEN 4  THEN 'Batería y sus bornes'
    WHEN 5  THEN 'Faja de alternador'
    WHEN 6  THEN 'Espejos del tractor'
    WHEN 7  THEN 'Claxon'
    WHEN 8  THEN 'Extintor'
    WHEN 9  THEN 'Nivel de aceite en los reductores delante y post.'
    WHEN 10 THEN 'Nivel de aceite del tren delantero'
    WHEN 11 THEN 'Templadores de los brazos de levante y pines/seguros'
    WHEN 12 THEN 'Llantas y ajuste de tuercas de rueda'
    WHEN 13 THEN 'Cinturón de seguridad y Protección antivuelco'
    WHEN 14 THEN 'Luces del tractor'
    WHEN 15 THEN 'Alarma de retroceso'
    WHEN 16 THEN 'Tacos de seguridad'

    -- Categoría 2
    WHEN 17 THEN 'Nivel de  aceite hidráulico del implemento'
    WHEN 18 THEN 'Nivel de aceite de la caja multiplicadora'
    WHEN 19 THEN 'Llantas y ajuste de tuercas de rueda'
    WHEN 20 THEN 'Barra de tiro, pines y seguro'
    WHEN 21 THEN 'Tanque de productos'
    WHEN 22 THEN 'Cardan y su Protector'
    WHEN 23 THEN 'Mangueras hidráulicas'
    WHEN 24 THEN 'Mangueras agroquímicos'
    WHEN 25 THEN 'Fajas de transmisión'
    WHEN 26 THEN 'Bombines hidráulicos'
    WHEN 27 THEN 'Comando hidráulico'
    WHEN 28 THEN 'Comando eléctrico'
    WHEN 29 THEN 'Luces del implemento'
    WHEN 30 THEN 'Horómetro'
    WHEN 31 THEN 'Techo y soportes'
    WHEN 32 THEN 'Soporte frontal y templadores'
END
WHERE tipo_registro = 'tractor'
  AND id BETWEEN 1 AND 32;


USE [ERPHispatec];  -- Ajustar según el nombre de la base de datos
GO

SET NOCOUNT ON;
GOc

-- =====================================================================
-- 1. TABLAS DE CATÁLOGO (MAESTROS)
-- =====================================================================

SELECT * FROM CLI547_AGM_MMA_PROCESOS

CLI547_AGM_SP_MMA_DASHBOARD_RENDIMIENTO_OPERADOR  
UPDATE CLI547_AGM_MMA_PROCESOS
SET rendimiento_teorico = 2.50
WHERE id= 1;
SELECT * FROM cultivos where Descripcion  like  '%B-02%'

-- 1.1 PROCESOS
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA='dbo' AND TABLE_NAME='CLI547_AGM_MMA_PROCESOS')
BEGIN
    CREATE TABLE dbo.CLI547_AGM_MMA_PROCESOS (
        id                            INT IDENTITY(1,1) NOT NULL,
        codigo                        VARCHAR(20)   NOT NULL,
        nombre                        VARCHAR(100)  NOT NULL,
        descripcion                   VARCHAR(MAX)  NULL,
        requiere_bines                BIT           NOT NULL CONSTRAINT DF_PROCESOS_REQUIERE_BINES DEFAULT 0,
        especie_botanica_erp_id       INT           NULL,
        activo                        BIT           NOT NULL CONSTRAINT DF_PROCESOS_ACTIVO DEFAULT 1,
        created_at                    DATETIME2     NOT NULL CONSTRAINT DF_PROCESOS_CREATED DEFAULT GETDATE(),
        updated_at                    DATETIME2     NOT NULL CONSTRAINT DF_PROCESOS_UPDATED DEFAULT GETDATE(),
        requiere_sublabores           BIT           NOT NULL CONSTRAINT DF_PROCESOS_REQ_SUBLABORES DEFAULT 0,
        tipo_registro                 VARCHAR(20)   NOT NULL CONSTRAINT DF_PROCESOS_TIPO_REG DEFAULT 'tractor',
        rendimiento_teorico_bins_por_hora DECIMAL(10,2) NULL,
        rendimiento_teorico           DECIMAL(10,2) NULL,
        CONSTRAINT PK_PROCESOS PRIMARY KEY CLUSTERED (id),
        CONSTRAINT UQ_PROCESOS_CODIGO UNIQUE (codigo),
        CONSTRAINT UQ_PROCESOS_NOMBRE UNIQUE (nombre),
        CONSTRAINT CK_PROCESOS_TIPO_REG CHECK (tipo_registro IN ('tractor','vehiculo'))
    );
END
GO

-- 1.2 SUBPROCESOS
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA='dbo' AND TABLE_NAME='CLI547_AGM_MMA_SUBPROCESOS')
BEGIN
    CREATE TABLE dbo.CLI547_AGM_MMA_SUBPROCESOS (
        id           INT IDENTITY(1,1) NOT NULL,
        proceso_id   INT NOT NULL,
        nombre       NVARCHAR(200) NOT NULL,
        codigo       VARCHAR(50) NOT NULL,
        descripcion  NVARCHAR(500) NULL,
        activo       BIT NOT NULL CONSTRAINT DF_SUBPROCESOS_ACTIVO DEFAULT 1,
        created_at   DATETIME2 NOT NULL CONSTRAINT DF_SUBPROCESOS_CREATED DEFAULT GETUTCDATE(),
        CONSTRAINT PK_SUBPROCESOS PRIMARY KEY CLUSTERED (id),
        CONSTRAINT FK_SUBPROCESOS_PROCESO FOREIGN KEY (proceso_id) REFERENCES dbo.CLI547_AGM_MMA_PROCESOS (id)
    );
END
GO

-- 1.3 CAJAS DE CAMBIOS (MARCHAS)
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA='dbo' AND TABLE_NAME='CLI547_AGM_MMA_CAJAS_CAMBIOS')
BEGIN
    CREATE TABLE dbo.CLI547_AGM_MMA_CAJAS_CAMBIOS (
        id      INT IDENTITY(1,1) NOT NULL,
        nombre  VARCHAR(50) NOT NULL,
        CONSTRAINT PK_CAJAS_CAMBIOS PRIMARY KEY CLUSTERED (id),
        CONSTRAINT UQ_CAJAS_CAMBIOS_NOMBRE UNIQUE (nombre)
    );
END
GO
select * from CLI547_AGM_MMA_TIPOS_PARO
-- 1.4 TIPOS DE PARO
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA='dbo' AND TABLE_NAME='CLI547_AGM_MMA_TIPOS_PARO')
BEGIN
    CREATE TABLE dbo.CLI547_AGM_MMA_TIPOS_PARO (
        id               INT IDENTITY(1,1) NOT NULL,
        codigo           VARCHAR(30)  NOT NULL,
        nombre           VARCHAR(100) NOT NULL,
        requiere_galones BIT          NOT NULL CONSTRAINT DF_TIPOSPARO_REQ_GALONES DEFAULT 0,
        requiere_equipo  BIT          NOT NULL CONSTRAINT DF_TIPOSPARO_REQ_EQUIPO DEFAULT 0,
        activo           BIT          NOT NULL CONSTRAINT DF_TIPOSPARO_ACTIVO DEFAULT 1,
        CONSTRAINT PK_TIPOS_PARO PRIMARY KEY CLUSTERED (id),
        CONSTRAINT UQ_TIPOS_PARO_CODIGO UNIQUE (codigo)
    );
END
GO

-- 1.5 CHECKLIST CATEGORÍAS
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA='dbo' AND TABLE_NAME='CLI547_AGM_MMA_CHECKLIST_CATEGORIAS')
BEGIN
    CREATE TABLE dbo.CLI547_AGM_MMA_CHECKLIST_CATEGORIAS (
        id      INT IDENTITY(1,1) NOT NULL,
        nombre  VARCHAR(100) NOT NULL,
        orden   SMALLINT NOT NULL CONSTRAINT DF_CHECKLIST_CAT_ORDEN DEFAULT 0,
        CONSTRAINT PK_CHECKLIST_CATEGORIAS PRIMARY KEY CLUSTERED (id),
        CONSTRAINT UQ_CHECKLIST_CATEGORIAS_NOMBRE UNIQUE (nombre)
    );
END
GO
select * from CLI547_AGM_MMA_CHECKLIST_ITEMS_CATALOGO
-- 1.6 CHECKLIST ITEMS CATÁLOGO
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA='dbo' AND TABLE_NAME='CLI547_AGM_MMA_CHECKLIST_ITEMS_CATALOGO')
BEGIN
    CREATE TABLE dbo.CLI547_AGM_MMA_CHECKLIST_ITEMS_CATALOGO (
        id           INT IDENTITY(1,1) NOT NULL,
        categoria_id INT NOT NULL,
        nombre       VARCHAR(200) NOT NULL,
        descripcion  VARCHAR(MAX) NULL,
        orden        SMALLINT NOT NULL CONSTRAINT DF_CHECKLIST_ITEMS_ORDEN DEFAULT 0,
        activo       BIT NOT NULL CONSTRAINT DF_CHECKLIST_ITEMS_ACTIVO DEFAULT 1,
        tipo_registro VARCHAR(20) NOT NULL CONSTRAINT DF_CHECKLIST_ITEMS_TIPO_REG DEFAULT 'tractor',
        CONSTRAINT PK_CHECKLIST_ITEMS PRIMARY KEY CLUSTERED (id),
        CONSTRAINT FK_CHECKLIST_ITEMS_CATEGORIA FOREIGN KEY (categoria_id) REFERENCES dbo.CLI547_AGM_MMA_CHECKLIST_CATEGORIAS (id),
        CONSTRAINT CK_CHECKLIST_ITEMS_TIPO_REG CHECK (tipo_registro IN ('tractor','vehiculo'))
    );
END
GO

-- 1.7 FALLAS MECÁNICAS (CATÁLOGO)
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA='dbo' AND TABLE_NAME='CLI547_AGM_MMA_FALLAS_MECANICAS')
BEGIN
    CREATE TABLE dbo.CLI547_AGM_MMA_FALLAS_MECANICAS (
        id         INT IDENTITY(1,1) NOT NULL,
        codigo     VARCHAR(30)  NOT NULL,
        nombre     VARCHAR(200) NOT NULL,
        activo     BIT NOT NULL CONSTRAINT DF_FALLAS_MEC_ACTIVO DEFAULT 1,
        created_at DATETIME2 NOT NULL CONSTRAINT DF_FALLAS_MEC_CREATED DEFAULT GETDATE(),
        CONSTRAINT PK_FALLAS_MECANICAS PRIMARY KEY CLUSTERED (id),
        CONSTRAINT UQ_FALLAS_MECANICAS_CODIGO UNIQUE (codigo)
    );
END
GO
select * from CLI547_AGM_MMA_FALLAS_MECANICAS
-- =====================================================================
-- 2. TABLAS TRANSACCIONALES
-- =====================================================================

-- 2.1 REGISTROS DIARIOS (CABECERA)
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA='dbo' AND TABLE_NAME='CLI547_AGM_MMA_REGISTROS_DIARIOS')
BEGIN
    CREATE TABLE dbo.CLI547_AGM_MMA_REGISTROS_DIARIOS (
        id                          UNIQUEIDENTIFIER NOT NULL CONSTRAINT DF_REGISTROS_DIARIOS_ID DEFAULT NEWID(),
        numero_registro             VARCHAR(30)  NOT NULL,
        fecha                       DATE         NOT NULL,
        turno                       VARCHAR(10)  NOT NULL CONSTRAINT DF_REGISTROS_DIARIOS_TURNO DEFAULT 'dia',
        proceso_id                  INT          NULL,
        subproceso_id               INT          NULL,
        subproceso_nombre           NVARCHAR(200) NULL,
        cultivo_id_erp              INT          NULL,
        nombre_cultivo_snapshot     VARCHAR(150) NULL,
        operador_id_erp             INT          NOT NULL,
        nombre_operador_snapshot    VARCHAR(300) NULL,
        supervisor_id_erp           INT          NULL,
        nombre_supervisor_snapshot  VARCHAR(300) NULL,
        tractor_id_erp              INT          NOT NULL,
        codigo_tractor_snapshot     VARCHAR(100) NULL,
        implemento_id_erp           INT          NULL,
        codigo_implemento_snapshot  VARCHAR(100) NULL,
        caja_cambios_id             INT          NULL,
        estado                      VARCHAR(20)  NOT NULL CONSTRAINT DF_REGISTROS_DIARIOS_ESTADO DEFAULT 'borrador',
        tipo_registro               VARCHAR(20)  NOT NULL CONSTRAINT DF_REGISTROS_DIARIOS_TIPO_REG DEFAULT 'tractor',
        observaciones_maq           VARCHAR(MAX) NULL,
        firma_operador              NVARCHAR(MAX) NULL,
        aprobado_por_erp            INT          NULL,
        aprobado_at                 DATETIME2    NULL,
        motivo_rechazo              VARCHAR(MAX) NULL,
        dispositivo_id              VARCHAR(150) NULL,
        sincronizado_erp            BIT          NOT NULL CONSTRAINT DF_REGISTROS_DIARIOS_SINC_ERP DEFAULT 0,
        sincronizado_at             DATETIME2    NULL,
        jornada_inicio_at           DATETIME2    NULL,
        jornada_fin_at              DATETIME2    NULL,
        created_by_erp              INT          NOT NULL,
        created_at                  DATETIME2    NOT NULL CONSTRAINT DF_REGISTROS_DIARIOS_CREATED DEFAULT GETDATE(),
        updated_at                  DATETIME2    NOT NULL CONSTRAINT DF_REGISTROS_DIARIOS_UPDATED DEFAULT GETDATE(),
        proceso_vehiculo            VARCHAR(50)  NULL,
        cantidad_tancadas           INT          NULL,
        CONSTRAINT PK_REGISTROS_DIARIOS PRIMARY KEY CLUSTERED (id),
        CONSTRAINT UQ_REGISTROS_DIARIOS_NUMERO UNIQUE (numero_registro),
        CONSTRAINT FK_REGISTROS_DIARIOS_PROCESO FOREIGN KEY (proceso_id) REFERENCES dbo.CLI547_AGM_MMA_PROCESOS (id),
        CONSTRAINT FK_REGISTROS_DIARIOS_SUBPROCESO FOREIGN KEY (subproceso_id) REFERENCES dbo.CLI547_AGM_MMA_SUBPROCESOS (id),
        CONSTRAINT FK_REGISTROS_DIARIOS_CAJA_CAMBIOS FOREIGN KEY (caja_cambios_id) REFERENCES dbo.CLI547_AGM_MMA_CAJAS_CAMBIOS (id),
        CONSTRAINT CK_REGISTROS_DIARIOS_TURNO CHECK (turno IN ('dia','noche')),
        CONSTRAINT CK_REGISTROS_DIARIOS_ESTADO CHECK (estado IN ('borrador','completado','aprobado','rechazado')),
        CONSTRAINT CK_REGISTROS_DIARIOS_TIPO_REG CHECK (tipo_registro IN ('tractor','vehiculo'))
    );
END
GO

-- 2.2 HORÓMETROS
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA='dbo' AND TABLE_NAME='CLI547_AGM_MMA_HOROMETROS')
BEGIN
    CREATE TABLE dbo.CLI547_AGM_MMA_HOROMETROS (
        id                  UNIQUEIDENTIFIER NOT NULL CONSTRAINT DF_HOROMETROS_ID DEFAULT NEWID(),
        registro_id         UNIQUEIDENTIFIER NOT NULL,
        tractor_inicio      DECIMAL(10,1) NULL,
        tractor_final       DECIMAL(10,1) NULL,
        horas_tractor       AS (CASE WHEN tractor_final IS NOT NULL AND tractor_inicio IS NOT NULL THEN tractor_final - tractor_inicio ELSE NULL END) PERSISTED,
        implemento_inicio   DECIMAL(10,1) NULL,
        implemento_final    DECIMAL(10,1) NULL,
        horas_implemento    AS (CASE WHEN implemento_final IS NOT NULL AND implemento_inicio IS NOT NULL THEN implemento_final - implemento_inicio ELSE NULL END) PERSISTED,
        created_at          DATETIME2 NOT NULL CONSTRAINT DF_HOROMETROS_CREATED DEFAULT GETDATE(),
        updated_at          DATETIME2 NOT NULL CONSTRAINT DF_HOROMETROS_UPDATED DEFAULT GETDATE(),
        CONSTRAINT PK_HOROMETROS PRIMARY KEY CLUSTERED (id),
        CONSTRAINT UQ_HOROMETROS_REGISTRO UNIQUE (registro_id),
        CONSTRAINT FK_HOROMETROS_REGISTRO FOREIGN KEY (registro_id) REFERENCES dbo.CLI547_AGM_MMA_REGISTROS_DIARIOS (id) ON DELETE CASCADE
    );
END
GO
select * from CLI547_AGM_MMA_TIEMPOS_TURNO
sp_columns 'CLI547_AGM_MMA_TIEMPOS_TURNO'
-- 2.3 TIEMPOS DE TURNO
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA='dbo' AND TABLE_NAME='CLI547_AGM_MMA_TIEMPOS_TURNO')
BEGIN
    CREATE TABLE dbo.CLI547_AGM_MMA_TIEMPOS_TURNO (
        id                      UNIQUEIDENTIFIER NOT NULL CONSTRAINT DF_TIEMPOS_TURNO_ID DEFAULT NEWID(),
        registro_id             UNIQUEIDENTIFIER NOT NULL,
        hora_salida_taller      TIME NULL,
        hora_llegada_punto      TIME NULL,
        hora_salida_punto       TIME NULL,
        hora_llegada_taller     TIME NULL,
        hora_refrigerio         VARCHAR(30) NULL,
        minutos_efectivos       AS (CASE WHEN hora_salida_punto IS NOT NULL AND hora_llegada_punto IS NOT NULL THEN DATEDIFF(MINUTE, hora_llegada_punto, hora_salida_punto) ELSE NULL END) PERSISTED,
        created_at              DATETIME2 NOT NULL CONSTRAINT DF_TIEMPOS_TURNO_CREATED DEFAULT GETDATE(),
        updated_at              DATETIME2 NOT NULL CONSTRAINT DF_TIEMPOS_TURNO_UPDATED DEFAULT GETDATE(),
        CONSTRAINT PK_TIEMPOS_TURNO PRIMARY KEY CLUSTERED (id),
        CONSTRAINT UQ_TIEMPOS_TURNO_REGISTRO UNIQUE (registro_id),
        CONSTRAINT FK_TIEMPOS_TURNO_REGISTRO FOREIGN KEY (registro_id) REFERENCES dbo.CLI547_AGM_MMA_REGISTROS_DIARIOS (id) ON DELETE CASCADE
    );
END
GO

-- 2.4 PAROS DE EQUIPOS (TRACTOR)
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA='dbo' AND TABLE_NAME='CLI547_AGM_MMA_PAROS_EQUIPOS')
BEGIN
    CREATE TABLE dbo.CLI547_AGM_MMA_PAROS_EQUIPOS (
        id                     UNIQUEIDENTIFIER NOT NULL CONSTRAINT DF_PAROS_EQUIPOS_ID DEFAULT NEWID(),
        registro_id            UNIQUEIDENTIFIER NOT NULL,
        tipo_paro_id           INT NOT NULL,
        motivo                 VARCHAR(MAX) NULL,
        equipo                 VARCHAR(150) NULL,
        hora_inicio            TIME NOT NULL,
        hora_final             TIME NULL,
        galones                DECIMAL(8,2) NULL,
        duracion_min           AS (CASE WHEN hora_final IS NOT NULL THEN DATEDIFF(MINUTE, hora_inicio, hora_final) ELSE NULL END) PERSISTED,
        created_at             DATETIME2 NOT NULL CONSTRAINT DF_PAROS_EQUIPOS_CREATED DEFAULT GETDATE(),
        falla_mecanica_id      INT NULL,
        falla_mecanica_nombre  VARCHAR(200) NULL,
        hora_inicio_real       TIME NULL,
        hora_fin_real          TIME NULL,
        mecanico_id_erp        INT NULL,
        mecanico_nombre        VARCHAR(300) NULL,
        trabajo_realizado      NVARCHAR(MAX) NULL,
        estado_falla           VARCHAR(30) NULL CONSTRAINT DF_PAROS_EQUIPOS_ESTADO_FALLA DEFAULT 'pendiente',
        completado_at          DATETIME2 NULL,
        CONSTRAINT PK_PAROS_EQUIPOS PRIMARY KEY CLUSTERED (id),
        CONSTRAINT FK_PAROS_EQUIPOS_REGISTRO FOREIGN KEY (registro_id) REFERENCES dbo.CLI547_AGM_MMA_REGISTROS_DIARIOS (id) ON DELETE CASCADE,
        CONSTRAINT FK_PAROS_EQUIPOS_TIPO_PARO FOREIGN KEY (tipo_paro_id) REFERENCES dbo.CLI547_AGM_MMA_TIPOS_PARO (id),
        CONSTRAINT FK_PAROS_EQUIPOS_FALLA_MECANICA FOREIGN KEY (falla_mecanica_id) REFERENCES dbo.CLI547_AGM_MMA_FALLAS_MECANICAS (id)
    );
END
GO

-- 2.5 PAROS DE VEHÍCULO
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA='dbo' AND TABLE_NAME='CLI547_AGM_MMA_PAROS_VEHICULO')
BEGIN
    CREATE TABLE dbo.CLI547_AGM_MMA_PAROS_VEHICULO (
        id           INT IDENTITY(1,1) NOT NULL,
        registro_id  UNIQUEIDENTIFIER NOT NULL,
        motivo       NVARCHAR(250) NULL,
        hora_inicio  TIME NULL,
        hora_final   TIME NULL,
        CONSTRAINT PK_PAROS_VEHICULO PRIMARY KEY CLUSTERED (id),
        CONSTRAINT FK_PAROS_VEHICULO_REGISTRO FOREIGN KEY (registro_id) REFERENCES dbo.CLI547_AGM_MMA_REGISTROS_DIARIOS (id) ON DELETE CASCADE
    );
END
GO

-- 2.6 COSECHA BINES
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA='dbo' AND TABLE_NAME='CLI547_AGM_MMA_COSECHA_BINES')
BEGIN
    CREATE TABLE dbo.CLI547_AGM_MMA_COSECHA_BINES (
        id              UNIQUEIDENTIFIER NOT NULL CONSTRAINT DF_COSECHA_BINES_ID DEFAULT NEWID(),
        registro_id     UNIQUEIDENTIFIER NOT NULL,
        franja_horaria  VARCHAR(10) NOT NULL,
        turno_franja    VARCHAR(5)  NOT NULL,
        cantidad        SMALLINT NOT NULL CONSTRAINT DF_COSECHA_BINES_CANTIDAD DEFAULT 0,
        CONSTRAINT PK_COSECHA_BINES PRIMARY KEY CLUSTERED (id),
        CONSTRAINT FK_COSECHA_BINES_REGISTRO FOREIGN KEY (registro_id) REFERENCES dbo.CLI547_AGM_MMA_REGISTROS_DIARIOS (id) ON DELETE CASCADE,
        CONSTRAINT UQ_COSECHA_BINES_FRANJA UNIQUE (registro_id, franja_horaria),
        CONSTRAINT CK_COSECHA_BINES_TURNO_FRANJA CHECK (turno_franja IN ('am','pm')),
        CONSTRAINT CK_COSECHA_BINES_CANTIDAD CHECK (cantidad >= 0)
    );
END
GO

-- 2.7 REGISTROS LOTES
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA='dbo' AND TABLE_NAME='CLI547_AGM_MMA_REGISTROS_LOTES')
BEGIN
    CREATE TABLE dbo.CLI547_AGM_MMA_REGISTROS_LOTES (
        id                    UNIQUEIDENTIFIER NOT NULL CONSTRAINT DF_REGISTROS_LOTES_ID DEFAULT NEWID(),
        registro_id           UNIQUEIDENTIFIER NOT NULL,
        lote_id_erp           INT NOT NULL,
        finca_id_erp          INT NOT NULL,
        lote_codigo_snapshot  VARCHAR(50) NULL,
        sublote_snapshot      VARCHAR(200) NULL,
        area_trabajada_ha     DECIMAL(8,4) NULL,
        observacion           VARCHAR(MAX) NULL,
        CONSTRAINT PK_REGISTROS_LOTES PRIMARY KEY CLUSTERED (id),
        CONSTRAINT FK_REGISTROS_LOTES_REGISTRO FOREIGN KEY (registro_id) REFERENCES dbo.CLI547_AGM_MMA_REGISTROS_DIARIOS (id) ON DELETE CASCADE,
        CONSTRAINT UQ_REGISTROS_LOTES_UNICO UNIQUE (registro_id, lote_id_erp)
    );
END
GO

-- 2.8 REGISTROS SUBLABORES
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA='dbo' AND TABLE_NAME='CLI547_AGM_MMA_REGISTROS_SUBLABORES')
BEGIN
    CREATE TABLE dbo.CLI547_AGM_MMA_REGISTROS_SUBLABORES (
        id              INT IDENTITY(1,1) NOT NULL,
        registro_id     UNIQUEIDENTIFIER NOT NULL,
        sublabor_nombre NVARCHAR(200) NOT NULL,
        created_at      DATETIME2 NOT NULL CONSTRAINT DF_SUBLABORES_CREATED DEFAULT GETDATE(),
        CONSTRAINT PK_SUBLABORES PRIMARY KEY CLUSTERED (id),
        CONSTRAINT FK_SUBLABORES_REGISTRO FOREIGN KEY (registro_id) REFERENCES dbo.CLI547_AGM_MMA_REGISTROS_DIARIOS (id) ON DELETE CASCADE
    );
    CREATE INDEX idx_sublabores_registro ON dbo.CLI547_AGM_MMA_REGISTROS_SUBLABORES(registro_id);
END
GO

-- 2.9 REGISTROS MARCHAS
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA='dbo' AND TABLE_NAME='CLI547_AGM_MMA_REGISTROS_MARCHAS')
BEGIN
    CREATE TABLE dbo.CLI547_AGM_MMA_REGISTROS_MARCHAS (
        id            INT IDENTITY(1,1) NOT NULL,
        registro_id   UNIQUEIDENTIFIER NOT NULL,
        marcha_codigo VARCHAR(10) NOT NULL,
        horas_uso     DECIMAL(6,2) NULL,
        created_at    DATETIME2 NOT NULL CONSTRAINT DF_MARCHAS_CREATED DEFAULT GETDATE(),
        CONSTRAINT PK_MARCHAS PRIMARY KEY CLUSTERED (id),
        CONSTRAINT FK_MARCHAS_REGISTRO FOREIGN KEY (registro_id) REFERENCES dbo.CLI547_AGM_MMA_REGISTROS_DIARIOS (id) ON DELETE CASCADE
    );
    CREATE INDEX idx_marchas_registro ON dbo.CLI547_AGM_MMA_REGISTROS_MARCHAS(registro_id);
END
GO

-- 2.10 CHECKLIST RESULTADOS
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA='dbo' AND TABLE_NAME='CLI547_AGM_MMA_CHECKLIST_RESULTADOS')
BEGIN
    CREATE TABLE dbo.CLI547_AGM_MMA_CHECKLIST_RESULTADOS (
        id          UNIQUEIDENTIFIER NOT NULL CONSTRAINT DF_CHECKLIST_RESULTADOS_ID DEFAULT NEWID(),
        registro_id UNIQUEIDENTIFIER NOT NULL,
        item_id     INT NOT NULL,
        resultado   VARCHAR(4) NOT NULL,
        observacion VARCHAR(MAX) NULL,
        foto_url    VARCHAR(MAX) NULL,
        CONSTRAINT PK_CHECKLIST_RESULTADOS PRIMARY KEY CLUSTERED (id),
        CONSTRAINT FK_CHECKLIST_RESULTADOS_REGISTRO FOREIGN KEY (registro_id) REFERENCES dbo.CLI547_AGM_MMA_REGISTROS_DIARIOS (id) ON DELETE CASCADE,
        CONSTRAINT FK_CHECKLIST_RESULTADOS_ITEM FOREIGN KEY (item_id) REFERENCES dbo.CLI547_AGM_MMA_CHECKLIST_ITEMS_CATALOGO (id),
        CONSTRAINT UQ_CHECKLIST_RESULTADOS_UNICO UNIQUE (registro_id, item_id),
        CONSTRAINT CK_CHECKLIST_RESULTADOS_RESULTADO CHECK (resultado IN ('bien','mal','na'))
    );
END
GO

-- 2.11 COMBUSTIBLE VEHÍCULO
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA='dbo' AND TABLE_NAME='CLI547_AGM_MMA_COMBUSTIBLE_VEHICULO')
BEGIN
    CREATE TABLE dbo.CLI547_AGM_MMA_COMBUSTIBLE_VEHICULO (
        id           INT IDENTITY(1,1) NOT NULL,
        registro_id  UNIQUEIDENTIFIER NOT NULL,
        glns         DECIMAL(10,2) NULL,
        hora_inicio  TIME NULL,
        hora_final   TIME NULL,
        CONSTRAINT PK_COMBUSTIBLE_VEHICULO PRIMARY KEY CLUSTERED (id),
        CONSTRAINT FK_COMBUSTIBLE_VEHICULO_REGISTRO FOREIGN KEY (registro_id) REFERENCES dbo.CLI547_AGM_MMA_REGISTROS_DIARIOS (id) ON DELETE CASCADE
    );
END
GO

-- 2.12 STATUS JORNADA
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA='dbo' AND TABLE_NAME='CLI547_AGM_MMA_STATUS_JORNADA')
BEGIN
    CREATE TABLE dbo.CLI547_AGM_MMA_STATUS_JORNADA (
        id                 INT IDENTITY(1,1) NOT NULL,
        usuario_erp_id     INT NOT NULL,
        dispositivo_id     VARCHAR(100) NOT NULL,
        turno              VARCHAR(10) NOT NULL,
        jornada_inicio_at  DATETIME2 NOT NULL,
        jornada_fin_at     DATETIME2 NULL,
        created_at         DATETIME2 NOT NULL CONSTRAINT DF_STATUS_JORNADA_CREATED DEFAULT GETUTCDATE(),
        updated_at         DATETIME2 NOT NULL CONSTRAINT DF_STATUS_JORNADA_UPDATED DEFAULT GETUTCDATE(),
        jornada_fecha      AS CAST(jornada_inicio_at AS DATE) PERSISTED,
        CONSTRAINT PK_STATUS_JORNADA PRIMARY KEY CLUSTERED (id),
        CONSTRAINT UQ_STATUS_JORNADA_USUARIO_TURNO_FECHA UNIQUE (usuario_erp_id, turno, jornada_fecha),
        CONSTRAINT CK_STATUS_JORNADA_TURNO CHECK (turno IN ('dia','noche'))
    );
END
GO


select * from trabajadores where id = 42709
select * from sujetos where id = 44873
select * from CLI547_AGM_MMA_PORTERO_LECTURAS


-- 2.13 PORTERO LECTURAS
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA='dbo' AND TABLE_NAME='CLI547_AGM_MMA_PORTERO_LECTURAS')
BEGIN
    CREATE TABLE dbo.CLI547_AGM_MMA_PORTERO_LECTURAS (
        id                    UNIQUEIDENTIFIER NOT NULL CONSTRAINT DF_PORTERO_LECTURAS_ID DEFAULT NEWID(),
        portero_id_erp        INT NOT NULL,
        tractor_id_erp        INT NULL,
        tractor_codigo        VARCHAR(50) NULL,
        tractor_leido_at      DATETIME2 NULL,
        implemento_id_erp     INT NULL,
        implemento_codigo     VARCHAR(50) NULL,
        implemento_leido_at   DATETIME2 NULL,
        trabajador_id_erp     INT NULL,
        trabajador_codigo     VARCHAR(50) NULL,
        operador_leido_at     DATETIME2 NULL,
        cultivo_id_erp        INT NULL,
        cultivo_nombre        NVARCHAR(200) NULL,
        comentario            NVARCHAR(500) NULL,
        dispositivo_id        VARCHAR(100) NULL,
        hora_sincronizacion   DATETIME2 NULL,
        created_at            DATETIME2 NOT NULL CONSTRAINT DF_PORTERO_LECTURAS_CREATED DEFAULT GETUTCDATE(),
        CONSTRAINT PK_PORTERO_LECTURAS PRIMARY KEY CLUSTERED (id)
    );
END
GO

-- 2.14 INCUMPLIMIENTOS
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA='dbo' AND TABLE_NAME='CLI547_AGM_MMA_INCUMPLIMIENTOS')
BEGIN
    CREATE TABLE dbo.CLI547_AGM_MMA_INCUMPLIMIENTOS (
        id                   INT IDENTITY(1,1) NOT NULL,
        usuario_erp_id       INT NOT NULL,
        nombre_usuario       NVARCHAR(300) NOT NULL,
        fecha_jornada        DATE NOT NULL,
        turno                VARCHAR(10) NOT NULL,
        tipo_incumplimiento  VARCHAR(80) NOT NULL,
        detalle              NVARCHAR(MAX) NULL,
        dispositivo_id       VARCHAR(150) NULL,
        firestore_doc_id     VARCHAR(200) NULL,
        created_at           DATETIME2 NOT NULL CONSTRAINT DF_INCUMPLIMIENTOS_CREATED DEFAULT GETDATE(),
        CONSTRAINT PK_INCUMPLIMIENTOS PRIMARY KEY CLUSTERED (id),
        CONSTRAINT CK_INCUMPLIMIENTOS_TURNO CHECK (turno IN ('dia','noche'))
    );
    CREATE INDEX idx_incumplimientos_usuario ON dbo.CLI547_AGM_MMA_INCUMPLIMIENTOS(usuario_erp_id, fecha_jornada);
END
GO

-- 2.15 NOTIFICACIONES
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA='dbo' AND TABLE_NAME='CLI547_AGM_MMA_NOTIFICACIONES')
BEGIN
    CREATE TABLE dbo.CLI547_AGM_MMA_NOTIFICACIONES (
        id              INT IDENTITY(1,1) NOT NULL,
        usuario_erp_id  INT NOT NULL,
        tipo            VARCHAR(50) NOT NULL,
        titulo          NVARCHAR(200) NOT NULL,
        cuerpo          NVARCHAR(500) NULL,
        leida           BIT NOT NULL CONSTRAINT DF_NOTIFICACIONES_LEIDA DEFAULT 0,
        created_at      DATETIME2 NOT NULL CONSTRAINT DF_NOTIFICACIONES_CREATED DEFAULT GETUTCDATE(),
        CONSTRAINT PK_NOTIFICACIONES PRIMARY KEY CLUSTERED (id)
    );
END
GO

-- 2.16 SESIONES DISPOSITIVO
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA='dbo' AND TABLE_NAME='CLI547_AGM_MMA_SESIONES_DISPOSITIVO')
BEGIN
    CREATE TABLE dbo.CLI547_AGM_MMA_SESIONES_DISPOSITIVO (
        id              UNIQUEIDENTIFIER NOT NULL CONSTRAINT DF_SESIONES_ID DEFAULT NEWID(),
        usuario_erp_id  INT NOT NULL,
        dispositivo_id  VARCHAR(150) NOT NULL,
        token           VARCHAR(500) NOT NULL,
        activo          BIT NOT NULL CONSTRAINT DF_SESIONES_ACTIVO DEFAULT 1,
        creado_at       DATETIME2 NOT NULL CONSTRAINT DF_SESIONES_CREADO DEFAULT GETDATE(),
        expira_at       DATETIME2 NOT NULL CONSTRAINT DF_SESIONES_EXPIRA DEFAULT DATEADD(DAY, 30, GETDATE()),
        ultimo_uso      DATETIME2 NULL,
        CONSTRAINT PK_SESIONES PRIMARY KEY CLUSTERED (id),
        CONSTRAINT UQ_SESIONES_TOKEN UNIQUE (token)
    );
END
GO

-- 2.17 AUDITORÍA
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA='dbo' AND TABLE_NAME='CLI547_AGM_MMA_AUDIT_LOG')
BEGIN
    CREATE TABLE dbo.CLI547_AGM_MMA_AUDIT_LOG (
        id          BIGINT IDENTITY(1,1) NOT NULL,
        tabla       VARCHAR(80) NOT NULL,
        registro_pk VARCHAR(100) NOT NULL,
        accion      VARCHAR(10) NOT NULL,
        datos_old   NVARCHAR(MAX) NULL,
        datos_new   NVARCHAR(MAX) NULL,
        usuario_erp_id INT NULL,
        ip          VARCHAR(45) NULL,
        created_at  DATETIME2 NOT NULL CONSTRAINT DF_AUDIT_CREATED DEFAULT GETDATE(),
        CONSTRAINT PK_AUDIT PRIMARY KEY CLUSTERED (id),
        CONSTRAINT CK_AUDIT_ACCION CHECK (accion IN ('INSERT','UPDATE','DELETE'))
    );
END
GO

-- =====================================================================
-- 3. ÍNDICES ADICIONALES
-- =====================================================================

-- 3.1 Índices para REGISTROS_DIARIOS (si no existen)
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'idx_mma_rd_fecha' AND object_id = OBJECT_ID('dbo.CLI547_AGM_MMA_REGISTROS_DIARIOS'))
    CREATE INDEX idx_mma_rd_fecha ON dbo.CLI547_AGM_MMA_REGISTROS_DIARIOS(fecha DESC);

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'idx_mma_rd_estado' AND object_id = OBJECT_ID('dbo.CLI547_AGM_MMA_REGISTROS_DIARIOS'))
    CREATE INDEX idx_mma_rd_estado ON dbo.CLI547_AGM_MMA_REGISTROS_DIARIOS(estado);

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'idx_mma_rd_operador' AND object_id = OBJECT_ID('dbo.CLI547_AGM_MMA_REGISTROS_DIARIOS'))
    CREATE INDEX idx_mma_rd_operador ON dbo.CLI547_AGM_MMA_REGISTROS_DIARIOS(operador_id_erp);

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'idx_mma_rd_numero' AND object_id = OBJECT_ID('dbo.CLI547_AGM_MMA_REGISTROS_DIARIOS'))
    CREATE INDEX idx_mma_rd_numero ON dbo.CLI547_AGM_MMA_REGISTROS_DIARIOS(numero_registro);

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'idx_mma_rd_tipo' AND object_id = OBJECT_ID('dbo.CLI547_AGM_MMA_REGISTROS_DIARIOS'))
    CREATE INDEX idx_mma_rd_tipo ON dbo.CLI547_AGM_MMA_REGISTROS_DIARIOS(tipo_registro);

-- 3.2 Índice para CHECKLIST_ITEMS_CATALOGO (tipo_registro)
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'idx_mma_checklist_tipo' AND object_id = OBJECT_ID('dbo.CLI547_AGM_MMA_CHECKLIST_ITEMS_CATALOGO'))
    CREATE INDEX idx_mma_checklist_tipo ON dbo.CLI547_AGM_MMA_CHECKLIST_ITEMS_CATALOGO(tipo_registro);

-- 3.3 Índice para PAROS_EQUIPOS (registro_id)
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'idx_paros_equipos_registro' AND object_id = OBJECT_ID('dbo.CLI547_AGM_MMA_PAROS_EQUIPOS'))
    CREATE INDEX idx_paros_equipos_registro ON dbo.CLI547_AGM_MMA_PAROS_EQUIPOS(registro_id);

-- 3.4 Índice para CHECKLIST_RESULTADOS (registro_id)
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'idx_checklist_resultados_registro' AND object_id = OBJECT_ID('dbo.CLI547_AGM_MMA_CHECKLIST_RESULTADOS'))
    CREATE INDEX idx_checklist_resultados_registro ON dbo.CLI547_AGM_MMA_CHECKLIST_RESULTADOS(registro_id);

-- 3.5 Índice para STATUS_JORNADA (jornada_fecha y usuario)
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'idx_status_jornada_fecha' AND object_id = OBJECT_ID('dbo.CLI547_AGM_MMA_STATUS_JORNADA'))
    CREATE INDEX idx_status_jornada_fecha ON dbo.CLI547_AGM_MMA_STATUS_JORNADA(jornada_fecha);

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'idx_status_jornada_usuario' AND object_id = OBJECT_ID('dbo.CLI547_AGM_MMA_STATUS_JORNADA'))
    CREATE INDEX idx_status_jornada_usuario ON dbo.CLI547_AGM_MMA_STATUS_JORNADA(usuario_erp_id);

-- 3.6 Índice para PORTERO_LECTURAS (created_at)
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'idx_portero_created' AND object_id = OBJECT_ID('dbo.CLI547_AGM_MMA_PORTERO_LECTURAS'))
    CREATE INDEX idx_portero_created ON dbo.CLI547_AGM_MMA_PORTERO_LECTURAS(created_at DESC);

-- =====================================================================
-- 4. DATOS MAESTROS (INSERTS)
-- =====================================================================

-- 4.1 PROCESOS
SET IDENTITY_INSERT dbo.CLI547_AGM_MMA_PROCESOS ON;
GO

INSERT INTO dbo.CLI547_AGM_MMA_PROCESOS (id, codigo, nombre, descripcion, requiere_bines, especie_botanica_erp_id, activo, created_at, updated_at, requiere_sublabores, tipo_registro, rendimiento_teorico_bins_por_hora, rendimiento_teorico)
SELECT * FROM (VALUES
    (1, 'APLIC', 'Aplicación', NULL, 0, NULL, 1, '2026-07-09 10:44:53.6833333', '2026-07-09 10:44:53.6833333', 1, 'tractor', 10.00, 2.50),
    (2, 'COSEC', 'Cosecha', NULL, 1, NULL, 1, '2026-07-09 10:44:53.6833333', '2026-07-09 10:44:53.6833333', 0, 'tractor', 10.00, 15.00),
    (3, 'PODA', 'Poda', NULL, 0, NULL, 1, '2026-07-09 10:44:53.6833333', '2026-07-09 10:44:53.6833333', 0, 'tractor', 10.00, 1.80),
    (4, 'TRITU', 'Triturado', NULL, 0, NULL, 1, '2026-07-09 10:44:53.6833333', '2026-07-09 10:44:53.6833333', 0, 'tractor', 10.00, 2.00),
    (5, 'RUFA', 'Rufa', NULL, 0, NULL, 1, '2026-07-09 10:44:53.6833333', '2026-07-09 10:44:53.6833333', 0, 'tractor', 10.00, 1.00),
    (6, 'CARRE', 'Carreteo', NULL, 0, NULL, 1, '2026-07-09 10:44:53.6833333', '2026-07-09 10:44:53.6833333', 0, 'tractor', 10.00, 1.00),
    (7, 'MELAZ', 'Melaza', NULL, 0, NULL, 1, '2026-07-09 10:44:53.6833333', '2026-07-09 10:44:53.6833333', 0, 'tractor', 10.00, 1.00),
    (8, 'REGADO_CAMINOS', 'Regado de caminos', NULL, 0, NULL, 1, '2026-07-09 10:44:53.6833333', '2026-07-09 10:44:53.6833333', 0, 'vehiculo', 10.00, 1.00),
    (9, 'TRASLADO_MANGUERAS', 'Traslado de mangueras', NULL, 0, NULL, 1, '2026-07-09 10:44:53.6833333', '2026-07-09 10:44:53.6833333', 0, 'vehiculo', 10.00, 1.00),
    (10, 'TRASLADO_MATERIALES', 'Traslado de materiales', NULL, 0, NULL, 1, '2026-07-09 10:44:53.6833333', '2026-07-09 10:44:53.6833333', 0, 'vehiculo', 10.00, 1.00),
    (11, 'ABASTECIMIENTO', 'Abastecimiento', NULL, 0, NULL, 1, '2026-07-09 10:44:53.6833333', '2026-07-09 10:44:53.6833333', 0, 'vehiculo', 10.00, 1.00),
    (12, 'CULTIVO', 'Cultivo', NULL, 1, NULL, 1, '2026-07-09 10:44:53.6833333', '2026-07-09 10:44:53.6833333', 0, 'vehiculo', 10.00, 1.00),
    (13, 'APLICACION', 'Aplicacion', NULL, 0, NULL, 1, '2026-07-09 10:44:53.6833333', '2026-07-09 10:44:53.6833333', 1, 'vehiculo', 10.00, 1.00),
    (14, 'OTRO', 'Otro', NULL, 0, NULL, 1, '2026-07-09 10:44:53.6833333', '2026-07-09 10:44:53.6833333', 0, 'vehiculo', 10.00, 1.00)
) AS vals(id, codigo, nombre, descripcion, requiere_bines, especie_botanica_erp_id, activo, created_at, updated_at, requiere_sublabores, tipo_registro, rendimiento_teorico_bins_por_hora, rendimiento_teorico)
WHERE NOT EXISTS (SELECT 1 FROM dbo.CLI547_AGM_MMA_PROCESOS WHERE id = vals.id);

SET IDENTITY_INSERT dbo.CLI547_AGM_MMA_PROCESOS OFF;
GO

-- 4.2 TIPOS DE PARO
SET IDENTITY_INSERT dbo.CLI547_AGM_MMA_TIPOS_PARO ON;
GO

INSERT INTO dbo.CLI547_AGM_MMA_TIPOS_PARO (id, codigo, nombre, requiere_galones, requiere_equipo, activo)
SELECT * FROM (VALUES
    (1, 'CLIMA', 'Factor climático', 0, 0, 1),
    (2, 'COMBUSTIBLE', 'Abastecimiento de combustible', 1, 0, 1),
    (3, 'MECANICO', 'Falla mecánica', 0, 1, 1),
    (4, 'CALIBRACION', 'Calibración de equipos', 0, 0, 1),
    (5, 'CAPACITACION', 'Charlas o capacitaciones', 0, 0, 1)
) AS vals(id, codigo, nombre, requiere_galones, requiere_equipo, activo)
WHERE NOT EXISTS (SELECT 1 FROM dbo.CLI547_AGM_MMA_TIPOS_PARO WHERE id = vals.id);

SET IDENTITY_INSERT dbo.CLI547_AGM_MMA_TIPOS_PARO OFF;
GO

-- 4.3 CAJAS DE CAMBIOS
SET IDENTITY_INSERT dbo.CLI547_AGM_MMA_CAJAS_CAMBIOS ON;
GO

INSERT INTO dbo.CLI547_AGM_MMA_CAJAS_CAMBIOS (id, nombre)
SELECT * FROM (VALUES
    (1, 'T-1'), (2, 'T-2'), (3, 'T-3'), (4, 'T-4'),
    (5, 'H-1'), (6, 'H-2'), (7, 'H-3'), (8, 'H-4'),
    (9, 'L-1'), (10, 'L-2'), (11, 'L-3'), (12, 'L-4')
) AS vals(id, nombre)
WHERE NOT EXISTS (SELECT 1 FROM dbo.CLI547_AGM_MMA_CAJAS_CAMBIOS WHERE id = vals.id);

SET IDENTITY_INSERT dbo.CLI547_AGM_MMA_CAJAS_CAMBIOS OFF;
GO

-- 4.4 FALLAS MECÁNICAS
SET IDENTITY_INSERT dbo.CLI547_AGM_MMA_FALLAS_MECANICAS ON;
GO

INSERT INTO dbo.CLI547_AGM_MMA_FALLAS_MECANICAS (id, codigo, nombre, activo, created_at)
SELECT * FROM (VALUES
    (1, 'MOTOR', 'Falla de motor', 1, '2026-07-12 14:23:38.2600000'),
    (2, 'HIDRAULICO', 'Falla hidráulica', 1, '2026-07-12 14:23:38.2600000'),
    (3, 'ELECTRICO', 'Falla eléctrica', 1, '2026-07-12 14:23:38.2600000'),
    (4, 'FRENOS', 'Falla de frenos', 1, '2026-07-12 14:23:38.2600000'),
    (5, 'TRANSMISION', 'Falla de transmisión', 1, '2026-07-12 14:23:38.2600000'),
    (6, 'SISTEMA_ENFR', 'Sistema de enfriamiento', 1, '2026-07-12 14:23:38.2600000'),
    (7, 'NEUMATICOS', 'Neumáticos / Ruedas', 1, '2026-07-12 14:23:38.2600000'),
    (8, 'IMPLEMENTO', 'Falla de implemento', 1, '2026-07-12 14:23:38.2600000'),
    (9, 'HIDRAULICO_IMP', 'Hidráulico de implemento', 1, '2026-07-12 14:23:38.2600000'),
    (10, 'OTRO', 'Otro', 1, '2026-07-12 14:23:38.2600000')
) AS vals(id, codigo, nombre, activo, created_at)
WHERE NOT EXISTS (SELECT 1 FROM dbo.CLI547_AGM_MMA_FALLAS_MECANICAS WHERE id = vals.id);

SET IDENTITY_INSERT dbo.CLI547_AGM_MMA_FALLAS_MECANICAS OFF;
GO

-- 4.5 CHECKLIST CATEGORÍAS
SET IDENTITY_INSERT dbo.CLI547_AGM_MMA_CHECKLIST_CATEGORIAS ON;
GO

INSERT INTO dbo.CLI547_AGM_MMA_CHECKLIST_CATEGORIAS (id, nombre, orden)
SELECT * FROM (VALUES
    (1, 'Inspeccionar Tractor', 10),
    (2, 'Inspeccionar Implemento', 20),
    (3, 'Vehículo', 100)
) AS vals(id, nombre, orden)
WHERE NOT EXISTS (SELECT 1 FROM dbo.CLI547_AGM_MMA_CHECKLIST_CATEGORIAS WHERE id = vals.id);

SET IDENTITY_INSERT dbo.CLI547_AGM_MMA_CHECKLIST_CATEGORIAS OFF;
GO

-- 4.6 CHECKLIST ITEMS CATÁLOGO
SET IDENTITY_INSERT dbo.CLI547_AGM_MMA_CHECKLIST_ITEMS_CATALOGO ON;
GO

INSERT INTO dbo.CLI547_AGM_MMA_CHECKLIST_ITEMS_CATALOGO (id, categoria_id, nombre, descripcion, orden, activo, tipo_registro)
SELECT * FROM (VALUES
    (1, 1, 'Nivel de aceite del motor', NULL, 1, 1, 'tractor'),
    (2, 1, 'Nivel de aceite hidráulico del tractor', NULL, 2, 1, 'tractor'),
    (3, 1, 'Nivel de refrigerante del motor', NULL, 3, 1, 'tractor'),
    (4, 1, 'Nivel de aceite de la caja multiplicadora', NULL, 4, 1, 'tractor'),
    (5, 1, 'Nivel de aceite hidráulico del Implemento', NULL, 5, 1, 'tractor'),
    (6, 1, 'Llantas y ajuste de tuercas de rueda', NULL, 6, 1, 'tractor'),
    (7, 1, 'Batería y sus bornes', NULL, 7, 1, 'tractor'),
    (8, 1, 'Barra de tiro, pines y seguro', NULL, 8, 1, 'tractor'),
    (9, 1, 'Faja de alternador', NULL, 9, 1, 'tractor'),
    (10, 1, 'Tanque de productos', NULL, 10, 1, 'tractor'),
    (11, 1, 'Espejos del tractor', NULL, 11, 1, 'tractor'),
    (12, 1, 'Cardan y su Protector', NULL, 12, 1, 'tractor'),
    (13, 1, 'Claxon', NULL, 13, 1, 'tractor'),
    (14, 1, 'Mangueras hidráulicas', NULL, 14, 1, 'tractor'),
    (15, 1, 'Extintor', NULL, 15, 1, 'tractor'),
    (16, 1, 'Mangueras agroquímicas', NULL, 16, 1, 'tractor'),
    (17, 2, 'Nivel de aceite en los reductores delantero y posterior', NULL, 17, 1, 'tractor'),
    (18, 2, 'Fajas de transmisión', NULL, 18, 1, 'tractor'),
    (19, 2, 'Nivel de aceite del tren delantero', NULL, 19, 1, 'tractor'),
    (20, 2, 'Bombines hidráulicos', NULL, 20, 1, 'tractor'),
    (21, 2, 'Templadores de los brazos de levante y pines/seguros', NULL, 21, 1, 'tractor'),
    (22, 2, 'Comando hidráulico', NULL, 22, 1, 'tractor'),
    (23, 2, 'Llantas y ajuste de tuercas de rueda', NULL, 23, 1, 'tractor'),
    (24, 2, 'Comando eléctrico', NULL, 24, 1, 'tractor'),
    (25, 2, 'Cinturón de seguridad y Protección antivuelco', NULL, 25, 1, 'tractor'),
    (26, 2, 'Luces del implemento', NULL, 26, 1, 'tractor'),
    (27, 2, 'Luces del tractor', NULL, 27, 1, 'tractor'),
    (28, 2, 'Horómetro', NULL, 28, 1, 'tractor'),
    (29, 2, 'Alarma de retroceso', NULL, 29, 1, 'tractor'),
    (30, 2, 'Techo y soportes', NULL, 30, 1, 'tractor'),
    (31, 2, 'Tacos de seguridad', NULL, 31, 1, 'tractor'),
    (32, 2, 'Soporte frontal y templadores', NULL, 32, 1, 'tractor'),
    (33, 3, 'Nivel de aceite de motor', NULL, 1, 1, 'vehiculo'),
    (34, 3, 'Nivel de refrigerante de motor', NULL, 2, 1, 'vehiculo'),
    (35, 3, 'Nivel de hidrolina de dirección', NULL, 3, 1, 'vehiculo'),
    (36, 3, 'Nivel de aceite de motor', NULL, 1, 1, 'vehiculo'), -- duplicado intencional? Se mantiene tal cual
    (37, 3, 'Nivel de refrigerante de motor', NULL, 2, 1, 'vehiculo'),
    (38, 3, 'Nivel de hidrolina de dirección', NULL, 3, 1, 'vehiculo'),
    (39, 3, 'Nivel de líquido de frenos', NULL, 4, 1, 'vehiculo'),
    (40, 3, 'Nivel de combustible', NULL, 5, 1, 'vehiculo'),
    (41, 3, 'Nivel de aceite de los reductores posteriores', NULL, 6, 1, 'vehiculo'),
    (42, 3, 'Estado de Batería y sus bornes', NULL, 7, 1, 'vehiculo'),
    (43, 3, 'Estado de faja de alternador y templado', NULL, 8, 1, 'vehiculo'),
    (44, 3, 'Estado del radiador, mangueras y su tapa', NULL, 9, 1, 'vehiculo'),
    (45, 3, 'Estado de Llantas y ajuste de tuercas de rueda', NULL, 10, 1, 'vehiculo'),
    (46, 3, 'Estado de cardán y soportes', NULL, 11, 1, 'vehiculo'),
    (47, 3, 'Estado de freno de estacionamiento', NULL, 12, 1, 'vehiculo'),
    (48, 3, 'Extintor instalado y operativo', NULL, 13, 1, 'vehiculo'),
    (49, 3, 'Estado de Asiento y Cinturón de seguridad', NULL, 14, 1, 'vehiculo'),
    (50, 3, 'Estado de cabina de operador', NULL, 15, 1, 'vehiculo'),
    (51, 3, 'Estado de Puertas', NULL, 16, 1, 'vehiculo'),
    (52, 3, 'Espejos', NULL, 17, 1, 'vehiculo'),
    (53, 3, 'Luces', NULL, 18, 1, 'vehiculo'),
    (54, 3, 'Tacos de seguridad', NULL, 19, 1, 'vehiculo'),
    (55, 3, 'Alarma de retroceso', NULL, 20, 1, 'vehiculo'),
    (56, 3, 'Claxon', NULL, 21, 1, 'vehiculo'),
    (57, 3, 'Documentos del vehículo', NULL, 22, 1, 'vehiculo'),
    (58, 3, 'Parabrisas y Limpia parabrisas', NULL, 23, 1, 'vehiculo'),
    (59, 3, 'Horómetro y tacómetro', NULL, 24, 1, 'vehiculo')
) AS vals(id, categoria_id, nombre, descripcion, orden, activo, tipo_registro)
WHERE NOT EXISTS (SELECT 1 FROM dbo.CLI547_AGM_MMA_CHECKLIST_ITEMS_CATALOGO WHERE id = vals.id);

SET IDENTITY_INSERT dbo.CLI547_AGM_MMA_CHECKLIST_ITEMS_CATALOGO OFF;
GO

-- 4.7 SUBPROCESOS (ejemplo mínimo, ajustar según realidad)
SET IDENTITY_INSERT dbo.CLI547_AGM_MMA_SUBPROCESOS ON;
GO

INSERT INTO dbo.CLI547_AGM_MMA_SUBPROCESOS (id, proceso_id, nombre, codigo, descripcion, activo, created_at)
SELECT * FROM (VALUES
    (1, 1, 'Aplicación Fitosanitaria', 'FIT01', NULL, 1, GETUTCDATE()),
    (2, 1, 'Fertilización', 'FERT01', NULL, 1, GETUTCDATE()),
    (3, 13, 'Aplicación Vehículo', 'APLV01', NULL, 1, GETUTCDATE())
) AS vals(id, proceso_id, nombre, codigo, descripcion, activo, created_at)
WHERE NOT EXISTS (SELECT 1 FROM dbo.CLI547_AGM_MMA_SUBPROCESOS WHERE id = vals.id);

SET IDENTITY_INSERT dbo.CLI547_AGM_MMA_SUBPROCESOS OFF;
GO

PRINT '✅ Script de creación de tablas, índices, FK y datos maestros completado exitosamente.';
-- =====================================================================================  
-- 7. VISTAS  
-- =====================================================================================  
CREATE VIEW dbo.v_mma_registros_resumen AS  
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


---
  
CREATE VIEW dbo.v_mma_registros_vehiculo_resumen AS  
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

-------
  
CREATE VIEW dbo.v_mma_incumplimientos_resumen AS  
SELECT i.id, i.usuario_erp_id, i.nombre_usuario, i.fecha_jornada, i.turno, i.tipo_incumplimiento, i.detalle, i.created_at,  
    COUNT(rd.id) AS registros_dia,  
    SUM(CASE WHEN rd.estado = 'completado' THEN 1 ELSE 0 END) AS completados,  
    SUM(CASE WHEN rd.estado = 'borrador'   THEN 1 ELSE 0 END) AS borradores  
FROM dbo.CLI547_AGM_MMA_INCUMPLIMIENTOS i  
LEFT JOIN dbo.CLI547_AGM_MMA_REGISTROS_DIARIOS rd ON rd.operador_id_erp = i.usuario_erp_id AND rd.fecha = i.fecha_jornada AND rd.turno = i.turno  
GROUP BY i.id, i.usuario_erp_id, i.nombre_usuario, i.fecha_jornada, i.turno, i.tipo_incumplimiento, i.detalle, i.created_at;  
---


  
      CREATE       PROCEDURE dbo.CLI547_AGMSP_MMA_SINCRONIZAR_OFFLINE        
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
            @v_marchas NVARCHAR(MAX);        
        
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
            --SET @v_cultivo_id_erp = NULL;        
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
                DELETE FROM CLI547_AGM_MMA_REGISTROS_LOTES WHERE registro_id = @p_registro_id;        
                INSERT INTO CLI547_AGM_MMA_REGISTROS_LOTES (id, registro_id, lote_id_erp, finca_id_erp, lote_codigo_snapshot, sublote_snapshot, area_trabajada_ha, observacion)        
                SELECT NEWID(), @p_registro_id,        
                       TRY_CAST(JSON_VALUE(value, '$.lote_id_erp') AS INT),        
                       TRY_CAST(JSON_VALUE(value, '$.finca_id_erp') AS INT),        
                       JSON_VALUE(value, '$.lote_codigo_snapshot'), JSON_VALUE(value, '$.sublote_snapshot'),        
                       TRY_CAST(JSON_VALUE(value, '$.area_trabajada_ha') AS DECIMAL(8,4)), JSON_VALUE(value, '$.observacion')        
                FROM OPENJSON(@v_lotes);        
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
END  
GO
---
CREATE   PROCEDURE dbo.CLI547_AGMSP_MMA_ACTUALIZAR_STATUS_JORNADA  
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
  
        -- 🔑 Buscar por USUARIO + TURNO + FECHA (usando la columna calculada)  
        IF EXISTS (  
            SELECT 1 FROM dbo.CLI547_AGM_MMA_STATUS_JORNADA  
            WHERE usuario_erp_id = @v_usuario_id  
              AND turno = @v_turno  
              AND jornada_fecha = CAST(@v_inicio_at AS DATE)  -- 🔑 usa la columna calculada  
        )  
        BEGIN  
            -- Actualizar SOLO si es el mismo usuario (para evitar duplicados del mismo usuario)  
            UPDATE dbo.CLI547_AGM_MMA_STATUS_JORNADA  
            SET  
                dispositivo_id = @v_dispositivo_id,  
                jornada_inicio_at = @v_inicio_at,  
                jornada_fin_at = @v_fin_at,  
                updated_at = GETUTCDATE()  
            WHERE usuario_erp_id = @v_usuario_id  
              AND turno = @v_turno  
              AND jornada_fecha = CAST(@v_inicio_at AS DATE);  
        END  
        ELSE  
        BEGIN  
            -- Insertar nuevo registro para este usuario (permite que otro usuario use el mismo dispositivo)  
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
-----
CREATE     PROCEDURE [dbo].[CLI547_AGMSP_MMA_GetPerfilProfesional]    
    @UsuarioCodigo VARCHAR(50)    
AS    
BEGIN    
    SET NOCOUNT ON;    
    
    -- Limpiar espacios para evitar problemas de cruce    
    SET @UsuarioCodigo = LTRIM(RTRIM(@UsuarioCodigo));    
    
    -- Validar existencia    
    IF NOT EXISTS (    
        SELECT 1     
        FROM dbo.Usuarios     
        WHERE LTRIM(RTRIM(Codigo)) = @UsuarioCodigo    
    )    
    BEGIN    
        RAISERROR('Usuario [%s] no encontrado en la tabla Usuarios.', 16, 1, @UsuarioCodigo);    
        RETURN;    
    END    
    
    SELECT TOP 1    
        u.Codigo AS CodigoUsuario,                                    -- ← Para perfil_screen.dart    
        CONCAT(s.Nombre, ' ', s.PrimerApellido, ' ', s.SegundoApellido) AS NombreCompleto,  -- ← Para perfil_screen.dart    
        ISNULL((    
            SELECT TOP 1 R.Nombre     
            FROM dbo.Roles R     
            INNER JOIN dbo.Usuarios_Roles UR ON R.Id = UR.Id_Roles     
            WHERE UR.Id_Usuarios = U.Id    
            ORDER BY R.Id DESC     
        ), 'Personal Operativo') AS AreaProviene,                     -- ← Para perfil_screen.dart (Área)    
        'Fundo General' AS Fundo,                                      -- ← Valor fijo    
        ISNULL(z.Nombre, 'Sede Central') AS Sede,                      -- ← Sede real    
        s.Identificador AS DNI,                                        -- ← DNI    
        pt.Descripcion AS PuestoTrabajo,                               -- ← Puesto de trabajo    
        SUBSTRING(t.Codigo, 6, LEN(t.Codigo)) AS CodigoTrabajador,     -- ← Código de trabajador    
        CAST(u.FechaCreacion AS DATE) AS FechaCreacionUsuario,         -- ← Fecha de creación    
        CASE       
            WHEN u.FechaUltimaConexion >= DATEADD(MONTH, -3, GETDATE()) THEN 'Activo'      
            WHEN u.FechaUltimaConexion IS NOT NULL THEN 'Inactivo'      
            ELSE 'Sin accesos'      
        END AS EstadoUsuario                                          -- ← Estado    
    FROM dbo.Usuarios u          
    LEFT JOIN dbo.Sujetos s ON u.id_sujeto = s.id          
    LEFT JOIN dbo.Trabajadores t ON s.id = t.Id_Sujeto          
    LEFT JOIN dbo.PuestoTrabajo pt ON t.id_puestotrabajo = pt.id          
    LEFT JOIN dbo.Trabajadores_DatosComplementarios tdc       
           ON tdc.Id_Trabajadores = t.Id        
    LEFT JOIN dbo.DatoComplementarioValor dcv       
           ON dcv.Id = tdc.Id_DatosComplementarios        
    LEFT JOIN dbo.TecnicosCalidad tc       
           ON s.Id = tc.Id_Sujeto        
    LEFT JOIN dbo.CLI547_AGM_UsuarioConfiguracion uc       
           ON uc.id_usuario = u.id        
    LEFT JOIN dbo.DireccionesSujeto ds       
           ON s.Id = ds.Id_Sujeto      
    LEFT JOIN dbo.Direcciones d       
           ON ds.Id_Direccion = d.Id      
    LEFT JOIN dbo.Zonas z       
           ON d.Id_Zona = z.Id      
    WHERE       
        dcv.Id_DatoComplementario = '50000054'      
        AND LTRIM(RTRIM(u.Codigo)) = @UsuarioCodigo    
    ORDER BY u.FechaCreacion ASC;    
END    
GO
-------
  
-- 5.2 Guardar Checklist  
CREATE   PROCEDURE dbo.CLI547_AGMSP_MMA_GUARDAR_CHECKLIST  
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
-------------
  
-- 5.4 Registrar Paro  
CREATE   PROCEDURE dbo.CLI547_AGMSP_MMA_REGISTRAR_PARO  
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
------
  
-- 5.5 Cerrar Turno Tractor  
CREATE   PROCEDURE dbo.CLI547_AGMSP_MMA_CERRAR_TURNO  
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
            DELETE FROM dbo.CLI547_AGM_MMA_REGISTROS_LOTES WHERE registro_id = @v_rid;  
            INSERT INTO dbo.CLI547_AGM_MMA_REGISTROS_LOTES (id, registro_id, lote_id_erp, finca_id_erp, lote_codigo_snapshot, sublote_snapshot, area_trabajada_ha, observacion)  
            SELECT NEWID(), @v_rid, lote_id_erp, finca_id_erp, lote_codigo_snapshot, sublote_snapshot, area_ha, observacion  
            FROM OPENJSON(@p_lotes) WITH (lote_id_erp INT '$.lote_id_erp', finca_id_erp INT '$.finca_id_erp', lote_codigo_snapshot VARCHAR(50) '$.lote_codigo_snapshot', sublote_snapshot VARCHAR(200) '$.sublote_snapshot', area_ha DECIMAL(8,4) '$.area_ha', 
observacion NVARCHAR(MAX) '$.observacion');  
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
-----
  
-- 5.6 Cerrar Turno Vehículo  
CREATE   PROCEDURE dbo.CLI547_AGMSP_MMA_CERRAR_TURNO_VEHICULO  
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
--------------
  
-- 5.7 Registrar Bin  
CREATE   PROCEDURE dbo.CLI547_AGMSP_MMA_REGISTRAR_BIN  
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
--------
  
-- 5.15 Crear sesión dispositivo  
CREATE   PROCEDURE dbo.CLI547_AGMSP_MMA_CREAR_SESION  
    @p_trabajador_id_erp  INT,  
    @p_dispositivo_id     VARCHAR(150),  
    @p_token              VARCHAR(500)  
AS  
BEGIN  
    SET NOCOUNT ON;  
    IF @p_trabajador_id_erp IS NULL OR @p_trabajador_id_erp <= 0 OR @p_dispositivo_id IS NULL OR @p_token IS NULL  
    BEGIN  
        SELECT CAST(0 AS BIT) AS success, N'Parámetros inválidos' AS mensaje, NULL AS session_id;  
        RETURN;  
    END;  
    BEGIN TRY  
        UPDATE dbo.CLI547_AGM_MMA_SESIONES_DISPOSITIVO SET activo = 0 WHERE dispositivo_id = @p_dispositivo_id AND usuario_erp_id = @p_trabajador_id_erp;  
        DECLARE @v_session_id UNIQUEIDENTIFIER = NEWID();  
        INSERT INTO dbo.CLI547_AGM_MMA_SESIONES_DISPOSITIVO (id, usuario_erp_id, dispositivo_id, token, activo, creado_at, expira_at)  
        VALUES (@v_session_id, @p_trabajador_id_erp, @p_dispositivo_id, @p_token, 1, GETDATE(), DATEADD(DAY, 30, GETDATE()));  
        SELECT CAST(1 AS BIT) AS success, N'Sesión creada correctamente' AS mensaje, CAST(@v_session_id AS NVARCHAR(36)) AS session_id;  
    END TRY  
    BEGIN CATCH  
        SELECT CAST(0 AS BIT) AS success, CONCAT(N'Error: ', ERROR_MESSAGE()) AS mensaje, NULL AS session_id;  
    END CATCH;  
END;  
GO
------------
CREATE   PROCEDURE dbo.CLI547_AGMSP_MMA_REGISTRAR_LECTURA_PORTERO    
    @p_payload NVARCHAR(MAX)    
AS    
BEGIN    
    SET NOCOUNT ON;    
  
    -- 1. Validar JSON  
    IF ISJSON(@p_payload) = 0    
    BEGIN    
        SELECT CAST(0 AS BIT) AS success, N'Payload JSON inválido' AS mensaje, NULL AS lectura_id;    
        RETURN;    
    END;    
  
    -- 2. Extraer datos  
    DECLARE @v_id UNIQUEIDENTIFIER = COALESCE(TRY_CONVERT(UNIQUEIDENTIFIER, JSON_VALUE(@p_payload, '$.id')), NEWID());    
    DECLARE @v_portero_id_erp INT = TRY_CAST(JSON_VALUE(@p_payload, '$.portero_id_erp') AS INT);    
  
    IF @v_portero_id_erp IS NULL    
    BEGIN    
        SELECT CAST(0 AS BIT) AS success, N'portero_id_erp es obligatorio' AS mensaje, NULL AS lectura_id;    
        RETURN;    
    END;    
  
    BEGIN TRY    
        MERGE dbo.CLI547_AGM_MMA_PORTERO_LECTURAS AS target    
        USING (SELECT @v_id AS lid) AS source ON target.id = source.lid    
        WHEN MATCHED THEN UPDATE SET    
            portero_id_erp       = @v_portero_id_erp,    
            tractor_id_erp       = COALESCE(TRY_CAST(JSON_VALUE(@p_payload, '$.tractor_id_erp') AS INT), target.tractor_id_erp),    
            tractor_codigo       = COALESCE(JSON_VALUE(@p_payload, '$.tractor_codigo'), target.tractor_codigo),    
            tractor_leido_at     = COALESCE(TRY_CAST(JSON_VALUE(@p_payload, '$.tractor_leido_at') AS DATETIME2), target.tractor_leido_at),    
            implemento_id_erp    = COALESCE(TRY_CAST(JSON_VALUE(@p_payload, '$.implemento_id_erp') AS INT), target.implemento_id_erp),    
            implemento_codigo    = COALESCE(JSON_VALUE(@p_payload, '$.implemento_codigo'), target.implemento_codigo),    
            implemento_leido_at  = COALESCE(TRY_CAST(JSON_VALUE(@p_payload, '$.implemento_leido_at') AS DATETIME2), target.implemento_leido_at),    
            trabajador_id_erp    = COALESCE(TRY_CAST(JSON_VALUE(@p_payload, '$.trabajador_id_erp') AS INT), target.trabajador_id_erp),    
            trabajador_codigo    = COALESCE(JSON_VALUE(@p_payload, '$.trabajador_codigo'), target.trabajador_codigo),    
            operador_leido_at    = COALESCE(TRY_CAST(JSON_VALUE(@p_payload, '$.operador_leido_at') AS DATETIME2), target.operador_leido_at),    
            cultivo_id_erp       = COALESCE(TRY_CAST(JSON_VALUE(@p_payload, '$.cultivo_id_erp') AS INT), target.cultivo_id_erp),    
            cultivo_nombre       = COALESCE(JSON_VALUE(@p_payload, '$.cultivo_nombre'), target.cultivo_nombre),    
            comentario           = COALESCE(JSON_VALUE(@p_payload, '$.comentario'), target.comentario),    
            dispositivo_id       = COALESCE(JSON_VALUE(@p_payload, '$.dispositivo_id'), target.dispositivo_id),    
            hora_sincronizacion  = GETUTCDATE()    
        WHEN NOT MATCHED THEN INSERT (    
            id, portero_id_erp, tractor_id_erp, tractor_codigo, tractor_leido_at,    
            implemento_id_erp, implemento_codigo, implemento_leido_at,    
            trabajador_id_erp, trabajador_codigo, operador_leido_at,    
            cultivo_id_erp, cultivo_nombre, comentario, dispositivo_id,    
            hora_sincronizacion,    
            hora_evento   -- 🔥 Columna que faltaba    
        ) VALUES (    
            @v_id,    
            @v_portero_id_erp,    
            TRY_CAST(JSON_VALUE(@p_payload, '$.tractor_id_erp') AS INT),    
            JSON_VALUE(@p_payload, '$.tractor_codigo'),    
            TRY_CAST(JSON_VALUE(@p_payload, '$.tractor_leido_at') AS DATETIME2),    
            TRY_CAST(JSON_VALUE(@p_payload, '$.implemento_id_erp') AS INT),    
            JSON_VALUE(@p_payload, '$.implemento_codigo'),    
            TRY_CAST(JSON_VALUE(@p_payload, '$.implemento_leido_at') AS DATETIME2),    
            TRY_CAST(JSON_VALUE(@p_payload, '$.trabajador_id_erp') AS INT),    
            JSON_VALUE(@p_payload, '$.trabajador_codigo'),    
            TRY_CAST(JSON_VALUE(@p_payload, '$.operador_leido_at') AS DATETIME2),    
            TRY_CAST(JSON_VALUE(@p_payload, '$.cultivo_id_erp') AS INT),    
            JSON_VALUE(@p_payload, '$.cultivo_nombre'),    
            JSON_VALUE(@p_payload, '$.comentario'),    
            JSON_VALUE(@p_payload, '$.dispositivo_id'),    
            GETUTCDATE(),                                    -- hora_sincronizacion    
            COALESCE(    
                TRY_CAST(JSON_VALUE(@p_payload, '$.tractor_leido_at') AS DATETIME2),    
                TRY_CAST(JSON_VALUE(@p_payload, '$.implemento_leido_at') AS DATETIME2),    
                TRY_CAST(JSON_VALUE(@p_payload, '$.operador_leido_at') AS DATETIME2),    
                GETUTCDATE()    
            )                                                -- 🔥 hora_evento (prioriza tractor → implemento → operador → UTC)    
        );    
  
        SELECT CAST(1 AS BIT) AS success, N'Lectura registrada correctamente' AS mensaje, CAST(@v_id AS NVARCHAR(36)) AS lectura_id;    
    END TRY    
    BEGIN CATCH    
        SELECT CAST(0 AS BIT) AS success, CONCAT(N'Error: ', ERROR_MESSAGE()) AS mensaje, NULL AS lectura_id;    
    END CATCH;    
END;    
GO
--------
use ERPHispatec
sp_helptext 'SP_MMA_TPM_KPI_RESUMEN'
CREATE   PROCEDURE dbo.CLI547_AGMSP_MMA_COMPLETAR_FALLA_MECANICA  
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
            hora_final          = TRY_CAST(@p_hora_fin_real    AS TIME),  
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
--------
CREATE   PROCEDURE dbo.CLI547_AGMSP_MMA_GET_REGISTROS_SUPERVISOR  
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
  
        -- Proceso (join solo para nombre/código)  
        r.proceso_id,  
        ISNULL(p.nombre, r.proceso_vehiculo)    AS proceso_nombre,  
        ISNULL(p.codigo, r.proceso_vehiculo)    AS proceso_codigo,  
  
        -- Cultivo (snapshot guardado al sincronizar)  
        r.cultivo_id_erp,  
        r.nombre_cultivo_snapshot               AS nombre_cultivo,  
  
        -- Personas (snapshots guardados al sincronizar)  
        r.operador_id_erp,  
        r.nombre_operador_snapshot              AS nombre_operador,  
        r.supervisor_id_erp,  
        r.nombre_supervisor_snapshot            AS nombre_supervisor,  
  
        -- 👇 NUEVO: identificador del usuario ERP del operador (sin duplicar)  
        u.operador_usuario_erp_id,  
  
        -- Equipos (snapshots guardados al sincronizar)  
        r.tractor_id_erp,  
        r.codigo_tractor_snapshot               AS codigo_tractor,  
        r.implemento_id_erp,  
        r.codigo_implemento_snapshot            AS codigo_implemento,  
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
  
        -- Sub-entidades embebidas como JSON  
  
        -- Horómetros / KM  
        (SELECT  
            h.tractor_inicio,  
            h.tractor_final,  
            h.implemento_inicio,  
            h.implemento_final  
         FROM dbo.CLI547_AGM_MMA_HOROMETROS h  
         WHERE h.registro_id = r.id  
         FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)                          AS horometro_json,  
  
        -- Tiempos de turno  
        (SELECT  
            CONVERT(VARCHAR(8), tt.hora_salida_taller, 108)  AS hora_salida_taller,  
            CONVERT(VARCHAR(8), tt.hora_llegada_punto, 108)  AS hora_llegada_punto,  
            CONVERT(VARCHAR(8), tt.hora_salida_punto, 108)   AS hora_salida_punto,  
            CONVERT(VARCHAR(8), tt.hora_llegada_taller, 108) AS hora_llegada_taller,  
            tt.hora_refrigerio  
         FROM dbo.CLI547_AGM_MMA_TIEMPOS_TURNO tt  
         WHERE tt.registro_id = r.id  
         FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)                          AS tiempos_turno_json,  
  
        -- Datos específicos de vehículo  
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
        ELSE NULL END            AS vehiculo_json,  
  
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
    LEFT JOIN dbo.CLI547_AGM_MMA_PROCESOS p     ON p.id  = r.proceso_id  
    LEFT JOIN dbo.CLI547_AGM_MMA_CAJAS_CAMBIOS cc   ON cc.id = r.caja_cambios_id  
  
    -- 👇 NUEVO: OUTER APPLY para obtener el usuario ERP del operador (sin duplicar)  
    OUTER APPLY (  
        SELECT TOP 1 u.Id AS operador_usuario_erp_id  
        FROM dbo.Trabajadores t  
        INNER JOIN dbo.Sujetos s ON s.Id = t.Id_Sujeto  
        INNER JOIN dbo.Usuarios u ON u.Id_Sujeto = s.Id  
        WHERE t.Id = r.operador_id_erp  
    ) AS u  
  
    WHERE r.fecha = @p_fecha  
      AND (@p_turno IS NULL OR r.turno = @p_turno)  
      AND r.estado <> 'permanently_failed'  
  
    ORDER BY r.created_at DESC;  
END;  
GO
------
CREATE    PROCEDURE dbo.CLI547_AGMSP_MMA_GET_JORNADAS_SUPERVISOR    
    @p_fecha DATE,    
    @p_turno NVARCHAR(10) = NULL    
AS    
BEGIN    
    SET NOCOUNT ON;    
    SELECT    
        j.id,    
        j.usuario_erp_id,    
        LTRIM(RTRIM(CONCAT(s.PrimerApellido, ' ', s.SegundoApellido, ' ', s.Nombre))) AS nombre_usuario,    
        j.dispositivo_id,    
        j.turno,    
        j.jornada_inicio_at,    
        j.jornada_fin_at,    
        CAST(CASE WHEN j.jornada_fin_at IS NOT NULL THEN 1 ELSE 0 END AS BIT) AS jornada_cerrada,    
        (SELECT COUNT(*)    
        FROM dbo.CLI547_AGM_MMA_REGISTROS_DIARIOS r    
        WHERE r.operador_id_erp = t.Id    
        AND r.fecha = @p_fecha    
        AND r.turno = j.turno)                                   AS total_registros,    
        (SELECT COUNT(*)    
        FROM dbo.CLI547_AGM_MMA_REGISTROS_DIARIOS r    
        WHERE r.operador_id_erp = t.Id    
        AND r.fecha = @p_fecha    
        AND r.turno = j.turno    
        AND r.sincronizado_erp = 1)                              AS registros_sincronizados,    
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
END  
GO
------
  
-- 5.13 Aprobar/Rechazar registro  
CREATE   PROCEDURE dbo.CLI547_AGMSP_MMA_APROBAR_REGISTRO  
    @p_registro_id       NVARCHAR(36),  
    @p_supervisor_erp_id INT,  
    @p_accion            NVARCHAR(10),  
    @p_motivo            NVARCHAR(MAX) = NULL,  
    @p_success           BIT             OUTPUT,  
    @p_mensaje           NVARCHAR(500)   OUTPUT  
AS  
BEGIN  
    SET NOCOUNT ON;  
    DECLARE @v_uid UNIQUEIDENTIFIER = TRY_CAST(@p_registro_id AS UNIQUEIDENTIFIER);  
    IF @v_uid IS NULL  
    BEGIN  
        SET @p_success = 0; SET @p_mensaje = N'ID de registro inválido';  
        SELECT @p_success AS success, @p_mensaje AS mensaje;  
        RETURN;  
    END;  
  
    DECLARE @v_estado_actual NVARCHAR(20);  
    SELECT @v_estado_actual = estado FROM dbo.CLI547_AGM_MMA_REGISTROS_DIARIOS WHERE id = @v_uid;  
    IF @v_estado_actual IS NULL  
    BEGIN  
        SET @p_success = 0; SET @p_mensaje = N'Registro no encontrado';  
        SELECT @p_success AS success, @p_mensaje AS mensaje;  
        RETURN;  
    END;  
  
    DECLARE @v_nuevo_estado NVARCHAR(20) = CASE @p_accion WHEN 'aprobar' THEN 'aprobado' WHEN 'rechazar' THEN 'rechazado' ELSE NULL END;  
    IF @v_nuevo_estado IS NULL  
    BEGIN  
        SET @p_success = 0; SET @p_mensaje = N'Acción inválida. Use "aprobar" o "rechazar"';  
        SELECT @p_success AS success, @p_mensaje AS mensaje;  
        RETURN;  
    END;  
  
    IF @v_estado_actual = @v_nuevo_estado  
    BEGIN  
        SET @p_success = 1; SET @p_mensaje = CONCAT(N'Registro ya estaba ', @v_nuevo_estado, N' (idempotente)');  
        SELECT @p_success AS success, @p_mensaje AS mensaje, @p_registro_id AS registro_id;  
        RETURN;  
    END;  
  
    IF @v_estado_actual NOT IN ('completado', 'borrador')  
    BEGIN  
        SET @p_success = 0; SET @p_mensaje = CONCAT(N'El registro ya fue ', @v_estado_actual, N' y no puede modificarse');  
        SELECT @p_success AS success, @p_mensaje AS mensaje;  
        RETURN;  
    END;  
  
    BEGIN TRY  
        UPDATE dbo.CLI547_AGM_MMA_REGISTROS_DIARIOS  
        SET estado = @v_nuevo_estado,  
            supervisor_id_erp = @p_supervisor_erp_id,  
            aprobado_por_erp = @p_supervisor_erp_id,  
            aprobado_at = GETDATE(),  
            motivo_rechazo = CASE WHEN @p_accion = 'rechazar' THEN @p_motivo ELSE NULL END,  
            updated_at = GETDATE()  
        WHERE id = @v_uid;  
        SET @p_success = 1; SET @p_mensaje = CONCAT(N'Registro ', @v_nuevo_estado, N' correctamente');  
        SELECT @p_success AS success, @p_mensaje AS mensaje, @p_registro_id AS registro_id;  
    END TRY  
    BEGIN CATCH  
        SET @p_success = 0; SET @p_mensaje = CONCAT(N'Error al actualizar: ', ERROR_MESSAGE());  
        SELECT @p_success AS success, @p_mensaje AS mensaje;  
    END CATCH;  
END;  
GO
----------
CREATE   PROCEDURE [dbo].[CLI547_AGM_SP_MMA_REPORTE_PORTERO_DETALLADO]    
(    
    @FechaInicio DATE = NULL,    
    @FechaFin    DATE = NULL,    
    @Cultivo     NVARCHAR(100) = NULL,    
    @Tractor     VARCHAR(50) = NULL,    
    @Implemento  VARCHAR(50) = NULL    
)    
AS    
BEGIN    
    SET NOCOUNT ON;    
  
    IF @FechaInicio IS NOT NULL    
       AND @FechaFin IS NOT NULL    
       AND @FechaInicio > @FechaFin    
    BEGIN    
        THROW 50001, 'La fecha de inicio no puede ser mayor que la fecha final.', 1;    
    END;    
  
    IF OBJECT_ID('tempdb..#Portero') IS NOT NULL    
        DROP TABLE #Portero;    
  
    SELECT    
        PL.id AS IdLecturaPortero,    
  
        CAST(PL.hora_evento AS DATE) AS Fecha,    
        CONVERT(VARCHAR(8), PL.hora_evento, 108) AS HoraMovimiento,    
  
        PL.portero_id_erp AS IdPortero,    
        U.Nombre AS NombrePortero,    
  
        PL.tractor_id_erp AS IdTractor,    
        PL.tractor_codigo AS Tractor,    
  
        PL.implemento_id_erp AS IdImplemento,    
        PL.implemento_codigo AS Implemento,    
  
        PL.trabajador_id_erp AS IdOperador,    
        PL.trabajador_codigo AS CodigoOperador,    
  
        LTRIM(RTRIM(    
            ISNULL(S.Nombre, '') + ' ' +    
            ISNULL(S.PrimerApellido, '') + ' ' +    
            ISNULL(S.SegundoApellido, '')    
        )) AS NombreOperador,    
  
        PL.cultivo_id_erp AS IdCultivo,    
        PL.cultivo_nombre AS Cultivo,    
  
        PL.comentario AS ComentarioPortero,    
  
        CASE    
            WHEN UPPER(ISNULL(PL.comentario, '')) LIKE '%ENTRADA%'    
                THEN 'ENTRADA'    
            WHEN UPPER(ISNULL(PL.comentario, '')) LIKE '%SALIDA%'    
                THEN 'SALIDA'    
            ELSE 'OTRO'    
        END AS TipoMovimiento,    
  
        CONVERT(VARCHAR(8), PL.tractor_leido_at, 108) AS HoraLecturaTractor,    
        CONVERT(VARCHAR(8), PL.implemento_leido_at, 108) AS HoraLecturaImplemento,    
        CONVERT(VARCHAR(8), PL.operador_leido_at, 108) AS HoraLecturaOperador,    
  
        PL.dispositivo_id AS Dispositivo,    
  
        PL.hora_sincronizacion AS HoraSincronizacion,    
  
        CASE    
            WHEN PL.hora_sincronizacion IS NULL    
                THEN 'POR SINCRONIZAR'    
            ELSE 'SINCRONIZADO'    
        END AS EstadoSincronizacionPortero    
  
    INTO #Portero    
  
    FROM dbo.CLI547_AGM_MMA_PORTERO_LECTURAS AS PL    
  
    LEFT JOIN dbo.Usuarios AS U    
        ON TRY_CONVERT(INT, U.Codigo) = PL.portero_id_erp    
  
    LEFT JOIN dbo.Trabajadores AS T    
        ON T.Id = PL.trabajador_id_erp    
  
    LEFT JOIN dbo.Sujetos AS S    
        ON S.Id = T.Id_Sujeto    
  
    WHERE    
        (@FechaInicio IS NULL OR PL.hora_evento >= @FechaInicio)    
        AND (@FechaFin IS NULL OR PL.hora_evento < DATEADD(DAY, 1, @FechaFin))    
        AND (@Cultivo IS NULL OR PL.cultivo_nombre LIKE '%' + @Cultivo + '%')    
        AND (@Tractor IS NULL OR PL.tractor_codigo LIKE '%' + @Tractor + '%')    
        AND (@Implemento IS NULL OR PL.implemento_codigo LIKE '%' + @Implemento + '%')    
        AND PL.trabajador_id_erp IS NOT NULL    
        AND PL.tractor_id_erp IS NOT NULL;    
  
    -- Resultado detallado (sin cambios en columnas)    
    SELECT * FROM #Portero    
    ORDER BY Fecha DESC, HoraMovimiento DESC;    
  
    -- KPIs (sin cambios)    
    SELECT    
        COUNT(*) AS TotalMovimientos,    
        SUM(CASE WHEN EstadoSincronizacionPortero = 'SINCRONIZADO' THEN 1 ELSE 0 END) AS TotalSincronizados,    
        SUM(CASE WHEN EstadoSincronizacionPortero = 'POR SINCRONIZAR' THEN 1 ELSE 0 END) AS TotalPorSincronizar,    
        CAST(100.0 * SUM(CASE WHEN EstadoSincronizacionPortero = 'SINCRONIZADO' THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0) AS DECIMAL(10,2)) AS TasaSincronizacion,    
        SUM(CASE WHEN TipoMovimiento = 'ENTRADA' THEN 1 ELSE 0 END) AS TotalEntradas,    
        SUM(CASE WHEN TipoMovimiento = 'SALIDA' THEN 1 ELSE 0 END) AS TotalSalidas,    
        SUM(CASE WHEN TipoMovimiento = 'OTRO' THEN 1 ELSE 0 END) AS TotalOtros,    
        COUNT(DISTINCT IdTractor) AS TotalMaquinarias,    
        COUNT(DISTINCT IdImplemento) AS TotalImplementos,    
        COUNT(DISTINCT IdOperador) AS TotalOperadores    
    FROM #Portero;    
  
    DROP TABLE #Portero;    
END;    
GO
-------
  
CREATE   PROCEDURE [dbo].[CLI547_AGM_SP_MMA_ANALISIS_OPERATIVO_CONSOLIDADO]  
    @p_fecha_inicio DATE = NULL,  
    @p_fecha_fin DATE = NULL,  
    @p_tipo_registro VARCHAR(20) = NULL,  
    @p_estado VARCHAR(20) = NULL,  
    @p_operador_id INT = NULL,  
    @p_tractor_id INT = NULL  
AS  
BEGIN  
    SET NOCOUNT ON;  
  
    IF @p_fecha_inicio IS NULL  
        SET @p_fecha_inicio = DATEADD(DAY, -30, CAST(GETDATE() AS DATE));  
  
    IF @p_fecha_fin IS NULL  
        SET @p_fecha_fin = CAST(GETDATE() AS DATE);  
  
    IF @p_fecha_inicio > @p_fecha_fin  
    BEGIN  
        THROW 50001, 'La fecha de inicio no puede ser mayor que la fecha final.', 1;  
    END;  
  
    SELECT  
        rd.numero_registro AS Registro,  
        rd.fecha AS Fecha,  
        rd.turno AS Turno,  
        rd.tipo_registro AS Tipo_Registro,  
        rd.estado AS Estado,  
  
        CASE  
            WHEN rd.tipo_registro = 'tractor'  
                THEN p.nombre  
            ELSE rd.proceso_vehiculo  
        END AS Proceso,  
  
        rd.nombre_operador_snapshot AS Operador,  
        rd.nombre_supervisor_snapshot AS Supervisor,  
        rd.codigo_tractor_snapshot AS Equipo_Principal,  
        rd.codigo_implemento_snapshot AS Equipo_Secundario,  
  
        CASE  
            WHEN rd.tipo_registro = 'tractor' THEN 'HORAS'  
            ELSE 'KM'  
        END AS Unidad_Trabajo,  
  
        CAST(ISNULL(h.tractor_inicio, 0) AS DECIMAL(10,2)) AS Inicio_Equipo,  
        CAST(ISNULL(h.tractor_final, 0) AS DECIMAL(10,2)) AS Final_Equipo,  
        CAST(ISNULL(h.horas_tractor, 0) AS DECIMAL(10,2)) AS Horas_Km_Trabajados,  
  
        ISNULL(tt.minutos_efectivos, 0) AS Minutos_Efectivos,  
  
        CASE  
            WHEN tt.hora_salida_taller IS NOT NULL  
             AND tt.hora_llegada_taller IS NOT NULL  
            THEN DATEDIFF(  
                MINUTE,  
                tt.hora_salida_taller,  
                tt.hora_llegada_taller  
            )  
            ELSE 0  
        END AS Minutos_Totales,  
  
        CASE  
            WHEN tt.hora_salida_taller IS NOT NULL  
             AND tt.hora_llegada_taller IS NOT NULL  
             AND DATEDIFF(  
                    MINUTE,  
                    tt.hora_salida_taller,  
                    tt.hora_llegada_taller  
                 ) > 0  
            THEN CAST(  
                ISNULL(tt.minutos_efectivos, 0) * 100.0  
                / DATEDIFF(  
                    MINUTE,  
                    tt.hora_salida_taller,  
                    tt.hora_llegada_taller  
                  )  
                AS DECIMAL(10,2)  
            )  
            ELSE NULL  
        END AS Porcentaje_Eficiencia,  
  
        CAST(ISNULL(l.Total_Hectareas, 0) AS DECIMAL(10,2)) AS Hectareas_Trabajadas,  
        ISNULL(b.Total_Bines, 0) AS Total_Bines,  
        ISNULL(rd.cantidad_tancadas, 0) AS Total_Tancadas,  
        CAST(ISNULL(cv.Total_Galones, 0) AS DECIMAL(10,2)) AS Galones_Consumidos,  
  
        CASE  
            WHEN rd.tipo_registro = 'vehiculo'  
             AND ISNULL(cv.Total_Galones, 0) > 0  
            THEN CAST(  
                ISNULL(h.horas_tractor, 0)  
                / NULLIF(cv.Total_Galones, 0)  
                AS DECIMAL(10,2)  
            )  
            ELSE NULL  
        END AS Rendimiento_KM_Galon,  
  
        CAST(  
            ISNULL(p.rendimiento_teorico, 1.0)  
            AS DECIMAL(10,2)  
        ) AS Capacidad_Nominal_Teorica,  
  
        CAST(  
            CASE  
                WHEN rd.tipo_registro = 'tractor'  
                 AND ISNULL(h.horas_tractor, 0) > 0  
                THEN ISNULL(l.Total_Hectareas, 0)  
                     / NULLIF(ISNULL(h.horas_tractor, 0), 0)  
                ELSE 0  
            END  
            AS DECIMAL(10,2)  
        ) AS Rendimiento_Real,  
  
        CAST(  
            CASE  
                WHEN rd.tipo_registro = 'tractor'  
                 AND p.rendimiento_teorico > 0  
                 AND ISNULL(h.horas_tractor, 0) > 0  
                 AND ISNULL(l.Total_Hectareas, 0) > 0  
                THEN (  
                    (  
                        ISNULL(l.Total_Hectareas, 0)  
                        / NULLIF(ISNULL(h.horas_tractor, 0), 0)  
                    )  
                    / p.rendimiento_teorico  
                    - 1  
                ) * 100  
                ELSE 0  
            END  
            AS DECIMAL(10,2)  
        ) AS Desviacion_Rendimiento_Porcentaje,  
  
        CAST(  
            CASE  
                WHEN (  
                    ISNULL(  
                        DATEDIFF(  
                            MINUTE,  
                            tt.hora_salida_taller,  
                            tt.hora_llegada_punto  
                        ),  
                        0  
                    )  
                    +  
                    ISNULL(  
                        DATEDIFF(  
                            MINUTE,  
                            tt.hora_salida_punto,  
                            tt.hora_llegada_taller  
                        ),  
                        0  
                    )  
                ) > 0  
                THEN 1 -  
                    CAST(  
                        (  
                            ISNULL(  
                                DATEDIFF(  
                                    MINUTE,  
                                    tt.hora_salida_taller,  
                                    tt.hora_llegada_punto  
                                ),  
                                0  
                            )  
                            +  
                            ISNULL(  
                                DATEDIFF(  
                                    MINUTE,  
                                    tt.hora_salida_punto,  
                                    tt.hora_llegada_taller  
                                ),  
                                0  
                            )  
                        ) AS FLOAT  
                    ) / 450  
                ELSE 1  
            END  
            AS DECIMAL(10,2)  
        ) AS I_TR,  
  
        ISNULL(ch.Total_Fallas, 0) AS Fallas_Checklist,  
  
        ISNULL(pt.Total_Paros_Tractor, 0)  
        + ISNULL(pv.Total_Paros_Vehiculo, 0) AS Total_Paros,  
  
        ISNULL(pt.Minutos_Parados_Tractor, 0)  
        + ISNULL(pv.Minutos_Parados_Vehiculo, 0) AS Minutos_Parados,  
  
        CASE  
            WHEN ISNULL(ch.Total_Fallas, 0) > 0  
                THEN 'OBSERVADO POR CHECKLIST'  
  
            WHEN ISNULL(pt.Minutos_Parados_Tractor, 0)  
               + ISNULL(pv.Minutos_Parados_Vehiculo, 0) > 60  
                THEN 'OBSERVADO POR PAROS'  
  
            WHEN ISNULL(h.horas_tractor, 0) = 0  
                THEN 'SIN HORAS/KM REGISTRADOS'  
  
            WHEN rd.tipo_registro = 'tractor'  
             AND p.rendimiento_teorico > 0  
             AND ISNULL(l.Total_Hectareas, 0) > 0  
             AND ISNULL(h.horas_tractor, 0) > 0  
             AND (  
                    (  
                        ISNULL(l.Total_Hectareas, 0)  
                        / NULLIF(ISNULL(h.horas_tractor, 0), 0)  
                    )  
                    / p.rendimiento_teorico  
                 ) < 0.80  
                THEN 'RENDIMIENTO BAJO (<80% DE C_N)'  
  
            ELSE 'OPERATIVO'  
        END AS Resultado_Informe,  
  
        rd.created_at AS Fecha_Creacion,  
        CONVERT(VARCHAR(8), rd.created_at, 108) AS Hora_Creacion,  
        rd.sincronizado_at AS Fecha_Sincronizacion,  
        CONVERT(VARCHAR(8), rd.sincronizado_at, 108) AS Hora_Sincronizacion,  
        rd.aprobado_at AS Fecha_Aprobacion,  
        CONVERT(VARCHAR(8), rd.aprobado_at, 108) AS Hora_Aprobacion,  
        rd.aprobado_por_erp AS Usuario_Aprobacion_ERP,  
        rd.motivo_rechazo AS Motivo_Rechazo,  
        rd.observaciones_maq AS Observacion  
  
    FROM dbo.CLI547_AGM_MMA_REGISTROS_DIARIOS AS rd  
  
    LEFT JOIN dbo.CLI547_AGM_MMA_PROCESOS AS p  
        ON p.id = rd.proceso_id  
  
    LEFT JOIN dbo.CLI547_AGM_MMA_HOROMETROS AS h  
        ON h.registro_id = rd.id  
  
    LEFT JOIN dbo.CLI547_AGM_MMA_TIEMPOS_TURNO AS tt  
        ON tt.registro_id = rd.id  
  
    LEFT JOIN  
    (  
        SELECT  
            registro_id,  
            SUM(area_trabajada_ha) AS Total_Hectareas  
        FROM dbo.CLI547_AGM_MMA_REGISTROS_LOTES  
        GROUP BY registro_id  
    ) AS l  
        ON l.registro_id = rd.id  
  
    LEFT JOIN  
    (  
        SELECT  
            registro_id,  
            SUM(TRY_CAST(cantidad AS INT)) AS Total_Bines  
        FROM dbo.CLI547_AGM_MMA_COSECHA_BINES  
        GROUP BY registro_id  
    ) AS b  
        ON b.registro_id = rd.id  
  
    LEFT JOIN  
    (  
        SELECT  
            registro_id,  
            SUM(glns) AS Total_Galones  
        FROM dbo.CLI547_AGM_MMA_COMBUSTIBLE_VEHICULO  
        GROUP BY registro_id  
    ) AS cv  
        ON cv.registro_id = rd.id  
  
    LEFT JOIN  
    (  
        SELECT  
            registro_id,  
            COUNT(*) AS Total_Fallas  
        FROM dbo.CLI547_AGM_MMA_CHECKLIST_RESULTADOS  
        WHERE LOWER(resultado) = 'mal'  
        GROUP BY registro_id  
    ) AS ch  
        ON ch.registro_id = rd.id  
  
    LEFT JOIN  
    (  
        SELECT  
            registro_id,  
            COUNT(*) AS Total_Paros_Tractor,  
            SUM(ISNULL(duracion_min, 0)) AS Minutos_Parados_Tractor  
        FROM dbo.CLI547_AGM_MMA_PAROS_EQUIPOS  
        GROUP BY registro_id  
    ) AS pt  
        ON pt.registro_id = rd.id  
  
    LEFT JOIN  
    (  
        SELECT  
            registro_id,  
            COUNT(*) AS Total_Paros_Vehiculo,  
            SUM(  
                DATEDIFF(  
                    MINUTE,  
                    hora_inicio,  
                    hora_final  
                )  
            ) AS Minutos_Parados_Vehiculo  
        FROM dbo.CLI547_AGM_MMA_PAROS_VEHICULO  
        WHERE hora_inicio IS NOT NULL  
          AND hora_final IS NOT NULL  
        GROUP BY registro_id  
    ) AS pv  
        ON pv.registro_id = rd.id  
  
    WHERE  
        rd.fecha >= @p_fecha_inicio  
        AND rd.fecha < DATEADD(DAY, 1, @p_fecha_fin)  
  
        AND (  
            @p_tipo_registro IS NULL  
            OR rd.tipo_registro = @p_tipo_registro  
        )  
  
        AND (  
            @p_estado IS NULL  
            OR rd.estado = @p_estado  
        )  
  
        AND (  
            @p_operador_id IS NULL  
            OR rd.operador_id_erp = @p_operador_id  
        )  
  
        AND (  
            @p_tractor_id IS NULL  
            OR rd.tractor_id_erp = @p_tractor_id  
        )  
  
    ORDER BY  
        rd.fecha DESC,  
        rd.numero_registro DESC;  
END;  
GO
------
  
CREATE   PROCEDURE [dbo].[CLI547_AGM_SP_MMA_TRACTORES_TABULAR_FR004]  
(  
    @FechaInicio DATE = NULL,  
    @FechaFin    DATE = NULL,  
    @Operador    NVARCHAR(200) = NULL  
)  
AS  
BEGIN  
    SET NOCOUNT ON;  
  
    IF @FechaInicio IS NOT NULL  
       AND @FechaFin IS NOT NULL  
       AND @FechaInicio > @FechaFin  
    BEGIN  
        THROW 50001,  
              'La fecha de inicio no puede ser mayor que la fecha final.',  
              1;  
    END;  
  
    IF OBJECT_ID('tempdb..#BaseRegistros') IS NOT NULL  
        DROP TABLE #BaseRegistros;  
  
    /*==============================================================  
      1. REGISTROS BASE DE TRACTORES  
    ==============================================================*/  
    SELECT  
        RD.*,  
        P.rendimiento_teorico AS Capacidad_Nominal_Teorica,  
        P.nombre AS Proceso_Nombre  
    INTO #BaseRegistros  
    FROM dbo.CLI547_AGM_MMA_REGISTROS_DIARIOS AS RD  
    LEFT JOIN dbo.CLI547_AGM_MMA_PROCESOS AS P  
        ON P.id = RD.proceso_id  
    WHERE  
        RD.tipo_registro = 'tractor'  
  
        AND (  
            @FechaInicio IS NULL  
            OR RD.fecha >= @FechaInicio  
        )  
  
        AND (  
            @FechaFin IS NULL  
            OR RD.fecha < DATEADD(DAY, 1, @FechaFin)  
        )  
  
        AND (  
            @Operador IS NULL  
            OR RD.nombre_operador_snapshot LIKE '%' + @Operador + '%'  
        );  
  
    /*==============================================================  
      2. DETALLE OPERATIVO DE TRACTORES  
    ==============================================================*/  
    ;WITH Lotes AS  
    (  
        SELECT  
            registro_id,  
  
            STRING_AGG(  
                ISNULL(lote_codigo_snapshot, ''),  
                ', '  
            ) AS Lotes_Trabajados,  
  
            STRING_AGG(  
                ISNULL(sublote_snapshot, ''),  
                ', '  
            ) AS Sectores_Trabajados,  
  
            SUM(  
                ISNULL(area_trabajada_ha, 0)  
            ) AS Hectareas_Trabajadas  
  
        FROM dbo.CLI547_AGM_MMA_REGISTROS_LOTES  
        GROUP BY registro_id  
    ),  
    Paros AS  
    (  
        SELECT  
            PE.registro_id,  
            TP.codigo AS Codigo_Tipo_Paro,  
            TP.nombre AS Tipo_Paro,  
            PE.motivo,  
            PE.hora_inicio,  
            PE.hora_final,  
            PE.galones,  
            PE.duracion_min,  
  
            ROW_NUMBER() OVER  
            (  
                PARTITION BY PE.registro_id  
                ORDER BY PE.hora_inicio  
            ) AS NroParo  
  
        FROM dbo.CLI547_AGM_MMA_PAROS_EQUIPOS AS PE  
  
        LEFT JOIN dbo.CLI547_AGM_MMA_TIPOS_PARO AS TP  
            ON TP.id = PE.tipo_paro_id  
    )  
    SELECT  
        RD.numero_registro AS Registro,  
        RD.fecha AS Fecha,  
        RD.turno AS Horario,  
        RD.estado AS Estado,  
  
        RD.Proceso_Nombre AS Proceso,  
        RD.nombre_cultivo_snapshot AS Cultivo,  
        RD.nombre_operador_snapshot AS Operador,  
        RD.nombre_supervisor_snapshot AS Supervisor,  
  
        RD.codigo_tractor_snapshot AS Tractor,  
        RD.codigo_implemento_snapshot AS Implemento,  
  
        CAST(  
            ISNULL(H.tractor_inicio, 0)  
            AS DECIMAL(10,1)  
        ) AS Horometro_Tractor_Inicio,  
  
        CAST(  
            ISNULL(H.tractor_final, 0)  
            AS DECIMAL(10,1)  
        ) AS Horometro_Tractor_Final,  
  
        CAST(  
            ISNULL(H.horas_tractor, 0)  
            AS DECIMAL(10,1)  
        ) AS Horas_Tractor,  
  
        CAST(  
            ISNULL(H.implemento_inicio, 0)  
            AS DECIMAL(10,1)  
        ) AS Horometro_Implemento_Inicio,  
  
        CAST(  
            ISNULL(H.implemento_final, 0)  
            AS DECIMAL(10,1)  
        ) AS Horometro_Implemento_Final,  
  
        CAST(  
            ISNULL(H.horas_implemento, 0)  
            AS DECIMAL(10,1)  
        ) AS Horas_Implemento,  
  
        CONVERT(  
            VARCHAR(8),  
            TT.hora_salida_taller,  
            108  
        ) AS Hora_Salida_Taller_Base,  
  
        CONVERT(  
            VARCHAR(8),  
            TT.hora_llegada_punto,  
            108  
        ) AS Hora_Llegada_Punto_Trabajo,  
  
        CONVERT(  
            VARCHAR(8),  
            TT.hora_salida_punto,  
            108  
        ) AS Hora_Salida_Punto_Trabajo,  
  
        CONVERT(  
            VARCHAR(8),  
            TT.hora_llegada_taller,  
            108  
        ) AS Hora_Llegada_Taller_Base,  
  
        ISNULL(  
            TT.minutos_efectivos,  
            0  
        ) AS Minutos_Efectivos,  
  
        CC.nombre AS Marcha_Trabajo_Caja_Cambios,  
  
        ISNULL(  
            L.Lotes_Trabajados,  
            ''  
        ) AS Lotes_Trabajados,  
  
        ISNULL(  
            L.Sectores_Trabajados,  
            ''  
        ) AS Sectores_Trabajados,  
  
        CAST(  
            ISNULL(L.Hectareas_Trabajadas, 0)  
            AS DECIMAL(10,2)  
        ) AS Hectareas_Trabajadas,  
  
        CAST(  
            ISNULL(RD.Capacidad_Nominal_Teorica, 1.0)  
            AS DECIMAL(10,2)  
        ) AS Capacidad_Nominal_Teorica,  
  
        CAST(  
            CASE  
                WHEN ISNULL(H.horas_tractor, 0) > 0  
                THEN  
                    ISNULL(L.Hectareas_Trabajadas, 0)  
                    / NULLIF(H.horas_tractor, 0)  
                ELSE 0  
            END  
            AS DECIMAL(10,2)  
        ) AS Rendimiento_Real,  
  
        CAST(  
            CASE  
                WHEN RD.Capacidad_Nominal_Teorica > 0  
                 AND ISNULL(H.horas_tractor, 0) > 0  
                 AND ISNULL(L.Hectareas_Trabajadas, 0) > 0  
                THEN  
                    (  
                        (  
                            ISNULL(L.Hectareas_Trabajadas, 0)  
                            / NULLIF(H.horas_tractor, 0)  
                        )  
                        / RD.Capacidad_Nominal_Teorica  
                        - 1  
                    ) * 100  
                ELSE 0  
            END  
            AS DECIMAL(10,2)  
        ) AS Desviacion_Rendimiento_Porcentaje,  
  
        CAST(  
            CASE  
                WHEN  
                    (  
                        ISNULL(  
                            DATEDIFF(  
                                MINUTE,  
                                TT.hora_salida_taller,  
                                TT.hora_llegada_punto  
                            ),  
                            0  
                        )  
                        +  
                        ISNULL(  
                            DATEDIFF(  
                                MINUTE,  
                                TT.hora_salida_punto,  
                                TT.hora_llegada_taller  
                            ),  
                            0  
                        )  
                    ) > 0  
                THEN  
                    1 -  
                    CAST(  
                        (  
                            ISNULL(  
                                DATEDIFF(  
                                    MINUTE,  
                                    TT.hora_salida_taller,  
                                    TT.hora_llegada_punto  
                                ),  
                                0  
                            )  
                            +  
                            ISNULL(  
                                DATEDIFF(  
                                    MINUTE,  
                                    TT.hora_salida_punto,  
                                    TT.hora_llegada_taller  
                                ),  
                                0  
                            )  
                        ) AS FLOAT  
                    ) / 450  
                ELSE 1  
            END  
            AS DECIMAL(10,2)  
        ) AS I_TR,  
  
        PR.Codigo_Tipo_Paro,  
        PR.Tipo_Paro,  
        PR.motivo AS Motivo_Paro,  
  
        CONVERT(  
            VARCHAR(8),  
            PR.hora_inicio,  
   108  
        ) AS Hora_Inicio_Paro,  
  
        CONVERT(  
            VARCHAR(8),  
            PR.hora_final,  
            108  
        ) AS Hora_Final_Paro,  
  
        ISNULL(  
            PR.duracion_min,  
            0  
        ) AS Minutos_Paro,  
  
        CAST(  
            ISNULL(PR.galones, 0)  
            AS DECIMAL(10,2)  
        ) AS Galones,  
  
        CASE  
            WHEN ISNULL(PR.duracion_min, 0) > 60  
                THEN 'OBSERVADO POR PARO'  
  
            WHEN ISNULL(H.horas_tractor, 0) = 0  
                THEN 'SIN HORAS REGISTRADAS'  
  
            ELSE 'OPERATIVO'  
        END AS Estado_Informe,  
  
        RD.observaciones_maq AS Observacion_General,  
        RD.dispositivo_id AS Dispositivo,  
        RD.created_at AS Fecha_Creacion,  
        RD.sincronizado_at AS Fecha_Sincronizacion,  
        RD.aprobado_at AS Fecha_Aprobacion,  
        RD.aprobado_por_erp AS Usuario_Aprobacion_ERP  
  
    FROM #BaseRegistros AS RD  
  
    LEFT JOIN dbo.CLI547_AGM_MMA_CAJAS_CAMBIOS AS CC  
        ON CC.id = RD.caja_cambios_id  
  
    LEFT JOIN dbo.CLI547_AGM_MMA_HOROMETROS AS H  
        ON H.registro_id = RD.id  
  
    LEFT JOIN dbo.CLI547_AGM_MMA_TIEMPOS_TURNO AS TT  
        ON TT.registro_id = RD.id  
  
    LEFT JOIN Lotes AS L  
        ON L.registro_id = RD.id  
  
    LEFT JOIN Paros AS PR  
        ON PR.registro_id = RD.id  
  
    ORDER BY  
        RD.fecha DESC,  
        RD.numero_registro DESC,  
        PR.NroParo;  
  
    /*==============================================================  
      3. DETALLE DE CHECKLIST  
    ==============================================================*/  
    SELECT  
        RD.numero_registro AS Registro,  
        RD.fecha AS Fecha,  
        RD.nombre_operador_snapshot AS Operador,  
        RD.codigo_tractor_snapshot AS Tractor,  
        RD.codigo_implemento_snapshot AS Implemento,  
  
        CAT.nombre AS Categoria_Checklist,  
        CI.nombre AS Item_Checklist,  
        CR.resultado AS Resultado_Checklist,  
        CR.observacion AS Observacion_Checklist,  
  
        CASE  
            WHEN LOWER(CR.resultado) = 'bien' THEN 'B'  
            WHEN LOWER(CR.resultado) = 'mal'  THEN 'M'  
            WHEN LOWER(CR.resultado) = 'na'   THEN 'N/A'  
            ELSE ''  
        END AS Resultado_Formato,  
  
        CASE  
            WHEN LOWER(CR.resultado) = 'mal'  
                THEN 'OBSERVADO'  
  
            WHEN LOWER(CR.resultado) = 'bien'  
                THEN 'CONFORME'  
  
            WHEN LOWER(CR.resultado) = 'na'  
                THEN 'NO APLICA'  
  
            ELSE 'SIN RESULTADO'  
        END AS Estado_Checklist  
  
    FROM #BaseRegistros AS RD  
  
    LEFT JOIN dbo.CLI547_AGM_MMA_CHECKLIST_RESULTADOS AS CR  
        ON CR.registro_id = RD.id  
  
    LEFT JOIN dbo.CLI547_AGM_MMA_CHECKLIST_ITEMS_CATALOGO AS CI  
        ON CI.id = CR.item_id  
       AND CI.tipo_registro = 'tractor'  
  
    LEFT JOIN dbo.CLI547_AGM_MMA_CHECKLIST_CATEGORIAS AS CAT  
        ON CAT.id = CI.categoria_id  
  
    ORDER BY  
        RD.fecha DESC,  
        RD.numero_registro DESC,  
        CAT.orden,  
        CI.orden;  
  
    DROP TABLE #BaseRegistros;  
END;  
GO
----------
 --CARGAR A PRODUCTIVO  ESTOS DOS SP Y ESA MIGRACION DE DATOS OK 
CREATE OR ALTER PROCEDURE dbo.CLI547_AGM_SP_MMA_DASHBOARD_FALLAS_MECANICAS_COMPLETO
    @p_fecha_desde DATE = NULL,
    @p_fecha_hasta DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;

    -- Fechas por defecto (últimos 30 días)
    IF @p_fecha_desde IS NULL SET @p_fecha_desde = DATEADD(DAY, -30, CAST(GETDATE() AS DATE));
    IF @p_fecha_hasta IS NULL SET @p_fecha_hasta = CAST(GETDATE() AS DATE);

    -- =========================================================================
    -- TABLA TEMPORAL CON LAS NUEVAS COLUMNAS DE CATEGORÍA Y APLICACIÓN
    -- =========================================================================
    CREATE TABLE #fallas_base (
        id                      UNIQUEIDENTIFIER,
        falla_mecanica_id       INT,
        falla_mecanica_nombre   VARCHAR(200),
        estado_falla            VARCHAR(30),
        created_at              DATETIME2,
        completado_at           DATETIME2,
        hora_inicio_real        TIME,
        hora_fin_real           TIME,
        tractor_id_erp          INT,
        tractor_codigo          VARCHAR(100),
        proceso_id              INT,
        tipo_paro_codigo        VARCHAR(30),
        operador_nombre         VARCHAR(300),
        supervisor_nombre       VARCHAR(300),
        mecanico_nombre         VARCHAR(300),
        falla_categoria         VARCHAR(30) NULL,   -- <-- NUEVO
        falla_aplicacion        VARCHAR(200) NULL   -- <-- NUEVO
    );

    -- Llenar la tabla temporal incluyendo las nuevas columnas
    INSERT INTO #fallas_base
    SELECT
        pe.id,
        pe.falla_mecanica_id,
        COALESCE(fm.nombre, pe.falla_mecanica_nombre) AS falla_mecanica_nombre,
        pe.estado_falla,
        pe.created_at,
        pe.completado_at,
        pe.hora_inicio_real,
        pe.hora_fin_real,
        rd.tractor_id_erp,
        rd.codigo_tractor_snapshot,
        rd.proceso_id,
        tp.codigo AS tipo_paro_codigo,
        rd.nombre_operador_snapshot,
        rd.nombre_supervisor_snapshot,
        pe.mecanico_nombre,
        fm.categoria AS falla_categoria,      -- <-- NUEVO
        fm.aplicacion AS falla_aplicacion     -- <-- NUEVO
    FROM dbo.CLI547_AGM_MMA_PAROS_EQUIPOS pe
    INNER JOIN dbo.CLI547_AGM_MMA_TIPOS_PARO tp ON tp.id = pe.tipo_paro_id
    LEFT JOIN dbo.CLI547_AGM_MMA_FALLAS_MECANICAS fm ON fm.id = pe.falla_mecanica_id
    LEFT JOIN dbo.CLI547_AGM_MMA_REGISTROS_DIARIOS rd ON rd.id = pe.registro_id
    WHERE (tp.codigo = 'MECANICO' OR pe.falla_mecanica_id IS NOT NULL)
      AND CAST(pe.created_at AS DATE) BETWEEN @p_fecha_desde AND @p_fecha_hasta;

    -- ---- 1. MÉTRICAS GENERALES ----
    DECLARE @TotalFallas INT, @Pendientes INT, @Resueltas INT;
    DECLARE @TasaResolucion DECIMAL(10,2), @TiempoPromedio DECIMAL(10,2);

    SELECT
        @TotalFallas = COUNT(*),
        @Pendientes = SUM(CASE WHEN estado_falla = 'pendiente' THEN 1 ELSE 0 END),
        @Resueltas  = SUM(CASE WHEN estado_falla = 'resuelto' THEN 1 ELSE 0 END)
    FROM #fallas_base;

    SELECT @TasaResolucion = CAST(
        100.0 * @Resueltas / NULLIF(@TotalFallas, 0)
        AS DECIMAL(10,2)
    );

    SELECT @TiempoPromedio = CAST(
        AVG(
            CASE
                WHEN estado_falla = 'resuelto'
                     AND hora_inicio_real IS NOT NULL
                     AND hora_fin_real IS NOT NULL
                THEN DATEDIFF(MINUTE, hora_inicio_real, hora_fin_real)
                ELSE NULL
            END
        ) AS DECIMAL(10,2)
    )
    FROM #fallas_base;

    -- ---- 2. PARETO DE CAUSAS (Top 5) ----
    CREATE TABLE #pareto (
        Causa      VARCHAR(200),
        Ocurrencias INT,
        Porcentaje  DECIMAL(10,2)
    );

    INSERT INTO #pareto
    SELECT TOP 5
        COALESCE(falla_mecanica_nombre, 'Sin clasificar') AS Causa,
        COUNT(*) AS Ocurrencias,
        CAST(
            100.0 * COUNT(*) / NULLIF(@TotalFallas, 0)
            AS DECIMAL(10,2)
        ) AS Porcentaje
    FROM #fallas_base
    GROUP BY COALESCE(falla_mecanica_nombre, 'Sin clasificar')
    ORDER BY Ocurrencias DESC;

    -- ---- 3. RANKING DE EQUIPOS (Top 5) ----
    CREATE TABLE #ranking (
        Tractor      VARCHAR(100),
        TotalFallas  INT,
        HorasParadas DECIMAL(10,2)
    );

    INSERT INTO #ranking
    SELECT TOP 5
        COALESCE(tractor_codigo, 'N/A') AS Tractor,
        COUNT(*) AS TotalFallas,
        CAST(
            SUM(
                CASE
                    WHEN estado_falla = 'resuelto'
                         AND hora_inicio_real IS NOT NULL
                         AND hora_fin_real IS NOT NULL
                    THEN DATEDIFF(MINUTE, hora_inicio_real, hora_fin_real)
                    ELSE 0
                END
            ) / 60.0 AS DECIMAL(10,2)
        ) AS HorasParadas
    FROM #fallas_base
    GROUP BY COALESCE(tractor_codigo, 'N/A')
    ORDER BY TotalFallas DESC;

    -- ---- 4. TENDENCIA DIARIA ----
    CREATE TABLE #tendencia (
        Fecha           DATE,
        FallasDelDia    INT,
        ResueltasDelDia INT
    );

    INSERT INTO #tendencia
    SELECT
        CAST(created_at AS DATE) AS Fecha,
        COUNT(*) AS FallasDelDia,
        SUM(CASE WHEN estado_falla = 'resuelto' THEN 1 ELSE 0 END) AS ResueltasDelDia
    FROM #fallas_base
    GROUP BY CAST(created_at AS DATE);

    -- ===================================================================
    -- RESULTADO FINAL (UNION ALL con columna Orden)
    -- ===================================================================
    SELECT
        'METRICAS' AS Seccion,
        'TotalFallas' AS Clave,
        CAST(@TotalFallas AS VARCHAR) AS Valor1,
        NULL AS Valor2,
        NULL AS Valor3,
        NULL AS Valor4,
        NULL AS Valor5,
        NULL AS Extra1,
        NULL AS Extra2,
        1 AS Orden,
        0 AS SubOrden
    UNION ALL
    SELECT 'METRICAS', 'Pendientes', CAST(@Pendientes AS VARCHAR), NULL, NULL, NULL, NULL, NULL, NULL, 1, 1
    UNION ALL
    SELECT 'METRICAS', 'Resueltas', CAST(@Resueltas AS VARCHAR), NULL, NULL, NULL, NULL, NULL, NULL, 1, 2
    UNION ALL
    SELECT 'METRICAS', 'TasaResolucion', CAST(@TasaResolucion AS VARCHAR), NULL, NULL, NULL, NULL, NULL, NULL, 1, 3
    UNION ALL
    SELECT 'METRICAS', 'TiempoPromedio', CAST(@TiempoPromedio AS VARCHAR), NULL, NULL, NULL, NULL, NULL, NULL, 1, 4

    UNION ALL

    SELECT 'PARETO_CAUSAS', Causa, CAST(Ocurrencias AS VARCHAR), CAST(Porcentaje AS VARCHAR), NULL, NULL, NULL, NULL, NULL, 2, ROW_NUMBER() OVER (ORDER BY Ocurrencias DESC)
    FROM #pareto

    UNION ALL

    SELECT 'RANKING_EQUIPOS', Tractor, CAST(TotalFallas AS VARCHAR), CAST(HorasParadas AS VARCHAR), NULL, NULL, NULL, NULL, NULL, 3, ROW_NUMBER() OVER (ORDER BY TotalFallas DESC)
    FROM #ranking

    UNION ALL

    SELECT 'TENDENCIA_DIARIA', CAST(Fecha AS VARCHAR), CAST(FallasDelDia AS VARCHAR), CAST(ResueltasDelDia AS VARCHAR), NULL, NULL, NULL, NULL, NULL, 4, ROW_NUMBER() OVER (ORDER BY Fecha DESC)
    FROM #tendencia

    ORDER BY Orden, SubOrden;

    -- ===================================================================
    -- DETALLE OPERATIVO (segundo conjunto de resultados) CON CATEGORÍA Y APLICACIÓN
    -- ===================================================================
    SELECT
        id AS ParoId,
        falla_mecanica_nombre AS FallaMecanica,
        estado_falla AS Estado,
        created_at AS FechaCreacion,
        completado_at AS FechaCompletado,
        hora_inicio_real AS HoraInicioReal,
        hora_fin_real AS HoraFinReal,
        tractor_codigo AS Tractor,
        tipo_paro_codigo AS TipoParo,
        operador_nombre AS Operador,
        supervisor_nombre AS Supervisor,
        mecanico_nombre AS Mecanico,
        falla_categoria AS Categoria,    -- <-- NUEVO
        falla_aplicacion AS Aplicacion   -- <-- NUEVO
    FROM #fallas_base
    ORDER BY created_at DESC;

    -- Limpiar tablas temporales
    DROP TABLE #fallas_base;
    DROP TABLE #pareto;
    DROP TABLE #ranking;
    DROP TABLE #tendencia;
END;
GO-----
sp_helptext 'CLI547_AGMSP_MMA_LISTAR_FALLAS_MECANICAS'
CREATE OR ALTER PROCEDURE dbo.CLI547_AGMSP_MMA_ERP_SYNC_PAYLOAD_COMPLETO
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @zona_maq NVARCHAR(50) = 'PISCO';
    DECLARE @zona_per NVARCHAR(20) = 'PCO';

    -- Cultivos: el mapper del APK lee cultivo_id_erp y nombre_cultivo.
    SELECT 'cultivos' AS catalogo, (
        SELECT
            eb.Id            AS cultivo_id_erp,
            eb.NombreComun   AS nombre_cultivo,
            eb.NombreEspecie AS nombre_especie,
            eb.NombreGenero  AS nombre_genero,
            eb.Grupo         AS grupo,
            eb.SubGrupo      AS sub_grupo
        FROM EspeciesBotanicas eb
        ORDER BY eb.NombreComun
        FOR JSON PATH
    ) AS datos;

    -- Tractores y camiones: prefijo T% cubre ambos tipos en Pisco.
    SELECT 'tractores' AS catalogo, (
        SELECT
            m.Id            AS tractor_id_erp,
            m.Identificacion AS codigo_tractor,
            m.Descripcion   AS descripcion,
            m.Marca         AS marca,
            m.Modelo        AS modelo,
            m.Matricula     AS matricula,
            m.Codigo        AS codigo_interno
        FROM Maquinaria m
        INNER JOIN Maquinaria_DatosComplementarios md ON m.Id = md.Id_Maquinaria
        INNER JOIN DatoComplementarioValor dc ON md.Id_DatosComplementarios = dc.Id
        INNER JOIN Zonas z ON dc.valor = z.Nombre
        WHERE z.Nombre = @zona_maq
          AND m.Identificacion LIKE 'T%'
        ORDER BY m.Identificacion
        FOR JSON PATH
    ) AS datos;

    -- Implementos: mismo patrón que tractores, prefijo I%.
    SELECT 'implementos' AS catalogo, (
        SELECT
            m.Id            AS implemento_id_erp,
            m.Identificacion AS codigo_implemento,
            m.Descripcion   AS descripcion,
            m.Marca         AS marca,
            m.Modelo        AS modelo,
            m.Matricula     AS matricula,
            m.Codigo        AS codigo_interno
        FROM Maquinaria m
        INNER JOIN Maquinaria_DatosComplementarios md ON m.Id = md.Id_Maquinaria
        INNER JOIN DatoComplementarioValor dc ON md.Id_DatosComplementarios = dc.Id
        INNER JOIN Zonas z ON dc.valor = z.Nombre
        WHERE z.Nombre = @zona_maq
          AND m.Identificacion LIKE 'I%'
        ORDER BY m.Identificacion
        FOR JSON PATH
    ) AS datos;

    -- Vehiculos: mismo patrón que tractores, prefijo V%.
    SELECT 'vehiculos' AS catalogo, (
        SELECT
            m.Id            AS implemento_id_erp,
            m.Identificacion AS codigo_implemento,
            m.Descripcion   AS descripcion,
            m.Marca         AS marca,
            m.Modelo        AS modelo,
            m.Matricula     AS matricula,
            m.Codigo        AS codigo_interno
        FROM Maquinaria m
        INNER JOIN Maquinaria_DatosComplementarios md ON m.Id = md.Id_Maquinaria
        INNER JOIN DatoComplementarioValor dc ON md.Id_DatosComplementarios = dc.Id
        INNER JOIN Zonas z ON dc.valor = z.Nombre
        WHERE z.Nombre = @zona_maq
          AND m.Identificacion LIKE '%V%'
        ORDER BY m.Identificacion
        FOR JSON PATH
    ) AS datos;

    -- Trabajadores
    SELECT 'trabajadores' AS catalogo, (
        SELECT
            t.Id AS trabajador_id_erp,
            u.Id AS usuario_id_erp,
            u.Codigo AS CodigoUsuario,
            SUBSTRING(t.Codigo, 6, LEN(t.Codigo)) AS cod_trabajador,
            CONCAT(s.PrimerApellido, ' ', s.SegundoApellido, ' ', s.Nombre) AS nombre_completo
        FROM sujetos s
        INNER JOIN trabajadores t ON s.Id = t.Id_Sujeto
        INNER JOIN Usuarios u ON u.id_sujeto = s.Id
        INNER JOIN DireccionesSujeto ds ON ds.Id_Sujeto = s.Id
        INNER JOIN direcciones d ON ds.Id_Direccion = d.Id
        INNER JOIN Zonas z ON d.Id_Zona = z.Id
        WHERE z.Nombre = @zona_maq
        ORDER BY s.PrimerApellido, s.SegundoApellido, s.Nombre
        FOR JSON PATH
    ) AS datos;

    -- Lotes
    SELECT 'lotes' AS catalogo, (
        SELECT
            f.Id AS finca_id_erp,
            f.Codigo AS lote_codigo,
            CAST(f.SuperficieCultivable / 10000.0 AS DECIMAL(10,2)) AS hectareas_lote,
            c.Id AS lote_id_erp,
            TRIM(c.Descripcion) AS sublote,
            CAST(c.SuperficieCultivada / 10000.0 AS DECIMAL(10,2)) AS hectareas_sublote
        FROM Fincas f
        INNER JOIN Zonas z ON f.Id_zona = z.Id
        LEFT JOIN Cultivos c ON c.Id_finca = f.Id
        WHERE z.Codigo = @zona_per
          AND (f.Codigo LIKE 'U-%' OR f.Codigo LIKE '%P_A%' OR f.Id = 640)
        ORDER BY f.Codigo, TRIM(c.Descripcion)
        FOR JSON PATH
    ) AS datos;

    -- Procesos de tractor
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

    -- Cajas de cambio (marchas de trabajo)
    SELECT 'cajas_cambios' AS catalogo, (
        SELECT id AS caja_id, nombre
        FROM dbo.CLI547_AGM_MMA_CAJAS_CAMBIOS
        ORDER BY id
        FOR JSON PATH
    ) AS datos;

    -- Tipos de paro
    SELECT 'tipos_paro' AS catalogo, (
        SELECT id AS tipo_paro_id, codigo, nombre, requiere_galones, requiere_equipo
        FROM dbo.CLI547_AGM_MMA_TIPOS_PARO
        WHERE activo = 1
        ORDER BY id
        FOR JSON PATH
    ) AS datos;

    -- Checklist items
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

    -- Último horómetro por tractor
    SELECT 'ultimo_horometro_tractores' AS catalogo, (
        SELECT
            t.tractor_id_erp,
            t.implemento_id_erp,
            t.codigo_tractor,
            T.codigo_implemento,
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
            LEFT JOIN dbo.Maquinaria m ON m.Id = rd.tractor_id_erp
            WHERE rd.tractor_id_erp IS NOT NULL
              AND h.tractor_final IS NOT NULL
              AND rd.estado IN ('completado','aprobado')
        ) t
        WHERE t.rn = 1
        ORDER BY t.tractor_id_erp, t.implemento_id_erp
        FOR JSON PATH
    ) AS datos;

    -- =========================================================================
    -- 🔥 CATÁLOGO DE FALLAS MECÁNICAS ACTUALIZADO (incluye categoria y aplicacion)
    -- =========================================================================
    SELECT 'fallas_mecanicas' AS catalogo, (
        SELECT
            id AS falla_id,
            codigo,
            nombre,
            categoria,        -- <-- NUEVO
            aplicacion        -- <-- NUEVO
        FROM dbo.CLI547_AGM_MMA_FALLAS_MECANICAS
        WHERE activo = 1
        ORDER BY nombre
        FOR JSON PATH
    ) AS datos;
END;
GO





sp_helptext 'SP_MMA_TPM_KPI_RESUMEN'

CREATE   or alter  PROCEDURE [dbo].[CLI547_AGMSP_MMA_GetPerfilProfesional]  
    @UsuarioCodigo VARCHAR(50)  
AS  
BEGIN  
    SET NOCOUNT ON;  
  
    -- Limpiar espacios para evitar problemas de cruce  
    SET @UsuarioCodigo = LTRIM(RTRIM(@UsuarioCodigo));  
  
    -- Validar existencia  
    IF NOT EXISTS (  
        SELECT 1   
        FROM dbo.Usuarios   
        WHERE LTRIM(RTRIM(Codigo)) = @UsuarioCodigo  
    )  
    BEGIN  
        RAISERROR('Usuario [%s] no encontrado en la tabla Usuarios.', 16, 1, @UsuarioCodigo);  
        RETURN;  
    END  
  
    SELECT TOP 1  
        u.id as IdUsuario,
        u.Codigo AS CodigoUsuario,                                    -- ← Para perfil_screen.dart  
        CONCAT(s.Nombre, ' ', s.PrimerApellido, ' ', s.SegundoApellido) AS NombreCompleto,  -- ← Para perfil_screen.dart  
        ISNULL((  
            SELECT TOP 1 R.Nombre   
            FROM dbo.Roles R   
            INNER JOIN dbo.Usuarios_Roles UR ON R.Id = UR.Id_Roles   
            WHERE UR.Id_Usuarios = U.Id  
            ORDER BY R.Id DESC   
        ), 'Personal Operativo') AS AreaProviene,                     -- ← Para perfil_screen.dart (Área)  
        'Fundo General' AS Fundo,                                      -- ← Valor fijo  
        ISNULL(z.Nombre, 'Sede Central') AS Sede,                      -- ← Sede real  
        s.Identificador AS DNI,                                        -- ← DNI  
        pt.Descripcion AS PuestoTrabajo,                               -- ← Puesto de trabajo  
        SUBSTRING(t.Codigo, 6, LEN(t.Codigo)) AS CodigoTrabajador,     -- ← Código de trabajador  
        CAST(u.FechaCreacion AS DATE) AS FechaCreacionUsuario,         -- ← Fecha de creación  
        CASE     
            WHEN u.FechaUltimaConexion >= DATEADD(MONTH, -3, GETDATE()) THEN 'Activo'    
            WHEN u.FechaUltimaConexion IS NOT NULL THEN 'Inactivo'    
            ELSE 'Sin accesos'    
        END AS EstadoUsuario                                          -- ← Estado  
    FROM dbo.Usuarios u        
    LEFT JOIN dbo.Sujetos s ON u.id_sujeto = s.id        
    LEFT JOIN dbo.Trabajadores t ON s.id = t.Id_Sujeto        
    LEFT JOIN dbo.PuestoTrabajo pt ON t.id_puestotrabajo = pt.id        
    LEFT JOIN dbo.Trabajadores_DatosComplementarios tdc     
           ON tdc.Id_Trabajadores = t.Id      
    LEFT JOIN dbo.DatoComplementarioValor dcv     
           ON dcv.Id = tdc.Id_DatosComplementarios      
    LEFT JOIN dbo.TecnicosCalidad tc     
           ON s.Id = tc.Id_Sujeto      
    LEFT JOIN dbo.CLI547_AGM_UsuarioConfiguracion uc     
           ON uc.id_usuario = u.id      
    LEFT JOIN dbo.DireccionesSujeto ds     
           ON s.Id = ds.Id_Sujeto    
    LEFT JOIN dbo.Direcciones d     
           ON ds.Id_Direccion = d.Id    
    LEFT JOIN dbo.Zonas z     
           ON d.Id_Zona = z.Id    
    WHERE     
        dcv.Id_DatoComplementario = '50000054'    
        AND LTRIM(RTRIM(u.Codigo)) = @UsuarioCodigo  
    ORDER BY u.FechaCreacion ASC;  
END  
-- Ejecuta en SSMS y mira qué columnas retorna:
EXEC dbo.CLI547_AGMSP_MMA_GetPerfilProfesional @UsuarioCodigo = 'JSANCHEZ'

    -- ===========================================================-- REESTRUCTURACIÓN DE CLI547_AGM_MMA_FALLAS_MECANICAS
-- Agrega columnas: categoria, aplicacion
-- Reemplaza todos los registros con los modos estandarizados
-- =====================================================================
SELECT name FROM sys.procedures WHERE name LIKE '%MMA%' ORDER BY name;

USE [ERPHispatec];  -- Ajusta según tu base de datos
GO

SET NOCOUNT ON;
GO

-- 1. Agregar columnas si no existen
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS 
               WHERE TABLE_SCHEMA='dbo' AND TABLE_NAME='CLI547_AGM_MMA_FALLAS_MECANICAS' 
               AND COLUMN_NAME='categoria')
BEGIN
    ALTER TABLE dbo.CLI547_AGM_MMA_FALLAS_MECANICAS
    ADD categoria VARCHAR(30) NULL;
    PRINT '✅ Columna categoria agregada.';
END

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS 
               WHERE TABLE_SCHEMA='dbo' AND TABLE_NAME='CLI547_AGM_MMA_FALLAS_MECANICAS' 
               AND COLUMN_NAME='aplicacion')
BEGIN
    ALTER TABLE dbo.CLI547_AGM_MMA_FALLAS_MECANICAS
    ADD aplicacion VARCHAR(200) NULL;
    PRINT '✅ Columna aplicacion agregada.';
END
GO

-- 2. Eliminar la FK (para poder truncar)
IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK__CLI547_AG__falla__256769CC')
BEGIN
    ALTER TABLE dbo.CLI547_AGM_MMA_PAROS_EQUIPOS
    DROP CONSTRAINT FK__CLI547_AG__falla__256769CC;
    PRINT '✅ FK eliminada.';
END
ELSE
    PRINT 'ℹ️ La FK no existe o ya fue eliminada.';
GO

-- 3. Truncar la tabla (borra datos y reinicia identity)
TRUNCATE TABLE dbo.CLI547_AGM_MMA_FALLAS_MECANICAS;
PRINT '✅ Tabla truncada.';
GO

-- 4. Insertar los nuevos registros (con categoria y aplicacion)
INSERT INTO dbo.CLI547_AGM_MMA_FALLAS_MECANICAS (codigo, nombre, categoria, aplicacion, activo, created_at)
VALUES
    -- ==================== MECÁNICOS ====================
    ('DESG', 'Desgastado', 'MECANICO', 'Ejes, bujes, engranajes', 1, GETDATE()),
    ('ROTO', 'Roto', 'MECANICO', 'Ejes, pernos, resortes', 1, GETDATE()),
    ('FRAC', 'Fracturado', 'MECANICO', 'Estructuras, carcasas', 1, GETDATE()),
    ('AGRI', 'Agrietado', 'MECANICO', 'Bastidores, carcasas, fundiciones', 1, GETDATE()),
    ('DEFO', 'Deformado', 'MECANICO', 'Ejes, paneles, brazos', 1, GETDATE()),
    ('DOBL', 'Doblado', 'MECANICO', 'Palancas, varillas, tuberías', 1, GETDATE()),
    ('DESAL', 'Desalineado', 'MECANICO', 'Ejes, poleas, tren delantero', 1, GETDATE()),
    ('DESBAL', 'Desbalanceado', 'MECANICO', 'Rotores, ventiladores, poleas', 1, GETDATE()),
    ('ATAS', 'Atascado', 'MECANICO', 'Válvulas, mecanismos, pistones', 1, GETDATE()),
    ('PEGA', 'Pegado', 'MECANICO', 'Pistones, válvulas, contactos eléctricos', 1, GETDATE()),
    ('TRAB', 'Trabado', 'MECANICO', 'Rodamientos, engranajes, mecanismos', 1, GETDATE()),
    ('FLOJ', 'Flojo', 'MECANICO', 'Pernos, tuercas, uniones', 1, GETDATE()),
    ('DESAJ', 'Desajustado', 'MECANICO', 'Mecanismos de control, válvulas', 1, GETDATE()),
    ('RAYA', 'Rayado', 'MECANICO', 'Superficies de cilindros, émbolos, vástagos', 1, GETDATE()),
    ('RASG', 'Rasgado', 'MECANICO', 'Correas, fajas, bandas transportadoras', 1, GETDATE()),
    ('TORC', 'Torcido', 'MECANICO', 'Ejes, brazos, vástagos', 1, GETDATE()),
    ('ESTI', 'Estirado', 'MECANICO', 'Tornillos, varillas sometidas a tracción excesiva', 1, GETDATE()),

    -- ==================== ELÉCTRICOS / ELECTRÓNICOS ====================
    ('QUEM', 'Quemado', 'ELECTRICO', 'Diodos, transistores, bobinados', 1, GETDATE()),
    ('CORT', 'Cortocircuitado', 'ELECTRICO', 'Cableado, componentes electrónicos', 1, GETDATE()),
    ('ABIE', 'Abierto', 'ELECTRICO', 'Circuitos, bobinas, soldaduras', 1, GETDATE()),
    ('SULF', 'Sulfatado', 'ELECTRICO', 'Bornes de batería, placas, Contactos, terminales', 1, GETDATE()),
    ('CARB', 'Carbonizado', 'ELECTRICO', 'Placas de contacto, conectores', 1, GETDATE()),
    ('DERR', 'Derretido', 'ELECTRICO', 'Aislantes, conectores', 1, GETDATE()),
    ('FUND', 'Fundido', 'ELECTRICO', 'Fusibles, soldaduras', 1, GETDATE()),
    ('DESP', 'Desprogramado', 'ELECTRICO', 'Controladores electrónicos', 1, GETDATE()),
    ('PELA', 'Pelado', 'ELECTRICO', 'Cables, aislantes, bandas', 1, GETDATE()),

    -- ==================== HIDRÁULICOS / NEUMÁTICOS ====================
    ('OBST', 'Obstruido', 'HIDRAULICO', 'Filtros, conductos, válvulas', 1, GETDATE()),
    ('FUG', 'Fugas', 'HIDRAULICO', 'Acoplamientos, mangueras, retenes', 1, GETDATE()),
    ('CONTAM', 'Contaminado', 'HIDRAULICO', 'Aceites, fluidos, filtros', 1, GETDATE()),
    ('AIRE', 'Aireado', 'HIDRAULICO', 'Líneas de combustible, sistemas hidráulicos', 1, GETDATE()),
    ('SOBREP', 'Sobrepresurizado', 'HIDRAULICO', 'Bombas, líneas', 1, GETDATE()),
    ('DESPRE', 'Despresurizado', 'HIDRAULICO', 'Válvulas, acumuladores', 1, GETDATE()),
    ('CAVIT', 'Cavitado', 'HIDRAULICO', 'Bombas, inyectores', 1, GETDATE()),
    ('OXID', 'Oxidado', 'HIDRAULICO', 'Cilindros, superficies metálicas', 1, GETDATE()),
    ('REVEN', 'Reventado', 'HIDRAULICO', 'Mangueras, fuelles, juntas', 1, GETDATE()),
    ('PIC', 'Picado', 'HIDRAULICO', 'Llantas o Bástagos de cilindros hidráulicos', 1, GETDATE()),

    -- ==================== LUBRICACIÓN ====================
    ('SINLUB', 'Sin lubricación', 'LUBRICACION', 'Cojinetes, bujes', 1, GETDATE()),
    ('DILUIDO', 'Diluido', 'LUBRICACION', 'Aceites o grasas', 1, GETDATE()),
    ('CONTLUB', 'Contaminado', 'LUBRICACION', 'Lubricantes, filtros', 1, GETDATE()),
    ('EMULS', 'Emulsionado', 'LUBRICACION', 'Aceites con agua', 1, GETDATE()),
    ('GOTEO', 'Con goteo o fuga', 'LUBRICACION', 'Orings, retenes', 1, GETDATE()),
    ('HUMED', 'Humedecido', 'LUBRICACION', 'Retenes, empaques', 1, GETDATE()),

    -- ==================== FÍSICO-QUÍMICOS ====================
    ('CORR', 'Corroído', 'FISICOQUIMICO', 'Carrocerías, conexiones', 1, GETDATE()),
    ('EROS', 'Erosionado', 'FISICOQUIMICO', 'Inyectores, toberas, impulsores, carcasas', 1, GETDATE()),
    ('CONG', 'Congelado', 'FISICOQUIMICO', 'Válvulas, líneas de líquido', 1, GETDATE()),
    ('EVAP', 'Evaporado', 'FISICOQUIMICO', 'Refrigerantes', 1, GETDATE());

PRINT '✅ ' + CAST(@@ROWCOUNT AS VARCHAR) + ' registros insertados correctamente.';
GO

-- 5. Recrear la FK
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK__CLI547_AG__falla__256769CC')
BEGIN
    ALTER TABLE dbo.CLI547_AGM_MMA_PAROS_EQUIPOS
    ADD CONSTRAINT FK__CLI547_AG__falla__256769CC
    FOREIGN KEY (falla_mecanica_id) REFERENCES dbo.CLI547_AGM_MMA_FALLAS_MECANICAS (id);
    PRINT '✅ FK recreada.';
END
ELSE
    PRINT 'ℹ️ La FK ya existe.';
GO

-- 6. Verificar los datos
SELECT id, codigo, nombre, categoria, aplicacion, activo
FROM dbo.CLI547_AGM_MMA_FALLAS_MECANICAS
ORDER BY categoria, id;
GO

PRINT '✅ Proceso completado exitosamente. Ahora la tabla tiene las nuevas columnas y los datos estructurados.';
sp_helptext 'SP_MMA_REPORTE_PORTERO_DETALLADO'
CREATE PROCEDURE dbo.CLI547_AGMSP_MMA_GET_PAROS_MECANICO
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

sp_helptext 'SP_MMA_TPM_KPI_RESUMEN'
select * from CLI547_AGM_FitPlanificacion
use ERPHispatec
USE PruebasAGK
CREATE OR ALTER PROCEDURE dbo.CLI547_AGMSP_MMA_GET_PAROS_MECANICO
    @p_fecha    DATE,
    @p_estado   VARCHAR(30) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        CAST(pe.id AS NVARCHAR(36)) AS paro_id,
        CAST(rd.id AS NVARCHAR(36)) AS registro_id,
        rd.numero_registro,
        CONVERT(VARCHAR(10), rd.fecha, 23) AS fecha,
        rd.turno,
        rd.operador_id_erp,
        rd.nombre_operador_snapshot AS operador_nombre,
        rd.tractor_id_erp,

        -- CORRECCIÓN DE COLLATION
        COALESCE(
            rd.codigo_tractor_snapshot COLLATE Modern_Spanish_CI_AS,
            m.Identificacion COLLATE Modern_Spanish_CI_AS
        ) AS tractor_codigo,

        tp.codigo AS tipo_paro_codigo,
        tp.nombre AS tipo_paro_nombre,
        pe.falla_mecanica_id,
        pe.falla_mecanica_nombre,
        pe.motivo AS motivo_operador,
        CONVERT(VARCHAR(8), pe.hora_inicio, 108) AS hora_inicio_operador,
        CONVERT(VARCHAR(8), pe.hora_fin_real, 108) AS hora_fin_real,
        CONVERT(VARCHAR(8), pe.hora_inicio_real, 108) AS hora_inicio_real,
        pe.mecanico_id_erp,
        pe.mecanico_nombre,
        pe.trabajo_realizado,

        -- También normalizamos la collation aquí
        ISNULL(
            pe.estado_falla COLLATE Modern_Spanish_CI_AS,
            'pendiente'
        ) AS estado_falla,

        pe.completado_at

    FROM dbo.CLI547_AGM_MMA_PAROS_EQUIPOS pe

    INNER JOIN dbo.CLI547_AGM_MMA_REGISTROS_DIARIOS rd
        ON rd.id = pe.registro_id

    INNER JOIN dbo.CLI547_AGM_MMA_TIPOS_PARO tp
        ON tp.id = pe.tipo_paro_id

    LEFT JOIN dbo.Maquinaria m
        ON m.Id = rd.tractor_id_erp

    WHERE rd.fecha = @p_fecha
      AND pe.falla_mecanica_id IS NOT NULL
      AND (
            @p_estado IS NULL
            OR pe.estado_falla COLLATE Modern_Spanish_CI_AS = @p_estado COLLATE Modern_Spanish_CI_AS
          )

    ORDER BY
        rd.fecha DESC,
        pe.hora_inicio ASC;
END;
GO




select * from usuarios where codigo = 'DGOMEZ'








sp_helptext 'SP_AGM_GestionPlanificacion'
CREATE OR ALTER PROCEDURE dbo.SP_AGM_GestionPlanificacion
    @Accion             VARCHAR(20),
    @IdPlanificacion    INT = NULL,
    @IdCampanya         INT = NULL,
    @IdSede             INT = NULL,
    @IdFundo            INT = NULL,
    @IdCultivo          INT = NULL,
    @IdVariedad         INT = NULL,
    @IdLote             INT = NULL,
    @IdSublote          INT = NULL,
    @NombreLote         VARCHAR(150) = NULL,
    @Prioridad          VARCHAR(20) = 'MEDIA',
    @Estado             VARCHAR(20) = 'PENDIENTE',
    @FechaProgramada    DATETIME = NULL,
    @UsuarioAsignado    VARCHAR(200) = NULL,
    @HectareasLote      DECIMAL(10,4) = NULL,
    @CoordenadasPoligono VARCHAR(MAX) = NULL,
    @UsuarioModificacion VARCHAR(100) = NULL,
    @RepartoJson        NVARCHAR(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @NuevaVersion BIGINT;

    BEGIN TRY
        IF @Accion = 'INSERT'
        BEGIN
            IF @IdSublote IS NULL
                THROW 50000, 'IdSublote es requerido para INSERT', 1;

            IF @HectareasLote IS NULL
            BEGIN
                SELECT @HectareasLote = HectareasLote
                FROM dbo.VW_AGM_FitSubloteCompleto
                WHERE Id_Sublote = @IdSublote;
            END

            IF @NombreLote IS NULL
            BEGIN
                SELECT @NombreLote = NombreSublote
                FROM dbo.VW_AGM_FitSubloteCompleto
                WHERE Id_Sublote = @IdSublote;
            END

            -- Obtener siguiente versión
            SELECT @NuevaVersion = ISNULL(MAX(Version), 0) + 1
            FROM dbo.CLI547_AGM_FitPlanificacion;

            INSERT INTO dbo.CLI547_AGM_FitPlanificacion (
                Id_Campanya, Id_Sede, Id_Fundo, Id_Cultivo, Id_Variedad,
                Id_Lote, Id_Sublote, Nombre_Lote, Prioridad, Estado,
                FechaProgramada, UsuarioAsignado, HectareasLote,
                CoordenadasPoligono, FechaCreacion,
                TipoPlanificacion, Id_Reparto,
                Version
            )
            VALUES (
                @IdCampanya, @IdSede, @IdFundo, @IdCultivo, @IdVariedad,
                @IdLote, @IdSublote, @NombreLote, @Prioridad, @Estado,
                @FechaProgramada, @UsuarioAsignado, @HectareasLote,
                @CoordenadasPoligono, GETDATE(),
                1, NULL,
                @NuevaVersion
            );

            SELECT SCOPE_IDENTITY() AS IdPlanificacion, 'OK' AS Resultado;
        END

        ELSE IF @Accion = 'UPDATE'
        BEGIN
            IF @IdPlanificacion IS NULL
                THROW 50000, 'IdPlanificacion requerido para UPDATE', 1;

            IF NOT EXISTS (SELECT 1 FROM dbo.CLI547_AGM_FitPlanificacion WHERE Id = @IdPlanificacion)
                THROW 50000, 'Planificacion no existe', 1;

            -- Obtener siguiente versión
            SELECT @NuevaVersion = ISNULL(MAX(Version), 0) + 1
            FROM dbo.CLI547_AGM_FitPlanificacion;

            UPDATE dbo.CLI547_AGM_FitPlanificacion
            SET
                Id_Campanya = ISNULL(@IdCampanya, Id_Campanya),
                Id_Sede = ISNULL(@IdSede, Id_Sede),
                Id_Fundo = ISNULL(@IdFundo, Id_Fundo),
                Id_Cultivo = ISNULL(@IdCultivo, Id_Cultivo),
                Id_Variedad = ISNULL(@IdVariedad, Id_Variedad),
                Id_Lote = ISNULL(@IdLote, Id_Lote),
                Id_Sublote = ISNULL(@IdSublote, Id_Sublote),
                Nombre_Lote = ISNULL(@NombreLote, Nombre_Lote),
                Prioridad = ISNULL(@Prioridad, Prioridad),
                Estado = ISNULL(@Estado, Estado),
                FechaProgramada = ISNULL(@FechaProgramada, FechaProgramada),
                UsuarioAsignado = ISNULL(@UsuarioAsignado, UsuarioAsignado),
                HectareasLote = ISNULL(@HectareasLote, HectareasLote),
                CoordenadasPoligono = ISNULL(@CoordenadasPoligono, CoordenadasPoligono),
                Version = @NuevaVersion
            WHERE Id = @IdPlanificacion;

            SELECT @IdPlanificacion AS IdPlanificacion, 'OK' AS Resultado;
        END

        ELSE IF @Accion = 'DELETE'
        BEGIN
            IF @IdPlanificacion IS NULL
                THROW 50000, 'IdPlanificacion requerido para DELETE', 1;

            IF EXISTS (SELECT 1 FROM dbo.CLI547_AGM_FitEvaluacion WHERE Id_Planificacion = @IdPlanificacion)
                THROW 50001, 'No se puede eliminar planificación con evaluaciones asociadas. Use ANULAR en su lugar.', 1;

            DELETE FROM dbo.CLI547_AGM_FitPlanificacion WHERE Id = @IdPlanificacion;

            SELECT @IdPlanificacion AS IdPlanificacion, 'OK' AS Resultado;
        END

        ELSE IF @Accion = 'ASIGNAR'
        BEGIN
            IF @IdPlanificacion IS NULL OR @UsuarioAsignado IS NULL
                THROW 50000, 'IdPlanificacion y UsuarioAsignado son requeridos para ASIGNAR', 1;

            -- Obtener siguiente versión (modifica UsuarioAsignado)
            SELECT @NuevaVersion = ISNULL(MAX(Version), 0) + 1
            FROM dbo.CLI547_AGM_FitPlanificacion;

            UPDATE dbo.CLI547_AGM_FitPlanificacion
            SET UsuarioAsignado = @UsuarioAsignado,
                Version = @NuevaVersion
            WHERE Id = @IdPlanificacion;

            SELECT @IdPlanificacion AS IdPlanificacion, 'OK' AS Resultado;
        END

        ELSE IF @Accion = 'REPROGRAMAR'
        BEGIN
            IF @IdPlanificacion IS NULL OR @FechaProgramada IS NULL
                THROW 50000, 'IdPlanificacion y FechaProgramada son requeridos para REPROGRAMAR', 1;

            -- Obtener siguiente versión (modifica FechaProgramada)
            SELECT @NuevaVersion = ISNULL(MAX(Version), 0) + 1
            FROM dbo.CLI547_AGM_FitPlanificacion;

            UPDATE dbo.CLI547_AGM_FitPlanificacion
            SET FechaProgramada = @FechaProgramada,
                Version = @NuevaVersion
            WHERE Id = @IdPlanificacion;

            SELECT @IdPlanificacion AS IdPlanificacion, 'OK' AS Resultado;
        END

        ELSE IF @Accion = 'INSERT_REPARTO'
        BEGIN
            IF @IdSublote IS NULL OR @FechaProgramada IS NULL OR @RepartoJson IS NULL
                THROW 50000, 'IdSublote, FechaProgramada y RepartoJson son requeridos para INSERT_REPARTO', 1;

            IF @HectareasLote IS NULL
                SELECT @HectareasLote = HectareasLote FROM dbo.VW_AGM_FitSubloteCompleto WHERE Id_Sublote = @IdSublote;

            IF @NombreLote IS NULL
                SELECT @NombreLote = NombreSublote FROM dbo.VW_AGM_FitSubloteCompleto WHERE Id_Sublote = @IdSublote;

            DECLARE @TotalPlantasSubloteReparto INT = CONVERT(INT, ROUND(ISNULL(@HectareasLote, 0) * 10.0, 0));
            DECLARE @SumaReparto INT;
            SELECT @SumaReparto = SUM(TRY_CAST(JSON_VALUE(value, '$.PlantasAsignadas') AS INT))
            FROM OPENJSON(@RepartoJson);

            IF @SumaReparto IS NULL OR @SumaReparto <= 0
                THROW 50003, 'El reparto debe sumar al menos 1 planta.', 1;

            IF @SumaReparto > @TotalPlantasSubloteReparto
                THROW 50002, 'La suma de plantas repartidas supera el total de plantas del sublote.', 1;

            DECLARE @IdRepartoActual UNIQUEIDENTIFIER = NEWID();

            -- Obtener siguiente versión (se asigna a TODAS las filas del reparto)
            SELECT @NuevaVersion = ISNULL(MAX(Version), 0) + 1
            FROM dbo.CLI547_AGM_FitPlanificacion;

            DECLARE @Insertados TABLE (Id INT);

            INSERT INTO dbo.CLI547_AGM_FitPlanificacion (
                Id_Campanya, Id_Sede, Id_Fundo, Id_Cultivo, Id_Variedad,
                Id_Lote, Id_Sublote, Nombre_Lote, Prioridad, Estado,
                FechaProgramada, UsuarioAsignado, HectareasLote, PlantasAsignadas,
                CoordenadasPoligono, FechaCreacion,
                TipoPlanificacion, Id_Reparto,
                Version
            )
            OUTPUT inserted.Id INTO @Insertados(Id)
            SELECT
                @IdCampanya, @IdSede, @IdFundo, @IdCultivo, @IdVariedad,
                @IdLote, @IdSublote, @NombreLote, @Prioridad, @Estado,
                @FechaProgramada, JSON_VALUE(r.value, '$.UsuarioAsignado'), @HectareasLote,
                TRY_CAST(JSON_VALUE(r.value, '$.PlantasAsignadas') AS INT),
                @CoordenadasPoligono, GETDATE(),
                2, @IdRepartoActual,
                @NuevaVersion
            FROM OPENJSON(@RepartoJson) r
            WHERE JSON_VALUE(r.value, '$.UsuarioAsignado') IS NOT NULL
              AND TRY_CAST(JSON_VALUE(r.value, '$.PlantasAsignadas') AS INT) > 0;

            SELECT Id AS IdPlanificacion, 'OK' AS Resultado FROM @Insertados;
        END

        ELSE
        BEGIN
            THROW 50000, 'Acción no válida. Use INSERT, UPDATE, DELETE, ASIGNAR, REPROGRAMAR o INSERT_REPARTO', 1;
        END
    END TRY
    BEGIN CATCH
        SELECT -1 AS IdPlanificacion, ERROR_MESSAGE() AS Resultado;
    END CATCH
END;
GO


















DECLARE @IdLugar INT = NULL;      -- o el CentroAgrotareo real
DECLARE @FechaDia DATE = CAST(GETDATE() AS DATE);
DECLARE @IdSede INT = 12;       -- o el IdSede real
DECLARE @IdCultivo INT = NULL;
DECLARE @SinceVersion BIGINT = NULL;

EXEC [dbo].[CLI547_AGM_MOBILE_MASTER_SYNC]
    @IdLugar = @IdLugar,
    @FechaDia = @FechaDia,
    @IdSede = @IdSede,
    @IdCultivo = @IdCultivo,
    @SinceVersion = @SinceVersion;


    ------------


    exec  CLI547_AGM_MOBILE_MASTER_SYNC @IdSede = 12

CREATE OR ALTER PROCEDURE [dbo].[CLI547_AGM_MOBILE_MASTER_SYNC]
(
    @IdSede       INT    = NULL,
    @SinceVersion BIGINT = NULL
)
AS
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

    -- =========================================================
    -- 1. ACTIVIDADES (GLOBAL)
    -- =========================================================
    SELECT
        id                  AS Activity_Id,
        code                AS Activity_Codigo,
        extcode             AS Activity_ExtCode,
        name                AS Activity_Nombre,
        productive          AS EsProductiva,
        isgroupal           AS EsGrupal,
        productivitylecture AS ModoLectura,
        product_default_id  AS ProductoDefault_Id
    FROM agrotareo.dbo.Tareo_activity
    WHERE active = 1
    OPTION (RECOMPILE);

    -- =========================================================
    -- 2. TIPOS DE PRODUCTIVIDAD
    -- =========================================================
    SELECT
        id                    AS ProductivityType_Id,
        name                  AS ProductivityType_Nombre,
        productivitylecture   AS ModoLectura,
        default_value         AS ValorDefecto,
        minvalue              AS Minimo,
        maxvalue              AS Maximo,
        steppervalue          AS Incremento,
        can_repeat            AS PuedeRepetir,
        app_visible           AS VisibleEnApp,
        businessunit_id,
        container_type_id,
        max_container_value,
        collection_rate_id
    FROM agrotareo.dbo.Tareo_productivitytype
    OPTION (RECOMPILE);

    -- =========================================================
    -- 3. PRODUCTOS
    -- =========================================================
    SELECT
        id            AS Product_Id,
        name          AS Product_Nombre,
        code          AS Product_Codigo,
        extcode       AS Product_ExtCode,
        container     AS EsContenedor,
        active        AS Activo,
        consumible    AS Consumible,
        businessunit_id
    FROM agrotareo.dbo.Tareo_product
    WHERE active = 1
    OPTION (RECOMPILE);

    -- =========================================================
    -- 4. RELACIÓN TIPO-PRODUCTO
    -- =========================================================
    SELECT
        id                  AS Relacion_Id,
        productivitytype_id AS ProductivityType_Id,
        product_id          AS Product_Id
    FROM agrotareo.dbo.Tareo_productivitytype_products
    OPTION (RECOMPILE);

    -- =========================================================
    -- 5. UBICACIONES (GLOBAL)
    -- =========================================================
    SELECT
        id          AS Location_Id,
        name        AS Location_Nombre,
        code        AS Location_Codigo,
        lector_code AS Location_LectorCode,
        area        AS Area,
        parent_id   AS Parent_Location_Id,
        type_id     AS TipoUbicacion_Id,
        lat,
        long
    FROM agrotareo.dbo.Tareo_location
    WHERE end_date IS NULL OR end_date >= CAST(GETDATE() AS DATE)
    OPTION (RECOMPILE);

    -- =========================================================
    -- 6. TIPOS DE UBICACIÓN
    -- =========================================================
    SELECT
        id,
        code,
        name
    FROM agrotareo.dbo.Master_locationtype
    OPTION (RECOMPILE);

    -- =========================================================
    -- 7. EMPLEADOS
    -- =========================================================
    SELECT
        ae.id               AS Employee_Id,
        ae.codeworker       AS CodigoTrabajador,
        ae.idworker         AS IdWorkerERP,
        ae.active           AS Activo,
        ae.location_id      AS Ubicacion_Id,
        ae.person_id        AS Persona_Id,
        ae.supplier_id      AS Proveedor_Id,
        p.identification    AS Documento,
        p.name              AS Nombre,
        p.firstname         AS SegundoNombre,
        p.lastname          AS Apellidos
    FROM agrotareo.dbo.Accounts_employee ae
    LEFT JOIN agrotareo.dbo.Accounts_person p ON p.id = ae.person_id
    WHERE ae.active = 1
    OPTION (RECOMPILE);

    -- =========================================================
    -- 8. PERFILES DE USUARIO (LÍDERES)
    -- =========================================================
    SELECT
        id               AS UserProfile_Id,
        code             AS Codigo,
        employee_id      AS Empleado_Id,
        group_id         AS Grupo_Id,
        person_id        AS Persona_Id,
        superintendent_id,
        user_id
    FROM agrotareo.dbo.Accounts_userprofile
    OPTION (RECOMPILE);

    -- =========================================================
    -- 9. GRUPOS Y SUBGRUPOS
    -- =========================================================
    SELECT
        id       AS Grupo_Id,
        name     AS Grupo_Nombre,
        code     AS Grupo_Codigo,
        active   AS Activo
    FROM agrotareo.dbo.Tareo_group
    WHERE active = 1
    OPTION (RECOMPILE);

    SELECT
        id       AS Subgrupo_Id,
        name     AS Subgrupo_Nombre,
        code     AS Subgrupo_Codigo,
        group_id AS Grupo_Id,
        active   AS Activo
    FROM agrotareo.dbo.Tareo_subgroup
    WHERE active = 1
    OPTION (RECOMPILE);

    -- =========================================================
    -- 10. VARIEDADES Y CULTIVOS
    -- =========================================================
    SELECT
        id       AS Variedad_Id,
        name     AS Variedad_Nombre,
        code     AS Variedad_Codigo,
        active   AS Activo
    FROM agrotareo.dbo.Tareo_variety
    WHERE active = 1
    OPTION (RECOMPILE);

    SELECT
        id       AS Cultivo_Id,
        name     AS Cultivo_Nombre,
        code     AS Cultivo_Codigo,
        active   AS Activo
    FROM agrotareo.dbo.Tareo_crop
    WHERE active = 1
    OPTION (RECOMPILE);

    -- =========================================================
    -- 11. UNIDADES DE NEGOCIO
    -- =========================================================
    SELECT
        id       AS BusinessUnit_Id,
        name     AS BusinessUnit_Nombre,
        code     AS BusinessUnit_Codigo,
        active   AS Activo
    FROM agrotareo.dbo.Tareo_businessunit
    WHERE active = 1
    OPTION (RECOMPILE);

    -- =========================================================
    -- 12. ÓRDENES DE TRABAJO ACTIVAS
    -- =========================================================
    SELECT
        id          AS TaskOrder_Id,
        start_time  AS Inicio,
        end_time    AS Fin,
        code        AS Codigo,
        user_id     AS UserProfile_Id,
        campaign_id AS Campaña_Id
    FROM agrotareo.dbo.ControlRoute_taskorder
    WHERE end_time IS NULL OR end_time >= CAST(GETDATE() AS DATE)
    OPTION (RECOMPILE);

    -- =========================================================
    -- 13. SUBLOTES / MAPA (FILTRADO POR SEDE)
    -- =========================================================
    IF @IdSede IS NOT NULL
    BEGIN
        SELECT
            cuLP.Id                                                          AS Id,
            (SELECT TOP 1 ca.Id FROM dbo.Campanyas ca
             WHERE ca.Componente = 1 ORDER BY ca.FechaInicial DESC)         AS Id_Campanya,
            @IdSede                                                         AS Id_Sede,
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
            NULL                                                            AS TotalPlantas,
            eb.NombreComun                                                  AS NombreCultivo,
            ebv.Denominacion                                                AS NombreVariedad,
            z.Nombre                                                        AS NombreSede,
            cuLP.Descripcion                                                AS NombreSublote,
            CASE WHEN geo.Geometria IS NOT NULL
                 THEN geo.Geometria.STAsText() ELSE NULL END                AS GeometriaWKT,
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
            END                                                              AS ColorCultivo,
            CAST(cuLP.Version AS BIGINT)                                     AS Version
        FROM ERPHispatec.dbo.Cultivos AS cuLP WITH (NOLOCK)
        INNER JOIN dbo.Fincas fi WITH (NOLOCK) ON fi.Id = cuLP.Id_Finca
        INNER JOIN dbo.Fincas_DatosComplementarios fdc WITH (NOLOCK) ON fi.Id = fdc.Id_Fincas
        INNER JOIN dbo.DatoComplementarioValor dcvc WITH (NOLOCK) ON dcvc.Id = fdc.Id_DatosComplementarios
        INNER JOIN dbo.DatosComplementarios dcc WITH (NOLOCK) ON dcc.Id = dcvc.Id_DatoComplementario AND dcc.Codigo = 'VAR'
        INNER JOIN dbo.EspecieBotanicaVariedad ebv WITH (NOLOCK) ON ebv.Id = dcvc.Valor
        INNER JOIN dbo.EspeciesBotanicas eb WITH (NOLOCK) ON eb.Id = ebv.Id_EspecieBotanica
        LEFT JOIN ERPHispatec.dbo.Zonas z WITH (NOLOCK) ON z.Id = fi.Id_Zona
        OUTER APPLY (
            SELECT TOP 1 g.Geometria
            FROM dbo.Cultivos_Coordenadas cc2 WITH (NOLOCK)
            JOIN dbo.CoordenadaGPS g WITH (NOLOCK) ON g.Id = cc2.Id_Coordenadas AND g.Geometria IS NOT NULL
            WHERE cc2.Id_Cultivos = cuLP.Id
        ) geo
        WHERE TRY_CAST(dcvc.Valor AS FLOAT) IS NOT NULL
          AND fi.Id_Zona = @IdSede
          AND (@SinceVersion IS NULL OR cuLP.Version > @SinceVersion)
        ORDER BY fi.Nombre, cuLP.Descripcion;
    END
END;
GO















CREATE PROCEDURE [dbo].[CLI547_AGM_MOBILE_SYNC_INSERT]
    @JsonData NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        IF ISJSON(@JsonData) = 0
        BEGIN
            RAISERROR('El parámetro @JsonData no es JSON válido.', 16, 1);
            RETURN;
        END

        -- Tablas de mapeo de IDs temporales
        DECLARE @TickageMap TABLE (TempId NVARCHAR(50), NewId INT);
        DECLARE @LocationMap TABLE (TempId NVARCHAR(50), NewId INT);
        DECLARE @ActivityMap TABLE (TempId NVARCHAR(50), NewId INT);

        -- =========================================================
        -- 1. CREACIÓN OPCIONAL DE NUEVAS UBICACIONES
        -- =========================================================
        IF EXISTS (SELECT 1 FROM OPENJSON(@JsonData, '$.locations'))
        BEGIN
            INSERT INTO agrotareo.dbo.Tareo_location (
                name, code, lector_code, center, area, parent_id, supplier_id, type_id, lat, long
            )
            OUTPUT source.temp_id, inserted.id
            INTO @LocationMap (TempId, NewId)
            SELECT
                source.name,
                source.code,
                source.lector_code,
                source.center,
                source.area,
                source.parent_id,
                source.supplier_id,
                source.type_id,
                source.lat,
                source.long
            FROM OPENJSON(@JsonData, '$.locations')
            WITH (
                temp_id NVARCHAR(50) '$.temp_id',
                name NVARCHAR(200) '$.name',
                code NVARCHAR(50) '$.code',
                lector_code NVARCHAR(50) '$.lector_code',
                center NVARCHAR(100) '$.center',
                area NVARCHAR(100) '$.area',
                parent_id INT '$.parent_id',
                supplier_id INT '$.supplier_id',
                type_id INT '$.type_id',
                lat FLOAT '$.lat',
                long FLOAT '$.long'
            ) AS source;
        END

        -- =========================================================
        -- 2. CREACIÓN OPCIONAL DE NUEVAS ACTIVIDADES
        -- =========================================================
        IF EXISTS (SELECT 1 FROM OPENJSON(@JsonData, '$.activities'))
        BEGIN
            INSERT INTO agrotareo.dbo.Tareo_activity (
                name, code, extcode, active, productive, isgroupal, productivitylecture, creation
            )
            OUTPUT source.temp_id, inserted.id
            INTO @ActivityMap (TempId, NewId)
            SELECT
                source.name,
                source.code,
                source.extcode,
                source.active,
                source.productive,
                source.isgroupal,
                source.productivitylecture,
                GETDATE()
            FROM OPENJSON(@JsonData, '$.activities')
            WITH (
                temp_id NVARCHAR(50) '$.temp_id',
                name NVARCHAR(200) '$.name',
                code NVARCHAR(50) '$.code',
                extcode NVARCHAR(50) '$.extcode',
                active BIT '$.active',
                productive BIT '$.productive',
                isgroupal BIT '$.isgroupal',
                productivitylecture NVARCHAR(50) '$.productivitylecture'
            ) AS source;
        END

        -- =========================================================
        -- 3. INSERCIÓN DE TICKAJES
        -- =========================================================
        IF EXISTS (SELECT 1 FROM OPENJSON(@JsonData, '$.tickages'))
        BEGIN
            INSERT INTO agrotareo.dbo.ControlRoute_tickage (
                initial,
                final,
                fecha,
                type,
                employee_id,
                activity_id,
                location_id,
                group_id,
                user_id,
                task_order_id,
                state,
                initialValidate,
                finalValidate,
                created
            )
            OUTPUT source.temp_id, inserted.id
            INTO @TickageMap (TempId, NewId)
            SELECT
                source.initial,
                source.final,
                CAST(source.initial AS DATE),
                source.type,
                source.employee_id,
                source.activity_id,
                source.location_id,
                source.group_id,
                source.user_id,
                source.task_order_id,
                'FINALIZADO',
                source.initialValidate,
                source.finalValidate,
                GETDATE()
            FROM OPENJSON(@JsonData, '$.tickages')
            WITH (
                temp_id NVARCHAR(50) '$.temp_id',
                initial DATETIME '$.initial',
                final DATETIME '$.final',
                type VARCHAR(20) '$.type',
                employee_id INT '$.employee_id',
                activity_id INT '$.activity_id',
                location_id INT '$.location_id',
                group_id INT '$.group_id',
                user_id INT '$.user_id',
                task_order_id INT '$.task_order_id',
                initialValidate DATETIME '$.initialValidate',
                finalValidate DATETIME '$.finalValidate'
            ) AS source;
        END

        -- =========================================================
        -- 4. INSERCIÓN DE UBICACIONES DEL TICKAJE
        -- =========================================================
        IF EXISTS (SELECT 1 FROM OPENJSON(@JsonData, '$.tickage_locations'))
        BEGIN
            INSERT INTO agrotareo.dbo.ControlRoute_tickage_locations (
                tickage_id,
                location_id
            )
            SELECT
                tm.NewId,
                tl.location_id
            FROM OPENJSON(@JsonData, '$.tickage_locations')
            WITH (
                tickage_temp_id NVARCHAR(50) '$.tickage_temp_id',
                location_id INT '$.location_id'
            ) AS tl
            INNER JOIN @TickageMap tm ON tm.TempId = tl.tickage_temp_id;
        END

        -- =========================================================
        -- 5. INSERCIÓN DE PRODUCTIVIDADES
        -- =========================================================
        IF EXISTS (SELECT 1 FROM OPENJSON(@JsonData, '$.productivity_logs'))
        BEGIN
            INSERT INTO agrotareo.dbo.Tareo_productivity_log (
                readtime,
                quantity,
                businessunit_id_id,
                employee_id_id,
                location_id_id,
                product_id,
                productivity_type_id,
                tickaje_id_id,
                userprofile_id,
                created_at
            )
            SELECT
                pl.readtime,
                pl.quantity,
                pl.businessunit_id_id,
                pl.employee_id,
                pl.location_id,
                pl.product_id,
                pl.productivity_type_id,
                tm.NewId,
                pl.userprofile_id,
                GETDATE()
            FROM OPENJSON(@JsonData, '$.productivity_logs')
            WITH (
                tickage_temp_id NVARCHAR(50) '$.tickage_temp_id',
                readtime DATETIME '$.readtime',
                quantity DECIMAL(18,3) '$.quantity',
                businessunit_id_id INT '$.businessunit_id_id',
                employee_id INT '$.employee_id',
                location_id INT '$.location_id',
                product_id INT '$.product_id',
                productivity_type_id INT '$.productivity_type_id',
                userprofile_id INT '$.userprofile_id'
            ) AS pl
            INNER JOIN @TickageMap tm ON tm.TempId = pl.tickage_temp_id;
        END

        COMMIT TRANSACTION;

        -- Resultado final
        SELECT
            'OK' AS Resultado,
            (SELECT COUNT(*) FROM @TickageMap) AS TickagesInsertados,
            (SELECT COUNT(*) FROM @LocationMap) AS UbicacionesInsertadas,
            (SELECT COUNT(*) FROM @ActivityMap) AS ActividadesInsertadas;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        SELECT 'ERROR' AS Resultado, ERROR_MESSAGE() AS ErrorMensaje;
    END CATCH;
END;
GO
select id, code, employee_id from agrotareo.dbo.Accounts_userprofile
where code = '423562'
select u.id , s.Nombre,s.PrimerApellido, s.id, t.id from usuarios u 
inner join sujetos s on u.id_sujeto = s.id
inner join trabajadores t on t.id_sujeto = s.id
where t.codigo = '465P0423562' --u.id = 1829

--code=423562, personid=11806, userid= 119, employe=11663
--465P0404732

select * FROM agrotareo.dbo.Accounts_userprofile where date_request = '2026-08-13'
select * from usuarios where id = 11663
SELECT * FROM Trabajadores where id = 11663

-- 26229, 1829, 26237
--182,627
DECLARE @FechaDia DATE = DATEADD(DAY, -1, CAST(GETDATE() AS DATE));  -- ayer
DECLARE @UserProfileId INT = 623;   -- ID del líder/capataz (Accounts_userprofile)
SELECT
    up.id               AS Lider_UserProfile_Id,
    up.code             AS Lider_Codigo,
    up.employee_id      AS Lider_Employee_Id,
    ae.codeworker       AS Lider_CodigoTrabajador,
    ae.idworker         AS Lider_IdWorkerERP,
    ae.person_id        AS Lider_Persona_Id,
    p.identification    AS Lider_Documento,
    p.name              AS Lider_Nombre,
    p.firstname         AS Lider_SegundoNombre,
    p.lastname          AS Lider_Apellidos,
    up.group_id         AS Grupo_Id,
    g.name              AS Grupo_Nombre
FROM agrotareo.dbo.Accounts_userprofile up
LEFT JOIN agrotareo.dbo.Accounts_employee ae ON ae.id = up.employee_id
LEFT JOIN agrotareo.dbo.Accounts_person p ON p.id = ae.person_id
LEFT JOIN agrotareo.dbo.Tareo_group g ON g.id = up.group_id
WHERE up.id = @UserProfileId;

----
SELECT DISTINCT
    ae.id               AS Empleado_Id,
    ae.codeworker       AS CodigoTrabajador,
    ae.idworker         AS IdWorkerERP,
    p.identification    AS Documento,
    p.name              AS Nombre,
    p.firstname         AS SegundoNombre,
    p.lastname          AS Apellidos
FROM agrotareo.dbo.ControlRoute_tickage ct
INNER JOIN agrotareo.dbo.Accounts_employee ae ON ae.id = ct.employee_id
INNER JOIN agrotareo.dbo.Accounts_person p ON p.id = ae.person_id
WHERE ct.user_id = @UserProfileId
  AND ct.fecha = @FechaDia
UNION
SELECT DISTINCT
    ae.id,
    ae.codeworker,
    ae.idworker,
    p.identification,
    p.name,
    p.firstname,
    p.lastname
FROM agrotareo.dbo.Tareo_productivity_log tpl
INNER JOIN agrotareo.dbo.Accounts_employee ae ON ae.id = tpl.employee_id_id
INNER JOIN agrotareo.dbo.Accounts_person p ON p.id = ae.person_id
WHERE tpl.userprofile_id = @UserProfileId
  AND CAST(tpl.readtime AS DATE) = @FechaDia
ORDER BY Apellidos, Nombre;
----
SELECT
    ct.id               AS Tickage_Id,
    ct.initial          AS Inicio,
    ct.final            AS Fin,
    ct.fecha            AS Fecha,
    ct.state            AS Estado,
    ct.type             AS Tipo,
    ae.codeworker       AS Trabajador_Codigo,
    p.name              AS Trabajador_Nombre,
    p.firstname         AS Trabajador_SegundoNombre,
    p.lastname          AS Trabajador_Apellidos,
    ta.name             AS Actividad,
    tl.name             AS Ubicacion
FROM agrotareo.dbo.ControlRoute_tickage ct
INNER JOIN agrotareo.dbo.Accounts_employee ae ON ae.id = ct.employee_id
INNER JOIN agrotareo.dbo.Accounts_person p ON p.id = ae.person_id
LEFT JOIN agrotareo.dbo.Tareo_activity ta ON ta.id = ct.activity_id
LEFT JOIN agrotareo.dbo.Tareo_location tl ON tl.id = ct.location_id
WHERE ct.user_id = @UserProfileId
  AND ct.fecha = @FechaDia
ORDER BY ct.initial;
-----
SELECT
    tpl.id                  AS Productividad_Id,
    tpl.readtime            AS FechaHoraLectura,
    tpl.quantity            AS Cantidad,
    ae.codeworker           AS Trabajador_Codigo,
    p.name                  AS Trabajador_Nombre,
    p.firstname             AS Trabajador_SegundoNombre,
    p.lastname              AS Trabajador_Apellidos,
    tp.name                 AS Producto,
    tpt.name                AS TipoProductividad,
    tl.name                 AS Ubicacion,
    ct.initial              AS Tickage_Inicio,
    ct.final                AS Tickage_Fin
FROM agrotareo.dbo.Tareo_productivity_log tpl
INNER JOIN agrotareo.dbo.Accounts_employee ae ON ae.id = tpl.employee_id_id
INNER JOIN agrotareo.dbo.Accounts_person p ON p.id = ae.person_id
LEFT JOIN agrotareo.dbo.Tareo_product tp ON tp.id = tpl.product_id
LEFT JOIN agrotareo.dbo.Tareo_productivitytype tpt ON tpt.id = tpl.productivity_type_id
LEFT JOIN agrotareo.dbo.Tareo_location tl ON tl.id = tpl.location_id_id
LEFT JOIN agrotareo.dbo.ControlRoute_tickage ct ON ct.id = tpl.tickaje_id_id
WHERE tpl.userprofile_id = @UserProfileId
  AND CAST(tpl.readtime AS DATE) = @FechaDia
ORDER BY tpl.readtime;
-----
SELECT
    tl.id           AS Ubicacion_Id,
    tl.name         AS Ubicacion_Nombre,
    tl.code         AS Ubicacion_Codigo,
    tl.lector_code  AS LectorCode,
    tl.area         AS Area,
    tl.parent_id    AS UbicacionPadre_Id
FROM agrotareo.dbo.ControlRoute_tickage ct
INNER JOIN agrotareo.dbo.Tareo_location tl ON tl.id = ct.location_id
WHERE ct.user_id = @UserProfileId
  AND ct.fecha = @FechaDia
UNION
SELECT
    tl.id,
    tl.name,
    tl.code,
    tl.lector_code,
    tl.area,
    tl.parent_id
FROM agrotareo.dbo.Tareo_productivity_log tpl
INNER JOIN agrotareo.dbo.Tareo_location tl ON tl.id = tpl.location_id_id
WHERE tpl.userprofile_id = @UserProfileId
  AND CAST(tpl.readtime AS DATE) = @FechaDia
ORDER BY Ubicacion_Nombre;
----
SELECT
    @UserProfileId                                   AS Lider_Id,
    @FechaDia                                        AS Fecha,
    COUNT(DISTINCT ct.id)                            AS Total_Tickajes,
    COUNT(DISTINCT ct.employee_id)                   AS Total_Trabajadores_Tickados,
    COUNT(DISTINCT tpl.id)                           AS Total_Registros_Productividad,
    SUM(ISNULL(tpl.quantity, 0))                     AS Total_Cantidad_Productividad
FROM agrotareo.dbo.ControlRoute_tickage ct
FULL OUTER JOIN agrotareo.dbo.Tareo_productivity_log tpl
    ON tpl.tickaje_id_id = ct.id
WHERE ct.user_id = @UserProfileId
  AND ct.fecha = @FechaDia
   OR (tpl.userprofile_id = @UserProfileId AND CAST(tpl.readtime AS DATE) = @FechaDia);
   ------





      CREATE  PROCEDURE [dbo].[CLI547_AGMSP_AGK_GetUserContext]
        @UsuarioCodigo VARCHAR(50)
    AS
    BEGIN
        SET NOCOUNT ON;
        SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

        SET @UsuarioCodigo = LTRIM(RTRIM(@UsuarioCodigo));

        IF NOT EXISTS (
            SELECT 1 FROM dbo.Usuarios WHERE LTRIM(RTRIM(Codigo)) = @UsuarioCodigo
        )
        BEGIN
            RAISERROR('Usuario [%s] no encontrado en la tabla Usuarios.', 16, 1, @UsuarioCodigo);
            RETURN;
        END

        SELECT TOP 1
            u.Codigo                                 AS CodigoUsuario,
            CONCAT(s.Nombre, ' ', s.PrimerApellido, ' ', s.SegundoApellido) AS NombreCompleto,
            s.Identificador                          AS DNI,
            pt.Descripcion                           AS PuestoTrabajo,
            SUBSTRING(t.Codigo, 6, LEN(t.Codigo))    AS CodigoTrabajador,
            ISNULL(z.Nombre COLLATE SQL_Latin1_General_CP1_CI_AI, 'Sede Central') AS Sede,
            z.Id                                     AS IdSede,
            ISNULL(up.center, ae.location_id)        AS CentroAgrotareo,
            up.id                                    AS UserProfileId,
            ae.id                                    AS EmployeeId,
            t.Id                                     AS IdWorkerERP,
            -- Fundo real basado en la sede
            ISNULL(f.PrimerApellido COLLATE SQL_Latin1_General_CP1_CI_AI, 'Fundo General') AS Fundo,
            f.Id                                     AS IdFundo,
            CASE 
                WHEN u.FechaUltimaConexion >= DATEADD(MONTH, -3, GETDATE()) THEN 'Activo'
                WHEN u.FechaUltimaConexion IS NOT NULL THEN 'Inactivo'
                ELSE 'Sin accesos'
            END                                       AS EstadoDescripcion,
            CAST(u.FechaCreacion AS DATE)             AS FechaCreacionUsuario
        FROM dbo.Usuarios u
        LEFT JOIN dbo.Sujetos s ON u.id_sujeto = s.id
        LEFT JOIN dbo.Trabajadores t ON s.id = t.Id_Sujeto
        LEFT JOIN dbo.PuestoTrabajo pt ON t.id_puestotrabajo = pt.id

        -- Relación con Agrotareo
        LEFT JOIN agrotareo.dbo.Accounts_employee ae ON ae.idworker = t.Id
        LEFT JOIN agrotareo.dbo.Accounts_userprofile up ON up.employee_id = ae.id

        -- Dirección / Sede (ERP)
        LEFT JOIN dbo.DireccionesSujeto ds ON s.Id = ds.Id_Sujeto
        LEFT JOIN dbo.Direcciones d ON ds.Id_Direccion = d.Id
        LEFT JOIN dbo.Zonas z ON d.Id_Zona = z.Id

        -- Relación Sede -> Fundo (asumiendo que Fincas.Id_Representante apunta a Sujetos con Nombre='FUNDO')
        OUTER APPLY (
            SELECT TOP 1
                s2.Id               AS Id,
                s2.PrimerApellido   AS PrimerApellido
            FROM dbo.Fincas fi
            INNER JOIN dbo.Sujetos s2 ON s2.Id = fi.Id_Representante
                                    AND s2.Nombre = 'FUNDO'
            WHERE fi.Id_Zona = z.Id
            ORDER BY fi.Id DESC   -- Tomar el más reciente
        ) f

        WHERE LTRIM(RTRIM(u.Codigo)) = 'JSANCHEZ'
        ORDER BY u.FechaCreacion DESC;
    END
    GO

    SP_HELPTEXT 'CLI547_AGMSP_MMA_ERP_SYNC_PAYLOAD_COMPLETO'
CREATE OR ALTER PROCEDURE dbo.CLI547_AGMSP_MMA_ERP_SYNC_PAYLOAD_COMPLETO
    @IdUsuario INT,
    @SinceVersion INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @zona_maq NVARCHAR(50) = 'PISCO';
    DECLARE @zona_per NVARCHAR(20) = 'PCO';

    -- Cultivos: el mapper del APK lee cultivo_id_erp y nombre_cultivo.
    SELECT 'cultivos' AS catalogo, (
        SELECT
            eb.Id            AS cultivo_id_erp,
            eb.NombreComun   AS nombre_cultivo,
            eb.NombreEspecie AS nombre_especie,
            eb.NombreGenero  AS nombre_genero,
            eb.Grupo         AS grupo,
            eb.SubGrupo      AS sub_grupo
        FROM EspeciesBotanicas eb
        ORDER BY eb.NombreComun
        FOR JSON PATH
    ) AS datos;

    -- Tractores y camiones: prefijo T% cubre ambos tipos en Pisco.
    SELECT 'tractores' AS catalogo, (
        SELECT
            m.Id            AS tractor_id_erp,
            m.Identificacion AS codigo_tractor,
            m.Descripcion   AS descripcion,
            m.Marca         AS marca,
            m.Modelo        AS modelo,
            m.Matricula     AS matricula,
            m.Codigo        AS codigo_interno
        FROM Maquinaria m
        INNER JOIN Maquinaria_DatosComplementarios md ON m.Id = md.Id_Maquinaria
        INNER JOIN DatoComplementarioValor dc ON md.Id_DatosComplementarios = dc.Id
        INNER JOIN Zonas z ON dc.valor = z.Nombre
        WHERE z.Nombre = @zona_maq
          AND m.Identificacion LIKE 'T%'
        ORDER BY m.Identificacion
        FOR JSON PATH
    ) AS datos;

    -- Implementos: mismo patrón que tractores, prefijo I%.
    SELECT 'implementos' AS catalogo, (
        SELECT
            m.Id            AS implemento_id_erp,
            m.Identificacion AS codigo_implemento,
            m.Descripcion   AS descripcion,
            m.Marca         AS marca,
            m.Modelo        AS modelo,
            m.Matricula     AS matricula,
            m.Codigo        AS codigo_interno
        FROM Maquinaria m
        INNER JOIN Maquinaria_DatosComplementarios md ON m.Id = md.Id_Maquinaria
        INNER JOIN DatoComplementarioValor dc ON md.Id_DatosComplementarios = dc.Id
        INNER JOIN Zonas z ON dc.valor = z.Nombre
        WHERE z.Nombre = @zona_maq
          AND m.Identificacion LIKE 'I%'
        ORDER BY m.Identificacion
        FOR JSON PATH
    ) AS datos;

    -- Vehiculos: mismo patrón que tractores, prefijo V%.
    SELECT 'vehiculos' AS catalogo, (
        SELECT
            m.Id            AS implemento_id_erp,
            m.Identificacion AS codigo_implemento,
            m.Descripcion   AS descripcion,
            m.Marca         AS marca,
            m.Modelo        AS modelo,
            m.Matricula     AS matricula,
            m.Codigo        AS codigo_interno
        FROM Maquinaria m
        INNER JOIN Maquinaria_DatosComplementarios md ON m.Id = md.Id_Maquinaria
        INNER JOIN DatoComplementarioValor dc ON md.Id_DatosComplementarios = dc.Id
        INNER JOIN Zonas z ON dc.valor = z.Nombre
        WHERE z.Nombre = @zona_maq
          AND m.Identificacion LIKE '%V%'
        ORDER BY m.Identificacion
        FOR JSON PATH
    ) AS datos;

    -- Trabajadores
    SELECT 'trabajadores' AS catalogo, (
        SELECT
            t.Id AS trabajador_id_erp,
            u.Id AS usuario_id_erp,
            u.Codigo AS CodigoUsuario,
            SUBSTRING(t.Codigo, 6, LEN(t.Codigo)) AS cod_trabajador,
            CONCAT(s.PrimerApellido, ' ', s.SegundoApellido, ' ', s.Nombre) AS nombre_completo
        FROM sujetos s
        INNER JOIN trabajadores t ON s.Id = t.Id_Sujeto
        INNER JOIN Usuarios u ON u.id_sujeto = s.Id
        INNER JOIN DireccionesSujeto ds ON ds.Id_Sujeto = s.Id
        INNER JOIN direcciones d ON ds.Id_Direccion = d.Id
        INNER JOIN Zonas z ON d.Id_Zona = z.Id
        WHERE z.Nombre = @zona_maq
        ORDER BY s.PrimerApellido, s.SegundoApellido, s.Nombre
        FOR JSON PATH
    ) AS datos;

    -- Lotes
    SELECT 'lotes' AS catalogo, (
        SELECT
            f.Id AS finca_id_erp,
            f.Codigo AS lote_codigo,
            CAST(f.SuperficieCultivable / 10000.0 AS DECIMAL(10,2)) AS hectareas_lote,
            c.Id AS lote_id_erp,
            TRIM(c.Descripcion) AS sublote,
            CAST(c.SuperficieCultivada / 10000.0 AS DECIMAL(10,2)) AS hectareas_sublote
        FROM Fincas f
        INNER JOIN Zonas z ON f.Id_zona = z.Id
        LEFT JOIN Cultivos c ON c.Id_finca = f.Id
        WHERE z.Codigo = @zona_per
          AND (f.Codigo LIKE 'U-%' OR f.Codigo LIKE '%P_A%' OR f.Id = 640)
        ORDER BY f.Codigo, TRIM(c.Descripcion)
        FOR JSON PATH
    ) AS datos;

    -- Procesos de tractor
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

    -- Cajas de cambio (marchas de trabajo)
    SELECT 'cajas_cambios' AS catalogo, (
        SELECT id AS caja_id, nombre
        FROM dbo.CLI547_AGM_MMA_CAJAS_CAMBIOS
        ORDER BY id
        FOR JSON PATH
    ) AS datos;

    -- Tipos de paro
    SELECT 'tipos_paro' AS catalogo, (
        SELECT id AS tipo_paro_id, codigo, nombre, requiere_galones, requiere_equipo
        FROM dbo.CLI547_AGM_MMA_TIPOS_PARO
        WHERE activo = 1
        ORDER BY id
        FOR JSON PATH
    ) AS datos;

    -- Checklist items
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

    -- Último horómetro por tractor
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
            LEFT JOIN dbo.Maquinaria m ON m.Id = rd.tractor_id_erp
            WHERE rd.tractor_id_erp IS NOT NULL
              AND h.tractor_final IS NOT NULL
              AND rd.estado IN ('completado','aprobado')
        ) t
        WHERE t.rn = 1
        ORDER BY t.tractor_id_erp, t.implemento_id_erp
        FOR JSON PATH
    ) AS datos;

    -- =========================================================================
    -- 🔥 CATÁLOGO DE FALLAS MECÁNICAS ACTUALIZADO (incluye categoria y aplicacion)
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
    -- 🧭 CATÁLOGO DE NAVEGACIÓN (menú móvil) con permisos del usuario
    -- =========================================================================
    SELECT 'navegacion' AS catalogo, (
        SELECT DISTINCT
            n.Id,
            n.Nombre,
            n.Ruta,
            n.Icono,
            n.Orden,
            n.ParentId,
            n.EsGrupo,
            n.Estado,
            c.Nombre AS Componente,
            s.Nombre AS Sistema,
            n.Version
        FROM dbo.CLI547_AGM_Navegacion n
        JOIN dbo.CLI547_AGM_Componentes c ON c.Id = n.IdComponente
        JOIN dbo.CLI547_AGM_Sistemas s ON s.Id = n.IdSistema
        WHERE n.Id IN (
            SELECT pu.IdNavegacion
            FROM dbo.CLI547_AGM_PermisosUsuario pu
            WHERE pu.IdUsuario = @IdUsuario
              AND pu.Acceso = 'PERMITIDO'
            UNION
            SELECT pn.IdNavegacion
            FROM dbo.CLI547_AGM_PermisosNavegacion pn
            WHERE pn.IdRol IN (
                SELECT ur.Id_Roles
                FROM dbo.Usuarios_Roles ur
                WHERE ur.Id_Usuarios = @IdUsuario
            )
              AND pn.Acceso = 'PERMITIDO'
              AND NOT EXISTS (
                  SELECT 1
                  FROM dbo.CLI547_AGM_PermisosUsuario pu
                  WHERE pu.IdUsuario = @IdUsuario
                    AND pu.IdNavegacion = pn.IdNavegacion
              )
        )
        AND n.Estado = 'ACTIVO'
        AND s.Nombre = 'AgroMetrics Móvil'
        AND (@SinceVersion IS NULL OR n.Version > @SinceVersion)
        ORDER BY n.ParentId, n.Orden, n.Nombre
        FOR JSON PATH
    ) AS datos;

END;
GO
sp_helptext 'CLI547_AGMSP_SyncCatalogos'
    CREATE   PROCEDURE [dbo].[CLI547_AGMSP_SyncCatalogos]  
    @TableName     NVARCHAR(50),  
    @IdUsuario     INT,  
    @SinceVersion  BIGINT = NULL   -- NULL = full; si viene, aplica delta (Version > @SinceVersion)  
AS  
BEGIN  
    SET NOCOUNT ON;  
    SET XACT_ABORT ON;  
  
    BEGIN TRY  
        /* ==============================  
           Contexto de acceso del usuario  
           ============================== */  
        DECLARE @Id_Sede     INT,  
                @Id_Cultivo  INT,  
                @Id_Almacen  INT,  
                @Operacion   NVARCHAR(50);  
  
        SELECT TOP (1)  
            @Id_Sede    = uc.Id_Sede,  
            @Id_Cultivo = uc.Id_Cultivo,  
            @Id_Almacen = NULL,  
            @Operacion  = uc.Operacion  
        FROM dbo.CLI547_AGM_UsuarioConfiguracion AS uc  
        WHERE uc.Id_Usuario = @IdUsuario  
        ORDER BY uc.Id DESC;  
  
        -- 2) Unifica alcance en una sola #temp  
        IF OBJECT_ID('tempdb..#UserScope') IS NOT NULL  
            DROP TABLE #UserScope;  
  
        CREATE TABLE #UserScope  
        (  
            Kind          CHAR(1)       NOT NULL,  -- 'A' = Almacén, 'C' = Centro  
            Id            INT           NULL,      -- Id de almacén / centro  
            CodigoCentro  NVARCHAR(50)  NULL       -- solo para centros  
        );  
  
        -- A) Almacenes accesibles ('A')  
        INSERT INTO #UserScope (Kind, Id)  
        SELECT DISTINCT 'A', al.Id  
        FROM dbo.Almacenes al  
        JOIN dbo.EntornoAccesible_Almacenes eaal ON eaal.Id_Almacenes = al.Id  
        JOIN dbo.Usuarios us ON us.Id_EntornoAccesible = eaal.Id_EntornoAccesible  
        WHERE us.Id = @IdUsuario;  
  
        -- B) Centros del usuario ('C')  
        INSERT INTO #UserScope (Kind, Id, CodigoCentro)  
        SELECT DISTINCT 'C', ce.Id, ce.Codigo  
        FROM dbo.Usuarios u  
        JOIN dbo.EntornoInicial ei ON ei.Id_Usuario = u.Id  
        JOIN dbo.Centros ce ON ce.Id = ei.Id_Centro  
        WHERE u.Id = @IdUsuario;  
  
        -- Índices clave para acelerar EXISTS/IN  
        CREATE NONCLUSTERED INDEX IX_UserScope_A ON #UserScope(Kind, Id) WHERE Kind = 'A';  
        CREATE NONCLUSTERED INDEX IX_UserScope_C ON #UserScope(Kind, CodigoCentro) WHERE Kind = 'C';  
  
        /* ==============================  
           Ramas por tabla  
           ============================== */  
  
        IF @TableName = N'Centros'  -- (en tu lógica actual devuelve Almacenes)  
        BEGIN  
            SELECT al.Id, al.Codigo, al.Nombre AS Descripcion, al.Version  
            FROM dbo.Almacenes al  
            WHERE EXISTS (SELECT 1 FROM #UserScope s WHERE s.Kind = 'A' AND s.Id = al.Id)  
              AND (@SinceVersion IS NULL OR al.Version > @SinceVersion);  
            RETURN;  
        END  
  
        ELSE IF @TableName = N'Departamentos'  
        BEGIN  
            SELECT  
                id,  
                Codigo,  
                Nombre Descripcion,  
                Version  
            FROM ComunidadAutonoma  
            WHERE Nombre IN ('ICA', 'LIMA')  
              AND (@SinceVersion IS NULL OR Version > @SinceVersion);  
            RETURN;  
        END  
  
        ELSE IF @TableName = N'Provincias'  
        BEGIN  
            SELECT  
                P.Id,  
                P.Codigo,  
                P.Nombre Descripcion,  
                P.Id_Pais,  
                P.Id_ComunidadAutonoma IdDepartamento,  
                P.Version  
            FROM Provincias P  
            JOIN ComunidadAutonoma CA ON CA.Id = P.Id_ComunidadAutonoma  
            WHERE CA.Nombre IN ('ICA', 'LIMA')  
              AND (@SinceVersion IS NULL OR P.Version > @SinceVersion);  
            RETURN;  
        END  
  
        ELSE IF @TableName = N'Distritos'  
        BEGIN  
            SELECT  
                PB.Id,  
                PB.Codigo,  
                PB.Nombre Descripcion,  
                PB.Id_Provincia IdProvincia,  
                PB.Id_LocalidadINE,  
                PB.Version  
            FROM Poblaciones PB  
    JOIN Provincias P ON PB.Id_Provincia = P.Id  
            JOIN ComunidadAutonoma CA ON CA.Id = P.Id_ComunidadAutonoma  
            WHERE CA.Nombre IN ('ICA', 'LIMA')  
              AND (@SinceVersion IS NULL OR PB.Version > @SinceVersion);  
            RETURN;  
        END  
  
        ELSE IF @TableName = N'Paraderos'  
        BEGIN  
            SELECT  
                PR.Id,  
                PR.NombreParadero Descripcion,  
                PR.Id_Poblacion,  
                PR.Direccion,  
                PR.Latitud,  
                PR.Longitud,  
                PR.Activo,  
                PR.Version  
            FROM CLI547_AGM_Paradero PR  
            JOIN Poblaciones PB ON PR.Id_Poblacion = PB.Id  
            JOIN Provincias P ON PB.Id_Provincia = P.Id  
            JOIN ComunidadAutonoma CA ON CA.Id = P.Id_ComunidadAutonoma  
            WHERE CA.Nombre IN ('ICA', 'LIMA')  
              AND (@SinceVersion IS NULL OR PR.Version > @SinceVersion);  
            RETURN;  
        END  
  
        ELSE IF @TableName = N'TipoTransporte'  
        BEGIN  
            SELECT  
                Id,  
                Nombre Descripcion,  
                Activo,  
                UsoPrivado,  
                Version  
            FROM CLI547_AGM_TipoTransporte  
            WHERE (@SinceVersion IS NULL OR Version > @SinceVersion);  
            RETURN;  
        END  
  
        ELSE IF @TableName = N'Campanyas'  
        BEGIN  
            SELECT  
                Id,  
                Codigo,  
                Nombre,  
                FechaInicial,  
                FechaFinal,  
                Version  
            FROM dbo.Campanyas  
            WHERE Componente = '1'  
              AND (@SinceVersion IS NULL OR Version > @SinceVersion);  
            RETURN;  
        END  
  
        -- AGREGADO -GBARRIOS 07-08-2026  
        ELSE IF @TableName = N'Vehiculos'  
        BEGIN  
            SELECT  
                V.Id,  
                V.Placa,  
                TT.Nombre TipoTransporte,  
                V.NumeroPlazas,  
                O.Nombre Tipo_Operacion,  
                V.Version  
            FROM CLI547_AGM_Vehiculo V  
            JOIN CLI547_AGM_TipoTransporte TT ON TT.Id = V.Id_TipoTransporte  
            JOIN CLI547_AGM_Operacion O ON O.Id = V.Id_Operacion  
            WHERE (@SinceVersion IS NULL OR V.Version > @SinceVersion);  
            RETURN;  
        END  
  
        ELSE IF @TableName = N'Lineas'  
        BEGIN  
            SELECT  
                lp.Id,  
                lp.Id_Almacen,  
                lp.Codigo,  
                lp.DescripcionCorta AS Descripcion,  
                lp.Version  
            FROM dbo.LineaProduccion lp  
            WHERE lp.Nombre LIKE '%LINEA UVA%'  
              AND EXISTS (SELECT 1 FROM #UserScope s WHERE s.Kind = 'A' AND s.Id = lp.Id_Almacen)  
              AND (@SinceVersion IS NULL OR lp.Version > @SinceVersion);  
            RETURN;  
        END  
  
        ELSE IF @TableName = N'Cultivos'  
        BEGIN  
            SELECT  
                Id,  
                Codigo,  
                NombreComun AS Descripcion,  
                Version  
            FROM dbo.EspeciesBotanicas  
            WHERE (@Id_Cultivo IS NULL OR Id = @Id_Cultivo)  
              AND (@SinceVersion IS NULL OR Version > @SinceVersion);  
            RETURN;  
        END  
  
        ELSE IF @TableName = N'Labores'  
        BEGIN  
            SELECT  
                ap.Id,  
                ap.Codigo,  
                ap.Nombre AS Descripcion,  
                ap.Version  
            FROM dbo.ActividadesProduccion ap  
            LEFT JOIN ActividadProduccionArticuloProducir     apap ON ap.Id = apap.Id_ActividadProduccion  
            LEFT JOIN Articulos                                pr  ON pr.Id = apap.Id_Articulo  
            LEFT JOIN FamiliasArticulo                         fa  ON fa.Id = pr.Id_Familia  
            LEFT JOIN FamiliasArticulo                         fa1 ON fa1.Id = fa.Id_FamiliaSuperior  
            LEFT JOIN FamiliasArticuloAgro                     faa ON faa.Id = fa1.Id_FamiliaArticuloAgro  
            LEFT JOIN EspeciesBotanicas                        eb  ON eb.Id = faa.Id_EspecieBotanica  
            INNER JOIN ActividadesProduccion_DatosComplementarios apdc ON apdc.Id_ActividadesProduccion = ap.Id  
            INNER JOIN DatoComplementarioValor dcv ON dcv.Id = apdc.Id_DatosComplementarios  
            INNER JOIN DatosComplementarios dc ON dc.Id = dcv.Id_DatoComplementario AND dc.Codigo = 'OPE'  
            WHERE dcv.Valor = @Operacion  
              AND (ap.Productiva = 1 AND ap.EsEnvasado = 1)  
              AND eb.Id = @Id_Cultivo  
              AND (@SinceVersion IS NULL OR ap.Version > @SinceVersion)  
            GROUP BY ap.Id, ap.Codigo, ap.Nombre, ap.Version;  
            RETURN;  
        END  
  
        ELSE IF @TableName = N'Presentaciones'  
        BEGIN  
            SELECT  
                pr.Id,  
                ap.Id                AS IdActividad,  
                pr.Codigo,  
                pr.Nombre            AS Descripcion,  
                um.Nombre AS UnidadBase,  
                MAX(CASE WHEN ca.Codigo = 'CAP'  THEN ac.ValorNumerico     END) AS Capacidad,  
                MAX(CASE WHEN ca.Codigo = 'PES'  THEN ac.ValorAlfanumerico END) AS Peso,  
                MAX(CASE WHEN ca.Codigo = 'NCOS' THEN ac.ValorNumerico     END) AS NCosecha,  
                MAX(CASE WHEN ca.Codigo = 'NACO' THEN ac.ValorNumerico     END) AS NAcopio,  
                pr.Version  
            FROM dbo.ActividadesProduccion ap  
            JOIN ActividadProduccionArticuloProducir     apap ON ap.Id = apap.Id_ActividadProduccion  
            JOIN Articulos                                pr  ON pr.Id = apap.Id_Articulo  
            JOIN FamiliasArticulo                         fa  ON fa.Id = pr.Id_Familia  
            JOIN FamiliasArticulo                         fa1 ON fa1.Id = fa.Id_FamiliaSuperior  
            JOIN FamiliasArticuloAgro                     faa ON faa.Id = fa1.Id_FamiliaArticuloAgro  
            JOIN EspeciesBotanicas                        eb  ON eb.Id = faa.Id_EspecieBotanica  
            JOIN UnidadesMedida         um  ON um.Id = pr.Id_UnidadMedidaAlmacen  
            LEFT JOIN ArticulosCaracteristica             ac  ON ac.Id_Articulo = pr.Id  
            LEFT JOIN Caracteristicas                     ca  ON ca.Id = ac.Id_Caracteristica  
            GROUP BY pr.Id, ap.Id, pr.Codigo, pr.Nombre, um.Nombre, pr.Version;  
            RETURN;  
        END  
  
        ELSE IF @TableName = N'Articulos'  
        BEGIN  
            SELECT  
                a.Id,  
                a.Codigo,  
                a.Nombre,  
                a.Descripcion,  
                a.Id_Familia,  
                a.Version  
            FROM dbo.Articulos a  
            JOIN FamiliasArticulo fa WITH (NOLOCK) ON fa.Id = a.Id_Familia  
            WHERE (@SinceVersion IS NULL OR a.Version > @SinceVersion);  
            RETURN;  
        END  
  
        ELSE IF @TableName = N'Trabajadores'  
        BEGIN  
            SELECT DISTINCT  
                t.Id,  
                RIGHT(t.Codigo, 6) AS Codigo,  
                CONCAT(s.PrimerApellido, ' ', s.SegundoApellido, ' ', s.Nombre) AS Descripcion,  
                s.Identificador,  
                tu.Descripcion Turno,  
                tt.Nombre TipoTransporte,  
                t.Version  
            FROM dbo.Trabajadores t  
            JOIN dbo.Sujetos s            ON s.Id = t.Id_Sujeto  
            JOIN dbo.DireccionesSujeto ds ON ds.Id_Sujeto = s.Id  
            JOIN dbo.Direcciones dir      ON dir.Id = ds.Id_Direccion  
            JOIN dbo.Zonas zo             ON zo.Id = dir.Id_Zona  
            LEFT JOIN CLI547_AGM_CensoTrabajador ct ON ct.Id_Trabajador = t.Id AND ct.Estado = 1  
            LEFT JOIN CLI547_AGM_CensoTrabajadorTurno ctt ON ctt.Id_Trabajador = ct.Id_Trabajador  
            LEFT JOIN CLI547_AGM_Turno tu ON tu.Id = ctt.Id_Turno  
            LEFT JOIN CLI547_AGM_TipoTransporte tt ON tt.Id = ct.Id_TipoTransporte  
            WHERE EXISTS (  
                SELECT 1  
                FROM #UserScope us  
                WHERE us.Kind = 'C'  
                  AND us.CodigoCentro COLLATE Modern_Spanish_BIN = zo.Codigo  
            )  
            AND (@SinceVersion IS NULL OR t.Version > @SinceVersion);  
            RETURN;  
        END  
  
        ------ INICIO CATALOGO 18/05/2026 ---- JMATTA -------  
        ELSE IF @TableName = N'TrabajadoresAll'  
        BEGIN  
            SELECT DISTINCT  
                t.Id,  
                RIGHT(t.Codigo, 6) AS Codigo,  
                CONCAT(s.PrimerApellido, ' ', s.SegundoApellido, ' ', s.Nombre) AS Descripcion,  
                s.Identificador,  
                t.Version  
            FROM dbo.Trabajadores t  
            JOIN dbo.Sujetos s ON s.Id = t.Id_Sujeto  
            JOIN dbo.DireccionesSujeto ds ON ds.Id_Sujeto = s.Id  
            JOIN dbo.Direcciones dir ON dir.Id = ds.Id_Direccion  
            WHERE (@SinceVersion IS NULL OR t.Version > @SinceVersion);  
            RETURN;  
        END  
  
        ELSE IF @TableName = N'Fundos'  
        BEGIN  
            SELECT  
                s.Id,  
                s.PrimerApellido AS Descripcion,  
                s.Identificador,  
                Version  
            FROM Sujetos s  
            WHERE s.nombre = 'FUNDO';  
            RETURN;  
        END  
  
        ELSE IF @TableName = N'LaboresAll'  
        BEGIN  
            WITH ActividadesModificadas AS  
            (  
                SELECT DISTINCT apdc.Id_ActividadesProduccion  
                FROM ERPHispatec.dbo.ActividadesProduccion_DatosComplementarios apdc  
                JOIN ERPHispatec.dbo.DatoComplementarioValor dcv  
                    ON dcv.Id = apdc.Id_DatosComplementarios  
                WHERE @SinceVersion IS NULL OR dcv.Version > @SinceVersion  
            )  
            SELECT  
                apdc.Id_ActividadesProduccion AS Id,  
                --CodLabor         = MAX(CASE WHEN dc.Codigo='CLB' THEN dcv.Valor END),  
                Descripcion            = MAX(CASE WHEN dc.Codigo = 'LT' THEN dcv.Valor END),  
                --Area_Depa        = MAX(CASE WHEN dc.Codigo='DP'  THEN dcv.Valor END),  
                --GrupoLabor       = MAX(CASE WHEN dc.Codigo='GLB' THEN dcv.Valor END),  
                --LaborPptoGeneral = MAX(CASE WHEN dc.Codigo='LPG' THEN dcv.Valor END)  
                Version = MAX(dcv.Version)  
            FROM ActividadesModificadas am  
            JOIN ERPHispatec.dbo.ActividadesProduccion_DatosComplementarios apdc  
                ON apdc.Id_ActividadesProduccion = am.Id_ActividadesProduccion  
            JOIN ERPHispatec.dbo.DatoComplementarioValor dcv  
                ON dcv.Id = apdc.Id_DatosComplementarios  
            JOIN ERPHispatec.dbo.DatosComplementarios dc  
                ON dc.Id = dcv.Id_DatoComplementario  
            WHERE dc.Codigo IN ('CLB', 'LT', 'DP', 'GLB', 'LPG')  
            GROUP BY apdc.Id_ActividadesProduccion  
            HAVING MAX(CASE WHEN dc.Codigo = 'LT' THEN dcv.Valor END) IS NOT NULL;  
            RETURN;  
        END  
        ------ FIN CATALOGO 18/05/2026 ---- JMATTA -------  
  
        ------ NUEVO CATALOGO 18/05/2026 ---- GBARRIOS -------  
        ELSE IF @TableName = N'Conductores'  
        BEGIN  
            SELECT DISTINCT  
                c.Id,  
                c.Codigo,  
                CONCAT(s.PrimerApellido, ' ', s.SegundoApellido, ' ', s.Nombre) AS Descripcion,  
                s.Identificador,  
                c.Version  
            FROM dbo.Conductor c  
            JOIN dbo.Sujetos s ON s.Id = c.Id_Sujeto  
            JOIN dbo.DireccionesSujeto ds ON ds.Id_Sujeto = s.Id  
            JOIN dbo.Direcciones dir ON dir.Id = ds.Id_Direccion  
            JOIN dbo.Zonas zo ON zo.Id = dir.Id_Zona  
            WHERE EXISTS (  
                SELECT 1  
                FROM #UserScope us  
                WHERE us.Kind = 'C'  
                  AND us.CodigoCentro COLLATE Modern_Spanish_BIN = zo.Codigo  
        )  
            AND (@SinceVersion IS NULL OR c.Version > @SinceVersion);  
            RETURN;  
        END  
  
        ELSE IF @TableName = N'Confeccion'  
        BEGIN  
            SELECT  
                co.Id,  
                co.Codigo,  
                co.Nombre,  
                ar.Id AS Id_Articulo,  
                ISNULL(MAX(CASE WHEN dc.Codigo = 'NAC' THEN dcv.Valor END), 1) AS NroETQ,  
                co.Version  
            FROM dbo.Confeccion co  
            LEFT JOIN Articulos ar ON ar.Id = co.Id_Envase  
            LEFT JOIN Articulos_DatosComplementarios adc ON adc.Id_Articulos = ar.Id  
            LEFT JOIN DatoComplementarioValor dcv ON dcv.Id = adc.Id_DatosComplementarios  
            LEFT JOIN DatosComplementarios dc ON dc.Id = dcv.Id_DatoComplementario AND dc.Codigo = 'NAC'  
            WHERE (@SinceVersion IS NULL OR co.Version > @SinceVersion)  
            GROUP BY co.Id, co.Codigo, co.Nombre, ar.Id, co.Version;  
            RETURN;  
        END  
  
        ELSE IF @TableName = N'Lotes'  
        BEGIN  
            SELECT  
                fi.Id AS IdFinca,  
                fi.Codigo,  
                fi.Nombre,  
                fi.Version  
            FROM Cultivos cu  
            INNER JOIN Fincas fi ON fi.Id = cu.Id_Finca  
            INNER JOIN Articulos ar ON ar.Id = cu.Id_Articulo  
            INNER JOIN ArticulosAgro aa ON aa.Id = ar.Id_ArticuloAgro  
            INNER JOIN ArticulosAgro_EspecieBotanicaVariedad aaebv ON aaebv.Id_ArticuloAgro = aa.Id  
            INNER JOIN EspecieBotanicaVariedad ebv ON ebv.Id = aaebv.Id_EspecieBotanicaVariedad  
            INNER JOIN EspeciesBotanicas eb ON eb.Id = ebv.Id_EspecieBotanica  
            WHERE eb.Id = @Id_Cultivo  
              AND fi.Id_Zona = @Id_Sede  
              AND (@SinceVersion IS NULL OR fi.Version > @SinceVersion)  
            GROUP BY fi.Id, fi.Codigo, fi.Nombre, fi.Version;  
            RETURN;  
        END  
  
        ELSE IF @TableName = N'SubLotes'  
        BEGIN  
            SELECT  
                cuLP.Id,  
                fi.Id AS IdFinca,  
                ebv.Denominacion AS Variedad,  
                cuLP.Descripcion AS SubLote,  
                cuLP.Version  
            FROM ERPHispatec.dbo.Cultivos AS cuLP  
            INNER JOIN ERPHispatec.dbo.Fincas fi ON fi.Id = cuLP.Id_Finca  
            INNER JOIN ERPHispatec.dbo.Fincas_DatosComplementarios fdc ON fi.Id = fdc.Id_Fincas  
            INNER JOIN ERPHispatec.dbo.DatoComplementarioValor dcvc ON dcvc.Id = fdc.Id_DatosComplementarios  
            INNER JOIN ERPHispatec.dbo.DatosComplementarios dcc ON dcc.Id = dcvc.Id_DatoComplementario AND dcc.Codigo = 'VAR'  
            INNER JOIN ERPHispatec.dbo.EspecieBotanicaVariedad ebv ON ebv.Id = dcvc.Valor  
            INNER JOIN ERPHispatec.dbo.EspeciesBotanicas eb ON eb.Id = ebv.Id_EspecieBotanica  
            INNER JOIN ERPHispatec.dbo.Zonas z ON fi.Id_Zona = z.Id  
            INNER JOIN ERPHispatec.dbo.Sujetos su ON su.Id = fi.Id_Representante  
            WHERE TRY_CAST(dcvc.Valor AS FLOAT) IS NOT NULL  
              AND eb.Id = @Id_Cultivo  
              AND fi.Id_Zona = @Id_Sede  
              AND (@SinceVersion IS NULL OR cuLP.Version > @SinceVersion)  
            GROUP BY cuLP.Id, fi.Id, ebv.Denominacion, cuLP.Descripcion, cuLP.Version;  
            RETURN;  
        END  
  
        ELSE IF @TableName = N'Menu'  
        BEGIN  
            SELECT DISTINCT  
                n.Id,  
                n.Nombre,  
                n.Ruta,  
                n.Icono,  
                n.Orden,  
                n.ParentId,  
                n.EsGrupo,  
                n.Estado,  
                c.Nombre AS Componente,  
                s.Nombre AS Sistema,  
                n.Version  
            FROM dbo.CLI547_AGM_Navegacion n  
            JOIN dbo.CLI547_AGM_Componentes c ON c.Id = n.IdComponente  
            JOIN dbo.CLI547_AGM_Sistemas s ON s.Id = n.IdSistema  
            WHERE n.Id IN (  
                SELECT pu.IdNavegacion  
  FROM dbo.CLI547_AGM_PermisosUsuario pu  
                WHERE pu.IdUsuario = @IdUsuario  
                  AND pu.Acceso = 'PERMITIDO'  
                UNION  
                SELECT pn.IdNavegacion  
                FROM dbo.CLI547_AGM_PermisosNavegacion pn  
                WHERE pn.IdRol IN (  
                    SELECT ur.Id_Roles  
                    FROM dbo.Usuarios_Roles ur  
                    WHERE ur.Id_Usuarios = @IdUsuario  
                )  
                AND pn.Acceso = 'PERMITIDO'  
                AND NOT EXISTS (  
                    SELECT 1  
                    FROM dbo.CLI547_AGM_PermisosUsuario pu  
                    WHERE pu.IdUsuario = @IdUsuario  
                      AND pu.IdNavegacion = pn.IdNavegacion  
                )  
            )  
            AND n.Estado = 'ACTIVO'  
            AND s.Nombre = 'AgroMetrics Móvil'  
            AND (@SinceVersion IS NULL OR n.Version > @SinceVersion)  
            ORDER BY n.ParentId, n.Orden, n.Nombre;  
            RETURN;  
        END  
  
        ELSE IF @TableName = N'FitPartePlanta'  
        BEGIN  
            SELECT  
                t.Id,  
                t.Codigo,  
                t.Nombre,  
                t.Activo,  
                CAST(t.[Version] AS bigint) AS Version  
            FROM dbo.CLI547_AGM_FitPartePlanta t  
            WHERE (@SinceVersion IS NULL OR CAST(t.[Version] AS bigint) > @SinceVersion);  
            RETURN;  
        END  
  
        ELSE IF @TableName = N'FitMetrica'  
        BEGIN  
            SELECT  
                t.Id,  
                t.Codigo,  
                t.Nombre,  
                t.Activo,  
                CAST(t.[Version] AS bigint) AS Version  
            FROM dbo.CLI547_AGM_FitMetrica t  
            WHERE (@SinceVersion IS NULL OR CAST(t.[Version] AS bigint) > @SinceVersion);  
            RETURN;  
        END  
  
        ELSE IF @TableName = N'FitEstadio'  
        BEGIN  
            SELECT  
                t.Id,  
                t.Codigo,  
                t.Nombre,  
                t.Activo,  
                CAST(t.[Version] AS bigint) AS Version  
            FROM dbo.CLI547_AGM_FitEstadio t  
            WHERE (@SinceVersion IS NULL OR CAST(t.[Version] AS bigint) > @SinceVersion);  
            RETURN;  
        END  
  
        ELSE IF @TableName = N'FitAgenteConcepto'  
        BEGIN  
            SELECT  
                ac.Id,  
                ac.Id_Cultivo,  
                ac.Id_AgenteNocivo,  
                ac.Id_PartePlanta,  
                ac.Id_Metrica,  
                ac.Id_Estadio,  
                ac.Id_Unidad,  
                ac.CodigoConcepto,  
                ac.Etiqueta,  
                ac.Activo,  
                pp.Nombre  AS NombrePartePlanta,  
                m.Nombre   AS NombreMetrica,  
                e.Nombre   AS NombreEstadio,  
                ISNULL(an.Nombre, 'Otros') AS PlagaEnfermedad,  
                an.NombreComun AS NombreComunPlaga,  
                an.NombreCientifico AS NombreCientificoPlaga,  
                an.Tipo    AS TipoPlaga,  
                -- 🔥 Ahora incluimos los umbrales  
                u.n_bajo   AS Umbral_bajo,  
                u.n_medio  AS Umbral_medio,  
                u.n_alto   AS Umbral_alto,  
                u.FactorAlerta,  
                u.ReevalDias,  
                u.RequiereDobleCheck,  
                CAST(ac.[Version] AS bigint) AS Version  
            FROM dbo.CLI547_AGM_FitAgenteConcepto ac  
            LEFT JOIN dbo.CLI547_AGM_FitPartePlanta pp ON pp.Id = ac.Id_PartePlanta  
            LEFT JOIN dbo.CLI547_AGM_FitMetrica     m  ON m.Id  = ac.Id_Metrica  
            LEFT JOIN dbo.CLI547_AGM_FitEstadio     e  ON e.Id  = ac.Id_Estadio  
            LEFT JOIN dbo.AGM_AgenteNocivo          an ON an.Id_AgenteNocivo = ac.Id_AgenteNocivo AND an.Activo = 1  
            LEFT JOIN (  
                SELECT DISTINCT  
                    Id_AgenteConcepto,  
                    n_bajo, n_medio, n_alto, FactorAlerta, ReevalDias, RequiereDobleCheck  
FROM dbo.CLI547_AGM_FitUmbral WITH (NOLOCK)  
                WHERE Activo = 1 AND GETDATE() BETWEEN VigenteDesde AND ISNULL(VigenteHasta, '9999-12-31')  
            ) u ON u.Id_AgenteConcepto = ac.Id  
            WHERE ac.Activo = 1  
              AND (@SinceVersion IS NULL OR CAST(ac.[Version] AS bigint) > @SinceVersion)  
            ORDER BY an.Tipo, an.NombreComun, pp.Nombre, m.Nombre, e.Nombre;  
            RETURN;  
        END  
  
        ELSE IF @TableName = N'FitUmbral'  
        BEGIN  
            SELECT  
                u.Id,  
                u.Id_AgenteConcepto,  
                u.Id_Sede,  
                u.Id_Variedad,  
                u.Id_FamiliaArticulo,  
                u.VigenteDesde,  
                u.VigenteHasta,  
                u.n_bajo,  
                u.n_medio,  
                u.n_alto,  
                u.FactorAlerta,  
                u.ReevalDias,  
                u.RequiereDobleCheck,  
                u.Activo,  
                u.FechaModificacion,  
                u.UsuarioMod,  
                CAST(u.[Version] AS bigint) AS Version  
            FROM dbo.CLI547_AGM_FitUmbral u  
            WHERE (u.Id_Sede IS NULL OR u.Id_Sede = @Id_Sede)  
              AND u.Activo = 1  
              AND (@SinceVersion IS NULL OR CAST(u.[Version] AS bigint) > @SinceVersion);  
            RETURN;  
        END  
  
        ELSE IF @TableName = N'FitPlanificacion'  
        BEGIN  
            SELECT  
                p.Id,  
                p.Id_Campanya,  
                p.Id_Sede,  
                p.Id_Fundo,  
                p.Id_Cultivo,  
                p.Id_Variedad,  
                p.Id_Lote,  
                p.Id_Sublote,  
                p.Nombre_Lote,  
                p.Prioridad,  
                p.Estado,  
                p.FechaProgramada,  
                p.FechaCreacion,  
                p.CoordenadasPoligono,  
                p.UsuarioAsignado,  
                p.HectareasLote,  
                p.PlantasAsignadas,  -- 🔥 NUEVO: cupo de este técnico en planificación parcial  
                -- 🔥 CORREGIDO: Si tiene PlantasAsignadas, usarlo como TotalPlantas; si no, usar hectáreas × 10  
                CASE  
                    WHEN p.PlantasAsignadas IS NOT NULL THEN p.PlantasAsignadas  
                    ELSE CONVERT(INT, ROUND(  
                        ISNULL(CAST(cuLP.SuperficieCultivada / 10000.0 AS DECIMAL(10,2)), p.HectareasLote)  
                        * 10.0, 0  
                    ))  
                END AS TotalPlantas,  
                eb.NombreComun AS NombreCultivo,  
                ev.Denominacion AS NombreVariedad,  
                z.Nombre AS NombreSede,  
                cuLP.Descripcion AS NombreSublote,  
                gps.Geometria.STAsText() AS GeometriaWKT,  
                gps.Geometria.STCentroid().STY AS LatitudCentro,  
                gps.Geometria.STCentroid().STX AS LongitudCentro,  
                CASE  
                    WHEN eb.NombreComun = 'UVA'       THEN '#8E44AD'  
                    WHEN eb.NombreComun = 'PALTO'     THEN '#27AE60'  
                    WHEN eb.NombreComun = 'ESPARRAGO' THEN '#E67E22'  
                    WHEN eb.NombreComun = 'ARANDANO'  THEN '#2980B9'  
                    ELSE '#95A5A6'  
                END AS ColorCultivo,  
                CAST(p.[Version] AS BIGINT) AS Version  
            FROM dbo.CLI547_AGM_FitPlanificacion p WITH (NOLOCK)  
            LEFT JOIN ERPHispatec.dbo.Cultivos cuLP WITH (NOLOCK) ON cuLP.Id = p.Id_Sublote  
            LEFT JOIN dbo.Cultivos_Coordenadas cc WITH (NOLOCK) ON cc.Id_Cultivos = p.Id_Sublote  
            LEFT JOIN dbo.CoordenadaGPS gps WITH (NOLOCK) ON gps.Id = cc.Id_Coordenadas AND gps.Geometria IS NOT NULL  
            LEFT JOIN dbo.EspeciesBotanicas eb WITH (NOLOCK) ON eb.Id = p.Id_Cultivo  
            LEFT JOIN dbo.EspecieBotanicaVariedad ev WITH (NOLOCK) ON ev.Id = p.Id_Variedad  
            LEFT JOIN dbo.Zonas z WITH (NOLOCK) ON z.Id = p.Id_Sede  
            CROSS JOIN dbo.Usuarios u  
            WHERE p.Estado <> 'CANCELADO'  
              AND (@SinceVersion IS NULL OR CAST(p.[Version] AS BIGINT) > @SinceVersion)  
              AND u.Id = @IdUsuario  
              AND (p.UsuarioAsignado COLLATE DATABASE_DEFAULT = u.Codigo COLLATE DATABASE_DEFAULT  
                   OR p.UsuarioAsignado IS NULL);  
            RETURN;  
        END  
        ELSE IF @TableName = N'FitSubloteCatalogo'  
        BEGIN  
            SELECT  
                cuLP.Id                                                         AS Id,  
                (SELECT TOP 1 ca.Id FROM dbo.Campanyas ca  
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
                z.Nombre                                                        AS NombreSede,   -- 🔥 NUEVO: nombre real de la sede  
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
            INNER JOIN dbo.Fincas fi WITH (NOLOCK) ON fi.Id = cuLP.Id_Finca  
            INNER JOIN dbo.Fincas_DatosComplementarios fdc WITH (NOLOCK) ON fi.Id = fdc.Id_Fincas  
            INNER JOIN dbo.DatoComplementarioValor dcvc WITH (NOLOCK) ON dcvc.Id = fdc.Id_DatosComplementarios  
            INNER JOIN dbo.DatosComplementarios dcc WITH (NOLOCK)  
                ON dcc.Id = dcvc.Id_DatoComplementario AND dcc.Codigo = 'VAR'  
            INNER JOIN dbo.EspecieBotanicaVariedad ebv WITH (NOLOCK) ON ebv.Id = dcvc.Valor  
            INNER JOIN dbo.EspeciesBotanicas eb WITH (NOLOCK) ON eb.Id = ebv.Id_EspecieBotanica  
            LEFT JOIN ERPHispatec.dbo.Zonas z ON z.Id = @Id_Sede   -- 🔥 NUEVO JOIN  
            OUTER APPLY (  
                SELECT TOP 1 g.Geometria  
                FROM dbo.Cultivos_Coordenadas cc2 WITH (NOLOCK)  
                JOIN dbo.CoordenadaGPS g WITH (NOLOCK)  
                    ON g.Id = cc2.Id_Coordenadas AND g.Geometria IS NOT NULL  
                WHERE cc2.Id_Cultivos = cuLP.Id  
            ) geo  
            WHERE TRY_CAST(dcvc.Valor AS FLOAT) IS NOT NULL  
              AND fi.Id_Zona = @Id_Sede  
              AND eb.Id = @Id_Cultivo  
              AND (@SinceVersion IS NULL OR cuLP.Version > @SinceVersion)  
            ORDER BY fi.Nombre, cuLP.Descripcion;  
            RETURN;  
        END  
  
        ELSE IF @TableName = N'FitAgenteNocivo'  
        BEGIN  
            SELECT  
                Id_AgenteNocivo,  
                Nombre,  
                NombreComun,  
                NombreCientifico,  
                Tipo,  
                Activo  
            FROM dbo.AGM_AgenteNocivo WITH (NOLOCK)  
            WHERE Activo = 1;  
            RETURN;  
        END  
  
        --  NUEVO CATÁLOGO: GruposTrabajadores (SOLO AGREGADO ESTO, NADA MÁS, 13/05/2026, 09:07 AM)  
        ELSE IF @TableName = N'GruposTrabajadores'  
        BEGIN  
            SELECT  
                gt.Id AS Id_Grupo,  
                gt.Codigo,  
                gt.Descripcion AS Nombre_Grupo,  
                CAST(gt.[Version] AS BIGINT) AS Version  
            FROM dbo.GruposTrabajadores gt  
            WHERE (@SinceVersion IS NULL OR CAST(gt.[Version] AS BIGINT) > @SinceVersion);  
            RETURN;  
        END  
  
        -- ⚠️ SI NO COINCIDE CON NINGÚN CATÁLOGO  
        ELSE  
        BEGIN  
            RAISERROR(N'Nombre de la tabla no reconocido: %s', 10, 1, @TableName);  
            RETURN;  
        END  
  
    END TRY  
    BEGIN CATCH  
        DECLARE @msg NVARCHAR(4000) =  
            CONCAT('SYNC WARNING [', ISNULL(@TableName,'(NULL)'), ']: ',  
                   ERROR_MESSAGE(), ' (', ERROR_NUMBER(), '/', ERROR_SEVERITY(), ')');  
        RAISERROR(@msg, 10, 1);  
        RETURN;  
    END CATCH  
END;  
GO



sp_helptext 'CLI547_AGMSP_MMA_SINCRONIZAR_OFFLINE'
  
  
      CREATE      PROCEDURE dbo.CLI547_AGMSP_MMA_SINCRONIZAR_OFFLINE      
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
            @v_marchas NVARCHAR(MAX);      
      
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
                DELETE FROM CLI547_AGM_MMA_REGISTROS_LOTES WHERE registro_id = @p_registro_id;      
                INSERT INTO CLI547_AGM_MMA_REGISTROS_LOTES (id, registro_id, lote_id_erp, finca_id_erp, lote_codigo_snapshot, sublote_snapshot, area_trabajada_ha, observacion)      
                SELECT NEWID(), @p_registro_id,      
                       TRY_CAST(JSON_VALUE(value, '$.lote_id_erp') AS INT),      
                       TRY_CAST(JSON_VALUE(value, '$.finca_id_erp') AS INT),      
                       JSON_VALUE(value, '$.lote_codigo_snapshot'), JSON_VALUE(value, '$.sublote_snapshot'),      
                       TRY_CAST(JSON_VALUE(value, '$.area_trabajada_ha') AS DECIMAL(8,4)), JSON_VALUE(value, '$.observacion')      
                FROM OPENJSON(@v_lotes);      
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


------------------


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
    
        -- ── Ruta GPS de maquinaria ──────────────────────────────────────────────
        -- Aplica a ambos tipos (tractor y vehículo).  Si el dispositivo no tiene
        -- GPS o el operador denegó el permiso, @v_ruta_gps llega NULL y este bloque
        -- se omite sin error.  Al sincronizar se reemplaza la ruta completa del
        -- registro (DELETE + INSERT) para garantizar idempotencia.
        IF @v_ruta_gps IS NOT NULL AND ISJSON(@v_ruta_gps) = 1
        BEGIN
            DELETE FROM dbo.CLI547_AGM_Punto_gps_maquinaria
            WHERE registro_id = @p_registro_id;

            INSERT INTO dbo.CLI547_AGM_Punto_gps_maquinaria
                   (id, registro_id, latitud, longitud, precision_m, altitud_m, velocidad_ms, secuencia, captured_at)
            SELECT
                COALESCE(TRY_CONVERT(UNIQUEIDENTIFIER, JSON_VALUE(value, '$.id')), NEWID()),
                @p_registro_id,
                TRY_CAST(JSON_VALUE(value, '$.lat')          AS FLOAT),
                TRY_CAST(JSON_VALUE(value, '$.lng')          AS FLOAT),
                TRY_CAST(JSON_VALUE(value, '$.precision_m')  AS FLOAT),
                TRY_CAST(JSON_VALUE(value, '$.altitud_m')    AS FLOAT),
                TRY_CAST(JSON_VALUE(value, '$.velocidad_ms') AS INT),
                TRY_CAST(JSON_VALUE(value, '$.sec')          AS INT),
                TRY_CAST(JSON_VALUE(value, '$.ts')           AS DATETIME2(0))
            FROM OPENJSON(@v_ruta_gps)
            WHERE TRY_CAST(JSON_VALUE(value, '$.lat') AS FLOAT) IS NOT NULL
              AND TRY_CAST(JSON_VALUE(value, '$.lng') AS FLOAT) IS NOT NULL;
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
go

use ERPHispatec

sp_helptext 'SP_MMA_REPORTE_PORTERO_DETALLADO'
select * from CLI547_AGM_Punto_gps_maquinaria

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



    SP_COLUMNS 'CLI547_AGM_Punto_gps_maquinaria'
    ----------------------

    CREATE TABLE dbo.CLI547_AGM_Punto_gps_maquinaria (
    id            NVARCHAR(50)   NOT NULL,
    registro_id   NVARCHAR(50)   NOT NULL,
    latitud       FLOAT          NOT NULL,
    longitud      FLOAT          NOT NULL,
    [precision]   FLOAT              NULL,   -- precisión GPS en metros (corchetes obligatorios)
    altitud       FLOAT              NULL,   -- metros sobre el nivel del mar
    velocidad     INT                NULL,   -- m/s entero (redondeado en APK)
    secuencia     INT            NOT NULL DEFAULT 0,
    captured_at   BIGINT         NOT NULL,   -- epoch milisegundos UTC
    created_at    DATETIME2      NOT NULL DEFAULT SYSUTCDATETIME(),
    CONSTRAINT PK_GPS_Punto PRIMARY KEY CLUSTERED (id)
);
GO

-- Índice compuesto: trayectoria por registro en orden cronológico
CREATE NONCLUSTERED INDEX IX_GPS_RegistroSecuencia
    ON dbo.CLI547_AGM_Punto_gps_maquinaria (registro_id, secuencia ASC);
GO

-- Índice para filtros de fecha/hora sobre captured_at
CREATE NONCLUSTERED INDEX IX_GPS_CapturedAt
    ON dbo.CLI547_AGM_Punto_gps_maquinaria (captured_at);
GO
    select * from CLI547_AGM_Punto_gps_maquinaria
CREATE OR ALTER PROCEDURE dbo.CLI547_AGMSP_MMA_REGISTRAR_PUNTOS_GPS
    -- ── INPUT ───────────────────────────────────────────────────────────────
    @p_registro_id       NVARCHAR(50),
    @p_puntos_json       NVARCHAR(MAX),
    -- ── OUTPUT ──────────────────────────────────────────────────────────────
    @p_success           BIT            OUTPUT,
    @p_mensaje           NVARCHAR(500)  OUTPUT,
    @p_total_insertados  INT            OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    SET @p_success          = 0;
    SET @p_mensaje          = '';
    SET @p_total_insertados = 0;

    -- ── Validaciones ─────────────────────────────────────────────────────────
    IF @p_registro_id IS NULL OR LEN(LTRIM(RTRIM(@p_registro_id))) = 0
    BEGIN
        SET @p_mensaje = 'Error: @p_registro_id es requerido.';
        RETURN;
    END

    -- JSON vacío → éxito sin insertar (APK todavía sin puntos GPS)
    IF @p_puntos_json IS NULL OR LEN(LTRIM(@p_puntos_json)) < 3
    BEGIN
        SET @p_success = 1;
        SET @p_mensaje = 'Sin puntos GPS para registrar.';
        RETURN;
    END

    IF ISJSON(@p_puntos_json) = 0
    BEGIN
        SET @p_mensaje = 'Error: @p_puntos_json no es JSON válido.';
        RETURN;
    END

    -- ── Tabla temporal de trabajo ─────────────────────────────────────────────
    -- [precision] con corchetes porque es palabra reservada en SQL Server.
    DECLARE @puntos TABLE (
        id            NVARCHAR(50)  NOT NULL,
        latitud       FLOAT         NOT NULL,
        longitud      FLOAT         NOT NULL,
        [precision]   FLOAT             NULL,
        altitud       FLOAT             NULL,
        velocidad     INT               NULL,
        secuencia     INT           NOT NULL,
        captured_at   BIGINT        NOT NULL
    );

    -- ── Parsear el JSON de puntos ─────────────────────────────────────────────
    -- Los valores numéricos llegan como NVARCHAR desde Flutter/JSON; se castean aquí.
    -- 'null' como string se convierte a NULL para las columnas opcionales.
    BEGIN TRY
        INSERT INTO @puntos
            (id, latitud, longitud, [precision], altitud, velocidad, secuencia, captured_at)
        SELECT
            LTRIM(RTRIM(j.id))                                          AS id,
            CAST(j.latitud      AS FLOAT)                               AS latitud,
            CAST(j.longitud     AS FLOAT)                               AS longitud,
            CASE WHEN j.[precision] IS NULL OR j.[precision] = 'null'
                 THEN NULL
                 ELSE CAST(j.[precision] AS FLOAT)  END                 AS [precision],
            CASE WHEN j.altitud    IS NULL OR j.altitud    = 'null'
                 THEN NULL
                 ELSE CAST(j.altitud    AS FLOAT)   END                 AS altitud,
            CASE WHEN j.velocidad  IS NULL OR j.velocidad  = 'null'
                 THEN NULL
                 ELSE CAST(j.velocidad  AS INT)     END                 AS velocidad,
            ISNULL(CAST(j.secuencia AS INT), 0)                         AS secuencia,
            CAST(j.captured_at AS BIGINT)                               AS captured_at
        FROM OPENJSON(@p_puntos_json)
        WITH (
            id            NVARCHAR(50)  '$.id',
            latitud       NVARCHAR(50)  '$.latitud',
            longitud      NVARCHAR(50)  '$.longitud',
            [precision]   NVARCHAR(50)  '$.precision',
            altitud       NVARCHAR(50)  '$.altitud',
            velocidad     NVARCHAR(10)  '$.velocidad',
            secuencia     NVARCHAR(10)  '$.secuencia',
            captured_at   NVARCHAR(20)  '$.captured_at'
        ) AS j
        WHERE LTRIM(RTRIM(ISNULL(j.id, ''))) <> ''
          AND j.latitud  IS NOT NULL
          AND j.longitud IS NOT NULL;
    END TRY
    BEGIN CATCH
        SET @p_mensaje = 'Error al parsear JSON: ' + ERROR_MESSAGE();
        RETURN;
    END CATCH

    IF NOT EXISTS (SELECT 1 FROM @puntos)
    BEGIN
        SET @p_success = 1;
        SET @p_mensaje = 'JSON válido pero sin filas procesables (ids vacíos o lat/lon nulos).';
        RETURN;
    END

    -- ── MERGE idempotente ─────────────────────────────────────────────────────
    -- WHEN NOT MATCHED: insertar punto nuevo.
    -- WHEN MATCHED: no hacer nada (el mismo punto enviado dos veces no se duplica).
    BEGIN TRY
        BEGIN TRANSACTION;

        MERGE dbo.CLI547_AGM_Punto_gps_maquinaria AS target
        USING (
            SELECT
                id,
                @p_registro_id  AS registro_id,
                latitud,
                longitud,
                [precision],
                altitud,
                velocidad,
                secuencia,
                captured_at
            FROM @puntos
        ) AS source
        ON target.id = source.id
        WHEN NOT MATCHED BY TARGET THEN
            INSERT (
                id, registro_id, latitud, longitud,
                [precision], altitud, velocidad,
                secuencia, captured_at
            )
            VALUES (
                source.id, source.registro_id, source.latitud, source.longitud,
                source.[precision], source.altitud, source.velocidad,
                source.secuencia, source.captured_at
            );

        SET @p_total_insertados = @@ROWCOUNT;
        COMMIT TRANSACTION;

        SET @p_success = 1;
        SET @p_mensaje = 'OK: ' + CAST(@p_total_insertados AS NVARCHAR(10))
                         + ' punto(s) GPS registrado(s) para ' + @p_registro_id + '.';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        SET @p_success = 0;
        SET @p_mensaje = 'Error en MERGE GPS: ' + ERROR_MESSAGE();
    END CATCH
END;
GO




-- =============================================================================
-- 3. SP CONSULTA / MAPA — GET PUNTOS GPS MAQUINARIA
-- Devuelve la trayectoria GPS filtrada por fecha, operador o tractor.
-- captured_at (BIGINT epoch ms UTC) se convierte a DATETIME2 hora local Perú (UTC-5).
-- Conversión: se divide en días + ms-del-día para evitar overflow de DATEADD.
-- =============================================================================

1	CLI547_AGMSP_PackingSesion_Abrir
2	CLI547_AGMSP_PackingCaja_RegistrarDirecto
3	CLI547_AGMSP_Sesion_Cerrar
#	SP
1	CLI547_AGMSP_Packing_LugaresPermitidos_uva
2	CLI547_AGMSP_PackingSesion_Abrir_uva
3	CLI547_AGMSP_Packing_MapaOperariosPorLugar
4	CLI547_AGMSP_ApplyErpPayload
5	CLI547_AGMSP_Pallet_SetActivo
6	CLI547_AGMSP_PackingSesionPallet_SetActivo
7	CLI547_AGMSP_Cajas_RegistrarLote
8	CLI547_AGMSP_Sesion_Cerrar_uva
9	CLI547_AGMSP_PackingSesionPallet_MarcarCompleto
10	CLI547_AGMSP_PackingCaja_RegistrarDirecto
11	CLI547_AGMSP_PackingCaja_DevolucionLote



SP_HELPTEXT 'CLI547_AGMSP_PackingCaja_DevolucionLote'
CLI547_AGM_SP_MMA_TPM_KPI_RESUMEN
CLI547_AGM_SP_MMA_TPM_METRICAS_RESUMEN
CLI547_AGM_SP_MMA_TPM_TABLA_DIARIA
CLI547_AGM_SP_MMA_TPM_TIEMPOS_PRODUCTIVOS
CLI547_AGM_SP_MMA_TPM_PARETO_FALLAS
CLI547_AGM_SP_MMA_TPM_RANKING_MAQUINAS
CLI547_AGM_SP_MMA_ANALISIS_6_PERDIDAS
CLI547_AGM_SP_MMA_DASHBOARD_RENDIMIENTO_OPERADOR

        select * from CLI547_AGM_Ruta_maquinaria
        sp_helptext 'CLI547_AGMSP_MMA_ERP_SYNC_PAYLOAD_COMPLETO'

        select * from CLI547_AGM_Punto_gps_maquinaria
CREATE   PROCEDURE [dbo].[CLI547_AGMSP_MMA_ERP_SYNC_PAYLOAD_COMPLETO]  
AS  
BEGIN  
    SET NOCOUNT ON;  
    DECLARE @zona_maq NVARCHAR(50) = 'PISCO';  
    DECLARE @zona_per NVARCHAR(20) = 'PCO';  
  
    -- Cultivos: el mapper del APK lee cultivo_id_erp y nombre_cultivo.  
    SELECT 'cultivos' AS catalogo, (  
        SELECT  
            eb.Id            AS cultivo_id_erp,  
            eb.NombreComun   AS nombre_cultivo,  
            eb.NombreEspecie AS nombre_especie,  
            eb.NombreGenero  AS nombre_genero,  
            eb.Grupo         AS grupo,  
            eb.SubGrupo      AS sub_grupo  
        FROM EspeciesBotanicas eb  
        ORDER BY eb.NombreComun  
        FOR JSON PATH  
    ) AS datos;  
  
    -- Tractores y camiones: prefijo T% cubre ambos tipos en Pisco.  
    SELECT 'tractores' AS catalogo, (  
        SELECT  
            m.Id            AS tractor_id_erp,  
            m.Identificacion AS codigo_tractor,  
            m.Descripcion   AS descripcion,  
            m.Marca         AS marca,  
            m.Modelo        AS modelo,  
            m.Matricula     AS matricula,  
            m.Codigo        AS codigo_interno  
        FROM Maquinaria m  
        INNER JOIN Maquinaria_DatosComplementarios md ON m.Id = md.Id_Maquinaria  
        INNER JOIN DatoComplementarioValor dc ON md.Id_DatosComplementarios = dc.Id  
        INNER JOIN Zonas z ON dc.valor = z.Nombre  
        WHERE z.Nombre = @zona_maq  
          AND m.Identificacion LIKE 'TR%'  
        ORDER BY m.Identificacion  
        FOR JSON PATH  
    ) AS datos;  
  
    -- Implementos: mismo patrón que tractores, prefijo I%.  
    SELECT 'implementos' AS catalogo, (  
        SELECT  
            m.Id            AS implemento_id_erp,  
            m.Identificacion AS codigo_implemento,  
            m.Descripcion   AS descripcion,  
            m.Marca         AS marca,  
            m.Modelo        AS modelo,  
            m.Matricula     AS matricula,  
            m.Codigo        AS codigo_interno  
        FROM Maquinaria m  
        INNER JOIN Maquinaria_DatosComplementarios md ON m.Id = md.Id_Maquinaria  
        INNER JOIN DatoComplementarioValor dc ON md.Id_DatosComplementarios = dc.Id  
        INNER JOIN Zonas z ON dc.valor = z.Nombre  
        WHERE z.Nombre = @zona_maq  
          AND m.Identificacion LIKE 'I%'  
        ORDER BY m.Identificacion  
        FOR JSON PATH  
    ) AS datos;  
  
    -- Vehiculos: mismo patrón que tractores, prefijo V%.  
    SELECT 'vehiculos' AS catalogo, (  
        SELECT  
            m.Id            AS implemento_id_erp,  
            m.Identificacion AS codigo_implemento,  
            m.Descripcion   AS descripcion,  
            m.Marca         AS marca,  
            m.Modelo        AS modelo,  
            m.Matricula     AS matricula,  
            m.Codigo        AS codigo_interno  
        FROM Maquinaria m  
        INNER JOIN Maquinaria_DatosComplementarios md ON m.Id = md.Id_Maquinaria  
        INNER JOIN DatoComplementarioValor dc ON md.Id_DatosComplementarios = dc.Id  
        INNER JOIN Zonas z ON dc.valor = z.Nombre  
        WHERE z.Nombre = @zona_maq  
          AND m.Identificacion LIKE '%V%'  
        ORDER BY m.Identificacion  
        FOR JSON PATH  
    ) AS datos;  
  
    -- Trabajadores  
    SELECT 'trabajadores' AS catalogo, (  
        SELECT  
            t.Id AS trabajador_id_erp,  
            u.Id AS usuario_id_erp,  
            u.Codigo AS CodigoUsuario,  
            SUBSTRING(t.Codigo, 6, LEN(t.Codigo)) AS cod_trabajador,  
            CONCAT(s.PrimerApellido, ' ', s.SegundoApellido, ' ', s.Nombre) AS nombre_completo  
        FROM sujetos s  
        INNER JOIN trabajadores t ON s.Id = t.Id_Sujeto  
        INNER JOIN Usuarios u ON u.id_sujeto = s.Id  
        INNER JOIN DireccionesSujeto ds ON ds.Id_Sujeto = s.Id  
        INNER JOIN direcciones d ON ds.Id_Direccion = d.Id  
        INNER JOIN Zonas z ON d.Id_Zona = z.Id  
        WHERE z.Nombre = @zona_maq  
        ORDER BY s.PrimerApellido, s.SegundoApellido, s.Nombre  
        FOR JSON PATH  
    ) AS datos;  
  
    -- Lotes  
    SELECT 'lotes' AS catalogo, (  
        SELECT  
            f.Id AS finca_id_erp,  
            f.Codigo AS lote_codigo,  
            CAST(f.SuperficieCultivable / 10000.0 AS DECIMAL(10,2)) AS hectareas_lote,  
            c.Id AS lote_id_erp,  
            TRIM(c.Descripcion) AS sublote,  
            CAST(c.SuperficieCultivada / 10000.0 AS DECIMAL(10,2)) AS hectareas_sublote  
        FROM Fincas f  
        INNER JOIN Zonas z ON f.Id_zona = z.Id  
        LEFT JOIN Cultivos c ON c.Id_finca = f.Id  
        WHERE z.Codigo = @zona_per  
          AND (f.Codigo LIKE 'U-%' OR f.Codigo LIKE '%P_A%' OR f.Id IN (440, 530, 640, 643))  
        ORDER BY f.Codigo, TRIM(c.Descripcion)  
        FOR JSON PATH  
    ) AS datos;  
  
    -- Procesos de tractor  
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
  
    -- Cajas de cambio (marchas de trabajo)  
    SELECT 'cajas_cambios' AS catalogo, (  
        SELECT id AS caja_id, nombre  
        FROM dbo.CLI547_AGM_MMA_CAJAS_CAMBIOS  
        ORDER BY id  
        FOR JSON PATH  
    ) AS datos;  
  
    -- Tipos de paro  
    SELECT 'tipos_paro' AS catalogo, (  
        SELECT id AS tipo_paro_id, codigo, nombre, requiere_galones, requiere_equipo  
        FROM dbo.CLI547_AGM_MMA_TIPOS_PARO  
        WHERE activo = 1  
        ORDER BY id  
        FOR JSON PATH  
    ) AS datos;  
  
    -- Checklist items  
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
  
    -- Último horómetro por tractor  
    SELECT 'ultimo_horometro_tractores' AS catalogo, (  
        SELECT  
            t.tractor_id_erp,  
            t.implemento_id_erp,  
            t.codigo_tractor,  
            T.codigo_implemento,  
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
            LEFT JOIN dbo.Maquinaria m ON m.Id = rd.tractor_id_erp  
            WHERE rd.tractor_id_erp IS NOT NULL  
              AND h.tractor_final IS NOT NULL  
              AND rd.estado IN ('completado','aprobado')  
        ) t  
        WHERE t.rn = 1  
        ORDER BY t.tractor_id_erp, t.implemento_id_erp  
        FOR JSON PATH  
    ) AS datos;  
  
    -- =========================================================================  
    -- 🔥 CATÁLOGO DE FALLAS MECÁNICAS ACTUALIZADO (incluye categoria y aplicacion)  
    -- =========================================================================  
    SELECT 'fallas_mecanicas' AS catalogo, (  
        SELECT  
            id AS falla_id,  
            codigo,  
            nombre,  
            categoria,        -- <-- NUEVO  
            aplicacion        -- <-- NUEVO  
        FROM dbo.CLI547_AGM_MMA_FALLAS_MECANICAS  
        WHERE activo = 1  
        ORDER BY nombre  
        FOR JSON PATH  
    ) AS datos;  
END;  
GO



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





SELECT 
    r.id AS registro_id,
    r.codigo_tractor_snapshot,
    h.tractor_final,
    h.implemento_final,
    r.fecha
FROM dbo.CLI547_AGM_MMA_REGISTROS_DIARIOS r
INNER JOIN dbo.CLI547_AGM_MMA_HOROMETROS h ON h.registro_id = r.id
where h.tractor_final = 789.0
--WHERE r.codigo_tractor_snapshot = 'TRC08'  -- Cambia por el código de tu tractor
ORDER BY r.fecha DESC, r.created_at DESC;

UPDATE dbo.CLI547_AGM_MMA_HOROMETROS
SET tractor_final = 789.0,
    updated_at = GETDATE()
WHERE registro_id = '1A3EF477-CC36-4ED0-8652-3DC29F960AC9';

SELECT * 
FROM dbo.CLI547_AGM_MMA_HOROMETROS
WHERE registro_id = '1A3EF477-CC36-4ED0-8652-3DC29F960AC9';



