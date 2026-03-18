import 'package:flutter/material.dart';

/// Extensions on BuildContext
extension BuildContextX on BuildContext {
  /// Get screen width
  double get screenWidth => MediaQuery.of(this).size.width;

  /// Get screen height
  double get screenHeight => MediaQuery.of(this).size.height;

  /// Get padding top (safe area)
  double get paddingTop => MediaQuery.of(this).padding.top;

  /// Get padding bottom (safe area)
  double get paddingBottom => MediaQuery.of(this).padding.bottom;

  /// Check if screen is landscape
  bool get isLandscape => MediaQuery.of(this).orientation == Orientation.landscape;

  /// Check if screen is portrait
  bool get isPortrait => MediaQuery.of(this).orientation == Orientation.portrait;

  /// Get theme data
  ThemeData get theme => Theme.of(this);

  /// Get text theme
  TextTheme get textTheme => Theme.of(this).textTheme;

  /// Get color scheme
  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  /// Get app's primary color
  Color get primaryColor => Theme.of(this).primaryColor;

  /// Push named route
  Future<T?> pushNamed<T>(String routeName, {Object? arguments}) {
    return Navigator.of(this).pushNamed(routeName, arguments: arguments);
  }

  /// Push and remove until
  Future<T?> pushNamedAndRemoveUntil<T>(String routeName, RoutePredicate predicate) {
    return Navigator.of(this).pushNamedAndRemoveUntil(routeName, predicate);
  }

  /// Pop
  void pop<T>([T? result]) => Navigator.of(this).pop(result);

  /// Show snackbar
  void showSnackBar(String message, {Duration duration = const Duration(seconds: 2)}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration,
      ),
    );
  }

  /// Show error snackbar
  void showErrorSnackBar(String message) {
    showSnackBar(message);
  }

  /// Show dialog
  Future<T?> showDialog<T>(Widget dialog) {
    return Navigator.of(this).push<T>(
      DialogRoute<T>(
        context: this,
        builder: (_) => dialog,
      ),
    );
  }
}

/// Extensions on String
extension StringX on String {
  /// Capitalize first letter
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  /// Check if valid email
  bool isValidEmail() {
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return emailRegex.hasMatch(this);
  }

  /// Check if contains only digits
  bool isNumeric() {
    return RegExp(r'^[0-9]+$').hasMatch(this);
  }

  /// Truncate string with ellipsis
  String truncate(int maxLength) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength)}...';
  }
}

/// Extensions on List
extension ListX<T> on List<T> {
  /// Get random element
  T? getRandomElement() {
    if (isEmpty) return null;
    return this[(DateTime.now().millisecondsSinceEpoch) % length];
  }
}

/// Extensions on DateTime
extension DateTimeX on DateTime {
  /// Check if today
  bool isToday() {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  /// Check if yesterday
  bool isYesterday() {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year && month == yesterday.month && day == yesterday.day;
  }

  /// Get days difference
  int getDaysDifference(DateTime other) {
    return difference(other).inDays.abs();
  }
}
