import 'package:equatable/equatable.dart';
import '../../domain/entities/lead.dart';

abstract class LeadDetailState extends Equatable {
  const LeadDetailState();
  @override
  List<Object?> get props => [];
}

class LeadDetailInitial extends LeadDetailState {
  const LeadDetailInitial();
}

class LeadDetailLoading extends LeadDetailState {
  const LeadDetailLoading();
}

class LeadDetailLoaded extends LeadDetailState {
  final Lead lead;
  const LeadDetailLoaded(this.lead);
  @override
  List<Object?> get props => [lead];
}

class LeadDetailError extends LeadDetailState {
  final String message;
  const LeadDetailError(this.message);
  @override
  List<Object?> get props => [message];
}

class LeadDetailConverted extends LeadDetailState {
  final int accountId;
  const LeadDetailConverted(this.accountId);
  @override
  List<Object?> get props => [accountId];
}

class LeadDetailDeleted extends LeadDetailState {
  const LeadDetailDeleted();
}
