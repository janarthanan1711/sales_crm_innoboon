import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/formatters.dart' show DateFormatter;
import '../../../../core/widgets/shared_widgets.dart';
import '../../domain/entities/deal.dart';
import '../../domain/entities/deal_stage_def.dart';
import '../bloc/deals_list_bloc.dart';
import '../pages/create_deal_page.dart';

const String _cancelled = '__cancelled__';

/// Accent colours for the column status dots, cycled by stage order. Theme
/// tokens (not hex) so they lift correctly in dark mode.
List<Color> get _kStageDotColors => [
  AppColors.stageReceived,
  AppColors.stageQualified,
  AppColors.stageEvaluation,
  AppColors.warning,
  AppColors.stageContract,
  AppColors.stageWon,
  AppColors.stageLost,
  AppColors.stageCold,
];

/// Result of the move dialog: cancelled, or a confirmed (note, coldReason).
class _MoveResult {
  final String? note;
  final String? coldReason;
  const _MoveResult({this.note, this.coldReason});
}

Future<_MoveResult?> _showMoveDialog(
  BuildContext context,
  Deal deal,
  DealStageDef target,
) async {
  final noteController = TextEditingController();
  final coldController = TextEditingController();
  final needsReason = dealStageRequiresReason(target);
  final result = await showDialog<Object>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text('Move "${deal.name}" to ${target.name}?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (needsReason)
            TextField(
              controller: coldController,
              decoration: InputDecoration(
                labelText: 'Reason *',
                helperText: 'Required when moving to ${target.name}',
                border: const OutlineInputBorder(),
              ),
            ),
          if (needsReason) const SizedBox(height: AppSpacing.md),
          TextField(
            controller: noteController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Note (optional)',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(_cancelled),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (needsReason && coldController.text.trim().isEmpty) return;
            Navigator.of(dialogContext).pop(
              _MoveResult(
                note: noteController.text.trim().isEmpty
                    ? null
                    : noteController.text.trim(),
                coldReason: coldController.text.trim().isEmpty
                    ? null
                    : coldController.text.trim(),
              ),
            );
          },
          child: const Text('Move'),
        ),
      ],
    ),
  );
  if (result == null || result == _cancelled) return null;
  return result as _MoveResult;
}

class KanbanBoard extends StatelessWidget {
  const KanbanBoard({
    super.key,
    required this.deals,
    required this.stages,
    this.canManage = true,
  });
  final List<Deal> deals;
  final List<DealStageDef> stages;

  /// When false (user lacks `deals.access`), cards are not draggable and
  /// drop targets reject moves — the board is view-only.
  final bool canManage;

  @override
  Widget build(BuildContext context) {
    final knownStageIds = stages.map((s) => s.id).toSet();
    // Deals whose `stage_id` matches no stage in the catalog — e.g. a stage
    // that was deleted, or one belonging to another company. Without a home
    // column they used to vanish from the board silently, so they get a
    // trailing column that only exists when there are any.
    final orphans = deals
        .where((d) => !knownStageIds.contains(d.stageId))
        .toList(growable: false);

    final accents = _kStageDotColors;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < stages.length; i++)
            _KanbanColumn(
              stage: stages[i],
              deals: deals.where((d) => d.stageId == stages[i].id).toList(),
              canManage: canManage,
              accent: accents[i % accents.length],
            ),
          if (orphans.isNotEmpty)
            _KanbanColumn(
              stage: const DealStageDef(
                id: -1,
                companyId: 0,
                name: 'Unknown stage',
                sortOrder: 9999,
              ),
              deals: orphans,
              // Nothing can be dropped into a stage that doesn't exist.
              canManage: false,
              accent: AppColors.textMuted,
            ),
        ],
      ),
    );
  }
}

class _KanbanColumn extends StatelessWidget {
  const _KanbanColumn({
    required this.stage,
    required this.deals,
    required this.canManage,
    required this.accent,
  });
  final DealStageDef stage;
  final List<Deal> deals;
  final bool canManage;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final double totalValue = deals.fold(0, (sum, deal) => sum + deal.value);

    return DragTarget<Deal>(
      onWillAcceptWithDetails: (details) =>
          canManage && details.data.stageId != stage.id,
      onAcceptWithDetails: (details) async {
        final bloc = context.read<DealsListBloc>();
        final move = await _showMoveDialog(context, details.data, stage);
        if (move == null) return;
        bloc.add(
          DealsListStageUpdated(
            dealId: details.data.id,
            newStageId: stage.id,
            note: move.note,
            coldReason: move.coldReason,
          ),
        );
      },
      builder: (context, candidateData, rejectedData) {
        final hovering = candidateData.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 300,
          margin: const EdgeInsets.only(right: AppSpacing.lg),
          decoration: BoxDecoration(
            color: hovering ? AppColors.primaryLight : AppColors.borderLight,
            borderRadius: BorderRadius.circular(AppSpacing.cardRadiusLarge),
            border: Border.all(
              color: hovering ? AppColors.primary : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Column header — dot + stage name + count, stage total below.
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.sm,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: accent,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            stage.name,
                            style: AppTextStyles.labelLarge.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.cardBackground,
                            borderRadius: BorderRadius.circular(
                              AppSpacing.badgeRadius,
                            ),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Text(
                            '${deals.length}',
                            style: AppTextStyles.badge.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: Text(
                        CurrencyFormatter.formatINR(totalValue),
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // A fixed-height scroll area so empty columns are still valid
              // drop targets.
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.xs,
                    AppSpacing.md,
                    AppSpacing.md,
                  ),
                  itemCount: deals.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.md),
                  itemBuilder: (context, index) {
                    final deal = deals[index];
                    void open() => context.go('/deals/${deal.id}');
                    if (!canManage) {
                      return _DealCard(
                        key: ValueKey('deal-${deal.id}'),
                        deal: deal,
                        onTap: open,
                        canManage: false,
                      );
                    }
                    // Keyed by deal id, not list position. Dragging a card to
                    // another column reorders both lists, and without a key
                    // Flutter matches the rebuilt items by index — so the
                    // Draggable's own "am I being dragged" state, and the
                    // card's, could stay attached to whatever deal now sits at
                    // that index, leaving a card stuck rendering its
                    // half-transparent childWhenDragging placeholder.
                    return Draggable<Deal>(
                      key: ValueKey('deal-drag-${deal.id}'),
                      data: deal,
                      feedback: Material(
                        elevation: 12,
                        color: Colors.transparent,
                        shadowColor: AppColors.shadow,
                        borderRadius: BorderRadius.circular(
                          AppSpacing.cardRadius,
                        ),
                        child: SizedBox(
                          width: 276,
                          child: _DealCard(deal: deal, canManage: canManage),
                        ),
                      ),
                      childWhenDragging: Opacity(
                        opacity: 0.5,
                        child: _DealCard(deal: deal, canManage: canManage),
                      ),
                      child: _DealCard(
                        deal: deal,
                        onTap: open,
                        canManage: canManage,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DealCard extends StatefulWidget {
  const _DealCard({
    super.key,
    required this.deal,
    this.onTap,
    this.canManage = false,
  });
  final Deal deal;
  final VoidCallback? onTap;
  final bool canManage;

  @override
  State<_DealCard> createState() => _DealCardState();
}

class _DealCardState extends State<_DealCard> {
  bool _hover = false;

  Deal get deal => widget.deal;

  /// Days until expected close (negative = overdue); null without a date.
  int? get _daysLeft {
    final close = deal.expectedCloseDate;
    if (close == null) return null;
    final now = DateTime.now();
    return DateTime(
      close.year,
      close.month,
      close.day,
    ).difference(DateTime(now.year, now.month, now.day)).inDays;
  }

  /// Due within 10 days (or overdue) — flagged with a red date chip.
  bool get _dueSoon => (_daysLeft ?? 999) <= 10;

  void _openDetail() => context.go('/deals/${deal.id}');

  Future<void> _edit() async {
    final bloc = context.read<DealsListBloc>();
    final result = await showDialog(
      context: context,
      builder: (_) => CreateDealDialog(deal: deal),
    );
    if (result != null) bloc.add(const DealsListLoadRequested());
  }

  @override
  Widget build(BuildContext context) {
    // Uniform border on purpose: BoxDecoration can't paint a rounded border
    // with mismatched sides (it throws mid-paint and leaves an empty card).
    final card = AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(
          color: _hover
              ? AppColors.primary.withValues(alpha: 0.45)
              : AppColors.border,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: _hover ? 16 : 6,
            offset: Offset(0, _hover ? 6 : 2),
          ),
        ],
      ),
      child: _cardBody(),
    );

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap ?? _openDetail,
        child: AnimatedSlide(
          duration: const Duration(milliseconds: 150),
          offset: _hover ? const Offset(0, -0.015) : Offset.zero,
          child: card,
        ),
      ),
    );
  }

  Widget _cardBody() {
    final hasAccount = deal.accountName.trim().isNotEmpty;
    final hasName = deal.name.trim().isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Account line + overflow menu.
        Row(
          children: [
            if (hasAccount) ...[
              InitialsAvatar(name: deal.accountName, size: 22),
              const SizedBox(width: AppSpacing.sm),
            ],
            // Every line falls back to a visible placeholder, so a deal whose
            // lookups came back blank still renders as an identifiable card.
            Expanded(
              child: Text(
                hasAccount ? deal.accountName : 'No account linked',
                style: AppTextStyles.caption.copyWith(
                  color: hasAccount
                      ? AppColors.textSecondary
                      : AppColors.textMuted,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            _overflowMenu(),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          hasName ? deal.name : 'Untitled deal #${deal.id}',
          style: AppTextStyles.labelLarge.copyWith(
            fontWeight: FontWeight.w600,
            color: hasName ? AppColors.textPrimary : AppColors.textMuted,
            height: 1.35,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          'DL-${deal.id}',
          style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
        ),
        if (deal.tier.isNotEmpty || deal.priority != null) ...[
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              if (deal.tier.isNotEmpty) StatusBadge.tier(deal.tier),
              if (deal.priority != null) StatusBadge.priority(deal.priority!),
            ],
          ),
        ],
        // Linked contacts come straight off the wire, so they keep the card
        // identifiable even when the account/owner lookups return nothing.
        if (deal.contacts.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Icon(Icons.person_outline, size: 14, color: AppColors.textMuted),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  deal.contactNames,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          child: Divider(height: 1, color: AppColors.borderLight),
        ),
        Row(
          children: [
            Expanded(
              child: Text(
                CurrencyFormatter.formatINR(deal.value),
                style: AppTextStyles.labelLarge.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            _closeChip(),
            const SizedBox(width: AppSpacing.sm),
            Tooltip(
              message: deal.ownerLabel,
              child: ClipOval(
                child: InitialsAvatar(name: deal.ownerLabel, size: 24),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Expected-close chip: red when due within 10 days or overdue.
  Widget _closeChip() {
    final days = _daysLeft;
    final String label;
    if (days == null) {
      label = 'No date';
    } else if (days < 0) {
      label = 'Overdue';
    } else if (days == 0) {
      label = 'Today';
    } else if (_dueSoon) {
      label = '${days}d left';
    } else {
      label = DateFormatter.shortDate(deal.expectedCloseDate!);
    }
    final fg = _dueSoon ? AppColors.error : AppColors.textSecondary;
    return Tooltip(
      message: deal.expectedCloseDate == null
          ? 'No expected close date'
          : 'Expected close ${DateFormatter.displayDate(deal.expectedCloseDate!)}',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: _dueSoon ? AppColors.errorLight : AppColors.borderLight,
          borderRadius: BorderRadius.circular(AppSpacing.badgeRadius),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.schedule, size: 12, color: fg),
            const SizedBox(width: 4),
            Text(
              label,
              style: AppTextStyles.badge.copyWith(
                color: fg,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _overflowMenu() {
    return SizedBox(
      width: 28,
      height: 24,
      child: PopupMenuButton<String>(
        padding: EdgeInsets.zero,
        iconSize: 18,
        tooltip: 'Options',
        icon: Icon(Icons.more_horiz, color: AppColors.textMuted),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        ),
        onSelected: (v) {
          if (v == 'view') _openDetail();
          if (v == 'edit') _edit();
        },
        itemBuilder: (context) => [
          const PopupMenuItem(value: 'view', child: Text('View details')),
          if (widget.canManage)
            const PopupMenuItem(value: 'edit', child: Text('Edit')),
        ],
      ),
    );
  }
}
