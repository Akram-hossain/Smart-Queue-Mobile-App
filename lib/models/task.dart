import 'enums.dart';

class TaskItem {
  final String id;
  final String userId;
  final String title;
  final String? description;
  final TaskType type;
  final DateTime dueDate;
  final TaskPriority priority;
  final TaskStatus status;
  final DateTime createdAt;

  const TaskItem({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    required this.type,
    required this.dueDate,
    required this.priority,
    required this.status,
    required this.createdAt,
  });

  factory TaskItem.fromMap(Map<String, dynamic> map) => TaskItem(
        id: map['id'] as String,
        userId: map['user_id'] as String,
        title: map['title'] as String,
        description: map['description'] as String?,
        type: TaskType.fromDb(map['type'] as String),
        // Supabase stores timestamptz; DateTime.parse keeps UTC if the
        // string ends in Z. Convert to local so display uses the user's
        // timezone instead of UTC.
        dueDate: DateTime.parse(map['due_date'] as String).toLocal(),
        priority: TaskPriority.fromDb(map['priority'] as String),
        status: TaskStatus.fromDb(map['status'] as String),
        createdAt: (DateTime.tryParse(map['created_at']?.toString() ?? '') ??
                DateTime.now())
            .toLocal(),
      );

  Map<String, dynamic> toInsertMap(String userId) => {
        'user_id': userId,
        'title': title,
        'description': description,
        'type': type.dbValue,
        'due_date': dueDate.toUtc().toIso8601String(),
        'priority': priority.dbValue,
        'status': status.dbValue,
      };

  Map<String, dynamic> toUpdateMap() => {
        'title': title,
        'description': description,
        'type': type.dbValue,
        'due_date': dueDate.toUtc().toIso8601String(),
        'priority': priority.dbValue,
        'status': status.dbValue,
      };

  TaskItem copyWith({
    String? title,
    String? description,
    TaskType? type,
    DateTime? dueDate,
    TaskPriority? priority,
    TaskStatus? status,
  }) =>
      TaskItem(
        id: id,
        userId: userId,
        title: title ?? this.title,
        description: description ?? this.description,
        type: type ?? this.type,
        dueDate: dueDate ?? this.dueDate,
        priority: priority ?? this.priority,
        status: status ?? this.status,
        createdAt: createdAt,
      );

  bool get isOverdue =>
      status != TaskStatus.completed && dueDate.isBefore(DateTime.now());
}
