import 'package:drift/drift.dart';
import 'package:flutter_task_board/features/board/domain/board.dart' as domain;
import 'package:flutter_task_board/features/task/data/app_database.dart'
    as drift_db;
import 'package:flutter_task_board/features/task/domain/task_entity.dart';
import 'package:flutter_task_board/features/task/domain/comment_entity.dart';

extension BoardMapper on domain.Board {
  drift_db.BoardsCompanion toCompanion() {
    return drift_db.BoardsCompanion(
      id: Value(id),
      title: Value(title),
      createdAt: Value(createdAt),
    );
  }
}

extension BoardModelMapper on drift_db.Board {
  domain.Board toEntity() {
    return domain.Board(id: id, title: title, createdAt: createdAt);
  }
}

extension TaskEntityMapper on TaskEntity {
  drift_db.TasksCompanion toCompanion() {
    return drift_db.TasksCompanion(
      id: Value(id),
      boardId: Value(boardId),
      title: Value(title),
      description: Value(description),
      status: Value(status.name),
      priority: Value(priority.name),
      dueDate: Value(dueDate),
      assigneeId: Value(assigneeId),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }
}

extension TaskModelMapper on drift_db.Task {
  TaskEntity toEntity() {
    return TaskEntity(
      id: id,
      boardId: boardId,
      title: title,
      description: description,
      status: TaskStatus.values.byName(status),
      priority: TaskPriority.values.byName(priority),
      dueDate: dueDate,
      assigneeId: assigneeId,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

extension CommentEntityMapper on CommentEntity {
  drift_db.CommentsCompanion toCompanion() {
    return drift_db.CommentsCompanion(
      id: Value(id),
      taskId: Value(taskId),
      content: Value(content),
      authorId: Value(authorId),
      authorEmail: Value(authorEmail),
      createdAt: Value(createdAt),
    );
  }
}

extension CommentModelMapper on drift_db.Comment {
  CommentEntity toEntity() {
    return CommentEntity(
      id: id,
      taskId: taskId,
      content: content,
      authorId: authorId,
      authorEmail: authorEmail,
      createdAt: createdAt,
    );
  }
}
