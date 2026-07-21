import 'package:equatable/equatable.dart';
import '../../domain/entities/deal.dart';

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
  final DealStage? stage;
  final bool clearOwner;
  final bool clearStage;
  const DealsListFilterChanged({
    this.ownerId,
    this.stage,
    this.clearOwner = false,
    this.clearStage = false,
  });
  @override
  List<Object?> get props => [ownerId, stage, clearOwner, clearStage];
}

class DealsListStageUpdated extends DealsListEvent {
  final String dealId;
  final DealStage newStage;
  final String? note;
  const DealsListStageUpdated({
    required this.dealId,
    required this.newStage,
    this.note,
  });
  @override
  List<Object?> get props => [dealId, newStage, note];
}
