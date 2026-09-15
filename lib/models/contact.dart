class Contact {
  final String name;
  final String office;
  final String? phone;
  final String? email;
  final String? website;
  final String level; // "federal", "state", "county", "local"

  Contact({
    required this.name,
    required this.office,
    this.phone,
    this.email,
    this.website,
    required this.level,
  });
}