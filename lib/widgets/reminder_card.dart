import 'package:flutter/material.dart';
import '../models/announcement.dart';

/// Compact bullet list. Wrap flows horizontally on wide screens, and
/// onto new lines on narrow ones.
class ReminderCard extends StatelessWidget {
  final List<Announcement> items;
  const ReminderCard({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 36,
      runSpacing: 6,
      children: items.map((r) => Text('• ${r.title}', style: const TextStyle(fontSize: 22))).toList(),
    );
  }
}
