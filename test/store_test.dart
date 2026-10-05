import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:school_announcement_tv/data/sample_data.dart';
import 'package:school_announcement_tv/data/store.dart';
import 'package:school_announcement_tv/models/announcement.dart';

Announcement mk(int id, {String title = 'T', String date = '', String time = ''}) =>
    Announcement(
        id: id,
        type: 'Announcement',
        title: title,
        description: 'd',
        date: date,
        time: time);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late List<Announcement> snapshot;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    snapshot = List.of(announcements);
  });

  tearDown(() {
    announcements
      ..clear()
      ..addAll(snapshot);
  });

  test('first run seeds the sample list and freezes it into prefs', () async {
    await loadStore();
    expect(announcements, isNotEmpty);
    final prefs = await SharedPreferences.getInstance();
    // Frozen, so the seeded dates don't shift on every later launch.
    expect(prefs.getString(storeKey), isNotNull);
  });

  test('a stored empty list is respected — no reseed', () async {
    SharedPreferences.setMockInitialValues({storeKey: '[]'});
    await loadStore();
    expect(announcements, isEmpty);
  });

  test('saved items are restored with all fields', () async {
    SharedPreferences.setMockInitialValues({
      storeKey: jsonEncode([
        mk(1, title: 'Kept', date: 'October 5, 2026', time: '9:00 AM').toJson()
      ])
    });
    await loadStore();
    expect(announcements, hasLength(1));
    expect(announcements.first.title, 'Kept');
    expect(announcements.first.date, 'October 5, 2026');
    expect(announcements.first.time, '9:00 AM');
    expect(announcements.first.type, 'Announcement');
  });

  test('mutations round-trip through save then load', () async {
    SharedPreferences.setMockInitialValues({storeKey: '[]'});
    await loadStore();
    announcements
      ..clear()
      ..add(mk(1, title: 'Created', date: 'October 5, 2026'))
      ..add(mk(2, title: 'Second'));
    await saveStore();

    announcements.clear(); // simulate app restart
    await loadStore();

    expect(announcements.map((a) => a.title), ['Created', 'Second']);
    expect(announcements.first.date, 'October 5, 2026');
  });

  // Last: reserveIds permanently raises the id counter for this isolate.
  test('restored ids keep newId() out of collision range', () async {
    SharedPreferences.setMockInitialValues(
        {storeKey: jsonEncode([mk(4711).toJson()])});
    await loadStore();
    expect(newId(), greaterThan(4711));
  });
}
