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
