class SymptomModel {
  final String description;
  final String severity; // 'mild', 'moderate', 'severe'
  final String duration; // e.g., '2 days', '1 week'
  final DateTime reportedAt;
  final List<String> associatedSymptoms;

  SymptomModel({
    required this.description,
    required this.severity,
    required this.duration,
    required this.reportedAt,
    this.associatedSymptoms = const [],
  });

  Map<String, dynamic> toJson() => {
    'description': description,
    'severity': severity,
    'duration': duration,
    'reportedAt': reportedAt.toIso8601String(),
    'associatedSymptoms': associatedSymptoms,
  };

  factory SymptomModel.fromJson(Map<String, dynamic> json) => SymptomModel(
    description: json['description'] as String,
    severity: json['severity'] as String,
    duration: json['duration'] as String,
    reportedAt: DateTime.parse(json['reportedAt'] as String),
    associatedSymptoms:
        (json['associatedSymptoms'] as List<dynamic>?)
            ?.map((e) => e as String)
            .toList() ??
        [],
  );

  String toPromptString() {
    return 'Symptom: $description\nSeverity: $severity\nDuration: $duration'
        '${associatedSymptoms.isNotEmpty ? '\nAssociated: ${associatedSymptoms.join(", ")}' : ''}';
  }
}
