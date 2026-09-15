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
    theme: ThemeData(primaryColor: AppColors.brandPrimary, scaffoldBackgroundColor: AppColors.surface, useMaterial3: true),
    home: startScreen,
  ));
}
