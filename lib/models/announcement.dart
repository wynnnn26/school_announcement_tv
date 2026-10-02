// One item on the board: an announcement, event, reminder or schedule entry.
class Announcement {
  final int id;
  final String type; // one of [itemTypes]
  final String title;
  final String description;
  final String date;
  final String time;
  final String location;
  final String category; // one of [categories]
  bool isFeatured; // the big card on the TV display

  Announcement({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    this.date = '',
    this.time = '',
    this.location = '',
    this.category = 'General',
    this.isFeatured = false,
  });
}

const itemTypes = ['Announcement', 'Event', 'Reminder', 'Schedule'];
const categories = [
  'General', 'Academic', 'Event', 'Reminder', 'Important', 'Student Affairs'
];

const monthNames = [
  'January', 'February', 'March', 'April', 'May', 'June', 'July',
  'August', 'September', 'October', 'November', 'December'
];

String formatDate(DateTime d) => '${monthNames[d.month - 1]} ${d.day}, ${d.year}';

/// Reverse of [formatDate] for 'Month D, YYYY' text; null when unparseable.
DateTime? parseFormatDate(String s) {
  final m = RegExp(r'^(\w+) (\d+), (\d+)$').firstMatch(s.trim());
  if (m == null) return null;
  final month = monthNames.indexOf(m.group(1)!);
  if (month == -1) return null;
  return DateTime(int.parse(m.group(3)!), month + 1, int.parse(m.group(2)!));
}
