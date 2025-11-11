import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // <--- תיקון הייבוא הקריטי
import 'package:provider/provider.dart';
import 'package:synagogue_display/data/data_provider.dart';
import 'package:synagogue_display/data/database_helper.dart';
import 'package:synagogue_display/data/models.dart';
import 'package:synagogue_display/data/zmanim_helper.dart';

class MinyanimManagementTab extends StatelessWidget {
  const MinyanimManagementTab({Key? key}) : super(key: key);

  String _getScheduleTypeName(MinyanScheduleType type) {
    switch (type) {
      case MinyanScheduleType.REGULAR: return 'יום חול';
      case MinyanScheduleType.SHABBAT_DAY: return 'שבת/חג';
      case MinyanScheduleType.MOTZEI_SHABBAT: return 'מוצ"ש';
    }
  }

  Future<void> _showAddMinyanDialog(BuildContext context, List<Room> rooms) async {
    final timeController = TextEditingController();
    final customNameController = TextEditingController();
    final offsetController = TextEditingController(text: '0');

    Room? selectedRoom;
    MinyanScheduleType selectedScheduleType = MinyanScheduleType.REGULAR;
    String selectedPrayer = 'שחרית';
    const otherOption = 'אחר...';
    final prayerOptions = ['שחרית', 'מנחה', 'ערבית', 'מוסף', otherOption];
    
    MinyanTimeType selectedTimeType = MinyanTimeType.FIXED;
    RelativeZman selectedZman = RelativeZman.sunset;


    return showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: const Text('הוספת מניין חדש'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    DropdownButtonFormField<Room>(
                      hint: const Text('בחר חדר'), value: selectedRoom,
                      items: rooms.map((room) => DropdownMenuItem(value: room, child: Text(room.name))).toList(),
                      onChanged: (Room? newValue) => setState(() => selectedRoom = newValue),
                      validator: (value) => value == null ? 'חובה לבחור חדר' : null,
                    ),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'סוג תפילה'), value: selectedPrayer,
                      items: prayerOptions.map((prayer) => DropdownMenuItem(value: prayer, child: Text(prayer))).toList(),
                      onChanged: (String? newValue) => setState(() => selectedPrayer = newValue!),
                    ),
                    if (selectedPrayer == otherOption)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: TextField(controller: customNameController, decoration: const InputDecoration(labelText: 'שם מותאם אישית')),
                      ),
                    
                    const SizedBox(height: 16),
                    DropdownButtonFormField<MinyanTimeType>(
                      decoration: const InputDecoration(labelText: 'סוג זמן'), value: selectedTimeType,
                      items: const [
                        DropdownMenuItem(value: MinyanTimeType.FIXED, child: Text('זמן קבוע')),
                        DropdownMenuItem(value: MinyanTimeType.RELATIVE, child: Text('יחסית לזמן בלוח')),
                      ],
                      onChanged: (MinyanTimeType? newValue) => setState(() => selectedTimeType = newValue!),
                    ),

                    if (selectedTimeType == MinyanTimeType.FIXED)
                      TextField(controller: timeController, decoration: const InputDecoration(labelText: 'שעה (למשל, 08:00)')),
                    
                    if (selectedTimeType == MinyanTimeType.RELATIVE) ...[
                      const SizedBox(height: 8),
                      DropdownButtonFormField<RelativeZman>(
                        decoration: const InputDecoration(labelText: 'יחסית ל...'), value: selectedZman,
                        isExpanded: true,
                        items: ZmanimHelper.zmanimDisplayNames.entries.map((entry) => DropdownMenuItem(value: entry.key, child: Text(entry.value, overflow: TextOverflow.ellipsis))).toList(),
                        onChanged: (RelativeZman? newValue) => setState(() => selectedZman = newValue!),
                      ),
                      TextField(
                        controller: offsetController,
                        decoration: const InputDecoration(labelText: 'הפרש בדקות (לפני: מספר שלילי)'),
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^-?[0-9]*'))],
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(child: const Text('ביטול'), onPressed: () => Navigator.of(ctx).pop()),
                TextButton(
                  child: const Text('שמירה'),
                  onPressed: () async {
                    final prayerName = selectedPrayer == otherOption ? customNameController.text : selectedPrayer;
                    if (selectedRoom == null || prayerName.isEmpty) return;

                    Minyan newMinyan;
                    if (selectedTimeType == MinyanTimeType.FIXED) {
                      if (timeController.text.isEmpty) return;
                      newMinyan = Minyan(
                        name: prayerName, roomId: selectedRoom!.id!, scheduleType: selectedScheduleType,
                        timeType: MinyanTimeType.FIXED, time: timeController.text,
                      );
                    } else {
                      final offset = int.tryParse(offsetController.text) ?? 0;
                      newMinyan = Minyan(
                        name: prayerName, roomId: selectedRoom!.id!, scheduleType: selectedScheduleType,
                        timeType: MinyanTimeType.RELATIVE, relativeZman: selectedZman, relativeOffsetMinutes: offset,
                      );
                    }
                    
                    await DatabaseHelper().insertMinyan(newMinyan);
                    Provider.of<DataProvider>(context, listen: false).fetchAllData();
                    Navigator.of(ctx).pop();
                  },
                ),
              ],
            );
          },
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
              return Card(
                child: ListTile(
                  leading: Text(minyan.time ?? 'יחושב', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  title: Text(minyan.name),
                  subtitle: Text('${minyan.roomName ?? '...'} - ${_getScheduleTypeName(minyan.scheduleType)}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      await DatabaseHelper().deleteMinyan(minyan.id!);
                      Provider.of<DataProvider>(context, listen: false).fetchAllData();
                    },
                  ),
                ),
              );
            },
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: rooms.isEmpty ? null : () => _showAddMinyanDialog(context, rooms),
            backgroundColor: rooms.isEmpty ? Colors.grey : Theme.of(context).colorScheme.primary,
            tooltip: rooms.isEmpty ? 'יש להוסיף חדרים תחילה' : 'הוסף מניין',
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }
}