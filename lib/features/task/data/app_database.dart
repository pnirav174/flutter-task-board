import 'package:drift/drift.dart';
import 'package:take_home_assignment/features/task/data/app_database.tables.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Boards, Tasks, SyncQueue, Comments])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 2;
}
