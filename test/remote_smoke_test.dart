import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_announcement_tv/main.dart';

// Bounded remote-only smoke test for the wide TV board (960x540 logical):
// D-pad focus on the dashboard, scroll the page, open the form, walk the
// fields, and go back. No pickers or dialogs — the full flow lives in
// remote_navigation_test.dart (skipped until P3 is diagnosed).

const _gold = Color(0xFFF5B301);

Future<void> press(WidgetTester t, LogicalKeyboardKey key) async {
  await t.sendKeyEvent(key);
  await t.pumpAndSettle();
}

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
/// when [target] is inside the focused wrapper).
bool isFocused(WidgetTester t, Finder target) {
  if (target.evaluate().isEmpty) return false;
  final ctx = FocusManager.instance.primaryFocus?.context;
  if (ctx is! Element) return false;
  final el = t.element(target);
  return el == ctx || _isUnder(el, ctx) || _isUnder(ctx, el);
}

/// The focused control shows the gold focus ring.
bool ringShown(WidgetTester t) =>
    t.widgetList<AnimatedContainer>(find.byType(AnimatedContainer)).any((c) {
      final d = c.decoration;
      return d is BoxDecoration && d.border?.top.color == _gold;
    });

/// Walk focus with one D-pad key until [target] is selected.
Future<void> focusUntil(WidgetTester t, Finder target,
    LogicalKeyboardKey key,
    {int max = 60}) async {
  for (var i = 0; i < max && !isFocused(t, target); i++) {
    await press(t, key);
  }
  expect(target.evaluate().isNotEmpty, isTrue,
      reason: '$target never appeared (not built?)');
  expect(isFocused(t, target), isTrue,
      reason: 'remote could not reach $target');
}

void main() {
  testWidgets(
      'remote smoke: dashboard scroll, open form, walk fields, back',
      (t) async {
    t.view.physicalSize = const Size(1920, 1080);
    t.view.devicePixelRatio = 2; // real TV metrics: 960x540 logical
    addTearDown(t.view.reset);
    await t.pumpWidget(const SchoolAnnouncementApp());
    await t.pumpAndSettle();

    // The remote starts on Add, with a visible ring.
    expect(isFocused(t, find.text('Add')), isTrue);
    expect(ringShown(t), isTrue, reason: 'focused control shows a ring');

    // Down leaves Add for the first board card.
    await press(t, LogicalKeyboardKey.arrowDown);
    expect(isFocused(t, find.text('Add')), isFalse);
    expect(ringShown(t), isTrue, reason: 'ring follows focus onto the board');

    // Walk to the bottom of the wide board: the page must scroll the last
    // reminder into view (the wide layout is one scrollable page).
    await focusUntil(t, find.text('• Submit requirements'),
        LogicalKeyboardKey.arrowDown,
        max: 60);
    final rect = t.getRect(find.text('• Submit requirements'));
    expect(rect.top, greaterThanOrEqualTo(0));
    expect(rect.bottom, lessThanOrEqualTo(540),
        reason: 'bottom content scrolled into view');

    // All the way back up to Add.
    await focusUntil(
        t, find.text('Add'), LogicalKeyboardKey.arrowUp,
        max: 60);

    // OK opens the form; the first control takes focus.
    await press(t, LogicalKeyboardKey.select);
    expect(find.text('Add Announcement / Event'), findsOneWidget);
    expect(
        isFocused(t, find.byType(DropdownButtonFormField<String>).at(0)),
        isTrue);

    // Down walks Type → Title → Description.
    await press(t, LogicalKeyboardKey.arrowDown);
    expect(isFocused(t, find.byType(TextFormField).at(0)), isTrue); // Title
    await press(t, LogicalKeyboardKey.arrowDown);
    expect(isFocused(t, find.byType(TextFormField).at(1)), isTrue); // Description

    // Back (the AppBar button, via OK) returns to the dashboard and the
    // remote still has a focused control.
    await focusUntil(
        t, find.byType(BackButton), LogicalKeyboardKey.arrowUp,
        max: 6);
    await press(t, LogicalKeyboardKey.select);
    expect(find.text('CHCCI • School Announcement TV'), findsOneWidget);
    expect(isFocused(t, find.text('Add')), isTrue,
        reason: 'dashboard regains focus after Back');

    await t.pumpWidget(const SizedBox());
  });
}
