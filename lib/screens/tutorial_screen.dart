/// First-launch walkthrough (three swipeable pages).
///
/// Shown once; finishing or skipping saves `tutorial_seen` and moves on to
/// `OnboardingScreen`. `main.dart` decides whether to show this screen.
library;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme.dart';
import 'onboarding_screen.dart';

/// The first-launch walkthrough screen with swipeable pages.
class TutorialScreen extends StatefulWidget {
  /// Creates the state object for this screen.
  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

/// Content for one walkthrough page: an icon, a headline and a short blurb.
class _TutorialPage {
  /// Icon shown above the text.
  final IconData icon;
  /// Headline for the page.
  final String title;
  /// Short explanation under the headline.
  final String body;
  /// Creates a page with the given [icon], [title] and [body].
  _TutorialPage({required this.icon, required this.title, required this.body});
}

/// State for [TutorialScreen]; tracks which page is showing.
class _TutorialScreenState extends State<TutorialScreen> {
  /// Drives the page swipes and the "Next" button's animation.
  final controller = PageController();
  /// Index of the page currently on screen, used for the dots and button label.
  int page = 0;

  /// Releases the page controller when the screen goes away.
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  /// Builds the Skip button, the swipeable pages, the progress dots and the Next/Get started button.
  @override
  Widget build(BuildContext context) {
    // The three walkthrough pages, in order.
    final steps = [
      _TutorialPage(icon: Icons.category_outlined, title: "Pick your issue", body: "Choose from categories like Housing, Transportation, or Healthcare — whatever you need help with."),
      _TutorialPage(icon: Icons.account_tree_outlined, title: "We find the right level", body: "Not every issue goes to Congress. We figure out whether it's a federal, state, or county matter."),
      _TutorialPage(icon: Icons.call_outlined, title: "Contact them directly", body: "Get the real name, phone number, and website — tap to call or visit, right from the app."),
    ];

    return Scaffold(
      backgroundColor: AppColors.light.brandPrimary,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _finish,
                child: Text('Skip', style: TextStyle(color: Colors.white70)),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: controller,
                onPageChanged: (i) => setState(() => page = i),
                itemCount: steps.length,
                itemBuilder: (context, i) {
                  final step = steps[i];
                  return Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 96, height: 96,
                          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.12), shape: BoxShape.circle),
                          child: Icon(step.icon, color: AppColors.light.accent, size: 44),
                        ),
                        SizedBox(height: 32),
                        Text(step.title, textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800)),
                        SizedBox(height: 12),
                        Text(step.body, textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontSize: 16, height: 1.5)),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              // One dot per page; the current page gets a longer, accent-colored dot.
              children: List.generate(steps.length, (i) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: page == i ? 20 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: page == i ? AppColors.light.accent : Colors.white24,
                  borderRadius: BorderRadius.circular(4),
                ),
              )),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: ElevatedButton(
                onPressed: () {
                  // Not on the last page yet: slide to the next one; otherwise finish.
                  if (page < steps.length - 1) {
                    controller.nextPage(duration: Duration(milliseconds: 300), curve: Curves.easeOut);
                  } else {
                    _finish();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.light.accent,
                  minimumSize: Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(page < steps.length - 1 ? 'Next' : 'Get started', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Remembers the tutorial was seen, then replaces this screen with [OnboardingScreen].
  void _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('tutorial_seen', true);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => OnboardingScreen()));
  }
}
