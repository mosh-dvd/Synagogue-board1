// lib/services/minyan_data_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:synagogue_display/data/database_helper.dart';
import 'package:synagogue_display/data/models.dart';

class MinyanDataService {
  final DatabaseHelper _db = DatabaseHelper();

  Future<String> exportMinyanimToJson() async {
    final minyanim = await _db.getMinyanim();
    if (minyanim.isEmpty) {
      throw Exception('אין מניינים לייצא.');
    }

    final List<Map<String, dynamic>> minyanimAsMap = minyanim.map((m) => m.toDbMap()).toList();
    final String jsonString = jsonEncode(minyanimAsMap);

    final String? outputFile = await FilePicker.platform.saveFile(
      dialogTitle: 'שמור את קובץ המניינים:',
      fileName: 'minyanim_backup_${DateTime.now().toIso8601String().substring(0, 10)}.json',
    );

    if (outputFile == null) {
      throw Exception('השמירה בוטלה.');
    }

    final file = File(outputFile);
    await file.writeAsString(jsonString);
    
    return outputFile;
  }

  Future<int> importMinyanimFromJson() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result == null || result.files.single.path == null) {
      throw Exception('לא נבחר קובץ.');
    }

    final file = File(result.files.single.path!);
    final jsonString = await file.readAsString();

    final List<dynamic> jsonList = jsonDecode(jsonString);
    final List<Minyan> minyanimToImport = jsonList.map((jsonItem) => Minyan.fromMap(jsonItem)).toList();
    
    await _db.clearAndInsertMinyanim(minyanimToImport);
    return minyanimToImport.length;
  }
}