/// Fields accepted by the backend's single upsert endpoint (`POST /leads`,
/// see `LeadUpsert` in saleshub/app/schemas/lead.py) that the app actually
/// collects through the create/edit form. `id` is handled separately by the
/// repository (present -> update, absent -> create) rather than living on
/// this params object, since a not-yet-created lead has no id yet.
class LeadUpsertParams {
  final String firstName;
  final String? lastName;
  final String company;
  final String? domain;
  final String? jobTitle;
  final String email;
  final String? phone;
  final String? linkedinUrl;
  final String source;
  final String? status;
  final int? ownerId;
  final DateTime? nextFollowUpDate;
  final String? followUpNote;

  const LeadUpsertParams({
    required this.firstName,
    this.lastName,
    required this.company,
    this.domain,
    this.jobTitle,
    required this.email,
    this.phone,
    this.linkedinUrl,
    required this.source,
    this.status,
    this.ownerId,
    this.nextFollowUpDate,
    this.followUpNote,
  });
}
