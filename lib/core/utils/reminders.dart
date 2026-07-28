import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:intl/intl.dart';
import 'package:itemize/core/utils/maintenance_planner.dart';
import 'package:itemize/data/models/asset.dart';
import 'package:itemize/data/models/maintenance_schedule.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// How far ahead of a warranty expiring the owner is told.
///
/// Thirty days is enough to book a repair, seven to chase one that has stalled,
/// one to use the cover before it lapses.
const List<int> kReminderLeadDays = [30, 7, 1];

/// How far ahead of a maintenance job falling due the owner is told.
///
/// A week to arrange it, and again on the day. Shorter than the warranty leads
/// because a filter change is arranged in an afternoon, not a month.
const List<int> kMaintenanceLeadDays = [7, 0];

/// The hour reminders arrive, in the device's own timezone.
///
/// Mid-morning: late enough not to wake anyone, early enough to leave the day
/// free for doing something about it.
const int kReminderHour = 10;

/// Schedules everything the app has to say between being filled in and being
/// needed.
///
/// Two kinds, and they are the whole reason the app is worth opening again:
/// a warranty running out, and a job falling due. Both were facts already sitting
/// in the database that nothing ever mentioned.
class Reminders {
  Reminders._();

  static final Reminders instance = Reminders._();

  /// iOS keeps at most 64 pending local notifications per app and silently
  /// drops the rest, so the schedule is capped below that and filled with the
  /// soonest reminders. [sync] runs on every reload, which walks the window
  /// forward as time passes and items change.
  static const int _maxPending = 60;

  static const AndroidNotificationDetails _androidDetails =
      AndroidNotificationDetails(
        'warranty_reminders',
        'Item reminders',
        channelDescription:
            'Tells you before a warranty runs out or a job falls due.',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      );

  static const NotificationDetails _details = NotificationDetails(
    android: _androidDetails,
    iOS: DarwinNotificationDetails(),
  );

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _ready = false;

  /// True once the platform has been asked and has not said no.
  ///
  /// Scheduling against a refused permission is not an error on either
  /// platform, it simply does nothing, so this only exists to tell the settings
  /// screen whether to explain itself.
  bool _permitted = false;

  bool get isPermitted => _permitted;

  /// Prepares the plugin and the timezone database. Safe to call more than once.
  ///
  /// Failure here is swallowed: a device that will not give up its timezone is
  /// a reason to go without reminders, not a reason the app should refuse to
  /// start.
  Future<void> init({void Function(String assetId)? onTapAsset}) async {
    if (_ready) return;
    try {
      tzdata.initializeTimeZones();
      final localZone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(localZone.identifier));

      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          // Asked for separately, when reminders are actually switched on,
          // rather than thrown at someone during their first launch.
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
        onDidReceiveNotificationResponse: (response) {
          final payload = response.payload;
          if (payload != null && payload.isNotEmpty) onTapAsset?.call(payload);
        },
      );
      _ready = true;
    } catch (e) {
      if (kDebugMode) print('Warranty reminders unavailable: $e');
    }
  }

  /// Asks for permission to post notifications, returning whether it was given.
  Future<bool> requestPermission() async {
    if (!_ready) return false;
    try {
      if (Platform.isIOS) {
        _permitted =
            await _plugin
                .resolvePlatformSpecificImplementation<
                  IOSFlutterLocalNotificationsPlugin
                >()
                ?.requestPermissions(alert: true, badge: true, sound: true) ??
            false;
      } else if (Platform.isAndroid) {
        // Only Android 13 and up prompts; older versions return true outright.
        _permitted =
            await _plugin
                .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin
                >()
                ?.requestNotificationsPermission() ??
            false;
      }
    } catch (e) {
      if (kDebugMode) print('Notification permission request failed: $e');
      _permitted = false;
    }
    return _permitted;
  }

  /// Rebuilds the whole schedule from [assets].
  ///
  /// Everything is cancelled and re-scheduled rather than diffed. The schedule
  /// is small, capped, and derived entirely from the assets, so recomputing it
  /// is cheaper than keeping a correct record of what was scheduled when — and
  /// a stale reminder for an item that has been sold or deleted is exactly the
  /// bug a diff would eventually produce.
  Future<void> sync(
    List<Asset> assets, {
    List<MaintenanceSchedule> schedules = const [],
    required bool warrantyEnabled,
    required bool maintenanceEnabled,
  }) async {
    if (!_ready) return;
    try {
      await _plugin.cancelAll();
      if (!warrantyEnabled && !maintenanceEnabled) return;

      final due = upcomingReminders(
        assets,
        schedules: schedules,
        warrantyEnabled: warrantyEnabled,
        maintenanceEnabled: maintenanceEnabled,
      );
      for (final reminder in due.take(_maxPending)) {
        await _plugin.zonedSchedule(
          id: reminder.id,
          scheduledDate: reminder.fireAt,
          title: reminder.title,
          body: reminder.body,
          payload: reminder.assetId,
          notificationDetails: _details,
          // Inexact on purpose. Exact alarms need SCHEDULE_EXACT_ALARM, which
          // Google grants only to alarm and calendar apps, and a warranty
          // reminder does not care about the difference between 10:00 and
          // 10:20.
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
      }

      if (kDebugMode) {
        if (due.length > _maxPending) {
          print(
            'Warranty reminders: scheduled $_maxPending of ${due.length}; '
            'the rest follow as these fall due.',
          );
        }
      }
    } catch (e) {
      if (kDebugMode) print('Scheduling warranty reminders failed: $e');
    }
  }

  /// Every reminder still ahead of [now], soonest first.
  ///
  /// Warranty and maintenance reminders are merged and sorted together rather
  /// than kept in separate queues, because the cap that follows has to drop the
  /// furthest-off reminder of either kind, not the furthest-off of each.
  @visibleForTesting
  static List<ScheduledReminder> upcomingReminders(
    List<Asset> assets, {
    List<MaintenanceSchedule> schedules = const [],
    bool warrantyEnabled = true,
    bool maintenanceEnabled = true,
    DateTime? now,
  }) {
    final moment = now ?? DateTime.now();
    final reminders = <ScheduledReminder>[];

    if (warrantyEnabled) {
      reminders.addAll(_warrantyReminders(assets, moment));
    }
    if (maintenanceEnabled) {
      reminders.addAll(_maintenanceReminders(assets, schedules, moment));
    }

    reminders.sort((a, b) => a.fireAt.compareTo(b.fireAt));
    return reminders;
  }

  static Iterable<ScheduledReminder> _warrantyReminders(
    List<Asset> assets,
    DateTime moment,
  ) sync* {
    for (final asset in assets) {
      final expiry = asset.warrantyExpiry;
      if (expiry == null) continue;

      for (var i = 0; i < kReminderLeadDays.length; i++) {
        final leadDays = kReminderLeadDays[i];
        final day = expiry.subtract(Duration(days: leadDays));
        final fireAt = _at(day);
        if (!fireAt.isAfter(moment)) continue;

        yield ScheduledReminder(
          id: notificationId(asset.id, i),
          assetId: asset.id,
          fireAt: fireAt,
          title: _warrantyTitle(leadDays, asset.name),
          body:
              'Warranty ends ${DateFormat.yMMMd().format(expiry)}. '
              'Bought ${DateFormat.yMMMd().format(asset.purchaseDate)}.',
        );
      }
    }
  }

  static Iterable<ScheduledReminder> _maintenanceReminders(
    List<Asset> assets,
    List<MaintenanceSchedule> schedules,
    DateTime moment,
  ) sync* {
    for (final due in MaintenancePlanner.plan(assets, schedules)) {
      for (var i = 0; i < kMaintenanceLeadDays.length; i++) {
        final leadDays = kMaintenanceLeadDays[i];
        final fireAt = _at(due.dueAt.subtract(Duration(days: leadDays)));
        if (!fireAt.isAfter(moment)) continue;

        // Offset past the warranty lead slots so a schedule and its item can
        // never collide on an id.
        final slot = kReminderLeadDays.length + i;
        yield ScheduledReminder(
          id: notificationId(due.schedule.id, slot),
          assetId: due.asset.id,
          fireAt: fireAt,
          title:
              leadDays == 0
                  ? '${due.asset.name} — ${due.schedule.title} due today'
                  : '${due.asset.name} — ${due.schedule.title} due in $leadDays days',
          body: _maintenanceBody(due),
        );
      }
    }
  }

  static String _maintenanceBody(MaintenanceDue due) {
    final last =
        due.schedule.lastDoneAt == null
            ? 'Never logged as done.'
            : 'Last done ${DateFormat.yMMMd().format(due.schedule.lastDoneAt!)}.';

    if (!due.schedule.requiredForWarranty) return last;
    // Worth saying on the notification itself: this is the one whose lapse
    // costs money, and it is the reason the schedule was recorded at all.
    return '$last Required to keep the warranty valid.';
  }

  /// The reminder hour on [day], in the app's own timezone.
  ///
  /// Built straight in tz.local rather than as a plain DateTime that is
  /// converted afterwards. Both mean "local", but they are two different
  /// notions of it -- Dart's comes from the process, tz.local from the device
  /// -- and the conversion between them silently moved the hour whenever they
  /// disagreed.
  static tz.TZDateTime _at(DateTime day) =>
      tz.TZDateTime(tz.local, day.year, day.month, day.day, kReminderHour);

  static String _warrantyTitle(int leadDays, String name) {
    switch (leadDays) {
      case 1:
        return '$name — warranty ends tomorrow';
      case 7:
        return '$name — warranty ends in a week';
      default:
        return '$name — warranty ends in $leadDays days';
    }
  }

  /// A stable notification id for one reminder.
  ///
  /// Hashed here rather than with [String.hashCode], which Dart does not
  /// promise to keep stable between runs or SDK versions: an id that shifted
  /// underneath a pending notification would leave one that could never be
  /// cancelled. FNV-1a is fixed by its specification, so the same source always
  /// produces the same id.
  ///
  /// [sourceId] is an asset id for warranty reminders and a schedule id for
  /// maintenance ones; the two are UUIDs from the same pool and cannot clash.
  @visibleForTesting
  static int notificationId(String sourceId, int leadIndex) {
    var hash = 2166136261;
    for (final unit in sourceId.codeUnits) {
      hash ^= unit;
      hash = (hash * 16777619) & 0xFFFFFFFF;
    }
    // Android ids are 32-bit signed; this keeps the result inside that range
    // with a decimal digit spare for the lead index.
    return (hash % 200000000) * 10 + leadIndex;
  }
}

/// One scheduled reminder, resolved to an exact moment.
@immutable
class ScheduledReminder {
  final int id;
  final String assetId;
  final tz.TZDateTime fireAt;
  final String title;
  final String body;

  const ScheduledReminder({
    required this.id,
    required this.assetId,
    required this.fireAt,
    required this.title,
    required this.body,
  });
}
