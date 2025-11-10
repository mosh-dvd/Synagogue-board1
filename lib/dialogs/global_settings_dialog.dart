import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:synagogue_display/data/data_provider.dart';
import 'package:synagogue_display/data/zmanim_helper.dart';

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
    _selectedLocation = Provider.of<DataProvider>(context, listen: false).location;
  }

  Future<void> _saveSettings() async {
    if (_selectedLocation != null) {
      await Provider.of<DataProvider>(context, listen: false).updateLocation(_selectedLocation!);
    }
    Navigator.of(context).pop(true); // החזר true כדי לסמן שהתרחש שינוי
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
              return DropdownMenuItem<String>(value: city, child: Text(city));
            }).toList(),
            onChanged: (String? newValue) {
              setState(() => _selectedLocation = newValue);
            },
          ),
        ],
      ),
      actions: [
        TextButton(child: const Text('ביטול'), onPressed: () => Navigator.of(context).pop()),
        TextButton(child: const Text('שמירה'), onPressed: _saveSettings),
      ],
    );
  }
}