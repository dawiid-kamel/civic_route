import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/issue_tree.dart';
import '../../data/services_data.dart';
import '../../models/issue.dart';
import '../../services/device_location_service.dart';
import '../../services/resolver_service.dart';
import '../../theme.dart';
import '../../widgets/glass.dart';
import 'category_screen.dart';
import 'resident_hub_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String locationLabel = 'Your location';
  final TextEditingController _searchController = TextEditingController();
  List<String> savedCategories = [];
  List<String> recentCategories = [];
  bool alertsEnabled = true;

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

      try {
        final position = await getDeviceLocation();
        lat = position.latitude;
        lng = position.longitude;
        await prefs.setDouble('lat', lat);
        await prefs.setDouble('lng', lng);
      } catch (_) {
        // Use the last known position if location services are unavailable.
      }

      if (lat == null || lng == null) return;

      final location = await getCachedLocation(lat, lng);
      if (mounted) {
        setState(() => locationLabel = '${location.county}, ${location.state}');
      }
    } catch (_) {
      // Keep the generic label when reverse geocoding is unavailable.
    }
  }

  // "Change area" used to just pop a snackbar and do nothing else — it never
  // actually looked at the device's current position again. Now it does.
  Future<void> _refreshLocation() async {
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
                    _trackRecent(cat.id);
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => CategoryScreen(category: cat)),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<IssueCategory> get filteredCategories {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return issueTree;

    return issueTree.where((category) {
      final haystack = [
        category.name,
        category.description,
        ...category.subIssues.map((issue) => issue.name),
      ].join(' ').toLowerCase();
      return haystack.contains(query);
    }).toList();
  }

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
        value: '${savedCategories.length}',
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

    final alerts = [
      _AlertCard(
        title: 'Town hall',
        body: 'Public meeting this Thursday at 6:30 PM.',
        icon: Icons.campaign_outlined,
      ),
      _AlertCard(
        title: 'Road work',
        body: 'Lane closure on 7th Street through Friday.',
        icon: Icons.construction_outlined,
      ),
    ];

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppGradients.background),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
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
                        "Tap a category to route it, or tap (i) to learn what it covers.",
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
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                sliver: SliverToBoxAdapter(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        [
                          'Pothole',
                          'Housing',
                          'Transit',
                          'School',
                          'Taxes',
                        ].map((label) {
                          return Semantics(
                            button: true,
                            label: 'Search for $label',
                            child: GestureDetector(
                              onTap: () {
                                _searchController.text = label;
                                setState(() {});
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.25),
                                  ),
                                ),
                                child: Text(
                                  label,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
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
                        children: dashboardCards
                            .map((card) => Expanded(child: card))
                            .toList(),
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
                              onPressed: _refreshLocation,
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
              if (alertsEnabled)
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
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
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
                            onOpen: () => _trackRecent(cat.id),
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
    final card = Container(
      margin: const EdgeInsets.only(right: 8),
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

  // This used to open a separate bottom-sheet widget (_FaqSheet) that
  // duplicated the same FAQ content CategoryScreen already shows inline as
  // an expandable panel. Rather than maintaining the same data in two UI
  // patterns, the info icon now opens CategoryScreen directly with that
  // panel pre-expanded.
  void _openInfo(BuildContext context) {
    widget.onOpen();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CategoryScreen(category: widget.cat, startWithInfoOpen: true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cat = widget.cat;
    return GestureDetector(
      onTapDown: (_) => setState(() => pressed = true),
      onTapUp: (_) => setState(() => pressed = false),
      onTapCancel: () => setState(() => pressed = false),
      onTap: () {
        widget.onOpen();
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => CategoryScreen(category: cat)),
        );
      },
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
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          widget.onToggleSave();
                        },
                        child: Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            widget.saved
                                ? Icons.bookmark
                                : Icons.bookmark_border,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      if (cat.faqs.isNotEmpty) ...[
                        SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => _openInfo(context),
                          child: Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.info_outline,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
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

