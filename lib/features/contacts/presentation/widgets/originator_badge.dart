import 'package:flutter/material.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Marks a contact flagged "Is Originator". [compact] is the small ORIGINATOR
/// tag used in rows; the default is the larger pill for a detail header.
class OriginatorBadge extends StatelessWidget {
  const OriginatorBadge({super.key, this.compact = true});
  final bool compact;

  static const _color = Color(0xFF7C3AED);

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: _color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          'ORIGINATOR',
          style: AppTextStyles.caption.copyWith(
            color: _color,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.share_outlined, size: 12, color: _color),
          const SizedBox(width: 4),
          Text(
            'Originator',
            style: AppTextStyles.caption.copyWith(
              color: _color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
