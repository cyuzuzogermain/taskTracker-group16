import 'package:flutter/material.dart';
import 'package:task_tracker_app/models/task.dart';
import 'package:task_tracker_app/models/team_member.dart';
import 'package:task_tracker_app/services/storage_service.dart';
import 'package:task_tracker_app/theme/app_theme.dart';

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

  /// How many stored tasks are assigned to [member].
  int _taskCountFor(TeamMember member) {
    return tasks.where((task) => task.assigneeId == member.id).length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Team Members'),
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
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: members.length,
                  itemBuilder: (context, index) {
                    final member = members[index];

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
                        subtitle: Text(member.role),
                        trailing: _WorkloadBadge(count: _taskCountFor(member)),
                      ),
                    );
                  },
                ),
    );
  }
}

/// Small badge showing how many tasks a team member is assigned.
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
