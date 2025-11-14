// lib/dialogs/global_settings_dialog.dart (קובץ מלא - ללא קוד מחיקת DB)
import 'package:flutter/material.dart';
import 'package:synagogue_display/data/database_helper.dart';
import 'package:synagogue_display/data/zmanim_helper.dart';
import 'package:provider/provider.dart';
import 'package:synagogue_display/data/data_provider.dart';
// import 'package:desktop_multi_window/desktop_multi_window.dart'; // *** נמחק הייבוא ***

class GlobalSettingsDialog extends StatefulWidget {
  const GlobalSettingsDialog({Key? key}) : super(key: key);

  @override
  _GlobalSettingsDialogState createState() => _GlobalSettingsDialogState();
}

class _GlobalSettingsDialogState extends State<GlobalSettingsDialog> {
  String? _selectedLocation;
  final List<String> _cities = ZmanimHelper.getAllCities();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final location = await DatabaseHelper().getSetting('location');
    setState(() {
      _selectedLocation = location;
    });
  }

  Future<void> _saveSettings() async {
    if (_selectedLocation != null) {
      await DatabaseHelper().updateSetting('location', _selectedLocation!);
    }
    // רענון הנתונים הגלובליים לאחר שינוי מיקום (שישפיע על הזמנים)
    if (mounted) {
      Provider.of<DataProvider>(context, listen: false).fetchAllData();
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('הגדרות כלליות'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<String>(
            value: _selectedLocation,
            hint: const Text('בחר עיר לחישוב זמנים'),
            isExpanded: true,
            items: _cities.map((String city) {
              return DropdownMenuItem<String>(
                value: city,
                child: Text(city),
              );
            }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                _selectedLocation = newValue;
              });
            },
          ),
          
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 8),
          
        ],
      ),
      actions: [
        TextButton(child: const Text('ביטול'), onPressed: () => Navigator.of(context).pop()),
        TextButton(child: const Text('שמירה'), onPressed: _saveSettings),
      ],
    );
  }
}