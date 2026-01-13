import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:take_home_assignment/features/task/data/database_provider.dart';
import 'package:take_home_assignment/features/task/data/local_task_repository.dart';
import 'package:take_home_assignment/features/task/domain/task_entity.dart';
import 'package:take_home_assignment/features/task/domain/task_repository.dart';

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return LocalTaskRepository(db);
});

final boardTasksProvider = StreamProvider.family<List<TaskEntity>, String>((
  ref,
  boardId,
) {
  final repo = ref.watch(taskRepositoryProvider);
  return repo.watchTasks(boardId);
});
