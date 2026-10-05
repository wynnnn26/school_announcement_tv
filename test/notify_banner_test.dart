import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_announcement_tv/models/announcement.dart';
import 'package:school_announcement_tv/widgets/notify_banner.dart';

Announcement item() => Announcement(
    id: 1,
    type: 'Announcement',
    title: 'Midterm Examination Week',
    description: 'd',
    date: 'October 5, 2026',
    time: '10:30 AM',
    location: 'All Classrooms');

Future<void> pumpBanner(WidgetTester t, {VoidCallback? onDismiss}) async {
  await t.pumpWidget(MaterialApp(
      home: NotifyBanner(item: item(), onDismiss: onDismiss ?? () {})));
  await t.pump(const Duration(milliseconds: 400)); // slide-in finishes
}

void main() {
  testWidgets('banner shows label, title and detail line near the top',
      (t) async {
    await pumpBanner(t);
    expect(find.text('SCHOOL ANNOUNCEMENT'), findsOneWidget);
    expect(find.text('Midterm Examination Week'), findsOneWidget);
    expect(find.text('October 5, 2026 • 10:30 AM • All Classrooms'),
        findsOneWidget);

    final row = t.getRect(find.byType(Row));
    expect(row.top, lessThan(100), reason: 'banner must hug the top edge');
    expect(t.getCenter(find.byType(Row)).dx,
        closeTo(t.getSize(find.byType(MaterialApp)).width / 2, 1),
        reason: 'banner is top-center');
  });

  testWidgets('tapping the banner dismisses it', (t) async {
    var dismissed = false;
    await pumpBanner(t, onDismiss: () => dismissed = true);
    await t.tap(find.text('Midterm Examination Week'));
    await t.pump();
    expect(dismissed, isTrue);
  });

  testWidgets('banner survives an empty location field', (t) async {
    final bare = Announcement(
        id: 2, type: 'Event', title: 'Plain item', description: 'd');
    await t.pumpWidget(
        MaterialApp(home: NotifyBanner(item: bare, onDismiss: () {})));
    await t.pump(const Duration(milliseconds: 400));
    expect(find.text('Plain item'), findsOneWidget);
    expect(
        find.text('SCHOOL ANNOUNCEMENT'), findsOneWidget); // no detail line
  });
}
