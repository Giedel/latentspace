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

  // Safe mappings parsing incoming raw db strings into objects
  factory CoreAiAction.fromMap(Map<String, dynamic> map) {
    return CoreAiAction(
      actionId: map['action_id'].toString(),
      rawUserInput: map['raw_user_input'].toString(),
      inferredDomain: map['inferred_domain'].toString(),
      executionStrategy: map['execution_strategy'].toString(),
      jsonPayload: Map<String, dynamic>.from(jsonDecode(map['json_payload'].toString())),
      status: map['status'].toString(),
      createdAt: DateTime.parse(map['created_at'].toString()),
    );
  }

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
      createdAt: createdAt ?? this.createdAt,
    );
  }
}