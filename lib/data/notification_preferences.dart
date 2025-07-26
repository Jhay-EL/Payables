import 'package:shared_preferences/shared_preferences.dart';

class NotificationPreferences {
  static const String _keyPaymentReminders = 'notification_payment_reminders';
  static const String _keyWeeklySummary = 'notification_weekly_summary';
  static const String _keyBudgetAlerts = 'notification_budget_alerts';
  static const String _keyRenewalNotifications =
      'notification_renewal_notifications';
  static const String _keyNotificationsEnabled = 'notifications_enabled';

  // Default values
  static const bool _defaultPaymentReminders = true;
  static const bool _defaultWeeklySummary = false;
  static const bool _defaultBudgetAlerts = true;
  static const bool _defaultRenewalNotifications = true;
  static const bool _defaultNotificationsEnabled = false;

  // Get notification preferences
  static Future<Map<String, bool>> getPreferences() async {
    final prefs = await SharedPreferences.getInstance();

    return {
      'paymentReminders':
          prefs.getBool(_keyPaymentReminders) ?? _defaultPaymentReminders,
      'weeklySummary':
          prefs.getBool(_keyWeeklySummary) ?? _defaultWeeklySummary,
      'budgetAlerts': prefs.getBool(_keyBudgetAlerts) ?? _defaultBudgetAlerts,
      'renewalNotifications':
          prefs.getBool(_keyRenewalNotifications) ??
          _defaultRenewalNotifications,
      'notificationsEnabled':
          prefs.getBool(_keyNotificationsEnabled) ??
          _defaultNotificationsEnabled,
    };
  }

  // Set individual preference
  static Future<void> setPreference(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();

    switch (key) {
      case 'paymentReminders':
        await prefs.setBool(_keyPaymentReminders, value);
        break;
      case 'weeklySummary':
        await prefs.setBool(_keyWeeklySummary, value);
        break;
      case 'budgetAlerts':
        await prefs.setBool(_keyBudgetAlerts, value);
        break;
      case 'renewalNotifications':
        await prefs.setBool(_keyRenewalNotifications, value);
        break;
      case 'notificationsEnabled':
        await prefs.setBool(_keyNotificationsEnabled, value);
        break;
    }
  }

  // Set all preferences at once
  static Future<void> setAllPreferences(Map<String, bool> preferences) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool(
      _keyPaymentReminders,
      preferences['paymentReminders'] ?? _defaultPaymentReminders,
    );
    await prefs.setBool(
      _keyWeeklySummary,
      preferences['weeklySummary'] ?? _defaultWeeklySummary,
    );
    await prefs.setBool(
      _keyBudgetAlerts,
      preferences['budgetAlerts'] ?? _defaultBudgetAlerts,
    );
    await prefs.setBool(
      _keyRenewalNotifications,
      preferences['renewalNotifications'] ?? _defaultRenewalNotifications,
    );
    await prefs.setBool(
      _keyNotificationsEnabled,
      preferences['notificationsEnabled'] ?? _defaultNotificationsEnabled,
    );
  }

  // Reset to default preferences
  static Future<void> resetToDefaults() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool(_keyPaymentReminders, _defaultPaymentReminders);
    await prefs.setBool(_keyWeeklySummary, _defaultWeeklySummary);
    await prefs.setBool(_keyBudgetAlerts, _defaultBudgetAlerts);
    await prefs.setBool(_keyRenewalNotifications, _defaultRenewalNotifications);
    await prefs.setBool(_keyNotificationsEnabled, _defaultNotificationsEnabled);
  }

  // Get individual preference
  static Future<bool> getPaymentReminders() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyPaymentReminders) ?? _defaultPaymentReminders;
  }

  // Clear all notification preferences
  static Future<void> clearAllPreferences() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_keyPaymentReminders);
    await prefs.remove(_keyWeeklySummary);
    await prefs.remove(_keyBudgetAlerts);
    await prefs.remove(_keyRenewalNotifications);
    await prefs.remove(_keyNotificationsEnabled);
  }

  static Future<bool> getWeeklySummary() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyWeeklySummary) ?? _defaultWeeklySummary;
  }

  static Future<bool> getBudgetAlerts() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyBudgetAlerts) ?? _defaultBudgetAlerts;
  }

  static Future<bool> getRenewalNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyRenewalNotifications) ??
        _defaultRenewalNotifications;
  }

  static Future<bool> getNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyNotificationsEnabled) ??
        _defaultNotificationsEnabled;
  }
}
