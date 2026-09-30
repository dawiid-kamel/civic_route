import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/env_loader.dart';
import 'screens/tutorial_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/home_screen.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  appEnv['CONGRESS_API_KEY'] = dotenv.env['CONGRESS_API_KEY'] ?? '';
  appEnv['OPENSTATES_API_KEY'] = dotenv.env['OPENSTATES_API_KEY'] ?? '';

  final prefs = await SharedPreferences.getInstance();
  final tutorialSeen = prefs.getBool('tutorial_seen') ?? false;
  final onboarded = prefs.getBool('onboarded') ?? false;

  Widget startScreen;
  if (!tutorialSeen) {
    startScreen = TutorialScreen();
  } else if (!onboarded) {
    startScreen = OnboardingScreen();
  } else {
    startScreen = HomeScreen();
  }

  runApp(MaterialApp(
    title: 'Civic Route',
    themeMode: ThemeMode.system,
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
}
