import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:take_home_assignment/features/board/presentation/board_providers.dart';
import 'package:take_home_assignment/features/board/domain/board.dart'
    as domain;
import 'package:take_home_assignment/core/presentation/widgets/shimmer_widget.dart';
import 'package:take_home_assignment/core/presentation/widgets/error_retry_widget.dart';

class BoardListScreen extends ConsumerWidget {
  const BoardListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final boardsAsync = ref.watch(boardListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Boards'),
        actions: [
          IconButton(
            onPressed: () {
              context.push('/settings');
            },
            icon: const Icon(Icons.settings),
          ),
        ],
      ),
      body: boardsAsync.when(
        data: (boards) {
          if (boards.isEmpty) {
            return RefreshIndicator(
              onRefresh: () async => ref.refresh(boardListProvider),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 100),
                  Center(child: Text('No boards yet. Create one!')),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.refresh(boardListProvider),
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: boards.length,
              itemBuilder: (context, index) {
                final board = boards[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: ListTile(
                    title: Text(board.title),
                    subtitle: Text(
                      'Created: ${DateFormat.yMMMd().format(board.createdAt)}',
                    ),
                    onTap: () {
                      context.go(
                        '/board/${board.id}?title=${Uri.encodeComponent(board.title)}',
                      );
                    },
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') {
                          _showBoardDialog(context, ref, board: board);
                        } else if (value == 'delete') {
                          _confirmDeleteBoard(context, ref, board);
                        }
                      },
                      itemBuilder: (BuildContext context) => [
                        const PopupMenuItem(value: 'edit', child: Text('Edit')),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text(
                            'Delete',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
        loading: () => ListView.builder(
          itemCount: 5,
          itemBuilder: (context, index) => const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ShimmerWidget.rectangular(height: 72),
          ),
        ),
        error: (err, stack) => ErrorRetryWidget(
          message: err.toString(),
          onRetry: () => ref.refresh(boardListProvider),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showBoardDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showBoardDialog(
    BuildContext context,
    WidgetRef ref, {
    domain.Board? board,
  }) {
    final controller = TextEditingController(text: board?.title ?? '');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(board == null ? 'New Board' : 'Edit Board'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Board Title'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final title = controller.text.trim();
              if (title.isEmpty) return;

              // Close dialog first
              Navigator.pop(context);

              if (board == null) {
                ref.read(boardRepositoryProvider).createBoard(title);
              } else {
                final updatedBoard = domain.Board(
                  id: board.id,
                  title: title,
                  createdAt: board.createdAt,
                );
                ref.read(boardRepositoryProvider).updateBoard(updatedBoard);
              }
            },
            child: Text(board == null ? 'Create' : 'Save'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteBoard(
    BuildContext context,
    WidgetRef ref,
    domain.Board board,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Board?'),
        content: Text(
          'Are you sure you want to delete "${board.title}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(boardRepositoryProvider).deleteBoard(board.id);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
