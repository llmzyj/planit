import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import '../models/task.dart';
import '../models/note.dart';
import '../models/course_table.dart'; // 下面会创建这个模型
import 'dart:convert';
import '../models/time_node.dart';

class DBHelper {
  static final DBHelper instance = DBHelper._init();
  static Database? _database;

  DBHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    // 升级数据库文件名，确保重新创建表结构
    _database = await _initDB('planit_v7.db'); 
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    // 1. 任务表：新增 tableId 字段，用于关联课表
    await db.execute('''
      CREATE TABLE tasks ( 
        id TEXT PRIMARY KEY, 
        title TEXT, 
        location TEXT, 
        date INTEGER,
        startTime TEXT,
        endTime TEXT,
        isDone INTEGER,
        isClass INTEGER,
        tableId TEXT 
      )
    ''');

    // 2. 笔记表 (不变)
    await db.execute('''
      CREATE TABLE notes (
        id TEXT PRIMARY KEY,
        content TEXT,
        createTime INTEGER
      )
    ''');

    // 3. 设置表 (不变)
    await db.execute('CREATE TABLE settings (key TEXT PRIMARY KEY, value TEXT)');

    // 4. 新增：课表信息表
    await db.execute('''
      CREATE TABLE course_tables (
        id TEXT PRIMARY KEY,
        name TEXT,
        semesterStart INTEGER,
        isActive INTEGER
      )
    ''');
  }

  // --- Course Table Operations ---
  Future<List<CourseTable>> getAllCourseTables() async {
    final db = await instance.database;
    final maps = await db.query('course_tables', orderBy: 'semesterStart DESC');
    return maps.map((json) => CourseTable.fromMap(json)).toList();
  }

  Future<void> insertCourseTable(CourseTable table) async {
    final db = await instance.database;
    await db.insert('course_tables', table.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteCourseTable(String id) async {
    final db = await instance.database;
    // 删除课表
    await db.delete('course_tables', where: 'id = ?', whereArgs: [id]);
    // 级联删除该课表下的所有课程
    await db.delete('tasks', where: 'tableId = ?', whereArgs: [id]);
  }

  Future<void> setActiveTable(String id) async {
    final db = await instance.database;
    // 事务：先把所有设为非激活，再把指定id设为激活
    await db.transaction((txn) async {
      await txn.rawUpdate('UPDATE course_tables SET isActive = 0');
      await txn.rawUpdate('UPDATE course_tables SET isActive = 1 WHERE id = ?', [id]);
    });
  }

  // --- Tasks Operations (Updated) ---
  
  // 插入任务/课程
  Future<void> insertTask(Task task) async {
    final db = await instance.database;
    await db.insert('tasks', task.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> insertTasksBatch(List<Task> tasks) async {
    final db = await instance.database;
    final batch = db.batch();
    for (var task in tasks) {
      batch.insert('tasks', task.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  // 获取单日日程：普通任务(tableId为空) OR 当前激活课表的课程(tableId=currentId)
  Future<List<Task>> getTasksByDate(DateTime date, String? activeTableId) async {
    final db = await instance.database;
    final start = DateTime(date.year, date.month, date.day).millisecondsSinceEpoch;
    final end = DateTime(date.year, date.month, date.day, 23, 59, 59).millisecondsSinceEpoch;
    
    // SQL逻辑：(是课程 且 属于当前课表) 或者 (不是课程)
    // 注意：这里假设普通日程的 isClass=0。如果普通日程也有 tableId 且为空，逻辑如下：
    String whereClause = 'date >= ? AND date <= ? AND (isClass = 0 OR (isClass = 1 AND tableId = ?))';
    List<dynamic> args = [start, end, activeTableId ?? ''];

    final maps = await db.query('tasks', 
      where: whereClause, 
      whereArgs: args, 
      orderBy: 'startTime ASC'
    );
    return maps.map((json) => Task.fromMap(json)).toList();
  }

  // 获取总览：同上逻辑
  Future<List<Task>> getTasksRange(DateTime start, DateTime end, String? activeTableId) async {
    final db = await instance.database;
    String whereClause = 'date >= ? AND date <= ? AND (isClass = 0 OR (isClass = 1 AND tableId = ?))';
    List<dynamic> args = [start.millisecondsSinceEpoch, end.millisecondsSinceEpoch, activeTableId ?? ''];

    final maps = await db.query('tasks', 
      where: whereClause, 
      whereArgs: args,
      orderBy: 'date ASC, startTime ASC'
    );
    return maps.map((json) => Task.fromMap(json)).toList();
  }

  Future<List<Task>> getUndatedTasks() async {
    final db = await instance.database;
    final maps = await db.query('tasks', where: 'date IS NULL');
    return maps.map((json) => Task.fromMap(json)).toList();
  }

  Future<void> deleteTask(String id) async {
    final db = await instance.database;
    await db.delete('tasks', where: 'id = ?', whereArgs: [id]);
  }

  // --- Notes Operations (Unchanged) ---
  Future<List<Note>> getNotesPreview() async {
    final db = await instance.database;
    final maps = await db.rawQuery('SELECT id, substr(content, 1, 100) as content, createTime FROM notes ORDER BY createTime DESC');
    return maps.map((json) => Note.fromMap(json)).toList();
  }
  Future<Note?> getNoteById(String id) async {
    final db = await instance.database;
    final maps = await db.query('notes', where: 'id = ?', whereArgs: [id]);
    return maps.isNotEmpty ? Note.fromMap(maps.first) : null;
  }
  Future<void> insertNote(Note note) async {
    final db = await instance.database;
    await db.insert('notes', note.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }
  Future<void> deleteNote(String id) async {
    final db = await instance.database;
    await db.delete('notes', where: 'id = ?', whereArgs: [id]);
  }

  
  // --- Time Layout Settings ---
  
  // 保存作息表
  Future<void> saveTimeLayout(List<TimeNode> layout) async {
    final db = await instance.database;
    String jsonStr = jsonEncode(layout.map((e) => e.toJson()).toList());
    await db.insert(
      'settings', 
      {'key': 'time_layout', 'value': jsonStr}, 
      conflictAlgorithm: ConflictAlgorithm.replace
    );
  }

  // 读取作息表
  Future<List<TimeNode>> getTimeLayout() async {
    final db = await instance.database;
    final maps = await db.query('settings', where: 'key = ?', whereArgs: ['time_layout']);
    
    if (maps.isNotEmpty) {
      String jsonStr = maps.first['value'] as String;
      List<dynamic> list = jsonDecode(jsonStr);
      return list.map((e) => TimeNode.fromJson(e)).toList();
    }
    // 如果没有存过，返回默认
    return TimeNode.defaultLayout();
  }
}