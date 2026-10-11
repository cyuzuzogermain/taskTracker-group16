import 'package:flutter/material.dart';

import '../models/sla_status.dart';
import '../models/task.dart';
import '../models/team_member.dart';
import '../services/sla_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/member_avatar.dart';

/// Shows who is signed in, a summary of their own tasks, and a way to
/// sign out.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    required this.currentUser,
    required this.onSignOut,
  });

  /// The team member who is signed in.
  final TeamMember currentUser;

  /// Called after the user confirms they want to sign out.
  final VoidCallback onSignOut;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  /// The tasks assigned to the signed-in member.
  List<Task> _myTasks = [];

  bool _isLoading = true;
  bool _loadFailed = false;

  @override
  void initState() {
    super.initState();
    _loadMyTasks();
  }

  /// Reads all tasks from storage and keeps the ones assigned to this user.
  Future<void> _loadMyTasks() async {
    setState(() {
      _isLoading = true;
      _loadFailed = false;
    });

    try {
      final allTasks = await StorageService().loadTasks();
      final myTasks = allTasks
          .where((task) => task.assigneeId == widget.currentUser.id)
          .toList();

      if (!mounted) return;
      setState(() {
        _myTasks = myTasks;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadFailed = true;
      });
    }
  }

  /// How many of this user's tasks are in the given SLA state.
  int _countWithSla(SlaStatus status) {
    return _myTasks
        .where((task) => SlaService.computeSla(task) == status)
        .length;
  }

  /// Asks the user to confirm, then signs out.
  Future<void> _confirmSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text(
          'You will need to choose a team member again to use the app.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );

    // The dialog returns null if it is dismissed by tapping outside it.
    if (confirmed == true) {
      widget.onSignOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      // SingleChildScrollView keeps the screen usable on short phones.
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildUserCard(context),
            const SizedBox(height: AppSpacing.lg),
            Text('My tasks', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            _buildTaskSummary(context),
            const SizedBox(height: AppSpacing.xl),
            OutlinedButton.icon(
              onPressed: _confirmSignOut,
              icon: const Icon(Icons.logout_outlined, size: 20),
              label: const Text('Sign out'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserCard(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final user = widget.currentUser;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            MemberAvatar(member: user, size: 64),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: textTheme.headlineSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    user.role,
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Shows a spinner, an error, or the three summary numbers.
  Widget _buildTaskSummary(BuildContext context) {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_loadFailed) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              const Icon(Icons.error_outline, color: AppColors.error),
              const SizedBox(width: AppSpacing.sm),
              const Expanded(child: Text('Could not load your tasks.')),
              TextButton(onPressed: _loadMyTasks, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    final needAttention =
        _countWithSla(SlaStatus.overdue) + _countWithSla(SlaStatus.atRisk);

    // Each tile is wrapped in Expanded so the three share the row equally.
    return Row(
      children: [
        Expanded(
          child: _SummaryTile(label: 'Assigned', value: _myTasks.length),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _SummaryTile(
            label: 'Completed',
            value: _countWithSla(SlaStatus.completed),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _SummaryTile(label: 'Need attention', value: needAttention),
        ),
      ],
    );
  }
}

/// A small card with a number and a label under it.
class _SummaryTile extends StatelessWidget {
  const _SummaryTile({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: AppSpacing.md,
        ),
        child: Column(
          children: [
            Text('$value', style: textTheme.displaySmall),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              label,
              style: textTheme.bodySmall,
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }
}
