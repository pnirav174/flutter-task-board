import 'package:drift/drift.dart';

class Boards extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class Tasks extends Table {
  TextColumn get id => text()();
  TextColumn get boardId => text().references(Boards, #id)();
  TextColumn get title => text()();
  TextColumn get description => text()();
  TextColumn get status => text()(); // 'todo', 'in_progress', 'done'
  TextColumn get priority => text()(); // 'low', 'medium', 'high'
  DateTimeColumn get dueDate => dateTime().nullable()();
  TextColumn get assigneeId => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class Comments extends Table {
  TextColumn get id => text()();
  TextColumn get taskId => text().references(Tasks, #id)();
  TextColumn get content => text()();
  TextColumn get authorId => text()();
  TextColumn get authorEmail => text()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

// Queue for offline mutations
class SyncQueue extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get mutationType => text()(); // 'create', 'update', 'delete'
  TextColumn get table => text()(); // 'boards', 'tasks'
  TextColumn get data => text()(); // JSON payload
  DateTimeColumn get createdAt => dateTime()();
}
