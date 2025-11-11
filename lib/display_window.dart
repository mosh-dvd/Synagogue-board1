import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:synagogue_display/data/models.dart';
import 'package:synagogue_display/widgets/clock_widget.dart';
import 'package:synagogue_display/widgets/hebcal_widget.dart';
import 'package:synagogue_display/widgets/zmanim_widget.dart';
import 'package:synagogue_display/widgets/message_carousel_widget.dart';

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
  Map<int, List<Message>> _panelMessages = {};
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
    final allMinyanimRaw =
        (payload['minyanim'] as List).map((m) => Minyan.fromMap(m)).toList();

    final dayOfWeek = DateTime.now().weekday;
    final bool showSpecialMinyanim =
        (dayOfWeek == DateTime.friday || dayOfWeek == DateTime.saturday);
    List<Minyan> todaysMinyanim = allMinyanimRaw.where((minyan) {
      return (minyan.scheduleType == MinyanScheduleType.REGULAR) ? !showSpecialMinyanim : showSpecialMinyanim;
    }).toList();
    todaysMinyanim.sort((a, b) => a.time.compareTo(b.time));
    List<Minyan> filteredMinyanim = (currentRoomSettings.displayMode == MinyanDisplayMode.ALL)
        ? todaysMinyanim
        : todaysMinyanim.where((m) => m.roomId == widget.roomId).toList();
    
    final allMessages = (payload['messages'] as List).map((m) => Message.fromMap(m)).toList();
    final links = payload['message_links'] as Map<String, dynamic>;
    Map<int, List<Message>> categorizedMessages = {1: [], 2: [], 3: [], 4: []};

    for (final message in allMessages) {
      if (!message.isActive) continue;

      final messageLinks = links[message.id.toString()];
      final isLinkedToThisRoom = (messageLinks as List?)?.contains(widget.roomId) ?? false;
      final isGlobal = messageLinks == null || messageLinks.isEmpty;

      if (isGlobal || isLinkedToThisRoom) {
        if (categorizedMessages.containsKey(message.panelIndex)) {
          categorizedMessages[message.panelIndex]!.add(message);
        }
      }
    }

    setState(() {
      _roomSettings = currentRoomSettings;
      _minyanim = filteredMinyanim;
      _panelMessages = categorizedMessages;
      _location = payload['location'];
      _isLoading = false;
    });
  }

  Widget _buildMinyanimColumn({
      required Color cardBackgroundColor,
      required Color primaryTextColor,
      required Color headerColor,
      required Color timeColor
  }) {
    return Container(
      margin: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: cardBackgroundColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5)),
        ],
      ),
      child: _minyanim.isEmpty
          ? Center(
              child: Text('אין מניינים להיום',
                  style: TextStyle(fontSize: 24, color: Colors.grey.shade600)))
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Text("זמני תפילות",
                      style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: primaryTextColor)),
                ),
                const Divider(
                    color: Colors.black12, indent: 24, endIndent: 24, height: 1),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: _minyanim.length,
                    itemBuilder: (context, index) {
                      final minyan = _minyanim[index];
                      final showRoomName =
                          _roomSettings?.displayMode == MinyanDisplayMode.ALL;

                      return Container(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                            color: headerColor,
                            borderRadius: BorderRadius.circular(8)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(minyan.name,
                                      style: TextStyle(
                                          fontSize: 28, color: primaryTextColor),
                                      overflow: TextOverflow.ellipsis,
                                  ),
                                  if (showRoomName && minyan.roomName != null)
                                    Text(minyan.roomName!,
                                        style: const TextStyle(
                                            fontSize: 16, color: Colors.black54)),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              minyan.time,
                              style: TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  color: timeColor),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildMessagePanel(List<Message> messages) {
    return Container(
      margin: const EdgeInsets.all(4.0),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: MessageCarouselWidget(messages: messages),
      ),
    );
  }

  Widget _buildMessageLayout() {
    final activePanels = _roomSettings?.activeMessagePanels ?? 1;

    switch (activePanels) {
      case 2:
        return Row(children: [
          Expanded(child: _buildMessagePanel(_panelMessages[1] ?? [])),
          Expanded(child: _buildMessagePanel(_panelMessages[2] ?? [])),
        ]);
      case 3:
        return Column(children: [
          Expanded(
            child: Row(children: [
              Expanded(child: _buildMessagePanel(_panelMessages[1] ?? [])),
              Expanded(child: _buildMessagePanel(_panelMessages[2] ?? [])),
            ]),
          ),
          Expanded(child: _buildMessagePanel(_panelMessages[3] ?? [])),
        ]);
      case 4:
        return Column(children: [
          Expanded(
            child: Row(children: [
              Expanded(child: _buildMessagePanel(_panelMessages[1] ?? [])),
              Expanded(child: _buildMessagePanel(_panelMessages[2] ?? [])),
            ]),
          ),
          Expanded(
            child: Row(children: [
              Expanded(child: _buildMessagePanel(_panelMessages[3] ?? [])),
              Expanded(child: _buildMessagePanel(_panelMessages[4] ?? [])),
            ]),
          ),
        ]);
      case 1:
      default:
        return _buildMessagePanel(_panelMessages[1] ?? []);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8F9FA),
        body: Center(
            child: Text("ממתין לנתונים ממסך הניהול...",
                style: TextStyle(color: Colors.black54, fontSize: 24))),
      );
    }

    if (_roomSettings == null) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8F9FA),
        body: Center(
            child: Text("שגיאה: לא נמצאו הגדרות עבור חדר זה.",
                style: TextStyle(color: Colors.red, fontSize: 32))),
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
                  if (_roomSettings!.showClock) const ClockWidget(),
                  Text(
                    widget.title,
                    style: const TextStyle(
                        fontSize: 52,
                        fontWeight: FontWeight.bold,
                        color: primaryTextColor),
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
                      flex: _roomSettings!.sidePanelFlex,
                      child: _buildMinyanimColumn(
                        cardBackgroundColor: cardBackgroundColor,
                        primaryTextColor: primaryTextColor,
                        headerColor: headerColor,
                        timeColor: timeColor,
                      ),
                    ),
                    Expanded(
                      flex: 5,
                      child: Container(
                          margin: const EdgeInsets.all(4.0),
                          child: _buildMessageLayout()
                      ),
                    ),
                    if (_roomSettings!.showZmanim && _location != null)
                      Expanded(
                        flex: _roomSettings!.sidePanelFlex,
                        child: ZmanimWidget(location: _location!),
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