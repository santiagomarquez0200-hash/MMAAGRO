import 'package:dartz/dartz.dart';
import 'package:agro_aplicaciones/shared/auth/domain/entities/usuario.dart';
import 'package:agro_aplicaciones/shared/profile/domain/entities/perfil_usuario.dart';
import 'package:agro_aplicaciones/core/errors/failures.dart';

abstract class AuthRepository {
  Future<Either<Failure, void>> validarAccesoPin(String codigo, String pin);
  Future<Either<Failure, Usuario>> loginConPin(
      String codigo, String pin, String rol);
  /// Autentica directamente con la API ERP usando usuario y contraseña.
  Future<Either<Failure, Usuario>> loginConAPI(
      String username, String password, String rol);
  Future<Either<Failure, PerfilUsuario>> sincronizarPerfilProfesional(
      String usuarioLogin);
  Future<Either<Failure, PerfilUsuario?>> getPerfilProfesionalLocal(
      String? codigoUsuario);
  Future<Either<Failure, void>> logout();
  Future<Either<Failure, Usuario?>> getUsuarioActual();
  Future<Either<Failure, bool>> validarPin(String pin);
  Future<Either<Failure, void>> saveLastActivity();
  Future<Either<Failure, DateTime?>> getLastActivity();

  /// Intenta restaurar la sesión guardada localmente sin llamar a la API.
  /// Solo tiene éxito si:
  ///  - Existe un `session_usuario_json` de un login online previo.
  ///  - El [usuario] coincide con el login guardado.
  ///  - El sha-256 de [password] coincide con el hash guardado.
  Future<Either<Failure, Usuario>> tryRestoreOfflineSession(
      String usuario, String password);
}
