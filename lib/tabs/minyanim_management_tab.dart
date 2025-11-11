// lib/tabs/minyanim_management_tab.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:synagogue_display/data/data_provider.dart';
import 'package:synagogue_display/data/database_helper.dart';
import 'package:synagogue_display/data/models.dart';

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
    final nameController = TextEditingController();
    final timeController = TextEditingController();
    Room? selectedRoom;
    MinyanScheduleType selectedType = MinyanScheduleType.REGULAR;

    return showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('הוספת מניין חדש'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  DropdownButtonFormField<MinyanScheduleType>(
                    decoration: const InputDecoration(labelText: 'זמן'),
                    value: selectedType,
                    items: MinyanScheduleType.values.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(_getScheduleTypeName(type)),
                      );
                    }).toList(),
                    onChanged: (MinyanScheduleType? newValue) {
                      if (newValue != null) {
                        setState(() => selectedType = newValue);
                      }
                    },
                  ),
                  DropdownButtonFormField<Room>(
                    hint: const Text('בחר חדר'),
                    value: selectedRoom,
                    items: rooms.map((room) {
                      return DropdownMenuItem(value: room, child: Text(room.name));
                    }).toList(),
                    onChanged: (Room? newValue) {
                      setState(() => selectedRoom = newValue);
                    },
                  ),
                  TextField(controller: nameController, decoration: const InputDecoration(labelText: 'שם התפילה (למשל, שחרית)')),
                  TextField(controller: timeController, decoration: const InputDecoration(labelText: 'שעה (למשל, 08:00)')),
                ],
              );
            },
          ),
          actions: [
            TextButton(child: const Text('ביטול'), onPressed: () => Navigator.of(ctx).pop()),
            TextButton(
              child: const Text('שמירה'),
              onPressed: () async {
                if (selectedRoom != null && nameController.text.isNotEmpty && timeController.text.isNotEmpty) {
                  final newMinyan = Minyan(
                    name: nameController.text,
                    time: timeController.text,
                    roomId: selectedRoom!.id!,
                    scheduleType: selectedType,
                  );
                  await DatabaseHelper().insertMinyan(newMinyan);
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
        // --- התיקון כאן: הסרת בלוק ה-if ---
        // if (dataProvider.isLoading) {
        //   return const Center(child: CircularProgressIndicator());
        // }
        final minyanim = dataProvider.minyanim;
        final rooms = dataProvider.rooms;

        return Scaffold(
          body: ListView.builder(
            itemCount: minyanim.length,
            itemBuilder: (context, index) {
              final minyan = minyanim[index];
              return Card(
                child: ListTile(
                  leading: Text(minyan.time, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  title: Text(minyan.name),
                  subtitle: Text('${minyan.roomName ?? 'חדר לא ידוע'} - ${_getScheduleTypeName(minyan.scheduleType)}'),
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