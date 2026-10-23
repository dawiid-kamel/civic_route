/// Data model for the user's resolved location.
///
/// `services/location_service.dart` turns GPS coordinates into a
/// `LocationInfo` (county, state, congressional district). The resolver uses
/// it to decide which offices to query, and the Home and Resident hub
/// screens use it for the "County, State" label.
library;

/// Where the user is, in the terms government offices care about: county, state and House district.
class LocationInfo {
  /// County name as the Census reports it, e.g. "Baltimore County".
  final String county;
  /// Full state name, e.g. "Maryland".
  final String state;
  /// Two-letter state code, e.g. "MD"; used in the county directory key and Congress lookups.
  final String stateAbbr;
  // Null when the Census geocoder couldn't resolve a district for these
  // coordinates (this does happen — e.g. right on a district boundary, or
  // a quirk of that specific vintage layer). Callers that need a House
  // district must handle null rather than assume it's always present.
  /// U.S. House district number as text (no leading zeros), or null if unknown. See the note above.
  final String? congressionalDistrict;
  /// Latitude in degrees of the point this was resolved for.
  final double lat;
  /// Longitude in degrees of the point this was resolved for.
  final double lng;

  /// Creates a location; [congressionalDistrict] may be null when unresolved.
  LocationInfo({
    required this.county,
    required this.state,
    required this.stateAbbr,
    required this.congressionalDistrict,
    required this.lat,
    required this.lng,
  });

  /// Converts this location to JSON for the saved-location cache (the district is stored under "district").
  Map<String, dynamic> toJson() => {
        'county': county,
        'state': state,
        'stateAbbr': stateAbbr,
        'district': congressionalDistrict,
        'lat': lat,
        'lng': lng,
      };

  /// Rebuilds a location from the JSON written by [toJson].
  factory LocationInfo.fromJson(Map<String, dynamic> j) => LocationInfo(
        county: j['county'] as String,
        state: j['state'] as String,
        stateAbbr: j['stateAbbr'] as String,
        congressionalDistrict: j['district'] as String?,
        lat: (j['lat'] as num).toDouble(),
        lng: (j['lng'] as num).toDouble(),
      );
}
