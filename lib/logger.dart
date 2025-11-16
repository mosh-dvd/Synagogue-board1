// lib/logger.dart

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
        // *** שינוי עיקרי: מציאת הנתיב של תיקיית התוכנה ***
        
        // 1. קבלת הנתיב של קובץ ההפעלה של התוכנה
        final String exePath = Platform.script.toFilePath();
        
        // 2. מתוך הנתיב המלא, חילוץ הנתיב של התיקייה בלבד
        final String exeDir = p.dirname(exePath);

        // 3. יצירת תיקיית 'logs' בתוך תיקיית התוכנה
        final logDirectory = Directory(p.join(exeDir, 'logs'));
        
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

        logInfo('Logger initialized successfully in application directory.');
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

      print(logEntry);

      if (kReleaseMode && _logFile != null) {
        if (await _logFile!.exists()) {
          final fileSize = await _logFile!.length();
          const maxFileSize = 10 * 1024 * 1024; // 10MB
          if (fileSize > maxFileSize) {
            await _logFile!.writeAsString('--- Log file reset due to excessive size ($fileSize bytes) ---\n', mode: FileMode.write);
          }
        }
        await _logFile!.writeAsString(logEntry, mode: FileMode.append);
      }
    } catch (e) {
      print('Error writing to log file: $e');
    }
  }
}