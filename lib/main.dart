import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'widgets/header_widget.dart';

void main() => runApp(const SchoolAnnouncementApp());

class SchoolAnnouncementApp extends StatelessWidget {
  const SchoolAnnouncementApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CHCCI • School Announcement TV',
      debugShowCheckedModeBanner: false,
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
