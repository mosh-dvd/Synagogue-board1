import 'dart:io';
import 'package:flutter/material.dart';
// ... שאר ה-imports

class MessageEditDialog extends StatefulWidget {
  final Message? message;
  const MessageEditDialog({Key? key, this.message}) : super(key: key);
  @override
  _MessageEditDialogState createState() => _MessageEditDialogState();
}

class _MessageEditDialogState extends State<MessageEditDialog> {
  // ... (כל המשתנים והפונקציות נשארים זהים)

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.message == null ? 'הוספת הודעה חדשה' : 'עריכת הודעה'),
      content: SizedBox(
        // ******** התיקון כאן: הגדרת רוחב קבוע לתוכן ********
        width: 500, 
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ... כל התוכן של הדיאלוג נשאר זהה
              ],
            ),
          ),
        ),
      ),
      actions: [ /* ... כפתורים ... */ ],
    );
  }
}