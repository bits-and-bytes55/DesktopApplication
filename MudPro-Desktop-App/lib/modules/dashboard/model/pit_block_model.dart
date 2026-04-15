
import 'package:flutter/material.dart';

class PitBlock {
  final String title;
  final String subtitle;
  final Color color;
  final bool isActive;

  PitBlock({
    required this.title,
    required this.subtitle,
    required this.color,
    this.isActive = true,
  });
}
