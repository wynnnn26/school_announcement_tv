import 'package:flutter_test/flutter_test.dart';
import 'package:school_announcement_tv/data/notify.dart';
import 'package:school_announcement_tv/data/sample_data.dart';
import 'package:school_announcement_tv/main.dart';
import 'package:school_announcement_tv/models/announcement.dart';
import 'package:school_announcement_tv/widgets/notify_banner.dart';

Announcement mk(int id, {String date = '', String time = ''}) => Announcement(
    id: id,
    type: 'Announcement',
    title: 'Item $id',
    description: 'd',
    date: date,
    time: time);

// Fixed clock: Monday, October 5 2026, 10:30 AM.
final now = DateTime(2026, 10, 5, 10, 30);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('dueAt match rules', () {
    test('item dated today notifies once, not again in-session', () {
      final a = mk(1, date: 'October 5, 2026');
      final fired = <String>{};
      expect(dueAt([a], now, fired), [a]);
      expect(dueAt([a], now, fired), isEmpty);
    });

    test('restart re-notifies: a fresh fired set fires again', () {
      final a = mk(1, date: 'October 5, 2026');
      expect(dueAt([a], now, <String>{}), [a]); // new session = new set
    });

    test('past date is silent forever, future date silent until that day',
        () {
      expect(dueAt([mk(1, date: 'October 3, 2026')], now, <String>{}),
          isEmpty);
      expect(dueAt([mk(1, date: 'October 6, 2026')], now, <String>{}),
          isEmpty);
      // ...and then it fires on the day itself.
      final a = mk(1, date: 'October 6, 2026');
      expect(dueAt([a], DateTime(2026, 10, 6, 0, 5), <String>{}), [a]);
    });

    test('undated time fires at its exact minute only', () {
      final a = mk(1, time: '10:30 AM');
      expect(dueAt([a], now, <String>{}), [a]);
      expect(dueAt([mk(2, time: '10:29 AM')], now, <String>{}), isEmpty);
      expect(dueAt([mk(3, time: '10:31 AM')], now, <String>{}), isEmpty);
    });

    test('a minute already passed stays silent', () {
      expect(dueAt([mk(1, time: '9:15 AM')], now, <String>{}), isEmpty);
    });

    test('zero-padded hour matches too', () {
      final at930 = DateTime(2026, 10, 5, 9, 30);
      final a = mk(1, time: '09:30 AM');
      expect(dueAt([a], at930, <String>{}), [a]);
    });

    test('dated item matches date and time as ONE notification', () {
      final a = mk(1, date: 'October 5, 2026', time: '10:30 AM');
      expect(dueAt([a], now, <String>{}), hasLength(1));
    });

    test('dated time only fires on its date — passed date blocks it', () {
      expect(
          dueAt(
              [mk(1, date: 'October 3, 2026', time: '10:30 AM')],
              now,
              <String>{}),
          isEmpty);
      final a = mk(1, date: 'October 5, 2026', time: '10:30 AM');
      expect(dueAt([a], now, <String>{}), [a]);
    });

    test('undated daily time rings again the next day', () {
      final a = mk(1, time: '10:30 AM');
      final fired = <String>{};
      expect(dueAt([a], now, fired), [a]);
      expect(dueAt([a], DateTime(2026, 10, 6, 10, 30), fired), [a]);
    });

    test('date-less and time-less items (reminders) never notify', () {
      expect(dueAt([mk(1)], now, <String>{}), isEmpty);
    });

    test('a time range never time-matches, but its date still does', () {
      final a = mk(1, date: 'October 5, 2026', time: '8:00 AM – 4:00 PM');
      expect(dueAt([a], now, <String>{}), hasLength(1)); // date match only
    });
  });

  testWidgets('service shows a due item as a banner, hides it after 10s',
      (t) async {
    final snapshot = List.of(announcements);
    addTearDown(() {
      announcements
        ..clear()
        ..addAll(snapshot);
    });
    announcements
      ..clear()
      ..add(mk(99, date: formatDate(DateTime.now()))); // due right now

    final svc = NotifyService();
    addTearDown(svc.stop);

    await t.pumpWidget(const SchoolAnnouncementApp());
    svc.start();
    await t.pump(); // postFrame check runs, inserts the entry...
    await t.pump(); // ...which builds on this frame

    expect(find.text('SCHOOL ANNOUNCEMENT'), findsOneWidget);
    expect(
        find.descendant(
            of: find.byType(NotifyBanner), matching: find.text('Item 99')),
        findsOneWidget); // the dashboard card shares the title

    await t.pump(const Duration(seconds: 10));
    await t.pump();
    expect(find.text('SCHOOL ANNOUNCEMENT'), findsNothing);

    svc.stop(); // cancel the 30s tick before the test's timer check
  });
}
