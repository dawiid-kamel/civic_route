/// Shows who to contact for one sub-issue.
///
/// Resolves the saved location, asks `resolver_service.dart` for officials at
/// each level the issue involves, and lists them with call/website buttons.
/// A single "What to do next" card gives the recommended office, a short
/// script and a Save button; a separate card tracks progress. Each idea
/// appears once. Partial failures show the officials that loaded plus a notice,
/// and when the phone is offline the last saved list is shown with its date
/// (`services/results_cache.dart`). Counties with no hand-checked directory get
/// a "not supported yet" card with fallback links (USA.gov, 211).
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/issue.dart';
import '../services/api_client.dart';
import '../services/device_location_service.dart';
import '../services/launcher.dart';
import '../services/results_cache.dart';
import '../util/format.dart';
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
  // Set when some (but not all) levels of government failed to load, so the
  // user still sees the offices that did load plus a note about the rest.
  String? partialWarning;
  // Set when the list on screen is a saved copy because the phone is offline.
  DateTime? offlineSavedAt;
  // "County, ST" when we have no hand-checked county offices for the user's county.
  String? unsupportedCounty;
  Set<String> favoriteContacts = {};
  String currentStatus = _statusSteps.first;
  bool issueSaved = false;

  // Progress steps, in order. (These used to overlap with the "Save later" /
  // "Follow up later" labels elsewhere on the screen.)
  static const List<String> _statusSteps = [
    'Not started',
    'Contacted',
    'Waiting for a response',
    'Resolved',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final savedIds = prefs.getStringList('favorite_contact_ids') ?? [];
    final savedIssues = prefs.getStringList('saved_issues') ?? [];
    // Older versions stored different labels; anything unrecognized resets.
    final storedStatus = prefs.getString('issue_status_${widget.issue.id}');
    final savedStatus =
        _statusSteps.contains(storedStatus) ? storedStatus! : _statusSteps.first;

    try {
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

      // Every level is looked up at the same time. One failing lookup (e.g.
      // Open States down) must not hide the others, including local ones.
      final failedLevels = <String>{};
      Object? firstError;
      final lists = await Future.wait(widget.issue.levels.map((level) async {
        try {
          return await getContactsForIssue(level, loc, issueId: widget.issue.id);
        } catch (e) {
          firstError ??= e;
          failedLevels.add(_levelName(level));
          return <Contact>[];
        }
      }));
      final all = lists.expand((l) => l).toList();
      final allLevels = widget.issue.levels.map(_levelName).toSet();
      if (all.isEmpty && failedLevels.length == allLevels.length && firstError != null) {
        throw firstError!;
      }
      if (all.isNotEmpty) await saveCachedResults(widget.issue.id, all);

      if (!mounted) return;
      setState(() {
        partialWarning = failedLevels.isEmpty
            ? null
            : "Couldn't load ${failedLevels.join(' and ')} officials right now. Showing the rest.";
        unsupportedCounty =
            widget.issue.levels.contains('county') && !hasCountyDirectory(loc)
                ? '${loc.county}, ${loc.state}'
                : null;
        offlineSavedAt = null;
        results = all;
        favoriteContacts = savedIds.toSet();
        issueSaved = savedIssues.contains(widget.issue.id);
        currentStatus = savedStatus;
        loading = false;
      });
    } catch (e) {
      // Offline: show the last list we saved for this issue, if there is one.
      if (e is OfflineException) {
        final cached = await loadCachedResults(widget.issue.id);
        if (cached != null && mounted) {
          setState(() {
            results = cached.contacts;
            offlineSavedAt = cached.savedAt;
            favoriteContacts = savedIds.toSet();
            issueSaved = savedIssues.contains(widget.issue.id);
            currentStatus = savedStatus;
            loading = false;
          });
          return;
        }
      }
      debugPrint('Results load failed: $e');
      if (mounted) {
        setState(() {
          error = _friendlyError(e);
          loading = false;
        });
      }
    }
  }

  String _levelName(String level) => level.contains('federal')
      ? 'federal'
      : level == 'state'
          ? 'state'
          : 'county';

  /// Only messages written for users reach the screen; anything unexpected
  /// gets a generic line (the details are logged with debugPrint).
  String _friendlyError(Object e) {
    if (e is AppException) return e.toString();
    final text = e.toString();
    if (text.contains('permission') || text.contains('Location services')) {
      return 'We need your location to find your officials. Turn on location access, or enter an address from the Resident hub, and try again.';
    }
    return 'Something went wrong while looking up your officials. Please try again.';
  }

  Future<void> _copy(String text, String message) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  String get _callScript =>
      'Hello, I am calling about ${widget.issue.name.toLowerCase()}. '
      'Can you tell me the next steps and which office handles this? '
      'I have my dates, address and any case numbers ready.';

  String get _emailTemplate =>
      'Subject: Question about ${widget.issue.name}\n\n'
      'Hello,\n\n'
      'I am a resident writing about ${widget.issue.name.toLowerCase()}. '
      'Could you tell me the next steps and which office handles this?\n\n'
      'Details: [dates, address, case or account numbers]\n\n'
      'Thank you,\n[Your name]\n[Your phone number]';

  Future<void> _retry() async {
    setState(() {
      loading = true;
      error = null;
      partialWarning = null;
      offlineSavedAt = null;
    });
    await _load();
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
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, color: colors.error, size: 32),
                  SizedBox(height: 12),
                  Text(
                    error!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: colors.textPrimary, height: 1.4),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _retry,
                    icon: Icon(Icons.refresh),
                    label: Text('Try again'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.accent,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _summaryCard(colors),
                _statusCard(colors),
                if (offlineSavedAt != null)
                  _warningCard(
                    colors,
                    "You're offline. Showing the contacts saved on ${formatDate(offlineSavedAt!)}. They may have changed.",
                  ),
                if (partialWarning != null) _warningCard(colors, partialWarning!),
                if (unsupportedCounty != null) _unsupportedCountyCard(colors, unsupportedCounty!),
                if (results.isEmpty && unsupportedCounty == null)
                  _emptyResultsCard(colors)
                else
                  ...results.map((c) => _contactCard(c, colors)),
                _disclaimer(colors),
              ],
            ),
    );
  }

  /// The offices that handle this issue, e.g. "federal and state".
  String _levelsText() {
    final names = widget.issue.levels.map(_levelName).toSet().toList();
    if (names.length <= 1) return names.join();
    return '${names.sublist(0, names.length - 1).join(', ')} and ${names.last}';
  }

  /// Best office to start with: the one built for this exact issue if there
  /// is one, otherwise the first result.
  Contact? get _recommended {
    if (results.isEmpty) return null;
    return results.firstWhere(
      (c) => c.issueIds.contains(widget.issue.id),
      orElse: () => results.first,
    );
  }

  Widget _summaryCard(AppColors colors) {
    final recommended = _recommended;
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
            'This is usually handled by ${_levelsText()} offices.',
            style: TextStyle(color: colors.textPrimary, fontSize: 14, height: 1.5),
          ),
          if (recommended != null) ...[
            SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.arrow_forward, color: colors.accent, size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Start with ${recommended.name} (${recommended.office}).',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ],
          SizedBox(height: 14),
          Text(
            'What to say',
            style: TextStyle(color: colors.accent, fontWeight: FontWeight.w800, fontSize: 13),
          ),
          SizedBox(height: 6),
          Text(
            '“I am calling about ${widget.issue.name.toLowerCase()}. Can you tell me the next steps and who handles this?”',
            style: TextStyle(color: colors.textPrimary, fontSize: 14, height: 1.5),
          ),
          SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              TextButton.icon(
                onPressed: () => _copy(_callScript, 'Call script copied'),
                icon: Icon(Icons.copy, size: 16),
                label: Text('Copy call script'),
              ),
              TextButton.icon(
                onPressed: () => _copy(_emailTemplate, 'Email template copied'),
                icon: Icon(Icons.mail_outline, size: 16),
                label: Text('Copy email'),
              ),
            ],
          ),
          SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _toggleIssueSaved,
              icon: Icon(issueSaved ? Icons.bookmark : Icons.bookmark_border, size: 18),
              label: Text(issueSaved ? 'Saved to your topics' : 'Save this topic'),
              style: OutlinedButton.styleFrom(
                minimumSize: Size.fromHeight(46),
                foregroundColor: colors.accent,
                side: BorderSide(color: colors.accent),
              ),
            ),
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
            'Track your progress',
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
                checkmarkColor: Colors.white,
                backgroundColor: colors.surface,
                labelStyle: TextStyle(
                  color: active ? Colors.white : colors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _unsupportedCountyCard(AppColors colors, String county) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
              Icon(Icons.map_outlined, color: colors.accent, size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Local offices for $county aren\'t in Civic Route yet',
                  style: TextStyle(fontWeight: FontWeight.w800, color: colors.textPrimary),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            'Federal and state officials work everywhere, but county offices are only '
            'built in for Baltimore County, Maryland so far. These can still get you to the right place:',
            style: TextStyle(color: colors.muted, fontSize: 13, height: 1.5),
          ),
          SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () => openLink(context, Uri.parse('https://www.usa.gov/local-governments')),
                icon: Icon(Icons.language, size: 16),
                label: Text('Find your local government'),
              ),
              OutlinedButton.icon(
                onPressed: () => openLink(context, Uri.parse('tel:211')),
                icon: Icon(Icons.call, size: 16),
                label: Text('Call 211'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _disclaimer(AppColors colors) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 12),
      child: Text(
        'Contact information can change. Confirm with the office before you rely on it.',
        textAlign: TextAlign.center,
        style: TextStyle(color: colors.muted, fontSize: 12, height: 1.4),
      ),
    );
  }

  Widget _warningCard(AppColors colors, String message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.accentSoft,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, color: colors.accent, size: 18),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: colors.textPrimary, fontSize: 13, height: 1.4),
            ),
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
    final hasEmail = c.email != null;
    final verified = formatVerified(c.lastVerified);

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
                      if (c.address != null) ...[
                        SizedBox(height: 4),
                        Text(
                          c.address!,
                          style: TextStyle(fontSize: 12, color: colors.muted, height: 1.3),
                        ),
                      ],
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
                      onPressed: () => openLink(context, phoneUri(c.phone!)),
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
                      onPressed: () => openLink(context, Uri.parse(c.website!)),
                      icon: Icon(Icons.language, size: 16),
                      label: Text(
                        'Website',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  )
                else if (hasEmail)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => openLink(context, Uri(scheme: 'mailto', path: c.email!)),
                      icon: Icon(Icons.mail_outline, size: 16),
                      label: Text(
                        'Email',
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
            SizedBox(height: 4),
            Wrap(
              spacing: 8,
              children: [
                if (hasPhone && hasWebsite)
                  TextButton.icon(
                    onPressed: () => openLink(context, Uri.parse(c.website!)),
                    icon: Icon(Icons.language, size: 16),
                    label: Text('Website'),
                  ),
                if (hasEmail && (hasPhone || hasWebsite))
                  TextButton.icon(
                    onPressed: () => openLink(context, Uri(scheme: 'mailto', path: c.email!)),
                    icon: Icon(Icons.mail_outline, size: 16),
                    label: Text('Email'),
                  ),
                TextButton.icon(
                  onPressed: () => _copy(c.toShareText(), 'Contact details copied'),
                  icon: Icon(Icons.copy, size: 16),
                  label: Text('Copy details'),
                ),
              ],
            ),
            if (verified != null)
              Text(
                'Verified $verified',
                style: TextStyle(fontSize: 11, color: colors.muted),
              ),
          ],
        ),
      ),
    );
  }
}