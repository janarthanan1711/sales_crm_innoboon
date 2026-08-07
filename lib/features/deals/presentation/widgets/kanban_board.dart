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

/// Accent colors for the column status dots, cycled by stage order.
const List<Color> _kStageDotColors = [
  Color(0xFF94A3B8), // slate
  Color(0xFF3B82F6), // blue
  Color(0xFF8B5CF6), // violet
  Color(0xFFF97316), // orange
  Color(0xFF10B981), // emerald
  Color(0xFF06B6D4), // cyan
  Color(0xFFEF4444), // red
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
  final result = await showDialog<Object>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text('Move "${deal.name}" to ${target.name}?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (target.isCold)
            TextField(
              controller: coldController,
              decoration: const InputDecoration(
                labelText: 'Cold reason *',
                helperText: 'Required when moving to a cold stage',
                border: OutlineInputBorder(),
              ),
            ),
          if (target.isCold) const SizedBox(height: AppSpacing.md),
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
            if (target.isCold && coldController.text.trim().isEmpty) return;
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

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < stages.length; i++)
            _KanbanColumn(
              stage: stages[i],
              deals: deals.where((d) => d.stageId == stages[i].id).toList(),
              canManage: canManage,
              accent: _kStageDotColors[i % _kStageDotColors.length],
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
        return Container(
          width: 300,
          margin: const EdgeInsets.only(right: AppSpacing.lg),
          decoration: BoxDecoration(
            color: candidateData.isNotEmpty
                ? AppColors.primaryLight
                : AppColors.background,
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Column header — status dot + uppercase stage name + count.
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
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
                        stage.name.toUpperCase(),
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
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
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${deals.length}',
                        style: AppTextStyles.caption,
                      ),
                    ),
                  ],
                ),
              ),
              // A fixed-height scroll area so empty columns are still valid
              // drop targets.
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  itemCount: deals.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.sm),
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
                        elevation: 8,
                        borderRadius: BorderRadius.circular(
                          AppSpacing.cardRadius,
                        ),
                        child: SizedBox(
                          width: 280,
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
              // Column footer — pinned total for the stage.
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: AppColors.border)),
                ),
                child: Text(
                  'Total: ${CurrencyFormatter.formatINR(totalValue)}',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
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

  /// True when the deal is due within the next 10 days (or already overdue) —
  /// surfaced as a red left border to flag deals needing attention.
  bool get _dueSoon {
    final close = deal.expectedCloseDate;
    if (close == null) return false;
    return close.difference(DateTime.now()).inDays <= 10;
  }

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
    // Red for a deal that's due (or overdue), primary while hovered, nothing
    // otherwise. Painted as an overlaid stripe rather than a thick left
    // BorderSide — see the note on the decoration below.
    final accentColor = _dueSoon
        ? AppColors.error
        : (_hover ? AppColors.primary : null);
    final accentWidth = _dueSoon ? 4.0 : 3.0;

    final card = Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        // Uniform on purpose. BoxDecoration can only paint a *rounded* border
        // when all four sides match; give it a thicker or differently-coloured
        // left side alongside a borderRadius and painting throws part-way
        // through — after the shadow and background, before the child. The card
        // keeps its slot and its size but renders as an empty white rectangle.
        // That was the "sometimes the deal card is empty" bug: it hit exactly
        // the deals whose left border went red for being due soon.
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        child: Stack(
          children: [
            // The Stack takes its size from this, the only unpositioned child;
            // the stripe then stretches to whatever height the content needs.
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: _cardBody(),
            ),
            if (accentColor != null)
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Container(width: accentWidth, color: accentColor),
              ),
          ],
        ),
      ),
    );

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: InkWell(
        onTap: widget.onTap ?? _openDetail,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        child: card,
      ),
    );
  }

  Widget _cardBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tier badge + overflow menu.
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: deal.tier.isNotEmpty
                  ? Align(
                      alignment: Alignment.centerLeft,
                      child: TierBadge(tier: deal.tier),
                    )
                  : const SizedBox.shrink(),
            ),
            _overflowMenu(),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        // Every line below falls back to a visible placeholder. A deal whose
        // name/account/owner came back blank — or whose account couldn't be
        // resolved because the account or user list was unavailable — used to
        // render as an all-but-empty card with nothing to identify or click.
        Text(
          deal.name.trim().isEmpty ? 'Untitled deal #${deal.id}' : deal.name,
          style: AppTextStyles.labelLarge.copyWith(
            color: deal.name.trim().isEmpty
                ? AppColors.textMuted
                : AppColors.textPrimary,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          deal.accountName.trim().isEmpty
              ? 'No account linked'
              : deal.accountName,
          style: AppTextStyles.bodySmall.copyWith(
            color: deal.accountName.trim().isEmpty
                ? AppColors.textMuted
                : AppColors.primary,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        // Linked contacts come straight off the wire (`DealRead.contacts`),
        // needing none of the id→name lookups the account and owner lines
        // depend on — so they keep the card identifiable even when those
        // lookups return nothing.
        if (deal.contacts.isNotEmpty) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(
                Icons.person_outline,
                size: 13,
                color: AppColors.textMuted,
              ),
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
        const SizedBox(height: AppSpacing.md),
        Text(
          CurrencyFormatter.formatINR(deal.value),
          style: AppTextStyles.labelMedium,
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            if (deal.expectedCloseDate != null) ...[
              Icon(
                Icons.event_outlined,
                size: 13,
                color: _dueSoon ? AppColors.error : AppColors.textMuted,
              ),
              const SizedBox(width: 4),
              Text(
                DateFormatter.shortDate(deal.expectedCloseDate!),
                style: AppTextStyles.caption.copyWith(
                  color: _dueSoon ? AppColors.error : AppColors.textSecondary,
                ),
              ),
            ] else
              Text(
                'No close date',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            const Spacer(),
            Tooltip(
              message: deal.ownerLabel,
              child: InitialsAvatar(name: deal.ownerLabel, size: 26),
            ),
          ],
        ),
      ],
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
        icon: const Icon(Icons.more_horiz, color: AppColors.textMuted),
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
