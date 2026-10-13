/// Follow-up reminders for issues the user is working on.
///
/// When someone marks an issue "Contacted" or "Waiting for a response" on the
/// Results screen, `scheduleFollowUp` schedules one local notification a few
/// days later asking how it went. Tapping it opens that issue's Results screen
/// so the status can be updated. Moving an issue back to "Not started" or on to
/// "Resolved" cancels its reminder, and the "Issue reminders" switch in the
/// Resident hub turns all of this on or off.
///
/// Everything is local: no server, no account, and nothing leaves the device.
/// Notifications are only supported on Android and iOS; on other platforms
/// every method here quietly does nothing.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../data/issue_tree.dart';
import '../models/issue.dart';
import '../screens/results_screen.dart';

/// Static helpers for scheduling and cancelling issue follow-up notifications.
class ReminderService {
  ReminderService._();

  /// Lets a notification tap open a screen without a BuildContext.
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  /// How long after the user marks progress we ask again.
  static const Duration followUpDelay = Duration(days: 3);

  /// Statuses (from the Results screen) that should trigger a follow-up.
  static const Set<String> _statusesNeedingFollowUp = {
    'Contacted',
    'Waiting for a response',
  };

  static const _channelId = 'issue_followups';
  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  static bool _ready = false;

  static bool get _supported =>
      !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);

  /// Sets up notifications. Returns the issue id if the app was cold-started
  /// by tapping a reminder, so `main` can open that issue once the UI is up.
  static Future<String?> init() async {
    if (!_supported) return null;
    try {
      tz_data.initializeTimeZones();
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          // Permission is requested later, right after the user's first
          // "Contacted" tap, not at launch.
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
        onDidReceiveNotificationResponse: (response) => _openIssue(response.payload),
      );
      _ready = true;
      final launch = await _plugin.getNotificationAppLaunchDetails();
      if (launch?.didNotificationLaunchApp ?? false) {
        return launch?.notificationResponse?.payload;
      }
    } catch (e) {
      debugPrint('ReminderService.init failed: $e');
    }
    return null;
  }

  /// Asks the OS for permission to show notifications. True if allowed.
  static Future<bool> requestPermission() async {
    if (!_ready) return false;
    try {
      final ios = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
      if (ios != null) {
        return await ios.requestPermissions(alert: true, badge: true, sound: true) ?? false;
      }
      final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (android != null) {
        return await android.requestNotificationsPermission() ?? false;
      }
    } catch (e) {
      debugPrint('ReminderService.requestPermission failed: $e');
    }
    return false;
  }

  /// Schedules or cancels the follow-up for [issue] based on its new [status].
  /// Returns true only when a reminder was actually scheduled, so the caller
  /// can tell the user.
  static Future<bool> updateForStatus(Issue issue, String status) async {
    if (!_ready) return false;
    if (!_statusesNeedingFollowUp.contains(status)) {
      await cancelFollowUp(issue.id);
      return false;
    }
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool('reminders_enabled') ?? true)) return false;
    if (!await requestPermission()) return false;

    try {
      final when = tz.TZDateTime.now(tz.UTC).add(followUpDelay);
      await _plugin.zonedSchedule(
        id: _idFor(issue.id),
        title: 'Any update on ${issue.name}?',
        body: 'Tap to log how it went, or find who to contact again.',
        scheduledDate: when,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            'Issue follow-ups',
            channelDescription: 'Reminders to follow up on issues you contacted an office about',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        // Inexact so no special "exact alarm" permission is needed on Android.
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: issue.id,
      );
      return true;
    } catch (e) {
      debugPrint('ReminderService.updateForStatus failed: $e');
      return false;
    }
  }

  static Future<void> cancelFollowUp(String issueId) async {
    if (!_ready) return;
    try {
      await _plugin.cancel(id: _idFor(issueId));
    } catch (e) {
      debugPrint('ReminderService.cancelFollowUp failed: $e');
    }
  }

  static Future<void> cancelAll() async {
    if (!_ready) return;
    try {
      await _plugin.cancelAll();
    } catch (e) {
      debugPrint('ReminderService.cancelAll failed: $e');
    }
  }

  /// Opens the Results screen for the issue named in a notification payload.
  /// Safe to call before the UI exists; it just does nothing then.
  static void openIssueFromPayload(String? issueId) => _openIssue(issueId);

  static void _openIssue(String? issueId) {
    if (issueId == null) return;
    final issue = _findIssue(issueId);
    final nav = navigatorKey.currentState;
    if (issue == null || nav == null) return;
    nav.push(MaterialPageRoute(builder: (_) => ResultsScreen(issue: issue)));
  }

  static Issue? _findIssue(String id) {
    for (final category in issueTree) {
      for (final issue in category.subIssues) {
        if (issue.id == id) return issue;
      }
    }
    return null;
  }

  /// Stable positive 31-bit id from the issue id. (`String.hashCode` isn't
  /// guaranteed to be the same between app launches, so it can't be used.)
  static int _idFor(String issueId) {
    var hash = 0x811C9DC5;
    for (final unit in issueId.codeUnits) {
      hash = ((hash ^ unit) * 0x01000193) & 0x7FFFFFFF;
    }
    return hash;
  }
}
