import 'package:flutter_test/flutter_test.dart';

import 'package:task_tracker_app/models/task.dart';
import 'package:task_tracker_app/models/workload_summary.dart';

void main() {
  // Fixed "now" so the SLA status of each task is deterministic.
  final now = DateTime(2026, 6, 10, 10, 0, 0);

  Task task({
    required String id,
    required DateTime dueDate,
    TaskStatus status = TaskStatus.todo,
  }) {
    return Task(
      id: id,
      title: 'Task $id',
      assigneeId: '1',
      dueDate: dueDate,
      status: status,
      createdAt: now,
      updatedAt: now,
    );
  }

  test('an empty list gives an empty, clear summary', () {
    final summary = WorkloadSummary.of(const [], now: now);

    expect(summary.total, 0);
    expect(summary.atRisk, 0);
    expect(summary.overdue, 0);
    expect(summary.isClear, isTrue);
  });

  test('counts totals, At Risk and Overdue separately', () {
    final summary = WorkloadSummary.of([
      task(id: 'done', dueDate: DateTime(2026, 6, 9), status: TaskStatus.done),
      task(id: 'overdue', dueDate: DateTime(2026, 6, 9)),
      task(id: 'atRiskToday', dueDate: DateTime(2026, 6, 10)),
      task(id: 'atRiskTomorrow', dueDate: DateTime(2026, 6, 11)),
      task(id: 'onTrack', dueDate: DateTime(2026, 6, 20)),
    ], now: now);

    expect(summary.total, 5);
    expect(summary.atRisk, 2);
    expect(summary.overdue, 1);
    expect(summary.isClear, isFalse);
  });

  test('a done task that is past due is not counted as Overdue', () {
    final summary = WorkloadSummary.of([
      task(id: 'doneLate', dueDate: DateTime(2026, 1, 1), status: TaskStatus.done),
    ], now: now);

    expect(summary.total, 1);
    expect(summary.overdue, 0);
    expect(summary.atRisk, 0);
    expect(summary.isClear, isTrue);
  });

  test('an in-progress task that is past due is Overdue', () {
    final summary = WorkloadSummary.of([
      task(id: 'late', dueDate: DateTime(2026, 6, 1), status: TaskStatus.inProgress),
    ], now: now);

    expect(summary.overdue, 1);
  });
}
