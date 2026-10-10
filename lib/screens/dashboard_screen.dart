import 'package:flutter/material.dart';

import '../models/task.dart';
import '../models/team_member.dart';
import '../models/sla_status.dart';
import '../services/storage_service.dart';
import '../services/sla_service.dart';
import '../theme/sla_colors.dart';

/// Callback invoked when an SLA summary card is tapped.
/// The Task List screen will use this to filter tasks by SLA status.
typedef OnSlaCardTap = void Function(String status);

/// Callback invoked when a task in the recent list is tapped.
typedef OnTaskTap = void Function(Task task);

/// Dashboard screen showing project overview, SLA summary, and recent tasks.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    super.key,
    this.onSlaCardTap = _defaultSlaCardTap,
    this.onTaskTap = _defaultTaskTap,
  });

  /// Called when an SLA card is tapped. Receives the SLA status label.
  final OnSlaCardTap onSlaCardTap;

  /// Called when a task tile is tapped.
  final OnTaskTap onTaskTap;

  static void _defaultSlaCardTap(String status) {
    // Placeholder: show a SnackBar. The real screen will navigate/filter.
    debugPrint('SLA card tapped: $status');
  }

  static void _defaultTaskTap(Task task) {
    debugPrint('Task tapped: ${task.title}');
  }

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  /// The list of tasks currently shown on the dashboard.
  List<Task> _tasks = [];
  List<TeamMember> _members = [];

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    final storage = StorageService();
    final tasks = await storage.loadTasks();
    final members = await storage.loadTeamMembers();
    if (!mounted) return;
    setState(() {
      _tasks = tasks;
      _members = members;
    });
  }

  // ------------------------------------------------------------------
  // Computed values – kept in small, separate methods for clarity.
  // These read from _tasks, so they recompute whenever the list changes.
  // ------------------------------------------------------------------

  /// Total number of tasks.
  int get _totalTasks => _tasks.length;

  /// Number of tasks whose status is "Done".
  int _countCompleted() {
    return _tasks.where((t) => t.status == TaskStatus.done).length;
  }

  /// Percentage of tasks that are completed (0–100).
  double _completionPercent() {
    if (_totalTasks == 0) return 0.0;
    return (_countCompleted() / _totalTasks) * 100;
  }

  /// Count of tasks in a given SLA status.
  int _countByStatus(SlaStatus status) {
    return _tasks.where((t) => SlaService.computeSla(t) == status).length;
  }

  /// The 5 most recently created tasks, newest first.
  List<Task> get _recentTasks {
    final sorted = List<Task>.from(_tasks)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted.take(5).toList();
  }

  /// Assignee name lookup, or "Unassigned" when no assignee id is set.
  String _assigneeNameFor(Task task) {
    if (task.assigneeId.isEmpty) return 'Unassigned';
    final member = _members.where((m) => m.id == task.assigneeId).firstOrNull;
    return member?.name ?? 'Unassigned';
  }

  /// Icon for an SLA status card.
  IconData _slaIcon(SlaStatus status) {
    switch (status) {
      case SlaStatus.onTrack:
        return Icons.trending_up;
      case SlaStatus.atRisk:
        return Icons.warning_amber;
      case SlaStatus.overdue:
        return Icons.error_outline;
      case SlaStatus.completed:
        return Icons.check_circle_outline;
    }
  }

  // ------------------------------------------------------------------
  // UI building methods – each responsible for one section.
  // ------------------------------------------------------------------

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hello, Alex', // TODO: replace with the shared user model
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Project & SLA Task Tracker', // TODO: replace with shared project model
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection() {
    final percent = _completionPercent();
    final completed = _countCompleted();
    final total = _totalTasks;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Overall Progress',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  '$completed / $total tasks',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Linear progress indicator – fills from 0.0 to 1.0.
            LinearProgressIndicator(
              value: percent / 100,
              backgroundColor:
                  Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            const SizedBox(height: 8),
            Text(
              '${percent.toStringAsFixed(1)}% complete',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  /// 2x2 grid of SLA summary cards.
  Widget _buildSlaGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SLA Summary',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.4,
            children: [
            // For each SLA status, build a tappable card with
            // count, icon and colour.
            for (final status in SlaStatus.values)
              _SlaCard(
                label: status.label,
                count: _countByStatus(status),
                color: SlaColors.of(status).text,
                icon: _slaIcon(status),
                onTap: () {
                  // Notify the parent via the callback.
                  widget.onSlaCardTap(status.label);
                  // Also show a SnackBar so the user sees something.
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Tapped: $status.label'),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
              ),
          ]),
        ],
      ),
    );
  }

  Widget _buildRecentTasksSection() {
    final recent = _recentTasks;

    if (recent.isEmpty) {
      return _buildEmptyState();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Tasks',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  ),
          ),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: recent.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final task = recent[index];
              final sla = SlaService.computeSla(task);
              return _TaskTile(
                task: task,
                slaColor: SlaColors.of(sla).text,
                assigneeName: _assigneeNameFor(task),
                onTap: () {
                  widget.onTaskTap(task);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Tapped: ${task.title}'),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No tasks yet',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the + button to create your first task.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // SingleChildScrollView makes the whole page scroll-safe on small
    // phones so nothing overflows the viewport.
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildProgressSection(),
            const SizedBox(height: 8),
            _buildSlaGrid(),
            const SizedBox(height: 8),
            _buildRecentTasksSection(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------
// Small private widgets for readability.
// ------------------------------------------------------------------

/// A single SLA summary card in the 2x2 grid.
class _SlaCard extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  const _SlaCard({
    required this.label,
    required this.count,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(
                '$count',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A single task tile in the recent tasks list.
class _TaskTile extends StatelessWidget {
  final Task task;
  final Color slaColor;
  final String assigneeName;
  final VoidCallback onTap;

  const _TaskTile({
    required this.task,
    required this.slaColor,
    required this.assigneeName,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Assignee: $assigneeName',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    Text(
                      'Due: ${_formatDate(task.dueDate)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Coloured SLA status chip.
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: slaColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: slaColor.withValues(alpha: 0.4)),
                ),
                child: Text(
                  _slaStatusLabelForTask(),
                  style: TextStyle(
                    color: slaColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _slaStatusLabelForTask() {
    final sla = SlaService.computeSla(task);
    switch (sla) {
      case SlaStatus.onTrack:
        return 'On Track';
      case SlaStatus.atRisk:
        return 'At Risk';
      case SlaStatus.overdue:
        return 'Overdue';
      case SlaStatus.completed:
        return 'Completed';
    }
  }

  /// Short, readable date like "Oct 12, 2026".
  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
