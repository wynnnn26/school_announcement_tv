import '../models/announcement.dart';

// Runtime-only "database": a plain List that lives while the app runs.
int _nextId = 100;
int newId() => _nextId++;

final List<Announcement> announcements = [
  // ---- Announcements
  Announcement(
    id: 1, type: 'Announcement', category: 'Important', isFeatured: true,
    title: 'Midterm Examination Week',
    description: 'Examinations will begin on October 6. Review your schedules and prepare early.',
    date: 'October 6, 2026', time: '8:00 AM', location: 'All Classrooms',
  ),
  Announcement(
    id: 2, type: 'Announcement', category: 'General',
    title: 'School ID Reminder',
    description: 'All students are required to wear their school ID inside the campus.',
    date: 'September 30, 2026', location: 'School Gate',
  ),
  Announcement(
    id: 3, type: 'Announcement', category: 'Academic',
    title: 'Enrollment Announcement',
    description: 'Second-quarter enrollment is open. Please visit the registrar for your forms.',
    date: 'October 2, 2026', time: '9:00 AM', location: 'Registrar\'s Office',
  ),
  Announcement(
    id: 4, type: 'Announcement', category: 'Student Affairs',
    title: 'Library Reminder',
    description: 'The library will close one hour early on Fridays for inventory.',
    date: 'October 3, 2026', location: 'School Library',
  ),
  // ---- Events
  Announcement(
    id: 5, type: 'Event', category: 'Event',
    title: 'School Foundation Day',
    description: 'Annual celebration with games, performances and a program.',
    date: 'October 15, 2026', time: '8:00 AM – 4:00 PM', location: 'School Gymnasium',
  ),
  Announcement(
    id: 6, type: 'Event', category: 'Student Affairs',
    title: 'Intramurals',
    description: 'Opening parade and sports competitions between class sections.',
    date: 'October 28, 2026', time: '7:30 AM', location: 'Sports Oval',
  ),
  Announcement(
    id: 7, type: 'Event', category: 'Academic',
    title: 'Student Orientation',
    description: 'Orientation for new students and their parents.',
    date: 'November 3, 2026', time: '1:00 PM', location: 'Auditorium',
  ),
  Announcement(
    id: 8, type: 'Event', category: 'Academic',
    title: 'Recognition Day',
    description: 'Awarding of honor students for the first quarter.',
    date: 'November 12, 2026', time: '2:00 PM', location: 'Auditorium',
  ),
  // ---- Today's schedule
  Announcement(id: 9, type: 'Schedule', title: 'Flag Ceremony', description: 'Morning assembly', time: '08:00 AM', location: 'School Grounds'),
  Announcement(id: 10, type: 'Schedule', title: 'Morning Classes', description: 'Regular classes', time: '09:00 AM', location: 'Classrooms'),
  Announcement(id: 11, type: 'Schedule', title: 'Lunch Break', description: 'Lunch', time: '12:00 PM', location: 'Cafeteria'),
  Announcement(id: 12, type: 'Schedule', title: 'Afternoon Classes', description: 'Regular classes', time: '01:00 PM', location: 'Classrooms'),
  Announcement(id: 13, type: 'Schedule', title: 'End of Classes', description: 'Dismissal', time: '04:30 PM', location: 'School Gate'),
  // ---- Reminders
  Announcement(id: 14, type: 'Reminder', category: 'Reminder', title: 'Submit clearance forms', description: 'Before Friday'),
  Announcement(id: 15, type: 'Reminder', category: 'Reminder', title: 'Bring your school ID', description: 'Required at the gate'),
  Announcement(id: 16, type: 'Reminder', category: 'Reminder', title: 'Return library books', description: 'Due this week'),
  Announcement(id: 17, type: 'Reminder', category: 'Reminder', title: 'Submit requirements', description: 'To your adviser'),
];
