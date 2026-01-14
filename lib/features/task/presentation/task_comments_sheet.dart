import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:flutter_task_board/features/task/domain/comment_entity.dart';
import 'package:flutter_task_board/core/sync_providers.dart';
import 'package:flutter_task_board/features/auth/presentation/auth_providers.dart';
import 'package:flutter_task_board/features/task/presentation/task_providers.dart';
import 'package:uuid/uuid.dart';

final taskCommentsProvider = StreamProvider.family<List<CommentEntity>, String>(
  (ref, taskId) {
    final repo = ref.watch(taskRepositoryProvider);
    return repo.watchComments(taskId);
  },
);

class TaskCommentsSheet extends ConsumerStatefulWidget {
  final String taskId;
  final ScrollController scrollController;
  const TaskCommentsSheet({
    super.key,
    required this.taskId,
    required this.scrollController,
  });

  @override
  ConsumerState<TaskCommentsSheet> createState() => _TaskCommentsSheetState();
}

class _TaskCommentsSheetState extends ConsumerState<TaskCommentsSheet> {
  late final syncService;
  final _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    syncService = ref.read(syncServiceProvider);
    syncService.subscribeToTaskComments(widget.taskId);
  }

  @override
  void dispose() {
    syncService.unsubscribeFromTaskComments();
    _commentController.dispose();
    super.dispose();
  }

  void _addComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    final user = ref.read(authStateProvider).value;
    if (user == null) return;

    final comment = CommentEntity(
      id: const Uuid().v4(),
      taskId: widget.taskId,
      content: content,
      authorId: user.id,
      authorEmail: user.email,
      createdAt: DateTime.now(),
    );

    // Optimistic clear
    _commentController.clear();

    await ref.read(taskRepositoryProvider).addComment(comment);
  }

  @override
  Widget build(BuildContext context) {
    final commentsAsync = ref.watch(taskCommentsProvider(widget.taskId));

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Comments',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: commentsAsync.when(
              data: (comments) {
                if (comments.isEmpty) {
                  return const Center(child: Text('No comments yet.'));
                }
                // Sort by date desc
                final sorted = List<CommentEntity>.from(comments)
                  ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

                return ListView.builder(
                  controller: widget.scrollController,
                  itemCount: sorted.length,
                  itemBuilder: (context, index) {
                    final c = sorted[index];
                    return ListTile(
                      title: Text(c.authorEmail),
                      subtitle: Text(c.content),
                      trailing: Text(
                        formatShort(c.createdAt),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error: $err')),
            ),
          ),
          const SizedBox(height: 8),
          SafeArea(
            bottom: true,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      hintText: 'Add a comment...',
                      filled: true,
                      fillColor: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      hintStyle: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.primary,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _addComment,
                  icon: const Icon(Icons.send),
                  // color: Theme.of(context).primaryColor,
                ),
              ],
            ),
          ),
          const SizedBox(height: 5),
        ],
      ),
    );
  }

  String formatShort(DateTime date) {
    final now = DateTime.now();

    if (DateUtils.isSameDay(now, date)) {
      return DateFormat.Hm().format(date); // 14:30
    }

    return DateFormat('d MMM').format(date); // 12 Jan
  }
}
