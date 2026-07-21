import '../../domain/entities/lead.dart';
import '../../domain/usecases/lead_upsert_params.dart';

/// Lead model with JSON serialization — data layer. Maps 1:1 to the
/// backend's `LeadRead`/`LeadDetailRead` shapes (snake_case wire keys ->
/// camelCase entity fields). Enum fields keep the raw backend wire value
/// (e.g. 'website', 'not_contacted') — label translation only happens in
/// presentation widgets, never here.
class LeadModel extends Lead {
  const LeadModel({
    required super.id,
    required super.firstName,
    super.lastName,
    required super.company,
    super.domain,
    super.jobTitle,
    required super.email,
    super.phone,
    super.linkedinUrl,
    required super.source,
    required super.status,
    super.ownerId,
    super.ownerName,
    super.nextFollowUpDate,
    super.followUpNote,
    required super.isConverted,
    required super.updatedAt,
    super.contacts,
    super.activities,
    super.activityCount,
  });

  /// Parses a `LeadRead` response body. Also handles `LeadDetailRead`
  /// (list/get-by-id share this shape; detail adds `contacts`/`activities`/
  /// `activity_count`, which are simply absent — and left null — on the
  /// plain list shape).
  factory LeadModel.fromJson(Map<String, dynamic> json) {
    final rawContacts = json['contacts'] as List<dynamic>?;
    final rawActivities = json['activities'] as List<dynamic>?;

    return LeadModel(
      id: json['id'] as int,
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String?,
      company: json['company'] as String,
      domain: json['domain'] as String?,
      jobTitle: json['job_title'] as String?,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      linkedinUrl: json['linkedin_url'] as String?,
      source: json['source'] as String,
      status: json['status'] as String,
      ownerId: json['owner_id'] as int?,
      ownerName: json['owner_name'] as String?,
      nextFollowUpDate: json['next_follow_up_date'] != null
          ? DateTime.parse(json['next_follow_up_date'] as String)
          : null,
      followUpNote: json['follow_up_note'] as String?,
      isConverted: json['is_converted'] as bool,
      updatedAt: DateTime.parse(json['updated_at'] as String),
      contacts: rawContacts
          ?.map(
            (c) => LeadContact(
              id: c['id'] as int,
              email: c['email'] as String?,
              phone: c['phone'] as String?,
            ),
          )
          .toList(),
      activities: rawActivities
          ?.map(
            (a) => LeadActivity(
              id: a['id'] as int,
              leadId: a['lead_id'] as int,
              type: a['type'] as String,
              note: a['note'] as String,
              createdBy: a['created_by'] as int,
              createdAt: DateTime.parse(a['created_at'] as String),
              createdByName: a['created_by_name'] as String?,
            ),
          )
          .toList(),
      activityCount: json['activity_count'] as int?,
    );
  }

  /// Request body for `POST /leads`. `id` is included only for updates
  /// (server: present -> partial update, absent -> create). `contacts` is
  /// intentionally never sent — the server ignores it on update anyway
  /// (see `lead_service.update_lead`'s `exclude={"id", "contacts"}`) and the
  /// app doesn't yet collect extra contacts through the form.
  static Map<String, dynamic> toUpsertJson(
    LeadUpsertParams params, {
    int? id,
  }) {
    return {
      if (id != null) 'id': id,
      'first_name': params.firstName,
      'last_name': params.lastName,
      'company': params.company,
      'domain': params.domain,
      'job_title': params.jobTitle,
      'email': params.email,
      'phone': params.phone,
      'linkedin_url': params.linkedinUrl,
      'source': params.source,
      'status': params.status,
      'owner_id': params.ownerId,
      'next_follow_up_date': params.nextFollowUpDate != null
          ? _formatDate(params.nextFollowUpDate!)
          : null,
      'follow_up_note': params.followUpNote,
      if (params.additionalEmails != null && params.additionalEmails!.isNotEmpty)
        'contacts': params.additionalEmails!.map((e) => {'email': e}).toList(),
    };
  }

  static String _formatDate(DateTime date) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${date.year}-${two(date.month)}-${two(date.day)}';
  }
}
