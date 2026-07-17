import 'package:equatable/equatable.dart';
import '../../domain/entities/lead.dart';

abstract class LeadsListState extends Equatable {
  const LeadsListState();
  @override
  List<Object?> get props => [];
}

class LeadsListInitial extends LeadsListState {
  const LeadsListInitial();
}

class LeadsListLoading extends LeadsListState {
  const LeadsListLoading();
}

class LeadsListLoaded extends LeadsListState {
  final List<Lead> leads;
  final String? search;
  final String? statusFilter;
  final String? tierFilter;
  final String? ownerFilter;
  final String? sourceFilter;

  const LeadsListLoaded({
    required this.leads,
    this.search,
    this.statusFilter,
    this.tierFilter,
    this.ownerFilter,
    this.sourceFilter,
  });

  @override
  List<Object?> get props => [
    leads,
    search,
    statusFilter,
    tierFilter,
    ownerFilter,
    sourceFilter,
  ];
}

class LeadsListError extends LeadsListState {
  final String message;
  const LeadsListError(this.message);
  @override
  List<Object?> get props => [message];
}
