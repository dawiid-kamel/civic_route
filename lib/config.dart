/// Build-time settings for CivicRoute.
///
/// Values come from `--dart-define=NAME=value` when you run or build the app,
/// so the keys are not stored in the source code. NOTE: the Congress.gov and
/// Open States keys are compiled into the app and called directly from the
/// phone (there is no server in between), so anyone who unpacks the app can
/// read them. Both services issue free keys, so treat them as low-risk and
/// rotate them if they are abused. `services/congress_service` and
/// `services/state_service` use the keys; the Results and Resident hub screens
/// use the remaining values.
library;

/// Namespace for the build-time settings below; never instantiated.
class AppConfig {
  /// Private constructor so the class can't be instantiated.
  AppConfig._();

  /// Congress.gov API key (https://api.congress.gov/sign-up/), used for federal officials.
  static const String congressApiKey = String.fromEnvironment('CONGRESS_API_KEY');

  /// Open States API key (https://openstates.org/accounts/profile/), used for state legislators.
  static const String openStatesApiKey = String.fromEnvironment('OPENSTATES_API_KEY');

  /// JSON file with the contact directory, fetched at startup so contact
  /// changes ship without an app release. Falls back to the copy bundled in
  /// `lib/data/county_data.dart` when offline. See `services/directory_service.dart`.
  static const String directoryUrl = String.fromEnvironment(
    'DIRECTORY_URL',
    defaultValue:
        'https://raw.githubusercontent.com/dawiid-kamel/civic_route/main/data/county_directory.json',
  );

  /// Contact email shown at the bottom of the in-app privacy policy. Leave
  /// empty to hide the line; pass `--dart-define=SUPPORT_EMAIL=you@example.com`.
  static const String supportEmail = String.fromEnvironment('SUPPORT_EMAIL');

  /// Public privacy policy (both app stores require one). Hosted from `docs/`
  /// with GitHub Pages: Settings > Pages > Deploy from branch > /docs.
  static const String privacyPolicyUrl = String.fromEnvironment(
    'PRIVACY_POLICY_URL',
    defaultValue: 'https://dawiid-kamel.github.io/civic_route/privacy.html',
  );

  /// Turn on once a real alerts/events feed exists. Off for launch so the app
  /// doesn't show a section that can never have content.
  static const bool enableLocalAlerts = bool.fromEnvironment('ENABLE_LOCAL_ALERTS');

  /// Whether typing an address is allowed. OFF by default: the "Enter an
  /// address" buttons are grayed out and the app always uses the device's GPS
  /// location (any address saved earlier is ignored). Pass
  /// `--dart-define=ENABLE_ADDRESS_ENTRY=true` to turn address entry back on.
  static const bool enableAddressEntry = bool.fromEnvironment('ENABLE_ADDRESS_ENTRY', defaultValue: false);

  /// True when both API keys were provided.
  static bool get hasApi => congressApiKey.isNotEmpty && openStatesApiKey.isNotEmpty;
}
