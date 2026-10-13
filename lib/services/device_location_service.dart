/// Gets the phone's current GPS position.
///
/// Used by Onboarding ("Use my location"), Home, Resident hub ("Refresh my
/// area") and Results (when no position is saved yet). The coordinates are
/// saved in SharedPreferences and handed to `location_service.dart`. Throws
/// a readable exception when location is off or permission is denied.
library;

import 'package:geolocator/geolocator.dart';

/// Returns the phone's current position, asking for permission if needed.
/// Throws an [Exception] with a readable message if location services are off
/// or the user denies permission; the GPS fix gives up after 15 seconds.
Future<Position> getDeviceLocation() async {
  if (!await Geolocator.isLocationServiceEnabled()) {
    throw Exception('Location services disabled');
  }

  var permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }
  if (permission == LocationPermission.denied ||
      permission == LocationPermission.deniedForever) {
    throw Exception('Location permission denied');
  }

  // Without a time limit a weak GPS fix can leave the UI waiting forever.
  return Geolocator.getCurrentPosition(
    locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.medium,
      timeLimit: Duration(seconds: 15),
    ),
  );
}