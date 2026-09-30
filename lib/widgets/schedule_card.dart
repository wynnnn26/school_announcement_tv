import 'package:flutter/material.dart';
import '../models/announcement.dart';
import 'header_widget.dart';

/// Row-based schedule: time (highlighted) | activity + location.
class ScheduleCard extends StatelessWidget {
  final List<Announcement> items;
  const ScheduleCard({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: items.map((s) {
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFE9F2FD), // light-blue row tint from the logo
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(children: [
            Container(
              width: 110,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                  color: navy, borderRadius: BorderRadius.circular(8)),
              child: Text(s.time.isEmpty ? '—' : s.time,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.title,
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold)),
                    if (s.location.isNotEmpty)
                      Text(s.location,
                          style: const TextStyle(
                              fontSize: 18, color: Colors.black54)),
                  ]),
            ),
          ]),
        );
      }).toList(),
    );
  }
}
