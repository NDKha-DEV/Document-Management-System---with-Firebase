import 'package:flutter/material.dart';
import '../features/subjects/subjects_page.dart';
import '../features/documents/documents_page.dart';
import '../features/deadlines/deadlines_page.dart';
import '../features/settings/settings_page.dart';

class MainNavigationFramework extends StatefulWidget {
  const MainNavigationFramework({super.key});

  @override
  State<MainNavigationFramework> createState() =>
      _MainNavigationFrameworkState();
}

class _MainNavigationFrameworkState extends State<MainNavigationFramework> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    SubjectsPage(),
    DocumentsPage(),
    DeadlinesPage(),
    SettingsPage(),
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
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.school_outlined),
            selectedIcon: Icon(Icons.school_rounded),
            label: 'Môn Học',
          ),
          NavigationDestination(
            icon: Icon(Icons.description_outlined),
            selectedIcon: Icon(Icons.description_rounded),
            label: 'Tài Liệu',
          ),
          NavigationDestination(
            icon: Icon(Icons.event_note_outlined),
            selectedIcon: Icon(Icons.event_note_rounded),
            label: 'Hạn Nộp',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded),
            label: 'Cài Đặt',
          ),
        ],
      ),
    );
  }
}
