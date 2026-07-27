import 'package:equatable/equatable.dart';
import '../../domain/entities/deal.dart';
import '../../domain/entities/deal_activity.dart';
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
  final List<DealActivity> activities;

  /// True while an activity mutation (log/edit/delete) is in flight, so the
  /// Activity tab can show a subtle busy state without tearing down the tabs.
  final bool activityBusy;

  const DealDetailLoaded(
    this.deal, {
    this.stages = const [],
    this.stageHistory = const [],
    this.activities = const [],
    this.activityBusy = false,
  });

  DealDetailLoaded copyWith({
    List<DealStageHistoryEntry>? stageHistory,
    List<DealActivity>? activities,
    bool? activityBusy,
  }) {
    return DealDetailLoaded(
      deal,
      stages: stages,
      stageHistory: stageHistory ?? this.stageHistory,
      activities: activities ?? this.activities,
      activityBusy: activityBusy ?? this.activityBusy,
    );
  }

  /// Resolve a stage id to its display name (for the stage-history rows).
  String stageName(int? id) {
    if (id == null) return '';
    final m = stages.where((s) => s.id == id);
    return m.isEmpty ? 'Stage $id' : m.first.name;
  }

  @override
  List<Object?> get props => [deal, stages, stageHistory, activities, activityBusy];
}

class DealDetailError extends DealDetailState {
  final String message;
  const DealDetailError(this.message);
  @override
  List<Object?> get props => [message];
}
