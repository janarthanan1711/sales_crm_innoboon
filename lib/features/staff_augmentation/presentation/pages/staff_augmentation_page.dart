import 'package:flutter/material.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_colors.dart';

class StaffAugmentationPage extends StatelessWidget {
  const StaffAugmentationPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(backgroundColor: AppColors.background, body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.groups_outlined, size: 64, color: AppColors.textMuted), const SizedBox(height: 16), Text('Staff Augmentation', style: AppTextStyles.h1), const SizedBox(height: 8), Text('Coming in Milestone 3', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary))])));
}
