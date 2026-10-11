import 'package:flutter/material.dart';

import '../models/task.dart';
import '../models/team_member.dart';
import '../services/storage_service.dart';

import 'create_edit_task_screen.dart';
import 'dashboard_screen.dart';
import 'task_list_screen.dart';
import 'profile_screen.dart';
import 'team_members_screen.dart';
import 'task_details_screen.dart';
import '../utils/app_routes.dart';

/// The frame around the four main screens: it shows the bottom navigation
/// bar and switches between the Home, Tasks, Team and Profile tabs.
class MainShell extends StatefulWidget {
  const MainShell({
    super.key,
    required this.currentUser,
    required this.onSignOut,
  });

  /// The team member who is signed in.
  final TeamMember currentUser;

  /// Called when the user signs out from the Profile tab.
  final VoidCallback onSignOut;

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

  /// The team members, passed to Task Details to show the assignee's name.
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

  /// Opens the Create Task form on top of the tabs.
  Future<void> _openCreateTask() async {
    await Navigator.pushNamed(context, AppRoutes.createTask);
    if (!mounted) return;
    // The form saves the task itself, so the tabs only need to reload.
    _refresh();
  }

  /// Opens the form to edit [task]. Called from the Task Details screen.
  Future<void> _openEditTask(Task task) async {
    final updatedTask = await Navigator.push<Task>(
      context,
      MaterialPageRoute(
        builder: (context) => CreateEditTaskScreen(task: task),
      ),
    );

    // Null means the form was closed without saving.
    if (updatedTask == null || !mounted) return;

    // Task Details keeps its own copy of the task, so replace that screen
    // with a fresh one showing the saved values.
    _openTaskDetails(updatedTask, replaceCurrent: true);
  }

  /// Saves a change made on Task Details, such as a new status.
  ///
  /// The list is read from storage first so tasks created or edited
  /// elsewhere are neverr overwritten by an old copy.
  Future<void> _saveTask(Task updatedTask) async {
    final storage = StorageService();
    final tasks = await storage.loadTasks();
    final index = tasks.indexWhere((t) => t.id == updatedTask.id);
    if (index >= 0) {
      tasks[index] = updatedTask;
    }
    await storage.saveTasks(tasks);
    if (!mounted) return;
    _refresh();
  }

  /// Removes the tak with the given id from storage.
  Future<void> _deleteTask(String id) async {
    final storage = StorageService();
    final tasks = await storage.loadTasks();
    tasks.removeWhere((t) => t.id == id);
    await storage.saveTasks(tasks);
    if (!mounted) return;
    _refresh();
  }

  /// Opens Task Details for the given task.
  ///
  /// With [replaceCurrent] the screen on top is swapped for the new one
  /// instead of stacking another scraen above it.
  Future<void> _openTaskDetails(
    Task task, {
    bool replaceCurrent = false,
  }) async {
    final route = MaterialPageRoute<void>(
      builder: (context) => TaskDetailsScreen(
        task: task,
        members: _currentMembers,
        onSave: _saveTask,
        onDelete: _deleteTask,
        onEdit: _openEditTask,
      ),
    );

    if (replaceCurrent) {
      await Navigator.pushReplacement(context, route);
    } else {
      await Navigator.push(context, route);
    }

    if (!mounted) return;
    _refresh();
  }

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    final members = await StorageService().loadTeamMembers();
    if (!mounted) return;
    setState(() {
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
        currentUserId: widget.currentUser.id,
        onTaskTap: (task) => _openTaskDetails(task),
      ),
      const TeamMembersScreen(),
      ProfileScreen(
        key: ValueKey('profile-$_refreshToken'),
        currentUser: widget.currentUser,
        onSignOut: widget.onSignOut,
      ),
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
