import 'package:agro_aplicaciones/shared/widgets/spinner_time_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> openPicker(WidgetTester tester,
      {required ValueChanged<TimeOfDay?> onResult,
      TimeOfDay initial = const TimeOfDay(hour: 23, minute: 59),
      Brightness brightness = Brightness.light,
      Locale locale = const Locale('en')}) async {
    await tester.pumpWidget(MaterialApp(
      locale: locale,
      supportedLocales: const [Locale('en'), Locale('es')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: ThemeData(brightness: brightness),
      home: Scaffold(
        body: Builder(builder: (context) {
          return TextButton(
            onPressed: () async => onResult(await showSpinnerTimePicker(
                context: context, initialTime: initial)),
            child: const Text('Open'),
          );
        }),
      ),
    ));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
  }

  List<String> fields(WidgetTester tester) => tester
      .widgetList<TextFormField>(find.byType(TextFormField))
      .map((field) => field.controller!.text)
      .toList();

  testWidgets('AM/PM follows wheels and keyboard without changing 24-hour time',
      (tester) async {
    await openPicker(tester,
        initial: const TimeOfDay(hour: 11, minute: 30), onResult: (_) {});
    expect(find.text('AM'), findsOneWidget);
    final hourWheel = tester
        .widget<ListWheelScrollView>(find.byType(ListWheelScrollView).first);
    (hourWheel.controller! as FixedExtentScrollController).jumpToItem(12);
    await tester.pumpAndSettle();
    expect(find.text('PM'), findsOneWidget);
    expect(fields(tester).first, '12');
    await tester.tap(find.byIcon(Icons.keyboard_outlined));
    await tester.pumpAndSettle();
    expect(tester.testTextInput.isVisible, isFalse);
    for (final entry in {
      '00': 'AM',
      '11': 'AM',
      '12': 'PM',
      '23': 'PM',
      '24': '—',
      '': '—'
    }.entries) {
      await tester.enterText(find.byType(TextFormField).first, entry.key);
      await tester.pumpAndSettle();
      expect(find.text(entry.value), findsOneWidget);
    }
    await tester.enterText(find.byType(TextFormField).first, '00');
    await tester.tap(find.byIcon(Icons.schedule));
    await tester.pumpAndSettle();
    expect(find.text('AM'), findsOneWidget);
    expect(fields(tester), ['00', '30']);
  });

  testWidgets('initial time and confirmation preserve 24-hour values',
      (tester) async {
    TimeOfDay? result;
    await openPicker(tester, onResult: (value) => result = value);
    expect(fields(tester), ['23', '59']);
    final wheels = tester
        .widgetList<ListWheelScrollView>(find.byType(ListWheelScrollView));
    expect(
        wheels.map((wheel) =>
            (wheel.controller! as FixedExtentScrollController).selectedItem),
        [23, 59]);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(result, const TimeOfDay(hour: 23, minute: 59));
  });

  testWidgets('keyboard and wheels synchronize in both directions',
      (tester) async {
    TimeOfDay? result;
    await openPicker(tester, onResult: (value) => result = value);
    await tester.tap(find.byIcon(Icons.keyboard_outlined));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), '00');
    await tester.enterText(find.byType(TextFormField).at(1), '07');
    await tester.tap(find.byIcon(Icons.schedule));
    await tester.pumpAndSettle();
    final wheels = tester
        .widgetList<ListWheelScrollView>(find.byType(ListWheelScrollView))
        .toList();
    expect(
        wheels.map((wheel) =>
            (wheel.controller! as FixedExtentScrollController).selectedItem),
        [0, 7]);
    await tester.drag(
        find.byType(ListWheelScrollView).first, const Offset(0, -88));
    await tester.pumpAndSettle();
    final selectedHour =
        (wheels.first.controller! as FixedExtentScrollController).selectedItem;
    expect(selectedHour, greaterThan(0));
    // Scrolling updates the field without rebuilding either wheel.
    expect(tester.widget(find.byType(ListWheelScrollView).first),
        same(wheels.first));
    expect(fields(tester).first, selectedHour.toString().padLeft(2, '0'));
    await tester.tap(find.byIcon(Icons.keyboard_outlined));
    await tester.pumpAndSettle();
    expect(fields(tester), [selectedHour.toString().padLeft(2, '0'), '07']);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(result, TimeOfDay(hour: selectedHour, minute: 7));
  });

  testWidgets(
      'invalid and empty input cannot confirm or switch; cancel returns null',
      (tester) async {
    var completed = false;
    TimeOfDay? result = const TimeOfDay(hour: 1, minute: 1);
    await openPicker(tester, onResult: (value) {
      completed = true;
      result = value;
    });
    await tester.tap(find.byIcon(Icons.keyboard_outlined));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), '24');
    await tester.enterText(find.byType(TextFormField).at(1), '60');
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(completed, isFalse);
    expect(find.text('00–23'), findsOneWidget);
    expect(find.text('00–59'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).at(0), '');
    await tester.tap(find.byIcon(Icons.schedule));
    await tester.pumpAndSettle();
    expect(find.byType(ListWheelScrollView), findsNothing);
    final cancelLabel = MaterialLocalizations.of(
      tester.element(find.byType(AlertDialog)),
    ).cancelButtonLabel;
    await tester.tap(find.text(cancelLabel));
    await tester.pumpAndSettle();
    expect(completed, isTrue);
    expect(result, isNull);
  });

  testWidgets('dark theme and compact screen support keyboard and dismissal',
      (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var completed = false;
    await openPicker(tester,
        brightness: Brightness.dark,
        locale: const Locale('es'), onResult: (value) {
      completed = true;
      expect(value, isNull);
    });
    expect(tester.takeException(), isNull);
    final localizations =
        MaterialLocalizations.of(tester.element(find.byType(AlertDialog)));
    for (final label in [
      localizations.cancelButtonLabel,
      localizations.okButtonLabel
    ]) {
      final text = find.text(label);
      expect(text, findsOneWidget);
      expect(tester.getSize(text).height, lessThan(30));
      expect(
          tester
              .getRect(find.byType(AlertDialog))
              .contains(tester.getRect(text).bottomRight),
          isTrue);
    }
    await tester.tap(find.byIcon(Icons.keyboard_outlined));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tapAt(const Offset(2, 2));
    await tester.pumpAndSettle();
    expect(completed, isTrue);
  });

  testWidgets(
      'mode transition keeps mobile keyboard closed until a field is tapped',
      (tester) async {
    await openPicker(tester, onResult: (_) {});
    expect(tester.testTextInput.isVisible, isFalse);
    await tester.tap(find.byIcon(Icons.keyboard_outlined));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    expect(tester.hasRunningAnimations, isTrue);
    expect(tester.testTextInput.isVisible, isFalse);
    await tester.pumpAndSettle();
    expect(tester.testTextInput.isVisible, isFalse);
    await tester.tap(find.byType(TextFormField).at(1));
    await tester.pumpAndSettle();
    expect(tester.testTextInput.isVisible, isTrue);
    await tester.tap(find.byIcon(Icons.schedule));
    await tester.pumpAndSettle();
    expect(tester.testTextInput.isVisible, isFalse);
    await tester.tap(find.byIcon(Icons.keyboard_outlined));
    await tester.pumpAndSettle();
    expect(tester.testTextInput.isVisible, isFalse);
  });
}
