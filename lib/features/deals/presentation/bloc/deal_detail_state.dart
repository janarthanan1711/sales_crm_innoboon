import 'package:equatable/equatable.dart';
import '../../domain/entities/deal.dart';
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
  final List<DealStageHistoryEntry> stageHistory;
  const DealDetailLoaded(this.deal, {this.stageHistory = const []});
  @override
  List<Object?> get props => [deal, stageHistory];
}

class DealDetailError extends DealDetailState {
  final String message;
  const DealDetailError(this.message);
  @override
  List<Object?> get props => [message];
}
