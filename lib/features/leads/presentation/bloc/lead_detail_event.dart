import 'package:equatable/equatable.dart';

abstract class LeadDetailEvent extends Equatable {
  const LeadDetailEvent();
  @override
  List<Object?> get props => [];
}

class LeadDetailLoadRequested extends LeadDetailEvent {
  final int leadId;
  const LeadDetailLoadRequested(this.leadId);
  @override
  List<Object?> get props => [leadId];
}

class LeadDetailConvertRequested extends LeadDetailEvent {
  final int leadId;
  final String? tier;
  final int? ownerId;
  const LeadDetailConvertRequested(this.leadId, {this.tier, this.ownerId});
  @override
  List<Object?> get props => [leadId, tier, ownerId];
}

class LeadDetailDeleteRequested extends LeadDetailEvent {
  final int leadId;
  const LeadDetailDeleteRequested(this.leadId);
  @override
  List<Object?> get props => [leadId];
}
