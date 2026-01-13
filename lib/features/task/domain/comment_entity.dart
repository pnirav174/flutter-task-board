import 'package:equatable/equatable.dart';

class CommentEntity extends Equatable {
  final String id;
  final String taskId;
  final String content;
  final String authorId;
  final String authorEmail;
  final DateTime createdAt;

  const CommentEntity({
    required this.id,
    required this.taskId,
    required this.content,
    required this.authorId,
    required this.authorEmail,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
    id,
    taskId,
    content,
    authorId,
    authorEmail,
    createdAt,
  ];
}
