import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_announcement_tv/main.dart';

// Date/Time pickers on the TV remote. The round-2 device report said the
// FIRST activation of the Date/Time field was swallowed and the Date
// picker then died with OutOfMemoryError; every settle here is bounded so
// a stuck dialog fails fast with a stack instead of freezing the suite.

Future<void> settle(WidgetTester t) => t.pumpAndSettle(
      const Duration(milliseconds: 50),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 8),
    );

Future<void> launch(WidgetTester t) async {
  t.view.physicalSize = const Size(1920, 1080);
  t.view.devicePixelRatio = 2; // real TV metrics: 960x540 logical
  addTearDown(t.view.reset);
  await t.pumpWidget(const SchoolAnnouncementApp());
  await settle(t);
}

Future<void> press(WidgetTester t, LogicalKeyboardKey key) async {
  await t.sendKeyEvent(key);
  await settle(t);
}

/// Scope [target] to the dialog currently on screen.
Finder inDialog(Finder target) =>
    find.descendant(of: find.byType(AlertDialog), matching: target);

/// True when [target] contains the primary focus.
bool isFocused(WidgetTester t, Finder target) {
  final ctx = FocusManager.instance.primaryFocus?.context;
  if (ctx is! Element || target.evaluate().isEmpty) return false;
  final el = t.element(target);
  if (el == ctx) return true;
  var found = false;
  ctx.visitAncestorElements((node) {
    if (node == el) {
      found = true;
      return false;
    }
    return true;
  });
  return found;
}

String fieldText(WidgetTester t, Finder field) => t
    .widget<EditableText>(
        find.descendant(of: field, matching: find.byType(EditableText)))
    .controller
    .text;

/// The label of the dropdown menu item that currently has focus.
String? focusedItemText(WidgetTester t) {
  final ctx = FocusManager.instance.primaryFocus?.context;
  if (ctx is! Element) return null;
  String? found;
  void visit(Element e) {
    if (found != null) return;
    final w = e.widget;
    if (w is Text && (w.data ?? '').isNotEmpty) {
      found = w.data;
      return;
    }
    e.visitChildren(visit);
  }

  visit(ctx);
  return found;
}

void main() {
  testWidgets(
      'remote OK on Date: first press opens the picker, February caps at 28',
      (t) async {
    await launch(t);

    // Add → form; Down walks Type → Title → Description → Date.
    await press(t, LogicalKeyboardKey.select);
    expect(find.text('Add Announcement / Event'), findsOneWidget);
    for (var i = 0; i < 3; i++) {
      await press(t, LogicalKeyboardKey.arrowDown);
    }
    final dateField = find.byType(TextFormField).at(2);
    expect(isFocused(t, dateField), isTrue, reason: 'Down lands on Date');

    // The device bug: the FIRST press must already open the picker.
    await press(t, LogicalKeyboardKey.select);
    expect(find.text('Select date'), findsOneWidget,
        reason: 'first press on Date must open the picker');
    final day = inDialog(find.byType(DropdownButtonFormField<String>)).at(0);
    expect(isFocused(t, day), isTrue, reason: 'Day field is focused first');

    // Remote confirms with today's defaults: Day → CANCEL → Right → OK.
    for (var i = 0; i < 3; i++) {
      await press(t, LogicalKeyboardKey.arrowDown);
    }
    await press(t, LogicalKeyboardKey.arrowRight);
    await press(t, LogicalKeyboardKey.select);
    expect(find.text('Select date'), findsNothing);
    final picked = fieldText(t, dateField);
    expect(picked, matches(RegExp(r'^\w+ \d+, \d{4}$')),
        reason: 'date shown in the field');

    // Second press reopens it (the device saw press 1 swallowed, press 2
    // hit the OOM) — walk to February with the remote and check the cap.
    await press(t, LogicalKeyboardKey.select);
    expect(find.text('Select date'), findsOneWidget,
        reason: 'second press opens the picker again');

    // Down: Day → Month; OK opens the Month menu. It opens scrolled to the
    // selected month, so walk up to February instead of tapping.
    await press(t, LogicalKeyboardKey.arrowDown);
    await press(t, LogicalKeyboardKey.select);
    var month = focusedItemText(t);
    for (var i = 0; i < 14 && month != 'February'; i++) {
      await press(t, LogicalKeyboardKey.arrowUp);
      month = focusedItemText(t);
    }
    expect(month, 'February', reason: 'remote reaches February in the menu');
    await press(t, LogicalKeyboardKey.select); // pick February
    await settle(t);

    // The Day field's items are generated from the month length, so the
    // February cap holds without opening the long menu at all.
    final dayButton = t.widget<DropdownButton<String>>(
        find.descendant(of: day, matching: find.byType(DropdownButton<String>)));
    expect(dayButton.items, hasLength(28),
        reason: 'February offers days 1..28 — February 31 is impossible');

    // CANCEL keeps the previously picked date.
    await t.tap(find.text('CANCEL'));
    await settle(t);
    expect(find.text('Select date'), findsNothing);
    expect(fieldText(t, dateField), picked, reason: 'CANCEL changed nothing');

    await t.pumpWidget(const SizedBox());
  });

  testWidgets('first tap on the Date and Time fields opens their pickers',
      (t) async {
    await launch(t);
    await t.tap(find.byTooltip('Add announcement'));
    await settle(t);

    final dateField = find.byType(TextFormField).at(2);
    await t.ensureVisible(dateField);
    await settle(t);
    await t.tap(dateField); // device: first tap did nothing
    await settle(t);
    expect(find.text('Select date'), findsOneWidget,
        reason: 'first tap must open the date picker');
    await t.tap(find.text('CANCEL'));
    await settle(t);

    final timeField = find.byType(TextFormField).at(3);
    await t.ensureVisible(timeField);
    await settle(t);
    await t.tap(timeField);
    await settle(t);
    expect(find.text('Select time'), findsOneWidget,
        reason: 'first tap must open the time picker');
    await t.tap(find.text('CANCEL'));
    await settle(t);

    await t.pumpWidget(const SizedBox());
  });
}
