import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_tracker_app/models/task.dart';
import 'package:task_tracker_app/models/team_member.dart';

/// Reads and writes the app's data as JSON in SharedPreferences.
///
/// Loading never throws. If the saved data is missing or corrupted the bad
/// records are skipped and whatever is still readable is returned, so a
/// single bad record can never crash the app.
class StorageService {
  static const String _tasksKey = 'tasks';
  static const String _membersKey = 'team_members';
  static const String _seedVersionKey = 'seed_version';

  Future<void> saveTasks(List<Task> tasks) async {
    final prefs = await SharedPreferences.getInstance();

    final data = tasks
        .map((task) => jsonEncode(task.toMap()))
        .toList();

    await prefs.setStringList(_tasksKey, data);
  }

  Future<List<Task>> loadTasks() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final data = prefs.getStringList(_tasksKey);

      if (data == null) {
        return [];
      }

      final tasks = <Task>[];
      for (final item in data) {
        try {
          final decoded = jsonDecode(item);
          if (decoded is Map<String, dynamic>) {
            tasks.add(Task.fromMap(decoded));
          }
        } catch (error) {
          // Skip only the corrupt record and keep the rest of the list.
          debugPrint('Skipping corrupt task record: $error');
        }
      }
      return tasks;
    } catch (error) {
      // Storage itself failed: return an empty list instead of crashing.
      debugPrint('Could not load tasks: $error');
      return [];
    }
  }

  Future<void> saveTeamMembers(List<TeamMember> members) async {
    final prefs = await SharedPreferences.getInstance();

    final data = members
        .map((member) => jsonEncode(member.toMap()))
        .toList();

    await prefs.setStringList(_membersKey, data);
  }

  Future<List<TeamMember>> loadTeamMembers() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final data = prefs.getStringList(_membersKey);

      if (data == null) {
        return [];
      }

      final members = <TeamMember>[];
      for (final item in data) {
        try {
          final decoded = jsonDecode(item);
          if (decoded is Map<String, dynamic>) {
            members.add(TeamMember.fromMap(decoded));
          }
        } catch (error) {
          debugPrint('Skipping corrupt team member record: $error');
        }
      }
      return members;
    } catch (error) {
      debugPrint('Could not load team members: $error');
      return [];
    }
  }

  /// The seed version written by [SeedData], or 0 when nothing is stored.
  ///
  /// Used to decide whether the sample data needs (re)seeding on this run.
  Future<int> loadSeedVersion() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_seedVersionKey) ?? 0;
    } catch (error) {
      debugPrint('Could not load seed version: $error');
      return 0;
    }
  }

  Future<void> saveSeedVersion(int version) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_seedVersionKey, version);
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_tasksKey);
    await prefs.remove(_membersKey);
    await prefs.remove(_seedVersionKey);
  }
}
