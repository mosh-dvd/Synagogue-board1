import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:synagogue_display/data/minyan_logic_helper.dart';
import 'package:synagogue_display/data/models.dart';
import 'package:synagogue_display/data/zmanim_helper.dart';
import 'package:synagogue_display/widgets/auto_scrolling_list_view.dart'; // הוספת ייבוא
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
  Map<MinyanScheduleType, Map<String, List<Minyan>>> _groupedMinyanim = {};
  List<Minyan> _allMinyanim = [];
  Map<int, List<Message>> _panelMessages = {};
  String? _location;
  bool _isLoading = true;
  String? _previousPayload;
  MinyanWithTime? _nextMinyan;
  Timer? _nextMinyanTimer;
  String _nextMinyanCountdown = "";

  @override
  void initState() {
    super.initState();
    _startNextMinyanTimer();
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

  @override
  void dispose() {
    _nextMinyanTimer?.cancel();
    super.dispose();
  }

  void _startNextMinyanTimer() {
    _updateNextMinyan();
    _nextMinyanTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _tick();
    });
  }

  void _updateNextMinyan() {
    if (_allMinyanim.isEmpty || _location == null) return;
    final foundMinyan = MinyanLogicHelper.findNextMinyan(_allMinyanim, _location!);
    if (mounted && (foundMinyan?.minyan.id != _nextMinyan?.minyan.id)) {
      setState(() {
        _nextMinyan = foundMinyan;
      });
    }
  }

  void _tick() {
    if (_nextMinyan == null) {
      if (DateTime.now().second % 30 == 0) {
        _updateNextMinyan();
      }
      setState(() {
        _nextMinyanCountdown = "";
      });
      return;
    }
    final difference = _nextMinyan!.dateTime.difference(DateTime.now());
    if (difference.isNegative) {
      _updateNextMinyan();
      return;
    }
    final hours = difference.inHours;
    final minutes = difference.inMinutes.remainder(60);
    final seconds = difference.inSeconds.remainder(60);
    if (mounted) {
      setState(() {
        _nextMinyanCountdown = '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
      });
    }
  }

  void _processPayload(Map<String, dynamic> payload) {
    if (!mounted) return;
    final roomData = (payload['rooms'] as List).firstWhere((r) => r['id'] == widget.roomId, orElse: () => null);
    if (roomData == null) {
      setState(() => _isLoading = false);
      return;
    }
    final currentRoomSettings = Room.fromMap(roomData);
    final location = payload['location'] as String? ?? 'ירושלים';
    final allMinyanim = (payload['minyanim'] as List).map((m) => Minyan.fromMap(m)).toList();
    final zmanimDateTimes = ZmanimHelper.getZmanimDateTimes(location);
    final processedMinyanim = allMinyanim.map((minyan) {
      if (minyan.timeType == MinyanTimeType.RELATIVE && minyan.relativeZman != null) {
        final zmanTime = zmanimDateTimes[minyan.relativeZman!];
        if (zmanTime != null) {
          final calculatedTime = zmanTime.add(Duration(minutes: minyan.relativeOffsetMinutes ?? 0));
          return Minyan( id: minyan.id, name: minyan.name, roomId: minyan.roomId, roomName: minyan.roomName, scheduleType: minyan.scheduleType, timeType: MinyanTimeType.FIXED, time: DateFormat('HH:mm').format(calculatedTime) );
        }
      }
      return minyan;
    }).where((m) => m.time != null).toList();
    final dayOfWeek = DateTime.now().weekday;
    final bool showSpecialMinyanim = (dayOfWeek == DateTime.friday || dayOfWeek == DateTime.saturday);
    List<Minyan> todaysMinyanim = processedMinyanim.where((minyan) {
      return (minyan.scheduleType == MinyanScheduleType.REGULAR) ? !showSpecialMinyanim : showSpecialMinyanim;
    }).toList();
    todaysMinyanim.sort((a, b) => a.time!.compareTo(b.time!));
    List<Minyan> filteredMinyanim = (currentRoomSettings.displayMode == MinyanDisplayMode.ALL) ? todaysMinyanim : todaysMinyanim.where((m) => m.roomId == widget.roomId).toList();
    Map<MinyanScheduleType, Map<String, List<Minyan>>> categorizedMinyanim = {};
    for (final minyan in filteredMinyanim) {
      final scheduleType = minyan.scheduleType;
      final prayerName = minyan.name;
      if (categorizedMinyanim[scheduleType] == null) categorizedMinyanim[scheduleType] = {};
      if (categorizedMinyanim[scheduleType]![prayerName] == null) categorizedMinyanim[scheduleType]![prayerName] = [];
      categorizedMinyanim[scheduleType]![prayerName]!.add(minyan);
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
      _allMinyanim = allMinyanim;
      _panelMessages = categorizedMessages;
      _location = location;
      _isLoading = false;
    });
    _updateNextMinyan();
  }

  String _getScheduleTypeTitle(MinyanScheduleType type) {
    switch (type) {
      case MinyanScheduleType.REGULAR: return 'תפילות ליום חול';
      case MinyanScheduleType.SHABBAT_DAY: return 'תפילות שבת וחג';
      case MinyanScheduleType.MOTZEI_SHABBAT: return 'תפילות למוצאי שבת';
    }
  }

  Widget _buildMinyanimColumn({
      required Color cardBackgroundColor,
      required Color primaryTextColor,
      required Color accentColor
  }) {
    List<Widget> minyanWidgets = [];
    final orderedTypes = [MinyanScheduleType.REGULAR, MinyanScheduleType.SHABBAT_DAY, MinyanScheduleType.MOTZEI_SHABBAT];

    for (var type in orderedTypes) {
      if (_groupedMinyanim.containsKey(type) && _groupedMinyanim[type]!.isNotEmpty) {
        minyanWidgets.add( Padding( padding: const EdgeInsets.fromLTRB(16, 20, 16, 8), child: Text( _getScheduleTypeTitle(type), style: GoogleFonts.rubik(fontSize: 26, fontWeight: FontWeight.w500, color: primaryTextColor), textAlign: TextAlign.center, ), ), );
        minyanWidgets.add(Divider(color: primaryTextColor.withOpacity(0.1), indent: 30, endIndent: 30, thickness: 1));
        
        final prayerGroups = _groupedMinyanim[type]!.entries.toList();
        for (int i = 0; i < prayerGroups.length; i++) {
          final prayerName = prayerGroups[i].key;
          final minyanList = prayerGroups[i].value;

          minyanWidgets.add( Padding( padding: const EdgeInsets.fromLTRB(16, 12, 16, 4), child: Text( prayerName, style: GoogleFonts.rubik(fontSize: 24, fontWeight: FontWeight.w500, color: primaryTextColor.withOpacity(0.9)), textAlign: TextAlign.center, ), ), );
          for (var minyan in minyanList) {
            minyanWidgets.add( Padding( padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 24.0), child: Row( mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [ Text( minyan.roomName ?? 'חדר לא ידוע', style: GoogleFonts.rubik(fontSize: 18, color: primaryTextColor.withOpacity(0.7)), textAlign: TextAlign.right, ), Text( minyan.time ?? '--:--', style: GoogleFonts.tinos(fontSize: 30, fontWeight: FontWeight.bold, color: accentColor), textAlign: TextAlign.left, textDirection: ui.TextDirection.ltr, ), ], ), ), );
          }
          
          if (i < prayerGroups.length - 1) {
            minyanWidgets.add(
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 60.0),
                child: Row(
                  children: [
                    Expanded(child: Divider(color: primaryTextColor.withOpacity(0.2))),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      child: Icon(Icons.spa_outlined, color: primaryTextColor.withOpacity(0.6), size: 18),
                    ),
                    Expanded(child: Divider(color: primaryTextColor.withOpacity(0.2))),
                  ],
                ),
              )
            );
          }
        }
      }
    }
    return Container( 
      decoration: BoxDecoration( 
        color: cardBackgroundColor, 
        borderRadius: BorderRadius.circular(16), 
      ), 
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Positioned( top: 8, right: 8, child: Icon(Icons.spa_outlined, color: primaryTextColor.withOpacity(0.4), size: 24), ),
            Positioned( top: 8, left: 8, child: Transform( alignment: Alignment.center, transform: Matrix4.rotationY(pi), child: Icon(Icons.spa_outlined, color: primaryTextColor.withOpacity(0.4), size: 24), ), ),
            _groupedMinyanim.isEmpty 
              ? Center(child: Text('אין מניינים להיום', style: GoogleFonts.rubik(fontSize: 24, color: primaryTextColor.withOpacity(0.6)))) 
              : AutoScrollingListView( // שימוש בווידג'ט הגלילה
                  padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                  children: minyanWidgets
                ),
          ],
        ),
      ), 
    );
  }

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
          Expanded(flex: 2, child: Row(children: [ 
            Expanded(child: Padding(padding: const EdgeInsets.all(4.0), child: _buildMessagePanel(_panelMessages[1] ?? []))), 
            Expanded(child: Padding(padding: const EdgeInsets.all(4.0), child: _buildMessagePanel(_panelMessages[2] ?? []))),
          ])),
          Expanded(flex: 1, child: Padding(padding: const EdgeInsets.all(4.0), child: _buildMessagePanel(_panelMessages[3] ?? []))),
        ]);
      case 4:
        return Column(children: [
          Expanded(child: Row(children: [ 
            Expanded(child: Padding(padding: const EdgeInsets.all(4.0), child: _buildMessagePanel(_panelMessages[1] ?? []))), 
            Expanded(child: Padding(padding: const EdgeInsets.all(4.0), child: _buildMessagePanel(_panelMessages[2] ?? []))),
          ])),
          Expanded(child: Row(children: [ 
            Expanded(child: Padding(padding: const EdgeInsets.all(4.0), child: _buildMessagePanel(_panelMessages[3] ?? []))), 
            Expanded(child: Padding(padding: const EdgeInsets.all(4.0), child: _buildMessagePanel(_panelMessages[4] ?? []))),
          ])),
        ]);
      default:
        return Padding(padding: const EdgeInsets.all(4.0), child: _buildMessagePanel(_panelMessages[1] ?? []));
    }
  }

  Widget _buildHeaderTitle({
      required Color primaryTextColor,
      required Color accentColor
  }) {
    if (_nextMinyan == null) {
      return Text(
        widget.title,
        textAlign: TextAlign.center,
        style: GoogleFonts.amiri(fontSize: 58, fontWeight: FontWeight.bold, color: primaryTextColor),
      );
    } else {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'המניין הבא: ${_nextMinyan!.minyan.name} ב${_nextMinyan!.minyan.roomName ?? ''}',
            style: GoogleFonts.rubik(fontSize: 34, fontWeight: FontWeight.w500, color: primaryTextColor),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            _nextMinyanCountdown,
            style: GoogleFonts.robotoMono(fontSize: 30, fontWeight: FontWeight.bold, color: accentColor),
          ),
        ],
      );
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
    
    const backgroundColor = Color(0xFFFFF7F7);
    const columnColor = Color(0xFFB3E5FC);
    const primaryTextColor = Color(0xFF37474F);
    const accentColor = Color(0xFF0D47A1);
    const headerColor = Color(0xFFFFF7F7);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Directionality(
        textDirection: ui.TextDirection.rtl,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              color: headerColor,
              child: Row(
                children: [
                  const SizedBox(width: 96),
                  if (_roomSettings!.showClock) const ClockWidget(),
                  Expanded(child: _buildHeaderTitle(primaryTextColor: primaryTextColor, accentColor: accentColor)),
                  if (_roomSettings!.showCalendar) const HebcalWidget(),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: 3,
                      child: _buildMinyanimColumn(
                        cardBackgroundColor: columnColor,
                        primaryTextColor: primaryTextColor,
                        accentColor: accentColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 7,
                      child: _buildMessageLayout(),
                    ),
                    if (_roomSettings!.showZmanim && _location != null)
                      const SizedBox(width: 12),
                    if (_roomSettings!.showZmanim && _location != null)
                      Expanded(
                        flex: 3,
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