import 'package:flutter/material.dart';

class Task {
  final String id;
  String title;
  String location;
  DateTime? date;
  TimeOfDay? startTime;
  TimeOfDay? endTime;
  bool isDone;
  bool isClass;
  String? tableId; // 新增：所属课表ID

  Task({
    required this.id,
    required this.title,
    this.location = '',
    this.date,
    this.startTime,
    this.endTime,
    this.isDone = false,
    this.isClass = false,
    this.tableId,
  });

  bool get hasTime => startTime != null;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'location': location,
      'date': date?.millisecondsSinceEpoch,
      'startTime': startTime != null ? '${startTime!.hour}:${startTime!.minute}' : null,
      'endTime': endTime != null ? '${endTime!.hour}:${endTime!.minute}' : null,
      'isDone': isDone ? 1 : 0,
      'isClass': isClass ? 1 : 0,
      'tableId': tableId, // 新增
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    TimeOfDay? parseTime(String? str) {
      if (str == null) return null;
      final parts = str.split(':');
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    }
    return Task(
      id: map['id'],
      title: map['title'],
      location: map['location'] ?? '',
      date: map['date'] != null ? DateTime.fromMillisecondsSinceEpoch(map['date']) : null,
      startTime: parseTime(map['startTime']),
      endTime: parseTime(map['endTime']),
      isDone: map['isDone'] == 1,
      isClass: map['isClass'] == 1,
      tableId: map['tableId'], // 新增
    );
  }
}