import 'package:firebase_database/firebase_database.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:take_home_assignment/core/sync_service.dart';
import 'package:take_home_assignment/features/task/data/database_provider.dart';
import 'package:take_home_assignment/features/task/data/realtime_database_repository.dart';

final realtimeDatabaseRepositoryProvider = Provider<RealtimeDatabaseRepository>(
  (ref) {
    return RealtimeDatabaseRepository(FirebaseDatabase.instance);
  },
);

final syncServiceProvider = Provider<SyncService>((ref) {
  final db = ref.watch(databaseProvider);
  final remoteRepo = ref.watch(realtimeDatabaseRepositoryProvider);
  final connectivity = Connectivity(); // Connectivity instance
  return SyncService(db, remoteRepo, connectivity);
});
