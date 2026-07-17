import 'package:intl/intl.dart';

class CurrencyFormatter {
  static String formatINR(double amount) {
    final format = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );
    return format.format(amount);
  }
}
