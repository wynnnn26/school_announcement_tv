import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_announcement_tv/main.dart';

// Drives the app with remote-control keys only:
// D-pad arrows move focus, `select` is the OK/center button.

const _gold = Color(0xFFF5B301);

Future<void> launch(WidgetTester t) async {
  t.view.physicalSize = const Size(1920, 1080);
  t.view.devicePixelRatio = 2; // real TV metrics: 960x540 logical
  addTearDown(t.view.reset);
  await t.pumpWidget(const SchoolAnnouncementApp());
  await t.pumpAndSettle(); // let the autofocus land
}

Future<void> close(WidgetTester t) => t.pumpWidget(const SizedBox());

Future<void> press(WidgetTester t, LogicalKeyboardKey key) async {
  await t.sendKeyEvent(key);
  await t.pumpAndSettle();
}

Future<void> pressOk(WidgetTester t) => press(t, LogicalKeyboardKey.select);

/// True when [e] is [ancestor] or below it in the element tree.
bool _isUnder(Element ancestor, Element? e) {
  if (e == null) return false;
  if (e == ancestor) return true;
  var found = false;
  e.visitAncestorElements((node) {
    if (node == ancestor) {
      found = true;
      return false;
    }
    return true;
  });
  return found;
}

/// True when the focused widget is [target] or inside it (or contains it,
/// when [target] is inside the focused wrapper). False while [target] is
/// not built yet (lazy list children below the fold).
bool isFocused(WidgetTester t, Finder target) {
  if (target.evaluate().isEmpty) return false;
  final ctx = FocusManager.instance.primaryFocus?.context;
  if (ctx is! Element) return false;
  final el = t.element(target);
  return el == ctx || _isUnder(el, ctx) || _isUnder(ctx, el);
}

/// Scope [target] to the dialog currently on screen.
Finder inDialog(Finder target) => find.descendant(
    of: find.byType(AlertDialog), matching: target);

/// Walk focus with one D-pad key until [target] is selected.
Future<void> focusUntil(WidgetTester t, Finder target,
    LogicalKeyboardKey key,
    {int max = 40}) async {
  for (var i = 0; i < max && !isFocused(t, target); i++) {
    await press(t, key);
  }
  expect(target.evaluate().isNotEmpty, isTrue,
      reason: '$target never appeared (not built?)');
  expect(isFocused(t, target), isTrue,
      reason: 'remote could not reach $target');
}

/// The focused control shows the gold focus ring.
bool ringShown(WidgetTester t) =>
    t.widgetList<AnimatedContainer>(find.byType(AnimatedContainer)).any((c) {
      final d = c.decoration;
      return d is BoxDecoration && d.border?.top.color == _gold;
    });

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

/// Current text inside form field # [i].
String fieldText(WidgetTester t, int i) => t
    .widget<EditableText>(find.descendant(
        of: find.byType(TextFormField).at(i),
        matching: find.byType(EditableText)))
    .controller
    .text;

void main() {
  testWidgets(
      'remote only: dashboard → add → date/time → save → manage → '
      'edit → delete → back', (t) async {
    await launch(t);

    // ---- Dashboard: focus starts on Add, with a visible ring.
    expect(isFocused(t, find.text('Add')), isTrue);
    expect(ringShown(t), isTrue, reason: 'focused control shows a ring');

    // D-pad down walks to the very bottom of the board, and back up.
    await focusUntil(t, find.text('• Submit requirements'),
        LogicalKeyboardKey.arrowDown,
        max: 60);
    await focusUntil(
        t, find.text('Add'), LogicalKeyboardKey.arrowUp,
        max: 60);

    // ---- Add: OK opens the form, the first control takes focus.
    await pressOk(t);
    expect(find.text('Add Announcement / Event'), findsOneWidget);
    expect(
        isFocused(t, find.byType(DropdownButtonFormField<String>).at(0)), isTrue);

    // Down moves Type → Title; the keyboard types into the focused field.
    await press(t, LogicalKeyboardKey.arrowDown);
    expect(isFocused(t, find.byType(TextFormField).at(0)), isTrue); // Title
    await t.enterText(find.byType(TextFormField).at(0), 'Remote Test Event');
    await t.pumpAndSettle();

    // Down advances Title → Description (OK now opens the keyboard instead
    // of moving on — see usesTextInput).
    await press(t, LogicalKeyboardKey.arrowDown);
    expect(isFocused(t, find.byType(TextFormField).at(1)), isTrue); // Description
    await t.enterText(
        find.byType(TextFormField).at(1), 'Driven by the TV remote only');
    await t.pumpAndSettle();

    // Down to Date.
    await press(t, LogicalKeyboardKey.arrowDown);
    expect(isFocused(t, find.byType(TextFormField).at(2)), isTrue); // Date

    // ---- Date: OK opens the TV date picker; the Day field takes focus.
    await pressOk(t);
    expect(find.text('Select date'), findsOneWidget);
    expect(
        isFocused(
            t, inDialog(find.byType(DropdownButtonFormField<String>)).at(0)),
        isTrue,
        reason: 'Day field is focused first');

    // Down: Day → Month; OK opens the Month menu (starts on the current
    // month). Walk up to January, then one down to February.
    await press(t, LogicalKeyboardKey.arrowDown);
    expect(
        isFocused(
            t, inDialog(find.byType(DropdownButtonFormField<String>)).at(1)),
        isTrue,
        reason: 'Down moves Day → Month');
    await pressOk(t);
    var month = focusedItemText(t);
    for (var i = 0; i < 14 && month != 'January'; i++) {
      await press(t, LogicalKeyboardKey.arrowUp);
      month = focusedItemText(t);
    }
    expect(month, 'January', reason: 'remote reaches the top of the menu');
    await press(t, LogicalKeyboardKey.arrowDown);
    expect(focusedItemText(t), 'February');
    await pressOk(t); // pick February
    expect(
        isFocused(
            t, inDialog(find.byType(DropdownButtonFormField<String>)).at(1)),
        isTrue,
        reason: 'focus returns to the Month field');

    // Up back to Day, open its menu and walk to the bottom: February only
    // offers its real days, so day 29-31 (February 31) cannot be selected.
    await press(t, LogicalKeyboardKey.arrowUp);
    await pressOk(t);
    var day = focusedItemText(t);
    String? prev;
    for (var i = 0; i < 40 && day != prev; i++) {
      prev = day;
      await press(t, LogicalKeyboardKey.arrowDown);
      day = focusedItemText(t);
    }
    expect(day, '28',
        reason: 'the February Day menu ends at 28 — February 31 is impossible');
    await pressOk(t); // pick the focused day
    expect(
        isFocused(
            t, inDialog(find.byType(DropdownButtonFormField<String>)).at(0)),
        isTrue,
        reason: 'focus returns to the Day field');

    // Down: Month → Year → CANCEL, Right to OK, OK confirms.
    for (var i = 0; i < 3; i++) {
      await press(t, LogicalKeyboardKey.arrowDown);
    }
    expect(isFocused(t, inDialog(find.text('CANCEL'))), isTrue);
    await press(t, LogicalKeyboardKey.arrowRight);
    expect(isFocused(t, inDialog(find.text('OK'))), isTrue);
    await pressOk(t);
    expect(find.text('Select date'), findsNothing);
    expect(fieldText(t, 2), matches(RegExp(r'^\w+ \d+, \d{4}$')),
        reason: 'date shown in the field');
    expect(isFocused(t, find.byType(TextFormField).at(2)), isTrue,
        reason: 'focus returns to the form');

    // ---- Time: same flow through the TV time picker.
    await press(t, LogicalKeyboardKey.arrowDown);
    expect(isFocused(t, find.byType(TextFormField).at(3)), isTrue); // Time
    await pressOk(t);
    expect(find.text('Select time'), findsOneWidget);
    expect(
        isFocused(
            t, inDialog(find.byType(DropdownButtonFormField<String>)).at(0)),
        isTrue,
        reason: 'Hour field is focused first');

    // Down to Minute, change it through its menu.
    await press(t, LogicalKeyboardKey.arrowDown);
    expect(
        isFocused(
            t, inDialog(find.byType(DropdownButtonFormField<String>)).at(1)),
        isTrue);
    await pressOk(t); // open the Minute menu
    expect(
        isFocused(
            t, inDialog(find.byType(DropdownButtonFormField<String>)).at(1)),
        isFalse,
        reason: 'Minute menu took focus');
    await press(t, LogicalKeyboardKey.arrowDown);
    await pressOk(t); // pick a minute
    expect(
        isFocused(
            t, inDialog(find.byType(DropdownButtonFormField<String>)).at(1)),
        isTrue,
        reason: 'focus returns to the Minute field');

    // Down: AM/PM → CANCEL, Right to OK, OK confirms.
    await press(t, LogicalKeyboardKey.arrowDown);
    await press(t, LogicalKeyboardKey.arrowDown);
    expect(isFocused(t, inDialog(find.text('CANCEL'))), isTrue);
    await press(t, LogicalKeyboardKey.arrowRight);
    expect(isFocused(t, inDialog(find.text('OK'))), isTrue);
    await pressOk(t);
    expect(find.text('Select time'), findsNothing);
    expect(fieldText(t, 3), matches(RegExp(r'^\d{1,2}:\d{2} [AP]M$')),
        reason: 'time shown in the field');
    expect(isFocused(t, find.byType(TextFormField).at(3)), isTrue);

    // ---- Last field, then Down to the Add (submit) button.
    await press(t, LogicalKeyboardKey.arrowDown);
    expect(isFocused(t, find.byType(TextFormField).at(4)), isTrue); // Location
    await t.enterText(find.byType(TextFormField).at(4), 'TV Studio');
    await t.pumpAndSettle();
    await focusUntil(
        t, find.byKey(const Key('submitButton')), LogicalKeyboardKey.arrowDown,
        max: 8);
    await pressOk(t);
    expect(find.text('Announcement added successfully!'), findsOneWidget);
    expect(find.text('Add Announcement / Event'), findsNothing);
    expect(isFocused(t, find.text('Add')), isTrue, // back on the dashboard
        reason: 'focus returns to Add after saving');

    // ---- Manage: Right to Manage, OK opens it, search takes focus.
    await focusUntil(
        t, find.byTooltip('Manage announcements'), LogicalKeyboardKey.arrowRight,
        max: 4);
    await pressOk(t);
    expect(find.text('Summary / Management'), findsOneWidget);
    expect(isFocused(t, find.byType(TextField)), isTrue);

    // Filter with the keyboard so the new record is the only one in the grid.
    await t.enterText(find.byType(TextField), 'Remote Test Event');
    await t.pumpAndSettle();
    expect(
        find.descendant(
            of: find.byType(GridView), matching: find.text('Remote Test Event')),
        findsOneWidget);

    // ---- Edit: Down to View, Right to Edit, OK opens the form.
    await focusUntil(t, find.text('View'), LogicalKeyboardKey.arrowDown, max: 8);
    await press(t, LogicalKeyboardKey.arrowRight);
    expect(isFocused(t, find.text('Edit')), isTrue);
    await pressOk(t);
    expect(find.text('Edit Announcement'), findsOneWidget);
    expect(fieldText(t, 0), 'Remote Test Event', reason: 'record prefilled');

    // Update the title remotely and save.
    await press(t, LogicalKeyboardKey.arrowDown);
    expect(isFocused(t, find.byType(TextFormField).at(0)), isTrue);
    await t.enterText(find.byType(TextFormField).at(0), 'Remote Test Event v2');
    await t.pumpAndSettle();
    await focusUntil(
        t, find.byKey(const Key('submitButton')), LogicalKeyboardKey.arrowDown,
        max: 10);
    await pressOk(t);
    expect(find.text('Announcement updated successfully!'), findsOneWidget);
    expect(
        find.descendant(
            of: find.byType(GridView),
            matching: find.text('Remote Test Event v2')),
        findsOneWidget);
    expect(isFocused(t, find.text('Edit')), isTrue,
        reason: 'focus returns to Edit after saving');

    // ---- Delete: Right to Delete, OK, confirm in the dialog.
    await press(t, LogicalKeyboardKey.arrowRight);
    expect(isFocused(t, find.text('Delete')), isTrue);
    await pressOk(t);
    expect(find.text('Delete Announcement?'), findsOneWidget);
    expect(isFocused(t, find.text('CANCEL')), isTrue,
        reason: 'dialog starts on the safe choice');
    await press(t, LogicalKeyboardKey.arrowRight);
    expect(isFocused(t, find.text('DELETE')), isTrue);
    // Confirming works with the Enter key as well as OK/Select.
    await t.sendKeyEvent(LogicalKeyboardKey.enter);
    await t.pumpAndSettle();
    // ScaffoldMessenger queues snackbars: the update snackbar from a few
    // presses ago is still on its 4s timer — let it expire so ours shows.
    await t.pump(const Duration(seconds: 5));
    await t.pumpAndSettle();
    expect(find.text('Announcement deleted.'), findsOneWidget);
    expect(find.text('No records match your search.'), findsOneWidget);
    expect(isFocused(t, find.byType(TextField)), isTrue,
        reason: 'focus parks on search after the record is gone');

    // ---- Back to the dashboard.
    await focusUntil(
        t, find.byType(BackButton), LogicalKeyboardKey.arrowUp,
        max: 6);
    await pressOk(t);
    expect(find.text('CHCCI • School Announcement TV'), findsOneWidget);
    expect(isFocused(t, find.byTooltip('Manage announcements')), isTrue);

    await close(t);
  });

  testWidgets('remote scrolls the narrow dashboard to the bottom and back',
      (t) async {
    t.view.physicalSize = const Size(540, 960);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(const SchoolAnnouncementApp());
    await t.pumpAndSettle();

    expect(isFocused(t, find.text('Add')), isTrue);

    // Walk down to the last reminder; the page must scroll it into view.
    await focusUntil(t, find.text('• Submit requirements'),
        LogicalKeyboardKey.arrowDown,
        max: 80);
    final rect = t.getRect(find.text('• Submit requirements'));
    expect(rect.top, greaterThanOrEqualTo(0));
    expect(rect.bottom, lessThanOrEqualTo(960),
        reason: 'bottom content scrolled into view');

    // And all the way back up to Add.
    await focusUntil(
        t, find.text('Add'), LogicalKeyboardKey.arrowUp,
        max: 80);
    await close(t);
  });
}
