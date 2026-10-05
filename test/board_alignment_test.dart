import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_announcement_tv/main.dart';

// The "columns stagger after the IMPORTANT NOTICE card" fix was proven on
// the 960x540 emulator only — a TV reports other logical sizes. Same
// technique as the existing panels-level test, run at every TV resolution.
Future<void> launchAt(WidgetTester t, Size physical, double dpr) async {
  t.view.physicalSize = physical;
  t.view.devicePixelRatio = dpr;
  addTearDown(t.view.reset);
  await t.pumpWidget(const SchoolAnnouncementApp());
  await t.pump();
}

Future<void> expectPanelsLevel(WidgetTester t) async {
  final dividers = find.byType(Divider);
  final tops = [0, 1, 2].map((i) => t.getRect(dividers.at(i)).top).toList();
  expect(tops[0], tops[1], reason: 'news and events panels are level');
  expect(tops[1], tops[2], reason: 'events and schedule panels are level');
}

void main() {
  testWidgets('level at 960x540 logical (1080p TV, dpr 2)', (t) async {
    await launchAt(t, const Size(1920, 1080), 2);
    await expectPanelsLevel(t);
    await t.pumpWidget(const SizedBox()); // stop the header clock timer
  });

  testWidgets('level at 1920x1080 logical (4K TV, dpr 1)', (t) async {
    await launchAt(t, const Size(1920, 1080), 1);
    await expectPanelsLevel(t);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('level at 1280x720 logical (720p, dpr 1)', (t) async {
    await launchAt(t, const Size(1280, 720), 1);
    await expectPanelsLevel(t);
    await t.pumpWidget(const SizedBox());
  });
}
