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
  final String? owner;
  final String? tier;
  const DealsListFilterChanged({this.owner, this.tier});
  @override
  List<Object?> get props => [owner, tier];
}

class DealsListStageUpdated extends DealsListEvent {
  final String dealId;
  final DealStage newStage;
  const DealsListStageUpdated({required this.dealId, required this.newStage});
  @override
  List<Object?> get props => [dealId, newStage];
}
