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

/// Clears the search text and every filter in a single event, so the list
/// reloads exactly once with a clean slate (dispatching separate search +
/// filter events can race and leave a stale filter applied).
class LeadsListCleared extends LeadsListEvent {
  const LeadsListCleared();
}

class LeadsListFavouriteToggled extends LeadsListEvent {
  final int leadId;
  final bool isFavourite;
  const LeadsListFavouriteToggled(this.leadId, this.isFavourite);
  @override
  List<Object?> get props => [leadId, isFavourite];
}
