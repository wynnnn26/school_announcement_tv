import 'package:flutter/material.dart';
import 'data/notify.dart';
import 'data/store.dart';
import 'screens/home_screen.dart';
import 'widgets/header_widget.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await loadStore(); // restore saved items (first run keeps the sample seeds)
  runApp(const SchoolAnnouncementApp());
  NotifyService().start(); // in-app banner+beep: 30s tick, session-only memory
}

class SchoolAnnouncementApp extends StatelessWidget {
  const SchoolAnnouncementApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CHCCI • School Announcement TV',
      debugShowCheckedModeBanner: false,
      navigatorKey: rootNavKey, // banner overlays whatever screen is open
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: navy,
        // Deep navy page background; white cards carry the content.
        scaffoldBackgroundColor: navy,
        appBarTheme: const AppBarTheme(
            backgroundColor: navy, foregroundColor: Colors.white),
        cardTheme: CardThemeData(
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
        // White input fills keep every field readable on the navy background.
        inputDecorationTheme: InputDecorationThemeData(
          filled: true,
          fillColor: Colors.white,
          border: const OutlineInputBorder(),
        ),
      ),
      home: const HomeScreen(), // the TV display is always the first screen
    );
  }
}
