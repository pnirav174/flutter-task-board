import 'package:take_home_assignment/features/board/domain/board.dart';

abstract class BoardRepository {
  Stream<List<Board>> watchBoards();
  Future<void> createBoard(String title);
  Future<void> updateBoard(Board board);
  Future<void> deleteBoard(String id);
}
