import 'package:intl/intl.dart';

/// Currency formatting helpers (INR style: ₹45,00,000)
class CurrencyFormatter {
  CurrencyFormatter._();

  static final NumberFormat _inrFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  static final NumberFormat _inrFormatWithDecimals = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );

  /// Format as INR currency: ₹45,00,000
  static String formatINR(double amount, {bool showDecimals = false}) {
    if (showDecimals) {
      return _inrFormatWithDecimals.format(amount);
    }
    return _inrFormat.format(amount);
  }

  /// Format compact: ₹18.5L, ₹1.2Cr
  static String formatCompact(double amount) {
    if (amount >= 10000000) {
      return '₹${(amount / 10000000).toStringAsFixed(1)}Cr';
    }
    if (amount >= 100000) {
      return '₹${(amount / 100000).toStringAsFixed(1)}L';
    }
    if (amount >= 1000) {
      return '₹${(amount / 1000).toStringAsFixed(1)}K';
    }
    return '₹${amount.toStringAsFixed(0)}';
  }

  /// Parse INR string back to double
  static double? parseINR(String value) {
    final cleaned = value
        .replaceAll('₹', '')
        .replaceAll(',', '')
        .trim();
    return double.tryParse(cleaned);
  }
}

/// Date formatting helpers
class DateFormatter {
  DateFormatter._();

  static final DateFormat _displayDate = DateFormat('dd-MMM-yyyy');
  static final DateFormat _shortDate = DateFormat('MMM dd, yyyy');
  static final DateFormat _dateTime = DateFormat('dd-MMM-yyyy, h:mm a');
  static final DateFormat _timeOnly = DateFormat('h:mm a');
  static final DateFormat _apiDate = DateFormat('yyyy-MM-dd');

  static String displayDate(DateTime date) => _displayDate.format(date);
  static String shortDate(DateTime date) => _shortDate.format(date);
  static String dateTime(DateTime date) => _dateTime.format(date);
  static String timeOnly(DateTime date) => _timeOnly.format(date);
  static String apiDate(DateTime date) => _apiDate.format(date);

  /// Relative time: "2 hrs ago", "Yesterday", "3 days ago"
  static String relativeTime(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hrs ago';
    if (diff.inDays < 2) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()} weeks ago';
    return _shortDate.format(date);
  }

  /// Days remaining: "(72 days remaining)"
  static String daysRemaining(DateTime futureDate) {
    final days = futureDate.difference(DateTime.now()).inDays;
    if (days < 0) return '(${-days} days overdue)';
    if (days == 0) return '(Due today)';
    if (days == 1) return '(Tomorrow)';
    return '($days days remaining)';
  }
}
