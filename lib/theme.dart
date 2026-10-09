/// Shared colors and gradient for the whole app.
///
/// `AppColors.of(context)` returns the light or dark palette to match the
/// system theme; every content screen (Category, Results, Resident hub,
/// Onboarding) reads its colors from here so the app stays consistent.
/// `main.dart` also uses these values to build its `ThemeData`. The fixed
/// `AppGradients.background` is the branded backdrop behind the Home,
/// Onboarding and Tutorial screens.
library;

import 'package:flutter/material.dart';

/// Theme-aware brand palette.
///
/// Every screen that shows content on a plain surface (Category, Results,
/// Resident hub, Onboarding) should read colors through [AppColors.of]
/// instead of the old static constants, so the whole app actually follows
/// system light/dark mode instead of only the gradient hero screen doing so.
///
/// [HomeScreen] and the tutorial/onboarding hero art are intentionally
/// exempt: they're a fixed-color gradient/brand backdrop with white text by
/// design, the same way a splash screen doesn't flip with system theme.
class AppColors {
  final Color brandPrimary;
  final Color brandSecondary;
  final Color accent;
  final Color accentSoft;
  final Color surface;
  final Color surfaceSecondary;
  final Color surfaceTertiary;
  final Color textPrimary;
  final Color muted;
  final Color border;
  final Color federal;
  final Color state;
  final Color county;
  final Color error;

  const AppColors._({
    required this.brandPrimary,
    required this.brandSecondary,
    required this.accent,
    required this.accentSoft,
    required this.surface,
    required this.surfaceSecondary,
    required this.surfaceTertiary,
    required this.textPrimary,
    required this.muted,
    required this.border,
    required this.federal,
    required this.state,
    required this.county,
    required this.error,
  });

  static const light = AppColors._(
    brandPrimary: Color(0xFF0B1B34),
    brandSecondary: Color(0xFF1E3A5F),
    accent: Color(0xFFC0392B),
    accentSoft: Color(0xFFFCEAE7),
    surface: Colors.white,
    surfaceSecondary: Color(0xFFF7F8FB),
    surfaceTertiary: Color(0xFFEEF1F6),
    textPrimary: Color(0xFF0B1B34),
    muted: Color(0xFF64748B),
    border: Color(0xFFE5E9F0),
    federal: Color(0xFF1E3A5F),
    state: Color(0xFF2E7D5B),
    county: Color(0xFFB45309),
    error: Color(0xFFB91C1C),
  );

  static const dark = AppColors._(
    // Brand navy stays put — it's still used as a deliberate banner/gradient
    // color (SliverAppBar, resident-hub location card) in dark mode too.
    brandPrimary: Color(0xFF0B1B34),
    brandSecondary: Color(0xFF23456F),
    accent: Color(0xFFE2695A),
    accentSoft: Color(0xFF3A2420),
    surface: Color(0xFF121A2B),
    surfaceSecondary: Color(0xFF1A2438),
    surfaceTertiary: Color(0xFF232E45),
    textPrimary: Color(0xFFF3F5F9),
    muted: Color(0xFF97A6BC),
    border: Color(0xFF2C3750),
    federal: Color(0xFF4E7FB5),
    state: Color(0xFF3FA179),
    county: Color(0xFFD08A3E),
    error: Color(0xFFEF6259),
  );

  static AppColors of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;
}

class AppGradients {
  // Deliberately theme-independent: this is the branded hero background used
  // on the home, onboarding, and tutorial screens regardless of system theme.
  static const background = LinearGradient(
    colors: [Color(0xFF0B1B34), Color(0xFF16345C), Color(0xFFC0392B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.0, 0.55, 1.0],
  );
}
