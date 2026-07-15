class AdminTask {
  final int? taskId;
  final String actionId;
  final String title;
  final String? description;
  final String? dueDate;
  final int isRecurring;
  final int completionStatus;

  AdminTask({
    this.taskId,
    required this.actionId,
    required this.title,
    this.description,
    this.dueDate,
    this.isRecurring = 0,
    this.completionStatus = 0,
  });

  factory AdminTask.fromMap(Map<String, dynamic> map) {
    return AdminTask(
      // Using 'num?' prevents crashes if SQLite accidentally returns a double instead of an int
      taskId: (map['task_id'] as num?)?.toInt(),
      actionId: map['action_id'].toString(),
      title: map['title'].toString(),
      description: map['description']?.toString(),
      dueDate: map['due_date']?.toString(),
      isRecurring: (map['is_recurring'] as num?)?.toInt() ?? 0,
      completionStatus: (map['completion_status'] as num?)?.toInt() ?? 0,
    );
  }
}