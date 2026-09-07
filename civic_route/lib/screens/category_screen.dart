import 'package:flutter/material.dart';
import '../models/issue.dart';
import '../theme.dart';
import 'results_screen.dart';

const Map<String, String> _levelLabel = {
  'federal_house': 'Federal', 'federal_senate': 'Federal', 'state': 'State', 'county': 'County',
};
const Map<String, Color> _levelColor = {
  'Federal': AppColors.federal, 'State': AppColors.state, 'County': AppColors.county,
};

class CategoryScreen extends StatefulWidget {
  final IssueCategory category;
  CategoryScreen({required this.category});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  bool infoOpen = false;

  @override
  Widget build(BuildContext context) {
    final cat = widget.category;
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: AppColors.brandPrimary,
            expandedHeight: 140,
            pinned: true,
            iconTheme: IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: EdgeInsets.only(left: 20, bottom: 16, right: 60),
              title: Text(cat.name, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [AppColors.brandPrimary, AppColors.brandSecondary], begin: Alignment.topLeft, end: Alignment.bottomRight),
                ),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 24, top: 10),
                    child: Icon(cat.icon, size: 56, color: Colors.white.withOpacity(0.18)),
                  ),
                ),
              ),
            ),
          ),
          if (cat.faqs.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              sliver: SliverToBoxAdapter(
                child: Container(
                  decoration: BoxDecoration(color: AppColors.accentSoft, borderRadius: BorderRadius.circular(16)),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => setState(() => infoOpen = !infoOpen),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Icon(Icons.info_outline, color: AppColors.accent, size: 18),
                              SizedBox(width: 8),
                              Expanded(child: Text('What qualifies as ${cat.name.toLowerCase()}?', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.accent))),
                              AnimatedRotation(
                                turns: infoOpen ? 0.5 : 0,
                                duration: Duration(milliseconds: 200),
                                child: Icon(Icons.expand_more, size: 20, color: AppColors.accent),
                              ),
                            ]),
                            AnimatedCrossFade(
                              firstChild: SizedBox.shrink(),
                              secondChild: Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: cat.faqs.map((f) => Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(f.question, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                        SizedBox(height: 3),
                                        Text(f.answer, style: TextStyle(color: AppColors.muted, fontSize: 13, height: 1.4)),
                                      ],
                                    ),
                                  )).toList(),
                                ),
                              ),
                              crossFadeState: infoOpen ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                              duration: Duration(milliseconds: 200),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            sliver: SliverToBoxAdapter(
              child: Text('Pick the sub-issue closest to your situation', style: TextStyle(color: AppColors.muted, fontSize: 14)),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, i) {
                final sub = cat.subIssues[i];
                final levels = sub.levels.map((l) => _levelLabel[l] ?? l).toSet().toList();
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.border),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: Offset(0, 4))],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ResultsScreen(issue: sub))),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(sub.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  SizedBox(height: 4),
                                  Text(sub.description, style: TextStyle(color: AppColors.muted, fontSize: 13, height: 1.3)),
                                  SizedBox(height: 10),
                                  Wrap(spacing: 6, children: levels.map((l) => Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(color: _levelColor[l] ?? AppColors.muted, borderRadius: BorderRadius.circular(999)),
                                    child: Text(l, style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                  )).toList()),
                                ],
                              ),
                            ),
                            SizedBox(width: 8),
                            Container(
                              width: 32, height: 32,
                              decoration: BoxDecoration(color: AppColors.surfaceTertiary, shape: BoxShape.circle),
                              child: Icon(Icons.chevron_right, color: AppColors.muted, size: 18),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }, childCount: cat.subIssues.length),
            ),
          ),
        ],
      ),
    );
  }
}
