import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/device_location_service.dart';
import '../../theme.dart';
import 'home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  bool busy = false;

  Future<void> useLocation() async {
    setState(() => busy = true);
    try {
      final pos = await getDeviceLocation();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('lat', pos.latitude);
      await prefs.setDouble('lng', pos.longitude);
      await prefs.setBool('onboarded', true);
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => HomeScreen()));
    } catch (e) {
      setState(() => busy = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _skip() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarded', true);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => HomeScreen()));
  }

  @override
  Widget build(BuildContext context) {
    // The hero header is a fixed brand-navy backdrop by design (same as
    // Home/Tutorial) — it should look the same regardless of system theme.
    final brand = AppColors.light;
    // The bottom panel is a real content surface, so it follows system
    // light/dark like Category, Results, and Resident hub do.
    final colors = AppColors.of(context);

    return Scaffold(
      backgroundColor: brand.brandPrimary,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
                      child: Icon(Icons.location_on, color: brand.accent, size: 20),
                    ),
                    SizedBox(width: 10),
                    Text('CivicRoute', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    Spacer(),
                    TextButton(
                      onPressed: busy ? null : _skip,
                      child: Text('Skip', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
                    ),
                  ]),
                  SizedBox(height: 24),
                  Text('Who do you actually call?', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800, height: 1.2)),
                  SizedBox(height: 12),
                  Text('Figure out the exact person in government responsible for your issue — federal, state, or county.',
                      style: TextStyle(color: Colors.white70, fontSize: 16, height: 1.5)),
                ],
              ),
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: colors.surface, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _point(Icons.navigation, "We use your location to find your actual representatives.", colors),
                    SizedBox(height: 16),
                    _point(Icons.lock_outline, "Nothing is stored or shared — it stays on your device.", colors),
                    SizedBox(height: 16),
                    _point(Icons.flash_on, "No account, no ads. Straight to the phone number.", colors),
                    Spacer(),
                    ElevatedButton(
                      onPressed: busy ? null : useLocation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.accent,
                        minimumSize: Size(double.infinity, 56),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: busy
                          ? CircularProgressIndicator(color: Colors.white)
                          : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                              Icon(Icons.location_on, color: Colors.white, size: 18),
                              SizedBox(width: 8),
                              Text('Use my location', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
                            ]),
                    ),
                    SizedBox(height: 8),
                    // Denying/skipping location used to leave you stuck on
                    // this screen forever with no way forward — `onboarded`
                    // was only ever set inside the success path above.
                    TextButton(
                      onPressed: busy ? null : _skip,
                      child: Text("I'll do this later", style: TextStyle(color: colors.muted, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _point(IconData icon, String text, AppColors colors) {
    return Row(children: [
      Container(
        width: 36, height: 36,
        decoration: BoxDecoration(color: colors.accentSoft, shape: BoxShape.circle),
        child: Icon(icon, color: colors.accent, size: 16),
      ),
      SizedBox(width: 12),
      Expanded(child: Text(text, style: TextStyle(fontSize: 15, height: 1.4, color: colors.textPrimary))),
    ]);
  }
}
