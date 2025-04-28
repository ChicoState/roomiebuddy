import 'package:flutter/material.dart';

/// Converts a DateTime and TimeOfDay into a Unix timestamp (seconds since epoch).
/// Returns null if either date or time is null.
double? dateTimeToTimestamp(DateTime? date, TimeOfDay? time) {
  if (date == null || time == null) {
    return null;
  }
  final combinedDateTime = DateTime(
    date.year,
    date.month,
    date.day,
    time.hour,
    time.minute,
  );
  // Convert to seconds since epoch (Unix timestamp)
  return combinedDateTime.millisecondsSinceEpoch / 1000.0;
}

/// Converts a priority string ('Low', 'Medium', 'High') to an integer.
/// Returns 0 for 'Low', 1 for 'Medium', 2 for 'High'.
/// Returns 0 (Low) if the input is null or doesn't match.
int priorityToInt(String? priority) {
  switch (priority) {
    case 'Low':
      return 0;
    case 'Medium':
      return 1;
    case 'High':
      return 2;
    default:
      return 0; // Default to Low if null or unknown
  }
} 