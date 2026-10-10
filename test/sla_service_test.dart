import 'package:flutter_test/flutter_test.dart';

import 'package:task_tracker_app/models/task.dart';
import 'package:task_tracker_app/models/sla_status.dart';
import 'package:task_tracker_app/services/sla_service.dart';

void main() {
  // Fixed "now" for deterministic tests.
  final testNow = DateTime(2024, 6, 10, 10, 0, 0);

  group('computeSla', () {
    test('returns completed for a done task', () {
      final task = Task(
        id: '1',
        title: 'Done task',
        assigneeId: 'a',
        dueDate: DateTime(2024, 6, 9), // past due
        status: TaskStatus.done,
        createdAt: testNow,
        updatedAt: testNow,
      );
      expect(SlaService.computeSla(task, now: testNow), SlaStatus.completed);
    });

    test('returns overdue for a past-due not-done task', () {
      final task = Task(
        id: '2',
        title: 'Overdue task',
        assigneeId: 'a',
        dueDate: DateTime(2024, 6, 9), // yesterday
        status: TaskStatus.todo,
        createdAt: testNow,
        updatedAt: testNow,
      );
      expect(SlaService.computeSla(task, now: testNow), SlaStatus.overdue);
    });

    test('returns atRisk for a task due within 48 hours', () {
      // due today at 11:59:59pm, now is 10am -> 13h59m to deadline
      final task = Task(
        id: '3',
        title: 'Today task',
        assigneeId: 'a',
        dueDate: DateTime(2024, 6, 10), // today
        status: TaskStatus.todo,
        createdAt: testNow,
        updatedAt: testNow,
      );
      expect(SlaService.computeSla(task, now: testNow), SlaStatus.atRisk);
    });

    test('returns onTrack for a task due in more than 48 hours', () {
      // due in 3 days -> 3 days * 24h = 72h to deadline, well over 48
      final task = Task(
        id: '4',
        title: 'Future task',
        assigneeId: 'a',
        dueDate: DateTime(2024, 6, 13), // in 3 days
        status: TaskStatus.todo,
        createdAt: testNow,
        updatedAt: testNow,
      );
      expect(SlaService.computeSla(task, now: testNow), SlaStatus.onTrack);
    });

    test('returns atRisk when due within 48 hours (close future date)', () {
      // Due June 12 at 08:00 -> deadline June 12, 23:59:59
      // From June 10, 10:00 to June 12, 23:59:59 = ~62 hours -> still atRisk if <= 48?
      // Let's calculate: 2 days 13h59m59s = 61h59m59s -> more than 48, onTrack.
      // Need a date where deadline - now <= 48h.
      // June 12 noon deadline (task due June 12 23:59:59) - June 10 10:00 = 51h59m59s -> onTrack.
      // Try June 11: deadline = June 11 23:59:59 - June 10 10:00 = 37h59m59s -> atRisk
      final task = Task(
        id: '5',
        title: 'At risk task (due tomorrow)',
        assigneeId: 'a',
        dueDate: DateTime(2024, 6, 11), // tomorrow, deadline at 23:59:59
        status: TaskStatus.todo,
        createdAt: testNow,
        updatedAt: testNow,
      );
      expect(SlaService.computeSla(task, now: testNow), SlaStatus.atRisk);
    });

    test('returns onTrack when due date is beyond 48h window', () {
      // Due June 12 -> deadline June 12 23:59:59 - June 10 10:00 = 51h59m59s -> onTrack
      final task = Task(
        id: '6',
        title: 'On track task (due in 2 days)',
        assigneeId: 'a',
        dueDate: DateTime(2024, 6, 12),
        status: TaskStatus.todo,
        createdAt: testNow,
        updatedAt: testNow,
      );
      expect(SlaService.computeSla(task, now: testNow), SlaStatus.onTrack);
    });

    test('uses current time when now is not provided', () {
      final task = Task(
        id: '7',
        title: 'Any task',
        assigneeId: 'a',
        dueDate: DateTime(2099, 12, 31), // far future
        status: TaskStatus.todo,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      // Should not throw
      final result = SlaService.computeSla(task);
      expect(result, SlaStatus.onTrack);
    });

    test('an in-progress task that is past due is overdue', () {
      final task = Task(
        id: '8',
        title: 'In progress overdue',
        assigneeId: 'a',
        dueDate: DateTime(2024, 6, 9),
        status: TaskStatus.inProgress,
        createdAt: testNow,
        updatedAt: testNow,
      );
      expect(SlaService.computeSla(task, now: testNow), SlaStatus.overdue);
    });
  });

  group('deadlineOf', () {
    test('returns 23:59:59 on the due date', () {
      final task = Task(
        id: 'd1',
        title: 'Test task',
        assigneeId: 'a',
        dueDate: DateTime(2024, 6, 15, 14, 30, 0),
        status: TaskStatus.todo,
        createdAt: testNow,
        updatedAt: testNow,
      );
      final deadline = SlaService.deadlineOf(task);
      expect(deadline.year, 2024);
      expect(deadline.month, 6);
      expect(deadline.day, 15);
      expect(deadline.hour, 23);
      expect(deadline.minute, 59);
      expect(deadline.second, 59);
    });
  });

  group('deadlineLine', () {
    test('returns "Completed" for a done task', () {
      final task = Task(
        id: 'dl1',
        title: 'Done task',
        assigneeId: 'a',
        dueDate: DateTime(2024, 1, 1),
        status: TaskStatus.done,
        createdAt: testNow,
        updatedAt: testNow,
      );
      expect(SlaService.deadlineLine(task, now: testNow), 'Completed');
    });

    test('returns "Due today" when due today', () {
      final task = Task(
        id: 'dl2',
        title: 'Due today',
        assigneeId: 'a',
        dueDate: DateTime(2024, 6, 10), // matches testNow date
        status: TaskStatus.todo,
        createdAt: testNow,
        updatedAt: testNow,
      );
      expect(SlaService.deadlineLine(task, now: testNow), 'Due today');
    });

    test('returns "Due tomorrow" when due tomorrow', () {
      final task = Task(
        id: 'dl3',
        title: 'Due tomorrow',
        assigneeId: 'a',
        dueDate: DateTime(2024, 6, 11), // day after testNow
        status: TaskStatus.todo,
        createdAt: testNow,
        updatedAt: testNow,
      );
      expect(SlaService.deadlineLine(task, now: testNow), 'Due tomorrow');
    });

    test('returns "Due in N days" for future tasks', () {
      final task = Task(
        id: 'dl4',
        title: 'Due in 3 days',
        assigneeId: 'a',
        dueDate: DateTime(2024, 6, 13), // 3 days after testNow
        status: TaskStatus.todo,
        createdAt: testNow,
        updatedAt: testNow,
      );
      expect(SlaService.deadlineLine(task, now: testNow), 'Due in 3 days');
    });

    test('returns "1 day overdue" when exactly 1 whole day late', () {
      // Due June 9, deadline June 9 23:59:59. Now June 10 at 10:00.
      // The deadline was only 10h ago, so inDays=0 -> "Due soon" fallback.
      // But if we set now to June 11 at 00:00, diff = 1 day 0h0m1s -> inDays=1.
      final nowPastDeadline = DateTime(2024, 6, 11, 0, 0, 1);
      final task = Task(
        id: 'dl5',
        title: '1 day overdue',
        assigneeId: 'a',
        dueDate: DateTime(2024, 6, 9), // 2 days ago
        status: TaskStatus.todo,
        createdAt: testNow,
        updatedAt: testNow,
      );
      expect(
        SlaService.deadlineLine(task, now: nowPastDeadline),
        '1 day overdue',
      );
    });

    test('returns "N days overdue" for multiple days late', () {
      // Due June 7, deadline June 7 23:59:59. Now June 10 10:00.
      // diff = 2 days 10h0m1s -> inDays=2 -> "2 days overdue"
      final task = Task(
        id: 'dl6',
        title: 'Multiple days overdue',
        assigneeId: 'a',
        dueDate: DateTime(2024, 6, 7),
        status: TaskStatus.todo,
        createdAt: testNow,
        updatedAt: testNow,
      );
      expect(SlaService.deadlineLine(task, now: testNow), '2 days overdue');
    });
  });

  group('slaReason', () {
    test('returns correct reason for completed', () {
      final task = Task(
        id: 'r1',
        title: 'Done task',
        assigneeId: 'a',
        dueDate: DateTime(2024, 6, 9),
        status: TaskStatus.done,
        createdAt: testNow,
        updatedAt: testNow,
      );
      expect(SlaService.slaReason(task, now: testNow), 'Marked as done.');
    });

    test('returns correct reason for overdue', () {
      final task = Task(
        id: 'r2',
        title: 'Overdue task',
        assigneeId: 'a',
        dueDate: DateTime(2024, 6, 9),
        status: TaskStatus.todo,
        createdAt: testNow,
        updatedAt: testNow,
      );
      expect(
        SlaService.slaReason(task, now: testNow),
        'The deadline has passed and the task is not done.',
      );
    });

    test('returns correct reason for atRisk', () {
      final task = Task(
        id: 'r3',
        title: 'At risk task',
        assigneeId: 'a',
        dueDate: DateTime(2024, 6, 10), // today -> within 48h
        status: TaskStatus.todo,
        createdAt: testNow,
        updatedAt: testNow,
      );
      expect(
        SlaService.slaReason(task, now: testNow),
        'Due within 48 hours and not yet done.',
      );
    });

    test('returns correct reason for onTrack', () {
      final task = Task(
        id: 'r4',
        title: 'On track task',
        assigneeId: 'a',
        dueDate: DateTime(2024, 6, 13), // in 3 days -> > 48h
        status: TaskStatus.todo,
        createdAt: testNow,
        updatedAt: testNow,
      );
      expect(
        SlaService.slaReason(task, now: testNow),
        'Due in more than 48 hours.',
      );
    });
  });
}
