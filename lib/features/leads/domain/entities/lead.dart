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
  // Backend wire value: note/meeting/call/comment/follow_up. Null for
  // auto-logged activities that don't fit a category (e.g. the favourite
  // toggle's "marked as favourite" note) -- the backend's own schema types
  // this `LeadActivityType | None` for exactly that reason.
  final String? type;
  final String note;
  final int createdBy;
  final DateTime createdAt;
  final String? createdByName; // only present on the detail-view shape
  final int? updatedBy;
  final String? updatedByName;
  final DateTime? updatedAt;

  const LeadActivity({
    required this.id,
    required this.leadId,
    required this.type,
    required this.note,
    required this.createdBy,
    required this.createdAt,
    this.createdByName,
    this.updatedBy,
    this.updatedByName,
    this.updatedAt,
  });

  LeadActivity copyWith({
    int? id,
    int? leadId,
    String? type,
    String? note,
    int? createdBy,
    DateTime? createdAt,
    String? createdByName,
    int? updatedBy,
    String? updatedByName,
    DateTime? updatedAt,
  }) {
    return LeadActivity(
      id: id ?? this.id,
      leadId: leadId ?? this.leadId,
      type: type ?? this.type,
      note: note ?? this.note,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      createdByName: createdByName ?? this.createdByName,
      updatedBy: updatedBy ?? this.updatedBy,
      updatedByName: updatedByName ?? this.updatedByName,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    leadId,
    type,
    note,
    createdBy,
    createdAt,
    createdByName,
    updatedBy,
    updatedByName,
    updatedAt,
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
  final DateTime? createdAt;
  final List<LeadContact>? contacts;
  final List<LeadActivity>? activities;
  final int? activityCount;
  final bool isFavourite;

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
    this.createdAt,
    this.contacts,
    this.activities,
    this.activityCount,
    this.isFavourite = false,
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
    DateTime? createdAt,
    List<LeadContact>? contacts,
    List<LeadActivity>? activities,
    int? activityCount,
    bool? isFavourite,
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
      createdAt: createdAt ?? this.createdAt,
      contacts: contacts ?? this.contacts,
      activities: activities ?? this.activities,
      activityCount: activityCount ?? this.activityCount,
      isFavourite: isFavourite ?? this.isFavourite,
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
    createdAt,
    contacts,
    activities,
    activityCount,
    isFavourite,
  ];
}
