import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/issue.dart';
import '../services/device_location_service.dart';
import '../models/contact.dart';
import '../services/resolver_service.dart';
import '../theme.dart';

class ResultsScreen extends StatefulWidget {
  final Issue issue;
  ResultsScreen({required this.issue});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  List<Contact> results = [];
  bool loading = true;
  String? error;
  Set<String> favoriteContacts = {};
  String currentStatus = 'Issue found';
  bool issueSaved = false;

  static const List<String> _statusSteps = [
    'Issue found',
    'Representative identified',
    'Action steps ready',
    'Follow up later',
    'I need help with this again',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedIds = prefs.getStringList('favorite_contact_ids') ?? [];
      final savedIssues = prefs.getStringList('saved_issues') ?? [];
      final savedStatus =
          prefs.getString('issue_status_${widget.issue.id}') ?? 'Issue found';
      var lat = prefs.getDouble('lat');
      var lng = prefs.getDouble('lng');
      if (lat == null || lng == null) {
        final pos = await getDeviceLocation();
        lat = pos.latitude;
        lng = pos.longitude;
        await prefs.setDouble('lat', lat);
        await prefs.setDouble('lng', lng);
      }
      final loc = await getCachedLocation(lat, lng);
      List<Contact> all = [];
      for (final level in widget.issue.levels) {
        all.addAll(await getContactsForIssue(level, loc, issueId: widget.issue.id));
      }
      if (mounted)
        setState(() {
          results = all;
          favoriteContacts = savedIds.toSet();
          issueSaved = savedIssues.contains(widget.issue.id);
          currentStatus = savedStatus;
          loading = false;
        });
    } catch (e) {
      if (mounted)
        setState(() {
          error = e.toString();
          loading = false;
        });
    }
  }

  String _contactKey(Contact contact) =>
      '${contact.level}|${contact.name}|${contact.office}';

  Future<void> _toggleFavorite(Contact contact) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _contactKey(contact);
    final updated = Set<String>.from(favoriteContacts);
    if (updated.contains(key)) {
      updated.remove(key);
    } else {
      updated.add(key);
    }
    setState(() => favoriteContacts = updated);
    await prefs.setStringList('favorite_contact_ids', updated.toList());
  }

  Future<void> _setStatus(String status) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => currentStatus = status);
    await prefs.setString('issue_status_${widget.issue.id}', status);
  }

  Future<void> _toggleIssueSaved() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = List<String>.from(prefs.getStringList('saved_issues') ?? []);
    if (saved.contains(widget.issue.id)) {
      saved.remove(widget.issue.id);
    } else {
      saved.add(widget.issue.id);
    }
    setState(() => issueSaved = !issueSaved);
    await prefs.setStringList('saved_issues', saved);
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        iconTheme: IconThemeData(color: colors.textPrimary),
        title: Text(
          widget.issue.name,
          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w800),
        ),
      ),
      body: loading
          ? _loadingPin(colors)
          : error != null
          ? Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'Error: $error',
                style: TextStyle(color: colors.error),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _summaryCard(colors),
                _statusCard(colors),
                if (results.isEmpty)
                  _emptyResultsCard(colors)
                else
                  ...results.map((c) => _contactCard(c, colors)).toList(),
              ],
            ),
    );
  }

  Widget _summaryCard(AppColors colors) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.accentSoft,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: colors.accent, size: 18),
              SizedBox(width: 8),
              Text(
                'What to do next',
                style: TextStyle(
                  color: colors.accent,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            'This issue usually involves ${widget.issue.levels.map((level) => level.contains('federal')
                ? 'federal'
                : level == 'state'
                ? 'state'
                : 'county').toSet().join(', ')} offices. Start with the office that matches the issue, bring dates or documents, and follow up after you call.',
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 13,
              height: 1.5,
            ),
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: results.isEmpty
                      ? null
                      : () => ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Start with ${results.first.office}.',
                            ),
                          ),
                        ),
                  icon: Icon(Icons.arrow_forward, size: 16),
                  label: Text('Recommended office'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.accent,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              SizedBox(width: 8),
              IconButton(
                onPressed: _toggleIssueSaved,
                icon: Icon(
                  issueSaved ? Icons.bookmark : Icons.bookmark_border,
                  color: colors.accent,
                ),
                tooltip: issueSaved
                    ? 'Remove saved issue'
                    : 'Save issue for follow-up',
              ),
            ],
          ),
          SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _pill('Call first', colors),
              _pill('Bring dates', colors),
              _pill(issueSaved ? 'Saved for follow-up' : 'Save later', colors),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusCard(AppColors colors) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Track this issue',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: colors.textPrimary,
            ),
          ),
          SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _statusSteps.map((status) {
              final active = status == currentStatus;
              return ChoiceChip(
                label: Text(status),
                selected: active,
                onSelected: (_) => _setStatus(status),
                selectedColor: colors.accent,
                backgroundColor: colors.surface,
                labelStyle: TextStyle(
                  color: active ? Colors.white : colors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              );
            }).toList(),
          ),
          SizedBox(height: 10),
          Text(
            'Suggested script: “I am contacting your office about ${widget.issue.name.toLowerCase()} and would like guidance on the next steps and the correct office to handle this issue.”',
            style: TextStyle(fontSize: 12, color: colors.muted, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _emptyResultsCard(AppColors colors) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surfaceSecondary,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.search_off, color: colors.muted, size: 18),
              SizedBox(width: 8),
              Text(
                'No contacts found yet',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            'We couldn\'t find verified contacts for this office in your area yet. '
            'This is usually because local data hasn\'t been added for your county, '
            'or an API lookup didn\'t return results just now.',
            style: TextStyle(color: colors.muted, fontSize: 13, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _pill(String text, AppColors colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colors.border),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: colors.textPrimary,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _loadingPin(AppColors colors) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: colors.accent,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.location_on, color: Colors.white, size: 26),
          ),
          SizedBox(height: 16),
          Text(
            'Resolving jurisdiction…',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 17,
              color: colors.textPrimary,
            ),
          ),
          Text(
            'Finding the exact office responsible.',
            style: TextStyle(color: colors.muted),
          ),
        ],
      ),
    );
  }

  Widget _contactCard(Contact c, AppColors colors) {
    final levelColor = c.level == 'federal'
        ? colors.federal
        : c.level == 'state'
        ? colors.state
        : colors.county;
    final isFavorite = favoriteContacts.contains(_contactKey(c));
    final hasPhone = c.phone != null;
    final hasWebsite = c.website != null;

    return Semantics(
      label: 'Contact card for ${c.name}, ${c.office}',
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: colors.surface,
          border: Border.all(color: colors.border),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        c.name,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: colors.textPrimary,
                        ),
                      ),
                      Text(
                        c.office,
                        style: TextStyle(fontSize: 13, color: colors.muted),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: levelColor,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    c.level[0].toUpperCase() + c.level.substring(1),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 14),
            Row(
              children: [
                // Primary action: call if we have a number, otherwise offer
                // the website inline. Previously this row's website button
                // and the block below it could BOTH render for the same
                // contact whenever there was no phone number — showing the
                // same "Website" button twice. Now the website only ever
                // appears once: inline here when there's no phone, or as the
                // secondary action below when there is.
                if (hasPhone)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => launchUrl(
                        Uri.parse(
                          'tel:${c.phone!.replaceAll(RegExp(r'[^\d+]'), '')}',
                        ),
                      ),
                      icon: Icon(Icons.call, size: 16, color: Colors.white),
                      label: Text(
                        c.phone!,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.accent,
                      ),
                    ),
                  )
                else if (hasWebsite)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => launchUrl(Uri.parse(c.website!)),
                      icon: Icon(Icons.language, size: 16),
                      label: Text(
                        'Website',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: Text(
                      'No direct contact info yet',
                      style: TextStyle(color: colors.muted, fontSize: 12),
                    ),
                  ),
                SizedBox(width: 8),
                Semantics(
                  label: isFavorite
                      ? 'Remove this official from favorites'
                      : 'Save this official to favorites',
                  child: IconButton(
                    onPressed: () => _toggleFavorite(c),
                    icon: Icon(
                      isFavorite ? Icons.star : Icons.star_border,
                      color: colors.accent,
                    ),
                    tooltip: isFavorite ? 'Saved' : 'Save',
                  ),
                ),
              ],
            ),
            if (hasPhone && hasWebsite) ...[
              SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => launchUrl(Uri.parse(c.website!)),
                icon: Icon(Icons.language, size: 16),
                label: Text(
                  'Website',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}