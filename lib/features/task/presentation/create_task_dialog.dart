import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_task_board/features/task/domain/task_entity.dart';
import 'package:flutter_task_board/features/task/presentation/task_comments_sheet.dart';
import 'package:flutter_task_board/features/task/presentation/task_providers.dart';
import 'package:uuid/uuid.dart';

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
                          useSafeArea: true, // Add this line
                          backgroundColor: Colors.transparent,
                          builder: (context) {
                            return DraggableScrollableSheet(
                              initialChildSize: 1.0,
                              minChildSize: 0.3,
                              maxChildSize: 1.0,
                              snap: true,
                              snapSizes: const [0.3, 1.0],
                              builder: (innerContext, scrollController) {
                                final topInset = MediaQuery.of(
                                  innerContext,
                                ).padding.top;
                                print(
                                  'Top inset after useSafeArea: $topInset',
                                ); // Should now work

                                return Padding(
                                  padding: EdgeInsets.only(top: topInset + 20),
                                  child: Material(
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(16),
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    child: TaskCommentsSheet(
                                      taskId: widget.taskToEdit!.id,
                                      scrollController: scrollController,
                                    ),
                                  ),
                                );
                              },
                            );
                          },
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
