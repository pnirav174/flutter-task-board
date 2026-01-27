import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_task_board/core/sync_providers.dart';
import 'package:flutter_task_board/features/task/domain/task_entity.dart';
import 'package:flutter_task_board/features/task/presentation/task_board_screen.dart';
import 'package:flutter_task_board/features/task/presentation/task_providers.dart';
import 'package:mockito/mockito.dart';

import '../helpers/test_helpers.mocks.dart';

void main() {
  late MockSyncService mockSyncService;
  late MockTaskRepository mockTaskRepository;

  setUp(() {
    mockSyncService = MockSyncService();
    mockTaskRepository = MockTaskRepository();

    // Default stubs
    when(mockSyncService.subscribeToBoardTasks(any)).thenReturn(null);
    when(mockSyncService.unsubscribeFromBoardTasks()).thenReturn(null);
    when(mockTaskRepository.deleteTask(any)).thenAnswer((_) async {});
    when(mockTaskRepository.createTask(any)).thenAnswer((_) async {});
  });

  testWidgets('Swipe to delete task calls repository and shows undo', (
    WidgetTester tester,
  ) async {
    // Setup data
    final tasks = [
      TaskEntity(
        id: '1',
        boardId: 'b1',
        title: 'Task to Delete',
        description: 'Desc',
        status: TaskStatus.todo,
        priority: TaskPriority.medium,
        permissions: const {},
        isArchived: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];

    // Build UI
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          syncServiceProvider.overrideWithValue(mockSyncService),
          boardTasksProvider('b1').overrideWith((ref) => Stream.value(tasks)),
          taskRepositoryProvider.overrideWithValue(mockTaskRepository),
        ],
        child: const MaterialApp(
          home: TaskBoardScreen(boardId: 'b1', boardTitle: 'Test Board'),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify task is present
    expect(find.text('Task to Delete'), findsOneWidget);

    // Swipe to delete
    // Find the Dismissible - it wraps TaskCard
    final taskCard = find.text('Task to Delete');
    await tester.drag(taskCard, const Offset(-500, 0));
    await tester.pumpAndSettle();

    // Verify delete was called
    verify(mockTaskRepository.deleteTask('1')).called(1);

    // Verify Undo SnackBar appears
    expect(find.text('Task "Task to Delete" deleted'), findsOneWidget);
    expect(find.text('Undo'), findsOneWidget);

    // Tap Undo
    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();

    // Verify create was called (restore)
    verify(mockTaskRepository.createTask(any)).called(1);
  });
}
