import 'dart:convert';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_task_board/features/task/data/app_database.dart';
import 'package:flutter_task_board/features/task/data/local_task_repository.dart';
import 'package:flutter_task_board/features/task/domain/task_entity.dart';
import 'package:uuid/uuid.dart';

void main() {
  late AppDatabase db;
  late LocalTaskRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = LocalTaskRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('LocalTaskRepository Tests', () {
    test('createTask adds task to DB and Queue', () async {
      final task = TaskEntity(
        id: const Uuid().v4(),
        boardId: 'board1',
        title: 'Test Create',
        description: 'Desc',
        status: TaskStatus.todo,
        priority: TaskPriority.low,
        permissions: const {},
        isArchived: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await repo.createTask(task);

      final tasks = await repo.watchTasks('board1').first;
      expect(tasks.length, 1);
      expect(tasks.first.title, 'Test Create');

      // Check sync queue
      final queueItems = await db.select(db.syncQueue).get();
      expect(queueItems.length, 1);
      expect(queueItems.first.mutationType, 'create');
      expect(queueItems.first.table, 'tasks');

      final data = jsonDecode(queueItems.first.data);
      expect(data['id'], task.id);
      expect(data['title'], 'Test Create');
    });

    test('updateTask updates DB and adds update to Queue', () async {
      final task = TaskEntity(
        id: const Uuid().v4(),
        boardId: 'board1',
        title: 'Original Title',
        description: 'Desc',
        status: TaskStatus.todo,
        priority: TaskPriority.low,
        permissions: const {},
        isArchived: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await repo.createTask(task);

      // Verify original
      var tasks = await repo.watchTasks('board1').first;
      expect(tasks.first.title, 'Original Title');

      // Update
      final updatedTask = TaskEntity(
        id: task.id,
        boardId: task.boardId,
        title: 'Updated Title',
        description: task.description,
        status: task.status,
        priority: task.priority,
        permissions: task.permissions,
        isArchived: task.isArchived,
        createdAt: task.createdAt,
        updatedAt: DateTime.now(),
      );

      await repo.updateTask(updatedTask);

      // Verify update
      tasks = await repo.watchTasks('board1').first;
      expect(tasks.first.title, 'Updated Title');

      // Check sync queue
      final queueItems = await db.select(db.syncQueue).get();
      expect(queueItems.length, 2); // 1 create, 1 update
      expect(queueItems[1].mutationType, 'update');
    });

    test('deleteTask removes from DB and adds delete to Queue', () async {
      final task = TaskEntity(
        id: const Uuid().v4(),
        boardId: 'board1',
        title: 'To Delete',
        description: 'Desc',
        status: TaskStatus.todo,
        priority: TaskPriority.low,
        permissions: const {},
        isArchived: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await repo.createTask(task);
      await repo.deleteTask(task.id);

      final tasks = await repo.watchTasks('board1').first;
      expect(tasks.isEmpty, true);

      final queueItems = await db.select(db.syncQueue).get();
      expect(queueItems.length, 2); // create then delete
      expect(queueItems.last.mutationType, 'delete');
    });
  });
}
