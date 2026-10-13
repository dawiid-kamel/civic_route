/// Consistency checks for the category guides and the Resident hub directory.
///
/// Every category must explain itself in the same four parts, and the "who
/// handles it" rows must match the levels of its sub-issues. Every hub service
/// must list real Baltimore County contacts (so the sheet is never empty).
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:civic_route/data/issue_tree.dart';
import 'package:civic_route/data/services_data.dart';

void main() {
  /// Each category guide has non-empty 'covers' and 'prepare' text, and its federal/state/county
  /// rows exist exactly when some sub-issue is handled at that level.
  test('every category guide is complete and matches its sub-issues', () {
    for (final cat in issueTree) {
      final g = cat.guide;
      expect(g.covers.trim(), isNotEmpty, reason: '${cat.id} covers');
      expect(g.prepare.trim(), isNotEmpty, reason: '${cat.id} prepare');

      final levels = cat.subIssues.expand((i) => i.levels).toSet();
      expect(g.federal != null, levels.any((l) => l.startsWith('federal')),
          reason: '${cat.id} federal row should match its sub-issues');
      expect(g.state != null, levels.contains('state'),
          reason: '${cat.id} state row should match its sub-issues');
      expect(g.county != null, levels.contains('county'),
          reason: '${cat.id} county row should match its sub-issues');
    }
  });

  /// findCategoryById and findIssueById return the right item, or null for an unknown id.
  test('id lookups find categories and issues', () {
    expect(findCategoryById('housing')?.name, 'Housing');
    expect(findIssueById('hud')?.name, 'Federal housing policy (HUD)');
    expect(findCategoryById('nope'), isNull);
  });

  /// Every Resident hub service has Baltimore County contacts (each with a phone or website);
  /// an unknown county or a null county returns an empty list.
  test('every hub service has Baltimore County contacts', () {
    for (final service in hubServices) {
      final contacts = serviceContactsFor('Baltimore County, MD', service.title);
      expect(contacts, isNotEmpty, reason: service.title);
      for (final c in contacts) {
        expect(c.phone != null || c.website != null, isTrue,
            reason: '${c.name} needs a phone or website');
      }
    }
    expect(serviceContactsFor('Nowhere County, ZZ', 'Permits'), isEmpty);
    expect(serviceContactsFor(null, 'Permits'), isEmpty);
  });
}
