// lib/dialogs/message_edit_dialog.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:synagogue_display/data/database_helper.dart';
import 'package:synagogue_display/data/models.dart';

class MessageEditDialog extends StatefulWidget {
  final Message? message;
  const MessageEditDialog({Key? key, this.message}) : super(key: key);

  @override
  _MessageEditDialogState createState() => _MessageEditDialogState();
}

class _MessageEditDialogState extends State<MessageEditDialog> {
  final _formKey = GlobalKey<FormState>();
  
  MessageType _typeSelection = MessageType.TEXT;
  final _contentController = TextEditingController();
  final _durationController = TextEditingController();
  bool _isActive = true;
  String? _finalFileName;
  bool _isConverting = false;

  List<Room> _allRooms = [];
  List<int> _selectedRoomIds = [];

  @override
  void initState() {
    super.initState();
    _loadInitialData();

    if (widget.message != null) {
      _typeSelection = widget.message!.type == MessageType.TEXT ? MessageType.TEXT : MessageType.IMAGE;
      _durationController.text = widget.message!.duration.toString();
      _isActive = widget.message!.isActive;
      if (widget.message!.type == MessageType.TEXT) {
        _contentController.text = widget.message!.content;
      } else {
        _finalFileName = widget.message!.content;
      }
    } else {
      _durationController.text = '10';
    }
  }
  
  Future<void> _loadInitialData() async {
    _allRooms = await DatabaseHelper().getRooms();
    if (widget.message != null) {
      _selectedRoomIds = await DatabaseHelper().getLinkedRoomIdsForMessage(widget.message!.id!);
    }
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _pickFile() async {
    if (_isConverting) return;
    setState(() => _isConverting = true);

    FilePickerResult? result;
    if (_typeSelection == MessageType.IMAGE) {
      result = await FilePicker.platform.pickFiles(type: FileType.image);
    } else if (_typeSelection == MessageType.PDF) {
      result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
    }
    
    if (result == null) {
      setState(() => _isConverting = false);
      return;
    }

    final sourcePath = result.files.single.path!;
    final originalFileName = p.basename(sourcePath);
    final appDir = await getApplicationSupportDirectory();
    final mediaDir = Directory(p.join(appDir.path, 'media'));
    if (!await mediaDir.exists()) {
      await mediaDir.create(recursive: true);
    }

    String fileNameToSave;

    try {
      if (_typeSelection == MessageType.PDF) {
        final imageBaseName = p.basenameWithoutExtension(originalFileName);
        final outputImagePath = p.join(mediaDir.path, imageBaseName);

        final processResult = await Process.run('pdftoppm', [
          '-png', '-f', '1', '-l', '1', sourcePath, outputImagePath,
        ]);

        if (processResult.exitCode == 0) {
          fileNameToSave = '$imageBaseName-1.png';
        } else {
          print('PDF conversion failed: ${processResult.stderr}');
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('שגיאה בהמרת קובץ ה-PDF')));
          setState(() => _isConverting = false);
          return;
        }
      } else {
        final newFile = File(p.join(mediaDir.path, originalFileName));
        await File(sourcePath).copy(newFile.path);
        fileNameToSave = originalFileName;
      }

      setState(() {
        _finalFileName = fileNameToSave;
      });
    } catch (e) {
      print('Error during file processing: $e');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('שגיאה בעיבוד הקובץ')));
    } finally {
      setState(() => _isConverting = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    
    MessageType finalType = _typeSelection == MessageType.TEXT ? MessageType.TEXT : MessageType.IMAGE;
    String content;

    if (_typeSelection == MessageType.TEXT) {
      content = _contentController.text;
    } else {
      if (_finalFileName == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('חובה לבחור קובץ')));
        return;
      }
      content = _finalFileName!;
    }
    
    final message = Message(
      id: widget.message?.id,
      type: finalType,
      content: content,
      duration: int.tryParse(_durationController.text) ?? 10,
      isActive: _isActive,
      displayOrder: widget.message?.displayOrder ?? 0,
    );

    int messageId;
    if (widget.message == null) {
      messageId = await DatabaseHelper().insertMessage(message);
    } else {
      messageId = message.id!;
      await DatabaseHelper().updateMessage(message);
    }
    
    await DatabaseHelper().linkMessageToRooms(messageId, _selectedRoomIds);
    
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.message == null ? 'הוספת הודעה חדשה' : 'עריכת הודעה'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<MessageType>(
                value: _typeSelection,
                items: const [
                  DropdownMenuItem(value: MessageType.TEXT, child: Text('הודעת טקסט')),
                  DropdownMenuItem(value: MessageType.IMAGE, child: Text('תמונה')),
                  DropdownMenuItem(value: MessageType.PDF, child: Text('PDF (עמוד ראשון)')),
                ],
                onChanged: _isConverting ? null : (v) => setState(() {
                  _typeSelection = v!;
                  _finalFileName = null;
                }),
                decoration: const InputDecoration(labelText: 'סוג ההודעה'),
              ),
              const SizedBox(height: 16),
              if (_typeSelection == MessageType.TEXT)
                TextFormField(
                  controller: _contentController,
                  decoration: const InputDecoration(labelText: 'תוכן ההודעה'),
                  maxLines: 4,
                  validator: (v) => v!.isEmpty ? 'חובה למלא תוכן' : null,
                )
              else
                Column(
                  children: [
                    if (_isConverting)
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Column(children: [CircularProgressIndicator(), SizedBox(height: 8), Text("ממיר קובץ...")]),
                      )
                    else
                      ElevatedButton.icon(
                        onPressed: _pickFile,
                        icon: const Icon(Icons.attach_file),
                        label: Text(_typeSelection == MessageType.IMAGE ? 'בחר תמונה' : 'בחר PDF'),
                      ),
                    if (_finalFileName != null) ...[
                      const SizedBox(height: 8),
                      Text('קובץ נשמר בתור: $_finalFileName', textAlign: TextAlign.center),
                    ]
                  ],
                ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _durationController,
                decoration: const InputDecoration(labelText: 'משך תצוגה (שניות)'),
                keyboardType: TextInputType.number,
                validator: (v) => (int.tryParse(v!) == null || int.parse(v) <= 0) ? 'מספר חיובי' : null,
              ),
              SwitchListTile(
                title: const Text('פעיל'),
                value: _isActive,
                onChanged: (v) => setState(() => _isActive = v),
              ),
              const Divider(height: 24),
              const Text('הצג במסכים הבאים:', style: TextStyle(fontWeight: FontWeight.bold)),
              const Text('(אם לא נבחר כלום, יוצג בכולם)'),
              const SizedBox(height: 8),
              _allRooms.isEmpty
                ? const Center(child: Text('טוען חדרים...'))
                : Wrap(
                    spacing: 8.0,
                    runSpacing: 4.0,
                    children: _allRooms.map((room) {
                      final isSelected = _selectedRoomIds.contains(room.id);
                      return ChoiceChip(
                        label: Text(room.name),
                        selectedColor: Theme.of(context).primaryColorLight,
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedRoomIds.add(room.id!);
                            } else {
                              _selectedRoomIds.remove(room.id!);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('ביטול')),
        ElevatedButton(onPressed: _isConverting ? null : _save, child: const Text('שמירה')),
      ],
    );
  }
}