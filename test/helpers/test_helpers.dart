import 'package:mockito/annotations.dart';
import 'package:take_home_assignment/features/task/domain/task_repository.dart';
import 'package:take_home_assignment/features/board/domain/board_repository.dart';
import 'package:take_home_assignment/core/sync_service.dart';
import 'package:take_home_assignment/features/task/data/realtime_database_repository.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:take_home_assignment/features/auth/domain/auth_repository.dart';

@GenerateMocks([
  TaskRepository,
  BoardRepository,
  AuthRepository,
  RealtimeDatabaseRepository,
  Connectivity,
  SyncService,
])
void main() {}
