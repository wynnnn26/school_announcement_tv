import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_announcement_tv/main.dart';

// Pretend to be a 1080p TV, start the app.
Future<void> launch(WidgetTester t) async {
  t.view.physicalSize = const Size(1920, 1080);
  t.view.devicePixelRatio = 1;
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
    expect(find.text('MIDTERM EXAMINATION WEEK'), findsOneWidget); // featured
    expect(find.textContaining('Upcoming Events'), findsOneWidget);
    expect(find.text('Today\'s Schedule'), findsOneWidget);
    await close(t);
  });

  testWidgets('empty form shows both validation errors', (t) async {
    await launch(t);
    await t.tap(find.byTooltip('Add announcement'));
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
    expect(find.text('Midterm Examination Week'), findsOneWidget);

    // Search narrows the grid to one record (scope past the text field itself).
    await t.enterText(find.byType(TextField).first, 'Intramurals');
    await t.pumpAndSettle();
    expect(
        find.descendant(of: find.byType(GridView), matching: find.text('Intramurals')),
        findsOneWidget);
    expect(find.text('Midterm Examination Week'), findsNothing);

    // No hit shows the empty-search message instead of an empty grid.
    await t.enterText(find.byType(TextField).first, 'zzz-no-match');
    await t.pumpAndSettle();
    expect(find.text('No records match your search.'), findsOneWidget);
    await close(t);
  });

  testWidgets('valid form adds an item and returns to the display', (t) async {
    await launch(t);
    await t.tap(find.byTooltip('Add announcement'));
    await t.pumpAndSettle();
    final fields = find.byType(TextFormField);
    await t.enterText(fields.at(0), 'Test Notice');
    await t.enterText(fields.at(1), 'Test description');
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
