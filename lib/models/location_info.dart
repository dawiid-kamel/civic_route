class LocationInfo {
  final String county;
  final String state;
  final String stateAbbr;
  final String congressionalDistrict;
  final double lat;
  final double lng;

  LocationInfo({
    required this.county,
    required this.state,
    required this.stateAbbr,
    required this.congressionalDistrict,
    required this.lat,
    required this.lng,
  });
}
