import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/issue_tree.dart';
import '../../data/services_data.dart';
import '../../services/device_location_service.dart';
import '../../services/resolver_service.dart';
import '../../theme.dart';

class ResidentHubScreen extends StatefulWidget {
  final String? initialService;

  const ResidentHubScreen({this.initialService});

  @override
  State<ResidentHubScreen> createState() => _ResidentHubScreenState();
}

class _ResidentHubScreenState extends State<ResidentHubScreen> {
  String locationLabel = 'Your local service area';
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
    final lat = prefs.getDouble('lat');
    final lng = prefs.getDouble('lng');
    if (lat != null && lng != null) {
      try {
        final location = await getCachedLocation(lat, lng);
        label = '${location.county}, ${location.state}';
      } catch (_) {}
    }

    // "My civic follow-up" used to only ever show saved *categories*, even
    // though saving an individual issue (from the results screen) writes to
    // a separate `saved_issues` key. Pull both in so what you saved
    // elsewhere in the app actually shows up here.
    final savedCategoryIds = prefs.getStringList('saved_categories') ?? [];
    final savedIssueIds = prefs.getStringList('saved_issues') ?? [];
    final categoryNames = issueTree
        .where((c) => savedCategoryIds.contains(c.id))
        .map((c) => c.name)
        .toList();
    final issueNames = issueTree
        .expand((c) => c.subIssues)
        .where((i) => savedIssueIds.contains(i.id))
        .map((i) => i.name)
        .toList();

    if (!mounted) return;
    setState(() {
      locationLabel = label;
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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not refresh location: $e')),
        );
      }
    }
    await _load();
    if (mounted) setState(() => refreshing = false);
  }

  Future<void> _setPreference(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  void _showService(HubService service, AppColors colors) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: colors.surface,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
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
            Text(
              'Available for $locationLabel',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
            ),
            SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.open_in_new),
                label: Text('View local options'),
                style: ElevatedButton.styleFrom(
                  minimumSize: Size.fromHeight(48),
                  backgroundColor: colors.accent,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
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
          Text('Notifications and alerts', style: _headingStyle(colors)),
          SizedBox(height: 10),
          _settingsCard(colors),
          SizedBox(height: 20),
          Text('What happens next?', style: _headingStyle(colors)),
          SizedBox(height: 10),
          _guidanceCard(colors),
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
                  'Track each issue from Issue found to Action steps ready.',
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
            },
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
