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
  final int? stageId;
  final bool clearOwner;
  final bool clearStage;
  const DealsListFilterChanged({
    this.ownerId,
    this.stageId,
    this.clearOwner = false,
    this.clearStage = false,
  });
  @override
  List<Object?> get props => [ownerId, stageId, clearOwner, clearStage];
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
