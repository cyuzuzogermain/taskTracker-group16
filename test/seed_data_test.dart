import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:task_tracker_app/models/sla_status.dart';
import 'package:task_tracker_app/services/seed_data.dart';
import 'package:task_tracker_app/services/sla_service.dart';
import 'package:task_tracker_app/services/storage_service.dart';

void main() {
  // Fixed time so the "today"-relative sample dates are deterministic.
  final testNow = DateTime(2026, 1, 1, 10, 0, 0);

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('seeds eight tasks with unique, fixed ids', () async {
    final storage = StorageService();
    await SeedData.seed(storage, now: testNow);

    final tasks = await storage.loadTasks();

    expect(tasks.length, 8);
    // Every id is distinct: deleting or editing one cannot affect another.
    expect(tasks.map((t) => t.id).toSet().length, 8);
    expect(
      tasks.map((t) => t.id).toSet(),
      {'seed-1', 'seed-2', 'seed-3', 'seed-4', 'seed-5', 'seed-6', 'seed-7', 'seed-8'},
    );
  });

  test('seeds two tasks in each SLA state', () async {
    final storage = StorageService();
    await SeedData.seed(storage, now: testNow);

    final tasks = await storage.loadTasks();

    int countOf(SlaStatus status) =>
        tasks.where((t) => SlaService.computeSla(t, now: testNow) == status).length;

    expect(countOf(SlaStatus.completed), 2);
    expect(countOf(SlaStatus.overdue), 2);
    expect(countOf(SlaStatus.atRisk), 2);
    expect(countOf(SlaStatus.onTrack), 2);
  });

  test('seeds the four named team members', () async {
    final storage = StorageService();
    await SeedData.seed(storage, now: testNow);

    final members = await storage.loadTeamMembers();

    expect(members.length, 4);
    expect(
      members.map((m) => '${m.name} (${m.role})').toList(),
      [
        'Naomi (Mobile Developer)',
        'Cyuzuzo (Mobile Developer)',
        'Moses (QA Tester)',
        'Mitchell (Project Manager)',
      ],
    );
  });

  test('does not seed again once the current version is stored', () async {
    final storage = StorageService();
    await SeedData.seed(storage, now: testNow);

    // A user adds a task of their own.
    final tasks = await storage.loadTasks();
    await storage.saveTasks([...tasks, tasks.first.copyWith(title: 'Mine')]);

    // Running the seed again is a no-op, so the user's change survives.
    await SeedData.seed(storage, now: testNow.add(const Duration(days: 1)));

    expect((await storage.loadTasks()).length, 9);
  });

  test('re-seeds when the stored version is out of date', () async {
    final storage = StorageService();
    // Pretend an older seed ran before.
    await storage.saveSeedVersion(1);

    await SeedData.seed(storage, now: testNow);

    expect((await storage.loadTasks()).length, 8);
  });
}
