import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/announcement.dart';
import 'sample_data.dart';

// v2: the featured notice went full-screen + OK dropdown (fresh samples
// reseed once, replacing the earlier test entries on an installed TV).
const storeKey = 'announcements_v2';

/// Restore the saved list, called once from main() before runApp.
/// First run (no key yet) keeps the sample seeds and writes them once, so
/// the seeded dates freeze at install time instead of shifting daily.
/// Any failure leaves the in-memory sample data untouched — the board must
/// open even if preferences are unavailable.
Future<void> loadStore() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(storeKey);
    if (raw == null) {
      await saveStore(); // freeze the first-run seeds
      return;
    }
    final list = (jsonDecode(raw) as List)
        .map((e) => Announcement.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    announcements
      ..clear()
      ..addAll(list);
    if (list.isNotEmpty) {
      reserveIds(list.map((a) => a.id).reduce((a, b) => a > b ? a : b));
    }
  } catch (_) {
    // Unreadable prefs → keep the in-memory sample data.
  }
}

/// Persist the current list, called at every mutation site. Failures are
/// swallowed so a full or denied prefs store never crashes the app.
Future<void> saveStore() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        storeKey, jsonEncode(announcements.map((a) => a.toJson()).toList()));
  } catch (_) {}
}
