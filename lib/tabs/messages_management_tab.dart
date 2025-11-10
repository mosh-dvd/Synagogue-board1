import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import 'package:synagogue_display/data/data_provider.dart';
import 'package:synagogue_display/data/models.dart';
import 'package:synagogue_display/dialogs/message_edit_dialog.dart';

class MessagesManagementTab extends StatelessWidget {
  const MessagesManagementTab({Key? key}) : super(key: key);

  void _showEditDialog(BuildContext context, [Message? message]) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => MessageEditDialog(message: message),
    ).then((result) {
      if (result == true) {
        Provider.of<DataProvider>(context, listen: false).fetchAllData();
      }
    });
  }

  IconData _getIconForType(MessageType type) {
    switch (type) {
      case MessageType.TEXT: return Icons.text_fields;
      case MessageType.IMAGE: return Icons.image;
      case MessageType.PDF: return Icons.image;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dataProvider = Provider.of<DataProvider>(context, listen: false);

    return Scaffold(
      body: Selector<DataProvider, List<Message>>(
        selector: (_, provider) => provider.messages,
        builder: (context, messages, child) {
          return ListView.builder(
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final message = messages[index];
              return Card(
                key: ValueKey(message.id),
                child: ListTile(
                  leading: Icon(_getIconForType(message.type)),
                  title: Text(
                    message.type == MessageType.TEXT ? message.content : p.basename(message.content),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text('משך: ${message.duration} שניות | ${message.isActive ? "פעיל" : "לא פעיל"}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blueGrey),
                        onPressed: () => _showEditDialog(context, message),
                      ),
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
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showEditDialog(context),
        child: const Icon(Icons.add),
        tooltip: 'הוסף הודעה',
      ),
    );
  }
}