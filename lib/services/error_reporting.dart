/// Single place that receives every unexpected error.
///
/// `main.dart` routes Flutter and async errors here. Today it only logs; to
/// hear about crashes from real users, initialise Sentry or Firebase
/// Crashlytics in `main.dart` and forward the call below (instructions in
/// docs/RELEASE.md).
library;

import 'package:flutter/foundation.dart';

/// Records an unexpected [error] (with its [stack], if known). For now this
/// just logs it to the debug console.
void reportError(Object error, StackTrace? stack) {
  debugPrint('Unhandled error: $error\n${stack ?? ''}');
  // TODO(release): forward to Sentry.captureException(error, stackTrace: stack)
  // or FirebaseCrashlytics.instance.recordError(error, stack).
}
