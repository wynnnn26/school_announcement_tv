import 'package:flutter/material.dart';
import '../models/announcement.dart';
import 'header_widget.dart';

/// Icon + color for each category (shared by all cards).
/// Red is reserved for urgent/important notices; everything else rides
/// the navy / light-blue brand colors.
(IconData, Color) categoryStyle(String category) => switch (category) {
      'Academic' => (Icons.school, navy),
      'Event' => (Icons.celebration, sky),
      'Reminder' => (Icons.notifications_active, navy),
      'Important' => (Icons.priority_high, Colors.red),
      'Student Affairs' => (Icons.groups, sky),
      _ => (Icons.campaign, navy),
    };

/// Regular announcement card: icon, category, title, description, date.
class AnnouncementCard extends StatelessWidget {
  final Announcement item;
  const AnnouncementCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final (icon, color) = categoryStyle(item.category);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 8),
            Expanded(
              child: Text(item.category.toUpperCase(),
                  overflow: TextOverflow.ellipsis,
                  // navy keeps the label readable on white cards in every category
                  style: const TextStyle(
                      color: navy, fontSize: 20, fontWeight: FontWeight.bold)),
            ),
          ]),
          const SizedBox(height: 8),
          Text(item.title,
              style: const TextStyle(
                  fontSize: 26, fontWeight: FontWeight.bold, color: navy)),
          const SizedBox(height: 4),
          Text(item.description, style: const TextStyle(fontSize: 20)),
          if (item.date.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(item.date,
                style: const TextStyle(fontSize: 20, color: Colors.black54)),
          ],
        ]),
      ),
    );
  }
}

/// The large highlighted card. `tall` = fixed TV height and full-size text.
class FeaturedAnnouncementCard extends StatelessWidget {
  final Announcement? item;
  final bool tall;
  const FeaturedAnnouncementCard(
      {super.key, required this.item, required this.tall});

  @override
  Widget build(BuildContext context) {
    final s = tall ? 1.0 : 0.7; // text scale for small windows
    final a = item;
    // Red gradient is reserved for urgent notices; other featured items use brand navy.
    final important = a?.category == 'Important';
    final accent = important ? Colors.amber : sky;
    final (icon, _) = categoryStyle(a?.category ?? 'General');

    return Container(
      // minHeight, not height: a long description must grow the banner
      // instead of overflowing it (yellow stripes on the TV).
      constraints: tall ? const BoxConstraints(minHeight: 240) : null,
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: important
                ? const [Color(0xFFB71C1C), Color(0xFFE53935)]
                : [navy, const Color(0xFF2E6DB4)]),
        borderRadius: BorderRadius.circular(20),
      ),
      // Stack: red star texture behind urgent notices only, so a regular
      // featured item shows the clean navy → light-blue gradient.
      child: Stack(children: [
        if (important)
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset('assets/images/announcement_placeholder.png',
                  fit: BoxFit.cover),
            ),
          ),
        Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: a == null
                ? Text('No announcements available.',
                    style: TextStyle(color: Colors.white, fontSize: 32 * s))
                : Column(mainAxisSize: MainAxisSize.min, children: [
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(icon, color: accent, size: 30 * s),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                            a.category == 'Important'
                                ? 'IMPORTANT NOTICE'
                                : 'FEATURED ${a.type.toUpperCase()}',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                color: accent,
                                fontSize: 22 * s,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2)),
                      ),
                    ]),
                    Text(a.title.toUpperCase(),
                        maxLines: tall ? 1 : 3,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 46 * s,
                            fontWeight: FontWeight.bold)),
                    Text(a.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style:
                            TextStyle(color: Colors.white, fontSize: 26 * s)),
                    const SizedBox(height: 6),
                    Text(a.date,
                        style: TextStyle(color: accent, fontSize: 22 * s)),
                  ]),
          ),
        ),
      ]),
    );
  }
}
