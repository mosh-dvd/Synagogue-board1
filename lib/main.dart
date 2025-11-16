// lib/main.dart

import 'package:flutter/material.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'dart:convert';
import 'dart:io';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:synagogue_display/admin_window.dart';
import 'package:synagogue_display/data/data_provider.dart';
import 'package:synagogue_display/display_window.dart';
import 'package:synagogue_display/logger.dart';

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppLogger.init();

  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  if (args.isNotEmpty && args.first == 'multi_window') {
    // *** תיקון קריטי כאן ***
    final windowId = int.parse(args[1]);
    final arguments = jsonDecode(args[2]) as Map<String, dynamic>;
    final String screenTitle = arguments['title'] ?? 'תצוגה';
    final int roomId = arguments['room_id'];
    
    runApp(
      ChangeNotifierProvider(
        create: (context) => DataProvider(),
        child: DisplayApp(windowId: windowId, title: screenTitle, roomId: roomId),
      ),
    );
  } else {
    runApp(
      ChangeNotifierProvider(
        create: (context) => DataProvider(),
        child: const AdminApp(),
      ),
    );
  }
}

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