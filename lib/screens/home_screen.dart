/// Main screen: search, issue categories, dashboard and local alerts.
///
/// Shows the current county/state, a searchable grid of issue categories
/// from `data/issue_tree.dart` (opens `CategoryScreen`), a "Saved topics" list
/// for quick access to bookmarked categories and issues, service shortcuts
/// (opens `ResidentHubScreen`) and a "Local alerts" section that shows
/// "No new events found" until a real feed is connected.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config.dart';
import '../data/issue_tree.dart';
import '../data/services_data.dart';
import '../models/issue.dart';
import '../services/device_location_service.dart';
import '../services/resolver_service.dart';
import '../theme.dart';
import '../widgets/address_dialog.dart';
import '../widgets/glass.dart';
import 'category_screen.dart';
import 'results_screen.dart';
import 'resident_hub_screen.dart';

/// The app's landing page: category search, saved topics, dashboard and alerts.
class HomeScreen extends StatefulWidget {
  /// Creates the mutable state that holds saved lists, location and search text.
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

/// State for [HomeScreen]: loads location and saved data, and builds the page.
class _HomeScreenState extends State<HomeScreen> {
  /// Text shown in the location chip; becomes "County, State" once resolved.
  String locationLabel = 'Your location';
  /// Drives the search box so the category grid can filter as the user types.
  final TextEditingController _searchController = TextEditingController();
  /// Ids of categories the user bookmarked (persisted in SharedPreferences).
  List<String> savedCategories = [];
  /// Ids of individual issues the user bookmarked from the results screen.
  List<String> savedIssues = [];
  /// Up to three most recently opened category ids, newest first.
  List<String> recentCategories = [];
  /// Whether the user wants the "Local alerts" section shown (hub switch).
  bool alertsEnabled = true;
  /// Message explaining missing local-office coverage, or null when covered.
  // Shown when the user's county has no hand-checked local offices yet.
  String? coverageNote;

  /// Kicks off the location lookup and loads saved state when the screen opens.
  @override
  void initState() {
    super.initState();
    _loadLocation();
    _loadSavedState();
  }

  /// Releases the search controller when the screen goes away.
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Reads saved, recent and alert-setting values from SharedPreferences into state.
  Future<void> _loadSavedState() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      savedCategories = prefs.getStringList('saved_categories') ?? [];
      savedIssues = prefs.getStringList('saved_issues') ?? [];
      recentCategories = prefs.getStringList('recent_categories') ?? [];
      // Local alerts used to always render regardless of this setting, even
      // though the resident hub's "Local alerts" switch implied it controlled
      // them. Now it actually does.
      alertsEnabled = prefs.getBool('alerts_enabled') ?? true;
    });
  }

  /// Adds or removes a category from the saved list and persists the change.
  Future<void> _toggleSaved(String categoryId) async {
    final prefs = await SharedPreferences.getInstance();
    final updated = List<String>.from(savedCategories);
    if (updated.contains(categoryId)) {
      updated.remove(categoryId);
    } else {
      updated.add(categoryId);
    }
    setState(() => savedCategories = updated);
    await prefs.setStringList('saved_categories', updated);
  }

  /// Opens a category screen and records it as recently viewed.
  // Saving an issue happens two screens deep (Results), so reload the saved
  // lists whenever we come back to Home.
  void _openCategory(IssueCategory cat) {
    _trackRecent(cat.id);
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => CategoryScreen(category: cat)))
        .then((_) => _loadSavedState());
  }

  /// Opens the results screen for a single saved issue, then refreshes saved state.
  void _openIssue(Issue issue) {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => ResultsScreen(issue: issue)))
        .then((_) => _loadSavedState());
  }

  /// Moves a category to the front of the recent list (max three) and saves it.
  Future<void> _trackRecent(String categoryId) async {
    final prefs = await SharedPreferences.getInstance();
    final updated = List<String>.from(recentCategories);
    updated.remove(categoryId);
    updated.insert(0, categoryId);
    final trimmed = updated.take(3).toList();
    setState(() => recentCategories = trimmed);
    await prefs.setStringList('recent_categories', trimmed);
  }

  /// Works out the user's county/state label and whether local offices are covered.
  ///
  /// Uses GPS unless the user typed an address, falling back to the last saved position.
  Future<void> _loadLocation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      double? lat = prefs.getDouble('lat');
      double? lng = prefs.getDouble('lng');

      // A typed-in address is the user's choice; don't replace it with GPS.
      // (When address entry is switched off, any old saved address is ignored
      // and the device location is always used.)
      if (!AppConfig.enableAddressEntry || prefs.getString('location_source') != 'address') {
        try {
          final position = await getDeviceLocation();
          lat = position.latitude;
          lng = position.longitude;
          await prefs.setDouble('lat', lat);
          await prefs.setDouble('lng', lng);
          await prefs.setString('location_source', 'gps');
        } catch (e) {
          // Use the last known position if location services are unavailable.
          debugPrint('Device location unavailable, using last saved position: $e');
        }
      }

      if (lat == null || lng == null) return;

      final location = await getCachedLocation(lat, lng);
      if (mounted) {
        setState(() {
          locationLabel = '${location.county}, ${location.state}';
          coverageNote = hasCountyDirectory(location)
              ? null
              : "Local offices for ${location.county}, ${location.stateAbbr} aren't built in yet. "
                  'Federal and state officials still work here; full local coverage is in Baltimore County, MD.';
        });
      }
    } catch (e) {
      // Keep the generic label when the location can't be looked up (offline, etc.).
      debugPrint('Home location lookup failed: $e');
    }
  }

  /// "Change area": use the device location again, or type an address.
  Future<void> _changeArea() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      backgroundColor: const Color(0xFF16345C),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Change your area', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
              SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.my_location, color: Colors.white),
                title: Text('Use my current location', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                onTap: () => Navigator.pop(context, 'gps'),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.edit_location_alt_outlined, color: Colors.white),
                title: Text('Enter an address', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                // Grayed out when address entry is switched off (see AppConfig.enableAddressEntry).
                enabled: AppConfig.enableAddressEntry,
                onTap: AppConfig.enableAddressEntry ? () => Navigator.pop(context, 'address') : null,
              ),
            ],
          ),
        ),
      ),
    );
    if (!mounted || choice == null) return;

    if (choice == 'address') {
      final saved = await promptForAddress(context);
      if (!saved || !mounted) return;
      await _loadLocation();
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('location_source', 'gps');
    await _loadLocation();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Using your device location for local routing.')),
    );
  }

  /// Shows a bottom sheet listing recently viewed categories, tappable to reopen.
  void _showRecentSheet() {
    final names = recentCategories
        .map((id) {
          final match = issueTree.where((c) => c.id == id);
          return match.isEmpty ? null : match.first;
        })
        .whereType<IssueCategory>()
        .toList();

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: const Color(0xFF16345C),
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recently viewed',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
            ),
            SizedBox(height: 12),
            if (names.isEmpty)
              Text(
                'Categories you open will show up here.',
                style: TextStyle(color: Colors.white70),
              )
            else
              ...names.map(
                (cat) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(cat.icon, color: Colors.white),
                  title: Text(cat.name, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                  onTap: () {
                    Navigator.pop(context);
                    _openCategory(cat);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Categories matching the search text (name, description or sub-issues), or all when empty.
  List<IssueCategory> get filteredCategories {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return issueTree;

    return issueTree.where((category) {
      final haystack = [
        category.name,
        category.description,
        ...category.subIssues.map((issue) => issue.name),
        ...category.subIssues.map((issue) => issue.description),
      ].join(' ').toLowerCase();
      return haystack.contains(query);
    }).toList();
  }

  /// Builds the scrolling home page: header, search, saved topics, dashboard, alerts and grid.
  @override
  Widget build(BuildContext context) {
    // Previously this was a second, hand-maintained copy of the "local
    // services" list that lived only on this screen and quietly drifted out
    // of sync with the resident hub's own copy (6 items here vs. 7 there,
    // different subtitles/icons for the same service). Both screens now
    // read from the same `hubServices` list in data/services_data.dart.
    final serviceTiles = hubServices
        .map((service) => _ServiceTile(
              title: service.title,
              subtitle: service.subtitle,
              icon: service.icon,
            ))
        .toList();

    final dashboardCards = [
      _DashboardCard(
        label: 'Saved',
        value: '${savedCategories.length + savedIssues.length}',
        icon: Icons.bookmark_outline,
      ),
      _DashboardCard(
        label: 'Recent',
        value: '${recentCategories.length}',
        icon: Icons.history,
        onTap: recentCategories.isEmpty ? null : _showRecentSheet,
      ),
      _DashboardCard(
        label: 'Local services',
        value: '${hubServices.length} links',
        icon: Icons.grid_view_outlined,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => ResidentHubScreen()),
        ),
      ),
    ];

    // Stub: no live events/alerts feed is connected yet. These used to be two
    // hard-coded fake alerts ("Town hall", "Road work") that showed for every
    // user. Until a real source exists, the list stays empty and the section
    // shows a "No new events found" message instead.
    final List<_AlertCard> alerts = <_AlertCard>[];

    // The old layout wrapped the scroll view in a SafeArea, which clipped the
    // category cards in a hard line at the status bar and home indicator. The
    // scroll view now fills the whole screen and the safe-area insets are
    // added as padding *inside* it, so content scrolls out smoothly. The
    // status bar icons are forced light because the gradient behind them is dark.
    final safe = MediaQuery.of(context).padding;
    return Scaffold(
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(gradient: AppGradients.background),
        child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: EdgeInsets.fromLTRB(20, safe.top + 12, 20, 8),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GlassContainer(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        radius: 999,
                        opacity: 0.18,
                        tint: Colors.white,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.location_on,
                              color: Colors.white,
                              size: 14,
                            ),
                            SizedBox(width: 6),
                            Text(
                              locationLabel,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 20),
                      Text(
                        "What's the issue?",
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          height: 1.1,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        "Tap a category to see who handles it. Tap the bookmark to save it.",
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.white70,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                sliver: SliverToBoxAdapter(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      style: TextStyle(color: Colors.white, fontSize: 15),
                      decoration: InputDecoration(
                        hintText: 'Search issues and services',
                        hintStyle: TextStyle(color: Colors.white70),
                        prefixIcon: Icon(Icons.search, color: Colors.white70),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (coverageNote != null) _coverageNoteCard(),
                      _savedTopicsSection(),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'My civic dashboard',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 12),
                      Row(
                        children: [
                          for (var i = 0; i < dashboardCards.length; i++) ...[
                            if (i > 0) SizedBox(width: 8),
                            Expanded(child: dashboardCards[i]),
                          ],
                        ],
                      ),
                      SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.map_outlined,
                              color: Colors.white,
                              size: 18,
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Current service area',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    locationLabel,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            TextButton(
                              onPressed: _changeArea,
                              child: Text(
                                'Change area',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 12),
                      SizedBox(
                        height: 150,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: serviceTiles.length,
                          separatorBuilder: (_, __) => SizedBox(width: 10),
                          itemBuilder: (context, index) => GestureDetector(
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ResidentHubScreen(
                                  initialService: serviceTiles[index].title,
                                ),
                              ),
                            ),
                            child: serviceTiles[index],
                          ),
                        ),
                      ),
                      SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ResidentHubScreen(),
                            ),
                          ),
                          icon: Icon(
                            Icons.dashboard_customize_outlined,
                            color: Colors.white,
                          ),
                          label: Text(
                            'Open resident services hub',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            minimumSize: Size.fromHeight(50),
                            side: BorderSide(
                              color: Colors.white.withValues(alpha: 0.5),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (AppConfig.enableLocalAlerts && alertsEnabled)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Local alerts',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 10),
                        if (alerts.isEmpty)
                          const _EmptyAlertsCard()
                        else
                          ...alerts.map(
                            (alert) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: alert,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 32 + safe.bottom),
                sliver: filteredCategories.isEmpty
                    ? SliverToBoxAdapter(
                        child: GlassContainer(
                          padding: EdgeInsets.all(20),
                          opacity: 0.18,
                          radius: 18,
                          child: Text(
                            'No matching issues yet. Try another keyword.',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      )
                    : SliverGrid(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 14,
                          crossAxisSpacing: 14,
                          childAspectRatio: 0.92,
                        ),
                        delegate: SliverChildBuilderDelegate((context, i) {
                          final cat = filteredCategories[i];
                          return _CategoryCard(
                            cat: cat,
                            saved: savedCategories.contains(cat.id),
                            onToggleSave: () => _toggleSaved(cat.id),
                            onOpen: () => _openCategory(cat),
                          );
                        }, childCount: filteredCategories.length),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Small info card showing [coverageNote] when local offices are not built in yet.
  Widget _coverageNoteCard() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: Colors.white, size: 18),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              coverageNote!,
              style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  /// "Saved topics": bookmarked categories and issues, one tap away.
  Widget _savedTopicsSection() {
    final cats = savedCategories
        .map(findCategoryById)
        .whereType<IssueCategory>()
        .toList();
    final issues = savedIssues
        .map(findIssueById)
        .whereType<Issue>()
        .toList();

    // Builds one tappable saved-topic row (category or issue).
    Widget row(IconData icon, String title, String kind, VoidCallback onTap) {
      return Semantics(
        button: true,
        label: '$title, saved $kind',
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                Icon(icon, color: Colors.white, size: 20),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        kind,
                        style: TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: Colors.white70),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Saved topics',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 10),
        if (cats.isEmpty && issues.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                Icon(Icons.bookmark_border, color: Colors.white, size: 18),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'No saved topics yet. Tap the bookmark on a category to keep it here.',
                    style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                  ),
                ),
              ],
            ),
          )
        else ...[
          ...cats.map((c) => row(c.icon, c.name, 'Category', () => _openCategory(c))),
          ...issues.map((i) => row(Icons.flag_outlined, i.name, 'Topic', () => _openIssue(i))),
        ],
      ],
    );
  }
}

/// Tile in the horizontal services strip, showing an icon, title and short subtitle.
class _ServiceTile extends StatelessWidget {
  /// Service name; also used to open the matching section of the hub.
  final String title;
  /// One-line description shown under the title.
  final String subtitle;
  /// Icon representing the service.
  final IconData icon;

  const _ServiceTile({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  /// Builds the tile with a semantics label for screen readers.
  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$title, $subtitle',
      child: Container(
        width: 170,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 4),
            Flexible(
              child: Text(
                subtitle,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Card for a single local alert or event (none are shown until a feed exists).
class _AlertCard extends StatelessWidget {
  /// Short headline of the alert.
  final String title;
  /// Longer description of the alert.
  final String body;
  /// Icon shown at the left of the card.
  final IconData icon;

  const _AlertCard({
    required this.title,
    required this.body,
    required this.icon,
  });

  /// Builds the alert card with a combined semantics label.
  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$title. $body',
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    body,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shown in the "Local alerts" section while no real alerts/events exist.
class _EmptyAlertsCard extends StatelessWidget {
  const _EmptyAlertsCard();

  /// Builds the empty-state card with a semantics label.
  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'No new events found',
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.event_busy_outlined, color: Colors.white, size: 18),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'No new events found',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Town halls, road work, and other local notices will show up here.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small stat tile on the dashboard (saved count, recent count, services).
class _DashboardCard extends StatelessWidget {
  /// Caption above the value.
  final String label;
  /// Headline number or text for the tile.
  final String value;
  /// Icon at the top of the tile.
  final IconData icon;
  /// Optional tap handler; when null the tile is not tappable.
  final VoidCallback? onTap;

  const _DashboardCard({
    required this.label,
    required this.value,
    required this.icon,
    this.onTap,
  });

  /// Builds the tile and wraps it in a button only when [onTap] is set.
  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 18),
          SizedBox(height: 10),
          Text(
            label,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
    if (onTap == null) return card;
    return Semantics(
      button: true,
      label: '$label, $value',
      child: GestureDetector(onTap: onTap, child: card),
    );
  }
}

/// One tile in the category grid with a press animation and a bookmark button.
class _CategoryCard extends StatefulWidget {
  /// The issue category this card displays.
  final IssueCategory cat;
  /// Whether the category is currently bookmarked.
  final bool saved;
  /// Called when the bookmark button is tapped.
  final VoidCallback onToggleSave;
  /// Called when the card itself is tapped.
  final VoidCallback onOpen;

  _CategoryCard({
    required this.cat,
    required this.saved,
    required this.onToggleSave,
    required this.onOpen,
  });

  /// Creates the state that tracks the pressed (shrunk) look.
  @override
  State<_CategoryCard> createState() => _CategoryCardState();
}

/// State for [_CategoryCard].
class _CategoryCardState extends State<_CategoryCard> {
  /// True while a finger is down, which shrinks the card slightly.
  bool pressed = false;

  /// Builds the card with its icon, bookmark button, name and description.
  @override
  Widget build(BuildContext context) {
    final cat = widget.cat;
    return GestureDetector(
      onTapDown: (_) => setState(() => pressed = true),
      onTapUp: (_) => setState(() => pressed = false),
      onTapCancel: () => setState(() => pressed = false),
      onTap: widget.onOpen,
      child: AnimatedScale(
        scale: pressed ? 0.96 : 1.0,
        duration: Duration(milliseconds: 100),
        child: GlassContainer(
          padding: const EdgeInsets.all(18),
          opacity: 0.22,
          tint: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(cat.icon, color: Colors.white, size: 22),
                  ),
                  // 44x44 tap target around a small visual circle (it used to
                  // be only 26x26, which is hard to hit on a phone).
                  Semantics(
                    button: true,
                    label: widget.saved ? 'Remove ${cat.name} from saved topics' : 'Save ${cat.name}',
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: widget.onToggleSave,
                      child: SizedBox(
                        width: 44,
                        height: 44,
                        child: Center(
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              widget.saved ? Icons.bookmark : Icons.bookmark_border,
                              size: 18,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Spacer(),
              Text(
                cat.name,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 4),
              Text(
                cat.description,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white70,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

