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
  Map<MinyanScheduleType, List<Minyan>> _groupedMinyanim = {};
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
    
    Map<MinyanScheduleType, List<Minyan>> categorizedMinyanim = {};
    for (final minyan in filteredMinyanim) {
      if (categorizedMinyanim[minyan.scheduleType] == null) {
        categorizedMinyanim[minyan.scheduleType] = [];
      }
      categorizedMinyanim[minyan.scheduleType]!.add(minyan);
    }

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
      _groupedMinyanim = categorizedMinyanim;
      _panelMessages = categorizedMessages;
      _location = payload['location'];
      _isLoading = false;
    });
  }

  String _getScheduleTypeTitle(MinyanScheduleType type) {
    switch (type) {
      case MinyanScheduleType.REGULAR:
        return 'תפילות ליום חול';
      case MinyanScheduleType.SHABBAT_DAY:
        return 'תפילות שבת וחג';
      case MinyanScheduleType.MOTZEI_SHABBAT:
        return 'תפילות למוצאי שבת';
    }
  }

  Widget _buildMinyanimColumn({
      required Color cardBackgroundColor,
      required Color primaryTextColor,
      required Color timeColor
  }) {
    List<Widget> minyanWidgets = [];
    final orderedTypes = [MinyanScheduleType.REGULAR, MinyanScheduleType.SHABBAT_DAY, MinyanScheduleType.MOTZEI_SHABBAT];

    for (var type in orderedTypes) {
      if (_groupedMinyanim.containsKey(type) && _groupedMinyanim[type]!.isNotEmpty) {
        minyanWidgets.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: Text(
              _getScheduleTypeTitle(type),
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: primaryTextColor.withOpacity(0.9),
              ),
              textAlign: TextAlign.right,
            ),
          ),
        );

        for (var minyan in _groupedMinyanim[type]!) {
          minyanWidgets.add(
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          minyan.name,
                          style: TextStyle(fontSize: 22, color: primaryTextColor),
                          textAlign: TextAlign.right,
                        ),
                        if (minyan.roomName != null)
                          Text(
                            minyan.roomName!,
                            style: TextStyle(fontSize: 16, color: primaryTextColor.withOpacity(0.6)),
                            textAlign: TextAlign.right,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 90,
                    child: Text(
                      minyan.time,
                      style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: timeColor),
                      textAlign: TextAlign.left,
                      textDirection: TextDirection.ltr,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: cardBackgroundColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5)),
        ],
      ),
      child: _groupedMinyanim.isEmpty
          ? Center(child: Text('אין מניינים להיום', style: TextStyle(fontSize: 24, color: Colors.grey.shade600)))
          : Column(
              children: [
                Padding( // No const here because of the variable color
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Text("זמני תפילות", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: primaryTextColor)),
                ),
                const Divider(color: Colors.black12, indent: 24, endIndent: 24, height: 1),
                Expanded(
                  child: ListView(
                    children: minyanWidgets,
                  ),
                ),
              ],
            ),
    );
  } // <--- הוספת הסוגר החסר

  Widget _buildMessagePanel(List<Message> messages) {
    return Container(
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
          Expanded(child: Padding(padding: const EdgeInsets.all(4.0), child: _buildMessagePanel(_panelMessages[1] ?? []))),
          Expanded(child: Padding(padding: const EdgeInsets.all(4.0), child: _buildMessagePanel(_panelMessages[2] ?? []))),
        ]);
      case 3:
        return Column(children: [
          Expanded(
            flex: 2,
            child: Row(children: [
              Expanded(child: Padding(padding: const EdgeInsets.all(4.0), child: _buildMessagePanel(_panelMessages[1] ?? []))),
              Expanded(child: Padding(padding: const EdgeInsets.all(4.0), child: _buildMessagePanel(_panelMessages[2] ?? []))),
            ]),
          ),
          Expanded(
            flex: 1,
            child: Padding(padding: const EdgeInsets.all(4.0), child: _buildMessagePanel(_panelMessages[3] ?? []))),
        ]);
      case 4:
        return Column(children: [
          Expanded(
            child: Row(children: [
              Expanded(child: Padding(padding: const EdgeInsets.all(4.0), child: _buildMessagePanel(_panelMessages[1] ?? []))),
              Expanded(child: Padding(padding: const EdgeInsets.all(4.0), child: _buildMessagePanel(_panelMessages[2] ?? []))),
            ]),
          ),
          Expanded(
            child: Row(children: [
              Expanded(child: Padding(padding: const EdgeInsets.all(4.0), child: _buildMessagePanel(_panelMessages[3] ?? []))),
              Expanded(child: Padding(padding: const EdgeInsets.all(4.0), child: _buildMessagePanel(_panelMessages[4] ?? []))),
            ]),
          ),
        ]);
      case 1:
      default:
        return Padding(padding: const EdgeInsets.all(4.0), child: _buildMessagePanel(_panelMessages[1] ?? []));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_roomSettings == null) {
      return const Scaffold(body: Center(child: Text("שגיאה בטעינת הגדרות")));
    }
    
    const backgroundColor = Color(0xFFF8F9FA);
    const cardBackgroundColor = Colors.white;
    const primaryTextColor = Color(0xFF212529);
    const headerColor = Color(0xFFE9ECEF);
    final timeColor = Colors.teal[600]!;

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
                    style: const TextStyle(fontSize: 52, fontWeight: FontWeight.bold, color: primaryTextColor),
                  ),
                  if (_roomSettings!.showCalendar) const HebcalWidget(),
                ],
              ),
            ),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: 2,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(8, 8, 4, 8),
                      child: _buildMinyanimColumn(
                        cardBackgroundColor: cardBackgroundColor,
                        primaryTextColor: primaryTextColor,
                        timeColor: timeColor,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 7,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                      child: _buildMessageLayout(),
                    ),
                  ),
                  if (_roomSettings!.showZmanim && _location != null)
                    Expanded(
                      flex: 2,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(4, 8, 8, 8),
                        child: ZmanimWidget(location: _location!),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}