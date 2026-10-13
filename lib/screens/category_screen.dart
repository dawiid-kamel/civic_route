/// Detail page for one issue category.
///
/// Shows one consistent "About" card for the category (what it covers, who
/// handles it at each level of government, and what to have ready), followed
/// by its sub-issues. Tapping a sub-issue opens `ResultsScreen`. Opened from
/// the Home grid and from the saved-topics list.
library;

import 'package:flutter/material.dart';
import '../models/issue.dart';
import '../theme.dart';
import 'results_screen.dart';

/// Maps each government level key from the data to the label shown on its badge.
/// Both federal chambers share the single "Federal" label.
const Map<String, String> _levelLabel = {
  'federal_house': 'Federal', 'federal_senate': 'Federal', 'state': 'State', 'county': 'County',
};

/// Screen that shows one [IssueCategory]: its guide card and a list of sub-issues.
class CategoryScreen extends StatefulWidget {
  /// The category being displayed.
  final IssueCategory category;
  /// Creates the screen for [category].
  CategoryScreen({required this.category});

  /// Creates the state object for this screen.
  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

/// State for [CategoryScreen]; it holds no mutable data, only builds the UI.
class _CategoryScreenState extends State<CategoryScreen> {
  /// Builds the scrolling page: a navy app bar, the guide card, then one tappable
  /// card per sub-issue that opens [ResultsScreen].
  @override
  Widget build(BuildContext context) {
    final cat = widget.category;
    final colors = AppColors.of(context);
    // Badge color for each level label; unknown labels fall back to muted gray.
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
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            sliver: SliverToBoxAdapter(child: _GuideCard(guide: cat.guide, colors: colors)),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            sliver: SliverToBoxAdapter(
              child: Text('Choose the topic closest to your situation', style: TextStyle(color: colors.textPrimary, fontSize: 15, fontWeight: FontWeight.w800)),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, i) {
                final sub = cat.subIssues[i];
                // Turn level keys into unique display labels (so two federal keys show one badge).
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

/// The same four-part explanation for every category, so they all read alike:
/// what it covers, who handles it (Federal / State / County, always in that
/// order), and what to have ready before you contact an office.
class _GuideCard extends StatelessWidget {
  /// The category's explanation content (what it covers, who handles it, what to prepare).
  final CategoryGuide guide;
  /// Palette to draw with, passed in so the card matches the current theme.
  final AppColors colors;
  /// Creates the card for [guide] using [colors].
  const _GuideCard({required this.guide, required this.colors});

  /// Builds the tinted card with its three sections.
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.accentSoft,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _heading('What it covers'),
          SizedBox(height: 6),
          Text(guide.covers, style: _body()),
          SizedBox(height: 16),
          _heading('Who handles it'),
          SizedBox(height: 8),
          _levelRow('Federal', guide.federal, colors.federal),
          _levelRow('State', guide.state, colors.state),
          _levelRow('County', guide.county, colors.county),
          SizedBox(height: 8),
          _heading('Have ready before you call'),
          SizedBox(height: 6),
          Text(guide.prepare, style: _body()),
        ],
      ),
    );
  }

  /// Small accent-colored section title inside the card.
  Widget _heading(String text) => Text(
        text,
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: colors.accent),
      );

  /// Shared text style for the card's paragraphs.
  TextStyle _body() => TextStyle(fontSize: 14, color: colors.textPrimary, height: 1.45);

  /// One Federal/State/County row: a colored pill plus the description, or a
  /// grayed-out "Not usually involved." when [text] is null.
  Widget _levelRow(String label, String? text, Color color) {
    final involved = text != null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 64,
            margin: const EdgeInsets.only(top: 1),
            padding: const EdgeInsets.symmetric(vertical: 3),
            decoration: BoxDecoration(
              color: involved ? color : colors.surfaceTertiary,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(color: involved ? Colors.white : colors.muted, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              text ?? 'Not usually involved.',
              style: involved ? _body() : _body().copyWith(color: colors.muted),
            ),
          ),
        ],
      ),
    );
  }
}
