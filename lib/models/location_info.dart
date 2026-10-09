/// Data model for the user's resolved location.
///
/// `services/location_service.dart` turns GPS coordinates into a
/// `LocationInfo` (county, state, congressional district). The resolver uses
/// it to decide which offices to query, and the Home and Resident hub
/// screens use it for the "County, State" label.
library;

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

  Map<String, dynamic> toJson() => {
        'county': county,
        'state': state,
        'stateAbbr': stateAbbr,
        'district': congressionalDistrict,
        'lat': lat,
        'lng': lng,
      };

  factory LocationInfo.fromJson(Map<String, dynamic> j) => LocationInfo(
        county: j['county'] as String,
        state: j['state'] as String,
        stateAbbr: j['stateAbbr'] as String,
        congressionalDistrict: j['district'] as String?,
        lat: (j['lat'] as num).toDouble(),
        lng: (j['lng'] as num).toDouble(),
      );
}
