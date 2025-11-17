
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

  Future<void> _saveTheme() async {
    final dataProvider = Provider.of<DataProvider>(context, listen: false);
    await dataProvider.updateTheme(_currentTheme);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('הגדרות עיצוב'),
      content: SingleChildScrollView(
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
            const Text('מסגרות', style: TextStyle(fontWeight: FontWeight.bold)),
            ListTile(
              title: Text('עובי מסגרת (${_currentTheme.borderWidth.toStringAsFixed(1)})'),
              subtitle: Slider(
                value: _currentTheme.borderWidth,
                min: 0.0,
                max: 10.0,
                divisions: 20,
                label: _currentTheme.borderWidth.toStringAsFixed(1),
                onChanged: (value) => setState(() => _currentTheme = DisplayTheme.fromMap({..._currentTheme.toMap(), 'borderWidth': value})),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(child: const Text('ביטול'), onPressed: () => Navigator.of(context).pop()),
        ElevatedButton(child: const Text('שמירה'), onPressed: _saveTheme),
      ],
    );
  }
}