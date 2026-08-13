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
  final int total;
  final String? search;
  final String? statusFilter;
  final String? sourceFilter;
  final int? ownerIdFilter;
  final DateTime? dateFromFilter;
  final DateTime? dateToFilter;

  const LeadsListLoaded({
    required this.leads,
    required this.total,
    this.search,
    this.statusFilter,
    this.sourceFilter,
    this.ownerIdFilter,
    this.dateFromFilter,
    this.dateToFilter,
  });

  @override
  List<Object?> get props => [
    leads,
    total,
    search,
    statusFilter,
    sourceFilter,
    ownerIdFilter,
    dateFromFilter,
    dateToFilter,
  ];
}

class LeadsListError extends LeadsListState {
  final String message;
  const LeadsListError(this.message);
  @override
  List<Object?> get props => [message];
}
