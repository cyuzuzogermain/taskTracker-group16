import 'package:flutter/material.dart';

import '../models/sla_status.dart';

/// The colour pair used to show an SLA status: dark text on a light tint.
///
/// Chips, task card edges and the SLA card all read their colours from
/// here, so a status looks the same everywhere in the app.
class SlaColors {
  final Color text;
  final Color background;

  const SlaColors({required this.text, required this.background});

  /// Returns the colours for the given status.
  static SlaColors of(SlaStatus status) {
    switch (status) {
      case SlaStatus.onTrack:
        return const SlaColors(
          text: Color(0xFF1E6B41),
          background: Color(0xFFE7F4EC),
        );
      case SlaStatus.atRisk:
        return const SlaColors(
          text: Color(0xFF9A5B00),
          background: Color(0xFFFFF4E0),
        );
      case SlaStatus.overdue:
        return const SlaColors(
          text: Color(0xFFB3261E),
          background: Color(0xFFFDECEA),
        );
      case SlaStatus.completed:
        return const SlaColors(
          text: Color(0xFF5B6472),
          background: Color(0xFFEEF0F3),
        );
    }
  }
}
