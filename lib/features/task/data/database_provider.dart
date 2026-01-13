import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:take_home_assignment/features/task/data/app_database.dart';
import 'package:take_home_assignment/features/task/data/connection/connection.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase(openConnection());
  ref.onDispose(db.close);
  return db;
});
