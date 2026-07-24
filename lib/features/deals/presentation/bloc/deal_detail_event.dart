import 'package:equatable/equatable.dart';

abstract class DealDetailEvent extends Equatable {
  const DealDetailEvent();
  @override
  List<Object?> get props => [];
}

class DealDetailLoadRequested extends DealDetailEvent {
  final String id;
  const DealDetailLoadRequested(this.id);
  @override
  List<Object?> get props => [id];
}

class DealDetailStageUpdateRequested extends DealDetailEvent {
  final String id;
  final int stageId;
  final String? note;
  final String? coldReason;
  const DealDetailStageUpdateRequested({
    required this.id,
    required this.stageId,
    this.note,
    this.coldReason,
  });
  @override
  List<Object?> get props => [id, stageId, note, coldReason];
}

class DealDetailActivityLogRequested extends DealDetailEvent {
  final String dealId;
  final String type;
  final String? title;
  final String note;
  const DealDetailActivityLogRequested(
    this.dealId, {
    required this.type,
    this.title,
    required this.note,
  });
  @override
  List<Object?> get props => [dealId, type, title, note];
}

class DealDetailActivityUpdateRequested extends DealDetailEvent {
  final String dealId;
  final String activityId;
  final String? type;
  final String? title;
  final String? note;
  const DealDetailActivityUpdateRequested(
    this.dealId,
    this.activityId, {
    this.type,
    this.title,
    this.note,
  });
  @override
  List<Object?> get props => [dealId, activityId, type, title, note];
}

class DealDetailActivityDeleteRequested extends DealDetailEvent {
  final String dealId;
  final String activityId;
  const DealDetailActivityDeleteRequested(this.dealId, this.activityId);
  @override
  List<Object?> get props => [dealId, activityId];
}
