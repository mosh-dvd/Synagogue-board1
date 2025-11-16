// lib/dialogs/global_settings_dialog.dart

import 'package:flutter/material.dart';
import 'package:synagogue_display/data/database_helper.dart';
import 'package:synagogue_display/data/zmanim_helper.dart';
import 'package:provider/provider.dart';
import 'package:synagogue_display/data/data_provider.dart';
import 'package:intl/intl.dart';

class GlobalSettingsDialog extends StatefulWidget {
  const GlobalSettingsDialog({Key? key}) : super(key: key);

  @override
  _GlobalSettingsDialogState createState() => _GlobalSettingsDialogState();
}

class _GlobalSettingsDialogState extends State<GlobalSettingsDialog> {
  String? _selectedLocation;
  final List<String> _cities = ZmanimHelper.getAllCities();
  
  DateTime? _simDate;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final dataProvider = Provider.of<DataProvider>(context, listen: false);
    // *** שינוי: יצירת מופע חדש ***
    final location = await DatabaseHelper().getSetting('location');
    setState(() {
      _selectedLocation = location;
      _simDate = dataProvider.simulationDate.day == DateTime.now().day && 
                 dataProvider.simulationDate.month == DateTime.now().month &&
                 dataProvider.simulationDate.year == DateTime.now().year ? null : dataProvider.simulationDate;
    });
  }

  Future<void> _saveSettings() async {
    final dataProvider = Provider.of<DataProvider>(context, listen: false);
    
    if (_selectedLocation != null) {
      // *** שינוי: יצירת מופע חדש ***
      await DatabaseHelper().updateSetting('location', _selectedLocation!);
    }
    
    await dataProvider.setSimulationDate(_simDate); 
    
    Navigator.of(context).pop();
  }
  
  Future<void> _selectSimDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _simDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        _simDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('הגדרות כלליות'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
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

          const Text('הדמיית תאריך תצוגה', style: TextStyle(fontWeight: FontWeight.bold)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_simDate == null ? 'תאריך נוכחי (מערכת)' : DateFormat('dd/MM/yyyy').format(_simDate!)),
              TextButton.icon(
                icon: Icon(_simDate == null ? Icons.calendar_today : Icons.edit),
                label: Text(_simDate == null ? 'הצג תאריך אחר' : 'שנה תאריך'),
                onPressed: _selectSimDate,
              ),
            ],
          ),
          if (_simDate != null)
            TextButton.icon(
              icon: const Icon(Icons.clear, color: Colors.red),
              label: const Text('בטל הדמיית תאריך', style: TextStyle(color: Colors.red)),
              onPressed: () => setState(() => _simDate = null),
            ),

          const SizedBox(height: 24),
          const Divider(),
          
        ],
      ),
      actions: [
        TextButton(child: const Text('ביטול'), onPressed: () => Navigator.of(context).pop()),
        TextButton(child: const Text('שמירה'), onPressed: _saveSettings),
      ],
    );
  }
}