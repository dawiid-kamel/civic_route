class Contact {
  final String name;
  final String office;
  final String? phone;
  final String? email;
  final String? website;
  final String level; // "federal", "state", "county", "local"

  // Which specific issue ids (from data/issue_tree.dart) this contact
  // applies to, e.g. ["local-roads"]. Leave empty for a general/countywide
  // contact that should show up for every county-level issue (the County
  // Executive, County Council, 311, etc.) rather than just one of them.
  final List<String> issueIds;

  Contact({
    required this.name,
    required this.office,
    this.phone,
    this.email,
    this.website,
    required this.level,
    this.issueIds = const [],
  });
}