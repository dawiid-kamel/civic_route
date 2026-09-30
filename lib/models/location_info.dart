class LocationInfo {
  final String county;
  final String state;
  final String stateAbbr;
  // Null when the Census geocoder couldn't resolve a district for these
  // coordinates (this does happen — e.g. right on a district boundary, or
  // a quirk of that specific vintage layer). Callers that need a House
  // district must handle null rather than assume it's always present.
  final String? congressionalDistrict;
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