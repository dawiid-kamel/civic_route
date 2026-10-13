/// App entry point for CivicRoute.
///
/// Installs the global error hooks (`services/error_reporting.dart`), loads
/// the saved/hosted county directory (`services/directory_service.dart`), then
/// picks the first screen from saved preferences:
/// the tutorial on first launch, onboarding once the tutorial is done, and
/// the home screen after that. It also builds the light and dark `ThemeData`
/// from the shared palette in `theme.dart`.
library;

import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/directory_service.dart';
import 'services/error_reporting.dart';
import 'services/reminder_service.dart';
import 'screens/tutorial_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/home_screen.dart';
import 'theme.dart';

/// Starts the app: sets up error reporting, loads data and reminders, picks the
/// first screen from saved preferences, and runs the [MaterialApp].
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Send Flutter framework errors to the console and to our error reporter.
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    reportError(details.exception, details.stack);
  };
  // Catch uncaught async/platform errors too; returning true marks them handled.
  PlatformDispatcher.instance.onError = (error, stack) {
    reportError(error, stack);
    return true;
  };

  // Saved directory is applied right away; the fresh download happens in the background.
  await loadSavedDirectory();
  unawaited(refreshDirectory());

  // Set up follow-up reminders; non-null if the app was opened by tapping one.
  final launchIssueId = await ReminderService.init();

  final prefs = await SharedPreferences.getInstance();
  final tutorialSeen = prefs.getBool('tutorial_seen') ?? false;
  final onboarded = prefs.getBool('onboarded') ?? false;

  // Decide where to start: tutorial, then onboarding, then home.
  Widget startScreen;
  if (!tutorialSeen) {
    startScreen = TutorialScreen();
  } else if (!onboarded) {
    startScreen = OnboardingScreen();
  } else {
    startScreen = HomeScreen();
  }

  runApp(MaterialApp(
    navigatorKey: ReminderService.navigatorKey,
    title: 'Civic Route',
    themeMode: ThemeMode.system,
    // Light theme built from the light palette.
    theme: ThemeData(
      primaryColor: AppColors.light.brandPrimary,
      scaffoldBackgroundColor: AppColors.light.surface,
      colorScheme: ColorScheme.fromSeed(seedColor: AppColors.light.brandPrimary, brightness: Brightness.light),
      useMaterial3: true,
      iconTheme: IconThemeData(color: AppColors.light.brandPrimary),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.light.surface,
        foregroundColor: AppColors.light.brandPrimary,
        iconTheme: IconThemeData(color: AppColors.light.brandPrimary),
        titleTextStyle: TextStyle(color: AppColors.light.brandPrimary, fontWeight: FontWeight.w800, fontSize: 18),
      ),
    ),
    // Dark theme built from the dark palette.
    darkTheme: ThemeData(
      primaryColor: AppColors.dark.brandPrimary,
      // Previously a different, unrelated hardcoded navy (0xFF0B1220) than
      // the rest of the dark palette used elsewhere in the app — now shares
      // the same AppColors.dark.surface every other screen uses.
      scaffoldBackgroundColor: AppColors.dark.surface,
      colorScheme: ColorScheme.fromSeed(seedColor: AppColors.dark.brandPrimary, brightness: Brightness.dark),
      useMaterial3: true,
      iconTheme: IconThemeData(color: Colors.white),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.dark.surface,
        foregroundColor: Colors.white,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18),
      ),
    ),
    home: startScreen,
  ));

  // Cold start from a reminder: open that issue once the first screen is up.
  if (launchIssueId != null && onboarded) {
    WidgetsBinding.instance.addPostFrameCallback((_) => ReminderService.openIssueFromPayload(launchIssueId));
  }
}
