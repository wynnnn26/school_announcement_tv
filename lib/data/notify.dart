import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/announcement.dart';
import '../widgets/notify_banner.dart';
import 'sample_data.dart';

/// Root navigator key so the banner can overlay ANY screen, not just home.
final GlobalKey<NavigatorState> rootNavKey = GlobalKey<NavigatorState>();

/// Which items are due at [now] — pure, so tests can drive a fake clock.
///
/// Rules (per spec):
/// - dated item: notifies once when its date is today; a past date is silent
///   forever, a future date silent until that day.
/// - time: notifies only at its exact minute (a minute already passed can
///   never equal now). With a date, only on that date; undated, any day.
/// - [fired] holds per-session keys, so each match notifies exactly once in
///   a session; a fresh app start re-notifies (restart re-notify spec).
/// - unparseable date/time (e.g. a range like '8:00 AM – 4:00 PM') never
///   time-matches; time-less/date-less items (reminders) never notify.
List<Announcement> dueAt(
    Iterable<Announcement> items, DateTime now, Set<String> fired) {
  final due = <Announcement>[];
  final seen = <int>{};
  final dayKey = '${now.year}-${now.month}-${now.day}';
  for (final a in items) {
    final d = parseFormatDate(a.date); // null for '' or unparseable text
    final dateMatches = d != null &&
        d.year == now.year &&
        d.month == now.month &&
        d.day == now.day;
    final minutes = timeToMinutes(a.time);
    final timeMatches = minutes != null &&
        (d == null || dateMatches) &&
        minutes == now.hour * 60 + now.minute;

    if (dateMatches &&
        fired.add('${a.id}|date|${a.date}') &&
        seen.add(a.id)) {
      due.add(a);
    }
    // Keyed by day so an undated daily time rings again tomorrow.
    if (timeMatches &&
        fired.add('${a.id}|time|${d == null ? dayKey : a.date}|$minutes') &&
        seen.add(a.id)) {
      due.add(a);
    }
  }
  return due;
}

/// Owns the 30s tick, the session-only fired set and the visible banner.
/// Started once from main(); lives for the process, so no stop() in the app
/// (tests call it to release the periodic timer).
class NotifyService {
  final Set<String> _fired = {};
  final List<Announcement> _pending = [];
  Timer? _tick;
  Timer? _hide;
  OverlayEntry? _banner;

  void start() {
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
    _tick = Timer.periodic(const Duration(seconds: 30), (_) => _check());
  }

  void stop() {
    _tick?.cancel();
    _tick = null;
    _hideNow();
  }

  void _check() {
    final due = dueAt(announcements, DateTime.now(), _fired);
    if (due.isEmpty) return;
    _beep();
    _pending.addAll(due);
    _showNext();
  }

  Future<void> _beep() async {
    try {
      await SystemSound.play(SystemSoundType.alert);
    } catch (_) {
      // No system sound on this device → stay silent, never crash.
      // (Chime asset fallback gets added only if the TV test says silent.)
    }
  }

  void _showNext() {
    if (_banner != null || _pending.isEmpty) return;
    final overlay = rootNavKey.currentState?.overlay;
    if (overlay == null) return; // no frame yet; postFrame check avoids this
    final item = _pending.removeAt(0);
    _banner = OverlayEntry(
        builder: (_) => NotifyBanner(item: item, onDismiss: _hideNow));
    overlay.insert(_banner!);
    _hide = Timer(const Duration(seconds: 10), _hideNow);
  }

  void _hideNow() {
    _hide?.cancel();
    _hide = null;
    _banner?.remove();
    _banner = null;
    _showNext(); // chained items each get their own banner
  }
}
