import 'package:flutter/material.dart';
import 'package:task_tracker_app/models/sla_status.dart';
import 'package:task_tracker_app/models/task.dart';
import 'package:task_tracker_app/models/team_member.dart';
import 'package:task_tracker_app/models/workload_summary.dart';
import 'package:task_tracker_app/screens/add_member_screen.dart';
import 'package:task_tracker_app/services/storage_service.dart';
import 'package:task_tracker_app/theme/app_theme.dart';
import 'package:task_tracker_app/theme/sla_colors.dart';

class TeamMembersScreen extends StatefulWidget {
  const TeamMembersScreen({super.key});

  @override
  State<TeamMembersScreen> createState() => _TeamMembersScreenState();
}

class _TeamMembersScreenState extends State<TeamMembersScreen> {
  final StorageService storage = StorageService();

  List<TeamMember> members = [];
  List<Task> tasks = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadMembers();
  }

  Future<void> loadMembers() async {
    // The sample data is seeded in main() before the app starts, so this
    // only needs to read what is already stored.
    final memberData = await storage.loadTeamMembers();
    final taskData = await storage.loadTasks();

    if (!mounted) return;

    setState(() {
      members = memberData;
      tasks = taskData;
      isLoading = false;
    });
  }

  /// Opens the Add Team Member form, then reloads the list if one was added.
  Future<void> _openAddMember() async {
    final newMember = await Navigator.push<TeamMember>(
      context,
      MaterialPageRoute(builder: (context) => const AddMemberScreen()),
    );

    // Null means the form was closed without saving.
    if (newMember == null) return;
    await loadMembers();
  }

  /// Groups the tasks by assignee and summarises each member's load.
  ///
  /// [now] is passed straight to the SLA rules so every row is judged at the
  /// same moment.
  Map<String, WorkloadSummary> _workloadFor(DateTime now) {
    final byMember = <String, List<Task>>{};
    for (final task in tasks) {
      byMember.putIfAbsent(task.assigneeId, () => <Task>[]).add(task);
    }

    return {
      for (final member in members)
        member.id: WorkloadSummary.of(
          byMember[member.id] ?? const <Task>[],
          now: now,
        ),
    };
  }

  @override
  Widget build(BuildContext context) {
    // Work out the load once, so the SLA status is consistent across rows.
    final workload = _workloadFor(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Team Members'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        // A unique tag, because the Tasks tab's button is in the same
        // screen tree and two buttons cannot share the default tag.
        heroTag: 'addTeamMember',
        onPressed: _openAddMember,
        icon: const Icon(Icons.person_add_outlined),
        label: const Text('Add member'),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : members.isEmpty
              ? const Center(
                  child: Text(
                    'No team members found',
                    style: TextStyle(fontSize: 16),
                  ),
                )
              : ListView.builder(
                  // Extra space at the bottom so the Add member button
                  // never covers the last card.
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.md,
                    88,
                  ),
                  itemCount: members.length,
                  itemBuilder: (context, index) {
                    final member = members[index];
                    final summary =
                        workload[member.id] ?? WorkloadSummary.empty;

                    return Card(
                      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text(member.initials),
                        ),
                        title: Text(
                          member.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(member.role),
                            const SizedBox(height: AppSpacing.xxs),
                            _WorkloadBreakdown(summary: summary),
                          ],
                        ),
                        trailing: _WorkloadBadge(count: summary.total),
                      ),
                    );
                  },
                ),
    );
  }
}

/// Small badge showing the total number of tasks a member is assigned.
class _WorkloadBadge extends StatelessWidget {
  final int count;

  const _WorkloadBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    final label = count == 1 ? '1 task' : '$count tasks';

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: AppColors.primaryTint,
        borderRadius: BorderRadius.circular(AppRadius.control),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppColors.primary,
            ),
      ),
    );
  }
}

/// Shows how much of a member's load needs attention.
///
/// Lists the At Risk and Overdue counts as coloured pills, with a plain
/// fallback when there is nothing to flag.
class _WorkloadBreakdown extends StatelessWidget {
  final WorkloadSummary summary;

  const _WorkloadBreakdown({required this.summary});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (summary.total == 0) {
      return Text('No tasks assigned', style: theme.textTheme.bodySmall);
    }
    if (summary.isClear) {
      return Text('All tasks on track', style: theme.textTheme.bodySmall);
    }

    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xxs,
      children: [
        if (summary.atRisk > 0)
          _SlaCountPill(status: SlaStatus.atRisk, count: summary.atRisk),
        if (summary.overdue > 0)
          _SlaCountPill(status: SlaStatus.overdue, count: summary.overdue),
      ],
    );
  }
}

/// A coloured pill such as "1 At Risk" or "2 Overdue".
///
/// Colours and wording come from the shared SLA status so a state looks the
/// same here as everywhere else in the app.
class _SlaCountPill extends StatelessWidget {
  final SlaStatus status;
  final int count;

  const _SlaCountPill({required this.status, required this.count});

  @override
  Widget build(BuildContext context) {
    final colors = SlaColors.of(status);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(AppRadius.control),
        border: Border.all(color: colors.text.withValues(alpha: 0.3)),
      ),
      child: Text(
        '$count ${status.label}',
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: colors.text,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
