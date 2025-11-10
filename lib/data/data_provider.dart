// lib/data/data_provider.dart
import 'package:flutter/foundation.dart';
import 'package:synagogue_display/data/database_helper.dart';
import 'package:synagogue_display/data/models.dart';

class DataProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  List<Room> _rooms = [];
  List<Minyan> _minyanim = [];
  List<Message> _messages = [];
  Map<String, List<dynamic>> _messageLinks = {};
  String _location = 'ירושלים';

  List<Room> get rooms => _rooms;
  List<Minyan> get minyanim => _minyanim;
  List<Message> get messages => _messages;
  Map<String, List<dynamic>> get messageLinks => _messageLinks;
  String get location => _location;

  DataProvider() {
    fetchAllData();
  }

  // --- שינוי: פונקציות ניהול נקודתיות ---

  Future<void> fetchAllData() async {
    _rooms = await _dbHelper.getRooms();
    _minyanim = await _dbHelper.getMinyanim();
    _messages = await _dbHelper.getMessages();
    _messageLinks = await _dbHelper.getAllMessageLinks();
    _location = await _dbHelper.getSetting('location') ?? 'ירושלים';
    notifyListeners();
  }

  Future<void> addRoom(Room room) async {
    await _dbHelper.insertRoom(room);
    await fetchAllData(); // כאן טעינה מחדש הגיונית כי זה משפיע על הכל
  }

  Future<void> deleteRoom(int id) async {
    await _dbHelper.deleteRoom(id);
    _rooms.removeWhere((room) => room.id == id);
    notifyListeners();
  }

  Future<void> updateRoom(Room room) async {
    await _dbHelper.updateRoom(room);
    await fetchAllData();
  }
  
  Future<void> addMinyan(Minyan minyan) async {
    await _dbHelper.insertMinyan(minyan);
    await fetchAllData(); // טוענים מחדש כי צריך את ה-roomName
  }

  Future<void> deleteMinyan(int id) async {
    await _dbHelper.deleteMinyan(id);
    _minyanim.removeWhere((minyan) => minyan.id == id);
    notifyListeners();
  }

  Future<void> saveMessage(Message message, List<int> roomIds) async {
    if (message.id == null) {
      final newId = await _dbHelper.insertMessage(message);
      await _dbHelper.linkMessageToRooms(newId, roomIds);
    } else {
      await _dbHelper.updateMessage(message);
      await _dbHelper.linkMessageToRooms(message.id!, roomIds);
    }
    await fetchAllData();
  }

  Future<void> deleteMessage(int id) async {
    await _dbHelper.deleteMessage(id);
    _messages.removeWhere((msg) => msg.id == id);
    notifyListeners();
  }

  Future<void> updateLocation(String location) async {
    await _dbHelper.updateSetting('location', location);
    _location = location;
    notifyListeners();
  }
}