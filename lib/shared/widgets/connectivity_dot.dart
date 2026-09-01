import 'package:flutter/material.dart';
import 'package:agro_aplicaciones/injection_container.dart';
import 'package:agro_aplicaciones/infrastructure/services/connectivity_service.dart';

/// Small colored dot that shows network connectivity status.
/// Green = online, red = offline. Designed for AppBar actions.
class ConnectivityDot extends StatelessWidget {
  const ConnectivityDot({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: sl<ConnectivityService>().onConnectivityChanged,
      initialData: sl<ConnectivityService>().isOnline,
      builder: (context, snapshot) {
        final isOnline = snapshot.data ?? true;
        return Padding(
          padding: const EdgeInsets.only(right: 12),
          child: Tooltip(
            message:
                isOnline ? 'Con conexión' : 'Sin conexión — modo offline',
            child: Container(
              width: 10,
              height: 10,
              margin: const EdgeInsets.symmetric(vertical: 17),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isOnline
                    ? const Color(0xFF52B788)
                    : const Color(0xFFFF6B6B),
                boxShadow: [
                  BoxShadow(
                    color: (isOnline
                            ? const Color(0xFF52B788)
                            : const Color(0xFFFF6B6B))
                        .withValues(alpha: 0.6),
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
