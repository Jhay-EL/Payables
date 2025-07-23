import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../models/subscription.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

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
      print('Notification service initialization failed: $e');
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
      print('Failed to create notification channel: $e');
    }
  }

  Future<void> _onNotificationTapped(NotificationResponse response) async {
    // Handle notification tap
    // You can navigate to specific screens or perform actions here
    print('Notification tapped: ${response.payload}');
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

      return grantedNotificationPermission ?? false;
    } catch (e) {
      print('Failed to request notification permissions: $e');
      return false;
    }
  }

  Future<void> scheduleSubscriptionNotification(
    Subscription subscription,
  ) async {
    if (subscription.status != 'active') return;

    // Calculate next billing date
    final DateTime nextBillingDate = _calculateNextBillingDate(subscription);

    // Schedule notification 1 day before billing
    final DateTime notificationDate = nextBillingDate.subtract(
      const Duration(days: 1),
    );

    // Only schedule if the notification date is in the future
    if (notificationDate.isAfter(DateTime.now())) {
      await _scheduleNotification(
        id: subscription.id ?? 0,
        title: 'Subscription Renewal Tomorrow',
        body:
            '${subscription.title} will be renewed tomorrow for ${subscription.currency} ${subscription.amount.toStringAsFixed(2)}',
        scheduledDate: notificationDate,
        payload: subscription.id.toString(),
      );
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
          color: Color(0xFF2196F3), // Blue color
          enableVibration: true,
          playSound: true,
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
      print('Failed to show immediate notification: $e');
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
}
