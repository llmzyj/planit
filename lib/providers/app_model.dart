import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/task.dart';
import '../models/note.dart';
import '../models/course_table.dart';
import '../db/db_helper.dart';
import '../models/time_node.dart';

class AppModel extends ChangeNotifier {
  List<Task> _todaySchedule = [];
  List<Task> _undatedTodos = [];
  List<Note> _notesPreview = [];
  
  // 总览页状态
  List<Task> _overviewTasks = [];
  DateTime _overviewStartDate = DateTime.now();
  DateTime _overviewEndDate = DateTime.now();
  bool _isLoadingOverview = false;
  // 修复卡顿关键：标记是否还有更多数据
  bool _hasMorePast = true;
  bool _hasMoreFuture = true;

  DateTime _selectedDate = DateTime.now();
  bool _isLoaded = false;
  
  // 课表管理
  List<CourseTable> _courseTables = [];
  CourseTable? _activeTable; // 当前激活的课表

  List<Task> get todaySchedule => _todaySchedule;
  List<Task> get undatedTodos => _undatedTodos;
  List<Task> get overviewTasks => _overviewTasks;
  List<Note> get notes => _notesPreview;
  DateTime get selectedDate => _selectedDate;
  bool get isLoaded => _isLoaded;
  bool get isLoadingOverview => _isLoadingOverview;
  
  CourseTable? get activeTable => _activeTable;
  List<CourseTable> get courseTables => _courseTables;

  List<TimeNode> _timeLayout = [];
  List<TimeNode> get timeLayout => _timeLayout;

  AppModel() {
    _initData();
  }

  Future<void> _initData() async {
    await _loadCourseTables();
    _timeLayout = await DBHelper.instance.getTimeLayout();
    await refreshSingleDay();
    await refreshNotesList();
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> updateTimeLayout(List<TimeNode> newLayout) async {
    _timeLayout = newLayout;
    await DBHelper.instance.saveTimeLayout(newLayout);
    notifyListeners();
  }

  // --- Course Table Logic ---
  Future<void> _loadCourseTables() async {
    _courseTables = await DBHelper.instance.getAllCourseTables();
    if (_courseTables.isNotEmpty) {
      // 找激活的，找不到就默认第一个
      try {
        _activeTable = _courseTables.firstWhere((t) => t.isActive);
      } catch (e) {
        _activeTable = _courseTables.first;
        // 修正数据库状态
        await DBHelper.instance.setActiveTable(_activeTable!.id);
      }
    } else {
      _activeTable = null;
    }
    notifyListeners();
  }

  Future<void> addCourseTable(String name, DateTime start) async {
    final newTable = CourseTable(
      id: const Uuid().v4(),
      name: name,
      semesterStart: start,
      isActive: _courseTables.isEmpty, // 如果是第一个，默认激活
    );
    await DBHelper.instance.insertCourseTable(newTable);
    await _loadCourseTables();
    // 如果是第一个，刷新数据
    if (_courseTables.length == 1) await refreshSingleDay();
  }

  Future<void> switchActiveTable(String id) async {
    await DBHelper.instance.setActiveTable(id);
    await _loadCourseTables();
    await refreshSingleDay(); // 切换课表后，首页数据要变
    if (_overviewTasks.isNotEmpty) await resetAndLoadOverview(); // 总览也要变
  }

  Future<void> deleteCourseTable(String id) async {
    await DBHelper.instance.deleteCourseTable(id);
    await _loadCourseTables();
    await refreshSingleDay();
  }

  // --- Day View ---
  void setDate(DateTime date) {
    _selectedDate = date;
    refreshSingleDay();
    notifyListeners();
  }

  Future<void> refreshSingleDay() async {
    _todaySchedule = await DBHelper.instance.getTasksByDate(_selectedDate, _activeTable?.id);
    _undatedTodos = await DBHelper.instance.getUndatedTasks();
    notifyListeners();
  }

  // --- Overview (Fix Lag) ---
  Future<void> resetAndLoadOverview() async {
    _isLoadingOverview = true;
    _hasMorePast = true;
    _hasMoreFuture = true;
    
    _overviewStartDate = DateTime.now().subtract(const Duration(days: 7));
    _overviewEndDate = DateTime.now().add(const Duration(days: 30));
    notifyListeners();

    _overviewTasks = await DBHelper.instance.getTasksRange(_overviewStartDate, _overviewEndDate, _activeTable?.id);
    _isLoadingOverview = false;
    notifyListeners();
  }
  
  Future<void> loadMoreOverview({bool future = true}) async {
    if (_isLoadingOverview) return;
    // 关键修复：如果已知没有更多数据，直接返回，防止死循环
    if (future && !_hasMoreFuture) return;
    if (!future && !_hasMorePast) return;

    _isLoadingOverview = true;
    notifyListeners();

    // 简单防抖
    await Future.delayed(const Duration(milliseconds: 300));

    List<Task> newTasks;
    if (future) {
      final newEnd = _overviewEndDate.add(const Duration(days: 30));
      newTasks = await DBHelper.instance.getTasksRange(
        _overviewEndDate.add(const Duration(milliseconds: 1)), 
        newEnd, 
        _activeTable?.id
      );
      
      if (newTasks.isEmpty) {
        _hasMoreFuture = false; // 标记未来没有数据了
      } else {
        _overviewTasks.addAll(newTasks);
        _overviewEndDate = newEnd;
      }
    } else {
      final newStart = _overviewStartDate.subtract(const Duration(days: 30));
      newTasks = await DBHelper.instance.getTasksRange(
        newStart, 
        _overviewStartDate.subtract(const Duration(milliseconds: 1)),
        _activeTable?.id
      );
      
      if (newTasks.isEmpty) {
        _hasMorePast = false; // 标记过去没有数据了
      } else {
        _overviewTasks.insertAll(0, newTasks);
        _overviewStartDate = newStart;
      }
    }
    
    _isLoadingOverview = false;
    notifyListeners();
  }

  // --- Notes ---
  Future<void> refreshNotesList() async {
    _notesPreview = await DBHelper.instance.getNotesPreview();
    notifyListeners();
  }

  // --- CRUD ---
  Future<void> addTask(Task task) async {
    // 如果是课程，自动绑定当前激活的课表ID
    if (task.isClass && _activeTable != null) {
      task.tableId = _activeTable!.id;
    }
    await DBHelper.instance.insertTask(task);
    await _refreshAfterChange(task);
  }

  Future<void> importCourses(List<Task> tasks) async {
    if (_activeTable == null) return; // 必须有激活课表才能导入
    
    // 批量绑定 tableId
    for (var t in tasks) {
      t.tableId = _activeTable!.id;
    }
    
    await DBHelper.instance.insertTasksBatch(tasks);
    await refreshSingleDay();
    if (_overviewTasks.isNotEmpty) await resetAndLoadOverview();
  }

  Future<void> updateTask(Task task) async {
    await DBHelper.instance.insertTask(task);
    await _refreshAfterChange(task);
  }

  Future<void> deleteTask(String id) async {
    await DBHelper.instance.deleteTask(id);
    await refreshSingleDay();
    _overviewTasks.removeWhere((t) => t.id == id);
    notifyListeners();
  }

  Future<void> toggleTaskStatus(Task task) async {
    task.isDone = !task.isDone;
    await DBHelper.instance.insertTask(task);
    if (task.date == null) {
      final idx = _undatedTodos.indexWhere((t) => t.id == task.id);
      if (idx != -1) _undatedTodos[idx] = task;
    } else {
      final idx = _todaySchedule.indexWhere((t) => t.id == task.id);
      if (idx != -1) _todaySchedule[idx] = task;
    }
    notifyListeners();
  }

  Future<void> _refreshAfterChange(Task task) async {
    if (task.date == null || isSameDay(task.date!, _selectedDate)) {
      await refreshSingleDay();
    }
    if (_overviewTasks.isNotEmpty && task.date != null) {
      // 简单处理：如果修改了日程，重置总览，避免数据不一致
      await resetAndLoadOverview();
    }
  }

  Future<void> saveNote(Note note) async {
    await DBHelper.instance.insertNote(note);
    await refreshNotesList();
  }

  Future<void> deleteNote(String id) async {
    await DBHelper.instance.deleteNote(id);
    await refreshNotesList();
  }
  
  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}