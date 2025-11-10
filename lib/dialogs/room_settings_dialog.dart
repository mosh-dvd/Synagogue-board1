import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:synagogue_display/data/data_provider.dart';
import 'package:synagogue_display/data/models.dart';

class RoomSettingsDialog extends StatefulWidget {
  final Room room;
  const RoomSettingsDialog({Key? key, required this.room}) : super(key: key);
  @override
  _RoomSettingsDialogState createState() => _RoomSettingsDialogState();
}

class _RoomSettingsDialogState extends State<RoomSettingsDialog> {
  // ... (כל המשתנים והפונקציות נשארים זהים)

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('הגדרות תצוגה: ${widget.room.name}'),
      content: SizedBox(
        // ******** התיקון כאן: הגדרת רוחב קבוע לתוכן ********
        width: 400, 
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ... כל התוכן של הדיאלוג נשאר זהה
            ],
          ),
        ),
      ),
      actions: [ /* ... כפתורים ... */ ],
    );
  }
}