import 'package:flutter/material.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_colors.dart';

class DocumentsPage extends StatelessWidget {
  const DocumentsPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(backgroundColor: AppColors.background, body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.description_outlined, size: 64, color: AppColors.textMuted), const SizedBox(height: 16), Text('Documents', style: AppTextStyles.h1), const SizedBox(height: 8), Text('Coming in Milestone 3', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary))])));
}
