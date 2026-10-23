/// Shared HTTP helpers for every network call in the app.
///
/// `getJson` adds a timeout, retries temporary server errors, turns network
/// failures into one friendly `OfflineException`, and turns bad status codes into readable messages, so
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

/// Status codes that usually clear up on their own: server errors and the
/// "origin is down" codes (520 to 524) that a CDN such as Cloudflare returns
/// when the service behind it has a hiccup, plus rate limiting (429).
bool _isTransient(int status) => status == 429 || status >= 500;

/// How long to wait before each retry of a transient failure (so a request is
/// tried at most 3 times).
const List<Duration> _retryDelays = [Duration(seconds: 1), Duration(seconds: 2)];

/// GETs [url] and returns the decoded JSON. Server-side hiccups (5xx, 429) are
/// retried twice before giving up, so a momentary outage of a service like
/// Congress.gov doesn't show an error to the user.
Future<dynamic> getJson(
  Uri url, {
  Map<String, String>? headers,
  String service = 'The lookup service',
}) async {
  try {
    for (var attempt = 0;; attempt++) {
      final response = await http
          .get(url, headers: headers)
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) return jsonDecode(response.body);

      debugPrint('$service responded ${response.statusCode} for ${url.path} (attempt ${attempt + 1})');
      if (_isTransient(response.statusCode)) {
        if (attempt < _retryDelays.length) {
          await Future<void>.delayed(_retryDelays[attempt]);
          continue;
        }
        throw AppException("$service isn't responding right now. Please try again in a few minutes.");
      }
      throw AppException('$service returned an error (${response.statusCode}). Please try again later.');
    }
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
