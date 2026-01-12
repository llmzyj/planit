import 'package:flutter/material.dart';

class TimeNode {
  final int nodeIndex; // 第几节 (1, 2, 3...)
  TimeOfDay startTime;
  TimeOfDay endTime;

  TimeNode({
    required this.nodeIndex,
    required this.startTime,
    required this.endTime,
  });

  // 默认作息生成器
  static List<TimeNode> defaultLayout() {
    return List.generate(13, (i) {
      int node = i + 1;
      // 简单逻辑：8点开始，每节45分钟，课间10分钟
      // 上午：1-2, 3-4, 5
      // 下午：6-7, 8-9
      // 晚上：10-11, 12-13
      // 这里写一个简单的推算，实际用户可修改
      int startHour = 8;
      int startMin = 0;
      
      if (node <= 4) {
        // 上午 8:00 开始
        int totalMin = (node - 1) * 55; // 45+10
        startMin += totalMin;
      } else if (node <= 9) {
        // 下午 14:00 开始 (第5节通常是下午第一节或中午)
        // 假设第5节是下午13:30
        if (node == 5) { startHour = 13; startMin = 30; }
        else {
           startHour = 14; 
           int totalMin = (node - 6) * 55;
           startMin += totalMin;
        }
      } else {
        // 晚上 18:30 开始
        startHour = 18;
        startMin = 30 + (node - 10) * 55;
      }

      // 处理进位
      while (startMin >= 60) {
        startHour++;
        startMin -= 60;
      }

      TimeOfDay start = TimeOfDay(hour: startHour, minute: startMin);
      
      // 结束时间 = 开始 + 45分钟
      int endMin = startMin + 45;
      int endHour = startHour;
      while (endMin >= 60) {
        endHour++;
        endMin -= 60;
      }
      TimeOfDay end = TimeOfDay(hour: endHour, minute: endMin);

      return TimeNode(nodeIndex: node, startTime: start, endTime: end);
    });
  }

  Map<String, dynamic> toJson() {
    return {
      'nodeIndex': nodeIndex,
      'start': '${startTime.hour}:${startTime.minute}',
      'end': '${endTime.hour}:${endTime.minute}',
    };
  }

  factory TimeNode.fromJson(Map<String, dynamic> json) {
    TimeOfDay parse(String s) {
      var p = s.split(':');
      return TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1]));
    }
    return TimeNode(
      nodeIndex: json['nodeIndex'],
      startTime: parse(json['start']),
      endTime: parse(json['end']),
    );
  }
}