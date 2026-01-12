import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_model.dart';
import '../models/task.dart';
import 'edit_task_sheet.dart';

class OverviewPage extends StatefulWidget {
  const OverviewPage({super.key});
  @override
  State<OverviewPage> createState() => _OverviewPageState();
}

class _OverviewPageState extends State<OverviewPage> {
  final ScrollController _scrollCtrl = ScrollController();

  bool _onScrollNotification(ScrollNotification notification) {
    if (notification is ScrollEndNotification) {
      final metrics = notification.metrics;
      final model = Provider.of<AppModel>(context, listen: false);
      
      // 触底加载
      if (metrics.pixels >= metrics.maxScrollExtent - 100) { 
        model.loadMoreOverview(future: true);
      }
      // 触顶加载
      if (metrics.pixels <= metrics.minScrollExtent) {
        model.loadMoreOverview(future: false);
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final model = Provider.of<AppModel>(context);
    final tasks = model.overviewTasks;
    
    Map<String, List<Task>> grouped = {};
    for (var t in tasks) {
      if (t.date == null) continue;
      String key = DateFormat('yyyy-MM-dd').format(t.date!);
      if (!grouped.containsKey(key)) grouped[key] = [];
      grouped[key]!.add(t);
    }
    final sortedKeys = grouped.keys.toList();

    return Scaffold(
      appBar: AppBar(title: const Text("日程总览")),
      body: NotificationListener<ScrollNotification>(
        onNotification: _onScrollNotification,
        child: ListView.builder(
          controller: _scrollCtrl,
          physics: const AlwaysScrollableScrollPhysics(), // 关键：即使内容少也能拖动触发边界事件
          itemCount: sortedKeys.length,
          itemBuilder: (ctx, index) {
            String dateKey = sortedKeys[index];
            DateTime date = DateTime.parse(dateKey);
            List<Task> dailyTasks = grouped[dateKey]!;
            bool isToday = model.isSameDay(date, DateTime.now());
            final primary = Theme.of(context).colorScheme.primary;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (index == 0 && model.isLoadingOverview) const LinearProgressIndicator(minHeight: 2),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                  color: isToday ? primary.withOpacity(0.1) : Colors.grey.shade200,
                  width: double.infinity,
                  child: Text(DateFormat('yyyy/MM/dd EEEE', 'zh_CN').format(date), 
                    style: TextStyle(fontWeight: FontWeight.bold, color: isToday ? primary : Colors.black87)),
                ),
                ...dailyTasks.map((t) => ListTile(
                  dense: true,
                  leading: Text(t.hasTime ? t.startTime!.format(context) : "全天", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  title: Text(t.title),
                  trailing: t.isClass ? Text("课", style: TextStyle(fontSize: 10, color: primary)) : null,
                  onTap: () => showEditTaskSheet(context, t),
                )),
                if (index == sortedKeys.length - 1 && model.isLoadingOverview) const LinearProgressIndicator(minHeight: 2),
              ],
            );
          },
        ),
      ),
    );
  }
}