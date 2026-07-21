import 'package:equatable/equatable.dart';

/// An extra contact point on a lead (beyond its own primary email/phone).
/// Detail-view only — comes back from `GET /leads/{id}` as part of
/// `LeadDetailRead.contacts`.
class LeadContact extends Equatable {
  final int id;
  final String? email;
  final String? phone;

  const LeadContact({required this.id, this.email, this.phone});

  @override
  List<Object?> get props => [id, email, phone];
}

/// One entry in a lead's activity log. Detail-view only — comes back from
/// `GET /leads/{id}` as part of `LeadDetailRead.activities`, and is also the
/// response shape of `POST /leads/{id}/activities`.
class LeadActivity extends Equatable {
  final int id;
  final int leadId;
  final String type; // backend wire value: note/meeting/call/comment
  final String note;
  final int createdBy;
  final DateTime createdAt;
  final String? createdByName; // only present on the detail-view shape

  const LeadActivity({
    required this.id,
    required this.leadId,
    required this.type,
    required this.note,
    required this.createdBy,
    required this.createdAt,
    this.createdByName,
  });

  @override
  List<Object?> get props => [
    id,
    leadId,
    type,
    note,
    createdBy,
    createdAt,
    createdByName,
  ];
}

/// Lead entity — domain layer. Mirrors the backend's `LeadRead` shape
/// exactly (see saleshub/app/schemas/lead.py). `source`/`status` are always
/// backend wire values (e.g. 'website', 'not_contacted') — presentation
/// widgets translate those to display labels, never the other way round.
///
/// `contacts`/`activities`/`activityCount` are only populated when this
/// [Lead] came from the single-lead detail endpoint (`LeadDetailRead`); they
/// are null for leads loaded from the list endpoint (`LeadRead`), same as
/// how `Account.contacts` is embedded directly rather than split into a
/// separate detail entity.
class Lead extends Equatable {
  final int id;
  final String firstName;
  final String? lastName;
  final String company;
  final String? domain;
  final String? jobTitle;
  final String email;
  final String? phone;
  final String? linkedinUrl;
  final String source;
  final String status;
  final int? ownerId;
  final String? ownerName;
  final DateTime? nextFollowUpDate;
  final String? followUpNote;
  final bool isConverted;
  final DateTime updatedAt;
  final List<LeadContact>? contacts;
  final List<LeadActivity>? activities;
  final int? activityCount;

  const Lead({
    required this.id,
    required this.firstName,
    this.lastName,
    required this.company,
    this.domain,
    this.jobTitle,
    required this.email,
    this.phone,
    this.linkedinUrl,
    required this.source,
    required this.status,
    this.ownerId,
    this.ownerName,
    this.nextFollowUpDate,
    this.followUpNote,
    required this.isConverted,
    required this.updatedAt,
    this.contacts,
    this.activities,
    this.activityCount,
  });

  Lead copyWith({
    int? id,
    String? firstName,
    String? lastName,
    String? company,
    String? domain,
    String? jobTitle,
    String? email,
    String? phone,
    String? linkedinUrl,
    String? source,
    String? status,
    int? ownerId,
    String? ownerName,
    DateTime? nextFollowUpDate,
    String? followUpNote,
    bool? isConverted,
    DateTime? updatedAt,
    List<LeadContact>? contacts,
    List<LeadActivity>? activities,
    int? activityCount,
  }) {
    return Lead(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      company: company ?? this.company,
      domain: domain ?? this.domain,
      jobTitle: jobTitle ?? this.jobTitle,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      linkedinUrl: linkedinUrl ?? this.linkedinUrl,
      source: source ?? this.source,
      status: status ?? this.status,
      ownerId: ownerId ?? this.ownerId,
      ownerName: ownerName ?? this.ownerName,
      nextFollowUpDate: nextFollowUpDate ?? this.nextFollowUpDate,
      followUpNote: followUpNote ?? this.followUpNote,
      isConverted: isConverted ?? this.isConverted,
      updatedAt: updatedAt ?? this.updatedAt,
      contacts: contacts ?? this.contacts,
      activities: activities ?? this.activities,
      activityCount: activityCount ?? this.activityCount,
    );
  }

  @override
  List<Object?> get props => [
    id,
    firstName,
    lastName,
    company,
    domain,
    jobTitle,
    email,
    phone,
    linkedinUrl,
    source,
    status,
    ownerId,
    ownerName,
    nextFollowUpDate,
    followUpNote,
    isConverted,
    updatedAt,
    contacts,
    activities,
    activityCount,
  ];
}
