// lib/data/database_helper.dart (קובץ מלא)
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'models.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  static Future<void> init() async {
    if (_database != null) return;
    String path = join(await getDatabasesPath(), 'synagogue.db');
    _database = await openDatabase(
      path,
      version: 12, // *** שינוי: עדכון גרסה ל-12 ***
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<Database> get database async {
    if (_database == null) await init();
    return _database!;
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE rooms (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        show_clock INTEGER NOT NULL DEFAULT 1,
        show_calendar INTEGER NOT NULL DEFAULT 1,
        show_zmanim INTEGER NOT NULL DEFAULT 0,
        display_mode TEXT NOT NULL DEFAULT 'THIS_ROOM_ONLY',
        active_message_panels INTEGER NOT NULL DEFAULT 1,
        is_display_active INTEGER NOT NULL DEFAULT 1,
        show_weekday_minyanim_on_shabbat INTEGER NOT NULL DEFAULT 0 
      )
    ''');

    await db.execute('''
      CREATE TABLE minyanim (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        room_id INTEGER NOT NULL,
        schedule_type TEXT NOT NULL DEFAULT 'REGULAR',
        time_type TEXT NOT NULL DEFAULT 'FIXED',
        time TEXT,
        relative_zman TEXT,
        relative_offset_minutes INTEGER,
        FOREIGN KEY (room_id) REFERENCES rooms (id) ON DELETE CASCADE
      )
    ''');
    
    await db.execute('''CREATE TABLE settings (key TEXT PRIMARY KEY, value TEXT)''');
    await db.insert('settings', {'key': 'location', 'value': 'ירושלים'});
    await db.execute('''CREATE TABLE messages (id INTEGER PRIMARY KEY AUTOINCREMENT, type TEXT NOT NULL, content TEXT NOT NULL, duration INTEGER NOT NULL DEFAULT 10, display_order INTEGER NOT NULL DEFAULT 0, is_active INTEGER NOT NULL DEFAULT 1, panel_index INTEGER NOT NULL DEFAULT 1)''');
    await db.execute('''CREATE TABLE message_room_link (message_id INTEGER, room_id INTEGER, PRIMARY KEY (message_id, room_id), FOREIGN KEY (message_id) REFERENCES messages(id) ON DELETE CASCADE, FOREIGN KEY (room_id) REFERENCES rooms(id) ON DELETE CASCADE)''');
  }

  static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) { await db.execute('ALTER TABLE rooms ADD COLUMN show_zmanim INTEGER NOT NULL DEFAULT 0'); }
    if (oldVersion < 5) { await db.execute('ALTER TABLE rooms ADD COLUMN side_panel_flex INTEGER NOT NULL DEFAULT 1'); }
    if (oldVersion < 6) { await db.execute("ALTER TABLE minyanim ADD COLUMN schedule_type TEXT NOT NULL DEFAULT 'REGULAR'"); }
    if (oldVersion < 7) { await db.execute("ALTER TABLE rooms ADD COLUMN active_message_panels INTEGER NOT NULL DEFAULT 1"); }
    if (oldVersion < 8) { await db.execute("ALTER TABLE messages ADD COLUMN panel_index INTEGER NOT NULL DEFAULT 1"); }
    
    if (oldVersion < 9) {
      await db.execute('CREATE TABLE rooms_new (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL UNIQUE, show_clock INTEGER NOT NULL DEFAULT 1, show_calendar INTEGER NOT NULL DEFAULT 1, show_zmanim INTEGER NOT NULL DEFAULT 0, display_mode TEXT NOT NULL DEFAULT \'THIS_ROOM_ONLY\', active_message_panels INTEGER NOT NULL DEFAULT 1)');
      await db.execute('INSERT INTO rooms_new (id, name, show_clock, show_calendar, show_zmanim, display_mode, active_message_panels) SELECT id, name, show_clock, show_calendar, show_zmanim, display_mode, active_message_panels FROM rooms');
      await db.execute('DROP TABLE rooms');
      await db.execute('ALTER TABLE rooms_new RENAME TO rooms');
    }

    if (oldVersion < 10) {
      await db.execute('CREATE TABLE minyanim_new (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, room_id INTEGER NOT NULL, schedule_type TEXT NOT NULL DEFAULT \'REGULAR\', time_type TEXT NOT NULL DEFAULT \'FIXED\', time TEXT, relative_zman TEXT, relative_offset_minutes INTEGER)');
      await db.execute('INSERT INTO minyanim_new (id, name, room_id, schedule_type, time_type, time, relative_zman, relative_offset_minutes) SELECT id, name, room_id, schedule_type, time_type, time, relative_zman, relative_offset_minutes FROM minyanim');
      await db.execute('DROP TABLE minyanim');
      await db.execute('ALTER TABLE minyanim_new RENAME TO minyanim');
    }

    if (oldVersion < 11) {
      await db.execute('ALTER TABLE rooms ADD COLUMN is_display_active INTEGER NOT NULL DEFAULT 1');
    }
    
    if (oldVersion < 12) {
      await db.execute('ALTER TABLE rooms ADD COLUMN show_weekday_minyanim_on_shabbat INTEGER NOT NULL DEFAULT 0'); // *** שינוי: הוספת העמודה החדשה ***
    }
  }

  Future<String?> getSetting(String key) async {
    final db = await database;
    final maps = await db.query('settings', where: 'key = ?', whereArgs: [key]);
    return maps.isNotEmpty ? maps.first['value'] as String? : null;
  }

  Future<void> updateSetting(String key, String value) async {
    final db = await database;
    await db.insert('settings', {'key': key, 'value': value}, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> insertRoom(Room room) async {
    final db = await database;
    await db.insert('rooms', room.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateRoom(Room room) async {
    final db = await database;
    final data = room.toMap(); data.remove('id');
    await db.update('rooms', data, where: 'id = ?', whereArgs: [room.id]);
  }

  Future<List<Room>> getRooms() async {
    final db = await database;
    final maps = await db.query('rooms', orderBy: 'name ASC');
    return List.generate(maps.length, (i) => Room.fromMap(maps[i]));
  }

  Future<void> deleteRoom(int id) async {
    final db = await database;
    await db.delete('rooms', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> insertMinyan(Minyan minyan) async {
    final db = await database;
    await db.insert('minyanim', minyan.toDbMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Minyan>> getMinyanim() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT m.*, r.name as roomName
      FROM minyanim m
      JOIN rooms r ON m.room_id = r.id
      ORDER BY m.time ASC
    ''');
    return List.generate(maps.length, (i) => Minyan.fromMap(maps[i]));
  }

  Future<void> deleteMinyan(int id) async {
    final db = await database;
    await db.delete('minyanim', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearAndInsertMinyanim(List<Minyan> minyanim) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('minyanim');
      for (final minyan in minyanim) {
        await txn.insert('minyanim', minyan.toDbMap());
      }
    });
  }

  Future<int> insertMessage(Message message) async {
    final db = await database;
    return await db.insert('messages', message.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateMessage(Message message) async {
    final db = await database;
    final data = message.toMap(); data.remove('id');
    await db.update('messages', data, where: 'id = ?', whereArgs: [message.id]);
  }

  Future<void> deleteMessage(int id) async {
    final db = await database;
    await db.delete('messages', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Message>> getMessages({bool activeOnly = false}) async {
    final db = await database;
    final maps = await db.query('messages', where: activeOnly ? 'is_active = 1' : null, orderBy: 'display_order ASC, id ASC');
    return List.generate(maps.length, (i) => Message.fromMap(maps[i]));
  }

  Future<void> linkMessageToRooms(int messageId, List<int> roomIds) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('message_room_link', where: 'message_id = ?', whereArgs: [messageId]);
      for (final roomId in roomIds) {
        await txn.insert('message_room_link', {'message_id': messageId, 'room_id': roomId});
      }
    });
  }

  Future<List<int>> getLinkedRoomIdsForMessage(int messageId) async {
    final db = await database;
    final maps = await db.query('message_room_link', columns: ['room_id'], where: 'message_id = ?', whereArgs: [messageId]);
    return maps.map((map) => map['room_id'] as int).toList();
  }

  Future<Map<String, List<dynamic>>> getAllMessageLinks() async {
    final db = await database;
    final maps = await db.query('message_room_link');
    final Map<String, List<dynamic>> links = {};
    for (final map in maps) {
      final messageId = map['message_id'].toString(); final roomId = map['room_id'];
      if (links[messageId] == null) { links[messageId] = []; }
      links[messageId]!.add(roomId);
    }
    return links;
  }
}