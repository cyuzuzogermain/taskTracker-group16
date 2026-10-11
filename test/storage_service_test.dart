import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:task_tracker_app/models/task.dart';
import 'package:task_tracker_app/models/team_member.dart';
import 'package:task_tracker_app/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final now = DateTime(2026, 1, 1);

  final goodTask = Task(
    id: 'seed-1',
    title: 'Good task',
    assigneeId: '1',
    dueDate: now,
    createdAt: now,
    updatedAt: now,
  );

  const goodMember = TeamMember(id: '1', name: 'Naomi', role: 'QA Tester');

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('loadTasks', () {
    test('returns an empty list when nothing is stored', () async {
      expect(await StorageService().loadTasks(), isEmpty);
    });

    test('skips a corrupt record and keeps the good ones', () async {
      SharedPreferences.setMockInitialValues({
        'tasks': <String>[
          'this is not json',
          jsonEncode(goodTask.toMap()),
        ],
      });

      final tasks = await StorageService().loadTasks();

      expect(tasks.length, 1);
      expect(tasks.single.id, 'seed-1');
    });

    test('returns an empty list when every record is corrupt', () async {
      SharedPreferences.setMockInitialValues({
        'tasks': <String>['{not json}', 'also broken'],
      });

      expect(await StorageService().loadTasks(), isEmpty);
    });
  });

  group('loadTeamMembers', () {
    test('returns an empty list when nothing is stored', () async {
      expect(await StorageService().loadTeamMembers(), isEmpty);
    });

    test('skips a corrupt record and keeps the good ones', () async {
      SharedPreferences.setMockInitialValues({
        'team_members': <String>[
          jsonEncode(goodMember.toMap()),
          'not json at all',
        ],
      });

      final members = await StorageService().loadTeamMembers();

      expect(members.length, 1);
      expect(members.single.name, 'Naomi');
    });
  });

  group('seed version', () {
    test('defaults to 0 when nothing is stored', () async {
      expect(await StorageService().loadSeedVersion(), 0);
    });

    test('round-trips a saved value', () async {
      final storage = StorageService();
      await storage.saveSeedVersion(2);
      expect(await storage.loadSeedVersion(), 2);
    });

    test('clearAll removes the seed version too', () async {
      final storage = StorageService();
      await storage.saveSeedVersion(2);
      await storage.clearAll();
      expect(await storage.loadSeedVersion(), 0);
    });
  });
}
