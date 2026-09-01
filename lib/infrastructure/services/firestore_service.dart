import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';

/// Servicio centralizado para escritura/lectura en Firestore.
/// Requiere que el usuario haya agregado google-services.json y configurado Firebase.
class FirestoreService {
  FirestoreService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;
  final _log = Logger();

  // ─── Colecciones ────────────────────────────────────────────────────────────

  CollectionReference<Map<String, dynamic>> get _incumplimientos =>
      _db.collection('incumplimientos');

  CollectionReference<Map<String, dynamic>> get _notificaciones =>
      _db.collection('notificaciones');

  // ─── Incumplimientos ────────────────────────────────────────────────────────

  /// Registra un incumplimiento de jornada en Firestore.
  /// Retorna el ID del documento creado, o null si falla.
  Future<String?> registrarIncumplimiento({
    required int usuarioErpId,
    required String nombreUsuario,
    required DateTime fechaJornada,
    required String turno,
    required String tipoIncumplimiento,
    String? detalle,
    String? dispositivoId,
  }) async {
    try {
      final doc = await _incumplimientos.add({
        'usuario_erp_id': usuarioErpId,
        'nombre_usuario': nombreUsuario,
        'fecha_jornada': Timestamp.fromDate(fechaJornada),
        'turno': turno,
        'tipo_incumplimiento': tipoIncumplimiento,
        'detalle': detalle,
        'dispositivo_id': dispositivoId,
        'leido_por_admin': false,
        'created_at': FieldValue.serverTimestamp(),
      });
      _log.i('[Firestore] Incumplimiento registrado: ${doc.id}');
      return doc.id;
    } catch (e) {
      _log.e('[Firestore] Error registrando incumplimiento: $e');
      return null;
    }
  }

  /// Stream de incumplimientos recientes (para panel admin), ordenados por fecha desc.
  Stream<List<IncumplimientoFirestore>> watchIncumplimientos({int limit = 50}) {
    return _incumplimientos
        .orderBy('created_at', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => IncumplimientoFirestore.fromMap(d.id, d.data()))
            .toList());
  }

  /// Marca un incumplimiento como leído por el admin.
  Future<void> marcarIncumplimientoLeido(String docId) async {
    try {
      await _incumplimientos.doc(docId).update({'leido_por_admin': true});
    } catch (e) {
      _log.w('[Firestore] No se pudo marcar incumplimiento $docId: $e');
    }
  }

  // ─── Notificaciones ─────────────────────────────────────────────────────────

  /// Envía una notificación push-lite a un operador (almacenada en Firestore).
  /// El operador debe escuchar su colección de notificaciones.
  Future<void> enviarNotificacion({
    required int destinatarioErpId,
    required String titulo,
    required String cuerpo,
  }) async {
    try {
      await _notificaciones.add({
        'destinatario_erp_id': destinatarioErpId,
        'titulo': titulo,
        'cuerpo': cuerpo,
        'leida': false,
        'created_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      _log.e('[Firestore] Error enviando notificación: $e');
    }
  }

  /// Stream de notificaciones no leídas para un operador específico.
  Stream<List<NotificacionFirestore>> watchNotificaciones(int usuarioErpId) {
    return _notificaciones
        .where('destinatario_erp_id', isEqualTo: usuarioErpId)
        .where('leida', isEqualTo: false)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => NotificacionFirestore.fromMap(d.id, d.data()))
            .toList());
  }

  /// Marca una notificación como leída.
  Future<void> marcarNotificacionLeida(String docId) async {
    try {
      await _notificaciones.doc(docId).update({'leida': true});
    } catch (e) {
      _log.w('[Firestore] No se pudo marcar notificación $docId: $e');
    }
  }
}

// ─── DTOs ────────────────────────────────────────────────────────────────────

class IncumplimientoFirestore {
  const IncumplimientoFirestore({
    required this.docId,
    required this.usuarioErpId,
    required this.nombreUsuario,
    required this.fechaJornada,
    required this.turno,
    required this.tipoIncumplimiento,
    this.detalle,
    this.dispositivoId,
    required this.leidoPorAdmin,
    this.createdAt,
  });

  final String docId;
  final int usuarioErpId;
  final String nombreUsuario;
  final DateTime fechaJornada;
  final String turno;
  final String tipoIncumplimiento;
  final String? detalle;
  final String? dispositivoId;
  final bool leidoPorAdmin;
  final DateTime? createdAt;

  factory IncumplimientoFirestore.fromMap(
      String id, Map<String, dynamic> map) {
    return IncumplimientoFirestore(
      docId: id,
      usuarioErpId: (map['usuario_erp_id'] as num?)?.toInt() ?? 0,
      nombreUsuario: map['nombre_usuario'] as String? ?? '',
      fechaJornada: (map['fecha_jornada'] as Timestamp?)?.toDate() ??
          DateTime.now(),
      turno: map['turno'] as String? ?? 'dia',
      tipoIncumplimiento: map['tipo_incumplimiento'] as String? ?? '',
      detalle: map['detalle'] as String?,
      dispositivoId: map['dispositivo_id'] as String?,
      leidoPorAdmin: map['leido_por_admin'] as bool? ?? false,
      createdAt: (map['created_at'] as Timestamp?)?.toDate(),
    );
  }

  String get tipoLabel {
    switch (tipoIncumplimiento) {
      case 'cierre_sin_sincronizar':
        return 'Cierre sin sincronizar';
      case 'jornada_100_pct':
        return 'Jornada completada sin sync';
      case 'retraso_excesivo':
        return 'Retraso excesivo';
      default:
        return tipoIncumplimiento;
    }
  }
}

class NotificacionFirestore {
  const NotificacionFirestore({
    required this.docId,
    required this.destinatarioErpId,
    required this.titulo,
    required this.cuerpo,
    required this.leida,
    this.createdAt,
  });

  final String docId;
  final int destinatarioErpId;
  final String titulo;
  final String cuerpo;
  final bool leida;
  final DateTime? createdAt;

  factory NotificacionFirestore.fromMap(String id, Map<String, dynamic> map) {
    return NotificacionFirestore(
      docId: id,
      destinatarioErpId: (map['destinatario_erp_id'] as num?)?.toInt() ?? 0,
      titulo: map['titulo'] as String? ?? '',
      cuerpo: map['cuerpo'] as String? ?? '',
      leida: map['leida'] as bool? ?? false,
      createdAt: (map['created_at'] as Timestamp?)?.toDate(),
    );
  }
}
