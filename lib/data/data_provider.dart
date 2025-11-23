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
  DisplayTheme _theme = DisplayTheme.defaultTheme();
  
  // שדות חדשים
  List<SpecialSchedule> _specialSchedules = [];
  Nusach _nusach = Nusach.EDOT_HAMIZRACH;
  
  DateTime? _simulationDate;

  List<Room> get rooms => _rooms;
  List<Minyan> get minyanim => _minyanim;
  List<Message> get messages => _messages;
  Map<String, List<dynamic>> get messageLinks => _messageLinks;
  String get location => _location;
  DisplayTheme get theme => _theme;
  
  List<SpecialSchedule> get specialSchedules => _specialSchedules;
  Nusach get nusach => _nusach;

  DateTime get simulationDate {
    if (_simulationDate == null) {
      return DateTime.now();
    }
    final now = DateTime.now();
    return DateTime(_simulationDate!.year, _simulationDate!.month, _simulationDate!.day,
                    now.hour, now.minute, now.second, now.millisecond);
  }

  DataProvider() {
    fetchAllData();
  }

  Future<void> fetchAllData() async {
    _rooms = await _dbHelper.getRooms();
    _minyanim = await _dbHelper.getMinyanim();
    _messages = await _dbHelper.getMessages();
    _messageLinks = await _dbHelper.getAllMessageLinks();
    _location = await _dbHelper.getSetting('location') ?? 'ירושלים';
    _theme = await _dbHelper.getTheme();
    _specialSchedules = await _dbHelper.getSpecialSchedules(); // טעינת ימים מיוחדים
    
    // טעינת נוסח
    String? nusachStr = await _dbHelper.getSetting('nusach');
    if (nusachStr != null) {
      _nusach = Nusach.values.firstWhere((e) => e.name == nusachStr, orElse: () => Nusach.EDOT_HAMIZRACH);
    }
    
    final simDateStr = await _dbHelper.getSetting('simulation_date');
    if (simDateStr != null) {
      _simulationDate = DateTime.tryParse(simDateStr);
    } else {
      _simulationDate = null;
    }
    
    notifyListeners();
  }
  
  Future<void> updateTheme(DisplayTheme newTheme) async {
    await _dbHelper.updateTheme(newTheme);
    await fetchAllData();
  }
  
  Future<void> updateNusach(Nusach newNusach) async {
    _nusach = newNusach;
    await _dbHelper.updateSetting('nusach', newNusach.name);
    notifyListeners();
  }

  Future<void> setSimulationDate(DateTime? date) async {
    _simulationDate = date;
    if (date == null) {
      await _dbHelper.deleteSetting('simulation_date');
    } else {
      await _dbHelper.updateSetting('simulation_date', date.toIso8601String());
    }
    notifyListeners();
  }
}