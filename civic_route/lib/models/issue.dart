class Issue {
  final String name;
  final List<String> levels; // e.g. ["federal_house", "state"]
  final String description;

  Issue({required this.name, required this.levels, required this.description});
}

class IssueCategory {
  final String name;
  final List<Issue> subIssues;

  IssueCategory({required this.name, required this.subIssues});
}
