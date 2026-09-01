import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class DraftStorageService {
  static const _prefix = 'agro_draft';

  // Incrementar cuando cambie el esquema de cualquier formulario.
  // Los drafts guardados con versión anterior se descartan automáticamente.
  static const int _kSchemaVersion = 1;
  static const String _kVersionField = '__v';

  Future<Map<String, dynamic>?> read(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_prefix:$key');
    if (raw == null || raw.isEmpty) return null;

    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) return null;

    // Descartar drafts de versión de esquema anterior para evitar
    // crashes silenciosos al deserializar campos renombrados o eliminados.
    if ((decoded[_kVersionField] as int?) != _kSchemaVersion) {
      await delete(key);
      return null;
    }

    final data = Map<String, dynamic>.from(decoded)..remove(_kVersionField);
    return data;
  }

  Future<void> write(String key, Map<String, dynamic> value) async {
    final prefs = await SharedPreferences.getInstance();
    final payload = {...value, _kVersionField: _kSchemaVersion};
    await prefs.setString('$_prefix:$key', jsonEncode(payload));
  }

  Future<void> delete(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_prefix:$key');
  }
}
