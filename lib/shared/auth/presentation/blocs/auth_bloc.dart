import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:agro_aplicaciones/shared/auth/domain/usecases/login_usecase.dart';
import 'package:agro_aplicaciones/shared/auth/domain/repositories/auth_repository.dart';
import 'package:agro_aplicaciones/core/errors/failures.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase _loginUseCase;
  final AuthRepository _authRepository;

  AuthBloc({
    required LoginUseCase loginUseCase,
    required AuthRepository authRepository,
  })  : _loginUseCase = loginUseCase,
        _authRepository = authRepository,
        super(const AuthInitial()) {
    on<AuthCheckRequested>(_onCheckRequested);
    on<AuthPinGateRequested>(_onPinGateRequested);
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
    on<AuthUserUpdated>((event, emit) {
      emit(AuthAuthenticated(usuario: event.usuario));
    });
  }

  Future<void> _onCheckRequested(
      AuthCheckRequested event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());

    // Session timeout: force re-login after 24 h of inactivity
    final lastActivityResult = await _authRepository.getLastActivity();
    final lastActivity = lastActivityResult.fold((_) => null, (dt) => dt);
    if (lastActivity != null) {
      final elapsed = DateTime.now().toUtc().difference(lastActivity.toUtc());
      if (elapsed.inHours >= 24) {
        await _authRepository.logout();
        emit(const AuthUnauthenticated());
        return;
      }
    }

    final result = await _authRepository.getUsuarioActual();
    result.fold(
      (_) => emit(const AuthUnauthenticated()),
      (usuario) {
        if (usuario != null) {
          emit(AuthAuthenticated(usuario: usuario));
        } else {
          emit(const AuthUnauthenticated());
        }
      },
    );
  }

  Future<void> _onLoginRequested(
      AuthLoginRequested event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());

    if (event.username.trim().isEmpty || event.password.trim().isEmpty) {
      emit(const AuthFailureState(
          message: 'Ingrese usuario y contraseña para continuar'));
      return;
    }

    final result = await _loginUseCase(
        LoginParams(username: event.username, password: event.password, rol: event.rol));

    if (result.isRight()) {
      result.fold((_) => null, (usuario) => emit(AuthAuthenticated(usuario: usuario)));
      await _authRepository.saveLastActivity();
      return;
    }

    // El login online falló. Verificar si fue un error de red para poder
    // intentar la sesión offline guardada del mismo usuario.
    final failure = result.fold((f) => f, (_) => null)!;

    if (failure is NetworkFailure) {
      // Solo los errores de red habilitan el fallback offline.
      // Errores de autenticación (credenciales incorrectas) siempre fallan.
      final offlineResult = await _authRepository.tryRestoreOfflineSession(
          event.username, event.password);

      offlineResult.fold(
        (offlineFailure) {
          // No hay sesión offline válida → mostrar el error de red original
          // pero con un mensaje más informativo.
          emit(AuthFailureState(
              message: 'Sin conexión a internet. '
                  '${offlineFailure.message == 'Sin sesión guardada' ? 'No hay sesión guardada para continuar sin red.' : offlineFailure.message}'));
        },
        (usuario) {
          // Sesión offline restaurada: el usuario puede operar sin red.
          emit(AuthAuthenticated(usuario: usuario));
        },
      );

      if (offlineResult.isRight()) await _authRepository.saveLastActivity();
      return;
    }

    // Error de autenticación u otro error → mostrar directamente.
    emit(AuthFailureState(message: failure.message));
  }

  Future<void> _onLogoutRequested(
      AuthLogoutRequested event, Emitter<AuthState> emit) async {
    await _authRepository.logout();
    emit(const AuthUnauthenticated());
  }

  Future<void> _onPinGateRequested(
      AuthPinGateRequested event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    final result =
        await _authRepository.validarAccesoPin(event.codigo, event.pin);
    result.fold(
      (failure) => emit(AuthFailureState(message: failure.message)),
      (_) => emit(AuthPinValidated(
          codigo: event.codigo, pin: event.pin, rol: event.rol)),
    );
  }
}
