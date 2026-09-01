import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:agro_aplicaciones/infrastructure/database/app_database.dart';

// ── Modelos de resultado ──────────────────────────────────────────────────────

class BackupJornadaResumen {
  final String fecha;         // YYYY-MM-DD
  final String diaSemana;     // Lunes, Martes, …
  final int totalRegistros;
  final int sincronizados;
  final int pendientes;

  const BackupJornadaResumen({
    required this.fecha,
    required this.diaSemana,
    required this.totalRegistros,
    required this.sincronizados,
    required this.pendientes,
  });
}

class BackupResult {
  final int totalRegistros;
  final int sincronizados;
  final List<BackupJornadaResumen> jornadas;
  final String filePath;

  const BackupResult({
    required this.totalRegistros,
    required this.sincronizados,
    required this.jornadas,
    required this.filePath,
  });

  int get pendientes => totalRegistros - sincronizados;
  int get totalJornadas => jornadas.length;
}

// ── Servicio ──────────────────────────────────────────────────────────────────

/// Maneja backups locales del APK.
///
/// Dos modos de uso:
///  1. **Estático** (`BackupService.savePayload`) — guarda el payload del ERP
///     inmediatamente al cerrar un turno. No requiere instancia.
///  2. **Instancia** (`sl<BackupService>()`) — genera un ZIP/JSON de resumen
///     desde SQLite y permite compartirlo.
class BackupService {
  final AppDatabase _db;
  BackupService({required AppDatabase db}) : _db = db;

  // ── Instance methods ────────────────────────────────────────────────────────

  /// Lee todos los registros del operador en SQLite, los agrupa por fecha,
  /// genera un archivo JSON y devuelve el resumen para mostrarlo en la UI.
  Future<BackupResult> generarBackup({
    required int operadorIdErp,
    required String operadorCodigo,
  }) async {
    // 1. Leer registros del operador
    final registros = await _db.registroDao.getRegistros(
      operadorIdErp: operadorIdErp,
    );

    // 2. Agrupar por fecha (YYYY-MM-DD)
    final Map<String, List<RegistrosDiariosLocalData>> byDate = {};
    for (final r in registros) {
      final key =
          '${r.fecha.year}-${r.fecha.month.toString().padLeft(2, '0')}-${r.fecha.day.toString().padLeft(2, '0')}';
      byDate.putIfAbsent(key, () => []).add(r);
    }

    // 3. Calcular resúmenes por jornada (ordenadas newest first)
    final sortedEntries = byDate.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));
    final jornadas = <BackupJornadaResumen>[];
    for (final entry in sortedEntries) {
      final dateRegs = entry.value;
      final sinc = dateRegs.where((r) => r.sincronizado).length;
      final pend = dateRegs.length - sinc;
      jornadas.add(BackupJornadaResumen(
        fecha: entry.key,
        diaSemana: _diaSemana(DateTime.tryParse(entry.key)),
        totalRegistros: dateRegs.length,
        sincronizados: sinc,
        pendientes: pend,
      ));
    }

    final totalSinc = registros.where((r) => r.sincronizado).length;

    // 4. Construir payload JSON
    final payload = {
      'meta': {
        'operadorCodigo': operadorCodigo,
        'operadorIdErp': operadorIdErp,
        'generadoEn': DateTime.now().toIso8601String(),
        'totalRegistros': registros.length,
        'sincronizados': totalSinc,
        'pendientes': registros.length - totalSinc,
      },
      'jornadas': jornadas
          .map((j) => {
                'fecha': j.fecha,
                'diaSemana': j.diaSemana,
                'totalRegistros': j.totalRegistros,
                'sincronizados': j.sincronizados,
                'pendientes': j.pendientes,
              })
          .toList(),
      'registros': registros
          .map((r) => {
                'id': r.id,
                'numeroRegistro': r.numeroRegistro,
                'fecha': r.fecha.toIso8601String(),
                'estado': r.estado,
                'sincronizado': r.sincronizado,
                'procesoCodigo': r.procesoCodigo,
                'tractorCodigo': r.tractorCodigo,
                'turno': r.turno,
              })
          .toList(),
    };

    // 5. Escribir archivo
    final dir = await getApplicationDocumentsDirectory();
    final now = DateTime.now();
    final dateStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final ts =
        '${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';
    final backupDir = Directory('${dir.path}/backups/$dateStr/$operadorCodigo');
    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }
    final file = File('${backupDir.path}/${ts}_resumen_backup.json');
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(payload));

    return BackupResult(
      totalRegistros: registros.length,
      sincronizados: totalSinc,
      jornadas: jornadas,
      filePath: file.path,
    );
  }

  /// Comparte el archivo de backup usando el selector nativo del sistema.
  Future<void> compartirBackup(String filePath) async {
    final file = XFile(filePath);
    await Share.shareXFiles(
      [file],
      subject: 'Backup AgriControl',
      text: 'Backup de registros generado desde el APK.',
    );
  }

  // ── Static methods (sin acceso a DB) ────────────────────────────────────────

  /// Guarda una copia local del payload JSON enviado al ERP.
  /// Directorio: <app_documents>/backups/<YYYY-MM-DD>/<usuarioCodigo>/
  /// Archivo:    <HHmmss>_registro_<registroId>.json
  static Future<void> savePayload({
    required String registroId,
    required String usuarioCodigo,
    required Map<String, dynamic> payload,
  }) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final now = DateTime.now();
      final dateStr =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final timestamp =
          '${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';

      final backupDir =
          Directory('${dir.path}/backups/$dateStr/$usuarioCodigo');
      if (!await backupDir.exists()) {
        await backupDir.create(recursive: true);
      }

      final file = File(
          '${backupDir.path}/${timestamp}_registro_$registroId.json');
      await file.writeAsString(
        const JsonEncoder.withIndent('  ').convert({
          'meta': {
            'registroId': registroId,
            'usuarioCodigo': usuarioCodigo,
            'fechaBackup': now.toIso8601String(),
          },
          'payload': payload,
        }),
      );
    } catch (_) {
      // Best-effort — nunca bloquear el flujo principal
    }
  }

  /// Guarda un archivo JSON específico para la ruta GPS del registro.
  ///
  /// Incluye:
  ///  - El WKT (LINESTRING / POINT) tal como se envía al SP.
  ///  - Un bloque SQL INSERT listo para ejecutar manualmente en SQL Server
  ///    si el SP no insertó la fila en CLI547_AGM_Ruta_maquinaria.
  ///
  /// Se llama desde cerrarTurno justo después de construir el payload.
  /// Best-effort: nunca bloquea el flujo principal si falla.
  static Future<void> saveRutaGps({
    required String registroId,
    required String usuarioCodigo,
    required String? rutaWkt,
    required Map<String, dynamic> meta,
  }) async {
    if (rutaWkt == null || rutaWkt.isEmpty) return; // sin GPS → nada que guardar
    try {
      final dir = await getApplicationDocumentsDirectory();
      final now = DateTime.now();
      final dateStr =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final ts =
          '${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';

      final backupDir =
          Directory('${dir.path}/backups/$dateStr/$usuarioCodigo');
      if (!await backupDir.exists()) {
        await backupDir.create(recursive: true);
      }

      // SQL listo para inserción manual en caso de falla del SP
      final operadorId  = meta['operador_id_erp']  ?? 'NULL';
      final tractorId   = meta['tractor_id_erp']   ?? 'NULL';
      final procesoId   = meta['proceso_id']        != null ? '${meta['proceso_id']}' : 'NULL';
      final fecha       = meta['fecha']             ?? 'NULL';

      final sqlManual = '''
-- ============================================================
-- INSERCIÓN MANUAL — usar solo si la ruta no quedó en servidor
-- Registro : $registroId
-- Generado : ${now.toIso8601String()}
-- ============================================================
MERGE INTO dbo.CLI547_AGM_Ruta_maquinaria WITH (HOLDLOCK) AS target
USING (SELECT CAST('$registroId' AS UNIQUEIDENTIFIER) AS registro_id) AS src
    ON target.registro_id = src.registro_id
WHEN NOT MATCHED THEN
  INSERT (id, registro_id, ruta_geog, total_puntos, longitud_km,
          operador_id_erp, fecha, tractor_id_erp, proceso_id, sincronizado_at)
  VALUES (
    NEWID(),
    '$registroId',
    GEOGRAPHY::STGeomFromText('$rutaWkt', 4326),
    GEOGRAPHY::STGeomFromText('$rutaWkt', 4326).STNumPoints(),
    CAST(GEOGRAPHY::STGeomFromText('$rutaWkt', 4326).STLength() / 1000.0 AS DECIMAL(10,3)),
    $operadorId,
    '$fecha',
    $tractorId,
    $procesoId,
    SYSUTCDATETIME()
  );
''';

      final file = File('${backupDir.path}/${ts}_ruta_gps_$registroId.json');
      await file.writeAsString(
        const JsonEncoder.withIndent('  ').convert({
          'meta': {
            'registroId': registroId,
            'usuarioCodigo': usuarioCodigo,
            'fechaBackup': now.toIso8601String(),
            'nota': 'Usar sql_insercion_manual si la ruta no aparece en CLI547_AGM_Ruta_maquinaria',
            ...meta,
          },
          'ruta_wkt': rutaWkt,
          'sql_insercion_manual': sqlManual,
        }),
      );
    } catch (_) {
      // Best-effort — nunca bloquear el flujo principal
    }
  }

  /// Lista las fechas de backup disponibles (carpetas bajo backups/), newest first.
  static Future<List<String>> listDates() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final backupsDir = Directory('${dir.path}/backups');
      if (!await backupsDir.exists()) return [];
      return backupsDir
          .listSync()
          .whereType<Directory>()
          .map((d) => d.path.split(Platform.pathSeparator).last)
          .toList()
        ..sort((a, b) => b.compareTo(a));
    } catch (_) {
      return [];
    }
  }

  /// Elimina backups más antiguos que [days] días para evitar consumo excesivo.
  static Future<void> pruneOldBackups({int days = 30}) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final backupsDir = Directory('${dir.path}/backups');
      if (!await backupsDir.exists()) return;
      final cutoff = DateTime.now().subtract(Duration(days: days));
      for (final d in backupsDir.listSync().whereType<Directory>()) {
        final name = d.path.split(Platform.pathSeparator).last;
        final date = DateTime.tryParse(name);
        if (date != null && date.isBefore(cutoff)) {
          await d.delete(recursive: true);
        }
      }
    } catch (_) {}
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  static String _diaSemana(DateTime? dt) {
    if (dt == null) return '';
    const dias = [
      'Lunes', 'Martes', 'Miércoles', 'Jueves',
      'Viernes', 'Sábado', 'Domingo'
    ];
    return dias[(dt.weekday - 1) % 7];
  }
}
