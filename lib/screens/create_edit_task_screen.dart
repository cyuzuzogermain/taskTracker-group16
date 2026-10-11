import 'package:flutter/material.dart';

import '../models/task.dart';
import '../models/team_member.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../utils/date_format.dart';

/// One form used both to create a new task and to edit an existing one.
///
/// Pass a [task] to edit it; leave it out to create a new one. When the
/// task is saved the screen closes and returns the saved task.
class CreateEditTaskScreen extends StatefulWidget {
  const CreateEditTaskScreen({super.key, this.task});

  /// The task being edited, or null when creating a new task.
  final Task? task;

  @override
  State<CreateEditTaskScreen> createState() => _CreateEditTaskScreenState();
}

class _CreateEditTaskScreenState extends State<CreateEditTaskScreen> {
  /// Lets the Save button run every field's validator at once.
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  /// Shows the chosen due date as text inside the read-only date field.
  final TextEditingController _dueDateController = TextEditingController();

  List<TeamMember> _members = [];
  bool _isLoadingMembers = true;

  String? _assigneeId;
  DateTime? _dueDate;
  TaskPriority _priority = TaskPriority.medium;
  TaskStatus _status = TaskStatus.todo;

  /// True while the task is being written to storage.
  bool _isSaving = false;

  /// Turned on afterr the first failed save, so errors update as the user
  /// fixes each field.
  bool _validateAsYouType = false;

  bool get _isEditing => widget.task != null;

  @override
  void initState() {
    super.initState();
    _fillFromExistingTask();
    _loadMembers();
  }

  @override
  void dispose() {
    // Controllers hold resources, so release them when the screen closes.
    _titleController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    _dueDateController.dispose();
    super.dispose();
  }

  /// When editing, starts every field with the task's current values.
  void _fillFromExistingTask() {
    final task = widget.task;
    if (task == null) return;

    _titleController.text = task.title;
    _descriptionController.text = task.description;
    _notesController.text = task.notes;
    _dueDate = dateOnly(task.dueDate);
    _dueDateController.text = formatDate(task.dueDate);
    _priority = task.priority;
    _status = task.status;
  }

  /// Reads the team members for the assignee dropdown.
  Future<void> _loadMembers() async {
    final members = await StorageService().loadTeamMembers();

    if (!mounted) return;
    setState(() {
      _members = members;
      _isLoadingMembers = false;

      // Only pre-select the assignee if that member still exists.
      final currentAssigneeId = widget.task?.assigneeId;
      final stillExists = members.any((m) => m.id == currentAssigneeId);
      _assigneeId = stillExists ? currentAssigneeId : null;
    });
  }

  // ------------------------------------------------------------------
  // Validation rules. Each returns an error message, or null if valid.
  // ------------------------------------------------------------------

  String? _validateTitle(String? value) {
    final title = (value ?? '').trim();
    if (title.isEmpty) {
      return 'Enter a title';
    }
    if (title.length < Task.titleMinLength) {
      return 'Title must be at least ${Task.titleMinLength} characters';
    }
    if (title.length > Task.titleMaxLength) {
      return 'Title must be ${Task.titleMaxLength} characters or fewer';
    }
    return null;
  }

  String? _validateDescription(String? value) {
    final description = (value ?? '').trim();
    if (description.length > Task.descriptionMaxLength) {
      return 'Description must be ${Task.descriptionMaxLength} characters '
          'or fewer';
    }
    return null;
  }

  String? _validateAssignee(String? value) {
    if (value == null) {
      return 'Choose who this task is assigned to';
    }
    return null;
  }

  String? _validateDueDate(String? value) {
    final dueDate = _dueDate;
    if (dueDate == null) {
      return 'Choose a due date';
    }
    // A new task cannot start out already late. An existing task keeps
    // its date even if that date has passed.
    final today = dateOnly(DateTime.now());
    if (!_isEditing && dueDate.isBefore(today)) {
      return 'Due date cannot be in the past';
    }
    return null;
  }

  // ------------------------------------------------------------------
  // Actions
  // ------------------------------------------------------------------

  /// Opens the calendar and stores the day the user picks.
  Future<void> _pickDueDate() async {
    final today = dateOnly(DateTime.now());
    final current = _dueDate;

    // New tasks cannot be dated in the past. When editing, the calendar
    // must still be able to show the task's existing date.
    DateTime firstDate = today;
    if (current != null && current.isBefore(today)) {
      firstDate = current;
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? today,
      firstDate: firstDate,
      lastDate: DateTime(today.year + 5),
      helpText: 'Select due date',
    );

    // Null means the user closed the calendar without choosing.
    if (picked == null) return;

    setState(() {
      _dueDate = dateOnly(picked);
      _dueDateController.text = formatDate(picked);
    });
  }

  /// Validates the form, saves the task to storage and closes the screen.
  Future<void> _save() async {
    final isValid = _formKey.currentState!.validate();
    if (!isValid) {
      setState(() {
        _validateAsYouType = true;
      });
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final Task savedTask;
    final existing = widget.task;
    if (existing == null) {
      savedTask = Task.create(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        assigneeId: _assigneeId!,
        dueDate: _dueDate!,
        priority: _priority,
        status: _status,
        notes: _notesController.text.trim(),
      );
    } else {
      // copyWith keeps the id and createdAt and refreshes updatedAt.
      savedTask = existing.copyWith(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        assigneeId: _assigneeId!,
        dueDate: _dueDate!,
        priority: _priority,
        status: _status,
        notes: _notesController.text.trim(),
      );
    }

    try {
      // Read the latest list, add or replace this task, then write it back.
      final storage = StorageService();
      final tasks = await storage.loadTasks();
      final index = tasks.indexWhere((task) => task.id == savedTask.id);
      if (index >= 0) {
        tasks[index] = savedTask;
      } else {
        tasks.add(savedTask);
      }
      await storage.saveTasks(tasks);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not save the task. Please try again.'),
        ),
      );
      return;
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_isEditing ? 'Task updated' : 'Task created')),
    );
    // Hand the saved task back to the screen that opened this form.
    Navigator.pop(context, savedTask);
  }

  // ------------------------------------------------------------------
  // UI
  // ------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit Task' : 'New Task')),
      body: SafeArea(child: _buildBody(context)),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoadingMembers) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_members.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.xl),
          child: Text(
            'There are no team members to assign a task to yet.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Form(
      key: _formKey,
      autovalidateMode: _validateAsYouType
          ? AutovalidateMode.onUserInteraction
          : AutovalidateMode.disabled,
      // A Column inside SingleChildScrollView keeps every field built, so
      // the form can validate fields that are scrolled off screen.
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title'),
              maxLength: Task.titleMaxLength,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.next,
              validator: _validateTitle,
            ),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                alignLabelWithHint: true,
              ),
              maxLength: Task.descriptionMaxLength,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              validator: _validateDescription,
            ),
            const SizedBox(height: AppSpacing.sm),
            DropdownButtonFormField<String>(
              initialValue: _assigneeId,
              decoration: const InputDecoration(labelText: 'Assignee'),
              // isExpanded stops a long name from overflowing the field.
              isExpanded: true,
              items: [
                for (final member in _members)
                  DropdownMenuItem(
                    value: member.id,
                    child: Text(
                      '${member.name} (${member.role})',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: (value) {
                setState(() {
                  _assigneeId = value;
                });
              },
              validator: _validateAssignee,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _dueDateController,
              // Read-only: the date can only be set through the calendar.
              readOnly: true,
              decoration: const InputDecoration(
                labelText: 'Due date',
                suffixIcon: Icon(Icons.calendar_today_outlined, size: 20),
              ),
              onTap: _pickDueDate,
              validator: _validateDueDate,
            ),
            const SizedBox(height: AppSpacing.md),
            Text('Priority', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: AppSpacing.xs),
            SegmentedButton<TaskPriority>(
              showSelectedIcon: false,
              segments: [
                for (final priority in TaskPriority.values)
                  ButtonSegment(value: priority, label: Text(priority.label)),
              ],
              selected: {_priority},
              onSelectionChanged: (selection) {
                setState(() {
                  _priority = selection.first;
                });
              },
            ),
            const SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<TaskStatus>(
              initialValue: _status,
              decoration: const InputDecoration(labelText: 'Status'),
              items: [
                for (final status in TaskStatus.values)
                  DropdownMenuItem(value: status, child: Text(status.label)),
              ],
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  _status = value;
                });
              },
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                alignLabelWithHint: true,
              ),
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              // Disabled while saving so the task cannot be saved twice.
              onPressed: _isSaving ? null : _save,
              child: Text(_isEditing ? 'Save changes' : 'Create task'),
            ),
          ],
        ),
      ),
    );
  }
}
