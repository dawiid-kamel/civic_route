import 'dart:io';
import 'package:civic_route/data/issue_tree.dart';
import 'package:civic_route/services/env_loader.dart';
import 'package:civic_route/services/location_service.dart';
import 'package:civic_route/services/resolver_service.dart';

Future<void> main() async {
  loadEnv();

  print('=== CivicRoute CLI ===\n');

  stdout.write('Enter your latitude: ');
  final lat = double.parse(stdin.readLineSync()!.trim());
  stdout.write('Enter your longitude: ');
  final lng = double.parse(stdin.readLineSync()!.trim());

  print('\nResolving your location...');
  final location = await resolveLocation(lat, lng);
  print('County: ${location.county}');
  print('State: ${location.state} (${location.stateAbbr})');
  print('Congressional District: ${location.congressionalDistrict}\n');

  print('What issue are you dealing with?\n');
  for (var i = 0; i < issueTree.length; i++) {
    print('${i + 1}. ${issueTree[i].name}');
  }
  stdout.write('\nEnter a number: ');
  final catIndex = int.parse(stdin.readLineSync()!.trim()) - 1;
  final category = issueTree[catIndex];

  print('\n${category.name} — pick a specific issue:\n');
  for (var i = 0; i < category.subIssues.length; i++) {
    print('${i + 1}. ${category.subIssues[i].name}');
  }
  stdout.write('\nEnter a number: ');
  final issueIndex = int.parse(stdin.readLineSync()!.trim()) - 1;
  final issue = category.subIssues[issueIndex];

  print('\n${issue.name}');
  print(issue.description);
  print('\nWho to contact:\n');

  for (final level in issue.levels) {
    final contacts = await getContactsForIssue(level, location);
    if (contacts.isEmpty) {
      print('[$level] No contacts found yet (data not filled in for this level/county).');
      continue;
    }
    for (final c in contacts) {
      print('--- [$level] ---');
      print('Name: ${c.name}');
      print('Office: ${c.office}');
      if (c.phone != null) print('Phone: ${c.phone}');
      if (c.website != null) print('Website: ${c.website}');
    }
  }
}
