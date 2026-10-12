/// Resident hub: local services, saved items and notification settings.
///
/// Lists `hubServices` from `data/services_data.dart`, the user's saved
/// categories/issues (written by Home and Results), and switches for alerts
/// and reminders. Each service sheet lists the user's county offices for that
/// service (phone and website). Where a county has no directory yet, or there
/// is no event feed, the sheet says "No new events found" / "No local options
/// found yet".
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config.dart';
import '../data/issue_tree.dart';
import '../data/services_data.dart';
import '../models/contact.dart';
import '../services/device_location_service.dart';
import '../services/launcher.dart';
import '../services/reminder_service.dart';
import '../services/resolver_service.dart';
import '../theme.dart';
import '../util/format.dart';
import '../widgets/address_dialog.dart';

class ResidentHubScreen extends StatefulWidget {
  final String? initialService;

  const ResidentHubScreen({this.initialService});

  @override
  State<ResidentHubScreen> createState() => _ResidentHubScreenState();
}

class _ResidentHubScreenState extends State<ResidentHubScreen> {
  String locationLabel = 'Your local service area';
  // "County, ST" key (e.g. "Baltimore County, MD") used to look up local offices.
  String? countyName;
  List<String> savedCategoryNames = [];
  List<String> savedIssueNames = [];
  bool alertsEnabled = true;
  bool remindersEnabled = true;
  bool refreshing = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    var label = 'Your local service area';
    String? county;
    final lat = prefs.getDouble('lat');
    final lng = prefs.getDouble('lng');
    if (lat != null && lng != null) {
      try {
        final location = await getCachedLocation(lat, lng);
        label = '${location.county}, ${location.state}';
        county = countyKeyFor(location);
      } catch (e) {
        debugPrint('Resident hub location lookup failed: $e');
      }
    }

    // "My civic follow-up" used to only ever show saved *categories*, even
    // though saving an individual issue (from the results screen) writes to
    // a separate `saved_issues` key. Pull both in so what you saved
    // elsewhere in the app actually shows up here.
    final savedCategoryIds = prefs.getStringList('saved_categories') ?? [];
    final savedIssueIds = prefs.getStringList('saved_issues') ?? [];
    final categoryNames = savedCategoryIds
        .map((id) => findCategoryById(id)?.name)
        .whereType<String>()
        .toList();
    final issueNames = savedIssueIds
        .map((id) => findIssueById(id)?.name)
        .whereType<String>()
        .toList();

    if (!mounted) return;
    setState(() {
      locationLabel = label;
      countyName = county;
      savedCategoryNames = categoryNames;
      savedIssueNames = issueNames;
      alertsEnabled = prefs.getBool('alerts_enabled') ?? true;
      remindersEnabled = prefs.getBool('reminders_enabled') ?? true;
    });
  }

  Future<void> _refreshLocation() async {
    setState(() => refreshing = true);
    try {
      final position = await getDeviceLocation();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('lat', position.latitude);
      await prefs.setDouble('lng', position.longitude);
      await prefs.setString('location_source', 'gps');
    } catch (e) {
      debugPrint('Refresh location failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Couldn't get your location. Turn on location access, or enter an address instead.")),
        );
      }
    }
    await _load();
    if (mounted) setState(() => refreshing = false);
  }

  Future<void> _enterAddress() async {
    final saved = await promptForAddress(context);
    if (saved && mounted) await _load();
  }

  Future<void> _setPreference(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  void _showService(HubService service, AppColors colors) {
    final contacts = serviceContactsFor(countyName, service.title);
    final isCommunity = service.title == 'Community programs';
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: colors.surface,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(service.icon, color: colors.accent, size: 24),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      service.title,
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: colors.textPrimary),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Text(
                service.subtitle,
                style: TextStyle(color: colors.muted, height: 1.4),
              ),
              SizedBox(height: 16),
              // Stub: there is no live events feed yet, so Community programs
              // says so plainly (the offices below are still real).
              if (isCommunity && AppConfig.enableLocalAlerts) ...[
                _sheetNotice(colors, Icons.event_busy_outlined, 'No new events found for $locationLabel.'),
                SizedBox(height: 12),
              ],
              if (contacts.isEmpty)
                _sheetNotice(colors, Icons.search_off, 'No local options found yet for $locationLabel.')
              else
                ...contacts.map((c) => _sheetContact(c, colors)),
              SizedBox(height: 4),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(minimumSize: Size.fromHeight(48)),
                  child: Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sheetNotice(AppColors colors, IconData icon, String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surfaceSecondary,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: colors.muted, size: 18),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(fontWeight: FontWeight.w700, color: colors.textPrimary, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sheetContact(Contact c, AppColors colors) {
    final hasPhone = c.phone != null;
    final hasWebsite = c.website != null;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surfaceSecondary,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            c.name,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: colors.textPrimary),
          ),
          SizedBox(height: 2),
          Text(c.office, style: TextStyle(fontSize: 13, color: colors.muted, height: 1.3)),
          if (formatVerified(c.lastVerified) != null)
            Text('Verified ${formatVerified(c.lastVerified)}', style: TextStyle(fontSize: 11, color: colors.muted)),
          if (hasPhone || hasWebsite) ...[
            SizedBox(height: 10),
            Row(
              children: [
                if (hasPhone)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => openLink(context, phoneUri(c.phone!)),
                      icon: Icon(Icons.call, size: 16, color: Colors.white),
                      label: Text(
                        c.phone!,
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(backgroundColor: colors.accent),
                    ),
                  ),
                if (hasPhone && hasWebsite) SizedBox(width: 8),
                if (hasWebsite)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => openLink(context, Uri.parse(c.website!)),
                      icon: Icon(Icons.language, size: 16),
                      label: Text('Website', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        backgroundColor: colors.surface,
        foregroundColor: colors.textPrimary,
        title: Text('Resident hub'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          _locationCard(colors),
          SizedBox(height: 20),
          Text('Local services', style: _headingStyle(colors)),
          SizedBox(height: 10),
          ...hubServices.map((service) => _serviceTile(service, colors)),
          SizedBox(height: 20),
          Text('My civic follow-up', style: _headingStyle(colors)),
          SizedBox(height: 10),
          _savedCard(colors),
          SizedBox(height: 20),
          if (AppConfig.enableLocalAlerts) ...[
            Text('Notifications and alerts', style: _headingStyle(colors)),
            SizedBox(height: 10),
            _settingsCard(colors),
            SizedBox(height: 20),
          ],
          Text('What happens next?', style: _headingStyle(colors)),
          SizedBox(height: 10),
          _guidanceCard(colors),
          SizedBox(height: 20),
          Text('About', style: _headingStyle(colors)),
          SizedBox(height: 10),
          _aboutCard(colors),
        ],
      ),
    );
  }

  Widget _aboutCard(AppColors colors) {
    return Container(
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
            'Contact information can change. Confirm with the office before you rely on it.',
            style: TextStyle(color: colors.muted, fontSize: 13, height: 1.4),
          ),
          SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => openLink(context, Uri.parse(AppConfig.privacyPolicyUrl)),
            icon: Icon(Icons.privacy_tip_outlined, size: 18),
            label: Text('Privacy policy'),
          ),
        ],
      ),
    );
  }

  TextStyle _headingStyle(AppColors colors) => TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w800,
    color: colors.textPrimary,
  );

  Widget _locationCard(AppColors colors) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.light.brandPrimary, AppColors.light.brandSecondary],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.map_outlined, color: Colors.white),
              SizedBox(width: 10),
              Text(
                'Your service area',
                style: TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          Text(
            locationLabel,
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              'City offices',
              'County offices',
              'State offices',
              'House district',
              'Senate district',
            ].map((label) => _locationPill(label)).toList(),
          ),
          SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
          OutlinedButton.icon(
            onPressed: refreshing ? null : _refreshLocation,
            icon: refreshing
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Icon(Icons.my_location, color: Colors.white, size: 18),
            label: Text(
              refreshing ? 'Refreshing…' : 'Refresh my area',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.white54),
            ),
          ),
          OutlinedButton.icon(
            onPressed: refreshing ? null : _enterAddress,
            icon: Icon(Icons.edit_location_alt_outlined, color: Colors.white, size: 18),
            label: Text(
              'Enter an address',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.white54),
            ),
          ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _locationPill(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white24),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _serviceTile(HubService service, AppColors colors) {
    final highlighted = widget.initialService == service.title;
    return Semantics(
      button: true,
      label: '${service.title}. ${service.subtitle}',
      child: Card(
        margin: const EdgeInsets.only(bottom: 10),
        elevation: 0,
        color: highlighted ? colors.accentSoft : colors.surfaceSecondary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: highlighted ? colors.accent : colors.border,
          ),
        ),
        child: ListTile(
          minVerticalPadding: 12,
          leading: CircleAvatar(
            backgroundColor: highlighted
                ? colors.accent
                : colors.surfaceTertiary,
            child: Icon(
              service.icon,
              color: highlighted ? Colors.white : colors.textPrimary,
            ),
          ),
          title: Text(
            service.title,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: colors.textPrimary,
            ),
          ),
          subtitle: Text(
            service.subtitle,
            style: TextStyle(color: colors.muted),
          ),
          trailing: Icon(Icons.chevron_right, color: colors.muted),
          onTap: () => _showService(service, colors),
        ),
      ),
    );
  }

  Widget _savedCard(AppColors colors) {
    final hasAny = savedCategoryNames.isNotEmpty || savedIssueNames.isNotEmpty;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: !hasAny
          ? Row(
              children: [
                Icon(Icons.bookmark_outline, color: colors.accent),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Save an issue category or official after finding help. Your follow-up status will stay with it.',
                    style: TextStyle(color: colors.muted, height: 1.4),
                  ),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${savedCategoryNames.length + savedIssueNames.length} saved item${(savedCategoryNames.length + savedIssueNames.length) == 1 ? '' : 's'}',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: colors.textPrimary,
                  ),
                ),
                SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ...savedCategoryNames.map(
                      (name) => Chip(
                        label: Text(name),
                        avatar: Icon(
                          Icons.bookmark,
                          size: 16,
                          color: colors.accent,
                        ),
                      ),
                    ),
                    ...savedIssueNames.map(
                      (name) => Chip(
                        label: Text(name),
                        avatar: Icon(
                          Icons.flag_outlined,
                          size: 16,
                          color: colors.accent,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4),
                Text(
                  'Track each saved topic from Not started to Resolved.',
                  style: TextStyle(color: colors.muted, fontSize: 12),
                ),
              ],
            ),
    );
  }

  Widget _settingsCard(AppColors colors) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: colors.surfaceSecondary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.border),
      ),
      child: Column(
        children: [
          SwitchListTile.adaptive(
            title: Text(
              'Local alerts',
              style: TextStyle(fontWeight: FontWeight.w700, color: colors.textPrimary),
            ),
            subtitle: Text('Official notices, events, and town halls', style: TextStyle(color: colors.muted)),
            value: alertsEnabled,
            onChanged: (value) {
              setState(() => alertsEnabled = value);
              _setPreference('alerts_enabled', value);
            },
          ),
          Divider(height: 1, color: colors.border),
          SwitchListTile.adaptive(
            title: Text(
              'Issue reminders',
              style: TextStyle(fontWeight: FontWeight.w700, color: colors.textPrimary),
            ),
            subtitle: Text('Follow up later on saved issues', style: TextStyle(color: colors.muted)),
            value: remindersEnabled,
            onChanged: (value) {
              setState(() => remindersEnabled = value);
              _setPreference('reminders_enabled', value);
              // Turning off clears pending follow-ups; turning on asks for permission.
              if (value) {
                ReminderService.requestPermission();
              } else {
                ReminderService.cancelAll();
              }
            },
          ),
          Divider(height: 1, color: colors.border),
          // Stub: the switches above are saved, but no alert/reminder source
          // exists yet, so say so instead of leaving the card silent.
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Row(
              children: [
                Icon(Icons.notifications_none, size: 18, color: colors.muted),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    (!alertsEnabled && !remindersEnabled)
                        ? 'Notifications are turned off.'
                        : 'No new events or reminders right now.',
                    style: TextStyle(color: colors.muted, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _guidanceCard(AppColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.accentSoft,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Before you contact an office',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: colors.accent,
            ),
          ),
          SizedBox(height: 10),
          _guidanceRow(
            Icons.check_circle_outline,
            'Confirm who is responsible: local, county, state, or federal.',
            colors,
          ),
          _guidanceRow(
            Icons.folder_outlined,
            'Prepare dates, addresses, photos, and case numbers.',
            colors,
          ),
          _guidanceRow(
            Icons.reply_outlined,
            'Ask what happens next and when to follow up.',
            colors,
          ),
        ],
      ),
    );
  }

  Widget _guidanceRow(IconData icon, String text, AppColors colors) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: colors.accent),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: colors.textPrimary, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}
