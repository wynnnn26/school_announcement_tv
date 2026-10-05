import 'package:flutter/material.dart';

import '../models/announcement.dart';
import 'header_widget.dart';

/// Top-of-screen notification banner, inserted into the root overlay so it
/// floats above whichever screen is open. Slides down, auto-dismissed by the
/// NotifyService timer, or tap to close.
class NotifyBanner extends StatefulWidget {
  const NotifyBanner({super.key, required this.item, required this.onDismiss});

  final Announcement item;
  final VoidCallback onDismiss;

  @override
  State<NotifyBanner> createState() => _NotifyBannerState();
}

class _NotifyBannerState extends State<NotifyBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 350))
    ..forward();

  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.item;
    final detail =
        [a.date, a.time, a.location].where((s) => s.isNotEmpty).join(' • ');
    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.only(top: 14),
        child: SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero)
              .animate(
                  CurvedAnimation(parent: c, curve: Curves.easeOutCubic)),
          child: FadeTransition(
            opacity: c,
            child: GestureDetector(
              onTap: widget.onDismiss,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 920),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 26, vertical: 14),
                  decoration: BoxDecoration(
                    color: navy,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: gold, width: 2),
                    boxShadow: const [
                      BoxShadow(color: Colors.black54, blurRadius: 16)
                    ],
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.notifications_active,
                        color: gold, size: 30),
                    const SizedBox(width: 14),
                    Flexible(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('SCHOOL ANNOUNCEMENT',
                              style: TextStyle(
                                  color: gold,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 2)),
                          const SizedBox(height: 2),
                          Text(a.title,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold)),
                          if (detail.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(detail,
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 16)),
                          ],
                        ],
                      ),
                    ),
                  ]),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
