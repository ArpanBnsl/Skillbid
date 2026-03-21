import 'package:intl/intl.dart';

/// Formatters for dates, currency, etc.
class Formatters {
  /// Format date as "MMM dd, yyyy"
  static String formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date.toLocal());
  }

  /// Format date and time as "MMM dd, yyyy hh:mm a"
  static String formatDateTime(DateTime dateTime) {
    return DateFormat('MMM dd, yyyy hh:mm a').format(dateTime.toLocal());
  }

  /// Format time as "hh:mm a"
  static String formatTime(DateTime dateTime) {
    return DateFormat('hh:mm a').format(dateTime.toLocal());
  }

  /// Format currency with symbol
  static String formatCurrency(double amount, {String symbol = '₹'}) {
    return '$symbol${amount.toStringAsFixed(2)}';
  }

  /// Format currency short (no decimals)
  static String formatCurrencyShort(double amount, {String symbol = '₹'}) {
    return '$symbol${amount.toInt()}';
  }

  /// Format time difference (e.g., "2 hours ago")
  static String formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime.toLocal());

    if (diff.inSeconds < 60) {
      return 'now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes} min ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} hours ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else {
      return formatDate(dateTime);
    }
  }

  /// Context-aware timestamp for chat list items.
  static String formatChatTimestamp(DateTime dateTime) {
    final local = dateTime.toLocal();
    final now = DateTime.now();
    final sameDay = now.year == local.year && now.month == local.month && now.day == local.day;
    if (sameDay) {
      return formatTime(local);
    }
    return DateFormat('dd MMM').format(local);
  }

  /// Format number with commas (e.g., "1,234")
  static String formatNumber(num number) {
    final formatter = NumberFormat('#,###');
    return formatter.format(number);
  }

  /// Format phone number
  static String formatPhoneNumber(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleaned.length == 10) {
      return '${cleaned.substring(0, 3)}-${cleaned.substring(3, 6)}-${cleaned.substring(6)}';
    }
    return phone;
  }
}
