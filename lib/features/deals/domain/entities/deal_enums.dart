/// Backend wire value <-> display label map for deal activity types.
/// Keys are the exact values `saleshub` sends/accepts on the wire (see API
/// §6.9); values are the Title Case labels shown in the UI.
library;

const Map<String, String> dealActivityTypeLabels = {
  'note': 'Note',
  'meeting': 'Meeting',
  'call': 'Call',
  'comment': 'Comment',
  'follow_up': 'Follow-up',
};

/// Display label for a backend wire value; falls back to the raw value if
/// it's missing from [labels] so the UI degrades instead of crashing.
String labelForWireValue(Map<String, String> labels, String? wireValue) {
  if (wireValue == null) return '';
  return labels[wireValue] ?? wireValue;
}
