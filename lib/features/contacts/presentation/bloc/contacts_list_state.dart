import 'package:equatable/equatable.dart';
import '../../domain/entities/contact.dart';

abstract class ContactsListState extends Equatable {
  const ContactsListState();
  @override
  List<Object?> get props => [];
}

class ContactsListInitial extends ContactsListState {
  const ContactsListInitial();
}

class ContactsListLoading extends ContactsListState {
  const ContactsListLoading();
}

class ContactsListLoaded extends ContactsListState {
  final List<Contact> contacts;
  final int total;
  final int limit;
  final int offset;
  final String? search;
  final int? ownerFilter;
  final int? accountFilter;
  final String? tierFilter;
  final bool primaryOnly;

  /// Non-null when a mutation (e.g. delete) failed — surfaced as a snackbar.
  final String? actionError;

  const ContactsListLoaded({
    required this.contacts,
    required this.total,
    required this.limit,
    required this.offset,
    this.search,
    this.ownerFilter,
    this.accountFilter,
    this.tierFilter,
    this.primaryOnly = false,
    this.actionError,
  });

  @override
  List<Object?> get props => [
    contacts,
    total,
    limit,
    offset,
    search,
    ownerFilter,
    accountFilter,
    tierFilter,
    primaryOnly,
    actionError,
  ];
}

class ContactsListError extends ContactsListState {
  final String message;
  const ContactsListError(this.message);
  @override
  List<Object?> get props => [message];
}
