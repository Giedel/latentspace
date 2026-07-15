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
      taskId: map['task_id'] as int?,
      actionId: map['action_id'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      dueDate: map['due_date'] as String?,
      isRecurring: map['is_recurring'] as int,
      completionStatus: map['completion_status'] as int,
    );
  }
}