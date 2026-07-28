import 'package:equatable/equatable.dart';

/// One failed row from a bulk contact import. `row` is 1-indexed matching the
/// spreadsheet (row 1 is the header, so data rows start at 2).
class ContactImportRowError extends Equatable {
  final int row;
  final String error;

  const ContactImportRowError({required this.row, required this.error});

  @override
  List<Object?> get props => [row, error];
}

/// Result of `POST /contacts/import` — always returned with HTTP 200 even when
/// some or all rows failed, so callers must inspect [errors]. A bad row never
/// blocks the rest of the file.
class ContactImportResult extends Equatable {
  final int created;
  final List<ContactImportRowError> errors;

  const ContactImportResult({required this.created, this.errors = const []});

  bool get hasErrors => errors.isNotEmpty;

  @override
  List<Object?> get props => [created, errors];
}
