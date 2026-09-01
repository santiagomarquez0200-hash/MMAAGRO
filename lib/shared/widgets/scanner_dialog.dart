import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Abre un bottom-sheet con cámara de escaneo QR / código de barras.
///
/// Retorna el código escaneado como [String] (ya con `.trim()`) o `null`
/// si el usuario cancela o cierra el modal sin escanear.
///
/// Ejemplo de uso:
/// ```dart
/// final code = await showScannerDialog(context, label: 'Escanear Operario');
/// if (code != null) { /* buscar en catálogo */ }
/// ```
Future<String?> showScannerDialog(
  BuildContext context, {
  required String label,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _ScannerSheet(label: label),
  );
}

// ─────────────────────────────────────────────────────────────────────────────

class _ScannerSheet extends StatefulWidget {
  final String label;
  const _ScannerSheet({required this.label});

  @override
  State<_ScannerSheet> createState() => _ScannerSheetState();
}

class _ScannerSheetState extends State<_ScannerSheet> {
  late final MobileScannerController _controller;
  bool _detected = false;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      facing: CameraFacing.back,
      detectionSpeed: DetectionSpeed.noDuplicates,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_detected) return;
    final code = capture.barcodes.firstOrNull?.rawValue;
    if (code != null && code.trim().isNotEmpty) {
      _detected = true;
      final cleanedCode = code.replaceAll(' ', '').trim();
      if (mounted) Navigator.pop(context, cleanedCode);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;

    return Container(
      height: screenH * 0.72,
      decoration: const BoxDecoration(
        color: Color(0xFF0D1A14),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // ── Handle ──────────────────────────────────────────────────────────
          const SizedBox(height: 14),
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 18),

          // ── Título ───────────────────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.qr_code_scanner,
                color: Color(0xFF8CC53F),
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Apunta la cámara al código QR o de barras',
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
          const SizedBox(height: 16),

          // ── Área de cámara ───────────────────────────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    MobileScanner(
                      controller: _controller,
                      onDetect: _onDetect,
                    ),
                    // Mira de escaneo centrada
                    Center(
                      child: SizedBox(
                        width: 210,
                        height: 210,
                        child: CustomPaint(
                          painter: _ScanFramePainter(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Cancelar ─────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  backgroundColor: Colors.white12,
                  foregroundColor: Colors.white70,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, size: 18),
                label: const Text('Cancelar'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Mira decorativa con esquinas verdes ──────────────────────────────────────

class _ScanFramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final border = Paint()
      ..color = Colors.white24
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final corner = Paint()
      ..color = const Color(0xFF8CC53F)
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Marco completo tenue
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(8),
      ),
      border,
    );

    const L = 28.0; // longitud de cada esquina

    // Esquina superior-izquierda
    canvas.drawLine(const Offset(0, L), Offset.zero, corner);
    canvas.drawLine(Offset.zero, const Offset(L, 0), corner);

    // Esquina superior-derecha
    canvas.drawLine(Offset(size.width - L, 0), Offset(size.width, 0), corner);
    canvas.drawLine(Offset(size.width, 0), Offset(size.width, L), corner);

    // Esquina inferior-izquierda
    canvas.drawLine(
        Offset(0, size.height - L), Offset(0, size.height), corner);
    canvas.drawLine(
        Offset(0, size.height), Offset(L, size.height), corner);

    // Esquina inferior-derecha
    canvas.drawLine(Offset(size.width - L, size.height),
        Offset(size.width, size.height), corner);
    canvas.drawLine(Offset(size.width, size.height - L),
        Offset(size.width, size.height), corner);
  }

  @override
  bool shouldRepaint(_) => false;
}
