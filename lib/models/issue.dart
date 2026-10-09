/// Data models for the issue catalog.
///
/// `IssueCategory` (e.g. Housing) holds several `Issue`s (e.g. landlord
/// disputes) plus one `CategoryGuide`. `data/issue_tree.dart` builds the catalog,
/// Home and Category screens display it, and each `Issue.levels` list tells
/// the resolver (`services/resolver_service.dart`) which levels of government
/// to look up for that issue.
library;

import 'package:flutter/material.dart';

/// The plain-language explanation shown at the top of every category screen.
///
/// Every category fills in the same four fields, so every category screen
/// reads the same way: what it covers, who handles it at each level of
/// government, and what to have ready before contacting an office. Leave
/// [federal], [state] or [county] null when that level isn't usually involved.
class CategoryGuide {
  final String covers;
  final String? federal;
  final String? state;
  final String? county;
  final String prepare;

  const CategoryGuide({
    required this.covers,
    this.federal,
    this.state,
    this.county,
    required this.prepare,
  });
}

class Issue {
  final String id;
  final String name;
  final List<String> levels;
  final String description;
  Issue({required this.id, required this.name, required this.levels, required this.description});
}

class IssueCategory {
  final String id;
  final String name;
  final IconData icon;
  final String description;
  final List<Issue> subIssues;
  final CategoryGuide guide;
  IssueCategory({required this.id, required this.name, required this.icon, required this.description, required this.subIssues, required this.guide});
}
