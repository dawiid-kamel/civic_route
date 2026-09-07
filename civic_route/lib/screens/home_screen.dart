import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/issue_tree.dart';
import '../models/issue.dart';
import '../services/device_location_service.dart';
import '../services/resolver_service.dart';
import '../theme.dart';
import '../widgets/glass.dart';
import 'category_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String locationLabel = 'Your location';

  @override
  void initState() {
    super.initState();
    _loadLocation();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppGradients.background),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GlassContainer(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        radius: 999,
                        opacity: 0.18,
                        tint: Colors.white,
                        border: Border.all(color: Colors.white.withOpacity(0.3)),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.location_on, color: Colors.white, size: 14),
                          SizedBox(width: 6),
                          Text(locationLabel, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white)),
                        ]),
                      ),
                      SizedBox(height: 20),
                      Text("What's the issue?", style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, height: 1.1, color: Colors.white)),
                      SizedBox(height: 6),
                      Text("Tap a category to route it, or tap (i) to learn what it covers.",
                          style: TextStyle(fontSize: 15, color: Colors.white70, height: 1.4)),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 14, crossAxisSpacing: 14, childAspectRatio: 0.92),
                  delegate: SliverChildBuilderDelegate((context, i) {
                    final cat = issueTree[i];
                    return _CategoryCard(cat: cat);
                  }, childCount: issueTree.length),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryCard extends StatefulWidget {
  final IssueCategory cat;
  _CategoryCard({required this.cat});
  @override
  State<_CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<_CategoryCard> {
  bool pressed = false;

  void _showFaqSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _FaqSheet(cat: widget.cat),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cat = widget.cat;
    return GestureDetector(
      onTapDown: (_) => setState(() => pressed = true),
      onTapUp: (_) => setState(() => pressed = false),
      onTapCancel: () => setState(() => pressed = false),
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => CategoryScreen(category: cat))),
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
                    width: 44, height: 44,
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.25), borderRadius: BorderRadius.circular(14)),
                    child: Icon(cat.icon, color: Colors.white, size: 22),
                  ),
                  if (cat.faqs.isNotEmpty)
                    GestureDetector(
                      onTap: () => _showFaqSheet(context),
                      child: Container(
                        width: 26, height: 26,
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                        child: Icon(Icons.info_outline, size: 14, color: Colors.white),
                      ),
                    ),
                ],
              ),
              Spacer(),
              Text(cat.name, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
              SizedBox(height: 4),
              Text(cat.description, style: TextStyle(fontSize: 12, color: Colors.white70, height: 1.3), maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    );
  }
}

class _FaqSheet extends StatefulWidget {
  final IssueCategory cat;
  _FaqSheet({required this.cat});
  @override
  State<_FaqSheet> createState() => _FaqSheetState();
}

class _FaqSheetState extends State<_FaqSheet> {
  int? expanded;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(gradient: AppGradients.background, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
          child: Column(
            children: [
              SizedBox(height: 12),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white38, borderRadius: BorderRadius.circular(999))),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                    child: Icon(widget.cat.icon, color: Colors.white, size: 20),
                  ),
                  SizedBox(width: 12),
                  Expanded(child: Text(widget.cat.name, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white))),
                ]),
              ),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                  itemCount: widget.cat.faqs.length,
                  itemBuilder: (context, i) {
                    final faq = widget.cat.faqs[i];
                    final isOpen = expanded == i;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: GlassContainer(
                        radius: 14,
                        opacity: 0.15,
                        padding: EdgeInsets.zero,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () => setState(() => expanded = isOpen ? null : i),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(children: [
                                    Expanded(child: Text(faq.question, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.white))),
                                    AnimatedRotation(
                                      turns: isOpen ? 0.5 : 0,
                                      duration: Duration(milliseconds: 200),
                                      child: Icon(Icons.expand_more, size: 20, color: Colors.white70),
                                    ),
                                  ]),
                                  AnimatedCrossFade(
                                    firstChild: SizedBox.shrink(),
                                    secondChild: Padding(
                                      padding: const EdgeInsets.only(top: 10),
                                      child: Text(faq.answer, style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.5)),
                                    ),
                                    crossFadeState: isOpen ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                                    duration: Duration(milliseconds: 200),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
