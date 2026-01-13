import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter_task_board/core/sync_service.dart';
import 'package:flutter_task_board/features/task/data/app_database.dart';
import 'package:uuid/uuid.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
// For Value

import '../helpers/test_helpers.mocks.dart';

void main() {
  late AppDatabase db;
  late MockRealtimeDatabaseRepository mockRemoteRepo;
  late MockConnectivity mockConnectivity;
  late SyncService syncService;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    mockRemoteRepo = MockRealtimeDatabaseRepository();
    mockConnectivity = MockConnectivity();

    // Mock initial connectivity check (return connected)
    when(
      mockConnectivity.checkConnectivity(),
    ).thenAnswer((_) async => [ConnectivityResult.wifi]);
    // Mock connectivity stream (empty for now)
    when(
      mockConnectivity.onConnectivityChanged,
    ).thenAnswer((_) => const Stream.empty());

    // Mock remote repo streams (empty for simple queue test)
    when(
      mockRemoteRepo.watchRemoteBoards(),
    ).thenAnswer((_) => const Stream.empty());

    syncService = SyncService(db, mockRemoteRepo, mockConnectivity);
  });

  tearDown(() async {
    syncService.dispose();
    await db.close();
  });

  group('SyncService Tests', () {
    test('refresh() processes sync queue and pushes to remote', () async {
      final taskId = const Uuid().v4();

      // Insert item into Queue manually
      await db
          .into(db.syncQueue)
          .insert(
            SyncQueueCompanion.insert(
              // id is auto-increment, do not pass String!
              mutationType: 'create',
              table: 'tasks',
              data:
                  '{"id": "$taskId", "boardId": "b1", "title": "T1", "description": "D1", "status": "todo", "priority": "medium", "createdAt": "${DateTime.now().toIso8601String()}", "updatedAt": "${DateTime.now().toIso8601String()}", "assigneeId": null}',
              createdAt: DateTime.now(),
            ),
          );

      // Act
      await syncService.refresh();

      // Assert
      // Verify pushTask was called on remote repo
      verify(mockRemoteRepo.pushTask(any)).called(greaterThanOrEqualTo(1));

      // Verify queue is empty (processed items are deleted)
      final queueItems = await db.select(db.syncQueue).get();
      expect(queueItems.isEmpty, true);
    });
  });
}
