import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../data/issue_tree.dart';
import '../services/resolver_service.dart';
import '../models/contact.dart';

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Contact> results = [];
  bool loading = false;
  String? error;

  Future<Position> _getDevicePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) throw Exception('Location services are disabled.');

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permission denied.');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permission permanently denied.');
    }
    return await Geolocator.getCurrentPosition();
  }

  Future<void> pickIssue(String level) async {
    setState(() { loading = true; error = null; results = []; });
    try {
      final pos = await _getDevicePosition();
      final loc = await getCachedLocation(pos.latitude, pos.longitude);
      final contacts = await getContactsForIssue(level, loc);
      setState(() { results = contacts; loading = false; });
    } catch (e) {
      setState(() { error = e.toString(); loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('CivicRoute')),
      body: ListView(
        children: [
          for (var cat in issueTree)
            ExpansionTile(title: Text(cat.name), children: [
              for (var issue in cat.subIssues)
                ListTile(title: Text(issue.name), onTap: () => pickIssue(issue.levels.first))
            ]),
          if (loading) Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()),
          if (error != null) Padding(padding: EdgeInsets.all(16), child: Text('Error: $error', style: TextStyle(color: Colors.red))),
          if (results.isNotEmpty) Padding(padding: EdgeInsets.all(8), child: Text('Results:', style: TextStyle(fontWeight: FontWeight.bold))),
          for (var c in results) ListTile(title: Text(c.name), subtitle: Text('${c.office}\n${c.phone ?? ''}'), isThreeLine: true),
        ],
      ),
    );
  }
}
