/// Utility functions for parsing dates in various formats.
class DateParser {
  static DateTime? parseTaskDate(String dateStr) {
    DateTime? eventDateTime;
    
    // Try direct parsing first (standard ISO format)
    try {
      eventDateTime = DateTime.parse(dateStr);
      return eventDateTime;
    } catch (parseError) {
      // If direct parsing fails, try manual parsing
      try {
        final parts = dateStr.split(', ');
        if (parts.length > 1) {
          final dateParts = parts[1].split(' '); // ["23", "Apr", "2025", "00:27:00", "GMT"]
          
          if (dateParts.length >= 3) {
            final day = int.tryParse(dateParts[0]) ?? 1;
            
            // Convert month name to number
            final monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
            final month = monthNames.indexOf(dateParts[1]) + 1; // 1-based
            
            final year = int.tryParse(dateParts[2]) ?? DateTime.now().year;
            
            if (month > 0) { // Ensure we got a valid month
              return DateTime.utc(year, month, day);
            }
          }
        }
      } catch (e) {
        // If manual parsing fails too, return null
        return null;
      }
    }
    
    return null;
  }
  
  static DateTime normalizeDate(DateTime date) {
    return DateTime.utc(date.year, date.month, date.day);
  }
  
  static String formatDate(DateTime date) {
    return '${date.month}-${date.day}-${date.year}';
  }
} 