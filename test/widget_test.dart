import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_announcement_tv/main.dart';

// Pretend to be a 1080p TV: 1920x1080 physical at dpr 2 = 960x540 logical,
// which is what an actual TV reports (dpr 1 would hide layout bugs).
Future<void> launch(WidgetTester t) async {
  t.view.physicalSize = const Size(1920, 1080);
  t.view.devicePixelRatio = 2;
  addTearDown(t.view.reset);
  await t.pumpWidget(const SchoolAnnouncementApp());
}

// Unmount the app so the header's clock timer is cancelled.
Future<void> close(WidgetTester t) => t.pumpWidget(const SizedBox());

void main() {
  testWidgets('TV display shows the main sections', (t) async {
    await launch(t);
    expect(find.text('SCHOOL ANNOUNCEMENT BOARD'), findsOneWidget);
    expect(find.text('CHCCI • School Announcement TV'), findsOneWidget); // AppBar branding
    expect(find.text('School of Computer Studies'), findsOneWidget); // header branding
    expect(find.text('FINAL EXAMINATION WEEK'), findsOneWidget); // featured
    expect(find.textContaining('Upcoming Events'), findsOneWidget);
    expect(find.text('Today\'s Schedule'), findsOneWidget);
    await close(t);
  });

  testWidgets('empty form shows both validation errors', (t) async {
    await launch(t);
    await t.tap(find.byTooltip('Add announcement'));
    await t.pumpAndSettle();
    // The button sits below the fold on a short TV viewport (960x540).
    await t.ensureVisible(find.byKey(const Key('submitButton')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('submitButton')));
    await t.pumpAndSettle();
    expect(find.text('Please enter a title.'), findsOneWidget);
    expect(find.text('Please enter a description.'), findsOneWidget);
    await close(t);
  });

  testWidgets('management screen searches and filters records', (t) async {
    await launch(t);
    await t.tap(find.byTooltip('Manage announcements'));
    await t.pumpAndSettle();
    expect(find.text('Final Examination Week'), findsOneWidget);

    // Search narrows the grid to one record (scope past the text field itself).
    await t.enterText(find.byType(TextField).first, 'Inter-Section Quiz Bee');
    await t.pumpAndSettle();
    expect(
        find.descendant(
            of: find.byType(GridView), matching: find.text('Inter-Section Quiz Bee')),
        findsOneWidget);
    expect(find.text('Final Examination Week'), findsNothing);

    // No hit shows the empty-search message instead of an empty grid.
    await t.enterText(find.byType(TextField).first, 'zzz-no-match');
    await t.pumpAndSettle();
    expect(find.text('No records match your search.'), findsOneWidget);
    await close(t);
  });

  testWidgets('the three board panels are level', (t) async {
    await launch(t);
    await t.pump();
    // Every section card carries a divider under its title; with the board
    // Row stretched, all three panels must start at exactly the same y
    // (the old default alignment left them staggered — report §5).
    final dividers = find.byType(Divider);
    final tops = [0, 1, 2].map((i) => t.getRect(dividers.at(i)).top).toList();
    expect(tops[0], tops[1], reason: 'news and events panels are level');
    expect(tops[1], tops[2], reason: 'events and schedule panels are level');
    await close(t);
  });

  testWidgets('valid form adds an item and returns to the display', (t) async {
    await launch(t);
    await t.tap(find.byTooltip('Add announcement'));
    await t.pumpAndSettle();
    final fields = find.byType(TextFormField);
    await t.enterText(fields.at(0), 'Test Notice');
    await t.enterText(fields.at(1), 'Test description');
    // Let the focused field's scroll-into-view land first, or it fires
    // during the pump below and yanks the page back off the button.
    await t.pumpAndSettle();
    await t.ensureVisible(find.byKey(const Key('submitButton')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('submitButton')));
    await t.pumpAndSettle();
    expect(find.text('Announcement added successfully!'), findsOneWidget);

    // The announcements panel scrolls; bring the new item into view first.
    await t.scrollUntilVisible(
      find.text('Test Notice'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Test Notice'), findsOneWidget);
    await close(t);
  });
}
