/// Opens phone, email and web links, and tells the user when that fails.
///
/// `url_launcher` quietly returns false on devices with no dialer or mail app
/// (tablets, simulators); `openLink` turns that into a snackbar instead of a
/// button that appears to do nothing. Used by the Results and Resident hub
/// screens for their call / website / email buttons.
library;

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> openLink(BuildContext context, Uri uri) async {
  var ok = false;
  try {
    ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    ok = false;
  }
  if (!ok && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Couldn't open that on this device.")),
    );
  }
}

Uri phoneUri(String phone) => Uri.parse('tel:${phone.replaceAll(RegExp(r'[^\d+]'), '')}');
