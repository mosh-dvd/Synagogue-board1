// lib/dialogs/room_settings_dialog.dart
import 'package:flutter/material.dart';
import 'package:synagogue_display/data/models.dart';
import 'package:synagogue_display/data/database_helper.dart';

class RoomSettingsDialog extends StatefulWidget {
  final Room room;
  const RoomSettingsDialog({Key? key, required this.room}) : super(key: key);

  @override
  _RoomSettingsDialogState createState() => _RoomSettingsDialogState();
}

class _RoomSettingsDialogState extends State<RoomSettingsDialog> {
  late bool _showClock;
  late bool _showCalendar;
  late bool _showZmanim;
  late MinyanDisplayMode _displayMode;
  late double _sidePanelFlex;

  @override
  void initState() {
    super.initState();
    _showClock = widget.room.showClock;
    _showCalendar = widget.room.showCalendar;
    _showZmanim = widget.room.showZmanim;
    _displayMode = widget.room.displayMode;
    _sidePanelFlex = widget.room.sidePanelFlex.toDouble();
  }

  Future<void> _saveSettings() async {
    final updatedRoom = Room(
      id: widget.room.id,
      name: widget.room.name,
      showClock: _showClock,
      showCalendar: _showCalendar,
      showZmanim: _showZmanim,
      displayMode: _displayMode,
      sidePanelFlex: _sidePanelFlex.toInt(),
    );
    await DatabaseHelper().updateRoom(updatedRoom);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('הגדרות תצוגה: ${widget.room.name}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('תצוגת מניינים', style: TextStyle(fontWeight: FontWeight.bold)),
            DropdownButtonFormField<MinyanDisplayMode>(
              value: _displayMode,
              items: const [
                DropdownMenuItem(
                  value: MinyanDisplayMode.THIS_ROOM_ONLY,
                  child: Text('רק מניינים המשויכים לחדר זה'),
                ),
                DropdownMenuItem(
                  value: MinyanDisplayMode.ALL,
                  child: Text('כל המניינים (מסודרים לפי שעה)'),
                ),
              ],
              onChanged: (MinyanDisplayMode? newValue) {
                if (newValue != null) {
                  setState(() => _displayMode = newValue);
                }
              },
            ),
            const Divider(height: 30),
            const Text('ווידג\'טים נוספים', style: TextStyle(fontWeight: FontWeight.bold)),
            SwitchListTile(
              title: const Text('הצג שעון דיגיטלי'),
              value: _showClock,
              onChanged: (bool value) => setState(() => _showClock = value),
            ),
            SwitchListTile(
              title: const Text('הצג תאריך עברי'),
              value: _showCalendar,
              onChanged: (bool value) => setState(() => _showCalendar = value),
            ),
            SwitchListTile(
              title: const Text('הצג זמני היום'),
              value: _showZmanim,
              onChanged: (bool value) => setState(() => _showZmanim = value),
            ),
            const Divider(height: 30),
            const Text('יחס תצוגה', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('גודל עמודה צדדית: ${_sidePanelFlex.toInt()} (מתוך 5)'),
            Slider(
              value: _sidePanelFlex,
              min: 1,
              max: 4,
              divisions: 3,
              label: _sidePanelFlex.round().toString(),
              onChanged: (double value) {
                setState(() {
                  _sidePanelFlex = value;
                });
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(child: const Text('ביטול'), onPressed: () => Navigator.of(context).pop()),
        TextButton(child: const Text('שמירה'), onPressed: _saveSettings),
      ],
    );
  }
}