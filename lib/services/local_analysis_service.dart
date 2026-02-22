import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

/// A fully offline, rule-based clinical analysis engine.
/// Uses Symptoms.json to generate a diagnostic report without any API.
class LocalAnalysisService {
  List<Map<String, dynamic>>? _symptomDb;

  Future<void> _loadDb() async {
    if (_symptomDb != null) return;
    try {
      final raw = await rootBundle.loadString('Symptoms.json');
      final data = jsonDecode(raw);
      _symptomDb = List<Map<String, dynamic>>.from(data['symptoms']);
    } catch (e) {
      debugPrint('[LocalAnalysis] Error loading Symptoms.json: $e');
      _symptomDb = [];
    }
  }

  /// Generate a comprehensive Markdown report from selected symptoms.
  Future<String> generateReport({
    required List<String> symptoms,
    required String gender,
    required int age,
    required double temperature,
  }) async {
    await _loadDb();

    // Match selected symptoms against the database
    final matched = <Map<String, dynamic>>[];
    for (final name in symptoms) {
      final entry = _symptomDb!.firstWhere(
        (s) => s['name'].toString().toLowerCase() == name.toLowerCase(),
        orElse: () => {},
      );
      if (entry.isNotEmpty) matched.add(entry);
    }

    // Aggregate all possible conditions and count occurrences
    final conditionCount = <String, int>{};
    for (final s in matched) {
      final conditions = s['possible_conditions'] as List? ?? [];
      for (final c in conditions) {
        conditionCount[c.toString()] = (conditionCount[c.toString()] ?? 0) + 1;
      }
    }

    // Sort conditions by frequency
    final sortedConditions = conditionCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Collect unique specialists
    final specialists = matched
        .map((s) => s['specialist']?.toString() ?? '')
        .where((s) => s.isNotEmpty)
        .toSet()
        .toList();

    // Collect all unique tests
    final tests = <String>{};
    for (final s in matched) {
      final t = s['tests'] as List? ?? [];
      tests.addAll(t.map((e) => e.toString()));
    }

    // Collect all OTC suggestions
    final otc = <String>{};
    for (final s in matched) {
      final o = s['otc'] as List? ?? [];
      otc.addAll(o.map((e) => e.toString()));
    }

    // Overall risk (highest among matched)
    final riskOrder = {'High': 3, 'Medium': 2, 'Low': 1};
    int maxRisk = 0;
    String riskLabel = 'Unknown';
    for (final s in matched) {
      final r = s['risk_level']?.toString() ?? 'Low';
      final score = riskOrder[r] ?? 0;
      if (score > maxRisk) {
        maxRisk = score;
        riskLabel = r;
      }
    }

    // Temperature assessment
    String tempNote = '';
    if (temperature >= 39.5) {
      tempNote =
          '\n\n> 🌡️ **High Fever Alert:** Temperature of ${temperature.toStringAsFixed(1)}°C is significantly elevated. Seek medical attention promptly.';
    } else if (temperature >= 38.0) {
      tempNote =
          '\n\n> 🌡️ Temperature of ${temperature.toStringAsFixed(1)}°C indicates a fever. Monitor closely.';
    }

    // Age-based notes
    String ageNote = '';
    if (age < 5) {
      ageNote =
          '\n\n> 👶 **Paediatric Alert:** Child under 5 years. Symptoms warrant immediate paediatric evaluation.';
    } else if (age > 65) {
      ageNote =
          '\n\n> 👴 **Senior Alert:** Patient over 65 years. Higher risk for complications. Consult a doctor promptly.';
    }

    // Build the Markdown report
    final buffer = StringBuffer();

    buffer.writeln('## 🔍 Clinical Assessment Report');
    buffer.writeln(
      '\n**Patient Profile:** $gender, $age years old | Temp: ${temperature.toStringAsFixed(1)}°C',
    );
    buffer.writeln(
      '**Reported Symptoms (${symptoms.length}):** ${symptoms.join(', ')}',
    );
    buffer.writeln('**Estimated Risk Level:** $riskLabel');
    buffer.writeln(tempNote);
    buffer.writeln(ageNote);

    buffer.writeln('\n\n---\n\n## 📋 Possible Conditions');
    if (sortedConditions.isEmpty) {
      buffer.writeln('\n_Could not match symptoms to known conditions._');
    } else {
      for (var i = 0; i < sortedConditions.take(5).length; i++) {
        final entry = sortedConditions[i];
        final matchCount = entry.value;
        final confidence = matchCount >= 3
            ? '🔴 High match'
            : matchCount == 2
            ? '🟡 Moderate match'
            : '🟢 Possible';
        buffer.writeln(
          '\n${i + 1}. **${entry.key}** — $confidence ($matchCount symptom${matchCount > 1 ? 's' : ''} linked)',
        );
      }
    }

    buffer.writeln('\n\n---\n\n## 🩺 Recommended Specialists');
    if (specialists.isEmpty) {
      buffer.writeln('\n* General Physician');
    } else {
      for (final s in specialists) {
        buffer.writeln('\n* $s');
      }
    }

    buffer.writeln('\n\n---\n\n## 🧪 Suggested Diagnostic Tests');
    if (tests.isEmpty) {
      buffer.writeln('\n* Consult your doctor for appropriate investigations.');
    } else {
      for (final t in tests.take(8)) {
        buffer.writeln('\n* $t');
      }
    }

    buffer.writeln('\n\n---\n\n## 💊 Over-the-Counter Management');
    if (otc.isEmpty) {
      buffer.writeln('\n* Consult a doctor before taking any medication.');
    } else {
      for (final o in otc) {
        buffer.writeln('\n* $o');
      }
    }

    buffer.writeln('\n\n---');
    buffer.writeln(
      '\n> ⚠️ **Disclaimer:** This is a rule-based local assessment for informational purposes only. It is **NOT** a medical diagnosis. Please consult a licensed physician immediately for proper evaluation and treatment.',
    );

    return buffer.toString();
  }
}
