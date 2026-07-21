import 'package:equatable/equatable.dart';
import '../../domain/entities/deal.dart';

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
  final int? ownerIdFilter;
  final DealStage? stageFilter;
  /// One-shot error surfaced after a failed stage update (e.g. from a
  /// kanban drag) — read once via `BlocListener`, not persisted.
  final String? actionError;

  const DealsListLoaded({
    required this.deals,
    this.ownerIdFilter,
    this.stageFilter,
    this.actionError,
  });

  @override
  List<Object?> get props => [deals, ownerIdFilter, stageFilter, actionError];
}

class DealsListError extends DealsListState {
  final String message;
  const DealsListError(this.message);
  @override
  List<Object?> get props => [message];
}
