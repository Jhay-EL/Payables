import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/notification_service.dart';
import '../data/notification_preferences.dart';
import '../utils/snackbar_service.dart';

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
  bool _isLoading = true;

  // Notification type preferences
  bool _paymentReminders = true;
  bool _weeklySummary = false;
  bool _budgetAlerts = true;
  bool _renewalNotifications = true;

  // Dynamic color system that adapts to dark/light mode
  Color get backgroundColor {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark
        ? const Color(0xFF121212)
        : const Color(0xFFF2F7FF);
  }

  Color get lightColor {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark
        ? const Color(0xFF1E1E1E)
        : const Color(0xFFD7EAFF);
  }

  Color get darkColor {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark
        ? const Color(0xFF43474e)
        : const Color(0xFF43474e);
  }

  Color get highContrastDarkBlue {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark
        ? const Color(0xFFE3F2FD)
        : const Color(0xFF191c20);
  }

  @override
  void initState() {
    super.initState();
    _loadNotificationSettings();
  }

  Future<void> _loadNotificationSettings() async {
    try {
      final notificationsEnabled = await _notificationService
          .areNotificationsEnabled();
      final preferences = await NotificationPreferences.getPreferences();

      setState(() {
        _notificationsEnabled = notificationsEnabled;
        _paymentReminders = preferences['paymentReminders'] ?? true;
        _weeklySummary = preferences['weeklySummary'] ?? false;
        _budgetAlerts = preferences['budgetAlerts'] ?? true;
        _renewalNotifications = preferences['renewalNotifications'] ?? true;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _requestPermissions() async {
    final currentContext = context;
    final granted = await _notificationService.requestPermissions();
    setState(() {
      _notificationsEnabled = granted;
    });
    await NotificationPreferences.setPreference(
      'notificationsEnabled',
      granted,
    );

    if (!mounted) return;

    if (granted && currentContext.mounted) {
      SnackbarService.showSuccess(
        currentContext,
        'Notification permissions granted!',
      );
    } else if (currentContext.mounted) {
      SnackbarService.showWarning(
        currentContext,
        'Notification permissions denied. Please enable them in settings.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: const Color(0xFF6750A4)),
            )
          : CustomScrollView(
              slivers: [
                // M3 Expressive Large Flexible App Bar
                SliverAppBar(
                  expandedHeight: 200.0,
                  floating: false,
                  pinned: true,
                  snap: false,
                  elevation: 0,
                  surfaceTintColor: lightColor,
                  backgroundColor: backgroundColor,
                  leading: Padding(
                    padding: const EdgeInsets.only(left: 16.0),
                    child: RepaintBoundary(
                      child: IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(
                          Icons.arrow_back_rounded,
                          color: highContrastDarkBlue,
                          size: 24,
                        ),
                        splashRadius: 24,
                      ),
                    ),
                  ),
                  flexibleSpace: FlexibleSpaceBar(
                    background: RepaintBoundary(
                      child: Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(color: backgroundColor),
                          ),
                          // Animated Notification Settings Title
                          Positioned(
                            left: 16.0,
                            bottom: 32.0,
                            child: SafeArea(
                              child:
                                  Text(
                                        'Notification Settings',
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineLarge
                                            ?.copyWith(
                                              fontWeight: FontWeight.w400,
                                              color: highContrastDarkBlue,
                                            ),
                                      )
                                      .animate()
                                      .fadeIn(
                                        duration: const Duration(
                                          milliseconds: 800,
                                        ),
                                        curve: Curves.easeOutCubic,
                                      )
                                      .scale(
                                        duration: const Duration(
                                          milliseconds: 600,
                                        ),
                                        curve: Curves.elasticOut,
                                        begin: const Offset(0.8, 0.8),
                                        end: const Offset(1.0, 1.0),
                                      ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // M3 Expressive Notification Settings Content
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 32.0),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // Main Notification Toggle Section
                      _buildMainNotificationSection(),
                      const SizedBox(height: 32),

                      // Notification Types Section
                      _buildNotificationTypesSection(),
                      SizedBox(
                        height: 32 + MediaQuery.of(context).padding.bottom,
                      ),
                    ]),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildMainNotificationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Push Notifications',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w400,
            color: highContrastDarkBlue,
          ),
        ),
        const SizedBox(height: 20),
        Container(
          decoration: BoxDecoration(
            color: lightColor.withAlpha(150),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: lightColor.withAlpha(100), width: 1),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () async {
                final currentContext = context;
                if (!_notificationsEnabled) {
                  await _requestPermissions();
                } else {
                  setState(() {
                    _notificationsEnabled = false;
                  });
                  await NotificationPreferences.setPreference(
                    'notificationsEnabled',
                    false,
                  );
                  if (mounted && currentContext.mounted) {
                    SnackbarService.showWarning(
                      currentContext,
                      'Notifications disabled. You can re-enable them anytime.',
                    );
                  }
                }
              },
              borderRadius: BorderRadius.circular(24),
              splashColor: const Color(0xFF6750A4).withAlpha(31),
              highlightColor: const Color(0xFF6750A4).withAlpha(20),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6750A4).withAlpha(41),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        _notificationsEnabled
                            ? Icons.notifications_active_rounded
                            : Icons.notifications_off_rounded,
                        color: const Color(0xFF6750A4),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Enable Notifications',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w500,
                                  color: highContrastDarkBlue,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _notificationsEnabled
                                ? 'Receive app notifications and reminders'
                                : 'Notifications are currently disabled',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: darkColor,
                                  fontWeight: FontWeight.w400,
                                ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _notificationsEnabled,
                      onChanged: (value) async {
                        final currentContext = context;
                        if (value) {
                          await _requestPermissions();
                        } else {
                          setState(() {
                            _notificationsEnabled = false;
                          });
                          await NotificationPreferences.setPreference(
                            'notificationsEnabled',
                            false,
                          );
                          if (mounted && currentContext.mounted) {
                            SnackbarService.showWarning(
                              currentContext,
                              'Notifications disabled. You can re-enable them anytime.',
                            );
                          }
                        }
                      },
                      activeColor: const Color(0xFF6750A4),
                      activeTrackColor: const Color(0xFF6750A4).withAlpha(120),
                      inactiveThumbColor: darkColor,
                      inactiveTrackColor: lightColor,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationTypesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Notification Types',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w400,
            color: highContrastDarkBlue,
          ),
        ),
        const SizedBox(height: 20),
        _buildNotificationOptionsSection([
          _buildNotificationOption(
            'Payment Reminders',
            'Get notified before payments are due',
            Icons.payment_rounded,
            _paymentReminders,
            (value) async {
              setState(() {
                _paymentReminders = value;
              });
              await NotificationPreferences.setPreference(
                'paymentReminders',
                value,
              );
            },
            isFirst: true,
          ),
          _buildNotificationOption(
            'Renewal Notifications',
            'Get notified when subscriptions renew',
            Icons.refresh_rounded,
            _renewalNotifications,
            (value) async {
              setState(() {
                _renewalNotifications = value;
              });
              await NotificationPreferences.setPreference(
                'renewalNotifications',
                value,
              );
            },
          ),
          _buildNotificationOption(
            'Weekly Summary',
            'Get weekly spending summaries',
            Icons.summarize_rounded,
            _weeklySummary,
            (value) async {
              setState(() {
                _weeklySummary = value;
              });
              await NotificationPreferences.setPreference(
                'weeklySummary',
                value,
              );
            },
          ),
          _buildNotificationOption(
            'Budget Alerts',
            'Get alerts when approaching budget limits',
            Icons.warning_rounded,
            _budgetAlerts,
            (value) async {
              setState(() {
                _budgetAlerts = value;
              });
              await NotificationPreferences.setPreference(
                'budgetAlerts',
                value,
              );
            },
            isLast: true,
          ),
        ]),
      ],
    );
  }

  Widget _buildNotificationOptionsSection(List<Widget> items) {
    return Column(children: items);
  }

  Widget _buildNotificationOption(
    String title,
    String subtitle,
    IconData icon,
    bool isEnabled,
    Function(bool) onToggle, {
    bool isFirst = false,
    bool isLast = false,
  }) {
    final iconColor = _getIconColor(icon);

    BorderRadius borderRadius;
    if (isFirst && isLast) {
      borderRadius = BorderRadius.circular(24);
    } else if (isFirst) {
      borderRadius = const BorderRadius.only(
        topLeft: Radius.circular(24),
        topRight: Radius.circular(24),
        bottomLeft: Radius.circular(5),
        bottomRight: Radius.circular(5),
      );
    } else if (isLast) {
      borderRadius = const BorderRadius.only(
        topLeft: Radius.circular(5),
        topRight: Radius.circular(5),
        bottomLeft: Radius.circular(24),
        bottomRight: Radius.circular(24),
      );
    } else {
      borderRadius = BorderRadius.circular(5);
    }

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 2),
      child: Card(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: lightColor.withAlpha(150),
        shape: RoundedRectangleBorder(borderRadius: borderRadius),
        child: InkWell(
          onTap: () => onToggle(!isEnabled),
          borderRadius: borderRadius,
          splashColor: iconColor.withAlpha(31),
          highlightColor: iconColor.withAlpha(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconColor.withAlpha(41),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w500,
                              color: highContrastDarkBlue,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: darkColor,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: isEnabled,
                  onChanged: onToggle,
                  activeColor: iconColor,
                  activeTrackColor: iconColor.withAlpha(120),
                  inactiveThumbColor: darkColor,
                  inactiveTrackColor: lightColor,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getIconColor(IconData icon) {
    switch (icon) {
      case Icons.payment_rounded:
        return const Color(0xFF006A6B);
      case Icons.refresh_rounded:
        return const Color(0xFF8B5000);
      case Icons.summarize_rounded:
        return const Color(0xFF8E4EC6);
      case Icons.warning_rounded:
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF6750A4);
    }
  }
}
