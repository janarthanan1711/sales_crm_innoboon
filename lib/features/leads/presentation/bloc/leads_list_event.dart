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
///
/// `dateFrom`/`dateTo` filter on `created_at` (both inclusive). `clearDate`
/// resets the whole range together — there's no separate clear for just one
/// end, since a lone `dateFrom` or `dateTo` isn't a meaningful filter state.
class LeadsListFilterChanged extends LeadsListEvent {
  final String? status;
  final String? source;
  final int? ownerId;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final bool clearDate;

  const LeadsListFilterChanged({
    this.status,
    this.source,
    this.ownerId,
    this.dateFrom,
    this.dateTo,
    this.clearDate = false,
  });
  @override
  List<Object?> get props => [
    status,
    source,
    ownerId,
    dateFrom,
    dateTo,
    clearDate,
  ];
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
