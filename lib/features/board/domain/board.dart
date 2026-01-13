import 'package:equatable/equatable.dart';

class Board extends Equatable {
  final String id;
  final String title;
  final DateTime createdAt;

  const Board({required this.id, required this.title, required this.createdAt});

  @override
  List<Object?> get props => [id, title, createdAt];
}
