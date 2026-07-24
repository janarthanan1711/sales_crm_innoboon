import 'package:equatable/equatable.dart';

abstract class ContactsListEvent extends Equatable {
  const ContactsListEvent();
  @override
  List<Object?> get props => [];
}

class ContactsListLoadRequested extends ContactsListEvent {
  const ContactsListLoadRequested();
}

class ContactsListSearchChanged extends ContactsListEvent {
  final String query;
  const ContactsListSearchChanged(this.query);
  @override
  List<Object?> get props => [query];
}

/// Filter change. A `null` field means "leave unchanged"; to clear the owner
/// or account filter, pass the [clearOwner]/[clearAccount] sentinel.
class ContactsListFilterChanged extends ContactsListEvent {
  /// Sentinel passed as `ownerId`/`accountId` to explicitly clear that filter.
  static const int clearOwner = -1;
  static const int clearAccount = -1;

  final Object? ownerId; // int | clearOwner sentinel | null (unchanged)
  final Object? accountId; // int | clearAccount sentinel | null (unchanged)
  final String? tier; // wire value, or 'all' to clear
  final bool? isPrimary; // toggle; null = leave unchanged

  const ContactsListFilterChanged({
    this.ownerId,
    this.accountId,
    this.tier,
    this.isPrimary,
  });

  @override
  List<Object?> get props => [ownerId, accountId, tier, isPrimary];
}

/// Clears search + every filter in one atomic reload.
class ContactsListCleared extends ContactsListEvent {
  const ContactsListCleared();
}

class ContactsListPageChanged extends ContactsListEvent {
  final int offset;
  const ContactsListPageChanged(this.offset);
  @override
  List<Object?> get props => [offset];
}

class ContactsListRowsPerPageChanged extends ContactsListEvent {
  final int limit;
  const ContactsListRowsPerPageChanged(this.limit);
  @override
  List<Object?> get props => [limit];
}

/// Deletes the given contacts, then reloads the current page.
class ContactsListDeleteRequested extends ContactsListEvent {
  final List<int> ids;
  const ContactsListDeleteRequested(this.ids);
  @override
  List<Object?> get props => [ids];
}
