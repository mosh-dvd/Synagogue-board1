import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:synagogue_display/data/data_provider.dart';
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
    final dataProvider = Provider.of<DataProvider>(context, listen: false);

    return showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('הוספת מניין חדש'),
        content: StatefulBuilder( /* ... קוד הדיאלוג נשאר זהה ... */ ),
        actions: [
          TextButton(child: const Text('ביטול'), onPressed: () => Navigator.of(ctx).pop()),
          TextButton(
            child: const Text('שמירה'),
            onPressed: () async {
              if (selectedRoom != null && nameController.text.isNotEmpty && timeController.text.isNotEmpty) {
                final newMinyan = Minyan(name: nameController.text, time: timeController.text, roomId: selectedRoom!.id!, scheduleType: selectedType);
                await dataProvider.addMinyan(newMinyan);
                Navigator.of(ctx).pop();
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // אנו עדיין צריכים גישה לכל הפרויידר עבור הדיאלוג
    final dataProvider = Provider.of<DataProvider>(context, listen: false);
    final rooms = dataProvider.rooms;

    return Scaffold(
      body: Selector<DataProvider, List<Minyan>>(
        // שלב 1: בחר להאזין רק לרשימת המניינים
        selector: (_, provider) => provider.minyanim,
        
        // שלב 2: ה-builder ירוץ רק כאשר רשימת המניינים משתנה
        builder: (context, minyanim, child) {
          return ListView.builder(
            itemCount: minyanim.length,
            itemBuilder: (context, index) {
              final minyan = minyanim[index];
              return Card(
                key: ValueKey(minyan.id),
                child: ListTile(
                  leading: Text(minyan.time, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  title: Text(minyan.name),
                  subtitle: Text('${minyan.roomName ?? ''} - ${_getScheduleTypeName(minyan.scheduleType)}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      await dataProvider.deleteMinyan(minyan.id!);
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: rooms.isEmpty ? null : () => _showAddMinyanDialog(context, rooms),
        tooltip: rooms.isEmpty ? 'יש להוסיף חדרים תחילה' : 'הוסף מניין',
        child: const Icon(Icons.add),
      ),
    );
  }
}