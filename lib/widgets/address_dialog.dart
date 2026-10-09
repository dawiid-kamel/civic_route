/// "Enter an address" dialog for people who don't want to share GPS.
///
/// Looks the address up with the Census geocoder (`location_service.dart`),
/// saves the coordinates and marks the location source as "address" so the
/// Home screen doesn't overwrite it with the device GPS on the next launch.
/// Used by Onboarding, Home ("Change area") and the Resident hub.
library;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_client.dart';
import '../services/location_service.dart';

/// Returns true if a new location was saved.
Future<bool> promptForAddress(BuildContext context) async {
  final controller = TextEditingController();
  String? error;
  var busy = false;

  final saved = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) {
        Future<void> submit() async {
          setState(() {
            busy = true;
            error = null;
          });
          try {
            final result = await geocodeAddress(controller.text);
            final prefs = await SharedPreferences.getInstance();
            await prefs.setDouble('lat', result.lat);
            await prefs.setDouble('lng', result.lng);
            await prefs.setString('location_source', 'address');
            if (ctx.mounted) Navigator.pop(ctx, true);
          } catch (e) {
            setState(() {
              busy = false;
              error = e is AppException ? e.toString() : "Couldn't look up that address. Please try again.";
            });
          }
        }

        return AlertDialog(
          title: const Text('Enter your address'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: controller,
                autofocus: true,
                enabled: !busy,
                textInputAction: TextInputAction.done,
                keyboardType: TextInputType.streetAddress,
                onSubmitted: (_) => submit(),
                decoration: InputDecoration(
                  hintText: '123 Main St, Towson, MD 21204',
                  errorText: error,
                  errorMaxLines: 3,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Used only to find your county and districts. The address is sent to the '
                'U.S. Census Bureau\'s lookup service; only the resulting coordinates are saved on this device.',
                style: TextStyle(fontSize: 12, height: 1.4),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: busy ? null : () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: busy ? null : submit,
              child: busy
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Use this address'),
            ),
          ],
        );
      },
    ),
  );
  controller.dispose();
  return saved ?? false;
}
