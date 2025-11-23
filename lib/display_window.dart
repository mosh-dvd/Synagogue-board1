// lib/display_window.dart

import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:kosher_dart/kosher_dart.dart';
import 'package:provider/provider.dart';
import 'package:synagogue_display/data/data_provider.dart';
import 'package:synagogue_display/data/minyan_logic_helper.dart';
import 'package:synagogue_display/data/models.dart';
import 'package:synagogue_display/data/zmanim_helper.dart';
import 'package:synagogue_display/widgets/auto_scrolling_list_view.dart';
import 'package:synagogue_display/widgets/clock_widget.dart';
import 'package:synagogue_display/widgets/hebcal_widget.dart';
import 'package:synagogue_display/widgets/message_carousel_widget.dart';
import 'package:synagogue_display/widgets/zmanim_widget.dart';
import 'package:synagogue_display/widgets/large_clock_widget.dart';
import 'package:synagogue_display/widgets/gradient_text.dart';
import 'package:synagogue_display/widgets/glass_container.dart';
import 'package:synagogue_display/widgets/marquee_widget.dart';

// הרחבה כדי למצוא יום מיוחד
extension FirstWhereExt<T> on List<T> {
  T? firstWhereOrNull(bool Function(T) test) {
    for (var element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}

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
  DisplayTheme? _rawTheme;
  DisplayTheme? _effectiveTheme;
  
  // מפה המכילה את המניינים. אם יום מיוחד - המפתח יהיה SPECIAL_DATE, אחרת לפי סוגים רגילים.
  Map<MinyanScheduleType, Map<String, List<Minyan>>> _groupedMinyanim = {};
  
  // שם היום המיוחד אם יש (להצגה בכותרת)
  String? _specialDayName;

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
          final data = jsonDecode(call.arguments as String);
          _processPayload(data);
        }
      }
      return "";
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isLoading) {
      final dataProvider = Provider.of<DataProvider>(context, listen: false);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          final initialData = {
            'rooms': dataProvider.rooms.map((r) => r.toMap()).toList(),
            'minyanim': dataProvider.minyanim.map((m) => m.toBroadcastMap()).toList(),
            'messages': dataProvider.messages.map((m) => m.toMap()).toList(),
            'message_links': dataProvider.messageLinks,
            'location': dataProvider.location,
            'theme': dataProvider.theme.toMap(),
            // יש להוסיף את הלוחות המיוחדים לפיילוד גם אם הם לא שם כרגע, אבל
            // מכיוון שאנחנו בתוך ה-App באותו פרוסס (במקרה של פיתוח) או מקבלים נתונים, 
            // הכי טוב שהנתונים יגיעו מה-DataProvider ישירות אם זה החלון הראשי, או מהפיילוד.
            // כדי לפשט, נניח שה-DataProvider זמין גם בחלון זה (אם זה אותו Isolate)
            // אך ב-MultiWindow זה Isolate נפרד. לכן צריך להעביר גם את ה-SpecialSchedules בפיילוד.
            // כאן אני משתמש ב-DataProvider מקומי כי זה הדגמה, אך בייצור הפיילוד ב-admin_window צריך לכלול special_schedules.
          };
          
          // תיקון: אם זה חלון נפרד, הוא צריך לקבל את המידע. הוספתי לוגיקה שתמשוך מה-DB אם צריך, 
          // אבל לצורך התצוגה נסתמך על מה שיש.
          _processPayload(initialData); 
        }
      });
    }
  }
  
  DisplayTheme _calculateEffectiveTheme(DisplayTheme base, double scale) {
    if (scale == 1.0) return base;
    return DisplayTheme(
      id: base.id,
      scaffoldBackgroundColor: base.scaffoldBackgroundColor,
      minyanimColumnColor: base.minyanimColumnColor,
      zmanimColumnColor: base.zmanimColumnColor,
      messagePanelColor: base.messagePanelColor,
      primaryTextColor: base.primaryTextColor,
      accentColor: base.accentColor,
      borderColor: base.borderColor,
      highlightColor: base.highlightColor,
      primaryFont: base.primaryFont,
      secondaryFont: base.secondaryFont,
      borderWidth: base.borderWidth,
      titleFontSize: base.titleFontSize * scale,
      clockFontSize: base.clockFontSize * scale,
      largeClockFontSize: base.largeClockFontSize * scale,
      sectionTitleFontSize: base.sectionTitleFontSize * scale,
      bodyFontSize: base.bodyFontSize * scale,
      messageFontSize: base.messageFontSize * scale,
      dateFontSize: base.dateFontSize * scale,
      nextMinyanFontSize: base.nextMinyanFontSize * scale,
    );
  }

  Future<void> _processPayload(Map<String, dynamic> data) async {
    if (!mounted) return;

    final allRooms = (data['rooms'] as List).map((r) => Room.fromMap(r)).toList();
    final allMinyanim = (data['minyanim'] as List).map((m) => Minyan.fromMap(m)).toList();
    final allMessages = (data['messages'] as List).map((m) => Message.fromMap(m)).toList();
    final links = Map<String, dynamic>.from(data['message_links']);
    final location = data['location'] as String;
    final theme = DisplayTheme.fromMap(data['theme']);
    
    // שליפת הלוחות המיוחדים מה-DB ישירות כי זה אמין יותר בחלון נפרד
    // (בפרודקשן כדאי להעביר בפיילוד)
    final dataProvider = Provider.of<DataProvider>(context, listen: false);
    await dataProvider.fetchAllData(); 
    final specialSchedules = dataProvider.specialSchedules;
    final now = dataProvider.simulationDate;

    final roomData = allRooms.firstWhere(
        (r) => r.id == widget.roomId, 
        orElse: () => Room(id: -1, name: 'חדר לא נמצא')
    );
    
    if (roomData.id == -1) {
      if(mounted) setState(() => _isLoading = true);
      return;
    }
    final currentRoomSettings = roomData;
    
    final zmanimDateTimes = ZmanimHelper.getZmanimDateTimes(location, date: now);
    final processedMinyanim = allMinyanim.map((minyan) {
      if (minyan.timeType == MinyanTimeType.RELATIVE && minyan.relativeZman != null) {
        final zmanTime = zmanimDateTimes[minyan.relativeZman!];
        if (zmanTime != null) {
          final calculatedTime = zmanTime.add(Duration(minutes: minyan.relativeOffsetMinutes ?? 0));
          return Minyan( 
            id: minyan.id, 
            name: minyan.name, 
            roomId: minyan.roomId, 
            roomName: minyan.roomName, 
            scheduleType: minyan.scheduleType, 
            specialScheduleId: minyan.specialScheduleId,
            timeType: MinyanTimeType.FIXED, 
            time: DateFormat('HH:mm').format(calculatedTime) 
          );
        }
      }
      return minyan;
    }).where((m) => m.time != null).toList();

    // 1. בדיקה אם היום הוא יום מיוחד
    SpecialSchedule? todaySpecial = specialSchedules.firstWhereOrNull(
        (s) => s.date.day == now.day && s.date.month == now.month && s.date.year == now.year
    );

    List<Minyan> todaysMinyanim;
    String? specialName;

    if (todaySpecial != null) {
      // אם היום מיוחד - טוענים רק מניינים שמשויכים ליום הזה
      todaysMinyanim = processedMinyanim.where((m) => m.specialScheduleId == todaySpecial.id).toList();
      specialName = todaySpecial.name;
    } else {
      // אם יום רגיל - לוגיקה רגילה
      final jewishCalendar = JewishCalendar.fromDateTime(now);
      final sunsetToday = zmanimDateTimes[RelativeZman.sunset];
      final chatzosToday = zmanimDateTimes[RelativeZman.chatzos];
      List<MinyanScheduleType> activeScheduleTypes = [];

      final isShabbatOrYomTov = jewishCalendar.getDayOfWeek() == 7 || jewishCalendar.isYomTov();
      final isErevShabbatOrYomTov = jewishCalendar.getDayOfWeek() == 6 || jewishCalendar.isErevYomTov();
      
      if (isShabbatOrYomTov) { 
          if (sunsetToday != null && now.isAfter(sunsetToday)) {
              activeScheduleTypes = [MinyanScheduleType.MOTZEI_SHABBAT];
          } else {
              activeScheduleTypes = [MinyanScheduleType.SHABBAT_DAY, MinyanScheduleType.MOTZEI_SHABBAT];
          }
          if (currentRoomSettings.showWeekdayMinyanimOnShabbat) {
            activeScheduleTypes.add(MinyanScheduleType.REGULAR);
          }
      } else if (isErevShabbatOrYomTov) { 
          if (sunsetToday != null && now.isAfter(sunsetToday)) {
              activeScheduleTypes = [MinyanScheduleType.SHABBAT_DAY, MinyanScheduleType.MOTZEI_SHABBAT];
          } else if (chatzosToday != null && now.isAfter(chatzosToday)) {
              activeScheduleTypes = [MinyanScheduleType.EREV_SHABBAT, MinyanScheduleType.MOTZEI_SHABBAT]; 
          } else {
              activeScheduleTypes = [MinyanScheduleType.REGULAR];
          }
      } else { 
          activeScheduleTypes = [MinyanScheduleType.REGULAR, MinyanScheduleType.MOTZEI_SHABBAT]; 
      }

      // סינון לפי סוג וגם וידוא שאין להם ID מיוחד (כדי לא לערבב מניינים מיוחדים בימים רגילים)
      todaysMinyanim = processedMinyanim.where((minyan) => 
          activeScheduleTypes.contains(minyan.scheduleType) && minyan.specialScheduleId == null
      ).toList();
    }
    
    todaysMinyanim.sort((a, b) => a.time!.compareTo(b.time!));
    
    List<Minyan> filteredMinyanim = (currentRoomSettings.displayMode == MinyanDisplayMode.ALL) ? todaysMinyanim : todaysMinyanim.where((m) => m.roomId == widget.roomId).toList();
    
    Map<MinyanScheduleType, Map<String, List<Minyan>>> categorizedMinyanim = {};
    
    for (final minyan in filteredMinyanim) {
      // אם זה יום מיוחד, נקבץ הכל תחת "SPECIAL_DATE" או נשאיר את הסוג המקורי אם רוצים הפרדה
      // אבל כרגע כל המניינים המיוחדים מסומנים כ-SPECIAL_DATE במודל אם הם נוצרו דרך הממשק החדש, 
      // או ששמרנו את הסוג המקורי (REGULAR וכו') אבל עם special_schedule_id.
      // כדי להציג אותם יפה, נשתמש ב-ScheduleType שלהם.
      
      final scheduleType = todaySpecial != null ? MinyanScheduleType.SPECIAL_DATE : minyan.scheduleType;
      final prayerName = minyan.name.trim();
      
      if (categorizedMinyanim[scheduleType] == null) categorizedMinyanim[scheduleType] = {};
      if (categorizedMinyanim[scheduleType]![prayerName] == null) categorizedMinyanim[scheduleType]![prayerName] = [];
      categorizedMinyanim[scheduleType]![prayerName]!.add(minyan);
    }
    
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
    
    if (mounted) {
      setState(() {
        _roomSettings = currentRoomSettings;
        _rawTheme = theme;
        _effectiveTheme = _calculateEffectiveTheme(theme, currentRoomSettings.fontScale);
        _groupedMinyanim = categorizedMinyanim;
        _panelMessages = categorizedMessages;
        _location = location;
        _specialDayName = specialName;
        _isLoading = false;
      });
    }

    _updateNextMinyan(allMinyanim, location);
  }

  @override
  void dispose() {
    _nextMinyanTimer?.cancel();
    super.dispose();
  }

  void _startNextMinyanTimer() {
    _nextMinyanTimer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      _tick();
    });
  }

  void _updateNextMinyan(List<Minyan> allMinyanim, String location) {
    if (!mounted) return;
    
    final foundMinyan = MinyanLogicHelper.findNextMinyan(allMinyanim, location);
    if (mounted && (foundMinyan?.minyan.id != _nextMinyan?.minyan.id)) {
      setState(() {
        _nextMinyan = foundMinyan;
      });
    }
  }

  void _tick() {
    if (!mounted) return;
    final now = DateTime.now();
    if (_nextMinyan == null) {
      if (now.second % 30 == 0) {
        final dataProvider = Provider.of<DataProvider>(context, listen: false);
        _updateNextMinyan(dataProvider.minyanim, dataProvider.location);
      }
      return;
    }
    final difference = _nextMinyan!.dateTime.difference(now); 
    if (difference.isNegative) {
      final dataProvider = Provider.of<DataProvider>(context, listen: false);
      _updateNextMinyan(dataProvider.minyanim, dataProvider.location);
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

  String _getScheduleTypeTitle(MinyanScheduleType type) {
    if (_specialDayName != null && type == MinyanScheduleType.SPECIAL_DATE) {
      return 'זמני תפילות - $_specialDayName';
    }
    switch (type) {
      case MinyanScheduleType.REGULAR: return 'תפילות ליום חול';
      case MinyanScheduleType.EREV_SHABBAT: return 'מניינים מיוחדים'; 
      case MinyanScheduleType.SHABBAT_DAY: return 'תפילות שבת וחג';
      case MinyanScheduleType.MOTZEI_SHABBAT: return 'תפילות למוצאי שבת';
      case MinyanScheduleType.SPECIAL_DATE: return 'זמנים מיוחדים';
    }
  }
  
  Widget _buildTickerContent(DisplayTheme theme) {
    List<Widget> tickerItems = [];
    final textStyle = GoogleFonts.getFont(theme.primaryFont, fontSize: theme.dateFontSize, color: theme.primaryTextColor);
    final highlightStyle = GoogleFonts.getFont(theme.primaryFont, fontSize: theme.dateFontSize, fontWeight: FontWeight.bold, color: theme.highlightColor);

    tickerItems.add(const Text("   ")); 
    tickerItems.add(Theme(
        data: ThemeData(textTheme: TextTheme(bodyMedium: TextStyle(fontSize: theme.dateFontSize, color: theme.primaryTextColor))),
        child: const HebcalWidget()
    ));
    
    tickerItems.add(const SizedBox(width: 50));
    tickerItems.add(Text(" | ", style: textStyle));
    tickerItems.add(const SizedBox(width: 50));

    if (_nextMinyan != null) {
      tickerItems.add(Text("המניין הבא: ", style: textStyle));
      tickerItems.add(Text("${_nextMinyan!.minyan.name} בשעה ${DateFormat('HH:mm').format(_nextMinyan!.dateTime)}", style: highlightStyle));
      tickerItems.add(const SizedBox(width: 20));
      tickerItems.add(Text("בעוד: ", style: textStyle));
      tickerItems.add(Text(_nextMinyanCountdown, style: highlightStyle.copyWith(color: Colors.redAccent, fontFamily: theme.secondaryFont)));
    } else {
      tickerItems.add(Text("אין מניינים קרובים", style: textStyle));
    }
    
    tickerItems.add(const SizedBox(width: 100));

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: tickerItems,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _roomSettings == null || _location == null || _effectiveTheme == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final theme = _effectiveTheme!; 
    final backgroundColor = theme.scaffoldBackgroundColor;

    final minyanimColumn = _buildMinyanimColumn();
    final zmanimWidget = _roomSettings!.showZmanim && _location != null
        ? ZmanimWidget(location: _location!, showBorders: false)
        : null;
    final hasSidebar = zmanimWidget != null;

    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        backgroundColor: backgroundColor, 
        body: Column(
          children: [
            _buildHeaderTitle(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 1,
                      child: GlassContainer(
                        color: theme.minyanimColumnColor,
                        borderColor: theme.borderColor,
                        opacity: 0.2,
                        child: minyanimColumn
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      flex: 2,
                      child: _buildMessageLayout(),
                    ),
                    const SizedBox(width: 24),
                    if (hasSidebar)
                      Expanded(
                        flex: 1,
                        child: GlassContainer(
                          color: theme.zmanimColumnColor,
                          borderColor: theme.borderColor,
                          opacity: 0.2,
                          child: zmanimWidget!
                        ),
                      )
                    else 
                      const SizedBox.shrink(),
                  ],
                ),
              ),
            ),
            Container(
              width: double.infinity,
              height: theme.dateFontSize * 3.5,
              color: theme.primaryTextColor.withOpacity(0.1),
              alignment: Alignment.center,
              child: MarqueeWidget(
                child: _buildTickerContent(theme),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMinyanimColumn() {
    List<Widget> minyanWidgets = [];
    final theme = _effectiveTheme!;
    
    final Color titleColor = theme.primaryTextColor;
    final Color subTitleColor = theme.primaryTextColor.withOpacity(0.8);
    final Color timeColor = theme.accentColor; 
    final Color highlightColor = theme.highlightColor.withOpacity(0.2); 

    final now = DateTime.now();
    final jewishCalendar = JewishCalendar.fromDateTime(now);
    final isShabbatOrChag = jewishCalendar.getDayOfWeek() == 7 || jewishCalendar.isYomTov();
    
    const weekdayPrayerOrder = ['שחרית', 'מנחה', 'ערבית'];
    const shabbatPrayerOrder = ['ערבית', 'שחרית', 'מנחה'];
    
    List<MinyanScheduleType> orderedTypes;
    
    if (_specialDayName != null) {
      // אם יום מיוחד, מציגים רק אותו
      orderedTypes = [MinyanScheduleType.SPECIAL_DATE];
    } else if (isShabbatOrChag && (_roomSettings?.showWeekdayMinyanimOnShabbat ?? false)) {
        orderedTypes = [MinyanScheduleType.SHABBAT_DAY, MinyanScheduleType.REGULAR, MinyanScheduleType.MOTZEI_SHABBAT, MinyanScheduleType.EREV_SHABBAT];
    } else {
        orderedTypes = [MinyanScheduleType.REGULAR, MinyanScheduleType.EREV_SHABBAT, MinyanScheduleType.SHABBAT_DAY, MinyanScheduleType.MOTZEI_SHABBAT];
    }

    for (var type in orderedTypes) {
      if (_groupedMinyanim.containsKey(type) && _groupedMinyanim[type]!.isNotEmpty) {
        
        String title = _getScheduleTypeTitle(type);
        if (type == MinyanScheduleType.REGULAR && isShabbatOrChag && (_roomSettings?.showWeekdayMinyanimOnShabbat ?? false)) {
            title = 'מנייני השבוע';
        }
        
        minyanWidgets.add( Padding( padding: const EdgeInsets.fromLTRB(16, 20, 16, 8), child: Text( title, style: GoogleFonts.getFont(theme.primaryFont, fontSize: theme.sectionTitleFontSize, fontWeight: FontWeight.w300, color: titleColor), textAlign: TextAlign.center, ), ), );
        minyanWidgets.add(Divider(color: titleColor.withOpacity(0.3), indent: 40, endIndent: 40, thickness: 1));
        
        final prayerGroups = _groupedMinyanim[type]!.entries.toList();

        final prayerOrder = (type == MinyanScheduleType.SHABBAT_DAY || type == MinyanScheduleType.EREV_SHABBAT)
            ? shabbatPrayerOrder
            : weekdayPrayerOrder;

        prayerGroups.sort((a, b) {
          int indexA = prayerOrder.indexOf(a.key);
          int indexB = prayerOrder.indexOf(b.key);
          if (indexA == -1) indexA = prayerOrder.length;
          if (indexB == -1) indexB = prayerOrder.length;
          return indexA.compareTo(indexB);
        });

        for (int i = 0; i < prayerGroups.length; i++) {
          final prayerName = prayerGroups[i].key;
          final minyanList = prayerGroups[i].value;

          minyanWidgets.add( Padding( padding: const EdgeInsets.fromLTRB(16, 12, 16, 4), child: Text( prayerName, style: GoogleFonts.getFont(theme.primaryFont, fontSize: theme.sectionTitleFontSize * 0.85, fontWeight: FontWeight.w500, color: subTitleColor), textAlign: TextAlign.center, ), ), );
          
          for (var minyan in minyanList) {
            bool isNext = _nextMinyan?.minyan.id == minyan.id;

            Widget minyanRow = Padding( 
              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 24.0), 
              child: Row( 
                mainAxisAlignment: MainAxisAlignment.spaceBetween, 
                children: [ 
                  Text( minyan.roomName ?? 'חדר לא ידוע', style: GoogleFonts.getFont(theme.primaryFont, fontSize: theme.bodyFontSize * 0.9, color: isNext ? theme.highlightColor : subTitleColor.withOpacity(0.7)), textAlign: TextAlign.right, ), 
                  Text( minyan.time ?? '--:--', style: GoogleFonts.getFont(theme.secondaryFont, fontSize: theme.bodyFontSize * 1.3, fontWeight: FontWeight.bold, color: isNext ? theme.highlightColor : timeColor), textAlign: TextAlign.left, textDirection: ui.TextDirection.ltr, ), 
                ], 
              ), 
            );

            if (isNext) {
               minyanWidgets.add(Container(
                 decoration: BoxDecoration(
                   color: highlightColor,
                   borderRadius: BorderRadius.circular(8),
                   border: Border.all(color: theme.highlightColor, width: 1),
                 ),
                 child: minyanRow,
               ));
            } else {
               minyanWidgets.add(minyanRow);
            }
          }
          
          if (i < prayerGroups.length - 1) {
            minyanWidgets.add(const SizedBox(height: 16));
          }
        }
      }
    }
    
    return _groupedMinyanim.isEmpty 
      ? Center(child: Text('אין מניינים להיום', style: GoogleFonts.getFont(theme.primaryFont, fontSize: theme.bodyFontSize, color: subTitleColor))) 
      : AutoScrollingListView(
          padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
          children: minyanWidgets,
        );
  }

  // ... (שאר הפונקציות כמו _buildMessagePanel, _buildMessageLayout, _buildHeaderTitle נשארות זהות לקובץ המקורי)
  Widget _buildMessagePanel(List<Message> messages) {
    final theme = _effectiveTheme!;
    return GlassContainer(
      color: theme.messagePanelColor,
      borderColor: theme.borderColor,
      opacity: 0.5,
      child: messages.isEmpty
          ? Center(child: Text('אין הודעות לחלונית זו', style: GoogleFonts.getFont(theme.primaryFont, fontSize: theme.bodyFontSize, color: theme.primaryTextColor.withOpacity(0.5))))
          : MessageCarouselWidget(messages: messages),
    );
  }

  Widget _buildMessageLayout() {
    final bool isClockInMainPanel = _roomSettings!.showClock && _roomSettings!.clockPosition == ClockPosition.mainPanel;
    const double spacing = 24.0;

    Widget messagePanelsWidget;
    
    final panels = [
      _buildMessagePanel(_panelMessages[1] ?? []),
      _buildMessagePanel(_panelMessages[2] ?? []),
      if (_roomSettings!.activeMessagePanels >= 3) _buildMessagePanel(_panelMessages[3] ?? []),
      if (_roomSettings!.activeMessagePanels == 4) _buildMessagePanel(_panelMessages[4] ?? []),
    ];

    if (_roomSettings!.activeMessagePanels == 1) {
      messagePanelsWidget = panels[0];
    } else {
      List<Widget> messageRows = [];
      if (_roomSettings!.activeMessagePanels >= 2) {
        messageRows.add(
          Expanded(
            child: Row(
              children: [
                Expanded(child: panels[1]),
                const SizedBox(width: spacing),
                Expanded(child: panels[0]),
              ],
            ),
          ),
        );
      }
      if (_roomSettings!.activeMessagePanels >= 3) {
        messageRows.add(const SizedBox(height: spacing));
      }
      if (_roomSettings!.activeMessagePanels == 3) {
        messageRows.add(Expanded(child: panels[2]));
      } else if (_roomSettings!.activeMessagePanels == 4) {
        messageRows.add(
          Expanded(
            child: Row(
              children: [
                Expanded(child: panels[3]),
                const SizedBox(width: spacing),
                Expanded(child: panels[2]),
              ],
            ),
          ),
        );
      }
      messagePanelsWidget = Column(children: messageRows);
    }
    
    if (isClockInMainPanel) {
      return Column(
        children: [
          Expanded(
            flex: 1,
            child: GlassContainer(
              color: _effectiveTheme!.minyanimColumnColor,
              borderColor: _effectiveTheme!.borderColor,
              opacity: 0.2,
              child: Center(
                child: LargeClockWidget(roomSettings: _roomSettings!),
              ),
            ),
          ),
          const SizedBox(height: spacing),
          Expanded(
            flex: 2,
            child: messagePanelsWidget,
          ),
        ],
      );
    } 
    else {
      return messagePanelsWidget;
    }
  }

  Widget _buildHeaderTitle() {
    final theme = _effectiveTheme!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (_roomSettings!.showClock && _roomSettings!.clockPosition == ClockPosition.header) 
             Theme(
                data: ThemeData(
                  textTheme: TextTheme(
                    bodyMedium: TextStyle(color: theme.primaryTextColor)
                  )
                ), 
                child: const ClockWidget()
             )
          else
            const SizedBox(width: 80),
            
          GradientText(
            widget.title,
            style: GoogleFonts.getFont(theme.primaryFont, fontSize: theme.titleFontSize, fontWeight: FontWeight.w300),
            gradient: LinearGradient(
              colors: [
                theme.highlightColor, 
                theme.primaryTextColor, 
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          
          const SizedBox(width: 80),
        ],
      ),
    );
  }
}