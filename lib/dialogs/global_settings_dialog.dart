// lib/dialogs/global_settings_dialog.dart

import 'package:flutter/material.dart';
import 'package:synagogue_display/data/database_helper.dart';
import 'package:synagogue_display/data/models.dart';
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
  Nusach _nusach = Nusach.EDOT_HAMIZRACH;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final dataProvider = Provider.of<DataProvider>(context, listen: false);
    final location = await DatabaseHelper().getSetting('location');
    setState(() {
      _selectedLocation = location;
      _nusach = dataProvider.nusach;
      _simDate = dataProvider.simulationDate.day == DateTime.now().day && 
                 dataProvider.simulationDate.month == DateTime.now().month &&
                 dataProvider.simulationDate.year == DateTime.now().year ? null : dataProvider.simulationDate;
    });
  }

  Future<void> _saveSettings() async {
    final dataProvider = Provider.of<DataProvider>(context, listen: false);
    
    if (_selectedLocation != null) {
      await DatabaseHelper().updateSetting('location', _selectedLocation!);
    }
    
    await dataProvider.updateNusach(_nusach);
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
      content: SingleChildScrollView(
        child: Column(
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
            
            const SizedBox(height: 16),
            DropdownButtonFormField<Nusach>(
              value: _nusach,
              decoration: const InputDecoration(labelText: 'נוסח ספירת העומר'),
              isExpanded: true,
              items: const [
                DropdownMenuItem(value: Nusach.EDOT_HAMIZRACH, child: Text('עדות המזרח (ספרדי)')),
                DropdownMenuItem(value: Nusach.ASHKENAZ, child: Text('אשכנז')),
                DropdownMenuItem(value: Nusach.SEFARD, child: Text('ספרד (חסידים)')),
              ],
              onChanged: (val) => setState(() => _nusach = val!),
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
          ],
        ),
      ),
      actions: [
        TextButton(child: const Text('ביטול'), onPressed: () => Navigator.of(context).pop()),
        ElevatedButton(child: const Text('שמירה'), onPressed: _saveSettings),
      ],
    );
  }
}