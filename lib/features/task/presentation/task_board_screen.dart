import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_task_board/core/presentation/widgets/shimmer_widget.dart';
import 'package:flutter_task_board/core/presentation/widgets/error_retry_widget.dart';
import 'package:flutter_task_board/core/sync_providers.dart';
import 'package:flutter_task_board/features/task/domain/task_entity.dart';
import 'package:flutter_task_board/features/task/presentation/create_task_dialog.dart';
import 'package:flutter_task_board/features/task/presentation/task_providers.dart';
import 'package:flutter_task_board/features/task/presentation/widgets/task_column.dart';
import 'package:flutter_task_board/core/sync_service.dart';

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

//
