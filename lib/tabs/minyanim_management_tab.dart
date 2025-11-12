// lib/tabs/minyanim_management_tab.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:synagogue_display/data/data_provider.dart';
import 'package:synagogue_display/data/database_helper.dart';
import 'package:synagogue_display/data/models.dart';
import 'package:synagogue_display/data/zmanim_helper.dart';

// Helper to avoid ambiguity with dart:core's List.firstWhere
extension FirstWhereExt<T> on List<T> {
  T? firstWhereOrNull(bool Function(T) test) {
    for (var element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}

class MinyanimManagementTab extends StatelessWidget {
  const MinyanimManagementTab({Key? key}) : super(key: key);

  String _getScheduleTypeName(MinyanScheduleType type) {
    switch (type) {
      case MinyanScheduleType.REGULAR: return 'יום חול';
      case MinyanScheduleType.SHABBAT_DAY: return 'שבת/חג';
      case MinyanScheduleType.MOTZEI_SHABBAT: return 'מוצ"ש';
    }
  }
  
  Future<void> _showAddOrEditMinyanDialog(BuildContext context, List<Room> rooms, [Minyan? minyanToEdit]) async {
    final formKey = GlobalKey<FormState>();

    final nameController = TextEditingController(text: minyanToEdit?.name);
    final timeController = TextEditingController(text: minyanToEdit?.time);
    final offsetController = TextEditingController(text: minyanToEdit?.relativeOffsetMinutes?.toString() ?? '0');

    // --- התיקון כאן ---
    // שימוש בפונקציית עזר בטוחה במקום orNull שלא קיים
    Room? selectedRoom = rooms.firstWhereOrNull((r) => r.id == minyanToEdit?.roomId);
    if (selectedRoom == null && rooms.isNotEmpty) {
      selectedRoom = rooms.first;
    }

    MinyanScheduleType selectedScheduleType = minyanToEdit?.scheduleType ?? MinyanScheduleType.REGULAR;
    MinyanTimeType selectedTimeType = minyanToEdit?.timeType ?? MinyanTimeType.FIXED;
    RelativeZman? selectedRelativeZman = minyanToEdit?.relativeZman ?? RelativeZman.sunrise;

    return showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(minyanToEdit == null ? 'הוספת מניין חדש' : 'עריכת מניין'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(labelText: 'שם התפילה (למשל, שחרית)'),
                        validator: (v) => v!.isEmpty ? 'חובה למלא שם' : null,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<Room>(
                        hint: const Text('בחר חדר'),
                        value: selectedRoom,
                        items: rooms.map((room) => DropdownMenuItem(value: room, child: Text(room.name))).toList(),
                        onChanged: (Room? newValue) => setState(() => selectedRoom = newValue),
                        validator: (v) => v == null ? 'חובה לבחור חדר' : null,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<MinyanScheduleType>(
                        decoration: const InputDecoration(labelText: 'תזמון'),
                        value: selectedScheduleType,
                        items: MinyanScheduleType.values.map((type) => DropdownMenuItem(value: type, child: Text(_getScheduleTypeName(type)))).toList(),
                        onChanged: (v) => setState(() => selectedScheduleType = v!),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<MinyanTimeType>(
                        decoration: const InputDecoration(labelText: 'סוג הזמן'),
                        value: selectedTimeType,
                        items: const [
                          DropdownMenuItem(value: MinyanTimeType.FIXED, child: Text('שעה קבועה')),
                          DropdownMenuItem(value: MinyanTimeType.RELATIVE, child: Text('יחסי לזמן ביום')),
                        ],
                        onChanged: (v) => setState(() => selectedTimeType = v!),
                      ),
                      const SizedBox(height: 16),
                      if (selectedTimeType == MinyanTimeType.FIXED)
                        TextFormField(
                          controller: timeController,
                          decoration: const InputDecoration(labelText: 'שעה (פורמט HH:mm)'),
                          validator: (v) {
                            if (v!.isEmpty) return 'חובה למלא שעה';
                            if (!RegExp(r'^\d{2}:\d{2}$').hasMatch(v)) return 'פורמט לא תקין';
                            return null;
                          },
                        )
                      else
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              flex: 2,
                              child: DropdownButtonFormField<RelativeZman>(
                                isExpanded: true,
                                decoration: const InputDecoration(labelText: 'יחסית ל'),
                                value: selectedRelativeZman,
                                items: RelativeZman.values.map((zman) => DropdownMenuItem(
                                  value: zman,
                                  child: Text(ZmanimHelper.zmanimDisplayNames[zman]!, overflow: TextOverflow.ellipsis),
                                )).toList(),
                                onChanged: (v) => setState(() => selectedRelativeZman = v),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 1,
                              child: TextFormField(
                                controller: offsetController,
                                decoration: const InputDecoration(labelText: 'דקות (+/-)'),
                                keyboardType: TextInputType.number,
                                validator: (v) => int.tryParse(v!) == null ? 'מספר' : null,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
          actions: [
            TextButton(child: const Text('ביטול'), onPressed: () => Navigator.of(ctx).pop()),
            TextButton(
              child: const Text('שמירה'),
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final newMinyan = Minyan(
                    id: minyanToEdit?.id,
                    name: nameController.text,
                    roomId: selectedRoom!.id!,
                    scheduleType: selectedScheduleType,
                    timeType: selectedTimeType,
                    time: selectedTimeType == MinyanTimeType.FIXED ? timeController.text : null,
                    relativeZman: selectedTimeType == MinyanTimeType.RELATIVE ? selectedRelativeZman : null,
                    relativeOffsetMinutes: selectedTimeType == MinyanTimeType.RELATIVE ? int.parse(offsetController.text) : null,
                  );
                  if (minyanToEdit == null) {
                    await DatabaseHelper().insertMinyan(newMinyan);
                  } else {
                    // await DatabaseHelper().updateMinyan(newMinyan); // Should be added
                  }
                  Provider.of<DataProvider>(context, listen: false).fetchAllData();
                  Navigator.of(ctx).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DataProvider>(
      builder: (context, dataProvider, child) {
        final minyanim = dataProvider.minyanim;
        final rooms = dataProvider.rooms;

        return Scaffold(
          body: ListView.builder(
            itemCount: minyanim.length,
            itemBuilder: (context, index) {
              final minyan = minyanim[index];
              String timeDisplay;
              if (minyan.timeType == MinyanTimeType.FIXED) {
                timeDisplay = minyan.time ?? '--:--';
              } else {
                final zmanName = ZmanimHelper.zmanimDisplayNames[minyan.relativeZman] ?? '';
                final offset = minyan.relativeOffsetMinutes ?? 0;
                final offsetStr = offset == 0 ? '' : (offset > 0 ? ' +$offset דק\'' : ' $offset דק\'');
                timeDisplay = '$zmanName$offsetStr';
              }

              return Card(
                child: ListTile(
                  leading: const Icon(Icons.access_time),
                  title: Text('${minyan.name} - ${minyan.roomName ?? 'חדר לא ידוע'}'),
                  subtitle: Text('$timeDisplay (${_getScheduleTypeName(minyan.scheduleType)})'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          await DatabaseHelper().deleteMinyan(minyan.id!);
                          Provider.of<DataProvider>(context, listen: false).fetchAllData();
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: rooms.isEmpty ? null : () => _showAddOrEditMinyanDialog(context, rooms),
            backgroundColor: rooms.isEmpty ? Colors.grey : Theme.of(context).colorScheme.primary,
            tooltip: rooms.isEmpty ? 'יש להוסיף חדרים תחילה' : 'הוסף מניין',
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }
}