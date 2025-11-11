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

  Room({
    this.id,
    required this.name,
    this.showClock = true,
    this.showCalendar = true,
    this.showZmanim = false,
    this.displayMode = MinyanDisplayMode.THIS_ROOM_ONLY,
    this.activeMessagePanels = 1,
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
    );
  }
}

// ... שאר הקובץ (Minyan, Message) נשאר ללא שינוי ...
enum MinyanScheduleType {
REGULAR,
SHABBAT_DAY,
MOTZEI_SHABBAT
}

class Minyan {
  final int? id;
  final String name;
  final int roomId;
  final String time;
  final String? roomName;
  final MinyanScheduleType scheduleType;

  Minyan({
    this.id,
    required this.name,
    required this.roomId,
    required this.time,
    this.roomName,
    this.scheduleType = MinyanScheduleType.REGULAR,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'room_id': roomId,
      'time': time,
      'schedule_type': scheduleType.name,
    };
  }

  factory Minyan.fromMap(Map<String, dynamic> map) {
    return Minyan(
      id: map['id'],
      name: map['name'],
      roomId: map['room_id'],
      time: map['time'],
      roomName: map['roomName'],
      scheduleType: MinyanScheduleType.values.firstWhere(
        (e) => e.name == map['schedule_type'],
        orElse: () => MinyanScheduleType.REGULAR,
      ),
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