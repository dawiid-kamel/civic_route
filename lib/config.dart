/// Build-time settings for CivicRoute.
///
/// Values come from `--dart-define=NAME=value` when you run or build the app,
/// so nothing secret is stored in the source or in the app bundle. The API
/// keys themselves live only on the relay in `worker/` (see worker/README.md);
/// the app just needs to know the relay's address. `services/congress_service`
/// and `services/state_service` use [AppConfig.apiBaseUrl]; the Results and
/// Resident hub screens use the remaining values.
library;

class AppConfig {
  AppConfig._();

  /// Address of the API relay in `worker/`, e.g. https://civic-route-api.you.workers.dev
  static const String apiBaseUrl = String.fromEnvironment('API_BASE_URL');

  /// JSON file with the contact directory, fetched at startup so contact
  /// changes ship without an app release. Falls back to the copy bundled in
  /// `lib/data/county_data.dart` when offline. See `services/directory_service.dart`.
  static const String directoryUrl = String.fromEnvironment(
    'DIRECTORY_URL',
    defaultValue:
        'https://raw.githubusercontent.com/dawiid-kamel/civic_route/main/data/county_directory.json',
  );

  /// Public privacy policy (both app stores require one). Hosted from `docs/`
  /// with GitHub Pages: Settings > Pages > Deploy from branch > /docs.
  static const String privacyPolicyUrl = String.fromEnvironment(
    'PRIVACY_POLICY_URL',
    defaultValue: 'https://dawiid-kamel.github.io/civic_route/privacy.html',
  );

  /// Turn on once a real alerts/events feed exists. Off for launch so the app
  /// doesn't show a section that can never have content.
  static const bool enableLocalAlerts = bool.fromEnvironment('ENABLE_LOCAL_ALERTS');

  /// True when the relay address was provided.
  static bool get hasApi => apiBaseUrl.isNotEmpty;
}
