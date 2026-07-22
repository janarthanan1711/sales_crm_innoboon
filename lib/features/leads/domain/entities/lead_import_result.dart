import 'package:equatable/equatable.dart';

/// One failed row from a bulk import. `row` is 1-indexed matching the
/// spreadsheet (row 1 is the header, so data rows start at 2).
class LeadImportRowError extends Equatable {
  final int row;
  final String error;

  const LeadImportRowError({required this.row, required this.error});

  @override
  List<Object?> get props => [row, error];
}

/// Result of `POST /leads/import` — always returned with HTTP 200 even when
/// some or all rows failed, so callers must inspect [errors].
class LeadImportResult extends Equatable {
  final int created;
  final List<LeadImportRowError> errors;

  const LeadImportResult({required this.created, this.errors = const []});

  bool get hasErrors => errors.isNotEmpty;

  @override
  List<Object?> get props => [created, errors];
}
