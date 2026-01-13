import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:take_home_assignment/features/board/data/local_board_repository.dart';
import 'package:take_home_assignment/features/board/domain/board.dart';
import 'package:take_home_assignment/features/board/domain/board_repository.dart';
import 'package:take_home_assignment/features/task/data/database_provider.dart';

final boardRepositoryProvider = Provider<BoardRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return LocalBoardRepository(db);
});

final boardListProvider = StreamProvider<List<Board>>((ref) {
  final repo = ref.watch(boardRepositoryProvider);
  return repo.watchBoards();
});
