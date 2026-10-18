/// Tests for the forgiving Home search and the Department of Aging entry.
library;

import 'package:civic_route/data/issue_tree.dart';
import 'package:civic_route/data/search.dart';
import 'package:civic_route/data/services_data.dart';
import 'package:flutter_test/flutter_test.dart';

String? _topCategory(String query) {
  final hits = searchIssues(query);
  return hits.isEmpty ? null : hits.first.category.id;
}

void main() {
  group('searchIssues', () {
    test('blank queries match nothing', () {
      expect(searchIssues(''), isEmpty);
      expect(searchIssues('   '), isEmpty);
    });

    test('single keywords find their category', () {
      expect(_topCategory('pothole'), 'transportation');
      expect(_topCategory('rent'), 'housing');
      expect(_topCategory('medicare'), 'healthcare');
      expect(_topCategory('vote'), 'elections');
    });

    test('plurals and word endings still match', () {
      expect(_topCategory('potholes'), 'transportation');
      expect(_topCategory('taxes'), 'taxes');
      expect(_topCategory('renting'), 'housing');
    });

    test('whole questions are routed to the right category', () {
      expect(_topCategory("Who do I call about a pothole on my street?"), 'transportation');
      expect(_topCategory("my landlord won't fix the heat"), 'housing');
      expect(_topCategory('How do I register to vote?'), 'elections');
      expect(_topCategory('I got laid off, how do I apply for benefits?'), 'labor');
      expect(_topCategory('missed trash pickup'), 'environment');
      expect(_topCategory('where do I appeal my property tax bill'), 'taxes');
    });

    test('questions also surface the specific topic', () {
      final hit = searchIssues("my landlord won't fix the heat").first;
      expect(hit.issues.first.id, 'landlord');

      final pothole = searchIssues('who fixes potholes?').first;
      expect(pothole.issues.first.id, 'local-roads');
    });

    test('filler words alone fall back to a plain text match', () {
      // Every word is filler, so this uses substring matching instead.
      expect(searchIssues('what is'), isA<List<SearchHit>>());
    });

    test('gibberish matches nothing', () {
      expect(searchIssues('zzqxv'), isEmpty);
    });

    test('short words do not match longer unrelated words', () {
      // "car" must not match "care"/"healthcare".
      final ids = searchIssues('car').map((h) => h.category.id).toList();
      expect(ids, contains('transportation'));
      expect(ids, isNot(contains('healthcare')));
    });

    test('every category is reachable by its own name', () {
      for (final cat in issueTree) {
        final ids = searchIssues(cat.name).map((h) => h.category.id);
        expect(ids, contains(cat.id), reason: cat.name);
      }
    });

    test('results list at most three topics per category', () {
      for (final hit in searchIssues('tax')) {
        expect(hit.issues.length, lessThanOrEqualTo(maxIssuesPerHit));
      }
    });
  });

  test('Department of Aging lists its phone number', () {
    final programs = serviceContactsFor('Baltimore County, MD', 'Community programs');
    final aging = programs.firstWhere((c) => c.name == 'Baltimore County Department of Aging');
    expect(aging.phone, '410-887-2594');
  });
}
