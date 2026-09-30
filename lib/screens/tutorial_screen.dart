import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme.dart';
import 'onboarding_screen.dart';

class TutorialScreen extends StatefulWidget {
  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialPage {
  final IconData icon;
  final String title;
  final String body;
  _TutorialPage({required this.icon, required this.title, required this.body});
}

class _TutorialScreenState extends State<TutorialScreen> {
  final controller = PageController();
  int page = 0;

  @override
  Widget build(BuildContext context) {
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

  void _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('tutorial_seen', true);
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => OnboardingScreen()));
  }
}
