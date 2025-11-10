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
    // המאזין חוזר! הוא יגיב לכל שינוי נקודתי ב-Provider
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
    _broadcastDebouncer = Timer(const Duration(milliseconds: 100), () async {
      if (!mounted) return;
      final dataProvider = Provider.of<DataProvider>(context, listen: false);
      final payload = jsonEncode({
        'rooms': dataProvider.rooms.map((r) => r.toMap()).toList(),
        'minyanim': dataProvider.minyanim.map((m) => m.toMap()).toList(),
        'messages': dataProvider.messages.where((m) => m.isActive).map((m) => m.toMap()).toList(), // שלח רק הודעות פעילות
        'message_links': dataProvider.messageLinks,
        'location': dataProvider.location,
      });
      final windowIds = await DesktopMultiWindow.getAllSubWindowIds();
      for (final windowId in windowIds) {
        DesktopMultiWindow.invokeMethod(windowId, 'update_data', payload);
      }
    });
  }

  Future<void> _openAllWindows(BuildContext context) async {
    final dataProvider = Provider.of<DataProvider>(context, listen: false);
    await dataProvider.fetchAllData();
    for (final room in dataProvider.rooms) {
      final arguments = jsonEncode({'title': room.name, 'room_id': room.id});
      final window = await DesktopMultiWindow.createWindow(arguments);
      window
        ..setFrame(const Offset(0, 0) & const Size(1280, 720))
        ..setTitle(room.name)
        ..show();
    }
  }

  void _showGlobalSettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const GlobalSettingsDialog(),
    ).then((saved) {
      if (saved == true) {
        // המאזין יטפל בשידור אוטומטית
        final provider = Provider.of<DataProvider>(context, listen: false);
        provider.updateLocation(provider.location);
      }
    });
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
                icon: const Icon(Icons.settings),
                tooltip: 'הגדרות כלליות',
                onPressed: () => _showGlobalSettings(context),
              ),
              IconButton(
                icon: const Icon(Icons.open_in_new),
                tooltip: 'פתח את כל החלונות',
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