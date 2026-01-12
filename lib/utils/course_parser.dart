import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/task.dart';
import '../models/time_node.dart'; // 引入 TimeNode

class CourseParser {
  // 修改方法签名，增加 timeLayout 参数
  static List<Task> parseSeuJson(String jsonStr, DateTime semesterStart, List<TimeNode> timeLayout) {
    List<Task> tasks = [];
    try {
      final Map<String, dynamic> data = jsonDecode(jsonStr);
      final List<dynamic> schedule = data['theorySchedule'];

      for (var item in schedule) {
        String name = item['KCM'] ?? '未知课程';
        String location = item['SKDD'] ?? '';
        String? weeksStr = item['ZCMC']; 
        int? dayOfWeek = item['SKXQ']; 
        int? startNode = item['KSJC']; 
        int? endNode = item['JSJC'];   

        if (weeksStr != null && dayOfWeek != null && startNode != null && endNode != null) {
          List<int> weeks = _parseWeeks(weeksStr);
          
          // 使用传入的 timeLayout 获取时间
          TimeOfDay startTime = _getTimeFromLayout(timeLayout, startNode, isStart: true);
          TimeOfDay endTime = _getTimeFromLayout(timeLayout, endNode, isStart: false);

          for (int week in weeks) {
            DateTime classDate = semesterStart.add(Duration(days: (week - 1) * 7 + (dayOfWeek - 1)));
            
            tasks.add(Task(
              id: const Uuid().v4(),
              title: name,
              location: location,
              date: classDate,
              startTime: startTime,
              endTime: endTime,
              isClass: true,
            ));
          }
        }
      }
    } catch (e) {
      debugPrint("Parse Error: $e");
    }
    return tasks;
  }

  static List<int> _parseWeeks(String weekStr) {
    // 简单处理 "1-16周" 这种格式
    // 复杂格式如 "1-8,10-16周" 需正则，这里先做基础版
    List<int> weeks = [];
    try {
      String clean = weekStr.replaceAll("周", "");
      if (clean.contains("-")) {
        var parts = clean.split("-");
        int start = int.parse(parts[0]);
        int end = int.parse(parts[1]);
        for (int i = start; i <= end; i++) {
          weeks.add(i);
        }
      } else if (clean.contains(",")) {
         var parts = clean.split(",");
         for(var p in parts) {
           weeks.add(int.parse(p));
         }
      } else {
        weeks.add(int.parse(clean));
      }
    } catch (e) { 
      debugPrint("Week Parse Error: $e");
    }
    return weeks;
  }

  static TimeOfDay _getTimeFromLayout(List<TimeNode> layout, int nodeIndex, {required bool isStart}) {
    // 找到对应的节次配置
    try {
      final node = layout.firstWhere((n) => n.nodeIndex == nodeIndex);
      return isStart ? node.startTime : node.endTime;
    } catch (e) {
      // 如果找不到（比如配置只有10节，但课表有11节），返回默认5点
      return const TimeOfDay(hour: 5, minute: 0);
    }
  }
}