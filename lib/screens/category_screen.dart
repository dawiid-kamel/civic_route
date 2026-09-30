import 'package:flutter/material.dart';
import '../../models/issue.dart';
import '../../theme.dart';
import 'results_screen.dart';

const Map<String, String> _levelLabel = {
  'federal_house': 'Federal', 'federal_senate': 'Federal', 'state': 'State', 'county': 'County',
};

class CategoryScreen extends StatefulWidget {
  final IssueCategory category;
  final bool startWithInfoOpen;
  CategoryScreen({required this.category, this.startWithInfoOpen = false});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  late bool infoOpen = widget.startWithInfoOpen;

  @override
  Widget build(BuildContext context) {
    final cat = widget.category;
    final colors = AppColors.of(context);
    final levelColorFor = {
      'Federal': colors.federal,
      'State': colors.state,
      'County': colors.county,
    };
    return Scaffold(
      backgroundColor: colors.surface,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: AppColors.light.brandPrimary,
            expandedHeight: 140,
            pinned: true,
            iconTheme: IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: EdgeInsets.only(left: 20, bottom: 16, right: 60),
              title: Text(cat.name, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Colors.white)),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [AppColors.light.brandPrimary, AppColors.light.brandSecondary], begin: Alignment.topLeft, end: Alignment.bottomRight),
                ),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 24, top: 10),
                    child: Icon(cat.icon, size: 56, color: Colors.white.withValues(alpha: 0.18)),
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
                  decoration: BoxDecoration(color: colors.accentSoft, borderRadius: BorderRadius.circular(16)),
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
                              Icon(Icons.info_outline, color: colors.accent, size: 18),
                              SizedBox(width: 8),
                              Expanded(child: Text('What qualifies as ${cat.name.toLowerCase()}?', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: colors.accent))),
                              AnimatedRotation(
                                turns: infoOpen ? 0.5 : 0,
                                duration: Duration(milliseconds: 200),
                                child: Icon(Icons.expand_more, size: 20, color: colors.accent),
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
                                        Text(f.question, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: colors.textPrimary)),
                                        SizedBox(height: 3),
                                        Text(f.answer, style: TextStyle(color: colors.muted, fontSize: 13, height: 1.4)),
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
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            sliver: SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colors.surfaceSecondary,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: colors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Icon(Icons.help_outline, color: colors.accent, size: 18),
                      SizedBox(width: 8),
                      Expanded(child: Text('What this usually involves', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: colors.accent))),
                    ]),
                    SizedBox(height: 12),
                    Text('This issue usually falls under ${cat.subIssues.map((e) => e.levels).expand((x) => x).toSet().map((level) => level.contains('federal') ? 'federal' : level == 'state' ? 'state' : 'county').join(', ')} offices.', style: TextStyle(fontSize: 13, color: colors.textPrimary, height: 1.5)),
                    SizedBox(height: 10),
                    _bullet('Who is responsible?', 'A city, county, state, or federal office depending on the issue type.', colors),
                    _bullet('What to prepare?', 'Dates, addresses, photos, and any account or case numbers you already have.', colors),
                    _bullet('What happens next?', 'Identify the right office, contact them, and follow up with any requested documents.', colors),
                  ],
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            sliver: SliverToBoxAdapter(
              child: Text('Pick the sub-issue closest to your situation', style: TextStyle(color: colors.muted, fontSize: 14)),
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
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: colors.border),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: Offset(0, 4))],
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
                                  Text(sub.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: colors.textPrimary)),
                                  SizedBox(height: 4),
                                  Text(sub.description, style: TextStyle(color: colors.muted, fontSize: 13, height: 1.3)),
                                  SizedBox(height: 10),
                                  Wrap(spacing: 6, children: levels.map((l) => Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(color: levelColorFor[l] ?? colors.muted, borderRadius: BorderRadius.circular(999)),
                                    child: Text(l, style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                  )).toList()),
                                ],
                              ),
                            ),
                            SizedBox(width: 8),
                            Container(
                              width: 32, height: 32,
                              decoration: BoxDecoration(color: colors.surfaceTertiary, shape: BoxShape.circle),
                              child: Icon(Icons.chevron_right, color: colors.muted, size: 18),
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

Widget _bullet(String title, String description, AppColors colors) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 4),
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: colors.accent, shape: BoxShape.circle),
        ),
        SizedBox(width: 10),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: TextStyle(fontSize: 13, color: colors.muted, height: 1.5),
              children: [
                TextSpan(text: '$title ', style: TextStyle(fontWeight: FontWeight.w700, color: colors.textPrimary)),
                TextSpan(text: description),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
