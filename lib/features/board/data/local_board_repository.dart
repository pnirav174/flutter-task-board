import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:take_home_assignment/features/board/domain/board.dart'
    as domain;
import 'package:take_home_assignment/features/board/domain/board_repository.dart';
import 'package:take_home_assignment/features/task/data/app_database.dart';
import 'package:take_home_assignment/core/mappers.dart';
import 'package:uuid/uuid.dart';

class LocalBoardRepository implements BoardRepository {
  final AppDatabase _db;

  LocalBoardRepository(this._db);

  @override
  Stream<List<domain.Board>> watchBoards() {
    return _db.select(_db.boards).watch().map((rows) {
      return rows.map((row) => row.toEntity()).toList();
    });
  }

  @override
  Future<void> createBoard(String title) async {
    final id = const Uuid().v4();
    final board = domain.Board(id: id, title: title, createdAt: DateTime.now());

    await _db.transaction(() async {
      await _db.into(_db.boards).insert(board.toCompanion());

      // Add to Sync Queue
      await _db
          .into(_db.syncQueue)
          .insert(
            SyncQueueCompanion(
              mutationType: const Value('create'),
              table: const Value('boards'),
              data: Value(
                jsonEncode({
                  'id': board.id,
                  'title': board.title,
                  'createdAt': board.createdAt.toIso8601String(),
                }),
              ),
              createdAt: Value(DateTime.now()),
            ),
          );
    });
  }

  @override
  Future<void> updateBoard(domain.Board board) async {
    await _db.transaction(() async {
      await _db.update(_db.boards).replace(board.toCompanion());

      await _db
          .into(_db.syncQueue)
          .insert(
            SyncQueueCompanion(
              mutationType: const Value('update'),
              table: const Value('boards'),
              data: Value(
                jsonEncode({
                  'id': board.id,
                  'title': board.title,
                  'createdAt': board.createdAt.toIso8601String(),
                }),
              ),
              createdAt: Value(DateTime.now()),
            ),
          );
    });
  }

  @override
  Future<void> deleteBoard(String id) async {
    await _db.transaction(() async {
      await (_db.delete(_db.boards)..where((tbl) => tbl.id.equals(id))).go();

      await _db
          .into(_db.syncQueue)
          .insert(
            SyncQueueCompanion(
              mutationType: const Value('delete'),
              table: const Value('boards'),
              data: Value(jsonEncode({'id': id})),
              createdAt: Value(DateTime.now()),
            ),
          );
    });
  }
}
