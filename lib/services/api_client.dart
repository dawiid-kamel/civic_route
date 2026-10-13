/// Shared HTTP helpers for every network call in the app.
///
/// `getJson` adds a timeout, turns network failures into one friendly
/// `OfflineException`, and turns bad status codes into readable messages, so
/// the screens only ever have to show `error.toString()`. `congressUri` and
/// `openStatesUri` build the direct API URLs (keys come from `config.dart`).
/// Used by `congress_service`, `state_service` and `location_service`.
library;

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config.dart';

/// An error whose message is safe to show to the user as-is.
class AppException implements Exception {
  /// The user-facing text; also what `toString()` returns.
  final String message;
  /// Creates an exception carrying a message that is safe to show on screen.
  AppException(this.message);

  @override
  String toString() => message;
}

/// The device is offline, or the service didn't answer in time.
class OfflineException extends AppException {
  /// Creates the standard "check your connection" error.
  OfflineException()
      : super("Couldn't reach the lookup service. Check your internet connection and try again.");
}

/// Builds a Congress.gov API URL, e.g. `congressUri('member/congress/119/MD')`.
/// Adds the JSON format and the API key; throws a readable error if the build has no key.
Uri congressUri(String path, [Map<String, String> query = const {}]) {
  if (AppConfig.congressApiKey.isEmpty) {
    throw AppException(
      'This build has no Congress.gov key. Run the app with '
      '--dart-define=CONGRESS_API_KEY=<your key> (see README.md).',
    );
  }
  return Uri.https('api.congress.gov', '/v3/$path', {
    ...query,
    'format': 'json',
    'api_key': AppConfig.congressApiKey,
  });
}

/// Builds the Open States `people.geo` URL for a point. Coordinates are
/// rounded to about 100 m, which is plenty for finding districts and sends
/// less precise location data. Throws a readable error if the build has no key.
Uri openStatesPeopleGeoUri(double lat, double lng) {
  if (AppConfig.openStatesApiKey.isEmpty) {
    throw AppException(
      'This build has no Open States key. Run the app with '
      '--dart-define=OPENSTATES_API_KEY=<your key> (see README.md).',
    );
  }
  return Uri.https('v3.openstates.org', '/people.geo', {
    'lat': lat.toStringAsFixed(3),
    'lng': lng.toStringAsFixed(3),
    'include': 'offices',
  });
}

/// Request header Open States needs to identify the key.
Map<String, String> openStatesHeaders() => {'X-API-KEY': AppConfig.openStatesApiKey};

/// GETs [url] and returns the decoded JSON.
Future<dynamic> getJson(
  Uri url, {
  Map<String, String>? headers,
  String service = 'The lookup service',
}) async {
  try {
    final response = await http
        .get(url, headers: headers)
        .timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      debugPrint('$service responded ${response.statusCode} for ${url.path}');
      throw AppException('$service returned an error (${response.statusCode}). Please try again later.');
    }
    return jsonDecode(response.body);
  } on AppException {
    rethrow;
  } on TimeoutException {
    throw OfflineException();
  } on http.ClientException {
    throw OfflineException();
  } on FormatException {
    throw AppException('$service sent an unexpected response. Please try again later.');
  } catch (e) {
    // dart:io's SocketException isn't importable on web, so match by name.
    if (e.toString().contains('SocketException')) throw OfflineException();
    rethrow;
  }
}
