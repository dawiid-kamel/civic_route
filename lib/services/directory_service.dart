/// Keeps the county contact directory up to date without an app release.
///
/// At startup `main.dart` calls `loadSavedDirectory` (instant, from disk) and
/// then `refreshDirectory` (in the background), which downloads the hosted
/// `data/county_directory.json` (address in `config.dart`) and replaces the
/// matching entries in `countyDictionary` (`data/county_data.dart`). If the
/// download fails the bundled copy keeps working. To change a phone number or
/// an officeholder after an election, edit the JSON in the repo and commit.
library;

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config.dart';
import '../data/county_data.dart';
import '../models/contact.dart';
import 'api_client.dart';

/// SharedPreferences key under which the last downloaded directory JSON is saved.
const _prefsKey = 'directory_cache';

/// Applies a decoded directory JSON. Returns the number of counties applied
/// (0 means the data was unusable and nothing changed).
int applyDirectory(dynamic data) {
  final counties = data is Map ? data['counties'] : null;
  if (counties is! Map) return 0;

  final parsed = <String, List<Contact>>{};
  counties.forEach((key, list) {
    if (key is! String || list is! List) return;
    final contacts = <Contact>[];
    for (final item in list) {
      try {
        contacts.add(Contact.fromJson(item as Map<String, dynamic>));
      } catch (e) {
        debugPrint('Skipping bad directory entry in $key: $e');
      }
    }
    if (contacts.isNotEmpty) parsed[key] = contacts;
  });

  countyDictionary.addAll(parsed);
  return parsed.length;
}

/// Applies the last downloaded directory, if there is one.
Future<void> loadSavedDirectory() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw != null) applyDirectory(jsonDecode(raw));
  } catch (e) {
    debugPrint('loadSavedDirectory failed: $e');
  }
}

/// Downloads the hosted directory and saves it for next time.
Future<void> refreshDirectory() async {
  if (AppConfig.directoryUrl.isEmpty) return;
  try {
    final data = await getJson(Uri.parse(AppConfig.directoryUrl), service: 'The directory');
    if (applyDirectory(data) > 0) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, jsonEncode(data));
    }
  } catch (e) {
    debugPrint('refreshDirectory failed (using saved/bundled data): $e');
  }
}
