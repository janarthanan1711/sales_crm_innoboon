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

/// Re-fetches the activity list (Activity tab) with the given filters.
/// Pass empty [types] and null [dateFrom]/[dateTo] to clear all filters.
class LeadDetailActivityFilterChanged extends LeadDetailEvent {
  final int leadId;
  final Set<String> types;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  const LeadDetailActivityFilterChanged(
    this.leadId, {
    this.types = const {},
    this.dateFrom,
    this.dateTo,
  });
  @override
  List<Object?> get props => [leadId, types, dateFrom, dateTo];
}

class LeadDetailActivityLogRequested extends LeadDetailEvent {
  final int leadId;
  final String type;
  final String note;
  const LeadDetailActivityLogRequested(
    this.leadId, {
    required this.type,
    required this.note,
  });
  @override
  List<Object?> get props => [leadId, type, note];
}

class LeadDetailActivityUpdateRequested extends LeadDetailEvent {
  final int leadId;
  final int activityId;
  final String type;
  final String note;
  const LeadDetailActivityUpdateRequested(
    this.leadId,
    this.activityId, {
    required this.type,
    required this.note,
  });
  @override
  List<Object?> get props => [leadId, activityId, type, note];
}

class LeadDetailActivityDeleteRequested extends LeadDetailEvent {
  final int leadId;
  final int activityId;
  const LeadDetailActivityDeleteRequested(this.leadId, this.activityId);
  @override
  List<Object?> get props => [leadId, activityId];
}
