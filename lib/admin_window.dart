// lib/admin_window.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:synagogue_display/data/data_provider.dart';
import 'package:synagogue_display/tabs/minyanim_management_tab.dart';
import 'package:synagogue_display/tabs/rooms_management_tab.dart';
import 'package:synagogue_display/tabs/messages_management_tab.dart';
import 'package:synagogue_display/dialogs/global_settings_dialog.dart';
import 'package:synagogue_display/dialogs/theme_settings_dialog.dart';
import 'package:synagogue_display/dialogs/schedule_timing_dialog.dart'; // ייבוא חדש

class AdminWindow extends StatefulWidget {
  const AdminWindow({Key? key}) : super(key: key);

  @override
  State<AdminWindow> createState() => _AdminWindowState();
}

class _AdminWindowState extends State<AdminWindow> {
  Timer? _broadcastDebouncer;

  @override
  void initState() {
    super.initState();
    final dataProvider = Provider.of<DataProvider>(context, listen: false);
    dataProvider.addListener(_broadcastData);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _broadcastData();
      }
    });
  }

  @override
  void dispose() {
    _broadcastDebouncer?.cancel();
    Provider.of<DataProvider>(context, listen: false).removeListener(_broadcastData);
    super.dispose();
  }

  void _broadcastData() {
    if (_broadcastDebouncer?.isActive ?? false) _broadcastDebouncer!.cancel();

    _broadcastDebouncer = Timer(const Duration(milliseconds: 250), () async {
      if (!mounted) return;

      final dataProvider = Provider.of<DataProvider>(context, listen: false);
      
      final payload = jsonEncode({
        'rooms': dataProvider.rooms.map((r) => r.toMap()).toList(),
        'minyanim': dataProvider.minyanim.map((m) => m.toBroadcastMap()).toList(),
        'messages': dataProvider.messages.map((m) => m.toMap()).toList(),
        'message_links': dataProvider.messageLinks,
        'location': dataProvider.location,
        'theme': dataProvider.theme.toMap(),
        // העברת הגדרות הזמנים לחלונות התצוגה
        'switch_erev': dataProvider.switchErev.toMap(),
        'switch_shabbat': dataProvider.switchShabbat.toMap(),
        'switch_motzaei': dataProvider.switchMotzaei.toMap(),
      });
      
      final windowIds = await DesktopMultiWindow.getAllSubWindowIds();
      
      for (final windowId in windowIds) {
        DesktopMultiWindow.invokeMethod(
          windowId,
          'update_data',
          payload,
        );
      }
    });
  }

  Future<void> _openAllWindows(BuildContext context) async {
    final dataProvider = Provider.of<DataProvider>(context, listen: false);
    await dataProvider.fetchAllData();

    for (final room in dataProvider.rooms) {
      if (room.isDisplayActive) {
        final arguments = jsonEncode({
          'title': room.name,
          'room_id': room.id,
        });

        final window = await DesktopMultiWindow.createWindow(arguments);
        window
          ..setFrame(const Offset(0, 0) & const Size(1280, 720))
          ..setTitle(room.name)
          ..show();
      }
    }
  }

  void _showGlobalSettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const GlobalSettingsDialog(),
    ).then((_) {
      Provider.of<DataProvider>(context, listen: false).fetchAllData();
    });
  }
  
  void _showThemeSettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const ThemeSettingsDialog(),
    );
  }
  
  // פונקציה חדשה
  void _showScheduleTimingSettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const ScheduleTimingDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: DefaultTabController(
        length: 3,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('ממשק ניהול'),
            actions: [
              IconButton(
                icon: const Icon(Icons.access_time), // אייקון שעון להגדרות זמנים
                tooltip: 'הגדרת זמני מעבר לוחות',
                onPressed: () => _showScheduleTimingSettings(context),
              ),
              IconButton(
                icon: const Icon(Icons.color_lens_outlined),
                tooltip: 'הגדרות עיצוב',
                onPressed: () => _showThemeSettings(context),
              ),
              IconButton(
                icon: const Icon(Icons.settings),
                tooltip: 'הגדרות כלליות',
                onPressed: () => _showGlobalSettings(context),
              ),
              IconButton(
                icon: const Icon(Icons.open_in_new),
                tooltip: 'פתח חלונות פעילים',
                onPressed: () => _openAllWindows(context),
              ),
            ],
            bottom: const TabBar(
              tabs: [
                Tab(icon: Icon(Icons.people), text: 'ניהול מניינים'),
                Tab(icon: Icon(Icons.room), text: 'ניהול חדרים'),
                Tab(icon: Icon(Icons.message), text: 'ניהול הודעות'),
              ],
            ),
          ),
          body: const TabBarView(
            children: [
              MinyanimManagementTab(),
              RoomsManagementTab(),
              MessagesManagementTab(),
            ],
          ),
        ),
      ),
    );
  }
}