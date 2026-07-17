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

class LeadsListFilterChanged extends LeadsListEvent {
  final String? status;
  final String? tier;
  final String? owner;
  final String? source;

  const LeadsListFilterChanged({
    this.status,
    this.tier,
    this.owner,
    this.source,
  });
  @override
  List<Object?> get props => [status, tier, owner, source];
}
