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

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'title': title,
        'description': description,
        'date': date,
        'time': time,
        'location': location,
        'category': category,
        'isFeatured': isFeatured,
      };

  factory Announcement.fromJson(Map<String, dynamic> j) => Announcement(
        id: j['id'] as int,
        type: j['type'] as String,
        title: j['title'] as String,
        description: j['description'] as String,
        date: j['date'] as String? ?? '',
        time: j['time'] as String? ?? '',
        location: j['location'] as String? ?? '',
        category: j['category'] as String? ?? 'General',
        isFeatured: j['isFeatured'] as bool? ?? false,
      );
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

/// '9:46 PM' (or '09:46 PM') → minutes since midnight.
/// Null when unparseable — e.g. a range like '8:00 AM – 4:00 PM'.
int? timeToMinutes(String s) {
  final m = RegExp(r'^(\d{1,2}):(\d{2})\s*([AP]M)$').firstMatch(s.trim());
  if (m == null) return null;
  final h = int.parse(m.group(1)!);
  if (h < 1 || h > 12) return null;
  return (h % 12 + (m.group(3) == 'PM' ? 12 : 0)) * 60 + int.parse(m.group(2)!);
}

/// Reverse of [TimeOfDay.format] for this app's locale: '6:41 PM'.
String formatClock(DateTime t) {
  final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
  final m = t.minute.toString().padLeft(2, '0');
  return '$h:$m ${t.hour >= 12 ? 'PM' : 'AM'}';
}
