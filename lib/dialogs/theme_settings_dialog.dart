// lib/dialogs/theme_settings_dialog.dart (קובץ מלא מעודכן)

import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:synagogue_display/data/data_provider.dart';
import 'package:synagogue_display/data/models.dart';

class ThemeSettingsDialog extends StatefulWidget {
  const ThemeSettingsDialog({Key? key}) : super(key: key);

  @override
  _ThemeSettingsDialogState createState() => _ThemeSettingsDialogState();
}

class _ThemeSettingsDialogState extends State<ThemeSettingsDialog> {
  late DisplayTheme _currentTheme;
  
  final List<String> _fontFamilies = [
    'Rubik', 'Heebo', 'Arimo', 'Tinos', 'Frank Ruhl Libre', 'Suez One'
  ];

  @override
  void initState() {
    super.initState();
    _currentTheme = Provider.of<DataProvider>(context, listen: false).theme;
  }
  
  void _pickColor(Color initialColor, Function(Color) onColorChanged) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('בחירת צבע'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: initialColor,
            onColorChanged: onColorChanged,
            pickerAreaHeightPercent: 0.8,
          ),
        ),
        actions: [
          TextButton(
            child: const Text('אישור'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildColorPicker(String label, Color color, Function(Color) onColorChanged) {
    return ListTile(
      title: Text(label),
      trailing: GestureDetector(
        onTap: () => _pickColor(color, (newColor) => setState(() => onColorChanged(newColor))),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey.shade400),
          ),
        ),
      ),
    );
  }

  Widget _buildFontPicker(String label, String currentFont, Function(String?) onFontChanged) {
     return Padding(
       padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
       child: DropdownButtonFormField<String>(
         value: currentFont,
         decoration: InputDecoration(labelText: label),
         items: _fontFamilies.map((font) => DropdownMenuItem(
           value: font,
           child: Text(font, style: GoogleFonts.getFont(font)),
         )).toList(),
         onChanged: onFontChanged,
       ),
     );
  }

  Widget _buildSlider(String label, double value, double min, double max, Function(double) onChanged) {
    // Override min to allow very small fonts
    final effectiveMin = 5.0; 
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text('$label (${value.toInt()})', style: const TextStyle(fontWeight: FontWeight.w500)),
        ),
        Slider(
          value: value < effectiveMin ? effectiveMin : value, // הגנה
          min: effectiveMin,
          max: max,
          divisions: (max - effectiveMin).toInt(),
          label: value.toStringAsFixed(0),
          onChanged: (v) => setState(() => onChanged(v)),
        ),
      ],
    );
  }

  Future<void> _saveTheme() async {
    final dataProvider = Provider.of<DataProvider>(context, listen: false);
    await dataProvider.updateTheme(_currentTheme);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('הגדרות עיצוב'),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('צבעים', style: TextStyle(fontWeight: FontWeight.bold)),
              _buildColorPicker('רקע כללי', _currentTheme.scaffoldBackgroundColor, (c) => _currentTheme = DisplayTheme.fromMap({..._currentTheme.toMap(), 'scaffoldBackgroundColor': c.value})),
              _buildColorPicker('רקע עמודות', _currentTheme.minyanimColumnColor, (c) => _currentTheme = DisplayTheme.fromMap({..._currentTheme.toMap(), 'minyanimColumnColor': c.value, 'zmanimColumnColor': c.value})),
              _buildColorPicker('רקע הודעות', _currentTheme.messagePanelColor, (c) => _currentTheme = DisplayTheme.fromMap({..._currentTheme.toMap(), 'messagePanelColor': c.value})),
              _buildColorPicker('טקסט ראשי', _currentTheme.primaryTextColor, (c) => _currentTheme = DisplayTheme.fromMap({..._currentTheme.toMap(), 'primaryTextColor': c.value})),
              _buildColorPicker('צבע הדגשה (שעות)', _currentTheme.accentColor, (c) => _currentTheme = DisplayTheme.fromMap({..._currentTheme.toMap(), 'accentColor': c.value})),
              _buildColorPicker('צבע הדגשה מיוחד (זהב)', _currentTheme.highlightColor, (c) => _currentTheme = DisplayTheme.fromMap({..._currentTheme.toMap(), 'highlightColor': c.value})),
              _buildColorPicker('צבע מסגרות', _currentTheme.borderColor, (c) => _currentTheme = DisplayTheme.fromMap({..._currentTheme.toMap(), 'borderColor': c.value})),
              
              const Divider(height: 30),
              const Text('גופנים', style: TextStyle(fontWeight: FontWeight.bold)),
              _buildFontPicker('גופן ראשי (כותרות)', _currentTheme.primaryFont, (f) => setState(() => _currentTheme = DisplayTheme.fromMap({..._currentTheme.toMap(), 'primaryFont': f!}))),
              _buildFontPicker('גופן משני (שעות)', _currentTheme.secondaryFont, (f) => setState(() => _currentTheme = DisplayTheme.fromMap({..._currentTheme.toMap(), 'secondaryFont': f!}))),
              
              const Divider(height: 30),
              const Text('גדלי טקסט (גלובלי)', style: TextStyle(fontWeight: FontWeight.bold)),
              _buildSlider('כותרת עליונה', _currentTheme.titleFontSize, 5, 100, (v) => _currentTheme = DisplayTheme.fromMap({..._currentTheme.toMap(), 'titleFontSize': v})),
              _buildSlider('כותרות משנה (זמנים/תפילות)', _currentTheme.sectionTitleFontSize, 5, 60, (v) => _currentTheme = DisplayTheme.fromMap({..._currentTheme.toMap(), 'sectionTitleFontSize': v})),
              _buildSlider('טקסט גוף (שורות)', _currentTheme.bodyFontSize, 5, 50, (v) => _currentTheme = DisplayTheme.fromMap({..._currentTheme.toMap(), 'bodyFontSize': v})),
              _buildSlider('שעון עליון', _currentTheme.clockFontSize, 5, 60, (v) => _currentTheme = DisplayTheme.fromMap({..._currentTheme.toMap(), 'clockFontSize': v})),
              _buildSlider('שעון גדול (ראשי)', _currentTheme.largeClockFontSize, 5, 250, (v) => _currentTheme = DisplayTheme.fromMap({..._currentTheme.toMap(), 'largeClockFontSize': v})),
              _buildSlider('טקסט הודעות', _currentTheme.messageFontSize, 5, 150, (v) => _currentTheme = DisplayTheme.fromMap({..._currentTheme.toMap(), 'messageFontSize': v})),
              _buildSlider('טקסט תאריך/מניין קרוב', _currentTheme.dateFontSize, 5, 60, (v) => _currentTheme = DisplayTheme.fromMap({..._currentTheme.toMap(), 'dateFontSize': v})),

              const Divider(height: 30),
              const Text('מסגרות', style: TextStyle(fontWeight: FontWeight.bold)),
              _buildSlider('עובי מסגרת', _currentTheme.borderWidth, 0, 10, (v) => _currentTheme = DisplayTheme.fromMap({..._currentTheme.toMap(), 'borderWidth': v})),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(child: const Text('ביטול'), onPressed: () => Navigator.of(context).pop()),
        ElevatedButton(child: const Text('שמירה'), onPressed: _saveTheme),
      ],
    );
  }
}