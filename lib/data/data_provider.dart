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
  // --- שינוי 1: הסרת isLoading ---
  // bool _isLoading = true; // הוסר!

  List<Room> get rooms => _rooms;
  List<Minyan> get minyanim => _minyanim;
  List<Message> get messages => _messages;
  Map<String, List<dynamic>> get messageLinks => _messageLinks;
  String get location => _location;
  // bool get isLoading => _isLoading; // הוסר!

  DataProvider() {
    fetchAllData();
  }

  Future<void> fetchAllData() async {
    // --- שינוי 2: פישוט הלוגיקה ---
    // _isLoading = true; // הוסר
    // notifyListeners(); // הוסר - אין צורך לעדכן פעמיים

    _rooms = await _dbHelper.getRooms();
    _minyanim = await _dbHelper.getMinyanim();
    _messages = await _dbHelper.getMessages();
    _messageLinks = await _dbHelper.getAllMessageLinks();
    _location = await _dbHelper.getSetting('location') ?? 'ירושלים';
    
    // _isLoading = false; // הוסר
    // עדכון ה-UI יקרה רק פעם אחת בסוף, אחרי שכל הנתונים נטענו
    notifyListeners();
  }
}