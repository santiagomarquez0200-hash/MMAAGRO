import 'package:equatable/equatable.dart';

class PerfilUsuario extends Equatable {
  final String  codigoUsuario;
  final String  nombreCompleto;
  final String  areaProviene;
  final String  fundo;
  final String  sede;
  final String? dni;
  final String? puestoTrabajo;
  final String? codigoTrabajador;
  final DateTime? fechaCreacionUsuario;
  final String  estadoUsuario;
  final DateTime sincronizadoAt;

  /// ID entero del usuario en el sistema ERP (tabla Usuarios / Usuarios_Roles).
  /// Se extrae del SP de perfil si el campo está disponible en la respuesta.
  /// Es el mismo ID que CLI547_AGMSP_Obtener_Navegacion espera como @IdUsuario.
  final int? idUsuario;

  const PerfilUsuario({
    required this.codigoUsuario,
    required this.nombreCompleto,
    required this.areaProviene,
    required this.fundo,
    required this.sede,
    this.dni,
    this.puestoTrabajo,
    this.codigoTrabajador,
    this.fechaCreacionUsuario,
    required this.estadoUsuario,
    required this.sincronizadoAt,
    this.idUsuario,
  });

  @override
  List<Object?> get props => [codigoUsuario, sincronizadoAt];
}
