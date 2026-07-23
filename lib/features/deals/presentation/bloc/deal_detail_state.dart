import 'package:equatable/equatable.dart';
import '../../domain/entities/deal.dart';
import '../../domain/entities/deal_stage_def.dart';
import '../../domain/entities/deal_stage_history.dart';

abstract class DealDetailState extends Equatable {
  const DealDetailState();
  @override
  List<Object?> get props => [];
}

class DealDetailInitial extends DealDetailState {
  const DealDetailInitial();
}

class DealDetailLoading extends DealDetailState {
  const DealDetailLoading();
}

class DealDetailLoaded extends DealDetailState {
  final Deal deal;
  final List<DealStageDef> stages;
  final List<DealStageHistoryEntry> stageHistory;
  const DealDetailLoaded(this.deal, {this.stages = const [], this.stageHistory = const []});

  /// Resolve a stage id to its display name (for the stage-history rows).
  String stageName(int? id) {
    if (id == null) return '';
    final m = stages.where((s) => s.id == id);
    return m.isEmpty ? 'Stage $id' : m.first.name;
  }

  @override
  List<Object?> get props => [deal, stages, stageHistory];
}

class DealDetailError extends DealDetailState {
  final String message;
  const DealDetailError(this.message);
  @override
  List<Object?> get props => [message];
}
