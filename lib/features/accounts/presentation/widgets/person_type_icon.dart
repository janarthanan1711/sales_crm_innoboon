import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Marks a [SourcePerson] as a platform User or a Contact.
class PersonTypeIcon extends StatelessWidget {
  final String type;
  const PersonTypeIcon(this.type, {super.key});

  @override
  Widget build(BuildContext context) {
    final isUser = type == 'user';
    return Tooltip(
      message: isUser ? 'User' : 'Contact',
      child: Icon(
        isUser ? Icons.badge_outlined : Icons.contact_page_outlined,
        size: 16,
        color: isUser ? AppColors.primary : AppColors.textSecondary,
      ),
    );
  }
}
