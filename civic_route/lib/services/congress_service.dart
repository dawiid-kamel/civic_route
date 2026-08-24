import 'dart:convert';
import 'package:http/http.dart' as http;
import 'env_loader.dart';
import '../models/contact.dart';

Future<List<Contact>> fetchFederalReps(String stateAbbr, String district) async {
  final apiKey = appEnv['CONGRESS_API_KEY'];
  final url = Uri.parse(
    'https://api.congress.gov/v3/member/congress/119/$stateAbbr/$district'
    '?currentMember=true&api_key=$apiKey&format=json'
  );

  final response = await http.get(url);
  if (response.statusCode != 200) {
    throw Exception('Congress API failed: ${response.statusCode}');
  }

  final data = jsonDecode(response.body);
  final members = data['members'] as List;

  List<Contact> contacts = [];
  for (var m in members) {
    final bioguideId = m['bioguideId'];
    final detail = await fetchMemberDetail(bioguideId, apiKey!);
    contacts.add(Contact(
      name: detail['name'] ?? m['name'] ?? 'Unknown',
      office: 'U.S. House Representative',
      phone: detail['phone'],
      website: detail['website'],
      level: 'federal',
    ));
  }
  return contacts;
}

Future<Map<String, String?>> fetchMemberDetail(String bioguideId, String apiKey) async {
  final url = Uri.parse(
    'https://api.congress.gov/v3/member/$bioguideId?format=json&api_key=$apiKey'
  );
  final response = await http.get(url);
  if (response.statusCode != 200) {
    return {'name': null, 'phone': null, 'website': null};
  }

  final data = jsonDecode(response.body);
  final member = data['member'];
  final addressInfo = member['addressInformation'];

  return {
    'name': member['directOrderName'],
    'phone': addressInfo?['phoneNumber'],
    'website': member['officialWebsiteUrl'],
  };
}
Future<List<Contact>> fetchSenators(String stateAbbr) async {
  final apiKey = appEnv['CONGRESS_API_KEY'];
  final url = Uri.parse(
    'https://api.congress.gov/v3/member/congress/119/$stateAbbr'
    '?currentMember=true&api_key=$apiKey&format=json'
  );

  final response = await http.get(url);
  if (response.statusCode != 200) {
    throw Exception('Congress API failed: ${response.statusCode}');
  }

  final data = jsonDecode(response.body);
  final members = data['members'] as List;

  // filter for Senate only — this endpoint returns House + Senate together
  final senators = members.where((m) {
    final terms = m['terms']?['item'] as List?;
    if (terms == null || terms.isEmpty) return false;
    return terms.last['chamber'] == 'Senate';
  }).toList();

  List<Contact> contacts = [];
  for (var s in senators) {
    final bioguideId = s['bioguideId'];
    final detail = await fetchMemberDetail(bioguideId, apiKey!);
    contacts.add(Contact(
      name: detail['name'] ?? s['name'] ?? 'Unknown',
      office: 'U.S. Senator',
      phone: detail['phone'],
      website: detail['website'],
      level: 'federal',
    ));
  }
  return contacts;
}