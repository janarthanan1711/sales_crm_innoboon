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

  const LeadsListLoaded({
    required this.leads,
    required this.total,
    this.search,
    this.statusFilter,
    this.sourceFilter,
    this.ownerIdFilter,
  });

  @override
  List<Object?> get props => [
    leads,
    total,
    search,
    statusFilter,
    sourceFilter,
    ownerIdFilter,
  ];
}

class LeadsListError extends LeadsListState {
  final String message;
  const LeadsListError(this.message);
  @override
  List<Object?> get props => [message];
}
