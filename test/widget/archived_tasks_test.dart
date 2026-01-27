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
  });

  testWidgets('Archived tasks filter works correctly', (
    WidgetTester tester,
  ) async {
    // Setup data
    final tasks = [
      TaskEntity(
        id: '1',
        boardId: 'b1',
        title: 'Active Task',
        description: 'Desc',
        status: TaskStatus.todo,
        priority: TaskPriority.medium,
        permissions: const {},
        isArchived: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      TaskEntity(
        id: '2',
        boardId: 'b1',
        title: 'Archived Task',
        description: 'Desc',
        status: TaskStatus.todo,
        priority: TaskPriority.medium,
        permissions: const {},
        isArchived: true,
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

    // Verify default state: Active Task visible, Archived Task hidden
    expect(find.text('Active Task'), findsOneWidget);
    expect(find.text('Archived Task'), findsNothing);

    // Open Filter Dialog
    await tester.tap(find.byIcon(Icons.filter_list));
    await tester.pumpAndSettle();

    // Toggle "Show Archived Tasks"
    // Find SwitchListTile by text
    await tester.tap(find.text('Show Archived Tasks'));
    await tester.pumpAndSettle();

    // Apply Filter
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();

    // Verify archived state: Active Task hidden, Archived Task visible
    expect(find.text('Active Task'), findsNothing);
    expect(find.text('Archived Task'), findsOneWidget);

    // Reset Filter
    await tester.tap(find.byIcon(Icons.filter_list));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Clear'));
    await tester.pumpAndSettle();

    // Verify back to default
    expect(find.text('Active Task'), findsOneWidget);
    expect(find.text('Archived Task'), findsNothing);
  });
}
