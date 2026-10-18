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
import '../data/search.dart';
import '../data/services_data.dart';
import '../models/issue.dart';
import '../services/device_location_service.dart';
import '../services/launcher.dart';
import '../services/resolver_service.dart';
import '../theme.dart';
import '../widgets/address_dialog.dart';
import '../widgets/glass.dart';
import 'category_screen.dart';
import 'results_screen.dart';
import 'resident_hub_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String locationLabel = 'Your location';
  final TextEditingController _searchController = TextEditingController();
  List<String> savedCategories = [];
  List<String> savedIssues = [];
  List<String> recentCategories = [];
  bool alertsEnabled = true;
  // Shown when the user's county has no hand-checked local offices yet.
  String? coverageNote;

  @override
  void initState() {
    super.initState();
    _loadLocation();
    _loadSavedState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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

  // Saving an issue happens two screens deep (Results), so reload the saved
  // lists whenever we come back to Home.
  void _openCategory(IssueCategory cat) {
    _trackRecent(cat.id);
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => CategoryScreen(category: cat)))
        .then((_) => _loadSavedState());
  }

  void _openIssue(Issue issue) {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => ResultsScreen(issue: issue)))
        .then((_) => _loadSavedState());
  }

  Future<void> _trackRecent(String categoryId) async {
    final prefs = await SharedPreferences.getInstance();
    final updated = List<String>.from(recentCategories);
    updated.remove(categoryId);
    updated.insert(0, categoryId);
    final trimmed = updated.take(3).toList();
    setState(() => recentCategories = trimmed);
    await prefs.setStringList('recent_categories', trimmed);
  }

  Future<void> _loadLocation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      double? lat = prefs.getDouble('lat');
      double? lng = prefs.getDouble('lng');

      // A typed-in address is the user's choice; don't replace it with GPS.
      if (prefs.getString('location_source') != 'address') {
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
                onTap: () => Navigator.pop(context, 'address'),
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

  /// What the user typed, trimmed. Non-empty means "searching": the screen
  /// then shows only the matching issues instead of its usual panels.
  String get _query => _searchController.text.trim();

  void _clearSearch() {
    _searchController.clear();
    FocusScope.of(context).unfocus();
    setState(() {});
  }

  void _openIssueFromSearch(IssueCategory cat, Issue issue) {
    _trackRecent(cat.id);
    _openIssue(issue);
  }

  /// Search results: just the categories (and the topics inside them) that
  /// match what was typed, so you can see where the issue belongs.
  Widget _searchResultsSliver(List<SearchHit> hits, String query) {
    final emptyStyle = TextStyle(color: Colors.white70, fontSize: 13, height: 1.45);
    return SliverPadding(
      padding: EdgeInsets.fromLTRB(20, 4, 20, 32 + MediaQuery.of(context).padding.bottom),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          if (hits.isEmpty)
            _infoPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nothing matched "$query"',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Try describing the problem in your own words, like "pothole on my street" '
                    'or "landlord won\'t fix the heat", or search a single word such as "rent" or "vote".',
                    style: emptyStyle,
                  ),
                  SizedBox(height: 4),
                  TextButton(
                    onPressed: _clearSearch,
                    style: TextButton.styleFrom(padding: EdgeInsets.zero, foregroundColor: Colors.white),
                    child: Text('Browse all categories', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            )
          else ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                hits.length == 1 ? '1 matching category' : '${hits.length} matching categories',
                style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w700),
              ),
            ),
            for (final hit in hits)
              _SearchResultCard(
                hit: hit,
                saved: savedCategories.contains(hit.category.id),
                onToggleSave: () => _toggleSaved(hit.category.id),
                onOpenCategory: () => _openCategory(hit.category),
                onOpenIssue: (issue) => _openIssueFromSearch(hit.category, issue),
              ),
          ],
        ]),
      ),
    );
  }

  /// A plain, non-tappable information panel. It is deliberately flat (no
  /// border, no chevron) so it can't be mistaken for a button or a row you can tap.
  Widget _infoPanel({required Widget child, EdgeInsets padding = const EdgeInsets.all(14)}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final query = _query;
    final searching = query.isNotEmpty;
    final searchHits = searching ? searchIssues(query) : const <SearchHit>[];

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
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            slivers: [
              SliverPadding(
                padding: EdgeInsets.fromLTRB(20, safe.top + 12, 20, 8),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Plain label, not a pill: it isn't tappable ("Change area"
                      // further down is the control for that).
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.location_on,
                            color: Colors.white70,
                            size: 14,
                          ),
                          SizedBox(width: 4),
                          Text(
                            locationLabel,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      Text(
                        "What's the issue?",
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          height: 1.1,
                          color: Colors.white,
                        ),
                      ),
                      if (!searching) ...[
                        SizedBox(height: 6),
                        Text(
                          "Search, or tap a category to see who handles it. Tap the bookmark to save it.",
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.white70,
                            height: 1.4,
                          ),
                        ),
                      ],
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
                      textInputAction: TextInputAction.search,
                      style: TextStyle(color: Colors.white, fontSize: 15),
                      decoration: InputDecoration(
                        hintText: 'Search or ask, e.g. "who fixes potholes?"',
                        hintStyle: TextStyle(color: Colors.white70),
                        prefixIcon: Icon(Icons.search, color: Colors.white70),
                        suffixIcon: searching
                            ? IconButton(
                                tooltip: 'Clear search',
                                icon: Icon(Icons.close, color: Colors.white70),
                                onPressed: _clearSearch,
                              )
                            : null,
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
              // While searching, every other panel is hidden so only the
              // matching issues show. Clearing the search brings them all back.
              if (searching)
                _searchResultsSliver(searchHits, query)
              else ...[
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
                      _infoPanel(
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
                      SizedBox(height: 20),
                      _emergencySection(),
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
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: 0.92,
                  ),
                  delegate: SliverChildBuilderDelegate((context, i) {
                    final cat = issueTree[i];
                    return _CategoryCard(
                      cat: cat,
                      saved: savedCategories.contains(cat.id),
                      onToggleSave: () => _toggleSaved(cat.id),
                      onOpen: () => _openCategory(cat),
                    );
                  }, childCount: issueTree.length),
                ),
              ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Quick calls for urgent situations. These are real buttons (tap to dial).
  Widget _emergencySection() {
    Widget call(String number) => OutlinedButton.icon(
          onPressed: () => openLink(context, phoneUri(number)),
          icon: Icon(Icons.call, color: Colors.white, size: 16),
          label: Text(
            'Call $number',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
          ),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: Colors.white.withValues(alpha: 0.5)),
          ),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Need help right now?',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
        ),
        SizedBox(height: 6),
        Text(
          '911 for emergencies. 988 for a mental health crisis. 211 for food, housing and other local help.',
          style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
        ),
        SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            call('911'),
            call('988'),
            call('211'),
          ],
        ),
      ],
    );
  }

  Widget _coverageNoteCard() {
    return _infoPanel(
      padding: const EdgeInsets.all(12),
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
          _infoPanel(
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

class _ServiceTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _ServiceTile({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

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
            Row(
              children: [
                Icon(icon, color: Colors.white, size: 20),
                Spacer(),
                Icon(Icons.arrow_forward, color: Colors.white70, size: 14),
              ],
            ),
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

class _AlertCard extends StatelessWidget {
  final String title;
  final String body;
  final IconData icon;

  const _AlertCard({
    required this.title,
    required this.body,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$title. $body',
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(12),
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

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'No new events found',
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(12),
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

class _DashboardCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final VoidCallback? onTap;

  const _DashboardCard({
    required this.label,
    required this.value,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Tappable cards get a fill, a border and an arrow; plain stats are flat
    // text, so only things you can tap look tappable.
    final tappable = onTap != null;
    final card = Container(
      padding: const EdgeInsets.all(12),
      decoration: tappable
          ? BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white, size: 18),
              if (tappable) ...[
                Spacer(),
                Icon(Icons.arrow_forward, color: Colors.white70, size: 14),
              ],
            ],
          ),
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

class _CategoryCard extends StatefulWidget {
  final IssueCategory cat;
  final bool saved;
  final VoidCallback onToggleSave;
  final VoidCallback onOpen;

  _CategoryCard({
    required this.cat,
    required this.saved,
    required this.onToggleSave,
    required this.onOpen,
  });

  @override
  State<_CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<_CategoryCard> {
  bool pressed = false;

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


/// One search result: the matching category (tap to open it, bookmark to save
/// it) with the specific topics inside it that matched (tap to go straight to
/// who handles that topic). Everything tappable has a chevron.
class _SearchResultCard extends StatelessWidget {
  final SearchHit hit;
  final bool saved;
  final VoidCallback onToggleSave;
  final VoidCallback onOpenCategory;
  final void Function(Issue issue) onOpenIssue;

  const _SearchResultCard({
    required this.hit,
    required this.saved,
    required this.onToggleSave,
    required this.onOpenCategory,
    required this.onOpenIssue,
  });

  @override
  Widget build(BuildContext context) {
    final cat = hit.category;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white.withValues(alpha: 0.12),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              button: true,
              label: 'Open ${cat.name}',
              child: InkWell(
                onTap: onOpenCategory,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 8, 4, 8),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(cat.icon, color: Colors.white, size: 20),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              cat.name,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              cat.description,
                              style: TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: saved ? 'Remove ${cat.name} from saved topics' : 'Save ${cat.name}',
                        onPressed: onToggleSave,
                        icon: Icon(
                          saved ? Icons.bookmark : Icons.bookmark_border,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      Icon(Icons.chevron_right, color: Colors.white70),
                      SizedBox(width: 6),
                    ],
                  ),
                ),
              ),
            ),
            for (final issue in hit.issues) ...[
              Divider(height: 1, color: Colors.white.withValues(alpha: 0.15)),
              Semantics(
                button: true,
                label: issue.name,
                child: InkWell(
                  onTap: () => onOpenIssue(issue),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
                    child: Row(
                      children: [
                        Icon(Icons.flag_outlined, color: Colors.white70, size: 16),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                issue.name,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                issue.description,
                                style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.3),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right, color: Colors.white70),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
