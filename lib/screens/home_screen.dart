import 'package:flutter/material.dart';
import '../data/sample_data.dart';
import '../models/announcement.dart';
import '../widgets/announcement_card.dart';
import '../widgets/event_card.dart';
import '../widgets/header_widget.dart';
import '../widgets/reminder_card.dart';
import '../widgets/schedule_card.dart';
import '../widgets/tv_focus.dart';
import 'announcement_form_screen.dart';
import 'summary_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Announcement> ofType(String t) =>
      announcements.where((a) => a.type == t).toList();

  // Open another screen, then rebuild so any changes show up here.
  Future<void> open(Widget page) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    setState(() {});
  }

  // A titled panel. Content stacks; the page (not the panel) scrolls.
  Widget section(String title, IconData icon, List<Widget> kids, String empty) {
    if (kids.isEmpty) {
      kids = [
        Text(
          empty,
          style: const TextStyle(
            fontSize: 20,
            color: Colors.black54,
          ),
        ),
      ];
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: sky.withValues(alpha: 0.28),
                    borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, size: 26, color: navy),
              ),
              const SizedBox(width: 12),
              // Scale down instead of ellipsizing: a 266px TV panel cannot
              // hold 'Announcements (4)' at 28px, and a truncated title
              // reads like a bug (report §5).
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(title,
                      maxLines: 1,
                      style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: navy)),
                ),
              ),
            ]),
            const Divider(height: 24, color: Color(0xFFD8E6F7)),
            ...kids,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CHCCI • School Announcement TV',
            overflow: TextOverflow.ellipsis),
        actions: [
          Tooltip(
            message: 'Add announcement',
            child: TvFocusable(
              focusable: false,
              onPressed: () => open(const AnnouncementFormScreen()),
              child: TextButton.icon(
                autofocus: true, // the remote starts on Add
                onPressed: () => open(const AnnouncementFormScreen()),
                icon: const Icon(Icons.add_circle, size: 26),
                label: const Text('Add',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                style: TextButton.styleFrom(
                  foregroundColor: navy,
                  backgroundColor: gold,
                  minimumSize: const Size(88, 48),
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Tooltip(
            message: 'Manage announcements',
            child: TvFocusable(
              focusable: false,
              onPressed: () => open(const SummaryScreen()),
              child: TextButton.icon(
                onPressed: () => open(const SummaryScreen()),
                icon: const Icon(Icons.menu, size: 26),
                label: const Text('Manage',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.white.withValues(alpha: 0.14),
                  minimumSize: const Size(116, 48),
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: LayoutBuilder(builder: (context, c) {
        // A 1080p TV at devicePixelRatio 2 is only 960x540 logical, and the
        // body is shorter still (it sits below the AppBar), so measure width
        // only — the wide board scrolls as one page and can never overflow.
        final wide = c.maxWidth >= 900;

        final news = ofType('Announcement');
        final events = ofType('Event');
        final schedule = ofType('Schedule');
        final reminders = ofType('Reminder');
        final featured = announcements.where((a) => a.isFeatured).firstOrNull;

        final header = const HeaderWidget();
        // The big banner only when there is vertical room for it; the TV's
        // short body needs that space for the three-column board below.
        final featuredCard = TvFocusable(
            child: FeaturedAnnouncementCard(
                item: featured, tall: wide && c.maxHeight >= 620));
        final newsSection = section(
            'Announcements (${news.length})',
            Icons.campaign,
            news
                .where((a) => !a.isFeatured)
                .map((a) => TvFocusable(child: AnnouncementCard(item: a)))
                .toList(),
            'No announcements available.');
        final eventSection = section(
            'Upcoming Events (${events.length})',
            Icons.event,
            events
                .map((e) => TvFocusable(child: EventCard(event: e)))
                .toList(),
            'No upcoming events.');
        final scheduleSection = section(
            'Today\'s Schedule',
            Icons.schedule,
            schedule.isEmpty ? [] : [ScheduleCard(items: schedule)],
            'No schedule for today.');
        final reminderSection = section(
            'Reminders (${reminders.length})',
            Icons.notifications_active,
            reminders.isEmpty
                ? []
                : [
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 130),
                      child: SingleChildScrollView(
                          child: ReminderCard(items: reminders)),
                    )
                  ],
            'No reminders.');
        const gap = SizedBox(height: 16);

        if (wide) {
          // One scrollable page: a TV body (540 logical minus the AppBar) is
          // too short for a fixed board, and TvFocusable scrolls the focused
          // card into view. IntrinsicHeight keeps the three panels level.
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  header,
                  gap,
                  featuredCard,
                  gap,
                  IntrinsicHeight(
                    // stretch: all three panels start at the same y (the
                    // default center left them staggered when heights differ).
                    child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(child: newsSection),
                          Expanded(child: eventSection),
                          Expanded(child: scheduleSection),
                        ]),
                  ),
                  reminderSection,
                ]),
          );
        }
        // Narrow or short window: everything stacks and the page scrolls.
        return ListView(padding: const EdgeInsets.all(16), children: [
          header,
          gap,
          featuredCard,
          gap,
          newsSection,
          eventSection,
          scheduleSection,
          reminderSection,
        ]);
      }),
    );
  }
}
