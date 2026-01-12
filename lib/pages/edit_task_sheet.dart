import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/task.dart';
import '../providers/app_model.dart';

// 全局辅助方法，方便在任何页面调用
Future<void> showEditTaskSheet(BuildContext context, Task? task) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => EditTaskSheet(task: task),
  );
}

class EditTaskSheet extends StatefulWidget {
  final Task? task;
  const EditTaskSheet({super.key, this.task});

  @override
  State<EditTaskSheet> createState() => _EditTaskSheetState();
}

class _EditTaskSheetState extends State<EditTaskSheet> {
  final _titleCtrl = TextEditingController();
  final _locCtrl = TextEditingController();
  DateTime? _date;
  TimeOfDay? _start, _end;

  @override
  void initState() {
    super.initState();
    final t = widget.task;
    _titleCtrl.text = t?.title ?? "";
    _locCtrl.text = t?.location ?? "";
    
    if (t != null) {
      _date = t.date;
      _start = t.startTime;
      _end = t.endTime;
    } else {
      // 默认选中当前 Model 中的日期
      _date = Provider.of<AppModel>(context, listen: false).selectedDate; 
    }
  }

  @override
  Widget build(BuildContext context) {
    String typeText = "待办 (无日期)";
    if (_date != null) {
      typeText = _start != null ? "日程 (具体时间)" : "日程 (全天)";
    }

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 20, top: 20, left: 20, right: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.task == null ? "新建事项" : "编辑事项", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text(typeText, style: TextStyle(fontSize: 12, color: Theme.of(context).primaryColor)),
              ],
            ),
            const Spacer(),
            if (widget.task != null) IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: (){
              Provider.of<AppModel>(context, listen: false).deleteTask(widget.task!.id);
              if (mounted) Navigator.pop(context);
            })
          ]),
          const SizedBox(height: 10),
          TextField(controller: _titleCtrl, decoration: const InputDecoration(labelText: "内容/标题", border: OutlineInputBorder())),
          const SizedBox(height: 10),
          TextField(controller: _locCtrl, decoration: const InputDecoration(labelText: "地点 (选填)", border: OutlineInputBorder())),
          const SizedBox(height: 20),
          
          // 日期行
          Row(
            children: [
              const Icon(Icons.calendar_today, color: Colors.grey),
              const SizedBox(width: 8),
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final d = await showDatePicker(
                      context: context, 
                      initialDate: _date ?? DateTime.now(), 
                      firstDate: DateTime(2020), 
                      lastDate: DateTime(2030)
                    );
                    if (d != null) setState(() => _date = d);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                    decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(4)),
                    child: Text(_date == null ? "无日期 (待办)" : DateFormat('yyyy-MM-dd').format(_date!)),
                  ),
                ),
              ),
              if (_date != null) 
                 IconButton(
                   icon: const Icon(Icons.clear), 
                   tooltip: "清除日期",
                   onPressed: () => setState(() {
                     _date = null;
                     _start = null; 
                     _end = null;
                   }),
                 )
            ],
          ),

          const SizedBox(height: 10),

          // 时间行 (仅当选择了日期时显示)
          if (_date != null) 
            Row(
              children: [
                const Icon(Icons.access_time, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final t = await showTimePicker(context: context, initialTime: _start ?? const TimeOfDay(hour: 9, minute: 0));
                            if (t != null) setState(() => _start = t);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                            decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(4)),
                            child: Text(_start == null ? "开始时间" : _start!.format(context)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final t = await showTimePicker(context: context, initialTime: _end ?? const TimeOfDay(hour: 10, minute: 0));
                            if (t != null) setState(() => _end = t);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                            decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(4)),
                            child: Text(_end == null ? "结束时间" : _end!.format(context)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_start != null)
                  IconButton(
                    icon: const Icon(Icons.clear),
                    tooltip: "清除时间",
                    onPressed: () => setState(() {
                      _start = null;
                      _end = null;
                    }),
                  )
              ],
            ),

          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              if (_titleCtrl.text.isEmpty) return;
              final task = Task(
                id: widget.task?.id ?? const Uuid().v4(),
                title: _titleCtrl.text,
                location: _locCtrl.text,
                date: _date,
                startTime: _start,
                endTime: _end,
                isDone: widget.task?.isDone ?? false,
                isClass: widget.task?.isClass ?? false,
              );
              
              final model = Provider.of<AppModel>(context, listen: false);
              if (widget.task == null) {
                 model.addTask(task);
              } else {
                 model.updateTask(task);
              }
              if (mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary, 
              foregroundColor: Colors.white, 
              padding: const EdgeInsets.symmetric(vertical: 14)
            ),
            child: const Text("保存"),
          )
        ],
      ),
    );
  }
}