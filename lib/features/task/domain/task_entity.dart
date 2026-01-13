import 'package:equatable/equatable.dart';

enum TaskStatus { todo, inProgress, done }

enum TaskPriority { low, medium, high }

class TaskEntity extends Equatable {
  final String id;
  final String boardId;
  final String title;
  final String description;
  final TaskStatus status;
  final TaskPriority priority;
  final DateTime? dueDate;
  final String? assigneeId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TaskEntity({
    required this.id,
    required this.boardId,
    required this.title,
    required this.description,
    required this.status,
    required this.priority,
    this.dueDate,
    this.assigneeId,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
    id,
    boardId,
    title,
    description,
    status,
    priority,
    dueDate,
    assigneeId,
    createdAt,
    updatedAt,
  ];
}
