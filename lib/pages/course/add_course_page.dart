import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../providers/app_model.dart';
import '../../models/task.dart';
import '../../utils/course_parser.dart'; // 确保你创建了 utils/course_parser.dart
import '../../models/time_node.dart';

class AddCoursePage extends StatefulWidget {
  final DateTime semesterStart; // 必须传入开学日期
  const AddCoursePage({super.key, required this.semesterStart});
  
  @override
  State<AddCoursePage> createState() => _AddCoursePageState();
}

class _AddCoursePageState extends State<AddCoursePage> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  
  // --- 手动添加的表单变量 ---
  final _manualKey = GlobalKey<FormState>();
  String _name = "";
  String _location = "";
  int _dayOfWeek = 1; // 1=周一
  int _startNode = 1; // 第几节开始
  int _endNode = 2;   // 第几节结束
  int _startWeek = 1; // 起始周
  int _endWeek = 16;  // 结束周
  
  // --- 导入的控制器 ---
  final _jsonCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _jsonCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("添加课程"),
        bottom: TabBar(
          controller: _tabCtrl,
          tabs: const [
            Tab(text: "手动添加", icon: Icon(Icons.edit)), 
            Tab(text: "JSON导入", icon: Icon(Icons.code))
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _buildManualForm(),
          _buildImportForm(),
        ],
      ),
    );
  }

  // --- Tab 1: 手动添加表单 ---
  Widget _buildManualForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _manualKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 0,
              color: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TextFormField(
                      decoration: const InputDecoration(labelText: "课程名称", border: OutlineInputBorder()),
                      onSaved: (v) => _name = v!,
                      validator: (v) => v == null || v.isEmpty ? "请输入课程名称" : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      decoration: const InputDecoration(labelText: "上课地点 (选填)", border: OutlineInputBorder()),
                      onSaved: (v) => _location = v ?? "",
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            Card(
              elevation: 0,
              color: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(children: [
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: _dayOfWeek,
                          decoration: const InputDecoration(labelText: "星期", border: OutlineInputBorder()),
                          items: List.generate(7, (i) => DropdownMenuItem(value: i+1, child: Text("周${i+1}"))),
                          onChanged: (v) => setState(() => _dayOfWeek = v!),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 16),
                    Row(children: [
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: _startNode,
                          decoration: const InputDecoration(labelText: "开始节次", border: OutlineInputBorder()),
                          items: List.generate(13, (i) => DropdownMenuItem(value: i+1, child: Text("第${i+1}节"))),
                          onChanged: (v) => setState(() => _startNode = v!),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: _endNode,
                          decoration: const InputDecoration(labelText: "结束节次", border: OutlineInputBorder()),
                          items: List.generate(13, (i) => DropdownMenuItem(value: i+1, child: Text("第${i+1}节"))),
                          onChanged: (v) => setState(() => _endNode = v!),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 16),
                    Row(children: [
                       Expanded(
                         child: TextFormField(
                           decoration: const InputDecoration(labelText: "起始周", border: OutlineInputBorder()),
                           initialValue: "1",
                           keyboardType: TextInputType.number,
                           onSaved: (v) => _startWeek = int.tryParse(v ?? "1") ?? 1,
                         )
                       ),
                       const SizedBox(width: 16),
                       Expanded(
                         child: TextFormField(
                           decoration: const InputDecoration(labelText: "结束周", border: OutlineInputBorder()),
                           initialValue: "16",
                           keyboardType: TextInputType.number,
                           onSaved: (v) => _endWeek = int.tryParse(v ?? "16") ?? 16,
                         )
                       ),
                    ]),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor, 
                foregroundColor: Colors.white, 
                padding: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
              ),
              onPressed: _saveManual,
              child: const Text("保存课程", style: TextStyle(fontSize: 16)),
            )
          ],
        ),
      ),
    );
  }

  // --- Tab 2: JSON 导入表单 ---
  Widget _buildImportForm() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
            child: const Text(
              "说明：请将教务处抓包获取的 JSON 数据完整粘贴在下方。",
              style: TextStyle(color: Colors.blue, fontSize: 12),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: TextField(
              controller: _jsonCtrl,
              maxLines: null,
              expands: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: '{"code": 0, "schedule": [...]}',
                fillColor: Colors.white,
                filled: true,
              ),
              style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            icon: const Icon(Icons.download),
            label: const Text("解析并导入"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green, 
              foregroundColor: Colors.white, 
              padding: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
            ),
            onPressed: _importJson,
          )
        ],
      ),
    );
  }

  // --- 逻辑方法 ---

  void _saveManual() {
    if (_manualKey.currentState!.validate()) {
      _manualKey.currentState!.save();
      final model = Provider.of<AppModel>(context, listen: false);
      DateTime start = widget.semesterStart;
      // 获取当前的作息配置
      final layout = model.timeLayout; 
      
      List<Task> tasks = [];
      for (int w = _startWeek; w <= _endWeek; w++) {
         DateTime date = start.add(Duration(days: (w - 1) * 7 + (_dayOfWeek - 1)));
         
         // 使用配置的时间
         TimeOfDay tStart = _getTimeFromLayout(layout, _startNode, isStart: true);
         TimeOfDay tEnd = _getTimeFromLayout(layout, _endNode, isStart: false);
         
         tasks.add(Task(
           id: const Uuid().v4(),
           title: _name,
           location: _location,
           date: date,
           startTime: tStart,
           endTime: tEnd,
           isClass: true,
         ));
      }
      model.importCourses(tasks);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("课程添加成功")));
    }
  }

  // 辅助方法：从 layout 获取时间 (也可以把 CourseParser 里的那个方法设为 public static 并在外面调用)
  TimeOfDay _getTimeFromLayout(List<TimeNode> layout, int nodeIndex, {required bool isStart}) {
    try {
      final node = layout.firstWhere((n) => n.nodeIndex == nodeIndex);
      return isStart ? node.startTime : node.endTime;
    } catch (e) {
      return const TimeOfDay(hour: 8, minute: 0);
    }
  }

  void _importJson() {
    if (_jsonCtrl.text.isEmpty) return;
    final model = Provider.of<AppModel>(context, listen: false);
    
    // 传入 timeLayout
    List<Task> tasks = CourseParser.parseSeuJson(
      _jsonCtrl.text, 
      widget.semesterStart, 
      model.timeLayout // 关键修改
    );
    
    if (tasks.isEmpty) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("解析失败"),
          content: const Text("未能识别到有效课程数据，请检查 JSON 格式是否正确。"),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("确定"))],
        )
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("确认导入"),
        content: Text("解析成功！\n\n共找到 ${tasks.length} 条上课记录。\n(已自动展开周次)"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("取消")),
          TextButton(
            onPressed: () {
              model.importCourses(tasks);
              Navigator.pop(ctx); // close dialog
              Navigator.pop(context); // close page
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("成功导入 ${tasks.length} 条记录")));
            },
            child: const Text("确认写入"),
          ),
        ],
      )
    );
  }
}