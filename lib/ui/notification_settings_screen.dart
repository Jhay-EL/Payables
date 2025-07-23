import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../services/notification_service.dart';
import '../data/subscription_database.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  final NotificationService _notificationService = NotificationService();
  bool _notificationsEnabled = false;
  List<PendingNotificationRequest> _pendingNotifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotificationSettings();
  }

  Future<void> _loadNotificationSettings() async {
    try {
      final pendingNotifications = await _notificationService
          .getPendingNotifications();
      setState(() {
        _pendingNotifications = pendingNotifications;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _requestPermissions() async {
    final granted = await _notificationService.requestPermissions();
    setState(() {
      _notificationsEnabled = granted;
    });

    if (granted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notification permissions granted!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Notification permissions denied. Please enable them in settings.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<void> _testNotification() async {
    await _notificationService.showImmediateNotification(
      title: 'Test Notification',
      body: 'This is a test notification from Payables!',
    );
  }

  Future<void> _rescheduleAllNotifications() async {
    try {
      final subscriptions = await SubscriptionDatabase.getActiveSubscriptions();
      await _notificationService.scheduleAllSubscriptionNotifications(
        subscriptions,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Rescheduled notifications for ${subscriptions.length} active subscriptions',
          ),
          backgroundColor: Colors.green,
        ),
      );

      _loadNotificationSettings(); // Refresh the list
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to reschedule notifications'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _cancelAllNotifications() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel All Notifications'),
        content: const Text(
          'Are you sure you want to cancel all scheduled notifications?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Yes, Cancel All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _notificationService.cancelAllNotifications();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All notifications cancelled'),
          backgroundColor: Colors.orange,
        ),
      );
      _loadNotificationSettings(); // Refresh the list
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Settings'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Permission Section
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Notification Permissions',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(
                                _notificationsEnabled
                                    ? Icons.notifications_active
                                    : Icons.notifications_off,
                                color: _notificationsEnabled
                                    ? Colors.green
                                    : Colors.grey,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _notificationsEnabled
                                      ? 'Notifications are enabled'
                                      : 'Notifications are disabled',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: _requestPermissions,
                            child: const Text('Request Permissions'),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Test Notification Section
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Test Notifications',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Send a test notification to verify everything is working correctly.',
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: _testNotification,
                            child: const Text('Send Test Notification'),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Manage Notifications Section
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Manage Notifications',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _rescheduleAllNotifications,
                                  child: const Text('Reschedule All'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _cancelAllNotifications,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange,
                                  ),
                                  child: const Text('Cancel All'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Pending Notifications Section
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'Pending Notifications',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${_pendingNotifications.length}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (_pendingNotifications.isEmpty)
                            const Text(
                              'No pending notifications',
                              style: TextStyle(color: Colors.grey),
                            )
                          else
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _pendingNotifications.length,
                              itemBuilder: (context, index) {
                                final notification =
                                    _pendingNotifications[index];
                                return ListTile(
                                  leading: const Icon(Icons.schedule),
                                  title: Text(notification.title ?? 'No title'),
                                  subtitle: Text(
                                    notification.body ?? 'No body',
                                  ),
                                  trailing: Text(
                                    'ID: ${notification.id}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Information Section
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'How Notifications Work',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            '• Notifications are automatically scheduled when you add or update subscriptions\n'
                            '• You\'ll receive a reminder 1 day before each renewal\n'
                            '• You\'ll also receive a notification on the day of renewal\n'
                            '• Notifications are automatically cancelled when you delete subscriptions\n'
                            '• Paused subscriptions won\'t trigger notifications',
                            style: TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
