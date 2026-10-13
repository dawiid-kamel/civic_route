/// Federal lookups via the Congress.gov API (called directly from the app).
///
/// `fetchFederalReps` returns the House member for a state + district and
/// `fetchSenators` returns a state's two senators, both as `Contact`s.
/// `resolver_service.dart` calls them for the `federal_house` and
/// `federal_senate` levels. Member details are fetched in parallel and cached
/// in memory, since members rarely change. The API key comes from the build
/// (`AppConfig.congressApiKey`).
library;

import 'package:flutter/foundation.dart';

import '../models/contact.dart';
import 'api_client.dart';
import 'congress_number.dart';

/// How long a cached member-detail lookup stays fresh before it is re-fetched.
const _detailTtl = Duration(hours: 12);
/// In-memory cache of member details keyed by bioguide ID, with the time each
/// was stored so stale entries can be ignored (see [_detailTtl].)
final Map<String, ({DateTime at, Map<String, String?> data})> _detailCache = {};

/// The chamber of a member's most recent term, e.g. "Senate" or "House of Representatives".
String? memberChamber(dynamic member) {
  if (member is! Map) return null;
  final rawTerms = member['terms'];
  final terms = rawTerms is List
      ? rawTerms
      : rawTerms is Map && rawTerms['item'] is List
          ? rawTerms['item'] as List
          : null;
  final lastTerm = terms != null && terms.isNotEmpty ? terms.last : null;
  return lastTerm is Map ? lastTerm['chamber']?.toString() : null;
}

/// GETs a Congress.gov [path] and returns the JSON object.
/// Throws an [AppException] if the response is not a JSON object.
Future<Map<String, dynamic>> _congressGet(String path, Map<String, String> query) async {
  final data = await getJson(congressUri(path, query), service: 'Congress.gov');
  if (data is! Map<String, dynamic>) {
    throw AppException('Congress.gov sent an unexpected response. Please try again later.');
  }
  return data;
}

/// Returns the current U.S. House member for a state (two-letter code) and
/// congressional [district] number as a list of [Contact]s.
Future<List<Contact>> fetchFederalReps(String stateAbbr, String district) async {
  final data = await _congressGet(
    'member/congress/${currentCongress()}/$stateAbbr/$district',
    {'currentMember': 'true'},
  );
  final members = (data['members'] as List?) ?? const [];
  return _contactsFor(members, 'U.S. House Representative');
}

/// Returns the two current U.S. senators for a state (two-letter code) as
/// [Contact]s.
Future<List<Contact>> fetchSenators(String stateAbbr) async {
  // This endpoint lists every current member of the state (a few dozen at
  // most), so one small request is enough to pick out the two senators.
  final data = await _congressGet(
    'member/congress/${currentCongress()}/$stateAbbr',
    {'currentMember': 'true', 'limit': '60'},
  );
  final members = ((data['members'] as List?) ?? const [])
      .where((m) => memberChamber(m) == 'Senate')
      .toList();
  return _contactsFor(members, 'U.S. Senator');
}

/// Looks up every member's details at the same time (not one after another).
Future<List<Contact>> _contactsFor(List members, String office) {
  final valid = members.whereType<Map>().where((m) => m['bioguideId'] != null);
  return Future.wait(valid.map((m) async {
    final detail = await fetchMemberDetail(m['bioguideId'].toString());
    return Contact(
      name: detail['name'] ?? m['name']?.toString() ?? 'Unknown',
      office: office,
      phone: detail['phone'],
      website: detail['website'],
      address: detail['address'],
      level: 'federal',
    );
  }));
}

/// One member's name, phone, website and office address. A failure here
/// returns empty fields (and is logged) instead of throwing, so one bad
/// lookup can't wipe out the whole list of officials.
Future<Map<String, String?>> fetchMemberDetail(String bioguideId) async {
  final cached = _detailCache[bioguideId];
  if (cached != null && DateTime.now().difference(cached.at) < _detailTtl) {
    return cached.data;
  }
  try {
    final data = await _congressGet('member/$bioguideId', const {});
    final member = data['member'];
    if (member is! Map) return const {};
    final addressInfo = member['addressInformation'];

    String? address;
    if (addressInfo is Map && addressInfo['officeAddress'] != null) {
      final parts = [
        addressInfo['officeAddress'],
        addressInfo['city'],
        addressInfo['district'],
        addressInfo['zipCode'],
      ].where((p) => p != null && p.toString().trim().isNotEmpty).map((p) => p.toString().trim());
      address = parts.join(', ');
    }

    final result = <String, String?>{
      'name': member['directOrderName']?.toString(),
      'phone': addressInfo is Map ? addressInfo['phoneNumber']?.toString() : null,
      'website': member['officialWebsiteUrl']?.toString(),
      'address': address,
    };
    _detailCache[bioguideId] = (at: DateTime.now(), data: result);
    return result;
  } catch (e) {
    debugPrint('fetchMemberDetail($bioguideId) failed: $e');
    return const {};
  }
}
