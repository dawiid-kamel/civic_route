/// Tests for the hosted/bundled county directory and the Contact model.
library;

import 'dart:convert';
import 'dart:io';

import 'package:civic_route/data/county_data.dart';
import 'package:civic_route/models/contact.dart';
import 'package:civic_route/services/directory_service.dart';
import 'package:civic_route/util/format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  /// The hosted data/county_directory.json parses, has as many Baltimore County entries as the bundled
  /// list, and every contact has a phone or website and a lastVerified date.
  test('data/county_directory.json is valid and matches the bundled Baltimore County list', () {
    final json = jsonDecode(File('data/county_directory.json').readAsStringSync()) as Map<String, dynamic>;
    final list = (json['counties'] as Map<String, dynamic>)['Baltimore County, MD'] as List;
    expect(list.length, countyDictionary['Baltimore County, MD']!.length);
    for (final item in list) {
      final c = Contact.fromJson(item as Map<String, dynamic>);
      expect(c.phone != null || c.website != null, isTrue, reason: c.name);
      expect(c.lastVerified, isNotNull, reason: c.name);
    }
  });

  /// applyDirectory replaces/adds a county, skips malformed entries, returns the number of
  /// counties applied, and leaves other counties untouched.
  test('applyDirectory replaces a county and skips bad entries', () {
    final before = Map.of(countyDictionary);
    addTearDown(() => countyDictionary
      ..clear()
      ..addAll(before));

    final applied = applyDirectory({
      'counties': {
        'Test County, ZZ': [
          {'name': 'Test Office', 'office': 'Testing', 'phone': '555-0100', 'level': 'county'},
          {'broken': true},
        ],
      },
    });
    expect(applied, 1);
    expect(countyDictionary['Test County, ZZ'], hasLength(1));
    expect(countyDictionary['Baltimore County, MD'], isNotEmpty); // untouched
  });

  /// applyDirectory returns 0 for null or wrongly shaped input.
  test('applyDirectory ignores unusable data', () {
    expect(applyDirectory(null), 0);
    expect(applyDirectory({'counties': 'nope'}), 0);
  });

  /// A Contact encoded to JSON and decoded again is identical, and its share text includes the phone.
  test('Contact survives a JSON round trip', () {
    final c = Contact(
      name: 'A',
      office: 'B',
      phone: '1',
      email: 'a@b.c',
      website: 'https://x.y',
      address: '1 Main St',
      lastVerified: '2026-09',
      level: 'state',
      issueIds: ['hud'],
    );
    final copy = Contact.fromJson(jsonDecode(jsonEncode(c.toJson())) as Map<String, dynamic>);
    expect(copy.toJson(), c.toJson());
    expect(copy.toShareText(), contains('Phone: 1'));
  });

  /// formatVerified turns 'YYYY-MM' or 'YYYY-MM-DD' into 'Mon YYYY' and returns null for bad or missing input.
  test('formatVerified', () {
    expect(formatVerified('2026-09'), 'Sep 2026');
    expect(formatVerified('2026-09-30'), 'Sep 2026');
    expect(formatVerified('garbage'), isNull);
    expect(formatVerified(null), isNull);
  });
}
