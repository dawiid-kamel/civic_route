import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'services/env_loader.dart';
import 'screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  appEnv['CONGRESS_API_KEY'] = dotenv.env['CONGRESS_API_KEY'] ?? '';
  appEnv['OPENSTATES_API_KEY'] = dotenv.env['OPENSTATES_API_KEY'] ?? '';
  runApp(MaterialApp(home: HomeScreen()));
}
