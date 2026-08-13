import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// Drop-in replacement for [showDateRangePicker], which renders as a
/// near-full-screen dialog. Shows a single small calendar month — tap a start
/// day, then an end day, both in the one open dialog, instead of opening and
/// closing a separate picker for each bound.
Future<DateTimeRange?> showCompactDateRangePicker({
  required BuildContext context,
  DateTime? initialStart,
  DateTime? initialEnd,
  required DateTime firstDate,
  required DateTime lastDate,
}) {
  return showDialog<DateTimeRange>(
    context: context,
    builder: (_) => _CompactDateRangeDialog(
      initialStart: initialStart,
      initialEnd: initialEnd,
      firstDate: firstDate,
      lastDate: lastDate,
    ),
  );
}

class _CompactDateRangeDialog extends StatefulWidget {
  const _CompactDateRangeDialog({
    required this.initialStart,
    required this.initialEnd,
    required this.firstDate,
    required this.lastDate,
  });

  final DateTime? initialStart;
  final DateTime? initialEnd;
  final DateTime firstDate;
  final DateTime lastDate;

  @override
  State<_CompactDateRangeDialog> createState() =>
      _CompactDateRangeDialogState();
}

class _CompactDateRangeDialogState extends State<_CompactDateRangeDialog> {
  late DateTime? _start = widget.initialStart;
  late DateTime? _end = widget.initialEnd;
  late DateTime _visibleMonth = DateTime(
    (_start ?? _defaultDate).year,
    (_start ?? _defaultDate).month,
  );

  // Default to today, not `lastDate` -- callers commonly pass a far-future
  // `lastDate` (e.g. `DateTime(now.year + 1)`, meaning "allow next year",
  // Jan 1 of it) just to widen the pickable range, and the calendar
  // shouldn't open a year ahead of the current month just because that's
  // technically the last allowed date.
  DateTime get _defaultDate {
    final now = DateTime.now();
    if (now.isBefore(widget.firstDate)) return widget.firstDate;
    if (now.isAfter(widget.lastDate)) return widget.lastDate;
    return now;
  }

  static final _monthFormat = DateFormat('MMMM y');
  static final _dayFormat = DateFormat('d MMM y');
  static const _weekdayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  bool get _canGoBack {
    final firstOfVisible = DateTime(_visibleMonth.year, _visibleMonth.month);
    final firstOfFloor = DateTime(
      widget.firstDate.year,
      widget.firstDate.month,
    );
    return firstOfVisible.isAfter(firstOfFloor);
  }

  bool get _canGoForward {
    final firstOfVisible = DateTime(_visibleMonth.year, _visibleMonth.month);
    final firstOfCeiling = DateTime(
      widget.lastDate.year,
      widget.lastDate.month,
    );
    return firstOfVisible.isBefore(firstOfCeiling);
  }

  void _changeMonth(int delta) {
    setState(
      () => _visibleMonth = DateTime(
        _visibleMonth.year,
        _visibleMonth.month + delta,
      ),
    );
  }

  void _onDayTapped(DateTime day) {
    setState(() {
      // Nothing picked yet, or a full range already sitting there -- either
      // way this tap starts a fresh selection.
      if (_start == null || _end != null) {
        _start = day;
        _end = null;
      } else if (day.isBefore(_start!)) {
        // Tapped before the current start -- that becomes the new start
        // rather than erroring or silently ignoring the tap.
        _start = day;
      } else {
        _end = day;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final canApply = _start != null && _end != null;
    final firstOfMonth = DateTime(_visibleMonth.year, _visibleMonth.month, 1);
    final daysInMonth = DateUtils.getDaysInMonth(
      _visibleMonth.year,
      _visibleMonth.month,
    );
    // Monday-first grid; DateTime.weekday is already 1 (Mon) .. 7 (Sun).
    final leadingBlanks = firstOfMonth.weekday - 1;
    final weekCount = ((leadingBlanks + daysInMonth) / 7).ceil();

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 340),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Select Date Range', style: AppTextStyles.h3),
              const SizedBox(height: AppSpacing.xs),
              Text(
                _start == null
                    ? 'Pick a start date'
                    : _end == null
                    ? '${_dayFormat.format(_start!)} – Pick an end date'
                    : '${_dayFormat.format(_start!)} – ${_dayFormat.format(_end!)}',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  IconButton(
                    onPressed: _canGoBack ? () => _changeMonth(-1) : null,
                    icon: const Icon(Icons.chevron_left),
                    visualDensity: VisualDensity.compact,
                  ),
                  Expanded(
                    child: Text(
                      _monthFormat.format(_visibleMonth),
                      textAlign: TextAlign.center,
                      style: AppTextStyles.labelLarge,
                    ),
                  ),
                  IconButton(
                    onPressed: _canGoForward ? () => _changeMonth(1) : null,
                    icon: const Icon(Icons.chevron_right),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              Row(
                children: _weekdayLabels
                    .map(
                      (label) => Expanded(
                        child: Center(
                          child: Text(
                            label,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textMuted,
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: AppSpacing.xs),
              ...List.generate(weekCount, (week) {
                return Row(
                  children: List.generate(7, (weekday) {
                    final dayNum = week * 7 + weekday - leadingBlanks + 1;
                    if (dayNum < 1 || dayNum > daysInMonth) {
                      return const Expanded(child: SizedBox(height: 36));
                    }
                    final day = DateTime(
                      _visibleMonth.year,
                      _visibleMonth.month,
                      dayNum,
                    );
                    return Expanded(child: _dayCell(day));
                  }),
                );
              }),
              const SizedBox(height: AppSpacing.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  ElevatedButton(
                    onPressed: canApply
                        ? () => Navigator.of(
                            context,
                          ).pop(DateTimeRange(start: _start!, end: _end!))
                        : null,
                    child: const Text('Apply'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dayCell(DateTime day) {
    final disabled =
        day.isBefore(widget.firstDate) || day.isAfter(widget.lastDate);
    final isStart = _start != null && DateUtils.isSameDay(day, _start);
    final isEnd = _end != null && DateUtils.isSameDay(day, _end);
    final inRange =
        _start != null &&
        _end != null &&
        day.isAfter(_start!) &&
        day.isBefore(_end!);
    final isToday = DateUtils.isSameDay(day, DateTime.now());
    final isEndpoint = isStart || isEnd;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: InkWell(
        onTap: disabled ? null : () => _onDayTapped(day),
        borderRadius: BorderRadius.circular(18),
        child: Container(
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isEndpoint
                ? AppColors.primary
                : inRange
                ? AppColors.primaryLight
                : null,
            shape: isEndpoint ? BoxShape.circle : BoxShape.rectangle,
            border: isToday && !isEndpoint
                ? Border.all(color: AppColors.primary)
                : null,
          ),
          child: Text(
            '${day.day}',
            style: AppTextStyles.bodySmall.copyWith(
              color: disabled
                  ? AppColors.textMuted.withValues(alpha: 0.4)
                  : isEndpoint
                  ? AppColors.textOnPrimary
                  : AppColors.textBody,
              fontWeight: isEndpoint ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}
