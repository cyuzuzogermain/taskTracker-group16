import 'package:task_tracker_app/models/task.dart';
import 'package:task_tracker_app/models/team_member.dart';
import 'storage_service.dart';

class SeedData {
  static Future<void> seed(StorageService storage) async {
    final existingTasks = await storage.loadTasks();

    if (existingTasks.isNotEmpty) {
      return;
    }

    final members = [
      TeamMember(
        id: '1',
        name: 'Naomi',
        role: 'Frontend',
      ),
      TeamMember(
        id: '2',
        name: 'Cyuzuzo',
        role: 'Backend',
      ),
      TeamMember(
        id: '3',
        name: 'Mitchell',
        role: 'UI Designer',
      ),
      TeamMember(
        id: '4',
        name: 'Germain',
        role: 'Project Lead',
      ),
    ];

    await storage.saveTeamMembers(members);

    final now = DateTime.now();

    final tasks = [
      Task.create(
        title: 'Finish Dashboard',
        assigneeId: '1',
        dueDate: now.add(const Duration(days: 2)),
        priority: TaskPriority.high,
      ),
      Task.create(
        title: 'Implement Login',
        assigneeId: '2',
        dueDate: now.add(const Duration(days: 4)),
      ),
      Task.create(
        title: 'Profile Screen',
        assigneeId: '3',
        dueDate: now.add(const Duration(days: 5)),
      ),
      Task.create(
        title: 'Testing',
        assigneeId: '4',
        dueDate: now.add(const Duration(days: 7)),
      ),
    ];

    await storage.saveTasks(tasks);
  }
}