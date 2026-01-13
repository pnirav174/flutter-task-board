import 'package:mockito/annotations.dart';
import 'package:flutter_task_board/features/task/domain/task_repository.dart';
import 'package:flutter_task_board/features/board/domain/board_repository.dart';
import 'package:flutter_task_board/core/sync_service.dart';
import 'package:flutter_task_board/features/task/data/realtime_database_repository.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_task_board/features/auth/domain/auth_repository.dart';

@GenerateMocks([
  TaskRepository,
  BoardRepository,
  AuthRepository,
  RealtimeDatabaseRepository,
  Connectivity,
  SyncService,
])
void main() {}
