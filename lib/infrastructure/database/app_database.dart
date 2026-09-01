import 'dart:developer' as developer;
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'tables/outbox_table.dart';
import 'tables/catalogos_tables.dart';
import 'tables/registros_tables.dart';
import 'tables/portero_tables.dart';
import 'daos/outbox_dao.dart';
import 'daos/catalogo_dao.dart';
import 'daos/registro_dao.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    // Outbox
    OutboxEntries,
    // Catálogos PostgreSQL
    ProcesosLocal,
    CajasCambiosLocal,
    TiposParoLocal,
    ChecklistCategoriasLocal,
    ChecklistItemsLocal,
    // Catálogos ERP
    CultivosLocal,
    TractoresLocal,
    ImplementosLocal,
    TrabajadoresLocal,
    LotesLocal,
    SectoresLocal,
    // Catálogos MMA v3
    SubprocesosLocal,
    MenusLocal,
    // Registros
    RegistrosDiariosLocal,
    HorometrosLocal,
    TiemposTurnoLocal,
    RegistrosSectoresLocal,
    CosechaBinesLocal,
    ParosEquiposLocal,
    ChecklistResultadosLocal,
    // Registros MMA v3
    RegistrosVehiculoLocal,
    CombustibleVehiculoLocal,
    // Portero MMA v3
    PorteroLecturasLocal,
    // Nuevos MMA v8
    SubLaboresLocal,
    MarchasLocal,
    IncumplimientosLocal,
  ],
  daos: [
    OutboxDao,
    CatalogoDao,
    RegistroDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(QueryExecutor executor) : super(executor);

  @override
  int get schemaVersion => 21;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            for (final table in allTables) {
              await m.drop(table);
            }
            await m.createAll();
            return;
          }
          if (from < 3) {
            // v2→v3: requiereGalones y requiereEquipo en TiposParoLocal
            await m.addColumn(
                tiposParoLocal, tiposParoLocal.requiereGalones);
            await m.addColumn(
                tiposParoLocal, tiposParoLocal.requiereEquipo);
          }
          if (from < 4) {
            // v3→v4: codigoInterno en TractoresLocal e ImplementosLocal
            await m.addColumn(tractoresLocal, tractoresLocal.codigoInterno);
            await m.addColumn(implementosLocal, implementosLocal.codigoInterno);
          }
          if (from < 5) {
            // v4→v5: tablas nuevas MMA
            // Las tablas nuevas se crean con CREATE TABLE IF NOT EXISTS
            // para ser idempotentes aunque el .g.dart no esté generado aún.
            await customStatement('''
              CREATE TABLE IF NOT EXISTS subprocesos_local (
                id INTEGER NOT NULL,
                proceso_id INTEGER NOT NULL,
                nombre TEXT NOT NULL,
                codigo TEXT NOT NULL,
                descripcion TEXT,
                activo INTEGER NOT NULL DEFAULT 1,
                PRIMARY KEY (id)
              )
            ''');
            await customStatement('''
              CREATE TABLE IF NOT EXISTS menus_local (
                id INTEGER NOT NULL,
                parent_id INTEGER,
                titulo TEXT NOT NULL,
                icono TEXT,
                ruta TEXT,
                orden INTEGER NOT NULL DEFAULT 0,
                rol TEXT NOT NULL,
                PRIMARY KEY (id)
              )
            ''');
            await customStatement('''
              CREATE TABLE IF NOT EXISTS registros_vehiculo_local (
                id TEXT NOT NULL,
                registro_id TEXT NOT NULL,
                km_camion_inicio REAL,
                km_camion_final REAL,
                km_implemento_inicio REAL,
                km_implemento_final REAL,
                hora_salida_base_td TEXT,
                hora_llegada_zona TEXT,
                hora_retorno_base TEXT,
                hora_llegada_taller TEXT,
                hora_refrigerio TEXT,
                cantidad_tancadas INTEGER,
                observaciones_maq TEXT,
                sincronizado INTEGER NOT NULL DEFAULT 0,
                created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now') * 1000),
                PRIMARY KEY (id)
              )
            ''');
            await customStatement('''
              CREATE TABLE IF NOT EXISTS combustible_vehiculo_local (
                id TEXT NOT NULL,
                registro_id TEXT NOT NULL,
                glns REAL,
                hora_inicio TEXT,
                hora_final TEXT,
                PRIMARY KEY (id)
              )
            ''');
            await customStatement('''
              CREATE TABLE IF NOT EXISTS portero_lecturas_local (
                id TEXT NOT NULL,
                portero_id_erp INTEGER NOT NULL,
                tractor_id_erp INTEGER,
                tractor_codigo TEXT,
                tractor_leido_at INTEGER,
                implemento_id_erp INTEGER,
                implemento_codigo TEXT,
                implemento_leido_at INTEGER,
                trabajador_id_erp INTEGER,
                trabajador_codigo TEXT,
                operador_leido_at INTEGER,
                cultivo_id_erp INTEGER,
                cultivo_nombre TEXT,
                comentario TEXT,
                dispositivo_id TEXT,
                sincronizado INTEGER NOT NULL DEFAULT 0,
                created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now') * 1000),
                PRIMARY KEY (id)
              )
            ''');
            // Nuevas columnas en registros_diarios_local
            await _tryAlter('registros_diarios_local ADD COLUMN subproceso_id INTEGER');
            await _tryAlter('registros_diarios_local ADD COLUMN subproceso_nombre TEXT');
            await _tryAlter('registros_diarios_local ADD COLUMN jornada_inicio_at INTEGER');
            await _tryAlter('registros_diarios_local ADD COLUMN jornada_fin_at INTEGER');
            await _tryAlter("registros_diarios_local ADD COLUMN tipo_registro TEXT NOT NULL DEFAULT 'tractor'");
          }
          if (from < 6) {
            // v5→v6: tablas para control de jornada con sincronización automática
            await customStatement('''
              CREATE TABLE IF NOT EXISTS status_jornada_local (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                usuario_id INTEGER NOT NULL,
                dispositivo_id TEXT NOT NULL,
                turno TEXT NOT NULL,
                jornada_inicio_at INTEGER NOT NULL,
                jornada_fin_at INTEGER,
                sincronizado INTEGER NOT NULL DEFAULT 0,
                created_at INTEGER NOT NULL DEFAULT (strftime('%s','now') * 1000)
              )
            ''');
            await customStatement('''
              CREATE TABLE IF NOT EXISTS status_jornada_pendiente (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                payload_json TEXT NOT NULL,
                intentos INTEGER NOT NULL DEFAULT 0,
                created_at INTEGER NOT NULL DEFAULT (strftime('%s','now') * 1000)
              )
            ''');
          }
          if (from < 7) {
            // v6→v7: tipo_registro en checklist_items_local
            await _tryAlter("checklist_items_local ADD COLUMN tipo_registro TEXT NOT NULL DEFAULT 'tractor'");
          }
          if (from < 8) {
            // v7→v8: sub-labores, marchas, incumplimientos, requiere_sublabores en procesos
            await _tryAlter('procesos_local ADD COLUMN requiere_sublabores INTEGER NOT NULL DEFAULT 0');
            await customStatement('''
              CREATE TABLE IF NOT EXISTS sub_labores_local (
                id TEXT NOT NULL,
                registro_id TEXT NOT NULL,
                sublabor_nombre TEXT NOT NULL,
                created_at INTEGER NOT NULL DEFAULT (strftime('%s','now') * 1000),
                PRIMARY KEY (id)
              )
            ''');
            await customStatement('''
              CREATE TABLE IF NOT EXISTS marchas_local (
                id TEXT NOT NULL,
                registro_id TEXT NOT NULL,
                marcha_codigo TEXT NOT NULL,
                horas_uso REAL,
                created_at INTEGER NOT NULL DEFAULT (strftime('%s','now') * 1000),
                PRIMARY KEY (id)
              )
            ''');
            await customStatement('''
              CREATE TABLE IF NOT EXISTS incumplimientos_local (
                id TEXT NOT NULL,
                usuario_erp_id INTEGER NOT NULL,
                nombre_usuario TEXT NOT NULL DEFAULT '',
                fecha_jornada INTEGER NOT NULL,
                turno TEXT NOT NULL DEFAULT 'dia',
                tipo_incumplimiento TEXT NOT NULL,
                detalle TEXT,
                dispositivo_id TEXT,
                firestore_doc_id TEXT,
                sincronizado INTEGER NOT NULL DEFAULT 0,
                created_at INTEGER NOT NULL DEFAULT (strftime('%s','now') * 1000),
                PRIMARY KEY (id)
              )
            ''');
          }
          if (from < 9) {
            // v8→v9: tipo_registro en procesos_local para separar procesos de tractor y vehiculo
            await _tryAlter("procesos_local ADD COLUMN tipo_registro TEXT NOT NULL DEFAULT 'tractor'");
          }
          if (from < 10) {
            // v9→v10: tabla persistente de último horómetro por tractor.
            // No se borra con limpiarDatosJornada ni con el reset diario —
            // sirve como referencia entre jornadas y dispositivos.
            await customStatement('''
              CREATE TABLE IF NOT EXISTS ultimo_horometro_tractores_local (
                tractor_id_erp    INTEGER PRIMARY KEY,
                horometro_final   REAL,
                implemento_final  REAL,
                ultima_fecha      TEXT,
                updated_at        INTEGER NOT NULL DEFAULT (strftime('%s','now') * 1000)
              )
            ''');
          }
          if (from < 11) {
            // v10→v11: catálogo de vehículos V%
            await customStatement('''
              CREATE TABLE IF NOT EXISTS vehiculos_local (
                id_erp          INTEGER PRIMARY KEY,
                codigo_vehiculo TEXT NOT NULL,
                descripcion     TEXT NOT NULL,
                marca           TEXT,
                modelo          TEXT,
                matricula       TEXT,
                codigo_interno  TEXT,
                activo          INTEGER NOT NULL DEFAULT 1
              )
            ''');
          }
          if (from < 12) {
            // v11→v12: usuario_erp_id en trabajadores_local (Usuarios.Id del ERP)
            await _tryAlter('trabajadores_local ADD COLUMN usuario_erp_id INTEGER');
          }
          if (from < 13) {
            // v12→v13: codigo_barra en trabajadores_local (código físico/barcode).
            // Permite que portero y PIN entry funcionen con el código de barras
            // físico incluso cuando difiere de CodigoUsuario (ej. "468834" vs "PCORZO").
            await _tryAlter('trabajadores_local ADD COLUMN codigo_barra TEXT');
          }
          if (from < 15) {
            // v14→v15: catálogo de fallas mecánicas + columnas mecánico en paros
            await customStatement('''
              CREATE TABLE IF NOT EXISTS fallas_mecanicas_local (
                id     INTEGER PRIMARY KEY,
                codigo TEXT NOT NULL,
                nombre TEXT NOT NULL
              )
            ''');
            await _tryAlter('paros_equipos_local ADD COLUMN falla_mecanica_id INTEGER');
            await _tryAlter('paros_equipos_local ADD COLUMN falla_mecanica_nombre TEXT');
          }
          if (from < 14) {
            // v13→v14: tractor_id_erp pasa de INTEGER a TEXT en
            // ultimo_horometro_tractores_local.  El ERP envía el código de tractor
            // como string (e.g. "T-007"), no como entero, por lo que INTEGER PRIMARY
            // KEY rechazaba el INSERT con "datatype mismatch".
            // Se recrea la tabla vacía — los datos vendrán del próximo sync de catálogo.
            await customStatement('DROP TABLE IF EXISTS ultimo_horometro_tractores_local');
            await customStatement('''
              CREATE TABLE IF NOT EXISTS ultimo_horometro_tractores_local (
                tractor_id_erp    TEXT PRIMARY KEY,
                horometro_final   REAL,
                implemento_final  REAL,
                ultima_fecha      TEXT,
                updated_at        INTEGER NOT NULL DEFAULT (strftime('%s','now') * 1000)
              )
            ''');
          }
          if (from < 16) {
            // v15→v16: implemento_id_erp y codigo_implemento permiten saber
            // qué implemento generó el implemento_final almacenado, para no
            // aplicar el mínimo cuando el usuario selecciona otro diferente.
            await _tryAlter(
                'ultimo_horometro_tractores_local ADD COLUMN implemento_id_erp INTEGER');
            await _tryAlter(
                'ultimo_horometro_tractores_local ADD COLUMN codigo_implemento TEXT');
          }
          if (from < 17) {
            // v16→v17: firma digital del operador (base64 PNG) capturada al cerrar turno.
            await _tryAlter(
                'registros_diarios_local ADD COLUMN firma_operador TEXT');
          }
          if (from < 18) {
            // v17→v18: categoria y componentes_afectados en fallas_mecanicas_local.
            // Permite agrupar las fallas por tipo (MECANICO, ELECTRICO, HIDRAULICO,
            // LUBRICACION, FISICOQUIMICO) y mostrar los componentes típicos.
            await _tryAlter(
                "fallas_mecanicas_local ADD COLUMN categoria TEXT NOT NULL DEFAULT 'MECANICO'");
            await _tryAlter(
                'fallas_mecanicas_local ADD COLUMN componentes_afectados TEXT');
          }
          if (from < 19) {
            // v18→v19: tabla GPS de trazabilidad de maquinaria.
            // Nombre físico definido por el cliente: CLI547_AGM_Punto_gps_maquinaria.
            // Almacena puntos GPS capturados durante la jornada para reconstruir
            // la ruta del tractor/vehículo e incluirla en el payload de sync.
            await customStatement('''
              CREATE TABLE IF NOT EXISTS "CLI547_AGM_Punto_gps_maquinaria" (
                id          TEXT NOT NULL,
                registro_id TEXT NOT NULL,
                latitud     REAL NOT NULL,
                longitud    REAL NOT NULL,
                precision   REAL,
                altitud     REAL,
                velocidad   INTEGER,
                secuencia   INTEGER NOT NULL DEFAULT 0,
                captured_at INTEGER NOT NULL,
                PRIMARY KEY (id)
              )
            ''');
            await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_gps_registro '
              'ON "CLI547_AGM_Punto_gps_maquinaria"(registro_id)',
            );
          }
          if (from < 20) {
            // v19→v20: columna `enviado` en la tabla GPS.
            // 0 = pendiente de enviar al SP dedicado GPS.
            // 1 = ya enviado y confirmado por el servidor.
            // GpsSyncService lee WHERE enviado = 0 y marca 1 tras el envío exitoso.
            await _tryAlter(
              '"CLI547_AGM_Punto_gps_maquinaria" ADD COLUMN enviado INTEGER NOT NULL DEFAULT 0',
            );
            await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_gps_enviado '
              'ON "CLI547_AGM_Punto_gps_maquinaria"(enviado)',
            );
          }
          if (from < 21) {
            // v20→v21: geometrías de sublote en lotes_local (desde catálogo lotes_kmz)
            // y campos de analytics por punto GPS.
            //
            // lotes_local: 5 columnas nuevas para point-in-polygon offline y mapa
            await _tryAlter('lotes_local ADD COLUMN geometria_wkt TEXT');
            await _tryAlter('lotes_local ADD COLUMN latitud_centro REAL');
            await _tryAlter('lotes_local ADD COLUMN longitud_centro REAL');
            await _tryAlter('lotes_local ADD COLUMN nombre_cultivo TEXT');
            await _tryAlter('lotes_local ADD COLUMN color_cultivo TEXT');
            // CLI547_AGM_Punto_gps_maquinaria: 4 columnas para analytics
            // rumbo: dirección en grados (0–360)
            // velocidad_kmh: velocidad en km/h (speed m/s * 3.6)
            // tipo_movimiento: 'TRABAJO' | 'TRASLADO' | 'PARADO'
            // sublote_id: ID ERP del sublote donde se capturó el punto (null = fuera)
            await _tryAlter('"CLI547_AGM_Punto_gps_maquinaria" ADD COLUMN rumbo REAL');
            await _tryAlter('"CLI547_AGM_Punto_gps_maquinaria" ADD COLUMN velocidad_kmh REAL');
            await _tryAlter('"CLI547_AGM_Punto_gps_maquinaria" ADD COLUMN tipo_movimiento TEXT');
            await _tryAlter('"CLI547_AGM_Punto_gps_maquinaria" ADD COLUMN sublote_id INTEGER');
          }
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
          // Entradas atascadas en 'syncing' (la app se cerró a mitad de sync):
          // se restauran a 'failed' y se reinicia retry_count para que el siguiente ciclo las reintente.
          await customStatement(
            "UPDATE outbox_entries SET status = 'failed', retry_count = 0 WHERE status = 'syncing'",
          );
          // Índices de rendimiento — idempotentes, se aplican en toda apertura.
          // Cubren tanto instalaciones frescas como upgrades existentes.
          await customStatement('CREATE INDEX IF NOT EXISTS idx_reg_operador  ON registros_diarios_local(operador_id_erp)');
          await customStatement('CREATE INDEX IF NOT EXISTS idx_reg_fecha      ON registros_diarios_local(fecha)');
          await customStatement('CREATE INDEX IF NOT EXISTS idx_reg_sync       ON registros_diarios_local(sincronizado)');
          await customStatement('CREATE INDEX IF NOT EXISTS idx_paros_reg      ON paros_equipos_local(registro_id)');
          await customStatement('CREATE INDEX IF NOT EXISTS idx_checklist_reg  ON checklist_resultados_local(registro_id)');
          await customStatement('CREATE INDEX IF NOT EXISTS idx_bines_reg      ON cosecha_bines_local(registro_id)');
          await customStatement('CREATE INDEX IF NOT EXISTS idx_sectores_reg   ON registros_sectores_local(registro_id)');
          await customStatement('CREATE INDEX IF NOT EXISTS idx_outbox_status  ON outbox_entries(status, retry_count, timestamp)');
          // Columnas añadidas fuera del schema Drift — se aplican aquí para
          // cubrir tanto instalaciones frescas (onCreate) como upgrades.
          // El try/catch las hace idempotentes: si ya existen, no hacen nada.
          await _tryAlter("procesos_local ADD COLUMN tipo_registro TEXT NOT NULL DEFAULT 'tractor'");
          // v13→v15: columnas de falla mecánica en paros
          await _tryAlter('paros_equipos_local ADD COLUMN falla_mecanica_id INTEGER');
          await _tryAlter('paros_equipos_local ADD COLUMN falla_mecanica_nombre TEXT');
          // v15→v16: identificación del implemento en último horómetro
          await _tryAlter('ultimo_horometro_tractores_local ADD COLUMN implemento_id_erp INTEGER');
          await _tryAlter('ultimo_horometro_tractores_local ADD COLUMN codigo_implemento TEXT');
          // v16→v17: firma digital del operador
          await _tryAlter('registros_diarios_local ADD COLUMN firma_operador TEXT');
          // v17→v18: categoría y componentes en fallas mecánicas
          await _tryAlter("fallas_mecanicas_local ADD COLUMN categoria TEXT NOT NULL DEFAULT 'MECANICO'");
          await _tryAlter('fallas_mecanicas_local ADD COLUMN componentes_afectados TEXT');
          // Tablas raw SQL — se crean aquí para garantizar existencia tanto en
          // install fresco (onCreate) como en upgrades y limpiezas de datos.
          await customStatement('''
            CREATE TABLE IF NOT EXISTS mma_perfil_usuario_local (
              codigo_usuario TEXT PRIMARY KEY,
              nombre_completo TEXT,
              area_proviene TEXT,
              fundo TEXT,
              sede TEXT,
              dni TEXT,
              puesto_trabajo TEXT,
              codigo_trabajador TEXT,
              fecha_creacion_usuario TEXT,
              estado_usuario TEXT,
              sincronizado_at TEXT
            )
          ''');
          await customStatement('''
            CREATE TABLE IF NOT EXISTS status_jornada_local (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              usuario_id INTEGER NOT NULL,
              dispositivo_id TEXT NOT NULL,
              turno TEXT NOT NULL,
              jornada_inicio_at INTEGER NOT NULL,
              jornada_fin_at INTEGER,
              sincronizado INTEGER NOT NULL DEFAULT 0,
              created_at INTEGER NOT NULL DEFAULT (strftime('%s','now') * 1000)
            )
          ''');
          await customStatement('''
            CREATE TABLE IF NOT EXISTS status_jornada_pendiente (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              payload_json TEXT NOT NULL,
              intentos INTEGER NOT NULL DEFAULT 0,
              created_at INTEGER NOT NULL DEFAULT (strftime('%s','now') * 1000)
            )
          ''');
          await customStatement('''
            CREATE TABLE IF NOT EXISTS sub_labores_local (
              id TEXT NOT NULL,
              registro_id TEXT NOT NULL,
              sublabor_nombre TEXT NOT NULL,
              created_at INTEGER NOT NULL DEFAULT (strftime('%s','now') * 1000),
              PRIMARY KEY (id)
            )
          ''');
          await customStatement('''
            CREATE TABLE IF NOT EXISTS marchas_local (
              id TEXT NOT NULL,
              registro_id TEXT NOT NULL,
              marcha_codigo TEXT NOT NULL,
              horas_uso REAL,
              created_at INTEGER NOT NULL DEFAULT (strftime('%s','now') * 1000),
              PRIMARY KEY (id)
            )
          ''');
          await customStatement('''
            CREATE TABLE IF NOT EXISTS incumplimientos_local (
              id TEXT NOT NULL,
              usuario_erp_id INTEGER NOT NULL,
              nombre_usuario TEXT NOT NULL DEFAULT '',
              fecha_jornada INTEGER NOT NULL,
              turno TEXT NOT NULL DEFAULT 'dia',
              tipo_incumplimiento TEXT NOT NULL,
              detalle TEXT,
              dispositivo_id TEXT,
              firestore_doc_id TEXT,
              sincronizado INTEGER NOT NULL DEFAULT 0,
              created_at INTEGER NOT NULL DEFAULT (strftime('%s','now') * 1000),
              PRIMARY KEY (id)
            )
          ''');
          await customStatement('''
            CREATE TABLE IF NOT EXISTS ultimo_horometro_tractores_local (
              tractor_id_erp     TEXT PRIMARY KEY,
              horometro_final    REAL,
              implemento_final   REAL,
              implemento_id_erp  INTEGER,
              codigo_implemento  TEXT,
              ultima_fecha       TEXT,
              updated_at         INTEGER NOT NULL DEFAULT (strftime('%s','now') * 1000)
            )
          ''');
          await customStatement('''
            CREATE TABLE IF NOT EXISTS vehiculos_local (
              id_erp          INTEGER PRIMARY KEY,
              codigo_vehiculo TEXT NOT NULL,
              descripcion     TEXT NOT NULL,
              marca           TEXT,
              modelo          TEXT,
              matricula       TEXT,
              codigo_interno  TEXT,
              activo          INTEGER NOT NULL DEFAULT 1
            )
          ''');
          await customStatement('''
            CREATE TABLE IF NOT EXISTS fallas_mecanicas_local (
              id                    INTEGER PRIMARY KEY,
              codigo                TEXT NOT NULL,
              nombre                TEXT NOT NULL,
              categoria             TEXT NOT NULL DEFAULT 'MECANICO',
              componentes_afectados TEXT
            )
          ''');
          await _tryAlter('paros_equipos_local ADD COLUMN falla_mecanica_id INTEGER');
          await _tryAlter('paros_equipos_local ADD COLUMN falla_mecanica_nombre TEXT');
          // GPS trazabilidad — tabla con nombre definido por el cliente (v19/v20)
          // enviado: 0=pendiente de enviar al SP GPS, 1=confirmado en SQL Server
          await customStatement('''
            CREATE TABLE IF NOT EXISTS "CLI547_AGM_Punto_gps_maquinaria" (
              id          TEXT    NOT NULL,
              registro_id TEXT    NOT NULL,
              latitud     REAL    NOT NULL,
              longitud    REAL    NOT NULL,
              precision   REAL,
              altitud     REAL,
              velocidad   INTEGER,
              secuencia   INTEGER NOT NULL DEFAULT 0,
              captured_at INTEGER NOT NULL,
              enviado     INTEGER NOT NULL DEFAULT 0,
              PRIMARY KEY (id)
            )
          ''');
          await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_gps_registro '
            'ON "CLI547_AGM_Punto_gps_maquinaria"(registro_id)',
          );
          // Idempotente: agrega columna si no existe (upgrades v19 → v20)
          await _tryAlter(
            '"CLI547_AGM_Punto_gps_maquinaria" ADD COLUMN enviado INTEGER NOT NULL DEFAULT 0',
          );
          await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_gps_enviado '
            'ON "CLI547_AGM_Punto_gps_maquinaria"(enviado)',
          );
        },
      );

  /// Ejecuta un ALTER TABLE ignorando el error si la columna ya existe
  /// (idempotente entre migraciones y beforeOpen). Registra cualquier
  /// fallo distinto de "duplicate column" para facilitar el diagnóstico.
  Future<void> _tryAlter(String tableAndColumn) async {
    try {
      await customStatement('ALTER TABLE $tableAndColumn');
    } catch (e) {
      final msg = e.toString().toLowerCase();
      if (!msg.contains('duplicate column') && !msg.contains('already exists')) {
        developer.log(
          'ALTER TABLE $tableAndColumn falló: $e',
          name: 'AppDatabase/migrate',
          error: e,
        );
      }
    }
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'agricontrol.db'));
    return NativeDatabase.createInBackground(file);
  });
}
