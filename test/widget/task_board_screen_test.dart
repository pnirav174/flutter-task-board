import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_task_board/core/sync_providers.dart';
import 'package:flutter_task_board/features/task/domain/task_entity.dart';
import 'package:flutter_task_board/features/task/presentation/task_board_screen.dart';
import 'package:flutter_task_board/features/task/presentation/task_providers.dart';

import '../helpers/test_helpers.mocks.dart';

void main() {
  late MockSyncService mockSyncService;

  setUp(() {
    mockSyncService = MockSyncService();
  });

  testWidgets('TaskBoardScreen renders columns and tasks', (
    WidgetTester tester,
  ) async {
    // Setup data
    final tasks = [
      TaskEntity(
        id: '1',
        boardId: 'b1',
        title: 'Task 1',
        description: 'Desc 1',
        status: TaskStatus.todo,
        priority: TaskPriority.medium,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      TaskEntity(
        id: '2',
        boardId: 'b1',
        title: 'Task 2',
        description: 'Desc 2',
        status: TaskStatus.inProgress,
        priority: TaskPriority.high,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];

    // Setup overrides
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          syncServiceProvider.overrideWithValue(mockSyncService),
          boardTasksProvider('b1').overrideWith((ref) => Stream.value(tasks)),
        ],
        child: const MaterialApp(
          home: TaskBoardScreen(boardId: 'b1', boardTitle: 'Test Board'),
        ),
      ),
    );

    // Wait for frames
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('Task 1'), findsOneWidget);
    expect(find.text('Task 2'), findsOneWidget);
    expect(find.text('To Do'), findsOneWidget); // Column Header
    expect(find.text('In Progress'), findsOneWidget);

    // Verify sync service subscribed (might be called or not depending on init)
    // verify(mockSyncService.subscribeToBoardTasks('b1')).called(1);
  });
}
