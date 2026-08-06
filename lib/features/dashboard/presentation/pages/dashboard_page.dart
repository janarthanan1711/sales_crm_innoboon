import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/shared_widgets.dart';
import '../../../../app/di/injector.dart';
import '../../../../core/utils/media_url.dart';
import '../../domain/entities/dashboard_data.dart';
import '../../domain/entities/dashboard_range.dart';
import '../bloc/dashboard_bloc.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<DashboardBloc>()..add(const DashboardLoadRequested()),
      child: const _DashboardView(),
    );
  }
}

/// (label, wire value) for the named options in the period toggle. `today` was
/// dropped — a single day is now a custom range with equal bounds, which the
/// third (custom) segment handles.
const List<(String, String)> _kPeriods = [
  ('This Week', DashboardRange.thisWeek),
  ('This Month', DashboardRange.thisMonth),
];

class _DashboardView extends StatelessWidget {
  const _DashboardView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(context.pagePadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: AppSpacing.xl),
            BlocBuilder<DashboardBloc, DashboardState>(
              builder: (context, state) {
                // Cross-fade the spinner out instead of cutting to it. The
                // incoming content runs its own staggered entrance underneath,
                // so this only has to soften the swap itself.
                return AnimatedSwitcher(
                  duration: _Motion.off(context) ? Duration.zero : _Motion.swap,
                  // Keep the outgoing child pinned to the top: the default
                  // centre alignment makes the spinner drift as the taller
                  // dashboard lays in behind it.
                  layoutBuilder: (current, previous) => Stack(
                    alignment: Alignment.topCenter,
                    children: [...previous, ?current],
                  ),
                  child: KeyedSubtree(
                    key: ValueKey(state.runtimeType),
                    child: _buildBody(context, state),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, DashboardState state) {
    if (state is DashboardLoading || state is DashboardInitial) {
      return const Padding(
        padding: EdgeInsets.only(top: AppSpacing.xxxl),
        child: AppLoadingIndicator(message: 'Loading dashboard...'),
      );
    }
    if (state is DashboardError) {
      return Padding(
        padding: const EdgeInsets.only(top: AppSpacing.xxxl),
        child: ErrorState(
          message: state.message,
          onRetry: () =>
              context.read<DashboardBloc>().add(const DashboardLoadRequested()),
        ),
      );
    }
    if (state is DashboardLoaded) {
      return _buildContent(context, state.data);
    }
    return const SizedBox.shrink();
  }

  Widget _buildHeader(BuildContext context) {
    final range = context.select<DashboardBloc, DashboardRange>(
      (b) => b.state.range,
    );

    final titleBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Performance Overview', style: AppTextStyles.h1),
        const SizedBox(height: 4),
        Text(
          "Track your team's sales pipeline and conversion metrics.",
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );

    final toggle = _PeriodToggle(
      range: range,
      onSelected: (r) =>
          context.read<DashboardBloc>().add(DashboardLoadRequested(range: r)),
    );

    if (context.isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          titleBlock,
          const SizedBox(height: AppSpacing.md),
          // A picked custom range makes the third segment wide enough to
          // overflow a narrow phone, so let the toggle scroll sideways.
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: toggle,
          ),
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: titleBlock),
        toggle,
      ],
    );
  }

  Widget _buildContent(BuildContext context, DashboardData data) {
    // Conversion trend: sum transitions per period across all stages so the
    // chart reflects whatever the API returns, not just "Closed Won".
    final trend = _aggregateTrend(data.conversionTrend);
    final dealTotal = data.dealDistribution.fold<int>(0, (a, e) => a + e.count);

    // Half-width section cards — only the ones that actually have data.
    final halfCards = <Widget>[
      if (data.funnel.isNotEmpty) _FunnelCard(stages: data.funnel),
      if (trend.isNotEmpty) _ConversionTrendCard(points: trend),
      if (dealTotal > 0)
        _DealDistributionCard(entries: data.dealDistribution, total: dealTotal),
      if (data.leaderboard.isNotEmpty)
        _LeaderboardCard(entries: data.leaderboard),
    ];

    // Entrance order runs down the page. The tiles own indices 0-4; the cards
    // below start at 3 so their stagger overlaps the tail of the tiles' rather
    // than queueing behind it — the whole page is settled inside ~750ms.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SummaryTiles(summary: data.summary),
        if (halfCards.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xl),
          _halfGrid(context, [
            for (var i = 0; i < halfCards.length; i++)
              _FadeSlideIn(index: 3 + i, child: halfCards[i]),
          ]),
        ],
        if (data.activityFeed.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xl),
          _FadeSlideIn(
            index: 3 + halfCards.length,
            child: _ActivityFeedCard(entries: data.activityFeed),
          ),
        ],
        if (data.dropOffReasons.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xl),
          _FadeSlideIn(
            index: 4 + halfCards.length,
            child: _DropOffCard(entries: data.dropOffReasons),
          ),
        ],
      ],
    );
  }

  /// Lays out the half-width cards two-per-row on wide screens, stacked on
  /// phones. Handles an odd count (a lone card just takes one column).
  Widget _halfGrid(BuildContext context, List<Widget> cards) {
    if (context.isMobile) {
      return Column(
        children: [
          for (var i = 0; i < cards.length; i++) ...[
            if (i > 0) const SizedBox(height: AppSpacing.xl),
            cards[i],
          ],
        ],
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = AppSpacing.xl;
        final w = (constraints.maxWidth - gap) / 2;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: cards.map((c) => SizedBox(width: w, child: c)).toList(),
        );
      },
    );
  }

  /// Collapses the raw per-stage trend series into one point per period
  /// (total transitions), sorted chronologically.
  List<({DateTime period, int count})> _aggregateTrend(
    List<ConversionTrendEntry> entries,
  ) {
    final byPeriod = <DateTime, int>{};
    for (final e in entries) {
      byPeriod[e.period] = (byPeriod[e.period] ?? 0) + e.count;
    }
    final points =
        byPeriod.entries.map((e) => (period: e.key, count: e.value)).toList()
          ..sort((a, b) => a.period.compareTo(b.period));
    return points;
  }
}

// ─── Period toggle ──────────────────────────────────────
/// This Week / This Month / Custom range. The custom segment opens a date-range
/// picker and, once set, labels itself with the chosen dates.
class _PeriodToggle extends StatelessWidget {
  const _PeriodToggle({required this.range, required this.onSelected});
  final DashboardRange range;
  final ValueChanged<DashboardRange> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final p in _kPeriods)
            _segment(
              label: p.$1,
              active: !range.isCustom && p.$2 == range.period,
              onTap: () => onSelected(DashboardRange(period: p.$2)),
            ),
          _segment(
            label: _customLabel,
            icon: Icons.date_range_outlined,
            active: range.isCustom,
            onTap: () => _pickRange(context),
          ),
        ],
      ),
    );
  }

  /// "Custom" until a range is chosen, then the range itself. The year is
  /// carried by the end date alone unless the range straddles two years:
  /// "1 Jul – 31 Jul 2026", "28 Dec 2025 – 3 Jan 2026", "4 Aug 2026".
  String get _customLabel {
    final start = range.start;
    final end = range.end;
    if (!range.isCustom || start == null || end == null) return 'Custom';
    final withYear = DateFormat('d MMM y');
    if (start == end) return withYear.format(start);
    final left = start.year == end.year
        ? DateFormat('d MMM').format(start)
        : withYear.format(start);
    return '$left – ${withYear.format(end)}';
  }

  Future<void> _pickRange(BuildContext context) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(today.year - 5),
      // No future dates — the dashboard only aggregates what already happened.
      lastDate: today,
      initialDateRange: range.start != null && range.end != null
          ? DateTimeRange(start: range.start!, end: range.end!)
          : null,
      helpText: 'Select dashboard date range',
      saveText: 'Apply',
    );
    if (picked == null) return;
    onSelected(DashboardRange.between(picked.start, picked.end));
  }

  Widget _segment({
    required String label,
    required bool active,
    required VoidCallback onTap,
    IconData? icon,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: _Motion.segment,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: active ? AppColors.primaryLight : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSpacing.buttonRadius - 2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              // The pill behind the label already animates; without these the
              // label and icon snapped to their new colour a beat ahead of it.
              TweenAnimationBuilder<Color?>(
                duration: _Motion.segment,
                tween: ColorTween(
                  end: active ? AppColors.primary : AppColors.textSecondary,
                ),
                builder: (context, color, _) =>
                    Icon(icon, size: 15, color: color),
              ),
              const SizedBox(width: 5),
            ],
            AnimatedDefaultTextStyle(
              duration: _Motion.segment,
              style: AppTextStyles.labelMedium.copyWith(
                color: active ? AppColors.primary : AppColors.textSecondary,
                fontWeight: active ? FontWeight.w600 : FontWeight.w500,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Summary stat tiles ─────────────────────────────────
class _SummaryTiles extends StatelessWidget {
  const _SummaryTiles({required this.summary});
  final DashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    final tiles = [
      _StatTile(
        title: 'Leads Generated',
        stat: summary.leadsGenerated,
        icon: Icons.person_add_alt_1_outlined,
        color: AppColors.primary,
      ),
      _StatTile(
        title: 'Qualified Leads',
        stat: summary.qualifiedLeads,
        icon: Icons.verified_outlined,
        color: const Color(0xFF7C3AED),
      ),
      _StatTile(
        title: 'Deals in Pipeline',
        stat: summary.dealsInPipeline,
        icon: Icons.trending_up,
        color: const Color(0xFFD97706),
      ),
      _StatTile(
        title: 'Deals Closed',
        stat: summary.dealsClosed,
        icon: Icons.emoji_events_outlined,
        color: AppColors.success,
      ),
      // Accounts created in the period. Absent (not zero) on API builds that
      // don't return the section, in which case the tile is left out.
      if (summary.numAccounts != null)
        _StatTile(
          title: 'No. of Accounts',
          stat: summary.numAccounts!,
          icon: Icons.business_outlined,
          color: const Color(0xFF0891B2),
        ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        // Balanced rows at every width: 5 tiles go 5-up only when there's real
        // room, else 3+2 — a 4-up grid would leave the fifth tile stranded.
        final cols = constraints.maxWidth >= 1280
            ? (tiles.length > 4 ? 5 : 4)
            : constraints.maxWidth >= 1000
            ? (tiles.length > 4 ? 3 : 4)
            : constraints.maxWidth >= 560
            ? 2
            : 1;
        const gap = AppSpacing.lg;
        final tileWidth = (constraints.maxWidth - gap * (cols - 1)) / cols;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (var i = 0; i < tiles.length; i++)
              SizedBox(
                width: tileWidth,
                child: _FadeSlideIn(index: i, child: tiles[i]),
              ),
          ],
        );
      },
    );
  }
}

class _StatTile extends StatefulWidget {
  const _StatTile({
    required this.title,
    required this.stat,
    required this.icon,
    required this.color,
  });
  final String title;
  final DashboardStat stat;
  final IconData icon;
  final Color color;

  @override
  State<_StatTile> createState() => _StatTileState();
}

class _StatTileState extends State<_StatTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    // Deliberately restrained: a 2px lift, a tinted border and a soft shadow in
    // the tile's own accent. No colour flash and no cursor change — these tiles
    // aren't clickable, so the hover state should read as focus, not affordance.
    final raised = _hovered && !_Motion.off(context);
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: _Motion.hover,
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0, raised ? -2 : 0, 0),
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          border: Border.all(
            color: raised
                ? widget.color.withValues(alpha: 0.45)
                : AppColors.border,
          ),
          boxShadow: [
            BoxShadow(
              color: widget.color.withValues(alpha: raised ? 0.12 : 0),
              blurRadius: raised ? 18 : 0,
              offset: Offset(0, raised ? 6 : 0),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: widget.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(widget.icon, size: 18, color: widget.color),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            _CountUp(value: widget.stat.value, style: AppTextStyles.h1),
            const SizedBox(height: 6),
            _ChangeBadge(changePct: widget.stat.changePct),
          ],
        ),
      ),
    );
  }
}

/// The "+12% vs last month" pill. Renders nothing meaningful when the change
/// is null (e.g. deals-in-pipeline is a snapshot with no trend).
class _ChangeBadge extends StatelessWidget {
  const _ChangeBadge({required this.changePct});
  final double? changePct;

  @override
  Widget build(BuildContext context) {
    if (changePct == null) {
      return Text(
        'Current snapshot',
        style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
      );
    }
    final up = changePct! >= 0;
    final color = up ? AppColors.success : AppColors.error;
    final pct = changePct!.abs().toStringAsFixed(changePct! % 1 == 0 ? 0 : 1);
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                up ? Icons.trending_up : Icons.trending_down,
                size: 12,
                color: color,
              ),
              const SizedBox(width: 2),
              Text(
                '${up ? '+' : '-'}$pct%',
                style: AppTextStyles.overline.copyWith(color: color),
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            'vs prev. period',
            style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ─── Pipeline funnel ────────────────────────────────────
/// Pipeline Funnel — a centered stack of tinted pills that taper toward the
/// bottom, one per `funnel.stages` entry from `GET /dashboard`.
class _FunnelCard extends StatelessWidget {
  const _FunnelCard({required this.stages});
  final List<FunnelStage> stages;

  @override
  Widget build(BuildContext context) {
    final ordered = _byCount(stages);
    return SectionCard(
      title: 'Pipeline Funnel',
      child: Column(
        // Each bar is narrower than the one above it, so they have to be
        // centered for the stack to read as a funnel.
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          for (var i = 0; i < ordered.length; i++) ...[
            if (i > 0) const SizedBox(height: AppSpacing.sm),
            _FunnelBar(
              stage: ordered[i],
              palette: _funnelPalettes[i % _funnelPalettes.length],
              widthFactor: _taper(i, ordered.length),
              index: i,
            ),
          ],
        ],
      ),
    );
  }

  /// Orders the stages by count, biggest first, so the widest bar carries the
  /// largest number and the stack tapers downward.
  ///
  /// The API returns stages in pipeline (`sort_order`) order, which routinely
  /// puts a near-empty early stage above a busier later one — the taper then
  /// reads backwards. Ties keep their pipeline order (`List.sort` isn't
  /// guaranteed stable, hence the explicit index tie-break).
  List<FunnelStage> _byCount(List<FunnelStage> input) {
    final indexed = input.indexed.toList()
      ..sort((a, b) {
        final byCount = b.$2.count.compareTo(a.$2.count);
        return byCount != 0 ? byCount : a.$1.compareTo(b.$1);
      });
    return indexed.map((e) => e.$2).toList(growable: false);
  }

  /// Width of bar [index] as a fraction of the card body, tapering linearly
  /// from full width to [_narrowest].
  ///
  /// Deliberately independent of the counts: scaling by count would render
  /// late stages (84 out of 842) as unreadable slivers, and the funnel shape
  /// already conveys the drop-off — the numbers carry the exact values.
  double _taper(int index, int count) {
    if (count <= 1) return 1;
    const narrowest = 0.34;
    return 1 - (index / (count - 1)) * (1 - narrowest);
  }
}

typedef _FunnelPalette = ({Color background, Color foreground});

/// Tint per funnel step. Cycles if the pipeline has more stages than entries
/// (stages are admin-configurable, so the count isn't fixed).
const List<_FunnelPalette> _funnelPalettes = [
  (background: Color(0xFFDBEAFE), foreground: Color(0xFF1D4ED8)), // blue
  (background: Color(0xFFE0E7FF), foreground: Color(0xFF4338CA)), // indigo
  (background: Color(0xFFFFEDD5), foreground: Color(0xFFC2410C)), // orange
  (background: Color(0xFFDBEAFE), foreground: Color(0xFF1D4ED8)), // blue
  (background: Color(0xFFD1FAE5), foreground: Color(0xFF047857)), // green
  (background: Color(0xFFFCE7F3), foreground: Color(0xFFBE185D)), // pink
];

class _FunnelBar extends StatelessWidget {
  const _FunnelBar({
    required this.stage,
    required this.palette,
    required this.widthFactor,
    required this.index,
  });
  final FunnelStage stage;
  final _FunnelPalette palette;
  final double widthFactor;

  /// Position in the stack, used to cascade the unfurl.
  final int index;

  @override
  Widget build(BuildContext context) {
    final bar = _bar();
    if (_Motion.off(context)) {
      return FractionallySizedBox(widthFactor: widthFactor, child: bar);
    }
    // Each bar widens out from the centre, later ones taking longer, so the
    // funnel unfurls top-down. Starting at 55% of the final width rather than
    // zero keeps the row inside laid out the whole way: a bar animating up from
    // nothing would have less width than its own padding on the first frames.
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: widthFactor * 0.55, end: widthFactor),
      duration: Duration(milliseconds: 420 + 70 * index.clamp(0, 6)),
      curve: Curves.easeOutCubic,
      child: bar,
      builder: (context, w, child) =>
          FractionallySizedBox(widthFactor: w, child: child),
    );
  }

  Widget _bar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: palette.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // Narrow bars leave little room, so let long stage names wrap to a
          // second line rather than stealing space from the count.
          Expanded(
            child: Text(
              stage.stageName,
              style: AppTextStyles.labelMedium.copyWith(
                color: palette.foreground,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            '${stage.count}',
            style: AppTextStyles.labelMedium.copyWith(
              color: palette.foreground,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Conversion trend (transitions per period) ──────────
class _ConversionTrendCard extends StatelessWidget {
  const _ConversionTrendCard({required this.points});
  final List<({DateTime period, int count})> points;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      titleWidget: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Conversion Trend', style: AppTextStyles.h3),
          SizedBox(width: 5),
          Text(
            'Stage transitions',
            style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
          ),
        ],
      ),
      child: SizedBox(
        height: 368,
        child: Padding(
          // Extra right room so the last x-axis label (centered on the
          // right-most point) doesn't spill past the card edge.
          padding: const EdgeInsets.only(
            top: AppSpacing.md,
            left: 4,
            right: 24,
          ),
          child: _Motion.off(context)
              ? LineChart(_chartData(1))
              : TweenAnimationBuilder<double>(
                  // The series rises out of the baseline. fl_chart's own
                  // implicit tween is zeroed out underneath so it doesn't lag
                  // a frame behind this one and smear the curve.
                  tween: Tween(begin: 0, end: 1),
                  duration: _Motion.draw,
                  curve: Curves.easeOutCubic,
                  builder: (context, t, _) =>
                      LineChart(_chartData(t), duration: Duration.zero),
                ),
        ),
      ),
    );
  }

  /// [t] scales the plotted values from the axis floor up to their real
  /// heights, driving the entrance. Axis bounds and labels stay fixed at their
  /// final values so nothing reflows while the line grows.
  LineChartData _chartData(double t) {
    final maxY = points.map((e) => e.count).fold(0, (a, b) => a > b ? a : b);
    final niceMax = (maxY <= 5 ? 5 : ((maxY / 5).ceil() * 5)).toDouble();
    // A single period would give minX == maxX (divide-by-zero on intervals);
    // pad the axis to 1 so a lone point still renders as a dot.
    final maxX = points.length <= 1 ? 1.0 : points.length.toDouble() - 1;
    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: niceMax / 5,
        getDrawingHorizontalLine: (v) =>
            FlLine(color: AppColors.border, strokeWidth: 1, dashArray: [5, 5]),
      ),
      titlesData: FlTitlesData(
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 28,
            interval: 1,
            getTitlesWidget: (value, meta) {
              final i = value.toInt();
              // Only label real data points (x may fall between them when a
              // single period pads the axis to maxX = 1).
              if (i < 0 || i >= points.length || value != i.toDouble()) {
                return const SizedBox.shrink();
              }
              // SideTitleWidget lets fl_chart fit edge labels within the axis
              // area; the compact "MMM d" keeps them narrow.
              return SideTitleWidget(
                meta: meta,
                space: 6,
                child: Text(
                  DateFormat('MMM d').format(points[i].period.toLocal()),
                  style: AppTextStyles.caption,
                ),
              );
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 32,
            interval: niceMax / 5,
            getTitlesWidget: (value, meta) =>
                Text(value.toInt().toString(), style: AppTextStyles.caption),
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      // fl_chart defaults a tooltip's text colour to the *line's* colour, so
      // the hovered value came out dark blue on the dark tooltip and was
      // essentially unreadable. Spell out white text on a dark panel, and put
      // the bucket's date above the count so the hover says what it's counting.
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (_) => AppColors.textPrimary,
          tooltipRoundedRadius: 6,
          getTooltipItems: (touched) => touched.map((spot) {
            final i = spot.x.toInt();
            final inRange = i >= 0 && i < points.length;
            final label = inRange
                ? DateFormat('MMM d').format(points[i].period.toLocal())
                : '';
            return LineTooltipItem(
              // Read the count off the data, not off `spot.y` — mid-entrance
              // the plotted y is a fraction of the real value.
              '${inRange ? points[i].count : spot.y.toInt()}',
              const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
              children: [
                if (label.isNotEmpty)
                  TextSpan(
                    text: '\n$label',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.75),
                      fontWeight: FontWeight.w500,
                      fontSize: 11,
                    ),
                  ),
              ],
              textAlign: TextAlign.center,
            );
          }).toList(),
        ),
      ),
      minX: 0,
      maxX: maxX,
      minY: 0,
      maxY: niceMax,
      lineBarsData: [
        LineChartBarData(
          spots: points
              .asMap()
              .entries
              .map((e) => FlSpot(e.key.toDouble(), e.value.count * t))
              .toList(),
          isCurved: points.length > 1,
          color: AppColors.primary,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: true),
          belowBarData: BarAreaData(
            show: true,
            color: AppColors.primary.withValues(alpha: 0.1),
          ),
        ),
      ],
    );
  }
}

// ─── Deal distribution donut ────────────────────────────
const Map<String, Color> _tierColors = {
  'diamond': AppColors.tierDiamondText,
  'gold': AppColors.tierGoldText,
  'silver': AppColors.tierSilverText,
  'bronze': AppColors.tierBronzeText,
};

class _DealDistributionCard extends StatelessWidget {
  const _DealDistributionCard({required this.entries, required this.total});
  final List<DealDistributionEntry> entries;
  final int total;

  /// [t] grows the ring's thickness from nothing to its full 22px.
  PieChartData _donutData(double t) => PieChartData(
    sectionsSpace: 2,
    centerSpaceRadius: 55,
    sections: entries.map((e) {
      final color = _tierColors[e.tier.toLowerCase()] ?? AppColors.textMuted;
      return PieChartSectionData(
        color: color,
        value: e.count.toDouble(),
        title: '',
        radius: 22 * t,
      );
    }).toList(),
  );

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Deal Distribution',
      child: SizedBox(
        height: 240,
        child: Row(
          children: [
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (_Motion.off(context))
                    PieChart(_donutData(1))
                  else
                    TweenAnimationBuilder<double>(
                      // The ring thickens out of the centre hole. Scaling the
                      // radius rather than the values keeps every slice's share
                      // correct from the first frame — only the depth grows.
                      tween: Tween(begin: 0, end: 1),
                      duration: _Motion.draw,
                      curve: Curves.easeOutCubic,
                      builder: (context, t, _) =>
                          PieChart(_donutData(t), duration: Duration.zero),
                    ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _CountUp(value: total, style: AppTextStyles.h1),
                      Text('Total Deals', style: AppTextStyles.caption),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: entries.map((e) {
                final color =
                    _tierColors[e.tier.toLowerCase()] ?? AppColors.textMuted;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${_titleCase(e.tier)} (${e.count})',
                        style: AppTextStyles.bodySmall,
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Sales leaderboard (no % target, no progress line) ──
class _LeaderboardCard extends StatelessWidget {
  const _LeaderboardCard({required this.entries});
  final List<LeaderboardEntry> entries;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Sales Leaderboard',
      child: Column(
        children: [
          for (var i = 0; i < entries.length; i++)
            Padding(
              padding: EdgeInsets.only(
                bottom: i == entries.length - 1 ? 0 : AppSpacing.md,
              ),
              child: Row(
                children: [
                  UserAvatar(
                    name: entries[i].ownerName,
                    avatarUrl: resolveMediaUrl(
                      entries[i].avatarUrl,
                      bustCache: true,
                    ),
                    size: 36,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entries[i].ownerName,
                          style: AppTextStyles.labelLarge,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${entries[i].dealsClosed} deals closed',
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    CurrencyFormatter.formatCompact(entries[i].revenue),
                    style: AppTextStyles.labelLarge.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Activity feed ──────────────────────────────────────
class _ActivityFeedCard extends StatelessWidget {
  const _ActivityFeedCard({required this.entries});
  final List<DashboardActivity> entries;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Activity Feed',
      child: Column(
        children: entries.map((a) => _ActivityRow(activity: a)).toList(),
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.activity});
  final DashboardActivity activity;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = _activityStyle(activity.type);
    final who = activity.createdByName ?? 'Someone';
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: who, style: AppTextStyles.labelLarge),
                      TextSpan(
                        text:
                            ' · ${_titleCase(activity.type.replaceAll('_', ' '))} on ${activity.entityType}',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (activity.note != null && activity.note!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      activity.note!,
                      style: AppTextStyles.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                const SizedBox(height: 2),
                Text(
                  DateFormatter.relativeTime(activity.createdAt),
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

(IconData, Color) _activityStyle(String type) {
  switch (type) {
    case 'call':
      return (Icons.phone, AppColors.primary);
    case 'meeting':
      return (Icons.event, const Color(0xFF7C3AED));
    case 'note':
      return (Icons.sticky_note_2_outlined, AppColors.textSecondary);
    case 'comment':
      return (Icons.chat_bubble_outline, const Color(0xFF0891B2));
    case 'follow_up':
      return (Icons.flag_outlined, AppColors.success);
    default:
      return (Icons.bolt, AppColors.textMuted);
  }
}

// ─── Drop-off reasons table ─────────────────────────────
class _DropOffCard extends StatelessWidget {
  const _DropOffCard({required this.entries});
  final List<DropOffReason> entries;

  /// Below this the five columns squeeze into unreadable slivers, so the table
  /// scrolls sideways instead of shrinking.
  static const double _minTableWidth = 720;

  @override
  Widget build(BuildContext context) {
    final table = Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Row(
            children: [
              _h('Reason Category', flex: 4),
              _h('Stage Lost', flex: 3),
              _h('Count', flex: 2),
              _h('Impact (₹)', flex: 3),
              _h('Trend', flex: 2),
            ],
          ),
        ),
        const Divider(height: 1),
        for (final e in entries) _DropOffRow(reason: e),
      ],
    );

    return SectionCard(
      title: 'Drop-off Reasons (Lost Deals)',
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Lay the table out at the card's own width when there's room.
          // Wrapping it in a horizontal scroll view unconditionally hands the
          // rows unbounded width, which pushes every column after the reason
          // name off-screen.
          if (constraints.maxWidth >= _minTableWidth) return table;
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(width: _minTableWidth, child: table),
          );
        },
      ),
    );
  }

  Widget _h(String label, {int flex = 1}) => Expanded(
    flex: flex,
    child: Text(label, style: AppTextStyles.tableHeader),
  );
}

class _DropOffRow extends StatelessWidget {
  const _DropOffRow({required this.reason});
  final DropOffReason reason;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.error,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    reason.reason,
                    style: AppTextStyles.bodyMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(reason.stageLost, style: AppTextStyles.tableCell),
          ),
          Expanded(
            flex: 2,
            child: Text('${reason.count}', style: AppTextStyles.tableCell),
          ),
          Expanded(
            flex: 3,
            child: Text(
              CurrencyFormatter.formatINR(reason.lostValue),
              style: AppTextStyles.tableCell,
            ),
          ),
          Expanded(flex: 2, child: _TrendCell(changePct: reason.changePct)),
        ],
      ),
    );
  }
}

class _TrendCell extends StatelessWidget {
  const _TrendCell({required this.changePct});
  final double? changePct;

  @override
  Widget build(BuildContext context) {
    if (changePct == null || changePct == 0) {
      return Text(
        '— 0%',
        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
      );
    }
    // A rising loss count is bad (red); a falling one is good (green).
    final up = changePct! > 0;
    final color = up ? AppColors.error : AppColors.success;
    final pct = changePct!.abs().toStringAsFixed(changePct! % 1 == 0 ? 0 : 1);
    return Row(
      children: [
        Icon(
          up ? Icons.arrow_upward : Icons.arrow_downward,
          size: 14,
          color: color,
        ),
        const SizedBox(width: 2),
        Text('$pct%', style: AppTextStyles.bodySmall.copyWith(color: color)),
      ],
    );
  }
}

String _titleCase(String s) =>
    s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

// ─── Motion ─────────────────────────────────────────────
/// Every duration on this page in one place, so the dashboard animates as one
/// system rather than as a dozen independently-tuned widgets.
///
/// The page reloads through [DashboardLoading] on every period switch, which
/// unmounts the content — so fl_chart's own data-swap tweens never actually
/// fire here. The charts drive their own entrance instead (see `_chartData`'s
/// `t` and the donut's radius tween), and their implicit duration is zeroed so
/// the two don't fight.
class _Motion {
  _Motion._();

  static const Duration entrance = Duration(milliseconds: 360);
  static const Duration stagger = Duration(milliseconds: 55);
  static const Duration count = Duration(milliseconds: 700);
  static const Duration draw = Duration(milliseconds: 700);
  static const Duration hover = Duration(milliseconds: 140);
  static const Duration swap = Duration(milliseconds: 220);
  static const Duration segment = Duration(milliseconds: 150);

  /// Ceiling on stagger steps. Without it a long activity feed or a wide tile
  /// row would push the last item's delay past the point where it reads as
  /// "loading" rather than "arriving".
  static const int maxSteps = 8;

  /// Honours the platform's reduce-motion setting: everything here is
  /// decoration, so it all collapses to its end state rather than degrading.
  static bool off(BuildContext context) =>
      MediaQuery.disableAnimationsOf(context);
}

/// Fades a section in while lifting it a few pixels. One controller per child,
/// with the stagger delay baked into an [Interval] rather than a `Future.delayed`
/// — nothing can fire after dispose, and the delay stays in the animation
/// system where the framework can drive it.
///
/// Only used at the section level. Cards that stagger *their own* children
/// deliberately don't nest a second fade inside this one: the parent's opacity
/// multiplies through, so an inner fade running on the same clock is simply
/// invisible. Inner motion is width/height/value based instead.
class _FadeSlideIn extends StatefulWidget {
  const _FadeSlideIn({required this.child, this.index = 0});

  final Widget child;
  final int index;

  /// Pixels travelled upward. Kept small — this is a settle, not a slide.
  static const double offset = 14;

  @override
  State<_FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<_FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    final steps = widget.index.clamp(0, _Motion.maxSteps);
    final delayMs = _Motion.stagger.inMilliseconds * steps;
    final totalMs = delayMs + _Motion.entrance.inMilliseconds;
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: totalMs),
    );
    _anim = CurvedAnimation(
      parent: _controller,
      curve: Interval(delayMs / totalMs, 1, curve: Curves.easeOutCubic),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_Motion.off(context)) return widget.child;
    return FadeTransition(
      opacity: _anim,
      child: AnimatedBuilder(
        animation: _anim,
        // The child is built once and passed through — only the transform is
        // rebuilt per frame.
        child: widget.child,
        builder: (context, child) => Transform.translate(
          offset: Offset(0, (1 - _anim.value) * _FadeSlideIn.offset),
          child: child,
        ),
      ),
    );
  }
}

/// Counts a stat up to its value. On a period switch the tile is rebuilt from
/// scratch, so this runs from zero each time — which is the point: it draws the
/// eye to the numbers that just changed.
class _CountUp extends StatelessWidget {
  const _CountUp({required this.value, required this.style});

  final int value;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.toDouble()),
      duration: _Motion.off(context) ? Duration.zero : _Motion.count,
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => Text('${v.round()}', style: style),
    );
  }
}
