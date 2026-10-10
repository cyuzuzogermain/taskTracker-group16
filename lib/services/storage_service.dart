import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_tracker_app/models/task.dart';
import 'package:task_tracker_app/models/team_member.dart';

class StorageService {
  static const String _tasksKey = 'tasks';
  static const String _membersKey = 'team_members';

  Future<void> saveTasks(List<Task> tasks) async {
    final prefs = await SharedPreferences.getInstance();

    final data = tasks
        .map((task) => jsonEncode(task.toMap()))
        .toList();

    await prefs.setStringList(_tasksKey, data);
  }

  Future<List<Task>> loadTasks() async {
    final prefs = await SharedPreferences.getInstance();

    final data = prefs.getStringList(_tasksKey);

    if (data == null) {
      return [];
    }

    return data
        .map((item) => Task.fromMap(jsonDecode(item)))
        .toList();
  }

  Future<void> saveTeamMembers(List<TeamMember> members) async {
    final prefs = await SharedPreferences.getInstance();

    final data = members
        .map((member) => jsonEncode(member.toMap()))
        .toList();

    await prefs.setStringList(_membersKey, data);
  }

  Future<List<TeamMember>> loadTeamMembers() async {
    final prefs = await SharedPreferences.getInstance();

    final data = prefs.getStringList(_membersKey);

    if (data == null) {
      return [];
    }

    return data
        .map((item) => TeamMember.fromMap(jsonDecode(item)))
        .toList();
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_tasksKey);
    await prefs.remove(_membersKey);
  }
}