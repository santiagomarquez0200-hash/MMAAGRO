import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:agro_aplicaciones/app.dart';
import 'package:agro_aplicaciones/core/config/app_environment.dart';
import 'package:agro_aplicaciones/injection_container.dart';
import 'package:agro_aplicaciones/infrastructure/services/daily_reset_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Cargar variables de entorno desde .env (credenciales ERP, URLs)
  await dotenv.load(fileName: '.env');

  // Restaurar la URL de entorno guardada por el usuario (si existe)
  final prefs = await SharedPreferences.getInstance();
  final savedUrl = prefs.getString('env_url_override');
  if (savedUrl != null) AppEnvironment.setUrlOverride(savedUrl);

  // Inicializar Firebase con timeout: si el servicio no responde en 10 s el
  // arranque continúa sin notificaciones push en lugar de colgarse.
  try {
    await Firebase.initializeApp()
        .timeout(const Duration(seconds: 10));
  } catch (_) {
    // Firebase no disponible (sin internet, cuenta suspendida, etc.).
    // La app funciona offline; las funciones que dependen de Firebase
    // (notificaciones, Firestore) quedarán desactivadas silenciosamente.
  }

  // Orientación fija: portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Inicializar todas las dependencias (GetIt)
  await initDependencies();

  // Ejecutar el reset diario de las 04:00 h aquí, en el arranque de la app,
  // ANTES de mostrar cualquier pantalla. Esto evita que en primera instalación
  // el reset corra por primera vez dentro de home_page.dart (después de que el
  // operador ya abrió la jornada) y borre status_jornada_local recién creado.
  // En días posteriores esta llamada es un no-op (ya se corrió hoy).
  await sl<DailyResetService>().runIfNeeded();

  runApp(const AgriControlApp());
}
