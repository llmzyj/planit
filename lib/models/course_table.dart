class CourseTable {
  final String id;
  String name;
  DateTime semesterStart;
  bool isActive;

  CourseTable({
    required this.id,
    required this.name,
    required this.semesterStart,
    this.isActive = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'semesterStart': semesterStart.millisecondsSinceEpoch,
      'isActive': isActive ? 1 : 0,
    };
  }

  factory CourseTable.fromMap(Map<String, dynamic> map) {
    return CourseTable(
      id: map['id'],
      name: map['name'],
      semesterStart: DateTime.fromMillisecondsSinceEpoch(map['semesterStart']),
      isActive: map['isActive'] == 1,
    );
  }
}