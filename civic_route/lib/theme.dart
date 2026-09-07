import 'package:flutter/material.dart';

class AppColors {
  static const brandPrimary = Color(0xFF0B1B34);
  static const brandSecondary = Color(0xFF1E3A5F);
  static const accent = Color(0xFFC0392B);
  static const accentSoft = Color(0xFFFCEAE7);
  static const surface = Colors.white;
  static const surfaceSecondary = Color(0xFFF7F8FB);
  static const surfaceTertiary = Color(0xFFEEF1F6);
  static const muted = Color(0xFF64748B);
  static const border = Color(0xFFE5E9F0);
  static const federal = Color(0xFF1E3A5F);
  static const state = Color(0xFF2E7D5B);
  static const county = Color(0xFFB45309);
  static const error = Color(0xFFB91C1C);
}

class AppGradients {
  static const background = LinearGradient(
    colors: [Color(0xFF0B1B34), Color(0xFF16345C), Color(0xFFC0392B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.0, 0.55, 1.0],
  );
}
