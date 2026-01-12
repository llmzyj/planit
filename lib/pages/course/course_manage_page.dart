import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/course_table.dart';
import 'add_course_page.dart';
import 'time_setting_page.dart';

class CourseManagePage extends StatelessWidget {
  final CourseTable table;

  const CourseManagePage({super.key, required this.table});

  @override
  Widget build(BuildContext context) {
    final startDate = table.semesterStart;
    final now = DateTime.now();
    // 计算当前周数：(今天 - 开学日期) / 7 + 1
    int currentWeek = ((now.difference(startDate).inDays) / 7).floor() + 1;
    
    // 如果还没开学，显示负数或0
    String weekText = currentWeek > 0 ? "第 $currentWeek 周" : "尚未开学";

    return Scaffold(
      appBar: AppBar(title: Text(table.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 顶部信息卡片
          Card(
            elevation: 0,
            color: Colors.indigo.shade50,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    table.name, 
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.indigo)
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text("开学日期: ${DateFormat('yyyy-MM-dd').format(startDate)}"),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text("当前进度: $weekText", style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          const Padding(
            padding: EdgeInsets.only(left: 8.0, bottom: 8.0),
            child: Text("课程操作", style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.bold)),
          ),

          // 操作入口列表
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.indigo.shade100, borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.add, color: Colors.indigo),
                  ),
                  title: const Text("导入 / 添加课程"),
                  subtitle: const Text("支持手动录入或粘贴教务处JSON"),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                     // 跳转到添加页面，必须传递当前课表的开学日期，用于计算具体上课时间
                     Navigator.push(
                       context, 
                       MaterialPageRoute(builder: (_) => AddCoursePage(semesterStart: startDate))
                     );
                  },
                ),
                const Divider(height: 1, indent: 60),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.orange.shade100, borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.schedule, color: Colors.orange),
                  ),
                  title: const Text("作息时间设置"),
                  subtitle: const Text("自定义每节课的起止时间"),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // 跳转到作息设置页
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const TimeSettingPage()));
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}