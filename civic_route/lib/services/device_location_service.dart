import 'package:geolocator/geolocator.dart';

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

  return Geolocator.getCurrentPosition();
}