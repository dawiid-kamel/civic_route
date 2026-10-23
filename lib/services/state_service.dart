/// State legislator lookup via the Open States API (called directly from the app).
///
/// `fetchStateLegislators` takes the user's coordinates and returns the state
/// senator and representative as `Contact`s; `parseStateLegislators` is the
/// pure parsing step (kept separate so it can be unit tested).
/// `resolver_service.dart` calls it for the `state` level. Phone numbers and
/// office addresses come from Open States' `offices` data when it has them.
/// For Maryland, a contact with no website falls back to the General Assembly's
/// member directory so there is always somewhere to go.
library;

import '../models/contact.dart';
import 'api_client.dart';

/// Fallback page listing every Maryland General Assembly member, used when a legislator has no website.
const _marylandDirectory = 'https://mgaleg.maryland.gov/mgawebsite/Members/Index';

/// Finds the state legislators who represent the point ([lat], [lng]) through
/// Open States and returns them as [Contact]s.
Future<List<Contact>> fetchStateLegislators(double lat, double lng) async {
  final data = await getJson(
    openStatesPeopleGeoUri(lat, lng),
    headers: openStatesHeaders(),
    service: 'Open States',
  );
  return parseStateLegislators(data);
}

/// Turns an Open States `people.geo` response into state-level contacts.
List<Contact> parseStateLegislators(dynamic data) {
  final results = (data is Map ? data['results'] as List? : null) ?? const [];

  // This endpoint also returns federal reps/senators; keep only state-level people.
  final stateOnly = results.where((p) => p is Map && p['jurisdiction']?['classification'] == 'state');

  return stateOnly.map<Contact>((p) {
    final role = p['current_role'];

    // Open States' `email` is sometimes a real address and sometimes a
    // contact-form link. Links go to `website`, real addresses to `email`.
    final rawContact = p['email']?.toString().trim();
    String? website;
    String? email;
    if (rawContact != null && rawContact.startsWith('http')) {
      website = rawContact;
    } else if (rawContact != null && rawContact.contains('@')) {
      email = rawContact;
    }
    if (website == null && p['jurisdiction']?['name'] == 'Maryland') {
      website = _marylandDirectory;
    }

    String? phone;
    String? address;
    final offices = p['offices'];
    if (offices is List) {
      for (final o in offices) {
        if (o is! Map) continue;
        final voice = o['voice']?.toString().trim();
        if (phone == null && voice != null && voice.isNotEmpty) phone = voice;
        final addr = o['address']?.toString().trim();
        if (address == null && addr != null && addr.isNotEmpty) address = addr;
      }
    }

    return Contact(
      name: p['name']?.toString() ?? 'Unknown',
      office: role?['title']?.toString() ?? 'State Legislator',
      phone: phone,
      email: email,
      website: website,
      address: address,
      level: 'state',
    );
  }).toList();
}
