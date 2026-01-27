import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_task_board/features/board/domain/board.dart';
import 'package:flutter_task_board/features/task/domain/task_entity.dart';
import 'package:flutter_task_board/features/task/domain/comment_entity.dart';

class RealtimeDatabaseRepository {
  final FirebaseDatabase _db;

  RealtimeDatabaseRepository(this._db);

  // --- Boards ---
  Future<void> pushBoard(Board board) async {
    await _db.ref('boards/${board.id}').set({
      'id': board.id,
      'title': board.title,
      'createdAt': board.createdAt.toIso8601String(),
    });
  }

  Future<void> deleteBoard(String boardId) async {
    await _db.ref('boards/$boardId').remove();
  }

  Stream<List<Board>> watchRemoteBoards() {
    return _db.ref('boards').onValue.map((event) {
      final snapshot = event.snapshot;
      if (!snapshot.exists || snapshot.value == null) {
        return [];
      }

      final data = snapshot.value as Map;
      return data.values.map((value) {
        final map = Map<String, dynamic>.from(value as Map);
        return Board(
          id: map['id'],
          title: map['title'],
          createdAt: DateTime.parse(map['createdAt']),
        );
      }).toList();
    });
  }

  // --- Tasks ---
  Future<void> pushTask(TaskEntity task) async {
    await _db.ref('tasks/${task.id}').set({
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
      'permissions': task.permissions.map((k, v) => MapEntry(k, v.name)),
      'isArchived': task.isArchived,
    });
  }

  Future<void> deleteTask(String taskId) async {
    await _db.ref('tasks/$taskId').remove();
  }

  Stream<List<TaskEntity>> watchRemoteTasks(String boardId) {
    return _db
        .ref('tasks')
        .orderByChild('boardId')
        .equalTo(boardId)
        .onValue
        .map((event) {
          final snapshot = event.snapshot;
          if (!snapshot.exists || snapshot.value == null) {
            return [];
          }

          final data = snapshot.value as Map;
          return data.values.map((value) {
            final map = Map<String, dynamic>.from(value as Map);

            final permissionsMap = map['permissions'] as Map? ?? {};
            final permissions = permissionsMap.map(
              (k, v) =>
                  MapEntry(k as String, TaskRole.values.byName(v as String)),
            );

            return TaskEntity(
              id: map['id'],
              boardId: map['boardId'],
              title: map['title'],
              description: map['description'],
              status: TaskStatus.values.byName(map['status']),
              priority: TaskPriority.values.byName(map['priority']),
              createdAt: DateTime.parse(map['createdAt']),
              updatedAt: DateTime.parse(map['updatedAt']),
              dueDate: map['dueDate'] != null
                  ? DateTime.parse(map['dueDate'])
                  : null,
              assigneeId: map['assigneeId'],
              permissions: permissions,
              isArchived: map['isArchived'] ?? false,
            );
          }).toList();
        });
  }

  // --- Comments ---
  Future<void> pushComment(CommentEntity comment) async {
    await _db.ref('comments/${comment.taskId}/${comment.id}').set({
      'id': comment.id,
      'taskId': comment.taskId,
      'content': comment.content,
      'authorId': comment.authorId,
      'authorEmail': comment.authorEmail,
      'createdAt': comment.createdAt.toIso8601String(),
    });
  }

  Stream<List<CommentEntity>> watchRemoteComments(String taskId) {
    return _db.ref('comments/$taskId').onValue.map((event) {
      final snapshot = event.snapshot;
      if (!snapshot.exists || snapshot.value == null) {
        return [];
      }

      final data = snapshot.value as Map;
      return data.values.map((value) {
        final map = Map<String, dynamic>.from(value as Map);
        return CommentEntity(
          id: map['id'],
          taskId: map['taskId'],
          content: map['content'],
          authorId: map['authorId'],
          authorEmail: map['authorEmail'],
          createdAt: DateTime.parse(map['createdAt']),
        );
      }).toList();
    });
  }
}
