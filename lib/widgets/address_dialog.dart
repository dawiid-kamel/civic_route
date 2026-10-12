/// "Enter an address" picker for people who don't want to share GPS.
///
/// As the person types, matching addresses from the Census geocoder
/// (`location_service.dart`) appear as a tappable list; picking one saves its
/// coordinates right away. Pressing "Use this address" instead looks up
/// whatever was typed and uses the best match. Either way the location source
/// is marked "address" so the Home screen doesn't overwrite it with the device
/// GPS on the next launch. Used by Onboarding, Home ("Change area") and the
/// Resident hub.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_client.dart';
import '../services/location_service.dart';

/// Wait this long after the last keystroke before looking up suggestions, so
/// the Census service gets one request per pause rather than one per letter.
const _suggestDelay = Duration(milliseconds: 700);
const _minCharsForSuggestions = 8;
const _maxSuggestions = 5;

/// Returns true if a new location was saved.
Future<bool> promptForAddress(BuildContext context) async {
  final controller = TextEditingController();
  Timer? debounce;
  var requestId = 0; // ignore answers that arrive after a newer search started
  var suggestions = <AddressMatch>[];
  var searching = false;
  String? error;
  var busy = false;

  Future<void> save(AddressMatch match) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('lat', match.lat);
    await prefs.setDouble('lng', match.lng);
    await prefs.setString('location_source', 'address');
  }

  final saved = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) {
        void onChanged(String text) {
          debounce?.cancel();
          requestId++;
          if (text.trim().length < _minCharsForSuggestions) {
            setState(() {
              suggestions = [];
              searching = false;
              error = null;
            });
            return;
          }
          final thisRequest = requestId;
          debounce = Timer(_suggestDelay, () async {
            if (!ctx.mounted) return;
            setState(() {
              searching = true;
              error = null;
            });
            try {
              final found = await searchAddresses(text);
              if (!ctx.mounted || thisRequest != requestId) return;
              setState(() {
                suggestions = found.take(_maxSuggestions).toList();
                searching = false;
              });
            } catch (_) {
              // Suggestions are a convenience; the person can still submit what they typed.
              if (!ctx.mounted || thisRequest != requestId) return;
              setState(() {
                suggestions = [];
                searching = false;
              });
            }
          });
        }

        Future<void> pick(AddressMatch match) async {
          setState(() {
            busy = true;
            error = null;
          });
          try {
            await save(match);
            if (ctx.mounted) Navigator.pop(ctx, true);
          } catch (_) {
            if (!ctx.mounted) return;
            setState(() {
              busy = false;
              error = "Couldn't save that address. Please try again.";
            });
          }
        }

        Future<void> submit() async {
          debounce?.cancel();
          requestId++;
          setState(() {
            busy = true;
            searching = false;
            error = null;
          });
          try {
            await save(await geocodeAddress(controller.text));
            if (ctx.mounted) Navigator.pop(ctx, true);
          } catch (e) {
            if (!ctx.mounted) return;
            setState(() {
              busy = false;
              error = e is AppException ? e.toString() : "Couldn't look up that address. Please try again.";
            });
          }
        }

        return AlertDialog(
          title: const Text('Enter your address'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: controller,
                  autofocus: true,
                  enabled: !busy,
                  textInputAction: TextInputAction.done,
                  keyboardType: TextInputType.streetAddress,
                  onChanged: onChanged,
                  onSubmitted: (_) => submit(),
                  decoration: InputDecoration(
                    hintText: '123 Main St, Towson, MD 21204',
                    errorText: error,
                    errorMaxLines: 3,
                    suffixIcon: searching
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                          )
                        : null,
                  ),
                ),
                if (suggestions.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  for (final match in suggestions)
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.place_outlined, size: 20),
                      title: Text(_prettyAddress(match.matched), style: const TextStyle(fontSize: 14)),
                      enabled: !busy,
                      onTap: () => pick(match),
                    ),
                ],
                const SizedBox(height: 12),
                const Text(
                  'Used only to find your county and districts. As you type, the address is sent to the '
                  'U.S. Census Bureau\'s lookup service; only the resulting coordinates are saved on this device.',
                  style: TextStyle(fontSize: 12, height: 1.4),
                ),
              ],
            ),
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
  debounce?.cancel();
  controller.dispose();
  return saved ?? false;
}

/// The Census service returns addresses in capitals ("123 MAIN ST, TOWSON, MD,
/// 21204"); show them in normal capitalization, keeping the state abbreviation.
String _prettyAddress(String raw) {
  return raw.split(', ').map((part) {
    if (part.length == 2 && RegExp(r'^[A-Za-z]{2}$').hasMatch(part)) return part.toUpperCase();
    return part
        .split(' ')
        .map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1).toLowerCase())
        .join(' ');
  }).join(', ');
}
