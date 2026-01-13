import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:take_home_assignment/core/presentation/widgets/shimmer_widget.dart';
import 'package:take_home_assignment/core/presentation/widgets/error_retry_widget.dart';
import 'package:take_home_assignment/core/sync_providers.dart';
import 'package:take_home_assignment/features/task/domain/task_entity.dart';
import 'package:take_home_assignment/features/task/presentation/task_providers.dart';
import 'package:take_home_assignment/features/task/presentation/widgets/task_column.dart';
import 'package:take_home_assignment/core/sync_service.dart';
import 'package:take_home_assignment/features/task/presentation/task_comments_sheet.dart';
import 'package:uuid/uuid.dart';

class TaskBoardScreen extends ConsumerStatefulWidget {
  final String boardId;
  final String boardTitle;

  const TaskBoardScreen({
    super.key,
    required this.boardId,
    required this.boardTitle,
  });

  @override
  ConsumerState<TaskBoardScreen> createState() => _TaskBoardScreenState();
}

class _TaskBoardScreenState extends ConsumerState<TaskBoardScreen> {
  final ScrollController _horizontalScrollController = ScrollController();
  late final SyncService syncService;

  final _searchController = TextEditingController();
  final _assigneeFilterController = TextEditingController();
  TaskPriority? _priorityFilter;
  String? _dueDateFilter; // 'all', 'overdue', 'today', 'upcoming'

  @override
  void initState() {
    super.initState();
    // Subscribe to real-time updates for this board
    syncService = ref.read(syncServiceProvider);
    syncService.subscribeToBoardTasks(widget.boardId);
  }

  @override
  void dispose() {
    // Unsubscribe from real-time updates
    syncService.unsubscribeFromBoardTasks();
    _horizontalScrollController.dispose();
    _searchController.dispose();
    _assigneeFilterController.dispose();
    super.dispose();
  }

  List<TaskEntity> _filterTasks(List<TaskEntity> tasks) {
    return tasks.where((t) {
      // Search (Title/Description)
      if (_searchController.text.isNotEmpty) {
        final query = _searchController.text.toLowerCase();
        final matchesTitle = t.title.toLowerCase().contains(query);
        final matchesDesc = t.description.toLowerCase().contains(query);
        if (!matchesTitle && !matchesDesc) return false;
      }

      // Assignee Filter
      if (_assigneeFilterController.text.isNotEmpty) {
        if (t.assigneeId == null) return false;
        final query = _assigneeFilterController.text.toLowerCase();
        if (!t.assigneeId!.toLowerCase().contains(query)) return false;
      }

      // Priority Filter
      if (_priorityFilter != null) {
        if (t.priority != _priorityFilter) return false;
      }

      // Due Date Filter
      if (_dueDateFilter != null && _dueDateFilter != 'all') {
        if (t.dueDate == null) return false;
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final taskDate = DateTime(
          t.dueDate!.year,
          t.dueDate!.month,
          t.dueDate!.day,
        );

        if (_dueDateFilter == 'overdue') {
          if (!taskDate.isBefore(today)) return false;
        } else if (_dueDateFilter == 'today') {
          if (taskDate != today) return false;
        } else if (_dueDateFilter == 'upcoming') {
          if (!taskDate.isAfter(today)) return false;
        }
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(boardTasksProvider(widget.boardId));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.boardTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(context),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search tasks...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
        ),
      ),
      body: tasksAsync.when(
        data: (tasks) {
          final filteredTasks = _filterTasks(tasks);

          final todoTasks = filteredTasks
              .where((t) => t.status == TaskStatus.todo)
              .toList();
          final inProgressTasks = filteredTasks
              .where((t) => t.status == TaskStatus.inProgress)
              .toList();
          final doneTasks = filteredTasks
              .where((t) => t.status == TaskStatus.done)
              .toList();

          return Scrollbar(
            controller: _horizontalScrollController,
            thumbVisibility: true,
            child: SingleChildScrollView(
              controller: _horizontalScrollController,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TaskColumn(
                    title: 'To Do',
                    status: TaskStatus.todo,
                    tasks: todoTasks,
                    onTaskDropped: (task, status) =>
                        _updateTaskStatus(ref, task, status),
                    onTaskTap: (task) => _openTaskDetails(context, task),
                  ),
                  TaskColumn(
                    title: 'In Progress',
                    status: TaskStatus.inProgress,
                    tasks: inProgressTasks,
                    onTaskDropped: (task, status) =>
                        _updateTaskStatus(ref, task, status),
                    onTaskTap: (task) => _openTaskDetails(context, task),
                  ),
                  TaskColumn(
                    title: 'Done',
                    status: TaskStatus.done,
                    tasks: doneTasks,
                    onTaskDropped: (task, status) =>
                        _updateTaskStatus(ref, task, status),
                    onTaskTap: (task) => _openTaskDetails(context, task),
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: 3,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          itemBuilder: (context, index) => Container(
            width: 300,
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ShimmerWidget.rectangular(height: 20, width: 100),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      physics:
                          const NeverScrollableScrollPhysics(), // Skeleton doesn't need scroll
                      itemCount: 3,
                      itemBuilder: (_, __) => const Padding(
                        padding: EdgeInsets.symmetric(vertical: 4),
                        child: ShimmerWidget.rectangular(height: 80),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        error: (err, stack) => ErrorRetryWidget(
          message: err.toString(),
          onRetry: () => ref.refresh(boardTasksProvider(widget.boardId)),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _createNewTask(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Filter Tasks'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _assigneeFilterController,
                    decoration: const InputDecoration(
                      labelText: 'Assignee Name',
                    ),
                    onChanged: (_) {
                      // Just update local dialog state if needed, or parent
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<TaskPriority?>(
                    initialValue: _priorityFilter,
                    decoration: const InputDecoration(labelText: 'Priority'),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('All')),
                      ...TaskPriority.values.map((p) {
                        return DropdownMenuItem(
                          value: p,
                          child: Text(p.name.toUpperCase()),
                        );
                      }),
                    ],
                    onChanged: (val) {
                      setDialogState(() => _priorityFilter = val);
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _dueDateFilter ?? 'all',
                    decoration: const InputDecoration(labelText: 'Due Date'),
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('All')),
                      DropdownMenuItem(
                        value: 'overdue',
                        child: Text('Overdue'),
                      ),
                      DropdownMenuItem(value: 'today', child: Text('Today')),
                      DropdownMenuItem(
                        value: 'upcoming',
                        child: Text('Upcoming'),
                      ),
                    ],
                    onChanged: (val) {
                      setDialogState(() => _dueDateFilter = val);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    // Reset filters
                    setState(() {
                      _assigneeFilterController.clear();
                      _priorityFilter = null;
                      _dueDateFilter = null;
                    });
                    Navigator.pop(context);
                  },
                  child: const Text('Clear'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {}); // Apply filters
                    Navigator.pop(context);
                  },
                  child: const Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _updateTaskStatus(WidgetRef ref, TaskEntity task, TaskStatus newStatus) {
    final updatedTask = TaskEntity(
      id: task.id,
      boardId: task.boardId,
      title: task.title,
      description: task.description,
      status: newStatus,
      priority: task.priority,
      createdAt: task.createdAt,
      updatedAt: DateTime.now(),
      dueDate: task.dueDate,
      assigneeId: task.assigneeId,
    );
    ref.read(taskRepositoryProvider).updateTask(updatedTask);
  }

  void _createNewTask(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => CreateTaskDialog(boardId: widget.boardId),
    );
  }

  void _openTaskDetails(BuildContext context, TaskEntity task) {
    showDialog(
      context: context,
      builder: (context) =>
          CreateTaskDialog(boardId: widget.boardId, taskToEdit: task),
    );
  }
}

class CreateTaskDialog extends ConsumerStatefulWidget {
  final String boardId;
  final TaskEntity? taskToEdit;
  const CreateTaskDialog({super.key, required this.boardId, this.taskToEdit});

  @override
  ConsumerState<CreateTaskDialog> createState() => _CreateTaskDialogState();
}

class _CreateTaskDialogState extends ConsumerState<CreateTaskDialog> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _assigneeController = TextEditingController();
  TaskPriority _priority = TaskPriority.medium;
  DateTime? _dueDate;

  @override
  void initState() {
    super.initState();
    if (widget.taskToEdit != null) {
      _titleController.text = widget.taskToEdit!.title;
      _descController.text = widget.taskToEdit!.description;
      _assigneeController.text = widget.taskToEdit!.assigneeId ?? '';
      _priority = widget.taskToEdit!.priority;
      _dueDate = widget.taskToEdit!.dueDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.taskToEdit == null ? 'New Task' : 'Edit Task'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            TextField(
              controller: _descController,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 3,
            ),
            TextField(
              controller: _assigneeController,
              decoration: const InputDecoration(
                labelText: 'Assignee (Email/Name)',
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<TaskPriority>(
              initialValue: _priority,
              decoration: const InputDecoration(labelText: 'Priority'),
              items: TaskPriority.values.map((p) {
                return DropdownMenuItem(
                  value: p,
                  child: Text(p.name.toUpperCase()),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _priority = val);
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  _dueDate == null
                      ? 'No Due Date'
                      : '${_dueDate!.month}/${_dueDate!.day}/${_dueDate!.year}',
                ),
                const Spacer(),
                TextButton(
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _dueDate ?? DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) setState(() => _dueDate = date);
                  },
                  child: const Text('Pick Date'),
                ),
              ],
            ),
            if (widget.taskToEdit != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        _deleteTask(context);
                      },
                      icon: const Icon(Icons.delete, color: Colors.red),
                      label: const Text(
                        'Delete',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          builder: (context) => SizedBox(
                            height: MediaQuery.of(context).size.height * 0.7,
                            child: TaskCommentsSheet(
                              taskId: widget.taskToEdit!.id,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.comment),
                      label: const Text('Comments'),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => _saveTask(context),
          child: Text(widget.taskToEdit == null ? 'Create' : 'Save'),
        ),
      ],
    );
  }

  void _deleteTask(BuildContext context) async {
    if (widget.taskToEdit == null) return;
    await ref.read(taskRepositoryProvider).deleteTask(widget.taskToEdit!.id);
    if (context.mounted) Navigator.pop(context);
  }

  void _saveTask(BuildContext context) async {
    if (_titleController.text.trim().isEmpty) return;

    final repo = ref.read(taskRepositoryProvider);
    final title = _titleController.text.trim();
    final description = _descController.text.trim();
    final assignee = _assigneeController.text.trim().isEmpty
        ? null
        : _assigneeController.text.trim();

    if (widget.taskToEdit != null) {
      final updatedTask = TaskEntity(
        id: widget.taskToEdit!.id,
        boardId: widget.boardId,
        title: title,
        description: description,
        status: widget.taskToEdit!.status,
        priority: _priority,
        dueDate: _dueDate,
        assigneeId: assignee,
        createdAt: widget.taskToEdit!.createdAt,
        updatedAt: DateTime.now(),
      );
      await repo.updateTask(updatedTask);
    } else {
      final newTask = TaskEntity(
        id: const Uuid().v4(),
        boardId: widget.boardId,
        title: title,
        description: description,
        status: TaskStatus.todo,
        priority: _priority,
        dueDate: _dueDate,
        assigneeId: assignee,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await repo.createTask(newTask);
    }
    if (context.mounted) Navigator.pop(context);
  }
}
