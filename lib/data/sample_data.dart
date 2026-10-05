import '../models/announcement.dart';

// Runtime-only "database": a plain List that lives while the app runs.
// loadStore() replaces it with the saved list on restart (see store.dart).
int _nextId = 100;
int newId() => _nextId++;

/// Restored items may already own ids >= 100; keep newId() above them.
void reserveIds(int maxId) {
  if (maxId >= _nextId) _nextId = maxId + 1;
}

// ---- Smart seed dates -------------------------------------------------
// Computed on first run so the demo never goes stale: something fires today,
// something is already past, something is still ahead.
final DateTime _now = DateTime.now();
// Fires ~2 minutes after first launch — the live banner+beep demo. Its date
// is the fire moment's date, so a 23:58 install still matches correctly.
final DateTime _demoFire = _now.add(const Duration(minutes: 2));

String get _today => formatDate(_now);
String _plusDays(int n) => formatDate(_now.add(Duration(days: n)));
String _minusDays(int n) => formatDate(_now.subtract(Duration(days: n)));

final List<Announcement> announcements = [
  // ---- Announcements (4)
  Announcement(
    id: 1, type: 'Announcement', category: 'Important', isFeatured: true,
    title: 'Midterm Examination Week',
    description: 'Examinations begin this week. Review your schedule and prepare early.',
    date: formatDate(_demoFire), time: formatClock(_demoFire),
    location: 'All Classrooms',
  ),
  Announcement(
    id: 2, type: 'Announcement', category: 'General',
    title: 'School ID Reminder',
    description: 'All students are required to wear their school ID inside the campus.',
    date: _minusDays(3), location: 'School Gate',
  ),
  Announcement(
    id: 3, type: 'Announcement', category: 'Academic',
    title: 'Enrollment Announcement',
    description: 'Second-quarter enrollment is open. Please visit the registrar for your forms.',
    date: _plusDays(5), time: '9:00 AM', location: 'Registrar’s Office',
  ),
  Announcement(
    id: 4, type: 'Announcement', category: 'Student Affairs',
    title: 'Library Reminder',
    description: 'Return or renew borrowed books before the midterm break.',
    date: _today, location: 'School Library', // date-only match demo
  ),

  // ---- Events (4)
  Announcement(
    id: 5, type: 'Event', category: 'Event',
    title: 'School Foundation Day',
    description: 'Celebrate the school’s founding anniversary with the whole CHCCI community.',
    date: _plusDays(10), time: '8:00 AM – 4:00 PM', location: 'School Gymnasium',
  ),
  Announcement(
    id: 6, type: 'Event', category: 'Event',
    title: 'Intramurals',
    description: 'Inter-section games begin. Cheer for your section!',
    date: _plusDays(14), time: '7:30 AM', location: 'Sports Oval',
  ),
  Announcement(
    id: 7, type: 'Event', category: 'Academic',
    title: 'Student Orientation',
    description: 'Orientation for new students and transferees of the School of Computer Studies.',
    date: _plusDays(21), time: '1:00 PM', location: 'Auditorium',
  ),
  Announcement(
    id: 8, type: 'Event', category: 'Academic',
    title: 'Recognition Day',
    description: 'Top students and organizations are recognized for the first quarter.',
    date: _plusDays(30), time: '2:00 PM', location: 'Auditorium',
  ),

  // ---- Daily schedule (5) — time-only, so each entry "rings" on the dot
  Announcement(
    id: 9, type: 'Schedule', category: 'General',
    title: 'Flag Ceremony',
    description: 'Face the flag and observe proper decorum.',
    time: '8:00 AM', location: 'School Grounds',
  ),
  Announcement(
    id: 10, type: 'Schedule', category: 'Academic',
    title: 'Morning Classes',
    description: 'First through fourth period classes.',
    time: '9:00 AM', location: 'Classrooms',
  ),
  Announcement(
    id: 11, type: 'Schedule', category: 'General',
    title: 'Lunch Break',
    description: 'Meal break. Observe cleanliness in the cafeteria.',
    time: '12:00 PM', location: 'Cafeteria',
  ),
  Announcement(
    id: 12, type: 'Schedule', category: 'Academic',
    title: 'Afternoon Classes',
    description: 'Fifth through eighth period classes.',
    time: '1:00 PM', location: 'Classrooms',
  ),
  Announcement(
    id: 13, type: 'Schedule', category: 'General',
    title: 'End of Classes',
    description: 'Dismissal. Leave the campus in an orderly manner.',
    time: '4:30 PM', location: 'School Gate',
  ),

  // ---- Reminders (4) — no date/time: shown, never notify
  Announcement(
    id: 14, type: 'Reminder', category: 'Reminder',
    title: 'Submit clearance forms',
    description: 'Clearance for the second quarter — submit before Friday.',
    location: 'Registrar’s Office',
  ),
  Announcement(
    id: 15, type: 'Reminder', category: 'Reminder',
    title: 'Bring your school ID',
    description: 'Required at the gate at all times.',
    location: 'School Gate',
  ),
  Announcement(
    id: 16, type: 'Reminder', category: 'Reminder',
    title: 'Return library books',
    description: 'Avoid overdue fines.',
    location: 'School Library',
  ),
  Announcement(
    id: 17, type: 'Reminder', category: 'Reminder',
    title: 'Submit requirements',
    description: 'Final requirements for CSE101.',
    location: 'To your adviser',
  ),
];
