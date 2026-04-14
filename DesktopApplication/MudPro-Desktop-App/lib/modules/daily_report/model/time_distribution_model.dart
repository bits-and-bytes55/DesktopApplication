// time_distribution_model.dart
import 'package:flutter/material.dart';

class TimeDistributionModel {
  final String event;
  final double hours;
  final double percent;
  final Color color;

  TimeDistributionModel({
    required this.event,
    required this.hours,
    required this.percent,
    this.color = Colors.blue,
  });
}