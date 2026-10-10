// TEMPORARY, replace with the shared models and SLA service when merged.

/// Possible SLA statuses for a task.
enum SlaStatus {
  onTrack,
  atRisk,
  overdue,
  completed,
}

/// A minimal Task model for the Dashboard screen.
/// Will be replaced by the shared model from teammates.
class Task {
  final String id;
  final String title;
  final String assignee;
  final DateTime dueDate;
  final String status; // To Do, In Progress, Done
  final DateTime createdAt;

  const Task({
    required this.id,
    required this.title,
    required this.assignee,
    required this.dueDate,
    required this.status,
    required this.createdAt,
  });
}

/// Window (in hours) before the due date at which a task is "At Risk".
/// Change this value and hot reload to see counts update live during the demo.
const int atRiskHours = 48;

/// Classify a task into an SLA status based on its completion and due date.
SlaStatus computeSla(Task t) {
  // Completed tasks are always "Completed" regardless of dates.
  if (t.status == 'Done') {
    return SlaStatus.completed;
  }

  final now = DateTime.now();
  final due = t.dueDate;

  // Overdue: not completed and the deadline has already passed.
  if (due.isBefore(now)) {
    return SlaStatus.overdue;
  }

  // At Risk: not completed and due within the atRiskHours window.
  final hoursUntilDue = due.difference(now).inHours;
  if (hoursUntilDue <= atRiskHours) {
    return SlaStatus.atRisk;
  }

  // Otherwise the task is On Track.
  return SlaStatus.onTrack;
}

/// Seed data: ~8 tasks so all four SLA statuses appear on screen.
List<Task> createDummyTasks() {
  final now = DateTime.now();

  return [
    // Completed
    Task(
      id: '1',
      title: 'Submit group project proposal',
      assignee: 'Alice',
      dueDate: now.subtract(const Duration(days: 3)),
      status: 'Done',
      createdAt: now.subtract(const Duration(days: 10)),
    ),
    // Overdue
    Task(
      id: '2',
      title: 'Fix login screen UI bugs',
      assignee: 'Bob',
      dueDate: now.subtract(const Duration(days: 1)),
      status: 'In Progress',
      createdAt: now.subtract(const Duration(days: 7)),
    ),
    // At Risk (due within 48 hours)
    Task(
      id: '3',
      title: 'Review teammate pull requests',
      assignee: 'Charlie',
      dueDate: now.add(const Duration(hours: 12)),
      status: 'To Do',
      createdAt: now.subtract(const Duration(days: 2)),
    ),
    // At Risk (due within 48 hours)
    Task(
      id: '4',
      title: 'Prepare presentation slides',
      assignee: 'Diana',
      dueDate: now.add(const Duration(hours: 36)),
      status: 'In Progress',
      createdAt: now.subtract(const Duration(days: 1)),
    ),
    // On Track (due further out)
    Task(
      id: '5',
      title: 'Set up CI/CD pipeline',
      assignee: 'Alice',
      dueDate: now.add(const Duration(days: 5)),
      status: 'To Do',
      createdAt: now.subtract(const Duration(hours: 6)),
    ),
    // On Track (due further out)
    Task(
      id: '6',
      title: 'Write unit tests for auth module',
      assignee: 'Bob',
      dueDate: now.add(const Duration(days: 7)),
      status: 'To Do',
      createdAt: now.subtract(const Duration(hours: 4)),
    ),
    // Completed
    Task(
      id: '7',
      title: 'Create project README',
      assignee: 'Charlie',
      dueDate: now.subtract(const Duration(days: 5)),
      status: 'Done',
      createdAt: now.subtract(const Duration(days: 12)),
    ),
    // On Track
    Task(
      id: '8',
      title: 'Design database schema',
      assignee: 'Diana',
      dueDate: now.add(const Duration(days: 10)),
      status: 'In Progress',
      createdAt: now.subtract(const Duration(days: 3)),
    ),
  ];
}
