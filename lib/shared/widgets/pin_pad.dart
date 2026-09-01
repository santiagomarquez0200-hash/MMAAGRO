import 'package:flutter/material.dart';

class PinPad extends StatefulWidget {
  final void Function(String pin) onPinChanged;
  final void Function(String pin) onPinComplete;
  final int pinLength;

  const PinPad({
    super.key,
    required this.onPinChanged,
    required this.onPinComplete,
    this.pinLength = 4,
  });

  @override
  State<PinPad> createState() => _PinPadState();
}

class _PinPadState extends State<PinPad> {
  String _pin = '';

  void _onDigit(String digit) {
    if (_pin.length >= widget.pinLength) return;
    final newPin = _pin + digit;
    setState(() => _pin = newPin);
    widget.onPinChanged(newPin);
    if (newPin.length == widget.pinLength) {
      widget.onPinComplete(newPin);
    }
  }

  void _onDelete() {
    if (_pin.isEmpty) return;
    final newPin = _pin.substring(0, _pin.length - 1);
    setState(() => _pin = newPin);
    widget.onPinChanged(newPin);
  }

  void clear() {
    setState(() => _pin = '');
    widget.onPinChanged('');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildRow(['1', '2', '3']),
        const SizedBox(height: 12),
        _buildRow(['4', '5', '6']),
        const SizedBox(height: 12),
        _buildRow(['7', '8', '9']),
        const SizedBox(height: 12),
        _buildRow(['', '0', '⌫']),
      ],
    );
  }

  Widget _buildRow(List<String> keys) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: keys.map((k) {
        if (k.isEmpty) return const SizedBox(width: 80, height: 64);
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: InkWell(
            onTap: () => k == '⌫' ? _onDelete() : _onDigit(k),
            borderRadius: BorderRadius.circular(40),
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.15),
              ),
              child: Center(
                child: Text(
                  k,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
