import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:agro_aplicaciones/shared/auth/presentation/blocs/auth_bloc.dart';
import 'package:agro_aplicaciones/shared/auth/presentation/blocs/auth_event.dart';
import 'package:agro_aplicaciones/shared/auth/presentation/blocs/auth_state.dart';

class LoginPage extends StatefulWidget {
  final String codigo;
  final String pin;
  final String rol;

  const LoginPage({
    super.key,
    required this.codigo,
    required this.pin,
    required this.rol,
  });

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  Timer? _authTimeout;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthBloc>().add(AuthLoginRequested(
            codigo: widget.codigo,
            pin: widget.pin,
            username: widget.codigo,
            password: widget.pin,
            rol: widget.rol,
          ));
      // Si el ERP no responde en 30 s, regresar al PIN con mensaje claro.
      _authTimeout = Timer(const Duration(seconds: 30), () {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Sin respuesta del servidor. Verifica la red e intenta de nuevo.'),
          backgroundColor: Color(0xFFC62828),
          duration: Duration(seconds: 4),
        ));
        context.go('/pin');
      });
    });
  }

  @override
  void dispose() {
    _authTimeout?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B4332),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          // Cualquier resultado (éxito o fallo) cancela el timeout.
          _authTimeout?.cancel();
          _authTimeout = null;
          if (state is AuthFailureState) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red.shade800,
              duration: const Duration(seconds: 4),
            ));
            context.go('/pin');
          }
        },
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(14),
                  child: Image.asset(
                    'assets/images/ic_launcher2.png',
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 32),
                const CircularProgressIndicator(
                  color: Color(0xFF95D5B2),
                  strokeWidth: 3,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Autenticando...',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Verificando credenciales de ${widget.codigo}',
                  style: const TextStyle(
                    color: Color(0xFF95D5B2),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 48),
                Text(
                  'AgriControl · Agrokasa',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
