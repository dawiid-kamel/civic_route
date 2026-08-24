import 'dart:io';

Map<String, String> appEnv = {};

void loadEnv([String path = '.env']) {
  final file = File(path);
  if (!file.existsSync()) {
    throw Exception('.env file not found at $path');
  }
  for (final line in file.readAsLinesSync()) {
    final trimmed = line.trim();
    if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
    final idx = trimmed.indexOf('=');
    if (idx == -1) continue;
    final key = trimmed.substring(0, idx).trim();
    final value = trimmed.substring(idx + 1).trim();
    appEnv[key] = value;
  }
}
