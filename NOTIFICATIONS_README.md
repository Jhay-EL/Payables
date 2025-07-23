# Payables Notification System

This document describes the notification system implemented in the Payables app for managing subscription renewal reminders.

## Features

### Automatic Notification Scheduling
- **Day-before reminders**: Notifications are automatically scheduled 1 day before each subscription renewal
- **Same-day notifications**: Notifications are sent on the day of renewal
- **Smart scheduling**: Only active subscriptions trigger notifications
- **Automatic cleanup**: Notifications are cancelled when subscriptions are deleted or paused

### Notification Types
1. **Subscription Renewal Tomorrow**: Reminds users about upcoming renewals
2. **Subscription Renewed Today**: Confirms that a subscription has been renewed
3. **Test Notifications**: For testing the notification system

### Billing Cycle Support
The system supports all billing cycles:
- Daily
- Weekly  
- Monthly
- Yearly

## Implementation Details

### Files Added/Modified

#### New Files
- `lib/services/notification_service.dart` - Core notification service
- `lib/ui/notification_settings_screen.dart` - Settings UI for notifications
- `NOTIFICATIONS_README.md` - This documentation

#### Modified Files
- `lib/main.dart` - Added notification service initialization
- `lib/data/subscription_database.dart` - Integrated notifications with CRUD operations
- `lib/ui/settings_screen.dart` - Added navigation to notification settings
- `lib/ui/dashboard_screen.dart` - Added test notification button
- `pubspec.yaml` - Added timezone dependency
- `android/app/src/main/AndroidManifest.xml` - Added required permissions

### Dependencies Added
```yaml
flutter_local_notifications: ^19.3.1
timezone: ^0.10.1
```

### Android Permissions Added
```xml
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
<uses-permission android:name="android.permission.VIBRATE" />
<uses-permission android:name="android.permission.WAKE_LOCK" />
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM" />
```

## Usage

### For Users

1. **Access Notification Settings**:
   - Go to Settings → Notifications
   - Or use the floating action button on the dashboard to test notifications

2. **Request Permissions**:
   - Tap "Request Permissions" to enable notifications
   - Grant notification permissions when prompted

3. **Test Notifications**:
   - Use "Send Test Notification" to verify the system works
   - Use the floating action button on the dashboard for quick testing

4. **Manage Notifications**:
   - View pending notifications
   - Reschedule all notifications
   - Cancel all notifications

### For Developers

#### Initialization
The notification service is automatically initialized in `main.dart`:
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService().initialize();
  // ... rest of app initialization
}
```

#### Scheduling Notifications
Notifications are automatically scheduled when:
- A new subscription is added (if status is 'active')
- A subscription is updated
- All active subscriptions are rescheduled

#### Manual Notification Management
```dart
// Schedule notification for a specific subscription
await NotificationService().scheduleSubscriptionNotification(subscription);

// Update notifications for a subscription
await NotificationService().updateSubscriptionNotifications(subscription);

// Cancel notifications for a subscription
await NotificationService().cancelSubscriptionNotifications(subscriptionId);

// Show immediate notification
await NotificationService().showImmediateNotification(
  title: 'Title',
  body: 'Body',
);
```

## How It Works

### Notification Scheduling Logic
1. **Next Billing Date Calculation**: The system calculates the next billing date based on the subscription's billing cycle
2. **Notification Timing**: 
   - Day-before notification: 1 day before renewal
   - Same-day notification: On the renewal date
3. **Future-Only Scheduling**: Only schedules notifications for future dates
4. **Status Check**: Only active subscriptions trigger notifications

### Database Integration
- **Insert**: Automatically schedules notifications for new active subscriptions
- **Update**: Updates notifications when subscription details change
- **Delete**: Cancels notifications when subscriptions are removed
- **Status Change**: Handles paused/finished subscriptions appropriately

### Platform Support
- **Android**: Full support with custom notification channel
- **iOS**: Full support with proper permission handling
- **Windows**: Basic support (may have limitations)
- **Linux**: Basic support (may have limitations)
- **macOS**: Basic support (may have limitations)

## Testing

### Manual Testing
1. Add a subscription with a billing date in the near future
2. Check that notifications are scheduled
3. Use the test notification button to verify the system works
4. Modify subscription details and verify notifications are updated
5. Delete a subscription and verify notifications are cancelled

### Test Scenarios
- [ ] New subscription with active status
- [ ] New subscription with paused status
- [ ] Update subscription billing date
- [ ] Update subscription status from active to paused
- [ ] Delete subscription
- [ ] Different billing cycles (daily, weekly, monthly, yearly)
- [ ] Past billing dates (should not schedule notifications)
- [ ] Permission denied scenarios

## Troubleshooting

### Common Issues

1. **Notifications not appearing**:
   - Check if permissions are granted
   - Verify the device's notification settings
   - Test with immediate notifications first

2. **Scheduled notifications not firing**:
   - Check if the device has battery optimization enabled
   - Verify the app is not being killed by the system
   - Test with shorter intervals first

3. **Permission issues**:
   - Guide users to device settings to enable notifications
   - Use the "Request Permissions" button in notification settings

### Debug Information
- Check pending notifications in the notification settings screen
- Use the test notification feature to verify basic functionality
- Monitor logs for any error messages

## Future Enhancements

### Potential Improvements
1. **Customizable notification timing**: Allow users to set custom reminder intervals
2. **Notification categories**: Different notification types for different subscription categories
3. **Smart notifications**: Learn user patterns and adjust notification timing
4. **Rich notifications**: Include subscription details and quick actions
5. **Notification history**: Track sent notifications
6. **Batch notifications**: Group multiple renewals in a single notification

### Advanced Features
1. **Geolocation-based reminders**: Remind users when they're near payment locations
2. **Integration with calendar**: Add renewal dates to device calendar
3. **Email notifications**: Send email reminders as backup
4. **SMS notifications**: Send SMS reminders for critical renewals
5. **Smart scheduling**: Avoid notifications during user's quiet hours

## Security and Privacy

- Notifications are stored locally on the device
- No subscription data is sent to external services
- Permissions are requested explicitly with user consent
- Notification content is generated locally from subscription data

## Support

For issues or questions about the notification system:
1. Check this documentation
2. Test with the built-in test features
3. Review the notification settings screen for debugging information
4. Check device notification settings 