/// "Enter an address" picker for people who don't want to share GPS.
///
/// As the person types, matching addresses from the Census geocoder
/// (`location_service.dart`) appear as a tappable list; picking one saves its
/// coordinates right away. Pressing "Use this address" instead looks up
/// whatever was typed and uses the best match. Either way the location source
/// is marked "address" so the Home screen doesn't overwrite it with the device
/// GPS on the next launch. Used by Onboarding, Home ("Change area") and the
/// Resident hub.
///
/// The dialog is its own [StatefulWidget] so its text controller and debounce
/// timer are disposed by the framework only after the closing animation has
/// finished. (Disposing them right after `showDialog` returns crashed with
/// "TextEditingController was used after being disposed".)
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_client.dart';
import '../services/location_service.dart';

/// Wait this long after the last keystroke before looking up suggestions, so
/// the Census service gets one request per pause rather than one per letter.
const _suggestDelay = Duration(milliseconds: 700);

/// Suggestions are only looked up once the text is at least this long.
const _minCharsForSuggestions = 8;

/// Most suggestions shown under the text field.
const _maxSuggestions = 5;

/// Shows the address dialog. Returns true if a new location was saved.
Future<bool> promptForAddress(BuildContext context) async {
  final saved = await showDialog<bool>(
    context: context,
    builder: (_) => const _AddressDialog(),
  );
  return saved ?? false;
}

/// The dialog body: a text field, live suggestions and the action buttons.
class _AddressDialog extends StatefulWidget {
  const _AddressDialog();

  @override
  State<_AddressDialog> createState() => _AddressDialogState();
}

/// State for [_AddressDialog]: owns the text controller, debounce timer and suggestion list.
class _AddressDialogState extends State<_AddressDialog> {
  /// Holds the address text. Disposed in [dispose], i.e. after the dialog is gone.
  final TextEditingController _controller = TextEditingController();

  /// Waits for a pause in typing before asking for suggestions.
  Timer? _debounce;

  /// Bumped on every keystroke/submit so answers to older searches are ignored.
  int _requestId = 0;

  /// Matches currently shown under the text field.
  List<AddressMatch> _suggestions = [];

  /// True while a suggestion lookup is in flight (shows a small spinner).
  bool _searching = false;

  /// True while saving, so the buttons can't be pressed twice.
  bool _busy = false;

  /// Error text shown under the field, or null.
  String? _error;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  /// Saves the chosen coordinates and marks the location source as "address".
  Future<void> _save(AddressMatch match) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('lat', match.lat);
    await prefs.setDouble('lng', match.lng);
    await prefs.setString('location_source', 'address');
  }

  /// Called on every edit: waits for a pause, then looks up suggestions.
  void _onChanged(String text) {
    _debounce?.cancel();
    _requestId++;
    if (text.trim().length < _minCharsForSuggestions) {
      setState(() {
        _suggestions = [];
        _searching = false;
        _error = null;
      });
      return;
    }
    final thisRequest = _requestId;
    _debounce = Timer(_suggestDelay, () async {
      if (!mounted) return;
      setState(() {
        _searching = true;
        _error = null;
      });
      try {
        final found = await searchAddresses(text);
        if (!mounted || thisRequest != _requestId) return;
        setState(() {
          _suggestions = found.take(_maxSuggestions).toList();
          _searching = false;
        });
      } catch (_) {
        // Suggestions are a convenience; the person can still submit what they typed.
        if (!mounted || thisRequest != _requestId) return;
        setState(() {
          _suggestions = [];
          _searching = false;
        });
      }
    });
  }

  /// Uses a tapped suggestion.
  Future<void> _pick(AddressMatch match) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _save(match);
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = "Couldn't save that address. Please try again.";
      });
    }
  }

  /// Looks up whatever was typed (best match, with fallback) and uses it.
  Future<void> _submit() async {
    _debounce?.cancel();
    _requestId++;
    setState(() {
      _busy = true;
      _searching = false;
      _error = null;
    });
    try {
      await _save(await geocodeAddress(_controller.text));
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e is AppException ? e.toString() : "Couldn't look up that address. Please try again.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Enter your address'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _controller,
              autofocus: true,
              enabled: !_busy,
              textInputAction: TextInputAction.done,
              keyboardType: TextInputType.streetAddress,
              onChanged: _onChanged,
              onSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                hintText: '123 Main St, Towson, MD 21204',
                errorText: _error,
                errorMaxLines: 3,
                suffixIcon: _searching
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                      )
                    : null,
              ),
            ),
            if (_suggestions.isNotEmpty) ...[
              const SizedBox(height: 8),
              for (final match in _suggestions)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.place_outlined, size: 20),
                  title: Text(_prettyAddress(match.matched), style: const TextStyle(fontSize: 14)),
                  enabled: !_busy,
                  onTap: () => _pick(match),
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
          onPressed: _busy ? null : () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _busy ? null : _submit,
          child: _busy
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Use this address'),
        ),
      ],
    );
  }
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
