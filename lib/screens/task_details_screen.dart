import 'package:flutter/material.dart';

import '../models/sla_status.dart';
import '../models/task.dart';
import '../models/team_member.dart';
import '../services/sla_service.dart';
import '../theme/app_theme.dart';
import '../theme/sla_colors.dart';

/// Shorthand for the app's spacing constants.

/// Shortcuts to the app's spacing and radius so the screen stays readable.
/// These come from the top-level classes in app_theme.dart.
class _Spacing {
  static double get md => AppSpacing.md;
}

class _Radius {
  static double get control => AppRadius.control;
}

/// Details screen for a single task.
///
/// Holds the task in local state so the SLA card refreshes immediately when
/// the status changes. Data is owned by the caller; this screen does not
/// touch storage.
class TaskDetailsScreen extends StatefulWidget {
  final Task task;
  final List<TeamMember> members;
  final Future<void> Function(Task) onSave;
  final Future<void> Function(String id) onDelete;
  final void Function(Task) onEdit;

  const TaskDetailsScreen({
    super.key,
    required this.task,
    required this.members,
    required this.onSave,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  State<TaskDetailsScreen> createState() => _TaskDetailsScreenState();
}

class _TaskDetailsScreenState extends State<TaskDetailsScreen> {
  late Task _task;

  @override
  void initState() {
    super.initState();
    _task = widget.task;
  }

  TeamMember? _assigneeFor(Task task) {
    if (task.assigneeId.isEmpty) return null;
    try {
      return widget.members.firstWhere((m) => m.id == task.assigneeId);
    } catch (_) {
      return null;
    }
  }

  SlaStatus _slaFor(Task task) => SlaService.computeSla(task);

  SlaColors _slaColorsFor(Task task) => SlaColors.of(_slaFor(task));

  Future<void> _onStatusChanged(TaskStatus value) async {
    final previous = _task;
    final updated = _task.copyWith(
      status: value,
      updatedAt: DateTime.now(),
    );
    setState(() => _task = updated);
    try {
      await widget.onSave(updated);
    } catch (e) {
      if (mounted) {
        setState(() => _task = previous);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Could not save status change: ${e.toString()}',
            ),
          ),
        );
      }
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this task?'),
        content: Text('“${_task.title}” will be permanently removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await widget.onDelete(_task.id);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not delete task: ${e.toString()}'),
          ),
        );
      }
    }
  }

  /// Small chip showing the SLA status.
  ///
  /// TODO: replace with shared widget when lib/widgets/sla_chip.dart exists.
  /// TODO: missing-widget: Shared SLA chip widget not found; using inline chip.
  Widget _buildSlAChip(Task task, ThemeData theme) {
    final sla = _slaFor(task);
    final colors = _slaColorsFor(task);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(_Radius.control),
        border: Border.all(color: colors.text.withValues(alpha: 0.3)),
      ),
      child: Text(
        sla.label,
        style: theme.textTheme.labelMedium!.copyWith(
              color: colors.text,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.light();
    final assignee = _assigneeFor(_task);
    final colors = _slaColorsFor(_task);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(_task.title),
        actions: [
          TextButton.icon(
            onPressed: () => widget.onEdit(_task),
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Edit'),
          ),
          const SizedBox(width: AppSpacing.sm),
          FilledButton.tonalIcon(
            onPressed: _delete,
            icon: const Icon(Icons.delete_outline),
            label: const Text('Delete'),
          ),
          const SizedBox(width: AppSpacing.md),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // SLA card at the top so the user sees status immediately.
            _buildSlACard(_task, theme, colors),
            const SizedBox(height: AppSpacing.md),

            // Core fields.
            _buildSection(
              theme,
              'Details',
              [
                _buildField(
                  theme,
                  'Title',
                  Text(_task.title),
                ),
                _buildAssigneeField(theme, assignee),
                _buildDueDateField(theme),
                _buildPriorityField(theme),
                _buildStatusField(theme),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // Notes.
            _buildNotesSection(theme),
            const SizedBox(height: AppSpacing.md),

            // Timestamps.
            _buildSection(
              theme,
              'Timeline',
              [
                _buildField(
                  theme,
                  'Created',
                  Text(_formatDateTime(_task.createdAt)),
                ),
                _buildField(
                  theme,
                  'Updated',
                  Text(_formatDateTime(_task.updatedAt)),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }

  Widget _buildSlACard(Task task, ThemeData theme, SlaColors colors) {
    final deadline = SlaService.deadlineOf(task);
    final line = SlaService.deadlineLine(task);
    final reason = SlaService.slaReason(task);

    return Card(
      child: Padding(
        padding: EdgeInsets.all(_Spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildSlAChip(task, theme),
                const Spacer(),
                Text(
                  line,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Deadline',
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              _formatDateTime(deadline),
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: colors.background,
                borderRadius: BorderRadius.circular(AppRadius.control),
                border: Border.all(color: colors.text.withValues(alpha: 0.2)),
              ),
              child: Text(
                reason,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.text,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(ThemeData theme, String heading, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          heading,
          style: theme.textTheme.titleMedium?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        ...children,
      ],
    );
  }

  Widget _buildField(ThemeData theme, String label, Widget child) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          child,
        ],
      ),
    );
  }

  Widget _buildAssigneeField(ThemeData theme, TeamMember? assignee) {
    return _buildField(
      theme,
      'Assignee',
      Text(
        assignee?.name ?? 'Unassigned',
        style: theme.textTheme.bodyLarge,
      ),
    );
  }

  Widget _buildDueDateField(ThemeData theme) {
    return _buildField(
      theme,
      'Due date',
      Text(
        _formatDate(_task.dueDate),
        style: theme.textTheme.bodyLarge,
      ),
    );
  }

  Widget _buildPriorityField(ThemeData theme) {
    return _buildField(
      theme,
      'Priority',
      Text(
        _task.priority.label,
        style: theme.textTheme.bodyLarge,
      ),
    );
  }

  Widget _buildStatusField(ThemeData theme) {
    return _buildField(
      theme,
      'Status',
      Theme(
        data: theme.copyWith(
          unselectedWidgetColor: AppColors.textSecondary,
        ),
        child: DropdownButton<TaskStatus>(
          value: _task.status,
          isExpanded: true,
          underline: const SizedBox(),
          items: TaskStatus.values.map((status) {
            return DropdownMenuItem(
              value: status,
              child: Text(status.label),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) _onStatusChanged(value);
          },
        ),
      ),
    );
  }

  Widget _buildNotesSection(ThemeData theme) {
    final text =
        _task.notes.isEmpty ? 'No notes' : _task.notes;
    return _buildField(
      theme,
      'Notes',
      Text(
        text,
        style: theme.textTheme.bodyMedium,
        maxLines: null,
        softWrap: true,
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatDateTime(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '${months[date.month - 1]} ${date.day}, ${date.year}, $hour:$minute';
  }
}
