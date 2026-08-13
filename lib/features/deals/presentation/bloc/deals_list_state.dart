import 'package:equatable/equatable.dart';
import '../../domain/entities/deal.dart';
import '../../domain/entities/deal_stage_def.dart';

abstract class DealsListState extends Equatable {
  const DealsListState();
  @override
  List<Object?> get props => [];
}

class DealsListInitial extends DealsListState {
  const DealsListInitial();
}

class DealsListLoading extends DealsListState {
  const DealsListLoading();
}

class DealsListLoaded extends DealsListState {
  final List<Deal> deals;
  final List<DealStageDef> stages;
  final int? ownerIdFilter;
  final List<int>? stageIdFilter;

  // On-page `created_at` range filter (separate from the constructor-only
  // dashboard drill-down range).
  final DateTime? dateFromFilter;
  final DateTime? dateToFilter;

  /// One-shot error surfaced after a failed stage update (e.g. a kanban
  /// drag) — read once via `BlocListener`, not persisted.
  final String? actionError;

  const DealsListLoaded({
    required this.deals,
    this.stages = const [],
    this.ownerIdFilter,
    this.stageIdFilter,
    this.dateFromFilter,
    this.dateToFilter,
    this.actionError,
  });

  @override
  List<Object?> get props => [
    deals,
    stages,
    ownerIdFilter,
    stageIdFilter,
    dateFromFilter,
    dateToFilter,
    actionError,
  ];
}

class DealsListError extends DealsListState {
  final String message;
  const DealsListError(this.message);
  @override
  List<Object?> get props => [message];
}
