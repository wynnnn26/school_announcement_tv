import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_announcement_tv/main.dart';

// The real-TV bug from the device report: focusing a text field auto-opened
// the on-screen keyboard, which then swallowed every DPAD key. The contract:
// TvFocusable keeps the keyboard closed while the remote navigates, and OK
// opens it on demand. Verified through the text-input channel, because widget
// tests have no real IME to observe.

/// Pumps the app at TV metrics with the text-input channel recorded.
/// Returns the list of method names sent to `SystemChannels.textInput`.
Future<List<String>> launch(WidgetTester t) async {
  t.view.physicalSize = const Size(1920, 1080);
  t.view.devicePixelRatio = 2; // real TV metrics: 960x540 logical
  addTearDown(t.view.reset);

  final calls = <String>[];
  t.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.textInput, (call) async {
    calls.add(call.method);
    return null;
  });
  addTearDown(() => t.binding.defaultBinaryMessenger
      .setMockMethodCallHandler(SystemChannels.textInput, null));

  await t.pumpWidget(const SchoolAnnouncementApp());
  await t.pumpAndSettle();
  return calls;
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

void main() {
  testWidgets('form: keyboard closed on focus, opened only by OK',
      (t) async {
    final calls = await launch(t);

    Future<void> press(LogicalKeyboardKey key) async {
      await t.sendKeyEvent(key);
      await t.pumpAndSettle();
    }

    bool focusIn(Finder f) {
      final ctx = FocusManager.instance.primaryFocus?.context;
      return ctx is Element && _isUnder(t.element(f), ctx);
    }

    // OK on Add opens the form; Type takes focus.
    await press(LogicalKeyboardKey.select);
    expect(find.text('Add Announcement / Event'), findsOneWidget);

    // Down moves Type → Title. EditableText requests the keyboard the
    // moment the field is focused (this is what ate the remote keys on
    // the device), so a show must already be on the channel...
    await press(LogicalKeyboardKey.arrowDown);
    expect(focusIn(find.byType(TextFormField).at(0)), isTrue); // Title
    expect(calls, contains('TextInput.show'),
        reason: 'EditableText asked for the keyboard on focus');
    // ...and TvFocusable's hide must land after it. (EditablesText keeps
    // sending caret updates afterwards; those don't reopen the keyboard.)
    expect(calls.lastIndexOf('TextInput.hide'),
        greaterThan(calls.lastIndexOf('TextInput.show')),
        reason: 'the focused field must not keep the keyboard open');

    // Down still walks the form while the field is focused.
    await press(LogicalKeyboardKey.arrowDown);
    expect(focusIn(find.byType(TextFormField).at(1)), isTrue); // Description
    expect(calls.lastIndexOf('TextInput.hide'),
        greaterThan(calls.lastIndexOf('TextInput.show')),
        reason: 'each newly focused field closes the keyboard too');

    // OK on a text field opens the keyboard for typing.
    await press(LogicalKeyboardKey.select);
    expect(calls.lastIndexOf('TextInput.show'),
        greaterThan(calls.lastIndexOf('TextInput.hide')),
        reason: 'OK opens the keyboard');

    await t.pumpWidget(const SizedBox());
  });

  testWidgets('Manage: search takes focus without opening the keyboard',
      (t) async {
    final calls = await launch(t);

    await t.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await t.pumpAndSettle();
    await t.sendKeyEvent(LogicalKeyboardKey.select);
    await t.pumpAndSettle();

    expect(find.text('Summary / Management'), findsOneWidget);
    final search = find.byType(TextField).first;
    final ctx = FocusManager.instance.primaryFocus?.context;
    final searchEl = t.element(search);
    final searchFocused =
        ctx is Element && (ctx == searchEl || _isUnder(searchEl, ctx));
    expect(searchFocused, isTrue, reason: 'search autofocused');
    expect(calls.lastIndexOf('TextInput.hide'),
        greaterThan(calls.lastIndexOf('TextInput.show')),
        reason: 'opening Manage must not pop the on-screen keyboard');

    await t.pumpWidget(const SizedBox());
  });
}
