import 'package:flutter/material.dart';
import '../models/announcement.dart';
import 'header_widget.dart';

class EventCard extends StatelessWidget {
  final Announcement event;
  const EventCard({super.key, required this.event});

  Widget info(IconData icon, String text) => Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Row(children: [
          Icon(icon, size: 22, color: navy),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 20))),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const CircleAvatar(
              radius: 28,
              backgroundColor: navy,
              child: Icon(Icons.celebration, color: Colors.white, size: 30)),
          const SizedBox(width: 16),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(event.title.toUpperCase(),
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold, color: navy)),
              const SizedBox(height: 4),
              if (event.date.isNotEmpty) info(Icons.calendar_today, event.date),
              if (event.time.isNotEmpty) info(Icons.access_time, event.time),
              if (event.location.isNotEmpty) info(Icons.place, event.location),
            ]),
          ),
        ]),
      ),
    );
  }
}
