// lib/main.dart
import 'package:flutter/material.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'dart:convert';
import 'dart:io';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:synagogue_display/admin_window.dart';
import 'package:synagogue_display/data/data_provider.dart';
import 'package:synagogue_display/data/database_helper.dart';
import 'package:synagogue_display/display_window.dart';

// ******** תיקון: הלוגיקה עברה לכאן ישירות *********
void main(List<String> args) async {
  // הבדיקה אם מדובר בחלון משנה מתבצעת עכשיו ישירות על הארגומנטים
  if (args.isNotEmpty && args.first == 'multi_window') {
    final windowId = int.parse(args[1]);
    final arguments = jsonDecode(args[2]) as Map<String, dynamic>;
    final String screenTitle = arguments['title'] ?? 'תצוגה';
    final int roomId = arguments['room_id'];

    // אם זה חלון משנה, הרץ את אפליקציית התצוגה
    runApp(DisplayApp(windowId: windowId, title: screenTitle, roomId: roomId));
  } else {
    // אחרת, זה החלון הראשי. הרץ את אפליקציית הניהול
    WidgetsFlutterBinding.ensureInitialized();

    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
    await DatabaseHelper.init();

    runApp(
      ChangeNotifierProvider(
        create: (context) => DataProvider(),
        child: const AdminApp(),
      )
    );
  }
}

// ******** MainAppRouter נמחק כי הוא כבר לא נחוץ *********

class AdminApp extends StatelessWidget {
  const AdminApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ניהול שלט דיגיטלי',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: 'Heebo'),
      home: const AdminWindow(),
    );
  }
}

class DisplayApp extends StatelessWidget {
  final int windowId;
  final String title;
  final int roomId;

  const DisplayApp({
    Key? key,
    required this.windowId,
    required this.title,
    required this.roomId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // חשוב לעטוף גם את אפליקציית התצוגה ב-MaterialApp
    return MaterialApp(
      title: title,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        fontFamily: 'Heebo',
      ),
      home: DisplayWindow(windowId: windowId, title: title, roomId: roomId),
    );
  }
}