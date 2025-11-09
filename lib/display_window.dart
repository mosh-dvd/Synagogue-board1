// lib/display_window.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:kosher_dart/kosher_dart.dart';
import 'package:synagogue_display/data/models.dart';
import 'package:synagogue_display/widgets/clock_widget.dart';
import 'package:synagogue_display/widgets/hebcal_widget.dart';
import 'package:synagogue_display/widgets/zmanim_widget.dart';
import 'package:synagogue_display/widgets/message_carousel_widget.dart';
// import 'package:synagogue_display/widgets/auto_scrolling_list_view.dart'; // הוסר זמנית

class DisplayWindow extends StatefulWidget {
  final int windowId;
  final String title;
  final int roomId;

  const DisplayWindow({
    Key? key,
    required this.windowId,
    required this.title,
    required this.roomId,
  }) : super(key: key);

  @override
  State<DisplayWindow> createState() => _DisplayWindowState();
}

class _DisplayWindowState extends State<DisplayWindow> {
  Room? _roomSettings;
  List<Minyan> _minyanim = [];
  List<Message> _messages = [];
  String? _location;
  bool _isLoading = true;
  String? _previousPayload;

  @override
  void initState() {
    super.initState();
    DesktopMultiWindow.setMethodHandler((call, fromWindowId) async {
      if (call.method == 'update_data') {
        if (call.arguments != _previousPayload) {
          _previousPayload = call.arguments;
          final Map<String, dynamic> payload = jsonDecode(call.arguments);
          _processPayload(payload);
        }
      }
      return "";
    });
  }

  void _processPayload(Map<String, dynamic> payload) {
    if (!mounted) return;

    final roomData = (payload['rooms'] as List)
      .firstWhere((r) => r['id'] == widget.roomId, orElse: () => null);

    if (roomData == null) {
        setState(() => _isLoading = false);
        return;
    }
    final currentRoomSettings = Room.fromMap(roomData);

    final allMinyanimRaw = (payload['minyanim'] as List)
        .map((m) => Minyan.fromMap(m))
        .toList();

    // --- שינוי: לוגיקת סינון פשוטה, יציבה ובטוחה ---
    final dayOfWeek = DateTime.now().weekday; // Monday = 1, Sunday = 7
    // הצג מניינים מיוחדים בימי שישי (6) ושבת (7)
    final bool showSpecialMinyanim = (dayOfWeek == DateTime.friday || dayOfWeek == DateTime.saturday);

    List<Minyan> todaysMinyanim = allMinyanimRaw.where((minyan) {
      if (minyan.scheduleType == MinyanScheduleType.REGULAR) {
        return !showSpecialMinyanim;
      } else { // SHABBAT_DAY or MOTZEI_SHABBAT
        return showSpecialMinyanim;
      }
    }).toList();


    List<Minyan> filteredMinyanim;
    if (currentRoomSettings.displayMode == MinyanDisplayMode.ALL) {
      filteredMinyanim = todaysMinyanim;
    } else {
      filteredMinyanim = todaysMinyanim.where((m) => m.roomId == widget.roomId).toList();
    }

    final allMessages = (payload['messages'] as List).map((m) => Message.fromMap(m)).toList();
    final links = payload['message_links'] as Map<String, dynamic>;

    List<Message> filteredMessages = [];
    for (final message in allMessages) {
      final messageLinks = links[message.id.toString()];
      if (messageLinks == null || (messageLinks as List).isEmpty) {
        filteredMessages.add(message);
      } else if ((messageLinks as List).contains(widget.roomId)) {
        filteredMessages.add(message);
      }
    }

    setState(() {
      _roomSettings = currentRoomSettings;
      _minyanim = filteredMinyanim;
      _messages = filteredMessages;
      _location = payload['location'];
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8F9FA),
        body: Center(child: Text("ממתין לנתונים ממסך הניהול...", style: TextStyle(color: Colors.black54, fontSize: 24))),
      );
    }

    if (_roomSettings == null) {
       return const Scaffold(
        backgroundColor: Color(0xFFF8F9FA),
        body: Center(child: Text("שגיאה: לא נמצאו הגדרות עבור חדר זה.", style: TextStyle(color: Colors.red, fontSize: 32))),
      );
    }
    
    const backgroundColor = Color(0xFFF8F9FA);
    const cardBackgroundColor = Colors.white;
    const primaryTextColor = Color(0xFF212529);
    const headerColor = Color(0xFFE9ECEF);
    const timeColor = Color(0xFF008080);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              color: headerColor,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // החזרנו את השעון כי הוא לא הבעיה
                  if (_roomSettings!.showClock) const ClockWidget(),
                  Text(
                    widget.title,
                    style: const TextStyle(fontSize: 52, fontWeight: FontWeight.bold, color: primaryTextColor),
                  ),
                  if (_roomSettings!.showCalendar) const HebcalWidget(),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: 4,
                      child: Container(
                        margin: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          color: cardBackgroundColor,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5)),
                          ],
                        ),
                        child: _minyanim.isEmpty
                            ? const Center(child: Text('אין מניינים להיום', style: TextStyle(fontSize: 32, color: Colors.grey)))
                            : Column(
                                children: [
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 16.0),
                                    child: Text("זמני תפילות", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: primaryTextColor)),
                                  ),
                                  const Divider(color: Colors.black12, indent: 24, endIndent: 24, height: 1),
                                  Expanded(
                                    // בלי גלילה אוטומטית כרגע, כדי לשמור על יציבות
                                    child: ListView.builder(
                                      padding: const EdgeInsets.all(8),
                                      itemCount: _minyanim.length,
                                      itemBuilder: (context, index) {
                                        final minyan = _minyanim[index];
                                        final showRoomName = _roomSettings?.displayMode == MinyanDisplayMode.ALL;

                                        return Container(
                                          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                          decoration: BoxDecoration(color: headerColor, borderRadius: BorderRadius.circular(8)),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(minyan.name, style: const TextStyle(fontSize: 40, color: primaryTextColor)),
                                                  if (showRoomName && minyan.roomName != null)
                                                    Text(minyan.roomName!, style: const TextStyle(fontSize: 20, color: Colors.black54)),
                                                ],
                                              ),
                                              Text(
                                                minyan.time,
                                                style: const TextStyle(fontSize: 56, fontWeight: FontWeight.bold, color: timeColor),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    Expanded(
                      flex: _roomSettings!.sidePanelFlex,
                      child: Column(
                        children: [
                          if (_roomSettings!.showZmanim && _location != null)
                            Expanded(
                              flex: 3,
                              child: ZmanimWidget(location: _location!),
                            ),
                          if (_messages.isNotEmpty)
                            const SizedBox(height: 16),
                          if (_messages.isNotEmpty)
                            Expanded(
                              flex: 2,
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 8),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey.shade300)
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(11),
                                  child: MessageCarouselWidget(messages: _messages),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}