import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_task_board/features/auth/presentation/auth_providers.dart';
import 'package:flutter_task_board/features/task/domain/task_entity.dart';
import 'package:flutter_task_board/features/task/presentation/task_providers.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

class TaskCard extends ConsumerWidget {
  final TaskEntity task;
  final VoidCallback onTap;

  const TaskCard({super.key, required this.task, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LongPressDraggable<TaskEntity>(
      data: task,
      feedback: SizedBox(
        width: 250,
        child: Card(
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Text(
              task.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.5,
        child: _buildCardContent(context, ref),
      ),
      onDragStarted: () => HapticFeedback.selectionClick(),
      onDraggableCanceled: (_, __) => HapticFeedback.lightImpact(),
      onDragEnd: (_) => HapticFeedback.selectionClick(),
      child: _buildCardContent(context, ref),
    );
  }

  Widget _buildCardContent(BuildContext context, WidgetRef ref) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        onLongPress: () => _showContextMenu(context, ref),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                task.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (task.description.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  task.description,
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildPriorityChip(context, task.priority),
                  if (task.dueDate != null)
                    Text(
                      DateFormat.MMMd().format(task.dueDate!),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showContextMenu(BuildContext context, WidgetRef ref) async {
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final RenderBox card = context.findRenderObject() as RenderBox;
    final relativeOffset = card.localToGlobal(
      Offset.zero,
      ancestor: overlay,
    ); // Top-left of the card

    final selected = await showMenu<String>(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromPoints(
          relativeOffset,
          relativeOffset + card.size.bottomRight(Offset.zero),
        ),
        Offset.zero & overlay.size,
      ),
      items: [
        const PopupMenuItem(value: 'duplicate', child: Text('Duplicate')),
        const PopupMenuItem(value: 'archive', child: Text('Archive')),
        const PopupMenuItem(value: 'assign_me', child: Text('Assign to Me')),
      ],
    );

    if (selected == null) return;

    final repo = ref.read(taskRepositoryProvider);

    switch (selected) {
      case 'duplicate':
        final newTask = TaskEntity(
          id: const Uuid().v4(),
          boardId: task.boardId,
          title: '${task.title} (Copy)',
          description: task.description,
          status: task.status,
          priority: task.priority,
          dueDate: task.dueDate,
          assigneeId: task.assigneeId,
          permissions: task.permissions,
          isArchived: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await repo.createTask(newTask);
        break;

      case 'archive':
        final archivedTask = TaskEntity(
          id: task.id,
          boardId: task.boardId,
          title: task.title,
          description: task.description,
          status: task.status,
          priority: task.priority,
          dueDate: task.dueDate,
          assigneeId: task.assigneeId,
          permissions: task.permissions,
          isArchived: true,
          createdAt: task.createdAt,
          updatedAt: DateTime.now(),
        );
        await repo.updateTask(archivedTask);
        break;

      case 'assign_me':
        final currentUser = ref.read(authStateProvider).value;
        if (currentUser != null) {
          final assignedTask = TaskEntity(
            id: task.id,
            boardId: task.boardId,
            title: task.title,
            description: task.description,
            status: task.status,
            priority: task.priority,
            dueDate: task.dueDate,
            assigneeId: currentUser.email, // Using email as user ID for now
            permissions: task.permissions,
            isArchived: task.isArchived,
            createdAt: task.createdAt,
            updatedAt: DateTime.now(),
          );
          await repo.updateTask(assignedTask);
        }
        break;
    }
  }

  Widget _buildPriorityChip(BuildContext context, TaskPriority priority) {
    Color color;
    switch (priority) {
      case TaskPriority.high:
        color = Colors.redAccent;
        break;
      case TaskPriority.medium:
        color = Colors.orangeAccent;
        break;
      case TaskPriority.low:
        color = Colors.green;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        priority.name.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
