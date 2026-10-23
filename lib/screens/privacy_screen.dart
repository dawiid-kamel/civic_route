/// In-app privacy policy.
///
/// The text lives inside the app so it always opens (no website, no network)
/// and matches what this version of the app does. `docs/privacy.html` carries
/// the same policy for the app stores' "privacy policy URL" field; keep the two
/// in sync when either changes. Opened from the "About" card in the Resident hub.
library;

import 'package:flutter/material.dart';

import '../config.dart';
import '../theme.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  static const String lastUpdated = 'October 21, 2026';

  static const List<({String heading, List<String> paragraphs})> _sections = [
    (
      heading: 'What the app uses',
      paragraphs: [
        'Your location: your device\'s location (only after you tap "Use my location" and allow the permission) or, if address entry is turned on, a street address you type. It is used to work out your county, state and congressional district.',
        'Choices you make in the app, such as saved topics, starred officials and progress notes. These are stored only on your device.',
        'Follow-up reminders: if you mark an issue as contacted or waiting and allow notifications, the app schedules a reminder on your device a few days later. Reminders are created and shown locally; nothing about them is sent to anyone. You can turn them off with the "Issue reminders" switch in the Resident hub or in your device\'s notification settings.',
      ],
    ),
    (
      heading: 'Where your information goes',
      paragraphs: [
        'U.S. Census Bureau geocoder: receives your coordinates (or a typed address, including while you type it so the app can suggest matches) to return your county and congressional district.',
        'OpenStreetMap Nominatim: receives a typed address only if the Census geocoder can\'t find it or can\'t be reached. Nothing else is sent.',
        'Open States: receives your approximate coordinates (rounded to about 100 meters) directly from your device to find your state legislators.',
        'Congress.gov: receives only your state and congressional district, not your location, to find your federal officials.',
        'GitHub: when the app starts, it downloads a public file of county contact information from GitHub (raw.githubusercontent.com). No location or personal information is sent with that request.',
        'Like any website, these services (including GitHub) can see your device\'s IP address. Civic Route runs no server of its own and does not receive or store any of this. Nothing is sold, shared for advertising, or used to track you across apps or sites.',
      ],
    ),
    (
      heading: 'What stays on your device',
      paragraphs: [
        'Your coordinates, your last resolved county and district, saved topics, progress notes, and the last list of officials shown (so the app works offline). You can remove all of it at any time with "Clear saved data" in the Resident hub, by clearing the app\'s data, or by uninstalling the app.',
      ],
    ),
    (
      heading: 'What we do not collect',
      paragraphs: [
        'We do not collect your name, email, phone number, contacts, photos, or advertising identifiers, and the app has no accounts. The app does not currently include analytics or crash-reporting services. If that changes, this policy will be updated first.',
      ],
    ),
    (
      heading: 'Contact information shown in the app',
      paragraphs: [
        'Phone numbers and websites come from public government sources and may be out of date. Please confirm with the office before relying on them.',
      ],
    ),
    (
      heading: 'Children',
      paragraphs: [
        'Civic Route is not directed at children under 13 and does not knowingly collect personal information from them.',
      ],
    ),
    (
      heading: 'Changes',
      paragraphs: [
        'If this policy changes, the date above will be updated.',
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        backgroundColor: colors.surface,
        foregroundColor: colors.textPrimary,
        title: const Text('Privacy policy'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text(
            'Last updated: $lastUpdated',
            style: TextStyle(color: colors.muted, fontSize: 12),
          ),
          const SizedBox(height: 12),
          Text(
            'Civic Route helps you find the government office to contact about an issue. '
            'In short: there are no accounts, no ads and no tracking, and your location is '
            'used only to look up your officials.',
            style: TextStyle(color: colors.textPrimary, fontSize: 15, height: 1.5),
          ),
          for (final section in _sections) ...[
            const SizedBox(height: 22),
            Text(
              section.heading,
              style: TextStyle(color: colors.textPrimary, fontSize: 17, fontWeight: FontWeight.w800),
            ),
            for (final paragraph in section.paragraphs) ...[
              const SizedBox(height: 8),
              Text(
                paragraph,
                style: TextStyle(color: colors.textPrimary, fontSize: 14, height: 1.5),
              ),
            ],
          ],
          if (AppConfig.supportEmail.isNotEmpty) ...[
            const SizedBox(height: 22),
            Text(
              'Contact',
              style: TextStyle(color: colors.textPrimary, fontSize: 17, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            SelectableText(
              'Questions: ${AppConfig.supportEmail}',
              style: TextStyle(color: colors.textPrimary, fontSize: 14, height: 1.5),
            ),
          ],
        ],
      ),
    );
  }
}