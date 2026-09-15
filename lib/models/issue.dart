import 'package:flutter/material.dart';

class FaqItem {
  final String question;
  final String answer;
  FaqItem({required this.question, required this.answer});
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
  final List<FaqItem> faqs;
  IssueCategory({required this.id, required this.name, required this.icon, required this.description, required this.subIssues, this.faqs = const []});
}
