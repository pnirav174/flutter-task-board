import 'package:flutter_task_board/features/task/domain/task_entity.dart';
import 'package:flutter_task_board/features/task/domain/comment_entity.dart';

abstract class TaskRepository {
  Stream<List<TaskEntity>> watchTasks(String boardId);
  Future<void> createTask(TaskEntity task);
  Future<void> updateTask(TaskEntity task);
  Future<void> deleteTask(String id);

  // Comments
  Stream<List<CommentEntity>> watchComments(String taskId);
  Future<void> addComment(CommentEntity comment);
}
