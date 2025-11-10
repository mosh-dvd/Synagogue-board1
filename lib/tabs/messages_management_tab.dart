import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import 'package:synagogue_display/data/data_provider.dart';
import 'package:synagogue_display/data/models.dart';
import 'package:synagogue_display/dialogs/message_edit_dialog.dart';

class MessagesManagementTab extends StatelessWidget {
  const MessagesManagementTab({Key? key}) : super(key: key);

  void _showEditDialog(BuildContext context, [Message? message]) { /* ... */ }
  IconData _getIconForType(MessageType type) { /* ... */ }

  @override
  Widget build(BuildContext context) {
    final dataProvider = Provider.of<DataProvider>(context);
    final messages = dataProvider.messages;

    return Scaffold(
      body: ListView.builder(
        itemCount: messages.length,
        itemBuilder: (context, index) {
          final message = messages[index];
          return Card(
            // ******** התיקון כאן: הוספת מפתח ייחודי ********
            key: ValueKey(message.id),
            child: ListTile(
              leading: Icon(_getIconForType(message.type)),
              title: Text( /* ... */ ),
              subtitle: Text( /* ... */ ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton( /* ... */ ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      await dataProvider.deleteMessage(message.id!);
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton( /* ... */ ),
    );
  }
}