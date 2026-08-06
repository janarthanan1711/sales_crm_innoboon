import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_spacing.dart';

/// Tier badge widget matching Figma design
/// Displays tier name with color-coded background
/// Tier can be null for leads — returns empty SizedBox in that case
class TierBadge extends StatelessWidget {
  const TierBadge({super.key, required this.tier, this.showDot = false});

  final String? tier;
  final bool showDot;

  @override
  Widget build(BuildContext context) {
    // Return empty widget if tier is null (for leads)
    if (tier == null) {
      return const SizedBox.shrink();
    }

    final colors = _getTierColors(tier!);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.badgePaddingH,
        vertical: AppSpacing.badgePaddingV,
      ),
      decoration: BoxDecoration(
        color: colors.bg,
        borderRadius: BorderRadius.circular(AppSpacing.badgeRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDot) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: colors.text,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
          ],
          Text(
            tier!.toUpperCase(),
            style: AppTextStyles.badge.copyWith(color: colors.text),
          ),
        ],
      ),
    );
  }

  static ({Color bg, Color text}) _getTierColors(String tier) {
    switch (tier.toLowerCase()) {
      case 'strategic':
        return (
          bg: AppColors.tierStrategicBg,
          text: AppColors.tierStrategicText,
        );
      case 'diamond':
        return (bg: AppColors.tierDiamondBg, text: AppColors.tierDiamondText);
      case 'gold':
        return (bg: AppColors.tierGoldBg, text: AppColors.tierGoldText);
      case 'silver':
        return (bg: AppColors.tierSilverBg, text: AppColors.tierSilverText);
      case 'bronze':
        return (bg: AppColors.tierBronzeBg, text: AppColors.tierBronzeText);
      case 'not applicable':
        return (bg: AppColors.tierSilverBg, text: AppColors.tierSilverText);
      default:
        return (bg: AppColors.tierSilverBg, text: AppColors.tierSilverText);
    }
  }
}

/// Status badge for deal stages, lead statuses, etc.
class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.label,
    required this.backgroundColor,
    required this.textColor,
  });

  final String label;
  final Color backgroundColor;
  final Color textColor;

  /// Factory constructors for common statuses
  factory StatusBadge.dealStage(String stage) {
    final colors = _getDealStageColors(stage);
    return StatusBadge(
      label: stage.toUpperCase(),
      backgroundColor: colors.bg,
      textColor: colors.text,
    );
  }

  factory StatusBadge.leadStatus(String status) {
    final colors = _getLeadStatusColors(status);
    return StatusBadge(
      label: status,
      backgroundColor: colors.bg,
      textColor: colors.text,
    );
  }

  factory StatusBadge.priority(String priority) {
    final colors = _getPriorityColors(priority);
    return StatusBadge(
      label: priority.toUpperCase(),
      backgroundColor: colors.bg,
      textColor: colors.text,
    );
  }

  /// A user's account state (`active` / `invited` / `deactivated`), in the same
  /// pill every other Status column uses — the Admin Settings users table used
  /// to render this as a bare coloured dot plus text, which was the odd one out.
  factory StatusBadge.userStatus(String status) {
    final colors = _getUserStatusColors(status);
    return StatusBadge(
      label: status.isEmpty
          ? '—'
          : status[0].toUpperCase() + status.substring(1),
      backgroundColor: colors.bg,
      textColor: colors.text,
    );
  }

  /// Tier badge in the plain [StatusBadge] pill style (no leading dot).
  /// Reuses [TierBadge]'s tier→colour mapping so tiers stay consistent
  /// wherever they're shown.
  factory StatusBadge.tier(String tier) {
    final colors = TierBadge._getTierColors(tier);
    return StatusBadge(
      label: tier.toUpperCase(),
      backgroundColor: colors.bg,
      textColor: colors.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label, style: AppTextStyles.badge.copyWith(color: textColor)),
    );
  }

  static ({Color bg, Color text}) _getDealStageColors(String stage) {
    switch (stage.toLowerCase()) {
      case 'received requirements':
        return (bg: AppColors.tierSilverBg, text: AppColors.stageReceived);
      case 'qualified to buy':
      case 'discovery':
        return (bg: AppColors.discoveryBg, text: AppColors.discoveryText);
      case 'evaluation':
        return (bg: AppColors.tierDiamondBg, text: AppColors.stageEvaluation);
      case 'proposals':
      case 'proposal':
        return (bg: AppColors.proposalBg, text: AppColors.proposalText);
      case 'contracts':
        return (bg: AppColors.infoLight, text: AppColors.stageContract);
      case 'closed won':
      case 'won':
        return (bg: AppColors.successLight, text: AppColors.stageWon);
      case 'closed lost':
      case 'lost':
        return (bg: AppColors.errorLight, text: AppColors.stageLost);
      case 'cold deals':
      case 'cold':
        return (bg: AppColors.tierSilverBg, text: AppColors.stageCold);
      case 'negotiation':
        return (bg: AppColors.negotiationBg, text: AppColors.negotiationText);
      default:
        return (bg: AppColors.tierSilverBg, text: AppColors.textSecondary);
    }
  }

  static ({Color bg, Color text}) _getLeadStatusColors(String status) {
    // Labels match saleshub's LeadStatus enum (see lead_enums.dart).
    switch (status.toLowerCase()) {
      case 'not contacted':
        return (bg: AppColors.primaryLight, text: AppColors.primary);
      case 'attempted to contact':
        return (bg: AppColors.warningLight, text: AppColors.warning);
      case 'contacted':
        return (bg: AppColors.infoLight, text: AppColors.info);
      case 'contact in future':
        return (bg: AppColors.tierSilverBg, text: AppColors.textSecondary);
      case 'junk lead':
      case 'lost lead':
        return (bg: AppColors.errorLight, text: AppColors.error);
      default:
        return (bg: AppColors.tierSilverBg, text: AppColors.textSecondary);
    }
  }

  static ({Color bg, Color text}) _getUserStatusColors(String status) {
    // Matches saleshub's user `status` values (see doc §2.7).
    switch (status.toLowerCase()) {
      case 'active':
        return (bg: AppColors.successLight, text: AppColors.success);
      case 'invited':
        return (bg: AppColors.warningLight, text: AppColors.warning);
      case 'deactivated':
        return (bg: AppColors.errorLight, text: AppColors.error);
      default:
        return (bg: AppColors.tierSilverBg, text: AppColors.textSecondary);
    }
  }

  static ({Color bg, Color text}) _getPriorityColors(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return (bg: AppColors.errorLight, text: AppColors.error);
      case 'medium':
        return (bg: AppColors.warningLight, text: AppColors.warning);
      case 'low':
        return (bg: AppColors.successLight, text: AppColors.success);
      default:
        return (bg: AppColors.tierSilverBg, text: AppColors.textSecondary);
    }
  }
}

/// Initials avatar (NT, CS, PL etc.) as shown in Figma
class InitialsAvatar extends StatelessWidget {
  const InitialsAvatar({
    super.key,
    required this.name,
    this.size = 36,
    this.backgroundColor,
    this.textColor,
  });

  final String name;
  final double size;
  final Color? backgroundColor;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    final initials = _getInitials(name);
    final bgColor = backgroundColor ?? _getColorFromName(name);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(size / 4),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: AppTextStyles.badge.copyWith(
          color: textColor ?? Colors.white,
          fontSize: size * 0.35,
        ),
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    if (name.length >= 2) {
      return name.substring(0, 2).toUpperCase();
    }
    return name.toUpperCase();
  }

  Color _getColorFromName(String name) {
    final colors = [
      AppColors.primary,
      const Color(0xFF7C3AED),
      const Color(0xFFD97706),
      const Color(0xFF059669),
      const Color(0xFFDC2626),
      const Color(0xFF0EA5E9),
      const Color(0xFFEC4899),
      const Color(0xFF8B5CF6),
    ];
    final index = name.hashCode.abs() % colors.length;
    return colors[index];
  }
}

/// A user's photo when one is known, degrading to [InitialsAvatar] when it
/// isn't — or when the image fails to load (a stale `avatar_url` pointing at a
/// deleted file would otherwise leave a blank square).
///
/// [avatarUrl] must already be absolute; pass it through `resolveMediaUrl`
/// (with `bustCache: true`, since avatar paths are derived from the user id and
/// so don't change when the photo does).
class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.name,
    this.avatarUrl,
    this.size = 36,
  });

  final String name;
  final String? avatarUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    final fallback = InitialsAvatar(name: name, size: size);
    if (avatarUrl == null || avatarUrl!.isEmpty) return fallback;
    return ClipRRect(
      // Matches InitialsAvatar's squircle so mixed rows stay visually aligned.
      borderRadius: BorderRadius.circular(size / 4),
      child: CachedNetworkImage(
        imageUrl: avatarUrl!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        placeholder: (_, _) => fallback,
        errorWidget: (_, _, _) => fallback,
      ),
    );
  }
}

/// Owner avatar with name (small circle + name text)
class OwnerChip extends StatelessWidget {
  const OwnerChip({super.key, required this.name, this.showAvatar = true});

  final String? name;
  final bool showAvatar;

  @override
  Widget build(BuildContext context) {
    final displayName = name ?? 'Unassigned';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showAvatar) ...[
          InitialsAvatar(name: displayName, size: AppSpacing.avatarSmall),
          const SizedBox(width: AppSpacing.sm),
        ],
        Flexible(
          child: Text(
            displayName,
            style: AppTextStyles.bodyMedium,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// Empty state widget shown when lists have no data
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: AppColors.textMuted),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title,
              style: AppTextStyles.h3.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                subtitle!,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textMuted,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.xxl),
              ElevatedButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

/// Loading indicator
class AppLoadingIndicator extends StatelessWidget {
  const AppLoadingIndicator({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(
            color: AppColors.primary,
            strokeWidth: 3,
          ),
          if (message != null) ...[
            const SizedBox(height: AppSpacing.lg),
            Text(
              message!,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Error state widget with retry
class ErrorState extends StatelessWidget {
  const ErrorState({super.key, required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: AppColors.error,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              message,
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.xxl),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Search text field matching Figma design
class AppSearchField extends StatelessWidget {
  const AppSearchField({
    super.key,
    this.controller,
    this.hintText = 'Search...',
    this.onChanged,
    this.onSubmitted,
    this.width,
  });

  final TextEditingController? controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: AppSpacing.buttonHeight,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        decoration: InputDecoration(
          hintText: hintText,
          prefixIcon: const Icon(
            Icons.search,
            size: 20,
            color: AppColors.textMuted,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          filled: true,
          fillColor: AppColors.background,
        ),
        style: AppTextStyles.bodyMedium,
      ),
    );
  }
}

/// Section card with title matching Figma card style
class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    this.title,
    this.titleWidget,
    this.trailing,
    required this.child,
    this.padding,
  });

  final String? title;
  final Widget? titleWidget;
  final Widget? trailing;
  final Widget child;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null || titleWidget != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.cardPadding,
                AppSpacing.cardPadding,
                AppSpacing.cardPadding,
                AppSpacing.md,
              ),
              child: Row(
                children: [
                  titleWidget ?? Text(title!, style: AppTextStyles.h4),
                  const Spacer(),
                  ?trailing,
                ],
              ),
            ),
          Padding(
            padding:
                padding ??
                EdgeInsets.fromLTRB(
                  AppSpacing.cardPadding,
                  title != null || titleWidget != null
                      ? 0
                      : AppSpacing.cardPadding,
                  AppSpacing.cardPadding,
                  AppSpacing.cardPadding,
                ),
            child: child,
          ),
        ],
      ),
    );
  }
}

/// Stage pipeline indicator (visual stepper)
class StagePipeline extends StatelessWidget {
  const StagePipeline({
    super.key,
    required this.stages,
    required this.currentStageIndex,
    this.compact = false,
  });

  final List<String> stages;
  final int currentStageIndex;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Row(
          children: List.generate(stages.length, (index) {
            final isCompleted = index < currentStageIndex;
            final isCurrent = index == currentStageIndex;
            final isUpcoming = index > currentStageIndex;

            return Expanded(
              child: Column(
                children: [
                  Row(
                    children: [
                      if (index > 0)
                        Expanded(
                          child: Container(
                            height: 3,
                            color: isCompleted || isCurrent
                                ? AppColors.primary
                                : AppColors.border,
                          ),
                        ),
                      Container(
                        width: isCurrent ? 14 : 10,
                        height: isCurrent ? 14 : 10,
                        decoration: BoxDecoration(
                          color: isCompleted || isCurrent
                              ? AppColors.primary
                              : Colors.transparent,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isCompleted || isCurrent
                                ? AppColors.primary
                                : AppColors.border,
                            width: 2,
                          ),
                        ),
                      ),
                      if (index < stages.length - 1)
                        Expanded(
                          child: Container(
                            height: 3,
                            color: isCompleted
                                ? AppColors.primary
                                : AppColors.border,
                          ),
                        ),
                    ],
                  ),
                  if (!compact) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      stages[index],
                      style:
                          (isCurrent
                                  ? AppTextStyles.labelSmall.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w600,
                                    )
                                  : AppTextStyles.labelSmall)
                              .copyWith(
                                color: isUpcoming
                                    ? AppColors.textMuted
                                    : isCurrent
                                    ? AppColors.primary
                                    : AppColors.textSecondary,
                              ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            );
          }),
        );
      },
    );
  }
}

/// Filter chip button matching Figma filter UI
class AppFilterChip extends StatelessWidget {
  const AppFilterChip({
    super.key,
    required this.label,
    this.icon,
    this.isSelected = false,
    this.onTap,
    this.showDropdown = true,
  });

  final String label;
  final IconData? icon;
  final bool isSelected;
  final VoidCallback? onTap;
  final bool showDropdown;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryLight : AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
              const SizedBox(width: AppSpacing.xs),
            ],
            Text(
              label,
              style: AppTextStyles.labelMedium.copyWith(
                color: isSelected ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
            if (showDropdown) ...[
              const SizedBox(width: AppSpacing.xs),
              Icon(
                Icons.keyboard_arrow_down,
                size: 16,
                color: isSelected ? AppColors.primary : AppColors.textMuted,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
