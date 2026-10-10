/// How urgent a task is.
enum TaskPriority {
  low('Low'),
  medium('Medium'),
  high('High');

  const TaskPriority(this.label);

  /// Readable text shown in the UI.
  final String label;
}

/// Where a task is in its workflow.
enum TaskStatus {
  todo('To Do'),
  inProgress('In Progress'),
  done('Done');

  const TaskStatus(this.label);

  /// Readable text shown in the UI.
  final String label;
}

/// A single project task.
///
/// The SLA status is not stored here. It is calculated from [dueDate] and
/// [status] by the SLA service whenever it is needed.
class Task {
  // Validation limits, shared with the Create/Edit Task form.
  static const int titleMinLength = 3;
  static const int titleMaxLength = 60;
  static const int descriptionMaxLength = 300;

  final String id;
  final String title;
  final String description; // Empty string when not provided.
  final String assigneeId; // The id of a TeamMember, not their name.
  final DateTime dueDate;
  final TaskPriority priority;
  final TaskStatus status;
  final String notes; // Empty string when not provided.
  final DateTime createdAt;
  final DateTime updatedAt;

  const Task({
    required this.id,
    required this.title,
    this.description = '',
    required this.assigneeId,
    required this.dueDate,
    this.priority = TaskPriority.medium,
    this.status = TaskStatus.todo,
    this.notes = '',
    required this.createdAt,
    required this.updatedAt,
  });

  /// Creates a brand new task: generates the id and sets both timestamps.
  factory Task.create({
    required String title,
    String description = '',
    required String assigneeId,
    required DateTime dueDate,
    TaskPriority priority = TaskPriority.medium,
    TaskStatus status = TaskStatus.todo,
    String notes = '',
  }) {
    final now = DateTime.now();
    return Task(
      id: now.millisecondsSinceEpoch.toString(),
      title: title,
      description: description,
      assigneeId: assigneeId,
      dueDate: dueDate,
      priority: priority,
      status: status,
      notes: notes,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Returns a copy with the given fields changed.
  ///
  /// The id and createdAt never change. updatedAt is set to now unless a
  /// value is passed in.
  Task copyWith({
    String? title,
    String? description,
    String? assigneeId,
    DateTime? dueDate,
    TaskPriority? priority,
    TaskStatus? status,
    String? notes,
    DateTime? updatedAt,
  }) {
    return Task(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      assigneeId: assigneeId ?? this.assigneeId,
      dueDate: dueDate ?? this.dueDate,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  /// Converts the task to a map that can be saved as JSON.
  /// Dates are stored as ISO strings and enums by their name.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'assigneeId': assigneeId,
      'dueDate': dueDate.toIso8601String(),
      'priority': priority.name,
      'status': status.name,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Rebuilds a task from a map read out of storage.
  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String? ?? '',
      assigneeId: map['assigneeId'] as String,
      dueDate: DateTime.parse(map['dueDate'] as String),
      priority: _priorityFromName(map['priority'] as String?),
      status: _statusFromName(map['status'] as String?),
      notes: map['notes'] as String? ?? '',
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  // If the stored name is missing or unknown, fall back to the default
  // instead of crashing.
  static TaskPriority _priorityFromName(String? name) {
    for (final priority in TaskPriority.values) {
      if (priority.name == name) return priority;
    }
    return TaskPriority.medium;
  }

  static TaskStatus _statusFromName(String? name) {
    for (final status in TaskStatus.values) {
      if (status.name == name) return status;
    }
    return TaskStatus.todo;
  }
}
