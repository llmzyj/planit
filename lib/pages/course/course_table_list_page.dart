import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/app_model.dart';
import 'course_manage_page.dart';

class CourseTableListPage extends StatelessWidget {
  const CourseTableListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("我的课表")),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddTableDialog(context),
        label: const Text("新建课表"),
        icon: const Icon(Icons.add),
      ),
      body: Consumer<AppModel>(
        builder: (context, model, child) {
          if (model.courseTables.isEmpty) {
            return const Center(child: Text("暂无课表，请点击右下角新建"));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: model.courseTables.length,
            itemBuilder: (ctx, i) {
              final table = model.courseTables[i];
              return Card(
                elevation: table.isActive ? 4 : 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: table.isActive 
                    ? BorderSide(color: Theme.of(context).primaryColor, width: 2)
                    : BorderSide.none
                ),
                child: ListTile(
                  title: Text(table.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("开学日期: ${DateFormat('yyyy-MM-dd').format(table.semesterStart)}"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (table.isActive)
                        const Chip(label: Text("当前使用", style: TextStyle(fontSize: 10, color: Colors.white)), backgroundColor: Colors.green)
                      else
                        TextButton(
                          onPressed: () => model.switchActiveTable(table.id),
                          child: const Text("设为当前"),
                        ),
                      PopupMenuButton(
                        itemBuilder: (ctx) => [
                          const PopupMenuItem(value: 'delete', child: Text("删除课表")),
                        ],
                        onSelected: (v) {
                          if (v == 'delete') {
                            _confirmDelete(context, model, table.id);
                          }
                        },
                      )
                    ],
                  ),
                  onTap: () {
                    // 点击进入详情/导入页面
                    Navigator.push(context, MaterialPageRoute(builder: (_) => CourseManagePage(table: table)));
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showAddTableDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    DateTime selectedDate = DateTime.now();
    // 默认找最近的周一
    int diff = selectedDate.weekday - 1;
    selectedDate = selectedDate.subtract(Duration(days: diff));

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text("新建课表"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: "课表名称 (如: 大二上学期)"),
                ),
                const SizedBox(height: 20),
                ListTile(
                  title: const Text("开学日期 (第一周周一)"),
                  subtitle: Text(DateFormat('yyyy-MM-dd').format(selectedDate)),
                  contentPadding: EdgeInsets.zero,
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (d != null) {
                      // 强制周一
                      int diff = d.weekday - 1;
                      setState(() => selectedDate = d.subtract(Duration(days: diff)));
                    }
                  },
                )
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("取消")),
              ElevatedButton(
                onPressed: () {
                  if (nameCtrl.text.isNotEmpty) {
                    Provider.of<AppModel>(context, listen: false).addCourseTable(nameCtrl.text, selectedDate);
                    Navigator.pop(ctx);
                  }
                },
                child: const Text("创建"),
              )
            ],
          );
        }
      )
    );
  }

  void _confirmDelete(BuildContext context, AppModel model, String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("确认删除"),
        content: const Text("删除课表将同时删除该课表下的所有课程数据，且无法恢复。"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("取消")),
          TextButton(
            onPressed: () {
              model.deleteCourseTable(id);
              Navigator.pop(ctx);
            },
            child: const Text("删除", style: TextStyle(color: Colors.red)),
          )
        ],
      )
    );
  }
}