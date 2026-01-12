class Note {
  final String id;
  String content;
  DateTime createTime;

  Note({required this.id, required this.content, required this.createTime});

  Map<String, dynamic> toMap() => {
        'id': id,
        'content': content,
        'createTime': createTime.millisecondsSinceEpoch,
      };

  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'],
      content: map['content'],
      createTime: DateTime.fromMillisecondsSinceEpoch(map['createTime']),
    );
  }
}