import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:synagogue_display/data/data_provider.dart';
import 'package:synagogue_display/data/models.dart';
import 'package:synagogue_display/dialogs/room_settings_dialog.dart';

class RoomsManagementTab extends StatelessWidget {
  const RoomsManagementTab({Key? key}) : super(key: key);

  void _showSettingsDialog(BuildContext context, Room room) { /* ... */ }
  Future<void> _showAddRoomDialog(BuildContext context) async { /* ... */ }

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
            // ******** התיקון כאן: הוספת מפתח ייחודי ********
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
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddRoomDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}