import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/issue.dart';
import '../services/device_location_service.dart';
import '../models/contact.dart';
import '../services/resolver_service.dart';
import '../theme.dart';

class ResultsScreen extends StatefulWidget {
  final Issue issue;
  ResultsScreen({required this.issue});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  List<Contact> results = [];
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      var lat = prefs.getDouble('lat');
      var lng = prefs.getDouble('lng');
      if (lat == null || lng == null) {
        final pos = await getDeviceLocation();
        lat = pos.latitude;
        lng = pos.longitude;
        await prefs.setDouble('lat', lat);
        await prefs.setDouble('lng', lng);
      }
      final loc = await getCachedLocation(lat, lng);
      List<Contact> all = [];
      for (final level in widget.issue.levels) {
        all.addAll(await getContactsForIssue(level, loc));
      }
      if (mounted) setState(() { results = all; loading = false; });
    } catch (e) {
      if (mounted) setState(() { error = e.toString(); loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
        title: Text(widget.issue.name, style: TextStyle(color: Colors.black, fontWeight: FontWeight.w800)),
      ),
      body: loading
          ? _loadingPin()
          : error != null
              ? Padding(padding: const EdgeInsets.all(20), child: Text('Error: $error', style: TextStyle(color: AppColors.error)))
              : ListView(
                  padding: const EdgeInsets.all(20),
                  children: results.map((c) => _contactCard(c)).toList(),
                ),
    );
  }

  Widget _loadingPin() {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 64, height: 64,
          decoration: BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
          child: Icon(Icons.location_on, color: Colors.white, size: 26),
        ),
        SizedBox(height: 16),
        Text('Resolving jurisdiction…', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        Text('Finding the exact office responsible.', style: TextStyle(color: AppColors.muted)),
      ]),
    );
  }

  Widget _contactCard(Contact c) {
    final levelColor = c.level == 'federal' ? AppColors.federal : c.level == 'state' ? AppColors.state : AppColors.county;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(c.name, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
              Text(c.office, style: TextStyle(fontSize: 13, color: AppColors.muted)),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: levelColor, borderRadius: BorderRadius.circular(999)),
              child: Text(c.level[0].toUpperCase() + c.level.substring(1), style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
            ),
          ]),
          SizedBox(height: 14),
          Wrap(spacing: 8, runSpacing: 8, children: [
            if (c.phone != null) ElevatedButton.icon(
              onPressed: () => launchUrl(Uri.parse('tel:${c.phone!.replaceAll(RegExp(r'[^\d+]'), '')}')),
              icon: Icon(Icons.call, size: 16, color: Colors.white),
              label: Text(c.phone!, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
            ),
            if (c.website != null) OutlinedButton.icon(
              onPressed: () => launchUrl(Uri.parse(c.website!)),
              icon: Icon(Icons.language, size: 16),
              label: Text('Website', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ]),
        ],
      ),
    );
  }
}
