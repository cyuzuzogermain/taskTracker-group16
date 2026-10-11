import 'package:flutter/material.dart';

import '../models/sla_status.dart';
import '../models/task.dart';
import '../models/team_member.dart';
import '../services/storage_service.dart';
import '../services/sla_service.dart';
import '../theme/sla_colors.dart';

/// A screen that lists tasks with search, SLA filter chips, and urgency sorting.
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
      // Apply the initial filter the constructor may have supplied.
      _filter = widget.initialFilter;
    });
  }

  List<Task> get _filtered {
    var list = List<Task>.from(_tasks);

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

    if (_filter != null) {
      list = list.where((t) => SlaService.computeSla(t) == _filter).toList();
    }

    if (_myTasksOnly && widget.currentUserId != null) {
      list =
          list.where((t) => t.assigneeId == widget.currentUserId).toList();
    }

    return list;
  }

  List<Task> get _sorted {
    final list = List<Task>.from(_filtered);
    list.sort(_urgencyCompare);
    return list;
  }

  int _urgencyCompare(Task a, Task b) {
    final slaA = SlaService.computeSla(a);
    final slaB = SlaService.computeSla(b);
    final orderA = _slaOrder(slaA);
    final orderB = _slaOrder(slaB);
    if (orderA != orderB) return orderA.compareTo(orderB);
    return SlaService.deadlineOf(a).compareTo(SlaService.deadlineOf(b));
  }

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
    final colors = SlaColors.of(sla);

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border(
              left: BorderSide(color: colors.text, width: 4),
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
                  color: colors.background,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colors.text),
                ),
                child: Text(
                  sla.label,
                  style: TextStyle(
                    color: colors.text,
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

}
