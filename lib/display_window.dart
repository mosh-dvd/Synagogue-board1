// lib/display_window.dart (קובץ מלא)
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
import 'package:synagogue_display/widgets/clock_widget.dart';
import 'package:synagogue_display/widgets/hebcal_widget.dart';
import 'package:synagogue_display/widgets/zmanim_widget.dart';
import 'package:synagogue_display/widgets/message_carousel_widget.dart';
import 'package:kosher_dart/kosher_dart.dart';

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

    final now = DateTime.now();
    final jewishCalendar = JewishCalendar.fromDateTime(now);
    final sunsetToday = zmanimDateTimes[RelativeZman.sunset];
    final chatzosToday = zmanimDateTimes[RelativeZman.chatzos];
    List<MinyanScheduleType> activeScheduleTypes = [];

    final isShabbat = jewishCalendar.getDayOfWeek() == 7 || jewishCalendar.isYomTov();
    final isErevShabbat = jewishCalendar.getDayOfWeek() == 6 || jewishCalendar.isErevYomTov();
    final isSunday = jewishCalendar.getDayOfWeek() == 1;

    if (isShabbat) { // שבת / יום טוב
        if (sunsetToday != null && now.isAfter(sunsetToday)) {
            activeScheduleTypes = [MinyanScheduleType.MOTZEI_SHABBAT];
        } else {
            activeScheduleTypes = [MinyanScheduleType.SHABBAT_DAY, MinyanScheduleType.MOTZEI_SHABBAT];
        }
        
        // *** שינוי: הוספת מנייני יום חול אם ההגדרה מופעלת ***
        if (currentRoomSettings.showWeekdayMinyanimOnShabbat) {
          activeScheduleTypes.add(MinyanScheduleType.REGULAR);
        }
        // *** סוף שינוי ***
        
    } else if (isErevShabbat) { // ערב שבת / ערב יום טוב
        if (sunsetToday != null && now.isAfter(sunsetToday)) {
            activeScheduleTypes = [MinyanScheduleType.SHABBAT_DAY, MinyanScheduleType.MOTZEI_SHABBAT];
        } else if (chatzosToday != null && now.isAfter(chatzosToday)) {
            activeScheduleTypes = [MinyanScheduleType.EREV_SHABBAT, MinyanScheduleType.MOTZEI_SHABBAT]; 
        } else {
            activeScheduleTypes = [MinyanScheduleType.REGULAR];
        }
    } else if (isSunday && sunsetToday != null && now.isBefore(sunsetToday)) { // יום ראשון (מוצאי שבת)
         activeScheduleTypes = [MinyanScheduleType.REGULAR, MinyanScheduleType.MOTZEI_SHABBAT];
    } else { // יום חול רגיל (כולל יום ראשון אחרי שקיעה)
        activeScheduleTypes = [MinyanScheduleType.REGULAR];
    }
    
    List<Minyan> todaysMinyanim = processedMinyanim.where((minyan) => activeScheduleTypes.contains(minyan.scheduleType)).toList();
    
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
      case MinyanScheduleType.EREV_SHABBAT: return 'מניינים מיוחדים'; 
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
    // *** שינוי: סדר ההצגה: REGULAR לפני SHABBAT_DAY ***
    final orderedTypes = [MinyanScheduleType.REGULAR, MinyanScheduleType.EREV_SHABBAT, MinyanScheduleType.SHABBAT_DAY, MinyanScheduleType.MOTZEI_SHABBAT];

    for (var type in orderedTypes) {
      if (_groupedMinyanim.containsKey(type) && _groupedMinyanim[type]!.isNotEmpty) {
        // *** שינוי: אם זה REGULAR בשבת, מציג כ"מנייני השבוע" במקום "תפילות ליום חול" ***
        String title;
        if (type == MinyanScheduleType.REGULAR && (_roomSettings?.showWeekdayMinyanimOnShabbat ?? false)) {
            title = 'מנייני השבוע';
        } else {
            title = _getScheduleTypeTitle(type);
        }
        
        minyanWidgets.add( Padding( padding: const EdgeInsets.fromLTRB(16, 20, 16, 8), child: Text( title, style: GoogleFonts.rubik(fontSize: 26, fontWeight: FontWeight.w500, color: primaryTextColor), textAlign: TextAlign.center, ), ), );
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
            Positioned(
              top: 8, right: 8,
              child: Icon(Icons.spa_outlined, color: primaryTextColor.withOpacity(0.4), size: 24),
            ),
            Positioned(
              top: 8, left: 8,
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.rotationY(pi),
                child: Icon(Icons.spa_outlined, color: primaryTextColor.withOpacity(0.4), size: 24),
              ),
            ),
            _groupedMinyanim.isEmpty 
              ? Center(child: Text('אין מניינים להיום', style: GoogleFonts.rubik(fontSize: 24, color: primaryTextColor.withOpacity(0.6)))) 
              : ListView( padding: const EdgeInsets.only(top: 8.0, bottom: 8.0), children: minyanWidgets, ),
          ],
        ),
      ), 
    );
  }

  Widget _buildMessagePanel(List<Message> messages) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7F7), // צבע אפור בהיר
        borderRadius: BorderRadius.circular(11),
      ),
      child: messages.isEmpty
          ? Center(child: Text('אין הודעות לחלונית זו', style: GoogleFonts.rubik(fontSize: 18, color: Colors.grey[400])))
          : MessageCarouselWidget(messages: messages),
    );
  }

  Widget _buildMessageLayout() {
    
    final panels = [
      _buildMessagePanel(_panelMessages[1] ?? []), // חלונית 1
      _buildMessagePanel(_panelMessages[2] ?? []), // חלונית 2
      if (_roomSettings!.activeMessagePanels >= 3) _buildMessagePanel(_panelMessages[3] ?? []), // חלונית 3
      if (_roomSettings!.activeMessagePanels == 4) _buildMessagePanel(_panelMessages[4] ?? []), // חלונית 4
    ];
    
    const double spacing = 12.0; 
    
    // אם יש רק חלונית 1 פעילה
    if (_roomSettings!.activeMessagePanels == 1) {
       return panels[0];
    }
    
    List<Widget> messageWidgets = [];

    // שורה עליונה (חלוניות 1 ו-2)
    if (_roomSettings!.activeMessagePanels >= 2) {
        messageWidgets.add(
            Expanded(
                child: Row(
                    children: [
                        Expanded(child: panels[1]), // חלונית 2 (שמאל עליון)
                        const SizedBox(width: spacing), 
                        Expanded(child: panels[0]), // חלונית 1 (ימין עליון)
                    ],
                ),
            ),
        );
        // מרווח בין השורות
        if (_roomSettings!.activeMessagePanels >= 3) {
            messageWidgets.add(const SizedBox(height: spacing));
        }
    }
    
    // שורה תחתונה (חלוניות 3 ו-4)
    if (_roomSettings!.activeMessagePanels == 3) {
       messageWidgets.add(
            Expanded(
                child: panels[2], // חלונית 3 (למטה)
            ),
       );
    } else if (_roomSettings!.activeMessagePanels == 4) {
       messageWidgets.add(
            Expanded(
                child: Row(
                     children: [
                        Expanded(child: panels[3]), // חלונית 4 (שמאל תחתון)
                        const SizedBox(width: spacing),
                        Expanded(child: panels[2]), // חלונית 3 (ימין תחתון)
                     ],
                ),
            ),
       );
    }
    
    return Column(
        children: messageWidgets,
    );
  }

  Widget _buildHeaderTitle({ required Color primaryTextColor, required Color accentColor }) {
    
    // שורה 1: כותרת ראשית (שעון, תאריך עברי מלא, שם החדר)
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 1. שעון (ימין למעלה)
              if (_roomSettings!.showClock) 
                const ClockWidget()
              else
                const SizedBox.shrink(),
                
              // 2. כותרת החדר (אמצע, גדולה)
              Text(
                widget.title,
                style: GoogleFonts.rubik(fontSize: 36, fontWeight: FontWeight.bold, color: primaryTextColor),
              ),
              
              // 3. תאריך עברי מלא (שמאל למעלה)
              if (_roomSettings!.showCalendar) 
                const HebcalWidget()
              else
                const SizedBox.shrink(),
            ],
          ),
        ),
        
        // שורה 2: המניין הבא (רצועה כחולה בהירה)
        Container(
          color: primaryTextColor.withOpacity(0.05), // רקע עדין
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 1. טקסט "אין מניינים קרובים" / מניין הבא
              Text(
                _nextMinyan == null ? 'אין מניינים קרובים' : 'המניין הבא:', 
                style: GoogleFonts.rubik(fontSize: 22, color: primaryTextColor.withOpacity(0.8))
              ),
                
              // 2. פרטי המניין
              if (_nextMinyan != null) ...[
                Text(
                  '${_nextMinyan!.minyan.name} - ${_nextMinyan!.minyan.roomName ?? 'חדר לא ידוע'}',
                  style: GoogleFonts.rubik(fontSize: 22, fontWeight: FontWeight.bold, color: accentColor),
                ),
                Text(
                  _nextMinyanCountdown,
                  style: GoogleFonts.tinos(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.red),
                  textDirection: ui.TextDirection.ltr,
                ),
              ] else
                const SizedBox.shrink(),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _roomSettings == null || _location == null) {
      return const Center(child: CircularProgressIndicator());
    }

    const columnColor = Color(0xFFE3F2FD); // Light Blue Background
    const cardBackgroundColor = Color(0xFFB3E5FC); // Lighter Blue Card
    const primaryTextColor = Color(0xFF37474F); // Dark Slate Text
    const accentColor = Color(0xFF0D47A1); // Deep Blue Accent

    final minyanimColumn = _buildMinyanimColumn(
      cardBackgroundColor: cardBackgroundColor,
      primaryTextColor: primaryTextColor,
      accentColor: accentColor,
    );

    final zmanimWidget = _roomSettings!.showZmanim && _location != null
        ? ZmanimWidget(location: _location!)
        : null;

    final hasSidebar = zmanimWidget != null;

    // הפריסה הראשית: ימין (מניינים) : מרכז (הודעות) : שמאל (זמנים)
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        backgroundColor: columnColor,
        body: Column(
          children: [
            // הכותרת הראשית + המניין הבא
            _buildHeaderTitle(primaryTextColor: primaryTextColor, accentColor: accentColor),
            
            // אזור התצוגה הראשי
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    // עמודה ימנית: מניינים
                    Expanded(
                      flex: 1, // טור צר
                      child: minyanimColumn,
                    ),
                    const SizedBox(width: 16),
                    
                    // עמודה מרכזית: הודעות (החלק הרחב)
                    Expanded(
                      flex: 2, // טור רחב
                      child: _buildMessageLayout(), // הודעות בלבד
                    ),
                    const SizedBox(width: 16),
                    
                    // עמודה שמאלית: זמנים
                    if (hasSidebar) // מציג רק אם ווידג'ט זמנים פעיל
                      Expanded(
                        flex: 1, // טור צר
                        child: Column(
                          children: [
                            if (zmanimWidget != null)
                               Expanded(
                                  flex: 1,
                                  child: Padding(
                                    padding: const EdgeInsets.only(bottom: 16.0),
                                    child: AspectRatio(
                                      aspectRatio: 1 / 1.5,
                                      child: zmanimWidget,
                                    ),
                                  ),
                                ),
                          ],
                        ),
                      )
                    else 
                      const SizedBox.shrink(),
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