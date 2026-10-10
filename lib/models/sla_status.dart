/// The four SLA states a task can be in.
///
/// This file only names the states. The rules that decide which state a
/// task is in live in the SLA service, and the colours live in the theme.
enum SlaStatus {
  onTrack('On Track'),
  atRisk('At Risk'),
  overdue('Overdue'),
  completed('Completed');

  const SlaStatus(this.label);

  /// Readable text shown in the UI.
  final String label;
}
