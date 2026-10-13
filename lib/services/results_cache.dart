/// Remembers the last successful contact list for each issue.
///
/// `results_screen.dart` saves the list after every successful lookup and falls
/// back to it when the phone is offline, showing the date it was saved. Stored
/// in SharedPreferences as JSON, one entry per issue id.
library;

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/contact.dart';

/// Saves [contacts] (with the current time) as the latest results for an issue.
/// Failures are logged and ignored, since the cache is only a convenience.
Future<void> saveCachedResults(String issueId, List<Contact> contacts) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'results_cache_$issueId',
      jsonEncode({
        'savedAt': DateTime.now().toIso8601String(),
        'contacts': contacts.map((c) => c.toJson()).toList(),
      }),
    );
  } catch (e) {
    debugPrint('saveCachedResults failed: $e');
  }
}

/// Loads the saved contacts and save time for an issue, or null if nothing is
/// saved or the stored data is unreadable.
Future<({DateTime savedAt, List<Contact> contacts})?> loadCachedResults(String issueId) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('results_cache_$issueId');
    if (raw == null) return null;
    final map = jsonDecode(raw) as Map<String, dynamic>;
    final contacts = (map['contacts'] as List)
        .map((e) => Contact.fromJson(e as Map<String, dynamic>))
        .toList();
    return (savedAt: DateTime.parse(map['savedAt'] as String), contacts: contacts);
  } catch (e) {
    debugPrint('loadCachedResults failed: $e');
    return null;
  }
}
