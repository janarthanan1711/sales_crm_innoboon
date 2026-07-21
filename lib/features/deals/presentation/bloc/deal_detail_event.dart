import 'package:equatable/equatable.dart';
import '../../domain/entities/deal.dart';

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
  final DealStage stage;
  final String? note;
  const DealDetailStageUpdateRequested({
    required this.id,
    required this.stage,
    this.note,
  });
  @override
  List<Object?> get props => [id, stage, note];
}
