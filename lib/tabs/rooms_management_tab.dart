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
      builder: (ctx) => AlertDialog( /* ... קוד הדיאלוג נשאר זהה ... */ ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dataProvider = Provider.of<DataProvider>(context, listen: false);

    return Scaffold(
      body: Selector<DataProvider, List<Room>>(
        // האזן רק לרשימת החדרים
        selector: (_, provider) => provider.rooms,
        builder: (context, rooms, child) {
          return ListView.builder(
            itemCount: rooms.length,
            itemBuilder: (context, index) {
              final room = rooms[index];
              return Card(
                key: ValueKey(room.id),
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