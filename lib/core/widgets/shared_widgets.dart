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
    this.showDot = false,
  });

  final String label;
  final Color backgroundColor;
  final Color textColor;

  /// Leading colour dot, used by stage/status pills.
  final bool showDot;

  /// Factory constructors for common statuses
  factory StatusBadge.dealStage(String stage) {
    final colors = _getDealStageColors(stage);
    return StatusBadge(
      label: stage,
      backgroundColor: colors.bg,
      textColor: colors.text,
      showDot: true,
    );
  }

  factory StatusBadge.leadStatus(String status) {
    final colors = _getLeadStatusColors(status);
    return StatusBadge(
      label: status,
      backgroundColor: colors.bg,
      textColor: colors.text,
      showDot: true,
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
        horizontal: AppSpacing.badgePaddingH,
        vertical: AppSpacing.badgePaddingV,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppSpacing.badgeRadius),
      ),
      // One Text.rich (dot as a WidgetSpan) rather than a Row: it ellipsizes
      // inside narrow table columns, sizes naturally under unbounded width,
      // and still supports intrinsic sizing — a Row+Flexible can't do all 3.
      child: Text.rich(
        TextSpan(
          children: [
            if (showDot)
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: textColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            TextSpan(text: label),
          ],
        ),
        style: AppTextStyles.badge.copyWith(color: textColor),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  static ({Color bg, Color text}) _getDealStageColors(String stage) {
    switch (stage.toLowerCase()) {
      case 'received requirements':
        return (bg: AppColors.stageReceivedBg, text: AppColors.stageReceived);
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
        return (bg: AppColors.stageColdBg, text: AppColors.stageCold);
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
    // Deal priority (Mode A–D): Very High / High / Medium / Low.
    switch (priority.toLowerCase()) {
      case 'very high':
        return (bg: AppColors.errorLight, text: AppColors.error);
      case 'high':
        return (bg: AppColors.warningLight, text: AppColors.warning);
      case 'medium':
        return (bg: AppColors.infoLight, text: AppColors.info);
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
    final hue = _getColorFromName(name);
    // Soft tint + coloured initials by default; callers can still force a
    // solid fill via [backgroundColor]/[textColor].
    final bgColor =
        backgroundColor ??
        hue.withValues(alpha: AppColors.isDark ? 0.25 : 0.12);
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
          color: textColor ?? (backgroundColor != null ? Colors.white : hue),
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
          ClipOval(
            child: InitialsAvatar(
              name: displayName,
              size: AppSpacing.avatarSmall - 4,
            ),
          ),
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
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 28, color: AppColors.primary),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(title, style: AppTextStyles.h4, textAlign: TextAlign.center),
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
          CircularProgressIndicator(color: AppColors.primary, strokeWidth: 3),
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
            Icon(Icons.error_outline_rounded, size: 64, color: AppColors.error),
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
          prefixIcon: Icon(Icons.search, size: 20, color: AppColors.textMuted),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
            borderSide: BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
            borderSide: BorderSide(color: AppColors.border),
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
      decoration: appCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null || titleWidget != null)
            Container(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.cardPadding,
                AppSpacing.lg,
                AppSpacing.cardPadding,
                AppSpacing.lg,
              ),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AppColors.borderLight),
                ),
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
                const EdgeInsets.fromLTRB(
                  AppSpacing.cardPadding,
                  AppSpacing.cardPadding,
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

// ─── Modern layout building blocks (2026 revamp) ──────────────────────────

/// Standard white surface: rounded, hairline border, soft shadow.
BoxDecoration appCardDecoration({double? radius}) => BoxDecoration(
  color: AppColors.cardBackground,
  borderRadius: BorderRadius.circular(radius ?? AppSpacing.cardRadius),
  border: Border.all(color: AppColors.border),
  boxShadow: [
    BoxShadow(
      color: AppColors.shadow,
      blurRadius: 12,
      offset: const Offset(0, 2),
    ),
  ],
);

/// Page title block: large bold title, optional muted subtitle, actions right.
/// Stacks the actions under the title on narrow screens.
class PageHeader extends StatelessWidget {
  const PageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.titleTrailing,
    this.actions = const [],
  });

  final String title;
  final String? subtitle;

  /// Sits right after the title (e.g. a view toggle).
  final Widget? titleTrailing;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final heading = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                title,
                style: AppTextStyles.displayMedium,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (titleTrailing != null) ...[
              const SizedBox(width: AppSpacing.lg),
              titleTrailing!,
            ],
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            subtitle!,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ],
    );
    return LayoutBuilder(
      builder: (context, c) {
        if (c.maxWidth < 720) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              heading,
              if (actions.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: actions,
                ),
              ],
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: heading),
            for (var i = 0; i < actions.length; i++) ...[
              if (i > 0) const SizedBox(width: AppSpacing.sm),
              actions[i],
            ],
          ],
        );
      },
    );
  }
}

/// KPI tile: uppercase label + status dot, big value, caption line.
class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.label,
    required this.value,
    this.caption,
    this.captionTrailing,
    this.dotColor,
    this.onTap,
  });

  final String label;
  final String value;
  final String? caption;

  /// Right-aligned note on the caption line (e.g. "70%").
  final Widget? captionTrailing;
  final Color? dotColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        child: Ink(
          decoration: appCardDecoration(),
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      label.toUpperCase(),
                      style: AppTextStyles.tableHeader,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (dotColor != null)
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: dotColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(value, style: AppTextStyles.displayMedium),
              ),
              if (caption != null || captionTrailing != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        caption ?? '',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    ?captionTrailing,
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Lays [StatCard]s out on a single line: evenly when there's room, else a
/// sideways-scrolling strip of fixed-width cards. Never wraps — wrapping to
/// 2–3 rows on laptop widths pushed the list below it off-screen. Hidden
/// entirely on short viewports for the same reason.
class StatCardRow extends StatelessWidget {
  const StatCardRow({super.key, required this.cards});
  final List<Widget> cards;

  static const double _minCardWidth = 200;
  static const double _minViewportHeight = 640;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.sizeOf(context).height < _minViewportHeight) {
      return const SizedBox.shrink();
    }
    const gap = AppSpacing.lg;
    return LayoutBuilder(
      builder: (context, c) {
        final even = (c.maxWidth - gap * (cards.length - 1)) / cards.length;
        final w = even >= _minCardWidth ? even : _minCardWidth;
        final row = Row(
          children: [
            for (var i = 0; i < cards.length; i++) ...[
              if (i > 0) const SizedBox(width: gap),
              SizedBox(width: w, child: cards[i]),
            ],
          ],
        );
        if (even >= _minCardWidth) return row;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          // Room for the cards' shadow, which a scroll view would clip.
          padding: const EdgeInsets.only(bottom: 4),
          clipBehavior: Clip.none,
          child: row,
        );
      },
    );
  }
}

/// White card wrapping a list/table: optional title bar, a grey column-header
/// strip, then the rows. Clips its children to the rounded corners.
///
/// When the card is narrower than [minWidth], the header strip and rows scroll
/// sideways together (with a visible scrollbar) while the title bar stays put
/// — so flex columns never get crushed on tablets and small laptops.
class TableCard extends StatefulWidget {
  const TableCard({
    super.key,
    this.title,
    this.trailing,
    required this.header,
    required this.body,
    this.footer,
    this.minWidth,
  });

  final String? title;
  final Widget? trailing;

  /// The column-header row content (laid out by the caller).
  final Widget header;
  final Widget body;
  final Widget? footer;

  /// Narrowest the columns may get before the table scrolls horizontally.
  final double? minWidth;

  @override
  State<TableCard> createState() => _TableCardState();
}

class _TableCardState extends State<TableCard> {
  final _hScroll = ScrollController();

  @override
  void dispose() {
    _hScroll.dispose();
    super.dispose();
  }

  bool get _hasTitle => widget.title != null || widget.trailing != null;

  Widget _columns() => Column(
    children: [
      Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: AppColors.background,
          border: Border(
            top: _hasTitle
                ? BorderSide(color: AppColors.borderLight)
                : BorderSide.none,
            bottom: BorderSide(color: AppColors.borderLight),
          ),
        ),
        child: widget.header,
      ),
      Expanded(child: widget.body),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: appCardDecoration(),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          if (_hasTitle)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl,
                vertical: AppSpacing.lg,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: widget.title == null
                        ? const SizedBox.shrink()
                        : Text(
                            widget.title!,
                            style: AppTextStyles.h4,
                            overflow: TextOverflow.ellipsis,
                          ),
                  ),
                  if (widget.trailing != null) ...[
                    const SizedBox(width: AppSpacing.md),
                    widget.trailing!,
                  ],
                ],
              ),
            ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, c) {
                final min = widget.minWidth;
                if (min == null || c.maxWidth >= min) return _columns();
                return Scrollbar(
                  controller: _hScroll,
                  thumbVisibility: true,
                  child: SingleChildScrollView(
                    controller: _hScroll,
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(width: min, child: _columns()),
                  ),
                );
              },
            ),
          ),
          if (widget.footer != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl,
                vertical: AppSpacing.md,
              ),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.borderLight)),
              ),
              child: widget.footer,
            ),
        ],
      ),
    );
  }
}

/// Two-line table cell: bold primary text over a muted caption.
class TwoLineCell extends StatelessWidget {
  const TwoLineCell({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.titleStyle,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final TextStyle? titleStyle;

  @override
  Widget build(BuildContext context) {
    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style:
              titleStyle ??
              AppTextStyles.tableCell.copyWith(fontWeight: FontWeight.w600),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        if (subtitle != null && subtitle!.isNotEmpty)
          Text(
            subtitle!,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
      ],
    );
    if (leading == null) return text;
    return Row(
      children: [
        leading!,
        const SizedBox(width: AppSpacing.md),
        Flexible(child: text),
      ],
    );
  }
}

/// Label-over-value field grid (two columns on wide screens), each cell
/// separated by a hairline — the "Deal Information" look.
class InfoGrid extends StatelessWidget {
  const InfoGrid({super.key, required this.items, this.columns = 2});

  final List<(String, Widget)> items;
  final int columns;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final cols = c.maxWidth < 520 ? 1 : columns;
        const gap = AppSpacing.xxl;
        final w = (c.maxWidth - gap * (cols - 1)) / cols;
        return Wrap(
          spacing: gap,
          children: [
            for (final (label, value) in items)
              Container(
                width: w,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: AppColors.borderLight),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: AppTextStyles.labelMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    DefaultTextStyle.merge(
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      child: value,
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Compact pipeline progress: numbered chip + "Step x of n", then one rounded
/// segment per stage with a tiny label beneath. Matches the deal-detail mock.
class SegmentedStageBar extends StatelessWidget {
  const SegmentedStageBar({
    super.key,
    required this.stages,
    required this.currentIndex,
    this.label = 'Pipeline stage',
  });

  final List<String> stages;

  /// -1 when the current stage isn't in [stages].
  final int currentIndex;
  final String label;

  @override
  Widget build(BuildContext context) {
    final current = currentIndex >= 0 ? stages[currentIndex] : null;
    final summary = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            currentIndex >= 0 ? '${currentIndex + 1}' : '–',
            style: AppTextStyles.labelLarge.copyWith(
              color: AppColors.onAccent,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label.toUpperCase(), style: AppTextStyles.tableHeader),
                if (current != null) ...[
                  const SizedBox(width: AppSpacing.sm),
                  StatusBadge(
                    label: current,
                    backgroundColor: AppColors.primaryLight,
                    textColor: AppColors.primary,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 2),
            Text(
              currentIndex >= 0
                  ? 'Step ${currentIndex + 1} of ${stages.length} in the pipeline'
                  : 'Outside the main pipeline',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
    final bar = Row(
      children: [
        for (var i = 0; i < stages.length; i++) ...[
          if (i > 0) const SizedBox(width: 4),
          Expanded(
            child: Tooltip(
              message: stages[i],
              child: Column(
                children: [
                  Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: i <= currentIndex
                          ? AppColors.primary
                          : AppColors.border,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    stages[i],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.caption.copyWith(
                      fontSize: 10.5,
                      color: i == currentIndex
                          ? AppColors.primary
                          : AppColors.textMuted,
                      fontWeight: i == currentIndex
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: LayoutBuilder(
        builder: (context, c) => c.maxWidth < 640
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  summary,
                  const SizedBox(height: AppSpacing.lg),
                  bar,
                ],
              )
            : Row(
                children: [
                  summary,
                  const SizedBox(width: AppSpacing.xxl),
                  Expanded(child: bar),
                ],
              ),
      ),
    );
  }
}

/// Uppercase label over a value — the stats strip under a record header.
class MetaStat extends StatelessWidget {
  const MetaStat({super.key, required this.label, required this.value});
  final String label;
  final Widget value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label.toUpperCase(), style: AppTextStyles.tableHeader),
        const SizedBox(height: 6),
        DefaultTextStyle.merge(
          style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w500),
          child: value,
        ),
      ],
    );
  }
}
