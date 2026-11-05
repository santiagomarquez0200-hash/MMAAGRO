import 'dart:developer' as developer;

import 'package:location/location.dart' as loc;

/// Pide al sistema que active la ubicación mostrando el diálogo nativo de
/// Google Play Services ("Para continuar, activa la ubicación del dispositivo").
///
/// Por qué existe un segundo paquete de ubicación:
///   `geolocator` solo puede llevar al operador a la pantalla de Ajustes
///   (`openLocationSettings`), lo que implica salir de la app y confiar en que
///   vuelva. El paquete `location` expone `requestService()`, que muestra el
///   diálogo del sistema con un botón que enciende la ubicación SIN salir de la
///   app. Para un operador en campo, con guantes y apuro, esa diferencia es la
///   que decide si la jornada se rastrea o no.
///
/// Alcance deliberadamente mínimo: este wrapper NO inicia streams ni pide
/// permisos. Todo el rastreo sigue siendo de `geolocator`. Tener dos plugins de
/// ubicación conviviendo es aceptable mientras solo uno escuche posiciones.
///
/// Limitación: el diálogo necesita una Activity visible, así que solo funciona
/// con la app en primer plano. Si el operador apaga el GPS con la app
/// minimizada, no hay forma de mostrárselo hasta que vuelva a abrirla; ahí la
/// única garantía real es una política MDM en el dispositivo.
class GpsServicePrompt {
  static final loc.Location _location = loc.Location();

  /// Devuelve true si el servicio de ubicación quedó activo.
  ///
  /// Nunca lanza: ante cualquier fallo devuelve false y deja que el llamador
  /// decida. Activar la ubicación es un intento, no una garantía.
  static Future<bool> solicitarActivacion() async {
    try {
      if (await _location.serviceEnabled()) return true;

      developer.log(
        'Ubicación desactivada — mostrando el diálogo del sistema',
        name: 'GpsServicePrompt',
      );
      final activado = await _location.requestService();

      developer.log(
        activado
            ? 'El operador activó la ubicación'
            : 'El operador RECHAZÓ activar la ubicación — la jornada se '
                'registrará sin ruta GPS',
        name: 'GpsServicePrompt',
      );
      return activado;
    } catch (e) {
      developer.log(
        'No se pudo mostrar el diálogo de activación: $e',
        name: 'GpsServicePrompt',
      );
      return false;
    }
  }
}
