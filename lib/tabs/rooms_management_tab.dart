import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:synagogue_display/data/data_provider.dart';
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
    final dataProvider = Provider.of<DataProvider>(context, listen: false);

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
                await dataProvider.addRoom(Room(name: nameController.text));
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
    final dataProvider = Provider.of<DataProvider>(context);
    final rooms = dataProvider.rooms;

    return Scaffold(
      body: ListView.builder(
        itemCount: rooms.length,
        itemBuilder: (context, index) {
          final room = rooms[index];
          return Card(
            key: ValueKey(room.id), // הוספת מפתח ייחודי
            child: ListTile(
              title: Text(room.name),
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
                      await dataProvider.deleteRoom(room.id!);
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
  }
}