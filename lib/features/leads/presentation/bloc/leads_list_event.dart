import 'package:equatable/equatable.dart';

abstract class LeadsListEvent extends Equatable {
  const LeadsListEvent();
  @override
  List<Object?> get props => [];
}

class LeadsListLoadRequested extends LeadsListEvent {
  const LeadsListLoadRequested();
}

class LeadsListSearchChanged extends LeadsListEvent {
  final String query;
  const LeadsListSearchChanged(this.query);
  @override
  List<Object?> get props => [query];
}

/// Filter values are backend wire values (e.g. 'website', 'not_contacted'),
/// already translated from the display label by the caller.
class LeadsListFilterChanged extends LeadsListEvent {
  final String? status;
  final String? source;
  final int? ownerId;

  const LeadsListFilterChanged({this.status, this.source, this.ownerId});
  @override
  List<Object?> get props => [status, source, ownerId];
}
