import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:signature/signature.dart';

class FirmaPage extends StatefulWidget {
  const FirmaPage({super.key});

  @override
  State<FirmaPage> createState() => _FirmaPageState();
}

class _FirmaPageState extends State<FirmaPage> {
  final _ctrl = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _confirmar() async {
    if (_ctrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor firme antes de confirmar')),
      );
      return;
    }
    final Uint8List? png = await _ctrl.toPngBytes();
    if (mounted && png != null) Navigator.of(context).pop(png);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        title: const Text('Firma del Operador'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.undo),
            tooltip: 'Deshacer',
            onPressed: () => _ctrl.undo(),
          ),
          TextButton(
            onPressed: () => _ctrl.clear(),
            child: const Text('Limpiar', style: TextStyle(color: Colors.white70)),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Firme en el recuadro de abajo con su dedo o stylus',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade400, width: 1.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Signature(
                    controller: _ctrl,
                    backgroundColor: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _confirmar,
                icon: const Icon(Icons.check_circle),
                label: const Text('Confirmar Firma'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B5E20),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
