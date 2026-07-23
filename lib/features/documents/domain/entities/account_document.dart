import 'package:equatable/equatable.dart';

/// One prior version of a document (shown in the expandable version-history
/// panel on the account Documents tab).
class DocumentVersion extends Equatable {
  final String version;
  final String modifiedByName;
  final DateTime date;
  final String notes;

  const DocumentVersion({
    required this.version,
    required this.modifiedByName,
    required this.date,
    this.notes = '',
  });

  @override
  List<Object?> get props => [version, modifiedByName, date, notes];
}

/// A document attached to an account. NOTE: currently backed by a local mock
/// datasource — there's no documents API contract wired yet, so this mirrors
/// the shape the Figma needs and can be swapped to a real model later.
class AccountDocument extends Equatable {
  final String id;
  final String name;
  final int sizeBytes;
  final String version;
  final String uploadedByName;
  final DateTime uploadedAt;
  final List<DocumentVersion> versions;

  const AccountDocument({
    required this.id,
    required this.name,
    required this.sizeBytes,
    required this.version,
    required this.uploadedByName,
    required this.uploadedAt,
    this.versions = const [],
  });

  bool get hasHistory => versions.isNotEmpty;

  /// File extension (lowercased, no dot) — drives the row icon.
  String get extension {
    final dot = name.lastIndexOf('.');
    return dot == -1 ? '' : name.substring(dot + 1).toLowerCase();
  }

  @override
  List<Object?> get props => [id, name, sizeBytes, version, uploadedByName, uploadedAt, versions];
}
