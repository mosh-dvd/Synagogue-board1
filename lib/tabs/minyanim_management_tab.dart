// lib/tabs/minyanim_management_tab.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:synagogue_display/data/data_provider.dart';
import 'package:synagogue_display/data/database_helper.dart';
import 'package:synagogue_display/data/models.dart';
import 'package:synagogue_display/data/zmanim_helper.dart';
import 'package:synagogue_display/services/minyan_data_service.dart';

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
      case MinyanScheduleType.SHABBAT_DAY: return 'שבת/חג (יום)';
      case MinyanScheduleType.MOTZEI_SHABBAT: return 'מוצ"ש';
      case MinyanScheduleType.EREV_SHABBAT: return 'ערב שבת/חג (מנחה/ערבית)';
      case MinyanScheduleType.SPECIAL_DATE: return 'תאריך מיוחד';
    }
  }

  // --- דיאלוג ניהול ימים מיוחדים ---
  Future<void> _showSpecialDaysManager(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) => const SpecialDaysManagerDialog(),
    ).then((_) {
      // רענון הנתונים אחרי סגירת הדיאלוג
      Provider.of<DataProvider>(context, listen: false).fetchAllData();
    });
  }

  Future<void> _showDuplicateDialog(BuildContext context) async {
    MinyanScheduleType? source;
    MinyanScheduleType? target;
    
    return showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('שכפול מניינים'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('פעולה זו תעתיק את כל המניינים מהסוג הנבחר לסוג היעד.', style: TextStyle(fontSize: 13)),
              const SizedBox(height: 16),
              DropdownButtonFormField<MinyanScheduleType>(
                decoration: const InputDecoration(labelText: 'העתק מ...'),
                value: source,
                items: MinyanScheduleType.values.where((t) => t != MinyanScheduleType.SPECIAL_DATE).map((t) => DropdownMenuItem(value: t, child: Text(_getScheduleTypeName(t)))).toList(),
                onChanged: (v) => setState(() => source = v),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<MinyanScheduleType>(
                decoration: const InputDecoration(labelText: 'אל...'),
                value: target,
                items: MinyanScheduleType.values.where((t) => t != MinyanScheduleType.SPECIAL_DATE).map((t) => DropdownMenuItem(value: t, child: Text(_getScheduleTypeName(t)))).toList(),
                onChanged: (v) => setState(() => target = v),
              ),
            ],
          ),
          actions: [
            TextButton(child: const Text('ביטול'), onPressed: () => Navigator.of(ctx).pop()),
            ElevatedButton(
              child: const Text('בצע שכפול'),
              onPressed: (source == null || target == null || source == target) 
                ? null 
                : () async {
                    final db = DatabaseHelper();
                    final allMinyanim = await db.getMinyanim();
                    final sourceMinyanim = allMinyanim.where((m) => m.scheduleType == source).toList();
                    
                    int count = 0;
                    for (var m in sourceMinyanim) {
                      final newMinyan = Minyan(
                        name: m.name,
                        roomId: m.roomId,
                        scheduleType: target!,
                        timeType: m.timeType,
                        time: m.time,
                        relativeZman: m.relativeZman,
                        relativeOffsetMinutes: m.relativeOffsetMinutes
                      );
                      await db.insertMinyan(newMinyan);
                      count++;
                    }
                    
                    if (context.mounted) {
                        Navigator.of(ctx).pop();
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('שוכפלו בהצלחה $count מניינים')));
                        Provider.of<DataProvider>(context, listen: false).fetchAllData();
                    }
                },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddOrEditMinyanDialog(BuildContext context, List<Room> rooms, [Minyan? minyanToEdit]) async {
    final formKey = GlobalKey<FormState>();
    final specialSchedules = Provider.of<DataProvider>(context, listen: false).specialSchedules;

    final nameController = TextEditingController(text: minyanToEdit?.name);
    final timeController = TextEditingController(text: minyanToEdit?.time);
    final offsetController = TextEditingController(text: minyanToEdit?.relativeOffsetMinutes?.toString() ?? '0');

    Room? selectedRoom = rooms.firstWhereOrNull((r) => r.id == minyanToEdit?.roomId);
    if (selectedRoom == null && rooms.isNotEmpty) {
      selectedRoom = rooms.first;
    }

    MinyanScheduleType selectedScheduleType = minyanToEdit?.scheduleType ?? MinyanScheduleType.REGULAR;
    int? selectedSpecialScheduleId = minyanToEdit?.specialScheduleId;
    
    // קביעת הערך הראשוני ל-Dropdown המשולב
    String dropdownValue;
    if (selectedSpecialScheduleId != null) {
      dropdownValue = 'SPECIAL_$selectedSpecialScheduleId';
    } else {
      dropdownValue = selectedScheduleType.name;
    }

    MinyanTimeType selectedTimeType = minyanToEdit?.timeType ?? MinyanTimeType.FIXED;
    RelativeZman? selectedRelativeZman = minyanToEdit?.relativeZman ?? RelativeZman.sunrise;

    return showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(minyanToEdit == null ? 'הוספת מניין חדש' : 'עריכת מניין'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              
              // בניית רשימת האפשרויות ל-Dropdown
              List<DropdownMenuItem<String>> scheduleItems = [];
              
              // הוספת סוגים רגילים
              for (var type in MinyanScheduleType.values) {
                if (type != MinyanScheduleType.SPECIAL_DATE) {
                   scheduleItems.add(DropdownMenuItem(value: type.name, child: Text(_getScheduleTypeName(type))));
                }
              }
              
              // הוספת מפריד וכותרת אם יש ימים מיוחדים
              if (specialSchedules.isNotEmpty) {
                 scheduleItems.add(const DropdownMenuItem(enabled: false, value: 'DIVIDER', child: Divider()));
                 scheduleItems.add(const DropdownMenuItem(enabled: false, value: 'HEADER', child: Text('--- לוחות מיוחדים ---', style: TextStyle(fontSize: 12, color: Colors.grey))));
                 
                 for (var schedule in specialSchedules) {
                    scheduleItems.add(DropdownMenuItem(
                      value: 'SPECIAL_${schedule.id}',
                      child: Text('📅 ${schedule.name} (${DateFormat('dd/MM').format(schedule.date)})')
                    ));
                 }
              }

              return Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      TextFormField( controller: nameController, decoration: const InputDecoration(labelText: 'שם התפילה (למשל, שחרית)'), validator: (v) => v!.isEmpty ? 'חובה למלא שם' : null, ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<Room>( hint: const Text('בחר חדר'), value: selectedRoom, items: rooms.map((room) => DropdownMenuItem(value: room, child: Text(room.name))).toList(), onChanged: (Room? newValue) => setState(() => selectedRoom = newValue), validator: (v) => v == null ? 'חובה לבחור חדר' : null, ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(labelText: 'תזמון'),
                        value: dropdownValue,
                        items: scheduleItems,
                        onChanged: (v) {
                          if (v != null) {
                            setState(() {
                              dropdownValue = v;
                              if (v.startsWith('SPECIAL_')) {
                                selectedSpecialScheduleId = int.parse(v.split('_')[1]);
                                selectedScheduleType = MinyanScheduleType.SPECIAL_DATE; // סוג פנימי לסימון
                              } else {
                                selectedSpecialScheduleId = null;
                                selectedScheduleType = MinyanScheduleType.values.firstWhere((e) => e.name == v);
                              }
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<MinyanTimeType>( decoration: const InputDecoration(labelText: 'סוג הזמן'), value: selectedTimeType, items: const [ DropdownMenuItem(value: MinyanTimeType.FIXED, child: Text('שעה קבועה')), DropdownMenuItem(value: MinyanTimeType.RELATIVE, child: Text('יחסי לזמן ביום')), ], onChanged: (v) => setState(() => selectedTimeType = v!), ),
                      const SizedBox(height: 16),
                      if (selectedTimeType == MinyanTimeType.FIXED)
                        TextFormField( controller: timeController, decoration: const InputDecoration(labelText: 'שעה (פורמט HH:mm)'), validator: (v) { if (v!.isEmpty) return 'חובה למלא שעה'; if (!RegExp(r'^\d{2}:\d{2}$').hasMatch(v)) return 'פורמט לא תקין'; return null; }, )
                      else
                        Row( crossAxisAlignment: CrossAxisAlignment.end, children: [ Expanded( flex: 2, child: DropdownButtonFormField<RelativeZman>( isExpanded: true, decoration: const InputDecoration(labelText: 'יחסית ל'), value: selectedRelativeZman, items: RelativeZman.values.map((zman) => DropdownMenuItem( value: zman, child: Text(ZmanimHelper.zmanimDisplayNames[zman]!, overflow: TextOverflow.ellipsis), )).toList(), onChanged: (v) => setState(() => selectedRelativeZman = v), ), ), const SizedBox(width: 8), Expanded( flex: 1, child: TextFormField( controller: offsetController, decoration: const InputDecoration(labelText: 'דקות (+/-)'), keyboardType: TextInputType.number, validator: (v) => int.tryParse(v!) == null ? 'מספר' : null, ), ), ], ),
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
                    specialScheduleId: selectedSpecialScheduleId,
                    timeType: selectedTimeType,
                    time: selectedTimeType == MinyanTimeType.FIXED ? timeController.text : null,
                    relativeZman: selectedTimeType == MinyanTimeType.RELATIVE ? selectedRelativeZman : null,
                    relativeOffsetMinutes: selectedTimeType == MinyanTimeType.RELATIVE ? int.parse(offsetController.text) : null,
                  );
                  
                  if (newMinyan.id == null) {
                    await DatabaseHelper().insertMinyan(newMinyan);
                  } else {
                     // עבור עדכון - צריך להשתמש בפונקציה אחרת אם יש, או למחוק ולהכניס. 
                     // כרגע insertMinyan עושה conflict replace אז זה בסדר לעדכון גם כן אם ה ID קיים
                     await DatabaseHelper().insertMinyan(newMinyan);
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

  void _handleExport(BuildContext context) async {
    final service = MinyanDataService();
    try {
      final path = await service.exportMinyanimToJson();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('המניינים יוצאו בהצלחה!\nנשמר ב: $path')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('שגיאה בייצוא: ${e.toString()}')),
      );
    }
  }

  void _handleImport(BuildContext context) async {
    final service = MinyanDataService();
    try {
      final count = await service.importMinyanimFromJson();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$count מניינים יובאו בהצלחה!')),
      );
      Provider.of<DataProvider>(context, listen: false).fetchAllData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('שגיאה בייבוא: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DataProvider>(
      builder: (context, dataProvider, child) {
        final minyanim = dataProvider.minyanim;
        final rooms = dataProvider.rooms;

        return Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: const Text('ניהול מניינים'),
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            elevation: 1,
            actions: [
              TextButton.icon(
                icon: const Icon(Icons.calendar_today),
                label: const Text('ימים מיוחדים'),
                onPressed: () => _showSpecialDaysManager(context),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                icon: const Icon(Icons.copy_all),
                label: const Text('שכפול'),
                onPressed: () => _showDuplicateDialog(context),
              ),
              IconButton(
                icon: const Icon(Icons.file_upload_outlined),
                tooltip: 'ייבוא',
                onPressed: () => _handleImport(context),
              ),
              IconButton(
                icon: const Icon(Icons.file_download_outlined),
                tooltip: 'ייצוא',
                onPressed: () => _handleExport(context),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: ListView.builder(
            padding: const EdgeInsets.all(8),
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
              
              String scheduleDisplay;
              if (minyan.specialScheduleId != null) {
                final special = dataProvider.specialSchedules.firstWhereOrNull((s) => s.id == minyan.specialScheduleId);
                scheduleDisplay = special != null ? '📅 ${special.name}' : 'יום מיוחד (נמחק)';
              } else {
                scheduleDisplay = _getScheduleTypeName(minyan.scheduleType);
              }

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  leading: const Icon(Icons.access_time_filled_rounded),
                  title: Text('${minyan.name} - ${minyan.roomName ?? 'חדר לא ידוע'}'),
                  subtitle: Text('$timeDisplay ($scheduleDisplay)'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // כפתור עריכה
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _showAddOrEditMinyanDialog(context, rooms, minyan),
                      ),
                      // כפתור מחיקה
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
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
            tooltip: 'הוסף מניין',
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }
}

class SpecialDaysManagerDialog extends StatefulWidget {
  const SpecialDaysManagerDialog({Key? key}) : super(key: key);

  @override
  _SpecialDaysManagerDialogState createState() => _SpecialDaysManagerDialogState();
}

class _SpecialDaysManagerDialogState extends State<SpecialDaysManagerDialog> {
  final TextEditingController _nameController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Consumer<DataProvider>(
      builder: (context, dataProvider, child) {
        return AlertDialog(
          title: const Text('ניהול ימים מיוחדים'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // טופס הוספה
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _nameController,
                        decoration: const InputDecoration(labelText: 'שם היום (למשל: פורים)'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 1,
                      child: TextButton.icon(
                        icon: const Icon(Icons.calendar_month),
                        label: Text(DateFormat('dd/MM').format(_selectedDate)),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate,
                            firstDate: DateTime.now().subtract(const Duration(days: 365)),
                            lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                          );
                          if (picked != null) {
                            setState(() => _selectedDate = picked);
                          }
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle, color: Colors.green),
                      onPressed: () async {
                        if (_nameController.text.isNotEmpty) {
                          await DatabaseHelper().insertSpecialSchedule(
                            SpecialSchedule(name: _nameController.text, date: _selectedDate)
                          );
                          _nameController.clear();
                          Provider.of<DataProvider>(context, listen: false).fetchAllData();
                        }
                      },
                    )
                  ],
                ),
                const Divider(height: 30),
                const Text('ימים קיימים:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                // רשימת ימים קיימים
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: dataProvider.specialSchedules.length,
                    itemBuilder: (context, index) {
                      final schedule = dataProvider.specialSchedules[index];
                      return ListTile(
                        title: Text(schedule.name),
                        subtitle: Text(DateFormat('dd/MM/yyyy').format(schedule.date)),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            await DatabaseHelper().deleteSpecialSchedule(schedule.id!);
                            Provider.of<DataProvider>(context, listen: false).fetchAllData();
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(child: const Text('סגור'), onPressed: () => Navigator.of(context).pop()),
          ],
        );
      },
    );
  }
}