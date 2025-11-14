// lib/data/models.dart (קובץ מלא)
import 'package:synagogue_display/data/zmanim_helper.dart';

enum MinyanDisplayMode {
  THIS_ROOM_ONLY,
  ALL
}

class Room {
  final int? id;
  final String name;
  final bool showClock;
  final bool showCalendar;
  final bool showZmanim;
  final MinyanDisplayMode displayMode;
  final int activeMessagePanels;
  final bool isDisplayActive;
  final bool showWeekdayMinyanimOnShabbat; // *** שינוי: שדה חדש ***

  Room({
    this.id,
    required this.name,
    this.showClock = true,
    this.showCalendar = true,
    this.showZmanim = false,
    this.displayMode = MinyanDisplayMode.THIS_ROOM_ONLY,
    this.activeMessagePanels = 1,
    this.isDisplayActive = true,
    this.showWeekdayMinyanimOnShabbat = false, // *** שינוי: ערך ברירת מחדל ***
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'show_clock': showClock ? 1 : 0,
      'show_calendar': showCalendar ? 1 : 0,
      'show_zmanim': showZmanim ? 1 : 0,
      'display_mode': displayMode.name,
      'active_message_panels': activeMessagePanels,
      'is_display_active': isDisplayActive ? 1 : 0,
      'show_weekday_minyanim_on_shabbat': showWeekdayMinyanimOnShabbat ? 1 : 0, // *** שינוי: הוספה למפה ***
    };
  }

  factory Room.fromMap(Map<String, dynamic> map) {
    return Room(
      id: map['id'],
      name: map['name'],
      showClock: map['show_clock'] == 1,
      showCalendar: map['show_calendar'] == 1,
      showZmanim: map['show_zmanim'] == 1,
      displayMode: MinyanDisplayMode.values.firstWhere(
        (e) => e.name == map['display_mode'],
        orElse: () => MinyanDisplayMode.THIS_ROOM_ONLY
      ),
      activeMessagePanels: map['active_message_panels'] ?? 1,
      isDisplayActive: map['is_display_active'] == null ? true : map['is_display_active'] == 1,
      showWeekdayMinyanimOnShabbat: map['show_weekday_minyanim_on_shabbat'] == null ? false : map['show_weekday_minyanim_on_shabbat'] == 1, // *** שינוי: המרה מהמפה ***
    );
  }
}

enum MinyanScheduleType {
  REGULAR,
  SHABBAT_DAY,
  MOTZEI_SHABBAT,
  EREV_SHABBAT
}

enum MinyanTimeType { FIXED, RELATIVE }

class Minyan {
  final int? id;
  final String name;
  final int roomId;
  final String? roomName;
  final MinyanScheduleType scheduleType;
  
  final MinyanTimeType timeType;
  final String? time;
  final RelativeZman? relativeZman;
  final int? relativeOffsetMinutes;


  Minyan({
    this.id,
    required this.name,
    required this.roomId,
    this.roomName,
    this.scheduleType = MinyanScheduleType.REGULAR,
    required this.timeType,
    this.time,
    this.relativeZman,
    this.relativeOffsetMinutes,
  });

  Map<String, dynamic> toDbMap() {
    return {
      'id': id,
      'name': name,
      'room_id': roomId,
      'schedule_type': scheduleType.name,
      'time_type': timeType.name,
      'time': time,
      'relative_zman': relativeZman?.name,
      'relative_offset_minutes': relativeOffsetMinutes,
    };
  }

  Map<String, dynamic> toBroadcastMap() {
    return {
      'id': id,
      'name': name,
      'room_id': roomId,
      'roomName': roomName,
      'schedule_type': scheduleType.name,
      'time_type': timeType.name,
      'time': time,
      'relative_zman': relativeZman?.name,
      'relative_offset_minutes': relativeOffsetMinutes,
    };
  }

  factory Minyan.fromMap(Map<String, dynamic> map) {
    return Minyan(
      id: map['id'],
      name: map['name'],
      roomId: map['room_id'],
      roomName: map['roomName'],
      scheduleType: MinyanScheduleType.values.firstWhere((e) => e.name == map['schedule_type'], orElse: () => MinyanScheduleType.REGULAR),
      timeType: MinyanTimeType.values.firstWhere((e) => e.name == map['time_type'], orElse: () => MinyanTimeType.FIXED),
      time: map['time'],
      relativeZman: map['relative_zman'] != null ? RelativeZman.values.firstWhere((e) => e.name == map['relative_zman'], orElse: () => RelativeZman.sunrise) : null,
      relativeOffsetMinutes: map['relative_offset_minutes'],
    );
  }
}

enum MessageType { TEXT, IMAGE, PDF }

class Message {
  final int? id;
  final MessageType type;
  final String content;
  final int duration;
  final int displayOrder;
  final bool isActive;
  final int panelIndex;

  Message({
    this.id,
    required this.type,
    required this.content,
    this.duration = 10,
    this.displayOrder = 0,
    this.isActive = true,
    this.panelIndex = 1,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.name,
      'content': content,
      'duration': duration,
      'display_order': displayOrder,
      'is_active': isActive ? 1 : 0,
      'panel_index': panelIndex,
    };
  }

  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      id: map['id'],
      type: MessageType.values.firstWhere((e) => e.name == map['type']),
      content: map['content'],
      duration: map['duration'],
      displayOrder: map['display_order'],
      isActive: map['is_active'] == 1,
      panelIndex: map['panel_index'] ?? 1,
    );
  }
}