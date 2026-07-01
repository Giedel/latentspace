import 'dart:convert';

class CoreAiAction {
  final String actionId;
  final String rawUserInput;
  final String inferredDomain;
  final String executionStrategy;
  final Map<String, dynamic> jsonPayload;
  final String status;
  final DateTime createdAt;

  CoreAiAction({
    required this.actionId,
    required this.rawUserInput,
    required this.inferredDomain,
    required this.executionStrategy,
    required this.jsonPayload,
    required this.status,
    required this.createdAt,
  });

  // Factory constructor to create a Dart object from SQLite row map.
  // It automatically decodes the JSON string and parses the timestamp.
  factory CoreAiAction.fromMap(Map<String, dynamic> map) {
    return CoreAiAction(
      actionId: map['action_id'] as String,
      rawUserInput: map['raw_user_input'] as String,
      inferredDomain: map['inferred_domain'] as String,
      executionStrategy: map['execution_strategy'] as String,
      jsonPayload: jsonDecode(map['json_payload'] as String) as Map<String, dynamic>,
      status: map['status'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  // Converts the Dart object back into a map for SQLite insertion.
  // It encodes the JSON map back to a string and converts the DateTime to ISO-8601.
  Map<String, dynamic> toMap() {
    return {
      'action_id': actionId,
      'raw_user_input': rawUserInput,
      'inferred_domain': inferredDomain,
      'execution_strategy': executionStrategy,
      'json_payload': jsonEncode(jsonPayload),
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // A helper method to easily create a modified copy of an action.
  // This is extremely useful for Riverpod state immutability when updating statuses.
  CoreAiAction copyWith({
    String? actionId,
    String? rawUserInput,
    String? inferredDomain,
    String? executionStrategy,
    Map<String, dynamic>? jsonPayload,
    String? status,
    DateTime? createdAt,
  }) {
    return CoreAiAction(
      actionId: actionId ?? this.actionId,
      rawUserInput: rawUserInput ?? this.rawUserInput,
      inferredDomain: inferredDomain ?? this.inferredDomain,
      executionStrategy: executionStrategy ?? this.executionStrategy,
      jsonPayload: jsonPayload ?? this.jsonPayload,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt
    );
  }
}