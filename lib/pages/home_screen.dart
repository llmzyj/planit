import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_model.dart';
import 'single_day_page.dart';
import 'overview_page.dart';
import 'notes_page.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final List<Widget> _pages = [
    const SingleDayPage(),
    const OverviewPage(),
    const NotesPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) {
          setState(() => _currentIndex = idx);
          if (idx == 1) {
            Provider.of<AppModel>(context, listen: false).resetAndLoadOverview();
          }
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.calendar_view_day), label: '单日'),
          NavigationDestination(icon: Icon(Icons.calendar_month), label: '总览'),
          NavigationDestination(icon: Icon(Icons.note_alt), label: '笔记'),
        ],
      ),
    );
  }
}