import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:logger/logger.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../models/subscription.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static final Logger _logger = Logger();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static const String _channelId = 'payables_notifications';
  static const String _channelName = 'Payables Notifications';
  static const String _channelDescription =
      'Notifications for subscription renewals and reminders';

  Future<void> initialize() async {
    try {
      // Initialize timezone
      tz.initializeTimeZones();

      // Android settings
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      // iOS settings
      const DarwinInitializationSettings iosSettings =
          DarwinInitializationSettings(
            requestAlertPermission: true,
            requestBadgePermission: true,
            requestSoundPermission: true,
          );

      // Initialize settings
      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      // Initialize the plugin
      await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // Create notification channel for Android
      await _createNotificationChannel();
    } catch (e) {
      // Handle platform-specific errors gracefully
      _logger.e('Notification service initialization failed: $e');
      // Continue app execution even if notifications fail to initialize
    }
  }

  Future<void> _createNotificationChannel() async {
    try {
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDescription,
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
        showBadge: true,
      );

      await _notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(channel);
    } catch (e) {
      _logger.e('Failed to create notification channel: $e');
    }
  }

  Future<void> _onNotificationTapped(NotificationResponse response) async {
    // Handle notification tap
    // You can navigate to specific screens or perform actions here
    _logger.d('Notification tapped: ${response.payload}');
  }

  Future<bool> requestPermissions() async {
    try {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _notifications
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();

      final bool? grantedNotificationPermission = await androidImplementation
          ?.requestNotificationsPermission();

      // Request exact alarm permission on Android 12+
      if (androidImplementation != null) {
        try {
          await androidImplementation.requestExactAlarmsPermission();
        } catch (e) {
          _logger.w('Failed to request exact alarm permission: $e');
          // This is not critical, so we continue
        }
      }

      return grantedNotificationPermission ?? false;
    } catch (e) {
      _logger.e('Failed to request notification permissions: $e');
      return false;
    }
  }

  Future<bool> areNotificationsEnabled() async {
    try {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _notifications
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();

      final bool? granted = await androidImplementation
          ?.areNotificationsEnabled();
      return granted ?? false;
    } catch (e) {
      _logger.e('Failed to check notification permissions: $e');
      return false;
    }
  }

  Future<void> scheduleSubscriptionNotification(
    Subscription subscription,
  ) async {
    if (subscription.status != 'active') return;

    // Calculate next billing date
    final DateTime nextBillingDate = _calculateNextBillingDate(subscription);

    // Schedule notification based on user's alert preference
    if (subscription.alertDays > 0) {
      final DateTime notificationDate = nextBillingDate.subtract(
        Duration(days: subscription.alertDays),
      );

      // Only schedule if the notification date is in the future
      if (notificationDate.isAfter(DateTime.now())) {
        String alertText = subscription.alertDays == 1
            ? 'tomorrow'
            : 'in ${subscription.alertDays} days';

        await _scheduleNotification(
          id: subscription.id ?? 0,
          title: 'Subscription Renewal $alertText',
          body:
              '${subscription.title} will be renewed $alertText for ${subscription.currency} ${subscription.amount.toStringAsFixed(2)}',
          scheduledDate: notificationDate,
          payload: subscription.id.toString(),
        );
      }
    }

    // Schedule notification on billing date
    if (nextBillingDate.isAfter(DateTime.now())) {
      await _scheduleNotification(
        id:
            (subscription.id ?? 0) +
            1000, // Different ID for same-day notification
        title: 'Subscription Renewed Today',
        body:
            '${subscription.title} has been renewed for ${subscription.currency} ${subscription.amount.toStringAsFixed(2)}',
        scheduledDate: nextBillingDate,
        payload: subscription.id.toString(),
      );
    }
  }

  DateTime _calculateNextBillingDate(Subscription subscription) {
    DateTime nextDate = subscription.billingDate;

    while (nextDate.isBefore(DateTime.now())) {
      switch (subscription.billingCycle.toLowerCase()) {
        case 'daily':
          nextDate = nextDate.add(const Duration(days: 1));
          break;
        case 'weekly':
          nextDate = nextDate.add(const Duration(days: 7));
          break;
        case 'monthly':
          nextDate = DateTime(nextDate.year, nextDate.month + 1, nextDate.day);
          break;
        case 'yearly':
          nextDate = DateTime(nextDate.year + 1, nextDate.month, nextDate.day);
          break;
        default:
          nextDate = nextDate.add(const Duration(days: 30));
      }
    }

    return nextDate;
  }

  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    try {
      final tz.TZDateTime scheduledTZDate = tz.TZDateTime.from(
        scheduledDate,
        tz.local,
      );

      await _notifications.zonedSchedule(
        id,
        title,
        body,
        scheduledTZDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDescription,
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            color: Color(0xFF2196F3),
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: payload,
      );
    } catch (e) {
      // Handle exact alarms permission error
      if (e.toString().contains('exact_alarms_not_permitted')) {
        _logger.w(
          'Exact alarms not permitted, falling back to approximate scheduling',
        );
        try {
          // Fall back to approximate scheduling
          await _notifications.zonedSchedule(
            id,
            title,
            body,
            tz.TZDateTime.from(scheduledDate, tz.local),
            const NotificationDetails(
              android: AndroidNotificationDetails(
                _channelId,
                _channelName,
                channelDescription: _channelDescription,
                importance: Importance.high,
                priority: Priority.high,
                icon: '@mipmap/ic_launcher',
                color: Color(0xFF2196F3),
              ),
              iOS: DarwinNotificationDetails(
                presentAlert: true,
                presentBadge: true,
                presentSound: true,
              ),
            ),
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            payload: payload,
          );
        } catch (fallbackError) {
          _logger.w(
            'Failed to schedule notification even with fallback: $fallbackError',
          );
        }
      } else {
        _logger.w('Failed to schedule notification: $e');
      }
    }
  }

  Future<void> cancelSubscriptionNotifications(int subscriptionId) async {
    // Cancel both the day-before and same-day notifications
    await _notifications.cancel(subscriptionId);
    await _notifications.cancel(subscriptionId + 1000);
  }

  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }

  Future<void> showImmediateNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      await _notifications.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000, // Unique ID
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDescription,
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            color: Color(0xFF2196F3),
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: payload,
      );
    } catch (e) {
      _logger.e('Failed to show immediate notification: $e');
    }
  }

  // Method to schedule notifications for all active subscriptions
  Future<void> scheduleAllSubscriptionNotifications(
    List<Subscription> subscriptions,
  ) async {
    for (final subscription in subscriptions) {
      if (subscription.status == 'active') {
        await scheduleSubscriptionNotification(subscription);
      }
    }
  }

  // Method to update notifications when subscription is modified
  Future<void> updateSubscriptionNotifications(
    Subscription subscription,
  ) async {
    // Cancel existing notifications
    await cancelSubscriptionNotifications(subscription.id ?? 0);

    // Schedule new notifications if subscription is active
    if (subscription.status == 'active') {
      await scheduleSubscriptionNotification(subscription);
    }
  }

  // Method to schedule weekly summary notifications
  Future<void> scheduleWeeklySummaryNotification() async {
    // Schedule for every Sunday at 9 AM
    final now = DateTime.now();
    final nextSunday = now.add(Duration(days: (7 - now.weekday) % 7));
    final scheduledTime = DateTime(
      nextSunday.year,
      nextSunday.month,
      nextSunday.day,
      9, // 9 AM
      0,
    );

    if (scheduledTime.isAfter(now)) {
      await _scheduleNotification(
        id: 9999, // Special ID for weekly summary
        title: 'Weekly Subscription Summary',
        body: 'Check your spending summary for this week',
        scheduledDate: scheduledTime,
        payload: 'weekly_summary',
      );
    }
  }

  // Method to schedule budget alert notifications
  Future<void> scheduleBudgetAlertNotification(
    double currentSpending,
    double budgetLimit,
  ) async {
    final percentage = (currentSpending / budgetLimit) * 100;

    if (percentage >= 80) {
      await _scheduleNotification(
        id: 9998, // Special ID for budget alerts
        title: 'Budget Alert',
        body:
            'You\'ve used ${percentage.toStringAsFixed(1)}% of your monthly budget',
        scheduledDate: DateTime.now().add(const Duration(minutes: 1)),
        payload: 'budget_alert',
      );
    }
  }

  // Method to get notification statistics
  Future<Map<String, dynamic>> getNotificationStats() async {
    final pendingNotifications = await getPendingNotifications();
    final activeCount = pendingNotifications
        .where((n) => n.id < 1000 || n.id == 9999 || n.id == 9998)
        .length;

    return {
      'total': pendingNotifications.length,
      'active': activeCount,
      'subscription_reminders': pendingNotifications
          .where((n) => n.id < 1000)
          .length,
      'weekly_summaries': pendingNotifications
          .where((n) => n.id == 9999)
          .length,
      'budget_alerts': pendingNotifications.where((n) => n.id == 9998).length,
    };
  }

  // Method to clear specific notification types
  Future<void> clearNotificationType(String type) async {
    final pendingNotifications = await getPendingNotifications();

    switch (type) {
      case 'weekly_summary':
        for (final notification in pendingNotifications) {
          if (notification.id == 9999) {
            await _notifications.cancel(notification.id);
          }
        }
        break;
      case 'budget_alerts':
        for (final notification in pendingNotifications) {
          if (notification.id == 9998) {
            await _notifications.cancel(notification.id);
          }
        }
        break;
      case 'subscription_reminders':
        for (final notification in pendingNotifications) {
          if (notification.id < 1000) {
            await _notifications.cancel(notification.id);
          }
        }
        break;
    }
  }
}
