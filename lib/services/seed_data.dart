import 'package:task_tracker_app/models/task.dart';
import 'package:task_tracker_app/models/team_member.dart';
import 'storage_service.dart';

/// Writes the sample team and tasks into local storage.
///
/// [seed] is called once from `main` before the first screen is shown, so
/// every screen reads the same data. It only writes when the stored seed
/// version is out of date, which means:
///
/// * a fresh install is seeded once, and
/// * an install holding older sample data is refreshed automatically.
class SeedData {
  /// Bump this when the sample data below changes.
  ///
  /// Existing installs re-seed when the stored version does not match, so
  /// everyone sees the new sample data without uninstalling the app.
  static const int version = 2;

  static Future<void> seed(StorageService storage, {DateTime? now}) async {
    if (await storage.loadSeedVersion() == version) {
      return;
    }

    // Start clean so re-seeding never leaves old records behind.
    await storage.clearAll();

    final seededAt = now ?? DateTime.now();

    await storage.saveTeamMembers(_members);
    await storage.saveTasks(_tasks(seededAt));
    await storage.saveSeedVersion(version);
  }

  /// The four people on the project.
  ///
  /// Ids are fixed and stable because tasks store a member id, not a name.
  static const List<TeamMember> _members = [
    TeamMember(id: '1', name: 'Naomi', role: 'Mobile Developer'),
    TeamMember(id: '2', name: 'Cyuzuzo', role: 'Mobile Developer'),
    TeamMember(id: '3', name: 'Moses', role: 'QA Tester'),
    TeamMember(id: '4', name: 'Mitchell', role: 'Project Manager'),
  ];

  /// Builds the eight sample tasks.
  ///
  /// The mix is deliberate: 2 Completed, 2 Overdue, 2 At Risk (due within
  /// 48 hours) and 2 On Track, so the demo shows every SLA colour. Because
  /// the SLA status is computed from the due date, the sample dates are
  /// relative to [now] and the mix is correct as soon as the data is seeded.
  static List<Task> _tasks(DateTime now) {
    return [
      // --- Completed (2) ---
      _task(now, order: 0, id: 'seed-1', title: 'Finish Dashboard',
          assigneeId: '1', dueInDays: -3,
          priority: TaskPriority.high, status: TaskStatus.done),
      _task(now, order: 1, id: 'seed-2', title: 'Write API tests',
          assigneeId: '2', dueInDays: 2,
          priority: TaskPriority.medium, status: TaskStatus.done),

      // --- Overdue (2) ---
      _task(now, order: 2, id: 'seed-3', title: 'Fix login bug',
          assigneeId: '1', dueInDays: -1,
          priority: TaskPriority.high, status: TaskStatus.inProgress),
      _task(now, order: 3, id: 'seed-4', title: 'Update onboarding copy',
          assigneeId: '4', dueInDays: -4,
          priority: TaskPriority.low, status: TaskStatus.todo),

      // --- At Risk (2): deadline within 48 hours ---
      _task(now, order: 4, id: 'seed-5', title: 'Polish task list UI',
          assigneeId: '3', dueInDays: 0,
          priority: TaskPriority.high, status: TaskStatus.todo),
      _task(now, order: 5, id: 'seed-6', title: 'Set up CI pipeline',
          assigneeId: '2', dueInDays: 1,
          priority: TaskPriority.medium, status: TaskStatus.todo),

      // --- On Track (2): deadline more than 48 hours away ---
      _task(now, order: 6, id: 'seed-7', title: 'Design profile screen',
          assigneeId: '4', dueInDays: 4,
          priority: TaskPriority.low, status: TaskStatus.todo),
      _task(now, order: 7, id: 'seed-8', title: 'Rate limiting on the API',
          assigneeId: '2', dueInDays: 6,
          priority: TaskPriority.medium, status: TaskStatus.todo),
    ];
  }

  /// Builds one sample task with a fixed id.
  ///
  /// This uses the normal [Task] constructor on purpose: [Task.create]
  /// derives the id from the current time, so tasks created in the same
  /// millisecond would share an id and deleting one would affect the others.
  /// [order] only staggers [Task.createdAt] so the "Recent Tasks" list has
  /// a stable order.
  static Task _task(
    DateTime now, {
    required int order,
    required String id,
    required String title,
    required String assigneeId,
    required int dueInDays,
    required TaskPriority priority,
    required TaskStatus status,
  }) {
    final createdAt = now.subtract(Duration(minutes: order));
    return Task(
      id: id,
      title: title,
      assigneeId: assigneeId,
      // Only the calendar date matters to the SLA rules, so build it from
      // the date and let Dart roll the month/year over when needed.
      dueDate: DateTime(now.year, now.month, now.day + dueInDays),
      priority: priority,
      status: status,
      createdAt: createdAt,
      updatedAt: createdAt,
    );
  }
}
