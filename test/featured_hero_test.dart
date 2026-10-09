import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_announcement_tv/main.dart';
import 'package:school_announcement_tv/widgets/announcement_card.dart';
import 'package:school_announcement_tv/widgets/tv_focus.dart';

// The featured/important notice fills the first screen, the three columns
// start below the fold, and the remote's OK drops the description down
// inside the banner.

const _screenHeight = 540.0; // 1920x1080 at dpr 2 = 960x540 logical

Future<void> launch(WidgetTester t) async {
  t.view.physicalSize = const Size(1920, 1080);
  t.view.devicePixelRatio = 2;
  addTearDown(t.view.reset);
  await t.pumpWidget(const SchoolAnnouncementApp());
  await t.pumpAndSettle(); // let the autofocus land
}

Future<void> close(WidgetTester t) => t.pumpWidget(const SizedBox());

Future<void> press(WidgetTester t, LogicalKeyboardKey key) async {
  await t.sendKeyEvent(key);
  await t.pumpAndSettle();
}

/// True when the focused widget is [target] or inside it (or contains it,
/// when [target] is inside the focused wrapper).
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

bool isFocused(WidgetTester t, Finder target) {
  if (target.evaluate().isEmpty) return false;
  final ctx = FocusManager.instance.primaryFocus?.context;
  if (ctx is! Element) return false;
  final el = t.element(target);
  return el == ctx || _isUnder(el, ctx) || _isUnder(ctx, el);
}

/// Walk down with the D-pad until the notice holds focus.
Future<void> focusHero(WidgetTester t) async {
  final hero = find.byType(FeaturedAnnouncementCard);
  for (var i = 0; i < 10 && !isFocused(t, hero); i++) {
    await press(t, LogicalKeyboardKey.arrowDown);
  }
  expect(isFocused(t, hero), isTrue,
      reason: 'remote could not reach the featured notice');
}

void main() {
  testWidgets('notice fills the first screen, columns below the fold',
      (t) async {
    await launch(t);

    // Measure the focus wrapper: it owns the 4px focus border, so the card
    // inside sits 4px in from the screen edge.
    final hero = t.getRect(find.byKey(const Key('featuredNotice')));
    expect(hero.bottom, closeTo(_screenHeight, 1),
        reason: 'the notice must end exactly at the screen edge');
    expect(hero.height, greaterThan(_screenHeight / 3),
        reason: 'the notice fills most of the visible area');

    // First three dividers = the three section headers, all off screen.
    final panel = t.getRect(find.byType(Divider).at(0));
    expect(panel.top, greaterThanOrEqualTo(_screenHeight),
        reason: 'the columns must start below the fold');
    await close(t);
  });

  testWidgets('OK drops the description down; OK again closes it',
      (t) async {
    await launch(t);

    // Collapsed: the two-line preview only — no time/location row yet.
    expect(find.text('Press OK for details'), findsOneWidget);
    expect(find.text('All Classrooms'), findsNothing);

    await focusHero(t);
    await press(t, LogicalKeyboardKey.select);

    expect(find.text('All Classrooms'), findsOneWidget); // dropdown panel
    expect(find.text('Press OK to close'), findsOneWidget);
    expect(find.text('Press OK for details'), findsNothing);
    // Nothing focusable inside the panel — the remote can't get trapped.
    expect(
        find.descendant(
            of: find.byType(FeaturedAnnouncementCard),
            matching: find.byType(TvFocusable)),
        findsNothing);

    await press(t, LogicalKeyboardKey.select);
    expect(find.text('All Classrooms'), findsNothing);
    expect(find.text('Press OK for details'), findsOneWidget);
    await close(t);
  });
}
