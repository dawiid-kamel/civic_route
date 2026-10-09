/// Data model for one government official or office.
///
/// Every service (`congress_service`, `state_service`) and the hand-built
/// county list in `data/county_data.dart` return `Contact`s, and the Results
/// screen renders them as cards with call/website/email buttons. `issueIds` ties a
/// county contact to specific issues from `data/issue_tree.dart`.
library;

class Contact {
  final String name;
  final String office;
  final String? phone;
  final String? email;
  final String? website;
  final String? address; // office address, when a source provides one
  final String? lastVerified; // ISO date (YYYY-MM-DD) the entry was last checked by hand
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
    this.address,
    this.lastVerified,
    required this.level,
    this.issueIds = const [],
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'office': office,
        'phone': phone,
        'email': email,
        'website': website,
        'address': address,
        'lastVerified': lastVerified,
        'level': level,
        'issueIds': issueIds,
      };

  factory Contact.fromJson(Map<String, dynamic> j) => Contact(
        name: j['name'] as String,
        office: j['office'] as String,
        phone: j['phone'] as String?,
        email: j['email'] as String?,
        website: j['website'] as String?,
        address: j['address'] as String?,
        lastVerified: j['lastVerified'] as String?,
        level: (j['level'] as String?) ?? 'county',
        issueIds: ((j['issueIds'] as List?) ?? const []).map((e) => e.toString()).toList(),
      );

  /// Plain-text version for copying or sharing.
  String toShareText() {
    final lines = <String>[name, office];
    if (phone != null) lines.add('Phone: $phone');
    if (email != null) lines.add('Email: $email');
    if (website != null) lines.add('Website: $website');
    if (address != null) lines.add('Address: $address');
    return lines.join('\n');
  }
}
