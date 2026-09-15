import 'dart:convert';
import 'package:http/http.dart' as http;
import 'env_loader.dart';
import '../models/contact.dart';

Future<List<Contact>> fetchStateLegislators(double lat, double lng) async {
  final apiKey = appEnv['OPENSTATES_API_KEY'];
  final url = Uri.parse(
    'https://v3.openstates.org/people.geo?lat=$lat&lng=$lng&apikey=$apiKey'
  );

  final response = await http.get(url);
  if (response.statusCode != 200) {
    throw Exception('OpenStates API failed: ${response.statusCode}');
  }

  final data = jsonDecode(response.body);
  final results = data['results'] as List;

  // keep only state-level people — this endpoint also returns federal reps/senators
  final stateOnly = results.where((p) {
    return p['jurisdiction']?['classification'] == 'state';
  }).toList();

  return stateOnly.map((p) {
    final role = p['current_role'];
    return Contact(
      name: p['name'] ?? 'Unknown',
      office: role?['title'] ?? 'State Legislator',
      phone: null, // not available from this endpoint
      website: p['email'], // often a contact-form URL, not a real email — label accordingly in UI
      level: 'state',
    );
  }).toList();
}