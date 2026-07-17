import 'package:equatable/equatable.dart';
import '../../domain/entities/lead.dart';

abstract class LeadDetailEvent extends Equatable {
  const LeadDetailEvent();
  @override
  List<Object?> get props => [];
}

class LeadDetailLoadRequested extends LeadDetailEvent {
  final String leadId;
  const LeadDetailLoadRequested(this.leadId);
  @override
  List<Object?> get props => [leadId];
}

class LeadDetailUpdateRequested extends LeadDetailEvent {
  final Lead lead;
  const LeadDetailUpdateRequested(this.lead);
  @override
  List<Object?> get props => [lead];
}

class LeadDetailConvertRequested extends LeadDetailEvent {
  final String leadId;
  const LeadDetailConvertRequested(this.leadId);
  @override
  List<Object?> get props => [leadId];
}
