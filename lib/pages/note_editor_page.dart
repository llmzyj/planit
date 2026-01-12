import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/note.dart';
import '../providers/app_model.dart';

class NoteEditorPage extends StatefulWidget {
  final Note? note;
  const NoteEditorPage({super.key, this.note});
  @override
  State<NoteEditorPage> createState() => _NoteEditorPageState();
}

class _NoteEditorPageState extends State<NoteEditorPage> {
  late TextEditingController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.note?.content ?? "");
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 253, 240),
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        actions: [
          if (widget.note != null) IconButton(onPressed: (){
             Provider.of<AppModel>(context, listen: false).deleteNote(widget.note!.id);
             Navigator.pop(context);
          }, icon: const Icon(Icons.delete, color: Colors.brown)),
          IconButton(onPressed: _save, icon: const Icon(Icons.check, color: Colors.brown))
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: TextField(
          controller: _ctrl, 
          maxLines: null, 
          expands: true, 
          decoration: const InputDecoration(border: InputBorder.none, hintText: "输入笔记...")
        ),
      ),
    );
  }
  void _save() {
    if (_ctrl.text.isEmpty) return;
    final model = Provider.of<AppModel>(context, listen: false);
    if (widget.note == null) {
      model.saveNote(Note(id: const Uuid().v4(), content: _ctrl.text, createTime: DateTime.now()));
    } else {
      model.saveNote(Note(id: widget.note!.id, content: _ctrl.text, createTime: widget.note!.createTime));
    }
    if (mounted) Navigator.pop(context);
  }
}