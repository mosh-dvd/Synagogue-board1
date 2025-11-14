// lib/dialogs/room_settings_dialog.dart (קובץ מלא)
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
  late int _activeMessagePanels;
  late bool _showWeekdayMinyanimOnShabbat; // *** שינוי: משתנה חדש ***

  @override
  void initState() {
    super.initState();
    _showClock = widget.room.showClock;
    _showCalendar = widget.room.showCalendar;
    _showZmanim = widget.room.showZmanim;
    _displayMode = widget.room.displayMode;
    _activeMessagePanels = widget.room.activeMessagePanels;
    _showWeekdayMinyanimOnShabbat = widget.room.showWeekdayMinyanimOnShabbat; // *** שינוי: אתחול משתנה חדש ***
  }

  Future<void> _saveSettings() async {
    final updatedRoom = Room(
      id: widget.room.id,
      name: widget.room.name,
      showClock: _showClock,
      showCalendar: _showCalendar,
      showZmanim: _showZmanim,
      displayMode: _displayMode,
      activeMessagePanels: _activeMessagePanels,
      isDisplayActive: widget.room.isDisplayActive,
      showWeekdayMinyanimOnShabbat: _showWeekdayMinyanimOnShabbat, // *** שינוי: שמירת הערך החדש ***
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
            
            // *** שינוי: הוספת הגדרת תצוגת יום חול בשבת ***
            SwitchListTile(
              title: const Text('הצג מנייני יום חול גם בשבת/חג'),
              subtitle: const Text('מציג את מנייני יום חול (בנוסף למנייני שבת/חג)'),
              value: _showWeekdayMinyanimOnShabbat,
              onChanged: (bool value) => setState(() => _showWeekdayMinyanimOnShabbat = value),
            ),
            // *** סוף הוספת הגדרת תצוגת יום חול בשבת ***
            
            const Divider(height: 30),
            const Text('פריסת הודעות', style: TextStyle(fontWeight: FontWeight.bold)),
            DropdownButtonFormField<int>(
              value: _activeMessagePanels,
              items: const [
                DropdownMenuItem(value: 1, child: Text('חלונית אחת גדולה')),
                DropdownMenuItem(value: 2, child: Text('2 חלוניות (אופקי)')),
                DropdownMenuItem(value: 3, child: Text('3 חלוניות (2 למעלה, 1 למטה)')),
                DropdownMenuItem(value: 4, child: Text('4 חלוניות (רשת)')),
              ],
              onChanged: (int? newValue) {
                if (newValue != null) {
                  setState(() => _activeMessagePanels = newValue);
                }
              },
              decoration: const InputDecoration(labelText: 'מספר חלוניות פעילות'),
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