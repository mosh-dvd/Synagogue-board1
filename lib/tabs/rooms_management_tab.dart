import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:synagogue_display/data/data_provider.dart';
import 'package:synagogue_display/data/database_helper.dart';
import 'package:synagogue_display/data/models.dart';
import 'package:synagogue_display/dialogs/room_settings_dialog.dart';

class RoomsManagementTab extends StatelessWidget {
  const RoomsManagementTab({Key? key}) : super(key: key);

  void _showSettingsDialog(BuildContext context, Room room) {
    showDialog(
      context: context,
      builder: (ctx) => RoomSettingsDialog(room: room),
    ).then((_) {
      Provider.of<DataProvider>(context, listen: false).fetchAllData();
    });
  }

  Future<void> _showAddRoomDialog(BuildContext context) async {
    final nameController = TextEditingController();
    return showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('הוספת חדר חדש'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: 'שם החדר'),
          textAlign: TextAlign.right,
        ),
        actions: [
          TextButton(child: const Text('ביטול'), onPressed: () => Navigator.of(ctx).pop()),
          TextButton(
            child: const Text('שמירה'),
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                await DatabaseHelper().insertRoom(Room(name: nameController.text));
                Provider.of<DataProvider>(context, listen: false).fetchAllData();
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
    return Consumer<DataProvider>(
      builder: (context, dataProvider, child) {
        final rooms = dataProvider.rooms;
        return Scaffold(
          body: ListView.builder(
            itemCount: rooms.length,
            itemBuilder: (context, index) {
              final room = rooms[index];
              return Card(
                child: ListTile(
                  title: Text(room.name),
                  leading: Switch( // הוספת המתג
                    value: room.isDisplayActive,
                    onChanged: (bool value) async {
                      final updatedRoom = Room(
                        id: room.id,
                        name: room.name,
                        showClock: room.showClock,
                        showCalendar: room.showCalendar,
                        showZmanim: room.showZmanim,
                        displayMode: room.displayMode,
                        activeMessagePanels: room.activeMessagePanels,
                        isDisplayActive: value, // העברת הערך החדש
                      );
                      await DatabaseHelper().updateRoom(updatedRoom);
                      Provider.of<DataProvider>(context, listen: false).fetchAllData();
                    },
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.settings, color: Colors.blueGrey),
                        onPressed: () => _showSettingsDialog(context, room),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          await DatabaseHelper().deleteRoom(room.id!);
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
            onPressed: () => _showAddRoomDialog(context),
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }
}