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
  /// One-sentence summary of what the category includes.
  final String covers;
  /// What the federal government handles here, or null if it isn't usually involved.
  final String? federal;
  /// What the state government handles here, or null if it isn't usually involved.
  final String? state;
  /// What the county or local government handles here, or null if it isn't usually involved.
  final String? county;
  /// What to have ready (documents, dates, photos) before contacting an office.
  final String prepare;

  /// Creates a guide; [covers] and [prepare] are always required.
  const CategoryGuide({
    required this.covers,
    this.federal,
    this.state,
    this.county,
    required this.prepare,
  });
}

/// One specific problem a resident might have (e.g. potholes), and which levels of government handle it.
class Issue {
  /// Stable identifier used in saved data and in `Contact.issueIds`.
  final String id;
  /// Display name shown in lists and search.
  final String name;
  /// Levels to look up: any of `federal_house`, `federal_senate`, `state`, `county`.
  final List<String> levels;
  /// Short plain-language note on who handles this issue.
  final String description;
  /// Creates an issue; all fields are required.
  Issue({required this.id, required this.name, required this.levels, required this.description});
}

/// A topic group (e.g. Housing) shown on the Home grid, containing related [Issue]s and a [CategoryGuide].
class IssueCategory {
  final String id;
  final String name;
  /// Icon shown on the category tile.
  final IconData icon;
  final String description;
  /// The specific issues listed when the category is opened.
  final List<Issue> subIssues;
  /// The explainer shown at the top of the category screen.
  final CategoryGuide guide;
  /// Creates a category; all fields are required.
  IssueCategory({required this.id, required this.name, required this.icon, required this.description, required this.subIssues, required this.guide});
}
