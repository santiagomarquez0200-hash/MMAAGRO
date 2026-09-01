import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:agro_aplicaciones/core/constants/app_constants.dart';

class DeviceService {
  final DeviceInfoPlugin _deviceInfo;
  final SharedPreferences _prefs;
  final _uuid = const Uuid();

  const DeviceService(this._deviceInfo, this._prefs);

  Future<String> getDeviceId() async {
    final cached = _prefs.getString(AppConstants.deviceIdKey);
    if (cached != null) return cached;

    String deviceId;
    try {
      final androidInfo = await _deviceInfo.androidInfo;
      deviceId = androidInfo.id;
    } catch (_) {
      deviceId = _uuid.v4();
    }

    await _prefs.setString(AppConstants.deviceIdKey, deviceId);
    return deviceId;
  }
}
