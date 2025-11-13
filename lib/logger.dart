import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class AppLogger {
  static File? _logFile;

  static Future<void> init() async {
    if (kReleaseMode) { // רק במצב ריצה, לא בפיתוח
      try {
        final directory = await getApplicationSupportDirectory();
        final logDirectory = Directory(p.join(directory.path, 'logs'));
        if (!await logDirectory.exists()) {
          await logDirectory.create(recursive: true);
        }
        _logFile = File(p.join(logDirectory.path, 'app_log.txt'));

        // תפיסת שגיאות מה-framework של פלאטר
        FlutterError.onError = (details) {
          logError('Flutter Error', details.exception, details.stack);
        };

        // תפיסת שגיאות אסינכרוניות שלא נתפסו
        PlatformDispatcher.instance.onError = (error, stack) {
          logError('Platform Error', error, stack);
          return true;
        };

        logInfo('Logger initialized successfully.');
      } catch (e, stack) {
        print('Failed to initialize logger: $e');
        print(stack);
      }
    } else {
      print("Logger is disabled in debug mode. Errors will be printed to the console.");
    }
  }

  static Future<void> logError(String type, Object error, StackTrace? stack) async {
    final message = '[$type] $error\n$stack';
    await _writeToLog('ERROR', message);
  }

  static Future<void> logInfo(String message) async {
    await _writeToLog('INFO', message);
  }

  static Future<void> _writeToLog(String level, String message) async {
    try {
      final timestamp = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
      final logEntry = '$timestamp [$level]: $message\n\n';

      // הדפסה לקונסול תמיד (שימושי לפיתוח)
      print(logEntry);

      // כתיבה לקובץ רק במצב ריצה
      if (kReleaseMode && _logFile != null) {
        await _logFile!.writeAsString(logEntry, mode: FileMode.append);
      }
    } catch (e) {
      print('Error writing to log file: $e');
    }
  }
}