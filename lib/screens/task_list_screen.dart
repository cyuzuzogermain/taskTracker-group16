import 'package:flutter/material.dart';

import '../models/sla_status.dart';
import '../models/task.dart';
import '../models/team_member.dart';
import '../services/sla_service.dart';

/// A screen that lists tasks with search, SLA filter chips, and urgency sorting.
///
/// Data is loaded from a private [_loadData] method until Naomi's storage
/// service is merged. Swap the body of that method when storage is ready.
class TaskListScreen extends StatefulWidget {
  /// Optional initial SLA filter. When provided, the list opens pre-filtered.
  final SlaStatus? initialFilter;

  /// The id of the current user. When non-null, the "My tasks" chip is shown.
  final String? currentUserId;

  /// Called when a task tile is tapped.
  final void Function(Task) onTaskTap;

  const TaskListScreen({
    super.key,
    this.initialFilter,
    this.currentUserId,
    this.onTaskTap = _defaultOnTaskTap,
  });

  static void _defaultOnTaskTap(Task task) {
    // Try to navigate to the Task Details route. If that route does not
    // exist yet, fall back to a SnackBar so the tap is not lost.
    // TODO: confirm the route name matches whatever navigation shell we use.
    // TODO: if the app uses go_router or named routes, replace this block.
    // <missing-route> Task Details named route not found; show SnackBar fallback.
  }

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  List<Task> _tasks = [];
  List<TeamMember> _members = [];
  String _query = '';
  SlaStatus? _filter;
  bool _myTasksOnly = false;

  @override
  void initState() {
    super.initState();
    // Load sample data once. Replace [_loadData] with the storage service
    // when it is merged — every screen that needs data should call it from
    // one place so the change is localised.
    final data = _loadData();
    setState(() {
      _tasks = data.tasks;
      _members = data.members;
      // Apply the initial filter the constructor may have supplied.
      _filter = widget.initialFilter;
    });
  }

  // ------------------------------------------------------------------
  // Data loading — the only place to change when storage is ready.
  // ------------------------------------------------------------------

  /// Temporary in-memory data. Swap the body for [StorageService] reads.
  ///
  /// Returns a small set of tasks that exercise all four SLA statuses and
  /// a handful of team members.
  _LoadDataResult _loadData() {
    // <missing-service> TEMPORARY, swap for StorageService.
    final now = DateTime(2024, 6, 10, 10, 0, 0);

    final members = [
      const TeamMember(id: 'm1', name: 'Alex Chen', role: 'Developer'),
      const TeamMember(id: 'm2', name: 'Naomi Kumar', role: 'Designer'),
      const TeamMember(id: 'm3', name: 'Sam Rivera', role: 'Product Owner'),
      const TeamMember(id: 'm4', name: 'Jordan Lee', role: 'QA'),
    ];

    // Task whose deadline has passed and is not done → Overdue.
    final overdueTask = Task(
      id: 't1',
      title: 'Fix login crash on Android',
      description: 'Reproduces on API 33',
      assigneeId: 'm1',
      dueDate: DateTime(2024, 6, 8), // 2 days ago
      status: TaskStatus.inProgress,
      createdAt: now.subtract(const Duration(days: 5)),
      updatedAt: now.subtract(const Duration(hours: 2)),
    );

    // Due today, not done → At Risk.
    final atRiskToday = Task(
      id: 't2',
      title: 'Review pull request #42',
      assigneeId: 'm2',
      dueDate: DateTime(2024, 6, 10), // today
      status: TaskStatus.todo,
      createdAt: now.subtract(const Duration(days: 2)),
      updatedAt: now,
    );

    // Due tomorrow, not done → At Risk (within 48h).
    final atRiskTomorrow = Task(
      id: 't3',
      title: 'Update onboarding screenshots',
      assigneeId: 'm2',
      dueDate: DateTime(2024, 6, 11), // tomorrow
      status: TaskStatus.todo,
      createdAt: now.subtract(const Duration(days: 1)),
      updatedAt: now,
    );

    // Due in 3 days, not done → On Track.
    final onTrack = Task(
      id: 't4',
      title: 'Write unit tests for SLA service',
      assigneeId: 'm1',
      dueDate: DateTime(2024, 6, 13), // in 3 days
      status: TaskStatus.todo,
      createdAt: now.subtract(const Duration(days: 1)),
      updatedAt: now,
    );

    // Done task → Completed (even though it is past due).
    final completed = Task(
      id: 't5',
      title: 'Set up CI pipeline',
      description: 'GitHub Actions',
      assigneeId: 'm3',
      dueDate: DateTime(2024, 6, 5), // past due, but done
      status: TaskStatus.done,
      createdAt: now.subtract(const Duration(days: 7)),
      updatedAt: now.subtract(const Duration(days: 3)),
    );

    // Another completed task.
    final completed2 = Task(
      id: 't6',
      title: 'Draft README for v1.0',
      assigneeId: 'm4',
      dueDate: DateTime(2024, 6, 9),
      status: TaskStatus.done,
      createdAt: now.subtract(const Duration(days: 4)),
      updatedAt: now.subtract(const Duration(days: 2)),
    );

    // On Track with a far-future deadline.
    final onTrackFar = Task(
      id: 't7',
      title: 'Research analytics SDK',
      assigneeId: 'm3',
      dueDate: DateTime(2024, 6, 20), // 10 days out
      status: TaskStatus.todo,
      createdAt: now.subtract(const Duration(days: 1)),
      updatedAt: now,
    );

    // Unassigned task, due today → At Risk.
    final unassigned = Task(
      id: 't8',
      title: 'Schedule stakeholder demo',
      assigneeId: '', // no assignee
      dueDate: DateTime(2024, 6, 10), // today
      status: TaskStatus.todo,
      createdAt: now.subtract(const Duration(days: 1)),
      updatedAt: now,
    );

    return _LoadDataResult(
      tasks: [
        overdueTask,
        atRiskToday,
        atRiskTomorrow,
        onTrack,
        completed,
        completed2,
        onTrackFar,
        unassigned,
      ],
      members: members,
    );
  }

  // ------------------------------------------------------------------
  // Filtering and sorting — kept together so the logic is easy to explain
  // on camera. Both run on every setState, which is fine for a small list.
  // ------------------------------------------------------------------

  /// Tasks after search, filter chips, and "My tasks" are applied.
  List<Task> get _filtered {
    var list = List<Task>.from(_tasks);

    // Search: match title or assignee name (empty query matches everything).
    if (_query.isNotEmpty) {
      final q = _query.toLowerCase();
      list = list.where((t) {
        final titleMatch = t.title.toLowerCase().contains(q);
        final assignee = _assigneeFor(t);
        final nameMatch =
            assignee?.name.toLowerCase().contains(q) ?? false;
        return titleMatch || nameMatch;
      }).toList();
    }

    // SLA filter chip.
    if (_filter != null) {
      list = list.where((t) => SlaService.computeSla(t) == _filter).toList();
    }

    // "My tasks" chip — only when a current user is set.
    if (_myTasksOnly && widget.currentUserId != null) {
      list =
          list.where((t) => t.assigneeId == widget.currentUserId).toList();
    }

    return list;
  }

  /// Tasks sorted by urgency: Overdue, At Risk, On Track, Completed.
  /// Inside each group, nearest deadline first.
  List<Task> get _sorted {
    final list = List<Task>.from(_filtered);
    list.sort(_urgencyCompare);
    return list;
  }

  /// Sort comparator using [SlaService.computeSla] and [SlaService.deadlineOf].
  ///
  /// Lower return value = appears first.
  /// Order: Overdue (0), At Risk (1), On Track (2), Completed (3).
  /// Within a group, earlier deadline first.
  int _urgencyCompare(Task a, Task b) {
    final slaA = SlaService.computeSla(a);
    final slaB = SlaService.computeSla(b);
    final orderA = _slaOrder(slaA);
    final orderB = _slaOrder(slaB);
    if (orderA != orderB) return orderA.compareTo(orderB);
    // Same SLA bucket → nearest deadline first.
    return SlaService.deadlineOf(a).compareTo(SlaService.deadlineOf(b));
  }

  /// Ordinal for urgency sort. Lower = more urgent.
  int _slaOrder(SlaStatus status) {
    switch (status) {
      case SlaStatus.overdue:
        return 0;
      case SlaStatus.atRisk:
        return 1;
      case SlaStatus.onTrack:
        return 2;
      case SlaStatus.completed:
        return 3;
    }
  }

  /// Assignee name lookup, or null when no assignee id is set.
  TeamMember? _assigneeFor(Task task) {
    if (task.assigneeId.isEmpty) return null;
    return _members.where((m) => m.id == task.assigneeId).firstOrNull;
  }

  // ------------------------------------------------------------------
  // UI
  // ------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sorted = _sorted;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Task List'),
        centerTitle: false,
      ),
      body: Column(
        children: [
          _buildSearchField(theme),
          _buildFilterChips(theme),
          const Divider(height: 1),
          Expanded(
            child: sorted.isEmpty
                ? _buildEmptyState(theme)
                : _buildTaskList(sorted, theme),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search by title or assignee',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: theme.colorScheme.surfaceContainerHighest,
        ),
        onChanged: (value) {
          setState(() => _query = value);
        },
      ),
    );
  }

  Widget _buildFilterChips(ThemeData theme) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _FilterChip(
            label: 'All',
            selected: _filter == null && !_myTasksOnly,
            onSelected: (_) {
              setState(() {
                _filter = null;
                _myTasksOnly = false;
              });
            },
            theme: theme,
          ),
          const SizedBox(width: 8),
          // SLA chips use the labels from SlaStatus.xxx.label.
          for (final status in [
            SlaStatus.onTrack,
            SlaStatus.atRisk,
            SlaStatus.overdue,
            SlaStatus.completed,
          ])                  _FilterChip(
                    label: status.label,
                    selected: _filter == status,
                    onSelected: (_) {
                      setState(() {
                        _filter = status;
                        _myTasksOnly = false;
                      });
                    },
                    theme: theme,
                  ),
          if (widget.currentUserId != null) ...[
            const SizedBox(width: 8),
            _FilterChip(
              label: 'My tasks',
              selected: _myTasksOnly,
              onSelected: (_) {
                setState(() {
                  _myTasksOnly = !_myTasksOnly;
                  // When "My tasks" is turned on, drop the SLA filter so
                  // the user sees all their tasks across statuses.
                  if (_myTasksOnly) _filter = null;
                });
              },
              theme: theme,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTaskList(List<Task> tasks, ThemeData theme) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: tasks.length,
      separatorBuilder: (a,b) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final task = tasks[index];
        final sla = SlaService.computeSla(task);
        final assignee = _assigneeFor(task);
        return _TaskCard(
          task: task,
          sla: sla,
          assigneeName: assignee?.name ?? 'Unassigned',
          deadlineLine: SlaService.deadlineLine(task),
          theme: theme,
          onTap: () => widget.onTaskTap(task),
        );
      },
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          'No tasks match your search',
          style: theme.textTheme.titleLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------
// Private widgets
// ------------------------------------------------------------------

/// Data container for [_loadData]. A simple class keeps the return type
/// clear without relying on tuple destructuring.
class _LoadDataResult {
  final List<Task> tasks;
  final List<TeamMember> members;
  const _LoadDataResult({required this.tasks, required this.members});
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final void Function(bool) onSelected;
  final ThemeData theme;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
      selectedColor: theme.colorScheme.primaryContainer,
      checkmarkColor: theme.colorScheme.onPrimaryContainer,
      labelStyle: TextStyle(
        color: selected
            ? theme.colorScheme.onPrimaryContainer
            : theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final Task task;
  final SlaStatus sla;
  final String assigneeName;
  final String deadlineLine;
  final ThemeData theme;
  final VoidCallback onTap;

  const _TaskCard({
    required this.task,
    required this.sla,
    required this.assigneeName,
    required this.deadlineLine,
    required this.theme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Prefer the shared task card widget if the team adds one later.
    // TODO: replace with shared widget when lib/widgets/task_card.dart exists.
    // <missing-widget> Shared task card widget not found; using inline Card.

    // SLA colour from theme. The shared theme/sla_colors do not exist yet,
    // so derive from the colour scheme instead of hardcoding.
    // TODO: replace with shared sla_colors from theme when available.
    // <missing-theme> Shared SLA colours not found; using colorScheme.
    final slaColor = _slaColorFromTheme(sla, theme);

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            // 4px left edge in the SLA colour.
            border: Border(
              left: BorderSide(color: slaColor, width: 4),
            ),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                task.title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.person_outline,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      assigneeName,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    deadlineLine,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // SLA chip using the shared label.
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: slaColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: slaColor.withValues(alpha: 0.4)),
                ),
                child: Text(
                  sla.label,
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

  /// Derive an SLA colour from the theme's colorScheme so nothing is
  /// hardcoded. Once the shared theme is in place, point this at
  /// theme.slaColors[s la] instead.
  Color _slaColorFromTheme(SlaStatus sla, ThemeData theme) {
    switch (sla) {
      case SlaStatus.completed:
        return theme.colorScheme.primary;
      case SlaStatus.onTrack:
        return Colors.green;
      case SlaStatus.atRisk:
        return Colors.orange;
      case SlaStatus.overdue:
        return Colors.red;
    }
  }
}
