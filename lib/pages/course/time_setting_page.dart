import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_model.dart';
import '../../models/time_node.dart';

class TimeSettingPage extends StatefulWidget {
  const TimeSettingPage({super.key});

  @override
  State<TimeSettingPage> createState() => _TimeSettingPageState();
}

class _TimeSettingPageState extends State<TimeSettingPage> {
  late List<TimeNode> _tempLayout;

  @override
  void initState() {
    super.initState();
    // 深拷贝一份数据用于编辑，避免直接修改 Model
    final model = Provider.of<AppModel>(context, listen: false);
    _tempLayout = model.timeLayout.map((e) => TimeNode(
      nodeIndex: e.nodeIndex, 
      startTime: e.startTime, 
      endTime: e.endTime
    )).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("作息时间设置"),
        actions: [
          IconButton(
            icon: const Icon(Icons.restore),
            tooltip: "恢复默认",
            onPressed: _resetToDefault,
          ),
          IconButton(
            icon: const Icon(Icons.check),
            tooltip: "保存",
            onPressed: _save,
          )
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _tempLayout.length,
        separatorBuilder: (ctx, i) => const Divider(height: 1),
        itemBuilder: (ctx, i) {
          final node = _tempLayout[i];
          return ListTile(
            title: Text("第 ${node.nodeIndex} 节"),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTimeButton(context, node.startTime, (t) {
                  setState(() => node.startTime = t);
                }),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text("-", style: TextStyle(color: Colors.grey)),
                ),
                _buildTimeButton(context, node.endTime, (t) {
                  setState(() => node.endTime = t);
                }),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTimeButton(BuildContext context, TimeOfDay time, Function(TimeOfDay) onSelect) {
    return OutlinedButton(
      onPressed: () async {
        final t = await showTimePicker(context: context, initialTime: time);
        if (t != null) onSelect(t);
      },
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Text(
        time.format(context),
        style: const TextStyle(color: Colors.black87),
      ),
    );
  }

  void _resetToDefault() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("恢复默认"),
        content: const Text("确定要恢复到默认的作息时间吗？"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("取消")),
          TextButton(
            onPressed: () {
              setState(() {
                _tempLayout = TimeNode.defaultLayout();
              });
              Navigator.pop(ctx);
            },
            child: const Text("确定"),
          ),
        ],
      ),
    );
  }

  void _save() {
    Provider.of<AppModel>(context, listen: false).updateTimeLayout(_tempLayout);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("作息时间已保存")));
  }
}