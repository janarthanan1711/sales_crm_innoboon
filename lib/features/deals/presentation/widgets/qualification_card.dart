import 'package:flutter/material.dart';
import '../../../../app/di/injector.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/shared_widgets.dart';
import '../../domain/entities/deal.dart';
import '../../domain/entities/scoring_dimension.dart';
import '../../domain/usecases/get_scoring_dimensions_usecase.dart';

/// The deal's D1–D8 answers: one row per dimension with its points (1 red,
/// 2 amber, 3 green) and the chosen level; hover a row for what it means.
/// Dimensions/levels come from `GET /deals/scoring-dimensions`.
class QualificationCard extends StatefulWidget {
  const QualificationCard({super.key, required this.deal});
  final Deal deal;

  @override
  State<QualificationCard> createState() => _QualificationCardState();
}

class _QualificationCardState extends State<QualificationCard> {
  List<ScoringDimension>? _dimensions;

  @override
  void initState() {
    super.initState();
    sl<GetScoringDimensionsUseCase>()().then((result) {
      if (!mounted) return;
      result.fold(
        (_) => setState(() => _dimensions = const []),
        (d) => setState(() => _dimensions = d),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final scores = widget.deal.scores;
    return SectionCard(
      title: 'Qualification',
      trailing: widget.deal.totalScore == null
          ? null
          : Text(
              'Total ${widget.deal.totalScore}',
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
      child: switch (_dimensions) {
        null => const Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
        _ when scores == null || scores.isEmpty => Text(
          'Not scored yet. Use Edit Deal to add D1–D8.',
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted),
        ),
        final dims => Column(
          children: [
            for (final (i, dim) in dims.indexed) ...[
              if (i > 0) Divider(height: 1, color: AppColors.border),
              _row(dim, scores[dim.key]),
            ],
          ],
        ),
      },
    );
  }

  Widget _row(ScoringDimension dim, String? levelKey) {
    final level = dim.levels.where((l) => l.key == levelKey).firstOrNull;
    // "Pain Intensity (CHAMP)" -> "D1 Pain Intensity".
    final name = '${dim.key} ${dim.label.split(' (').first}';
    return Tooltip(
      message: level?.description ?? '',
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 150,
              child: Text(
                name,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            if (level != null) ...[
              _ScoreDot(level.score),
              const SizedBox(width: AppSpacing.sm),
            ],
            Expanded(
              child: Text(level?.label ?? '—', style: AppTextStyles.bodyMedium),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScoreDot extends StatelessWidget {
  const _ScoreDot(this.score);
  final int score;

  @override
  Widget build(BuildContext context) {
    final color = switch (score) {
      >= 3 => AppColors.success,
      2 => AppColors.warning,
      _ => AppColors.error,
    };
    return Container(
      width: 20,
      height: 20,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Text(
        '$score',
        style: AppTextStyles.caption.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
