import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

// 引入依赖
import '../providers/app_model.dart';
import '../models/task.dart';
import 'edit_task_sheet.dart'; 
import 'course/course_table_list_page.dart';

class SingleDayPage extends StatelessWidget {
  const SingleDayPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppModel>(
      builder: (context, model, child) {
        return Scaffold(
          appBar: AppBar(
            centerTitle: true, // 居中标题以便布局左右箭头
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 前一天按钮
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  tooltip: "前一天",
                  onPressed: () {
                    model.setDate(model.selectedDate.subtract(const Duration(days: 1)));
                  },
                ),
                // 日期点击区域
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => _showQuickDatePicker(context, model),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                    child: Row(
                      children: [
                        Text(
                          DateFormat('MM月dd日 EEEE', 'zh_CN').format(model.selectedDate),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const Icon(Icons.arrow_drop_down, size: 20),
                      ],
                    ),
                  ),
                ),
                // 后一天按钮
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  tooltip: "后一天",
                  onPressed: () {
                    model.setDate(model.selectedDate.add(const Duration(days: 1)));
                  },
                ),
              ],
            ),
            actions: [
              // 回到今天
              IconButton(
                icon: const Icon(Icons.rotate_90_degrees_ccw),
                tooltip: "回到今天",
                onPressed: () => model.setDate(DateTime.now()),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            heroTag: "fab_add_task", 
            onPressed: () => _showAddMenu(context),
            child: const Icon(Icons.add),
          ),
          body: Column(
            children: [
              // 区域1: 特定日期的日程/任务
              Expanded(
                flex: 5,
                child: _buildSection(
                  context, 
                  title: "单日日程", 
                  color: Theme.of(context).colorScheme.primary,
                  count: model.todaySchedule.length,
                  child: model.todaySchedule.isEmpty 
                    ? const Center(child: Text("今日无安排", style: TextStyle(color: Colors.grey)))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: model.todaySchedule.length,
                        itemBuilder: (ctx, i) => _ScheduleCard(task: model.todaySchedule[i]),
                      ),
                ),
              ),
              // 区域2: 待办池
              Expanded(
                flex: 4,
                child: _buildSection(
                  context, 
                  title: "待办箱 (无日期)", 
                  color: Colors.orange.shade800,
                  count: model.undatedTodos.length,
                  child: model.undatedTodos.isEmpty 
                    ? const Center(child: Text("待办箱为空", style: TextStyle(color: Colors.grey)))
                    : ListView.builder(
                        padding: EdgeInsets.zero,
                        itemCount: model.undatedTodos.length,
                        itemBuilder: (ctx, i) => _TodoTile(task: model.undatedTodos[i]),
                      ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- 快速日期选择器 (无需确认) ---
  void _showQuickDatePicker(BuildContext context, AppModel model) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          // 限制高度，避免占满全屏
          height: 400, 
          child: Column(
            children: [
              // 顶部把手
              Container(
                width: 40, height: 4, 
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))
              ),
              Expanded(
                child: CalendarDatePicker(
                  initialDate: model.selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                  onDateChanged: (newDate) {
                    // 核心逻辑：选中即生效，并关闭弹窗
                    model.setDate(newDate);
                    Navigator.pop(ctx);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- 辅助 UI 构建方法 ---

  Widget _buildSection(BuildContext context, {required String title, required Color color, required Widget child, required int count}) {
    final bgColor = color.withValues(alpha: 0.1); 

    return Container(
      margin: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(10)),
                  child: Text("$count", style: TextStyle(color: color, fontSize: 12)),
                )
              ],
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
  
  void _showAddMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          ListTile(
            leading: const Icon(Icons.edit_calendar),
            title: const Text('添加日程 / 待办'),
            subtitle: const Text('临时性事务，可设置日期或放入待办箱'),
            onTap: () {
              Navigator.pop(ctx);
              showEditTaskSheet(context, null); 
            },
          ),
          const Divider(indent: 16, endIndent: 16),
          ListTile(
            leading: const Icon(Icons.school, color: Colors.indigo),
            title: const Text('课程表管理'),
            subtitle: const Text('设置学期、导入课表、管理课程'),
            onTap: () {
              Navigator.pop(ctx);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const CourseTableListPage()));
            },
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}

// --- 内部组件：日程卡片 ---

class _ScheduleCard extends StatelessWidget {
  final Task task;
  const _ScheduleCard({required this.task});
  
  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final bg = task.isClass ? primary.withValues(alpha: 0.1) : Colors.blue.shade50;

    return Card(
      elevation: 0,
      color: bg,
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () => showEditTaskSheet(context, task),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              if (task.hasTime) ...[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(task.startTime!.format(context), style: const TextStyle(fontWeight: FontWeight.bold)),
                    if (task.endTime != null) 
                      Text(task.endTime!.format(context), style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ),
                const SizedBox(width: 12),
                Container(width: 2, height: 30, color: task.isClass ? primary : Colors.blue),
                const SizedBox(width: 12),
              ] else ...[
                 const Text("全天", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                 const SizedBox(width: 12),
                 Container(width: 2, height: 30, color: Colors.grey),
                 const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(task.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                    if (task.location.isNotEmpty) 
                      Text("📍 ${task.location}", style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ),
              ),
              if (task.isDone) const Icon(Icons.check, color: Colors.green, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _TodoTile extends StatelessWidget {
  final Task task;
  const _TodoTile({required this.task});
  
  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () => showEditTaskSheet(context, task),
      leading: Checkbox(
        value: task.isDone,
        onChanged: (_) => Provider.of<AppModel>(context, listen: false).toggleTaskStatus(task),
      ),
      title: Text(
        task.title, 
        style: TextStyle(
          decoration: task.isDone ? TextDecoration.lineThrough : null, 
          color: task.isDone ? Colors.grey : null
        )
      ),
      trailing: const Icon(Icons.edit, size: 16, color: Colors.grey),
    );
  }
}