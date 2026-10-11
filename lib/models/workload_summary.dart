import 'package:task_tracker_app/models/sla_status.dart';
import 'package:task_tracker_app/models/task.dart';
import 'package:task_tracker_app/services/sla_service.dart';

/// A team member's task load, split by the SLA states that need attention.
///
/// The SLA status is computed with [SlaService] and never stored or
/// duplicated, so this summary always agrees with the rules defined there.
class WorkloadSummary {
  /// Every task assigned to the member.
  final int total;

  /// How many of those tasks are within 48 hours of their deadline.
  final int atRisk;

  /// How many of those tasks are past their deadline and not done.
  final int overdue;

  const WorkloadSummary({
    required this.total,
    required this.atRisk,
    required this.overdue,
  });

  /// A summary for a member with nothing assigned.
  static const WorkloadSummary empty =
      WorkloadSummary(total: 0, atRisk: 0, overdue: 0);

  /// True when no assigned task needs attention.
  bool get isClear => atRisk == 0 && overdue == 0;

  /// Summarises the tasks assigned to one member.
  ///
  /// Pass [now] to keep the result deterministic in tests; it defaults to
  /// the current time.
  factory WorkloadSummary.of(List<Task> tasks, {DateTime? now}) {
    var atRisk = 0;
    var overdue = 0;

    for (final task in tasks) {
      final sla = SlaService.computeSla(task, now: now);
      if (sla == SlaStatus.atRisk) {
        atRisk++;
      } else if (sla == SlaStatus.overdue) {
        overdue++;
      }
      // On Track and Completed need no attention, so they are only counted
      // in the total.
    }

    return WorkloadSummary(
      total: tasks.length,
      atRisk: atRisk,
      overdue: overdue,
    );
  }
}
