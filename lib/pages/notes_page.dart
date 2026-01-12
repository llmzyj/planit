import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_model.dart';
import '../db/db_helper.dart';
import 'note_editor_page.dart'; // 引入编辑器页面

class NotesPage extends StatelessWidget {
  const NotesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppModel>(
      builder: (context, model, child) {
        return Scaffold(
          appBar: AppBar(title: const Text("笔记")),
          floatingActionButton: FloatingActionButton(
            heroTag: "fab_add_note",
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NoteEditorPage())),
            child: const Icon(Icons.add),
          ),
          body: GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, 
              crossAxisSpacing: 8, 
              mainAxisSpacing: 8
            ),
            itemCount: model.notes.length,
            itemBuilder: (ctx, i) {
              final note = model.notes[i];
              return GestureDetector(
                onTap: () async {
                   // 点击时获取完整内容
                   final fullNote = await DBHelper.instance.getNoteById(note.id);
                   if (context.mounted && fullNote != null) {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => NoteEditorPage(note: fullNote)));
                   }
                },
                child: Card(
                  color: const Color.fromARGB(255, 255, 252, 229), 
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormat('MM-dd HH:mm').format(note.createTime), 
                          style: const TextStyle(fontSize: 10, color: Colors.brown)
                        ),
                        const SizedBox(height: 8),
                        Text(
                          note.content, 
                          maxLines: 8, 
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 14)
                        ),
                      ],
                    ),
                  )
                ),
              );
            },
          ),
        );
      }
    );
  }
}