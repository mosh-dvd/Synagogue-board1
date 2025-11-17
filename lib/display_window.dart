import 'dart:async';
import 'dart:convert';
import 'dart:math';
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
  DisplayTheme? _theme;
  Map<MinyanScheduleType, Map<String, List<Minyan>>> _groupedMinyanim = {};
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
          };
          _processPayload(initialData);
        }
      });
    }
  }
  
  void _processPayload(Map<String, dynamic> data) {
    if (!mounted) return;

    final allRooms = (data['rooms'] as List).map((r) => Room.fromMap(r)).toList();
    final allMinyanim = (data['minyanim'] as List).map((m) => Minyan.fromMap(m)).toList();
    final allMessages = (data['messages'] as List).map((m) => Message.fromMap(m)).toList();
    final links = Map<String, dynamic>.from(data['message_links']);
    final location = data['location'] as String;
    final theme = DisplayTheme.fromMap(data['theme']);

    final now = DateTime.now();

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
          return Minyan( id: minyan.id, name: minyan.name, roomId: minyan.roomId, roomName: minyan.roomName, scheduleType: minyan.scheduleType, timeType: MinyanTimeType.FIXED, time: DateFormat('HH:mm').format(calculatedTime) );
        }
      }
      return minyan;
    }).where((m) => m.time != null).toList();

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

    List<Minyan> todaysMinyanim = processedMinyanim.where((minyan) => activeScheduleTypes.contains(minyan.scheduleType)).toList();
    
    todaysMinyanim.sort((a, b) => a.time!.compareTo(b.time!));
    
    List<Minyan> filteredMinyanim = (currentRoomSettings.displayMode == MinyanDisplayMode.ALL) ? todaysMinyanim : todaysMinyanim.where((m) => m.roomId == widget.roomId).toList();
    
    Map<MinyanScheduleType, Map<String, List<Minyan>>> categorizedMinyanim = {};
    for (final minyan in filteredMinyanim) {
      final scheduleType = minyan.scheduleType;
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
        _theme = theme;
        _groupedMinyanim = categorizedMinyanim;
        _panelMessages = categorizedMessages;
        _location = location;
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
    switch (type) {
      case MinyanScheduleType.REGULAR: return 'תפילות ליום חול';
      case MinyanScheduleType.EREV_SHABBAT: return 'מניינים מיוחדים'; 
      case MinyanScheduleType.SHABBAT_DAY: return 'תפילות שבת וחג';
      case MinyanScheduleType.MOTZEI_SHABBAT: return 'תפילות למוצאי שבת';
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading || _roomSettings == null || _location == null || _theme == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final theme = _theme!;

    final minyanimColumn = _buildMinyanimColumn();
    final zmanimWidget = _roomSettings!.showZmanim && _location != null
        ? ZmanimWidget(location: _location!, showBorders: _roomSettings!.showBorders)
        : null;
    final hasSidebar = zmanimWidget != null;

    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Column(
          children: [
            _buildHeaderTitle(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: minyanimColumn,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: _buildMessageLayout(),
                    ),
                    const SizedBox(width: 16),
                    if (hasSidebar)
                      Expanded(
                        flex: 1,
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

  Widget _buildMinyanimColumn() {
    List<Widget> minyanWidgets = [];
    final theme = _theme!;
    
    final now = DateTime.now();
    final jewishCalendar = JewishCalendar.fromDateTime(now);
    final isShabbatOrChag = jewishCalendar.getDayOfWeek() == 7 || jewishCalendar.isYomTov();
    
    const weekdayPrayerOrder = ['שחרית', 'מנחה', 'ערבית'];
    const shabbatPrayerOrder = ['ערבית', 'שחרית', 'מנחה'];
    
    List<MinyanScheduleType> orderedTypes;
    if (isShabbatOrChag && (_roomSettings?.showWeekdayMinyanimOnShabbat ?? false)) {
        orderedTypes = [MinyanScheduleType.SHABBAT_DAY, MinyanScheduleType.REGULAR, MinyanScheduleType.MOTZEI_SHABBAT, MinyanScheduleType.EREV_SHABBAT];
    } else {
        orderedTypes = [MinyanScheduleType.REGULAR, MinyanScheduleType.EREV_SHABBAT, MinyanScheduleType.SHABBAT_DAY, MinyanScheduleType.MOTZEI_SHABBAT];
    }

    for (var type in orderedTypes) {
      if (_groupedMinyanim.containsKey(type) && _groupedMinyanim[type]!.isNotEmpty) {
        
        String title;
        if (type == MinyanScheduleType.REGULAR && isShabbatOrChag && (_roomSettings?.showWeekdayMinyanimOnShabbat ?? false)) {
            title = 'מנייני השבוע';
        } else {
            title = _getScheduleTypeTitle(type);
        }
        
        minyanWidgets.add( Padding( padding: const EdgeInsets.fromLTRB(16, 20, 16, 8), child: Text( title, style: GoogleFonts.getFont(theme.primaryFont, fontSize: 26, fontWeight: FontWeight.w500, color: theme.primaryTextColor), textAlign: TextAlign.center, ), ), );
        minyanWidgets.add(Divider(color: theme.primaryTextColor.withOpacity(0.1), indent: 30, endIndent: 30, thickness: 1));
        
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

          minyanWidgets.add( Padding( padding: const EdgeInsets.fromLTRB(16, 12, 16, 4), child: Text( prayerName, style: GoogleFonts.getFont(theme.primaryFont, fontSize: 24, fontWeight: FontWeight.w500, color: theme.primaryTextColor.withOpacity(0.9)), textAlign: TextAlign.center, ), ), );
          for (var minyan in minyanList) {
            minyanWidgets.add( Padding( padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 24.0), child: Row( mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [ Text( minyan.roomName ?? 'חדר לא ידוע', style: GoogleFonts.getFont(theme.primaryFont, fontSize: 18, color: theme.primaryTextColor.withOpacity(0.7)), textAlign: TextAlign.right, ), Text( minyan.time ?? '--:--', style: GoogleFonts.getFont(theme.secondaryFont, fontSize: 30, fontWeight: FontWeight.bold, color: theme.accentColor), textAlign: TextAlign.left, textDirection: ui.TextDirection.ltr, ), ], ), ), );
          }
          
          if (i < prayerGroups.length - 1) {
            minyanWidgets.add(
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 60.0),
                child: Row(
                  children: [
                    Expanded(child: Divider(color: theme.primaryTextColor.withOpacity(0.2))),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      child: Icon(Icons.spa_outlined, color: theme.primaryTextColor.withOpacity(0.6), size: 18),
                    ),
                    Expanded(child: Divider(color: theme.primaryTextColor.withOpacity(0.2))),
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
        color: theme.minyanimColumnColor, 
        borderRadius: BorderRadius.circular(16), 
        border: _roomSettings!.showBorders
            ? Border.all(color: theme.borderColor, width: theme.borderWidth)
            : null,
      ), 
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Positioned(
              top: 8, right: 8,
              child: Icon(Icons.spa_outlined, color: theme.primaryTextColor.withOpacity(0.4), size: 24),
            ),
            Positioned(
              top: 8, left: 8,
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.rotationY(pi),
                child: Icon(Icons.spa_outlined, color: theme.primaryTextColor.withOpacity(0.4), size: 24),
              ),
            ),
            _groupedMinyanim.isEmpty 
              ? Center(child: Text('אין מניינים להיום', style: GoogleFonts.getFont(theme.primaryFont, fontSize: 24, color: theme.primaryTextColor.withOpacity(0.6)))) 
              : AutoScrollingListView(
                  padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                  children: minyanWidgets,
                ),
          ],
        ),
      ), 
    );
  }

  Widget _buildMessagePanel(List<Message> messages) {
    final theme = _theme!;
    return Container(
      decoration: BoxDecoration(
        color: theme.messagePanelColor,
        borderRadius: BorderRadius.circular(11),
        border: _roomSettings!.showBorders
            ? Border.all(color: theme.borderColor, width: theme.borderWidth)
            : null,
      ),
      child: messages.isEmpty
          ? Center(child: Text('אין הודעות לחלונית זו', style: GoogleFonts.getFont(theme.primaryFont, fontSize: 18, color: Colors.grey[400])))
          : MessageCarouselWidget(messages: messages),
    );
  }

  Widget _buildMessageLayout() {
    final bool isClockInMainPanel = _roomSettings!.showClock && _roomSettings!.clockPosition == ClockPosition.mainPanel;

    final panels = [
      isClockInMainPanel ? LargeClockWidget(roomSettings: _roomSettings!) : _buildMessagePanel(_panelMessages[1] ?? []),
      _buildMessagePanel(_panelMessages[2] ?? []),
      if (_roomSettings!.activeMessagePanels >= 3) _buildMessagePanel(_panelMessages[3] ?? []),
      if (_roomSettings!.activeMessagePanels == 4) _buildMessagePanel(_panelMessages[4] ?? []),
    ];
    
    const double spacing = 12.0; 
    
    if (_roomSettings!.activeMessagePanels == 1) {
       return panels[0];
    }
    
    List<Widget> messageWidgets = [];

    if (_roomSettings!.activeMessagePanels >= 2) {
        messageWidgets.add(
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
        if (_roomSettings!.activeMessagePanels >= 3) {
            messageWidgets.add(const SizedBox(height: spacing));
        }
    }
    
    if (_roomSettings!.activeMessagePanels == 3) {
       messageWidgets.add(
            Expanded(
                child: panels[2],
            ),
       );
    } else if (_roomSettings!.activeMessagePanels == 4) {
       messageWidgets.add(
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
    
    return Column(
        children: messageWidgets,
    );
  }

  Widget _buildHeaderTitle() {
    final theme = _theme!;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (_roomSettings!.showClock && _roomSettings!.clockPosition == ClockPosition.header) 
                const ClockWidget()
              else
                const SizedBox(width: 80),
                
              Text(
                widget.title,
                style: GoogleFonts.getFont(theme.primaryFont, fontSize: 36, fontWeight: FontWeight.bold, color: theme.highlightColor),
              ),
              
              if (_roomSettings!.showCalendar) 
                const HebcalWidget()
              else
                const SizedBox(width: 150),
            ],
          ),
        ),
        
        Container(
          color: theme.primaryTextColor.withOpacity(0.05),
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 20.0),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _nextMinyan == null ? 'אין מניינים קרובים' : 'המניין הבא:', 
                  style: GoogleFonts.getFont(theme.primaryFont, fontSize: 22, color: theme.primaryTextColor.withOpacity(0.8))
                ),
                const SizedBox(width: 12),
                if (_nextMinyan != null) ...[
                  RichText(
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    text: TextSpan(
                      style: GoogleFonts.getFont(theme.primaryFont, fontSize: 22, color: theme.accentColor),
                      children: [
                        TextSpan(
                          text: '${_nextMinyan!.minyan.name} ',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const TextSpan(text: 'בשעה '),
                        TextSpan(
                          text: '${DateFormat('HH:mm').format(_nextMinyan!.dateTime)} ',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const TextSpan(text: 'ב'),
                        TextSpan(
                          text: '${_nextMinyan!.minyan.roomName ?? 'חדר לא ידוע'}',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'בעוד:',
                    style: GoogleFonts.getFont(theme.primaryFont, fontSize: 22, color: theme.primaryTextColor.withOpacity(0.8)),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _nextMinyanCountdown,
                    style: GoogleFonts.getFont(theme.secondaryFont, fontSize: 24, fontWeight: FontWeight.bold, color: Colors.red.shade700),
                    textDirection: ui.TextDirection.ltr,
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}