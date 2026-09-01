import 'package:equatable/equatable.dart';

/// Sesión activa del trabajador en el dispositivo.
/// Se persiste en FlutterSecureStorage tras login exitoso.
class Usuario extends Equatable {
  /// UUID local (generado en primer login o proveniente del backend).
  final String id;

  /// Código de trabajador ERP (ej. "PCO-T-0012").
  final String codigo;

  final String nombres;
  final String apellidos;
  final String? dni;
  final String? telefono;
  final String? email;

  /// SHA-256 del PIN de 4 dígitos — nunca se transmite en claro.
  final String? pinHash;

  /// ID del usuario en la tabla Usuarios del ERP (Usuarios.Id).
  /// Es el que se envía al SP de jornada (ACTUALIZAR_STATUS_JORNADA).
  final int? usuarioErpId;

  /// ID del trabajador en la tabla Trabajadores del ERP (Trabajadores.Id).
  /// Se usa en registros de turno (operador_id_erp en SINCRONIZAR_OFFLINE).
  final int? trabajadorIdErp;

  final int rolId;
  final String rolNombre; // 'operador' | 'supervisor' | 'gerente' | 'portero' | 'mecanico'
  final String? fotoUrl;
  final bool activo;

  const Usuario({
    required this.id,
    required this.codigo,
    required this.nombres,
    required this.apellidos,
    this.dni,
    this.telefono,
    this.email,
    this.pinHash,
    this.usuarioErpId,
    this.trabajadorIdErp,
    required this.rolId,
    required this.rolNombre,
    this.fotoUrl,
    required this.activo,
  });

  String get nombreCompleto => '$nombres $apellidos'.trim();

  bool get esOperador => rolNombre == 'operador';
  bool get esSupervisor => rolNombre == 'supervisor';
  bool get esGerente => rolNombre == 'gerente';

  /// ID a enviar en el SP de jornada: prefiere usuarioErpId, cae en trabajadorIdErp.
  int? get idParaJornada => usuarioErpId ?? trabajadorIdErp;

  @override
  List<Object?> get props => [id, codigo, rolNombre];
}
