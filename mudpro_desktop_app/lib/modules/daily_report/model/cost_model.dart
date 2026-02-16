import 'package:flutter/material.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

class CostData {
  final String label;
  final double value;
  final Color color;
  final String? unit;
  final double? trend; // Positive or negative trend

  const CostData(
    this.label,
    this.value, {
    this.color = AppTheme.primaryColor,
    this.unit = '%',
    this.trend,
  });

  // Predefined color palette for charts
  static List<Color> chartColors = [
    AppTheme.primaryColor,
    AppTheme.secondaryColor,
    AppTheme.accentColor,
    AppTheme.successColor,
    AppTheme.warningColor,
    AppTheme.infoColor,
    Color(0xff9C27B0), // Purple
    Color(0xffFF9800), // Orange
    Color(0xff795548), // Brown
    Color(0xff607D8B), // Blue Grey
  ];
}