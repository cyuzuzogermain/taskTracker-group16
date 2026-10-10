import 'package:task_tracker_app/models/sla_status.dart';
import 'package:task_tracker_app/models/task.dart';

/// SLA rules for tasks.
///
/// Rules, checked in order:
/// 1. Completed: status == TaskStatus.done
/// 2. Overdue: not done and now is after the deadline
/// 3. At Risk: not done and the deadline is within 48 hours
/// 4. On Track: everything else
///
/// The deadline is 11:59:59 pm local time on the due date.
class SlaService {
  static const int atRiskWindowHours = 48;

  /// Returns the deadline for a task: 11:59:59 pm local time on the due date.
  static DateTime deadlineOf(Task t) {
    final due = t.dueDate;
    return DateTime(due.year, due.month, due.day, 23, 59, 59);
  }

  /// Computes the SLA status for a task at the given time (defaults to now).
  static SlaStatus computeSla(Task t, {DateTime? now}) {
    final effectiveNow = now ?? DateTime.now();
    final deadline = deadlineOf(t);

    if (t.status == TaskStatus.done) {
      return SlaStatus.completed;
    }
    if (effectiveNow.isAfter(deadline)) {
      return SlaStatus.overdue;
    }
    final hoursUntilDeadline = deadline.difference(effectiveNow).inHours;
    if (hoursUntilDeadline <= atRiskWindowHours) {
      return SlaStatus.atRisk;
    }
    return SlaStatus.onTrack;
  }

  /// Returns a human-readable deadline line.
  ///
  /// Examples:
  /// - "Completed"
  /// - "Due today"
  /// - "Due tomorrow"
  /// - "Due in N days"
  /// - "1 day overdue"
  /// - "N days overdue"
  static String deadlineLine(Task t, {DateTime? now}) {
    final effectiveNow = now ?? DateTime.now();
    final deadline = deadlineOf(t);

    if (t.status == TaskStatus.done) {
      return 'Completed';
    }

    final today = DateTime(effectiveNow.year, effectiveNow.month, effectiveNow.day);
    final tomorrow = today.add(const Duration(days: 1));
    final dueDate = t.dueDate;

    if (dueDate.isAtSameMomentAs(today)) {
      return 'Due today';
    }
    if (dueDate.isAtSameMomentAs(tomorrow)) {
      return 'Due tomorrow';
    }

    final diff = effectiveNow.difference(deadline);
    final daysLate = diff.inDays;

    if (daysLate > 0) {
      return '$daysLate day${daysLate == 1 ? '' : 's'} overdue';
    }

    // Due in the future
    final daysUntilDue = deadline.difference(effectiveNow).inDays;
    if (daysUntilDue > 1) {
      return 'Due in $daysUntilDue days';
    }

    // Should not reach here for valid inputs, but return a fallback
    return 'Due soon';
  }

  /// Returns the reason text for the SLA status.
  static String slaReason(Task t, {DateTime? now}) {
    switch (computeSla(t, now: now)) {
      case SlaStatus.completed:
        return 'Marked as done.';
      case SlaStatus.overdue:
        return 'The deadline has passed and the task is not done.';
      case SlaStatus.atRisk:
        return 'Due within $atRiskWindowHours hours and not yet done.';
      case SlaStatus.onTrack:
        return 'Due in more than $atRiskWindowHours hours.';
    }
  }
}
