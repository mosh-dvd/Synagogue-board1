// lib/tabs/messages_management_tab.dart

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import 'package:synagogue_display/data/data_provider.dart';
import 'package:synagogue_display/data/database_helper.dart';
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
      case MessageType.PDF: return Icons.picture_as_pdf;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DataProvider>(
      builder: (context, dataProvider, child) {
        final messages = dataProvider.messages;

        return Scaffold(
          body: ListView.builder(
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final message = messages[index];
              final titleText = message.type == MessageType.TEXT 
                  ? (message.content.length > 50 ? message.content.substring(0, 50) + '...' : message.content)
                  : p.basename(message.content);
                  
              return Card(
                child: ListTile(
                  leading: Icon(_getIconForType(message.type)),
                  title: Text(
                    titleText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text('משך: ${message.duration} שניות | חלונית: ${message.panelIndex} | ${message.isActive ? "פעיל" : "לא פעיל"}'),
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
                          await DatabaseHelper().deleteMessage(message.id!);
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
            onPressed: () => _showEditDialog(context),
            child: const Icon(Icons.add),
            tooltip: 'הוסף הודעה',
          ),
        );
      },
    );
  }
}