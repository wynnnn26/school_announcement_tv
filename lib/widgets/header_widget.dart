import 'dart:async';
import 'package:flutter/material.dart';
import '../models/announcement.dart';

const navy = Color(0xFF12305B);
const gold = Color(0xFFF5B301);
const sky = Color(0xFF8CC0EE); // light blue from the seal

/// TV header: logo + school name | board title | live date and time.
/// It is its own StatefulWidget so only the header rebuilds every second.
class HeaderWidget extends StatefulWidget {
  const HeaderWidget({super.key});

  @override
  State<HeaderWidget> createState() => _HeaderWidgetState();
}

class _HeaderWidgetState extends State<HeaderWidget> {
  DateTime now = DateTime.now();
  Timer? timer;

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(seconds: 1),
        (_) => setState(() => now = DateTime.now()));
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  String get clock {
    final h = now.hour % 12 == 0 ? 12 : now.hour % 12;
    final m = now.minute.toString().padLeft(2, '0');
    return '$h:$m ${now.hour < 12 ? 'AM' : 'PM'}';
  }

  @override
  Widget build(BuildContext context) {
    final left = Row(mainAxisSize: MainAxisSize.min, children: [
      Image.asset('assets/images/school_logo.png', height: 72),
      const SizedBox(width: 14),
      // School identity lives in the AppBar once; here it is the full name only.
      const Flexible(
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('School of Computer Studies',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold)),
              SizedBox(height: 2),
              Text('Concepcion Holy Cross College Inc.',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: gold, fontSize: 16)),
            ]),
      ),
    ]);

    final center = const FittedBox(
      fit: BoxFit.scaleDown,
      child: Column(children: [
        Text('SCHOOL ANNOUNCEMENT BOARD',
            style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5)),
        Text('Official School Information Display',
            style: TextStyle(color: sky, fontSize: 20)),
      ]),
    );

    final right = FittedBox(
      fit: BoxFit.scaleDown,
      child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Text(formatDate(now),
            style: const TextStyle(color: Colors.white, fontSize: 22)),
        Text(clock,
            style: const TextStyle(
                color: gold, fontSize: 40, fontWeight: FontWeight.bold)),
      ]),
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: navy,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: sky.withValues(alpha: 0.35), width: 2),
      ),
      child: LayoutBuilder(builder: (context, c) {
        // 800, not 900: on a 960-wide TV the header's inner width is only
        // ~888 after padding, and a 900 threshold made it stack.
        if (c.maxWidth >= 800) {
          return Row(children: [
            Expanded(
                flex: 3,
                child: Align(alignment: Alignment.centerLeft, child: left)),
            Expanded(flex: 4, child: center),
            Expanded(
                flex: 3,
                child: Align(alignment: Alignment.centerRight, child: right)),
          ]);
        }
        // Narrow: stack the three blocks.
        return Column(children: [
          left,
          const SizedBox(height: 12),
          center,
          const SizedBox(height: 12),
          right
        ]);
      }),
    );
  }
}
