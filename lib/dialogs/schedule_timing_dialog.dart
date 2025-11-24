// lib/dialogs/schedule_timing_dialog.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:synagogue_display/data/data_provider.dart';
import 'package:synagogue_display/data/models.dart';
import 'package:synagogue_display/data/zmanim_helper.dart';

class ScheduleTimingDialog extends StatefulWidget {
  const ScheduleTimingDialog({Key? key}) : super(key: key);

  @override
  _ScheduleTimingDialogState createState() => _ScheduleTimingDialogState();
}

class _ScheduleTimingDialogState extends State<ScheduleTimingDialog> {
  late ScheduleSwitchConfig _erev;
  late ScheduleSwitchConfig _shabbat;
  late ScheduleSwitchConfig _motzaei;

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<DataProvider>(context, listen: false);
    _erev = provider.switchErev;
    _shabbat = provider.switchShabbat;
    _motzaei = provider.switchMotzaei;
  }

  Widget _buildConfigRow(String title, ScheduleSwitchConfig current, Function(ScheduleSwitchConfig) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        Row(
          children: [
            const Text('החל מ: '),
            Expanded(
              child: DropdownButtonFormField<RelativeZman>(
                value: current.baseZman,
                isExpanded: true,
                items: RelativeZman.values.map((zman) => DropdownMenuItem(
                  value: zman,
                  child: Text(ZmanimHelper.zmanimDisplayNames[zman] ?? zman.name, overflow: TextOverflow.ellipsis),
                )).toList(),
                onChanged: (v) {
                  if (v != null) {
                    onChanged(ScheduleSwitchConfig(baseZman: v, offsetMinutes: current.offsetMinutes));
                  }
                },
              ),
            ),
            const SizedBox(width: 16),
            SizedBox(
              width: 80,
              child: TextFormField(
                initialValue: current.offsetMinutes.toString(),
                decoration: const InputDecoration(labelText: 'דקות (+/-)'),
                keyboardType: TextInputType.number,
                onChanged: (v) {
                  final val = int.tryParse(v);
                  if (val != null) {
                    onChanged(ScheduleSwitchConfig(baseZman: current.baseZman, offsetMinutes: val));
                  }
                },
              ),
            ),
          ],
        ),
        const Divider(height: 30),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('הגדרת מעבר בין לוחות זמנים'),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildConfigRow(
                'מתי לעבור לתצוגת ערב שבת/חג?',
                _erev,
                (newVal) => _erev = newVal,
              ),
              _buildConfigRow(
                'מתי לעבור לתצוגת שבת/חג (היום עצמו)?',
                _shabbat,
                (newVal) => _shabbat = newVal,
              ),
              _buildConfigRow(
                'מתי לעבור לתצוגת מוצאי שבת?',
                _motzaei,
                (newVal) => _motzaei = newVal,
              ),
              const Text(
                'הערה: המערכת מחשבת אוטומטית את ימי השבוע (שישי/שבת) או החג.\nההגדרות כאן קובעות את השעה המדויקת בתוך היום.',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(child: const Text('ביטול'), onPressed: () => Navigator.of(context).pop()),
        ElevatedButton(
          child: const Text('שמירה'),
          onPressed: () async {
            await Provider.of<DataProvider>(context, listen: false)
                .updateSwitchConfigs(_erev, _shabbat, _motzaei);
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}