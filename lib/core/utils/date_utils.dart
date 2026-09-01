import 'package:intl/intl.dart';

class AppDateUtils {
  AppDateUtils._();

  static final _dateFormat = DateFormat('yyyy-MM-dd');
  static final _timeFormat = DateFormat('HH:mm');
  static final _displayFormat = DateFormat('dd/MM/yyyy');
  static final _displayFullFormat = DateFormat('dd/MM/yyyy HH:mm');

  static String toApiDate(DateTime date) => _dateFormat.format(date);
  static String toApiTime(DateTime time) => _timeFormat.format(time);
  static String toDisplay(DateTime date) => _displayFormat.format(date);
  static String toDisplayFull(DateTime date) => _displayFullFormat.format(date);

  static DateTime? parseDate(String? value) {
    if (value == null || value.isEmpty) return null;
    try {
      return _dateFormat.parse(value);
    } catch (_) {
      return null;
    }
  }

  /// Inicio del día agrícola actual (medianoche del día correspondiente).
  /// Antes de las 04:00 pertenece al día anterior para no cortar el turno noche.
  static DateTime get diaAgricolaActual {
    final now = DateTime.now();
    final d = now.hour < 4 ? now.subtract(const Duration(days: 1)) : now;
    return DateTime(d.year, d.month, d.day);
  }

  static String generateRegistroNumber(
      DateTime fecha, int sequence, int operadorIdErp) {
    final dateStr = _dateFormat.format(fecha).replaceAll('-', '');
    final opStr = operadorIdErp.toString().padLeft(3, '0');
    return 'RD-$dateStr-$opStr-${sequence.toString().padLeft(3, '0')}';
  }

  // Franjas horarias para cosecha bines
  static List<String> get franjasHorarias {
    return List.generate(12, (i) {
      final start = (6 + i).toString().padLeft(2, '0');
      final end = (7 + i).toString().padLeft(2, '0');
      return '$start-$end';
    });
  }
}
