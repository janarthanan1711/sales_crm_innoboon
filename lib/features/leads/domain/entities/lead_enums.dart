/// Backend wire value <-> display label maps for lead-related enums.
/// Keys are the exact values `saleshub` sends/accepts on the wire (see
/// `app/models/enums.py`); values are the Title Case labels shown in the UI.
/// This is the single source of truth — dropdown option lists (see
/// `AppConstants.leadSources`/`leadStatuses`/`tiers`) are derived from these
/// maps' values, never independently maintained.
library;

const Map<String, String> leadSourceLabels = {
  'website': 'Website',
  'referral': 'Referral',
  'cold_call': 'Cold Call',
  'linkedin': 'LinkedIn',
  'email_campaign': 'Email Campaign',
  'other': 'Other',
};

const Map<String, String> leadStatusLabels = {
  'not_contacted': 'Not Contacted',
  'attempted_to_contact': 'Attempted to Contact',
  'contacted': 'Contacted',
  'contact_in_future': 'Contact in Future',
  'junk_lead': 'Junk Lead',
  'lost_lead': 'Lost Lead',
};

// Only used at lead-conversion time (LeadTier) — never a field on the lead
// itself.
const Map<String, String> leadTierLabels = {
  'diamond': 'Diamond',
  'gold': 'Gold',
  'silver': 'Silver',
  'bronze': 'Bronze',
};

const Map<String, String> leadActivityTypeLabels = {
  'note': 'Note',
  'meeting': 'Meeting',
  'call': 'Call',
  'comment': 'Comment',
  'follow_up': 'Follow-up',
};

/// Display label for a backend wire value; falls back to the raw value if
/// it's ever missing from the map (e.g. a new backend enum member the app
/// hasn't been updated for yet) so the UI degrades instead of crashing.
String labelForWireValue(Map<String, String> labels, String? wireValue) {
  if (wireValue == null) return '';
  return labels[wireValue] ?? wireValue;
}

/// Reverse lookup: display label -> backend wire value. Used by dropdowns,
/// which display labels but must submit wire values.
String? wireValueForLabel(Map<String, String> labels, String label) {
  for (final entry in labels.entries) {
    if (entry.value == label) return entry.key;
  }
  return null;
}
