import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Selector Material de 24 horas con ruedas y entrada por teclado sincronizadas.
Future<TimeOfDay?> showSpinnerTimePicker({
  required BuildContext context,
  required TimeOfDay initialTime,
}) {
  return showDialog<TimeOfDay>(
    context: context,
    builder: (_) => _SpinnerTimePicker(initialTime: initialTime),
  );
}

class _SpinnerTimePicker extends StatefulWidget {
  final TimeOfDay initialTime;

  const _SpinnerTimePicker({required this.initialTime});

  @override
  State<_SpinnerTimePicker> createState() => _SpinnerTimePickerState();
}

class _SpinnerTimePickerState extends State<_SpinnerTimePicker> {
  final _formKey = GlobalKey<FormState>();
  final _hourFocus = FocusNode();
  final _minuteFocus = FocusNode();
  late final TextEditingController _hourController;
  late final TextEditingController _minuteController;
  late TimeOfDay _time;
  bool _keyboard = false;

  String _digits(int value) => value.toString().padLeft(2, '0');

  @override
  void initState() {
    super.initState();
    _time = widget.initialTime;
    _hourController = TextEditingController(text: _digits(_time.hour));
    _minuteController = TextEditingController(text: _digits(_time.minute));
  }

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    _hourFocus.dispose();
    _minuteFocus.dispose();
    super.dispose();
  }

  bool _readKeyboard() {
    if (!_keyboard) return true;
    if (!_formKey.currentState!.validate()) return false;
    _time = TimeOfDay(
      hour: int.parse(_hourController.text),
      minute: int.parse(_minuteController.text),
    );
    return true;
  }

  void _toggleMode({bool focusField = false, bool minutes = false}) {
    if (!_readKeyboard()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _hourController.text = _digits(_time.hour);
      _minuteController.text = _digits(_time.minute);
      _keyboard = !_keyboard;
    });
    if (_keyboard && focusField) {
      final controller = minutes ? _minuteController : _hourController;
      controller.selection =
          TextSelection(baseOffset: 0, extentOffset: controller.text.length);
      (minutes ? _minuteFocus : _hourFocus).requestFocus();
    }
  }

  void _confirm() {
    if (_readKeyboard()) Navigator.pop(context, _time);
  }

  Widget _timeField({required bool minutes}) {
    final theme = Theme.of(context);
    final pickerTheme = TimePickerTheme.of(context);
    final colors = theme.colorScheme;
    final localizations = MaterialLocalizations.of(context);
    final maximum = minutes ? 59 : 23;
    return Expanded(
      child: TextFormField(
        controller: minutes ? _minuteController : _hourController,
        focusNode: minutes ? _minuteFocus : _hourFocus,
        readOnly: !_keyboard,
        showCursor: _keyboard,
        enableInteractiveSelection: _keyboard,
        keyboardType: TextInputType.number,
        textInputAction: minutes ? TextInputAction.done : TextInputAction.next,
        textAlign: TextAlign.center,
        style:
            (pickerTheme.hourMinuteTextStyle ?? theme.textTheme.displayMedium)
                ?.copyWith(
                    color: pickerTheme.hourMinuteTextColor ??
                        colors.onPrimaryContainer),
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(2),
        ],
        decoration: InputDecoration(
          filled: true,
          fillColor: pickerTheme.hourMinuteColor ?? colors.primaryContainer,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          helperText: minutes
              ? localizations.timePickerMinuteLabel
              : localizations.timePickerHourLabel,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
        ),
        validator: (value) {
          final number = int.tryParse(value ?? '');
          return number == null || number < 0 || number > maximum
              ? '00–$maximum'
              : null;
        },
        onTap: () {
          if (!_keyboard) _toggleMode(focusField: true, minutes: minutes);
        },
        onFieldSubmitted: (_) {
          if (minutes) {
            _confirm();
          } else {
            _minuteFocus.requestFocus();
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pickerTheme = TimePickerTheme.of(context);
    final localizations = MaterialLocalizations.of(context);
    return AlertDialog(
      backgroundColor: pickerTheme.backgroundColor,
      shape: pickerTheme.shape,
      elevation: pickerTheme.elevation,
      scrollable: true,
      title: Row(
        children: [
          Expanded(
            child: Text(
              _keyboard
                  ? localizations.timePickerInputHelpText
                  : localizations.timePickerDialHelpText,
              style: pickerTheme.helpTextStyle ?? theme.textTheme.labelLarge,
            ),
          ),
          const SizedBox(width: 12),
          // Escucha solo la hora: no reconstruye el diálogo al girar las ruedas.
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _hourController,
            builder: (context, value, child) {
              final hour = int.tryParse(value.text);
              final period = hour == null || hour < 0 || hour > 23
                  ? '—'
                  : hour < 12
                      ? 'AM'
                      : 'PM';
              return Semantics(
                label: 'AM/PM',
                value: period,
                liveRegion: true,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRect(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      transitionBuilder: (child, animation) => SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.8),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOutCubic,
                        )),
                        child: FadeTransition(opacity: animation, child: child),
                      ),
                      child: Text(
                        period,
                        key: ValueKey(period),
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.onSecondaryContainer,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      content: SizedBox(
        width: 280,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Form(
              key: _formKey,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _timeField(minutes: false),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(6, 8, 6, 0),
                    child: Text(':', style: theme.textTheme.displayMedium),
                  ),
                  _timeField(minutes: true),
                ],
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) => SizeTransition(
                sizeFactor: animation,
                alignment: Alignment.topCenter,
                child: FadeTransition(opacity: animation, child: child),
              ),
              child: _keyboard
                  ? const SizedBox.shrink(key: ValueKey('keyboard'))
                  : Padding(
                      key: const ValueKey('spinners'),
                      padding: const EdgeInsets.only(top: 16),
                      child: SizedBox(
                        height: 220,
                        child: Row(
                          children: [
                            _TimeWheel(
                              label: localizations.timePickerHourLabel,
                              initialValue: _time.hour,
                              count: 24,
                              onChanged: (hour) {
                                if (_keyboard) return;
                                _time =
                                    TimeOfDay(hour: hour, minute: _time.minute);
                                _hourController.text = _digits(hour);
                              },
                            ),
                            const SizedBox(width: 24),
                            _TimeWheel(
                              label: localizations.timePickerMinuteLabel,
                              initialValue: _time.minute,
                              count: 60,
                              onChanged: (minute) {
                                if (_keyboard) return;
                                _time =
                                    TimeOfDay(hour: _time.hour, minute: minute);
                                _minuteController.text = _digits(minute);
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(12, 0, 20, 12),
      actionsAlignment: MainAxisAlignment.spaceBetween,
      actionsOverflowAlignment: OverflowBarAlignment.end,
      actions: [
        IconButton(
          tooltip: _keyboard
              ? localizations.dialModeButtonLabel
              : localizations.inputTimeModeButtonLabel,
          icon: Icon(_keyboard ? Icons.schedule : Icons.keyboard_outlined),
          onPressed: _toggleMode,
        ),
        TextButton(
          style: pickerTheme.cancelButtonStyle,
          onPressed: () => Navigator.pop(context),
          child: Text(localizations.cancelButtonLabel),
        ),
        TextButton(
          style: pickerTheme.confirmButtonStyle,
          onPressed: _confirm,
          child: Text(localizations.okButtonLabel),
        ),
      ],
    );
  }
}

class _TimeWheel extends StatefulWidget {
  final String label;
  final int initialValue;
  final int count;
  final ValueChanged<int> onChanged;

  const _TimeWheel({
    required this.label,
    required this.initialValue,
    required this.count,
    required this.onChanged,
  });

  @override
  State<_TimeWheel> createState() => _TimeWheelState();
}

class _TimeWheelState extends State<_TimeWheel> {
  late final FixedExtentScrollController _controller;

  @override
  void initState() {
    super.initState();
    _controller = FixedExtentScrollController(initialItem: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Semantics(
        label: widget.label,
        child: RepaintBoundary(
          child: Stack(
            alignment: Alignment.center,
            children: [
              IgnorePointer(
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              ListWheelScrollView.useDelegate(
                controller: _controller,
                itemExtent: 44,
                physics: const FixedExtentScrollPhysics(),
                diameterRatio: 1.5,
                overAndUnderCenterOpacity: 0.45,
                onSelectedItemChanged: widget.onChanged,
                childDelegate: ListWheelChildBuilderDelegate(
                  childCount: widget.count,
                  builder: (context, index) => Center(
                    child: Text(
                      index.toString().padLeft(2, '0'),
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
