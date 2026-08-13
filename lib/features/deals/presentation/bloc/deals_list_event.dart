import 'package:equatable/equatable.dart';

abstract class DealsListEvent extends Equatable {
  const DealsListEvent();
  @override
  List<Object?> get props => [];
}

class DealsListLoadRequested extends DealsListEvent {
  const DealsListLoadRequested();
}

class DealsListFilterChanged extends DealsListEvent {
  final int? ownerId;
  final List<int>? stageId;
  final bool clearOwner;
  final bool clearStage;

  // On-page "created_at"/"closed_at" range a rep picks while browsing —
  // separate from the constructor-only dashboard drill-down.
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final bool clearDate;

  // `created_at` or `closed_at` — which timestamp `dateFrom`/`dateTo` filter
  // against. The on-page date-range picker always sends `closed_at` now, so
  // its range agrees with the dashboard's Deals Closed tile by construction;
  // `created_at` only still reaches here via a dashboard drill-down that
  // asks for it explicitly.
  final String? dateField;

  const DealsListFilterChanged({
    this.ownerId,
    this.stageId,
    this.clearOwner = false,
    this.clearStage = false,
    this.dateFrom,
    this.dateTo,
    this.clearDate = false,
    this.dateField,
  });
  @override
  List<Object?> get props => [
    ownerId,
    stageId,
    clearOwner,
    clearStage,
    dateFrom,
    dateTo,
    clearDate,
    dateField,
  ];
}

class DealsListStageUpdated extends DealsListEvent {
  final String dealId;
  final int newStageId;
  final String? note;
  final String? coldReason;
  const DealsListStageUpdated({
    required this.dealId,
    required this.newStageId,
    this.note,
    this.coldReason,
  });
  @override
  List<Object?> get props => [dealId, newStageId, note, coldReason];
}
