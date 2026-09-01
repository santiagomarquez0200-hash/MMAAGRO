import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  final _controller = StreamController<bool>.broadcast();
  StreamSubscription? _sub;

  Stream<bool> get onConnectivityChanged => _controller.stream;

  bool _isOnline = true;
  bool get isOnline => _isOnline;

  void init() {
    _sub = Connectivity().onConnectivityChanged.listen((results) {
      final online = results.any((r) => r != ConnectivityResult.none);
      if (online != _isOnline) {
        _isOnline = online;
        _controller.add(online);
      }
    });
    // Check immediately
    Connectivity().checkConnectivity().then((results) {
      _isOnline = results.any((r) => r != ConnectivityResult.none);
      _controller.add(_isOnline);
    });
  }

  void dispose() {
    _sub?.cancel();
    _controller.close();
  }
}
