class DiagnosisModel {
  final String conversation;
  final List<PossibleCondition> possibleConditions;
  final String severityLevel; // 'low', 'medium', 'high', 'emergency'
  final List<String> recommendedActions;
  final List<String> suggestedMedicines;
  final String aiResponse;
  final DateTime timestamp;

  DiagnosisModel({
    required this.conversation,
    required this.possibleConditions,
    required this.severityLevel,
    required this.recommendedActions,
    required this.suggestedMedicines,
    required this.aiResponse,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'conversation': conversation,
    'possibleConditions': possibleConditions.map((c) => c.toJson()).toList(),
    'severityLevel': severityLevel,
    'recommendedActions': recommendedActions,
    'suggestedMedicines': suggestedMedicines,
    'aiResponse': aiResponse,
    'timestamp': timestamp.toIso8601String(),
  };

  factory DiagnosisModel.fromJson(Map<String, dynamic> json) => DiagnosisModel(
    conversation: json['conversation'] as String,
    possibleConditions: (json['possibleConditions'] as List<dynamic>)
        .map((c) => PossibleCondition.fromJson(c as Map<String, dynamic>))
        .toList(),
    severityLevel: json['severityLevel'] as String,
    recommendedActions: (json['recommendedActions'] as List<dynamic>)
        .map((e) => e as String)
        .toList(),
    suggestedMedicines: (json['suggestedMedicines'] as List<dynamic>)
        .map((e) => e as String)
        .toList(),
    aiResponse: json['aiResponse'] as String,
    timestamp: DateTime.parse(json['timestamp'] as String),
  );
}

class PossibleCondition {
  final String name;
  final String likelihood; // 'high', 'medium', 'low'
  final String description;

  PossibleCondition({
    required this.name,
    required this.likelihood,
    required this.description,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'likelihood': likelihood,
    'description': description,
  };

  factory PossibleCondition.fromJson(Map<String, dynamic> json) =>
      PossibleCondition(
        name: json['name'] as String,
        likelihood: json['likelihood'] as String,
        description: json['description'] as String,
      );
}
