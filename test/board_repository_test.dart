import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_task_board/features/board/data/local_board_repository.dart';
import 'package:flutter_task_board/features/task/data/app_database.dart';

void main() {
  late AppDatabase db;
  late LocalBoardRepository repository;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repository = LocalBoardRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('createBoard adds a board to database and sync queue', () async {
    // Act
    await repository.createBoard('Test Board');

    // Assert
    final boards = await db.select(db.boards).get();
    expect(boards.length, 1);
    expect(boards.first.title, 'Test Board');

    final queue = await db.select(db.syncQueue).get();
    expect(queue.length, 1);
    expect(queue.first.mutationType, 'create');
    expect(queue.first.table, 'boards');
  });

  test('watchBoards emits updates', () async {
    // Act & Assert
    expectLater(repository.watchBoards(), emitsThrough(hasLength(1)));
    await repository.createBoard('Stream Board');
  });
}
