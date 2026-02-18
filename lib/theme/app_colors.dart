import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color seedColor = Color.fromARGB(255, 9, 41, 68);
  static const Color danger = Colors.red;
  static const Color white = Colors.white;

  static Color primary(BuildContext context) =>
      Theme.of(context).colorScheme.primary;
  static Color surface(BuildContext context) =>
      Theme.of(context).colorScheme.surface;
  static Color onPrimary(BuildContext context) =>
      Theme.of(context).colorScheme.onPrimary;

  static Color grey(BuildContext context, int shade) {
    return Colors.grey[shade] ?? Colors.grey;
  }

  static Color blackWithOpacity(double opacity) =>
      Colors.black.withOpacity(opacity);

  static Color black87() => Colors.black87;

  static Color blue300() => Colors.blue[300] ?? Colors.blue;
}
