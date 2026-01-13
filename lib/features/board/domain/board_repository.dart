import 'package:flutter_task_board/features/board/domain/board.dart';

abstract class BoardRepository {
  Stream<List<Board>> watchBoards();
  Future<void> createBoard(String title);
  Future<void> updateBoard(Board board);
  Future<void> deleteBoard(String id);
}
