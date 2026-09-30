import 'package:equatable/equatable.dart';

/// One D1–D8 qualification dimension from `GET /deals/scoring-dimensions`.
/// Entirely server-driven — the app never hardcodes dimensions or scores.
class ScoringDimension extends Equatable {
  final String key;
  final String label;
  final List<ScoringLevel> levels;

  const ScoringDimension({
    required this.key,
    required this.label,
    required this.levels,
  });

  factory ScoringDimension.fromJson(Map<String, dynamic> json) =>
      ScoringDimension(
        key: json['key'] as String,
        label: json['label'] as String,
        levels: (json['levels'] as List<dynamic>)
            .map((e) => ScoringLevel.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  @override
  List<Object?> get props => [key, label, levels];
}

class ScoringLevel extends Equatable {
  final String key;
  final String label;

  /// Tooltip text ("What This Score Means").
  final String description;

  const ScoringLevel({
    required this.key,
    required this.label,
    required this.description,
  });

  factory ScoringLevel.fromJson(Map<String, dynamic> json) => ScoringLevel(
    key: json['key'] as String,
    label: json['label'] as String,
    description: json['description'] as String? ?? '',
  );

  @override
  List<Object?> get props => [key, label, description];
}
