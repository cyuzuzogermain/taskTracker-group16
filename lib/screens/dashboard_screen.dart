import 'package:flutter/material.dart';

import 'dashboard_dummy_data.dart';

/// Callback invoked when an SLA summary card is tapped.
/// The Task List screen will use this to filter tasks by SLA status.
typedef OnSlaCardTap = void Function(String status);

/// Callback invoked when a task in the recent list is tapped.
typedef OnTaskTap = void Function(Task task);

/// Callback invoked when the "New Task" FAB is pressed.
typedef OnCreateTask = void Function();

/// Dashboard screen showing project overview, SLA summary, and recent tasks.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    super.key,
    this.onSlaCardTap = _defaultSlaCardTap,
    this.onTaskTap = _defaultTaskTap,
    this.onCreateTask = _defaultCreateTask,
  });

  /// Called when an SLA card is tapped. Receives the SLA status label.
  final OnSlaCardTap onSlaCardTap;

  /// Called when a task tile is tapped.
  final OnTaskTap onTaskTap;

  /// Called when the "New Task" FAB is pressed.
  final OnCreateTask onCreateTask;

  static void _defaultSlaCardTap(String status) {
    // Placeholder: show a SnackBar. The real screen will navigate/filter.
    debugPrint('SLA card tapped: $status');
  }

  static void _defaultTaskTap(Task task) {
    debugPrint('Task tapped: ${task.title}');
  }

  static void _defaultCreateTask() {
    debugPrint('New Task FAB pressed');
  }

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  /// The list of tasks currently shown on the dashboard.
  /// We start with dummy data; replace with the storage service when merged.
  List<Task> _tasks = [];

  @override
  void initState() {
    super.initState();
    // Seed with dummy tasks so the UI has something to display.
    _tasks = createDummyTasks();
  }

  // ------------------------------------------------------------------
  // Computed values – kept in small, separate methods for clarity.
  // These read from _tasks, so they recompute whenever the list changes.
  // ------------------------------------------------------------------

  /// Total number of tasks.
  int get _totalTasks => _tasks.length;

  /// Number of tasks whose status is "Done".
  int _countCompleted() {
    return _tasks.where((t) => t.status == 'Done').length;
  }

  /// Percentage of tasks that are completed (0–100).
  double _completionPercent() {
    if (_totalTasks == 0) return 0.0;
    return (_countCompleted() / _totalTasks) * 100;
  }

  /// Count of tasks in a given SLA status.
  int _countByStatus(SlaStatus status) {
    return _tasks.where((t) => computeSla(t) == status).length;
  }

  /// The 5 most recently created tasks, newest first.
  List<Task> get _recentTasks {
    final sorted = List<Task>.from(_tasks)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted.take(5).toList();
  }

  /// Human-readable label for an SLA status.
  String _slaLabel(SlaStatus status) {
    switch (status) {
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

  /// Material colour for an SLA status.
  /// Kept in one place so the team can align with the shared theme later.
  Color _slaColor(SlaStatus status) {
    switch (status) {
      case SlaStatus.onTrack:
        return Colors.green;
      case SlaStatus.atRisk:
        return Colors.orange;
      case SlaStatus.overdue:
        return Colors.red;
      case SlaStatus.completed:
        return Colors.blue;
    }
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

  /// Update the task list and trigger a rebuild.
  /// setState() tells Flutter that the widget's state has changed so it
  /// re-renders the UI. We use it here so the computed counts and lists
  /// stay in sync with the underlying data.
  ///
  /// Note: This method is kept for future use when we add task creation/
  /// deletion. For now it's unused but demonstrates the setState pattern.

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
                label: _slaLabel(status),
                count: _countByStatus(status),
                color: _slaColor(status),
                icon: _slaIcon(status),
                onTap: () {
                  // Notify the parent via the callback.
                  widget.onSlaCardTap(_slaLabel(status));
                  // Also show a SnackBar so the user sees something.
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Tapped: ${_slaLabel(status)}'),
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
              final sla = computeSla(task);
              return _TaskTile(
                task: task,
                slaColor: _slaColor(sla),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          widget.onCreateTask();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('New Task – placeholder. Navigate to create screen.'),
              duration: Duration(seconds: 2),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('New Task'),
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
  final VoidCallback onTap;

  const _TaskTile({
    required this.task,
    required this.slaColor,
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
                      'Assignee: ${task.assignee}',
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
    // Reuse the helper from the state class.
    final sla = computeSla(task);
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
