import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter_task_board/core/mappers.dart';
import 'package:flutter_task_board/features/task/data/app_database.dart';
import 'package:flutter_task_board/features/task/domain/task_entity.dart';
import 'package:flutter_task_board/features/task/domain/comment_entity.dart';
import 'package:flutter_task_board/features/task/domain/task_repository.dart';

class LocalTaskRepository implements TaskRepository {
  final AppDatabase _db;

  LocalTaskRepository(this._db);

  @override
  Stream<List<TaskEntity>> watchTasks(String boardId) {
    return (_db.select(_db.tasks)..where((tbl) => tbl.boardId.equals(boardId)))
        .watch()
        .map((rows) => rows.map((row) => row.toEntity()).toList());
  }

  @override
  Future<void> createTask(TaskEntity task) async {
    await _db.transaction(() async {
      await _db.into(_db.tasks).insert(task.toCompanion());

      await _db
          .into(_db.syncQueue)
          .insert(
            SyncQueueCompanion(
              mutationType: const Value('create'),
              table: const Value('tasks'),
              data: Value(
                jsonEncode({
                  'id': task.id,
                  'boardId': task.boardId,
                  'title': task.title,
                  'description': task.description,
                  'status': task.status.name,
                  'priority': task.priority.name,
                  'createdAt': task.createdAt.toIso8601String(),
                  'updatedAt': task.updatedAt.toIso8601String(),
                  'dueDate': task.dueDate?.toIso8601String(),
                  'assigneeId': task.assigneeId,
                }),
              ),
              createdAt: Value(DateTime.now()),
            ),
          );
    });
  }

  @override
  Future<void> updateTask(TaskEntity task) async {
    await _db.transaction(() async {
      await _db.update(_db.tasks).replace(task.toCompanion());

      await _db
          .into(_db.syncQueue)
          .insert(
            SyncQueueCompanion(
              mutationType: const Value('update'),
              table: const Value('tasks'),
              data: Value(
                jsonEncode({
                  'id': task.id,
                  'boardId': task.boardId,
                  'title': task.title,
                  'description': task.description,
                  'status': task.status.name,
                  'priority': task.priority.name,
                  'createdAt': task.createdAt.toIso8601String(),
                  'updatedAt': task.updatedAt.toIso8601String(),
                  'dueDate': task.dueDate?.toIso8601String(),
                  'assigneeId': task.assigneeId,
                }),
              ),
              createdAt: Value(DateTime.now()),
            ),
          );
    });
  }

  @override
  Future<void> deleteTask(String id) async {
    await _db.transaction(() async {
      await (_db.delete(_db.tasks)..where((tbl) => tbl.id.equals(id))).go();

      await _db
          .into(_db.syncQueue)
          .insert(
            SyncQueueCompanion(
              mutationType: const Value('delete'),
              table: const Value('tasks'),
              data: Value(jsonEncode({'id': id})),
              createdAt: Value(DateTime.now()),
            ),
          );
    });
  }

  @override
  Stream<List<CommentEntity>> watchComments(String taskId) {
    return (_db.select(_db.comments)..where((tbl) => tbl.taskId.equals(taskId)))
        .watch()
        .map((rows) => rows.map((row) => row.toEntity()).toList());
  }

  @override
  Future<void> addComment(CommentEntity comment) async {
    await _db.transaction(() async {
      await _db.into(_db.comments).insert(comment.toCompanion());

      await _db
          .into(_db.syncQueue)
          .insert(
            SyncQueueCompanion(
              mutationType: const Value('create'),
              table: const Value('comments'),
              data: Value(
                jsonEncode({
                  'id': comment.id,
                  'taskId': comment.taskId,
                  'content': comment.content,
                  'authorId': comment.authorId,
                  'authorEmail': comment.authorEmail,
                  'createdAt': comment.createdAt.toIso8601String(),
                }),
              ),
              createdAt: Value(DateTime.now()),
            ),
          );
    });
  }
}
