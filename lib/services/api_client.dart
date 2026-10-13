/// Shared HTTP helpers for every network call in the app.
///
/// `getJson` adds a timeout, turns network failures into one friendly
/// `OfflineException`, and turns bad status codes into readable messages, so
/// the screens only ever have to show `error.toString()`. `relayUri` builds
/// URLs for the API relay in `worker/` (address from `config.dart`).
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

/// Builds a URL on the API relay, e.g. `relayUri('congress/member/...')`.
Uri relayUri(String path, [Map<String, String> query = const {}]) {
  if (!AppConfig.hasApi) {
    throw AppException(
      'This build has no server address. Run the app with '
      '--dart-define=API_BASE_URL=<your relay URL> (see worker/README.md).',
    );
  }
  final base = AppConfig.apiBaseUrl.replaceAll(RegExp(r'/+$'), '');
  return Uri.parse('$base/$path').replace(queryParameters: query.isEmpty ? null : query);
}

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
