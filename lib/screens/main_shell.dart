import 'package:flutter/material.dart';

import '../models/task.dart';
import '../models/team_member.dart';
import '../services/storage_service.dart';

import 'dashboard_screen.dart';
import 'task_list_screen.dart';
import 'placeholder_screen.dart';
import 'team_members_screen.dart';
import 'task_details_screen.dart';
import '../utils/app_routes.dart';

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

  /// Increments each time a modal screen returns. Tabs key off this value
  /// so they reload their data after Task Details or Create Task closes.
  int _refreshToken = 0;

  List<Task> _currentTasks = [];
  List<TeamMember> _currentMembers = [];

  /// Switches tab. setState() tells Flutter the selected tab changed, so
  /// it rebuilds the body and highlights the new tab in the bar.
  void _selectTab(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  /// Increments the refresh token so tabs re-fetch from storage.
  void _refresh() {
    setState(() => _refreshToken++);
  }

  /// Opens the Create Task screen on top of the tabs.
  void _openCreateTask() async {
    await Navigator.pushNamed(context, AppRoutes.createTask);
    // After returning, both the Dashboard and Task List reload data.
    _refresh();
  }

  /// Opens Task Details for the given task.
  ///
  /// If [TaskDetailsScreen] exists it is shown directly; otherwise the
  /// placeholder is used and the caller is expected to wire it up later.
  Future<void> _openTaskDetails(Task task) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TaskDetailsScreen(
          task: task,
          members: _currentMembers,
          onSave: (updatedTask) async {
            // Update the task in our local list.
            final idx = _currentTasks.indexWhere((t) => t.id == updatedTask.id);
            if (idx >= 0) {
              _currentTasks = List<Task>.from(_currentTasks)..[idx] = updatedTask;
            }
            await StorageService().saveTasks(_currentTasks);
            _refresh();
          },
          onDelete: (id) async {
            final updated = _currentTasks.where((t) => t.id != id).toList();
            _currentTasks = updated;
            await StorageService().saveTasks(updated);
            _refresh();
          },
          onEdit: (task) {
            // TODO: navigate to the Create/Edit task route if it exists.
            // <missing-route> Create/Edit task route not wired yet; placeholder.
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Edit task: ${task.title}'),
                duration: const Duration(seconds: 1),
              ),
            );
          },
        ),
      ),
    );
    _refresh();
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final storage = StorageService();
    final tasks = await storage.loadTasks();
    final members = await storage.loadTeamMembers();
    if (!mounted) return;
    setState(() {
      _currentTasks = tasks;
      _currentMembers = members;
    });
  }

  @override
  Widget build(BuildContext context) {
    // The screens for each tab, in the same order as the destinations below.
    // Keyed by _refreshToken so the screens rebuild when data changes.
    final screens = [
      DashboardScreen(
        key: ValueKey('dashboard-$_refreshToken'),
        onSlaCardTap: (status) => _selectTab(_tasksTab),
        onTaskTap: (task) => _openTaskDetails(task),
      ),
      TaskListScreen(
        key: ValueKey('tasks-$_refreshToken'),
        currentUserId: null, // TODO: pass the current user id when auth is ready.
        onTaskTap: (task) => _openTaskDetails(task),
      ),
      const TeamMembersScreen(),
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
