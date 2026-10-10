import 'package:flutter/material.dart';
import 'task_list_screen.dart';

import '../utils/app_routes.dart';
import 'dashboard_screen.dart';
import 'placeholder_screen.dart';

/// The frame around the four main screens: it shows the bottom navigation
/// bar and switches between the Home, Tasks, Team and Profile tabs.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  // Tab positions, named so the code never uses bare numbers.
  static const int _homeTab = 0;
  static const int _tasksTab = 1;

  /// The tab currently shown.
  int _selectedIndex = _homeTab;

  /// Switches tab. setState() tells Flutter the selected tab changed, so
  /// it rebuilds the body and highlights the new tab in the bar.
  void _selectTab(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  /// Opens the Create Task screen on top of the tabs.
  void _openCreateTask() {
    Navigator.pushNamed(context, AppRoutes.createTask);
  }

  /// Opens Task Details on top of the tabs.
  void _openTaskDetails() {
    // TODO: pass the tapped task to the real Task Details screen.
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PlaceholderScreen(title: 'Task Details'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // The screens for each tab, in the same order as the destinations below.
    final screens = [
      DashboardScreen(
        onSlaCardTap: (status) => _selectTab(_tasksTab),
        onTaskTap: (task) => _openTaskDetails(),
        onCreateTask: _openCreateTask,
      ),
      const TaskListScreen(),
      const PlaceholderScreen(title: 'Team'),
      const PlaceholderScreen(title: 'Profile'),
    ];

    return Scaffold(
      // IndexedStack keeps every tab alive and only shows the selected one,
      // so a tab keeps its scroll position when you come back to it.
      body: IndexedStack(
        index: _selectedIndex,
        children: screens,
      ),
      // The Home tab has its own New Task button, so the shell only adds
      // one on the Tasks tab.
      floatingActionButton: _selectedIndex == _tasksTab
          ? FloatingActionButton.extended(
              // A unique tag, because the Home tab's button is still in
              // the tree and two buttons cannot share the default tag.
              heroTag: 'shellNewTask',
              onPressed: _openCreateTask,
              icon: const Icon(Icons.add),
              label: const Text('New Task'),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _selectTab,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.checklist_outlined),
            selectedIcon: Icon(Icons.checklist),
            label: 'Tasks',
          ),
          NavigationDestination(
            icon: Icon(Icons.group_outlined),
            selectedIcon: Icon(Icons.group),
            label: 'Team',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
