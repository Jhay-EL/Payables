import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math' as math;
import 'package:payables/utils/theme_provider.dart';
import 'package:provider/provider.dart';
import 'about_screen.dart';
import 'widget_settings_screen.dart';
import 'package:payables/models/currency.dart';
import 'package:payables/data/currency_database.dart';
import 'package:payables/data/currency_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0.0;

  // Dynamic color system that adapts to dark/light mode (from dashboard)
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

  Color get userSelectedColor {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark
        ? const Color(0xFF3D5A80)
        : const Color(0xFFAAD6FF);
  }

  Color get highContrastBlue {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark
        ? const Color(0xFF4FC3F7)
        : const Color(0xFF00AFEC);
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
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    // Only update if the change is significant enough to warrant a rebuild
    final newOffset = _scrollController.offset;
    // Use a larger threshold to reduce rebuild frequency
    if ((newOffset - _scrollOffset).abs() > 5.0) {
      setState(() {
        _scrollOffset = newOffset;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: CustomScrollView(
        controller: _scrollController,
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
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back_rounded,
                color: highContrastDarkBlue,
                size: 24,
              ),
              onPressed: () => Navigator.pop(context),
              style: IconButton.styleFrom(
                foregroundColor: highContrastDarkBlue,
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: RepaintBoundary(
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(color: backgroundColor),
                    ),
                    // Animated Settings Title with flutter_animate
                    Positioned(
                      left: _getAnimatedTitleLeft(),
                      bottom: _getAnimatedTitleBottom(),
                      child: SafeArea(
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOutCubicEmphasized,
                          opacity: _getAnimatedTitleOpacity(),
                          child:
                              Text(
                                    'Settings',
                                    style: _getAnimatedTitleStyle(context),
                                  )
                                  .animate()
                                  .fadeIn(
                                    duration: const Duration(milliseconds: 800),
                                    curve: Curves.easeOutCubic,
                                  )
                                  .scale(
                                    duration: const Duration(milliseconds: 600),
                                    curve: Curves.elasticOut,
                                    begin: const Offset(0.8, 0.8),
                                    end: const Offset(1.0, 1.0),
                                  )
                                  .then(delay: const Duration(seconds: 2))
                                  .shimmer(
                                    duration: const Duration(
                                      milliseconds: 2000,
                                    ),
                                    color: highContrastDarkBlue.withOpacity(
                                      0.3,
                                    ),
                                    size: 2.0,
                                  ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // M3 Expressive Settings Content
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 32.0),
            sliver: SliverList(
              delegate: SliverChildListDelegate(<Widget>[
                // M3 General Settings Section
                Text(
                  'General',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w400,
                    color: highContrastDarkBlue,
                  ),
                ),
                const SizedBox(height: 20),
                _buildM3SettingsSection([
                  _buildM3SettingsItem(
                    icon: Icons.notifications_rounded,
                    title: 'Notifications',
                    description: 'Enable/Disable app notifications',
                    iconColor: const Color(0xFF6750A4),
                    onTap: () => _handleNotificationsTap(context),
                    isFirst: true,
                  ),
                  _buildM3SettingsItem(
                    icon: Icons.palette_rounded,
                    title: 'Appearance',
                    description: 'Change app color appearance',
                    iconColor: const Color(0xFF006A6B),
                    onTap: () => _handleAppearanceTap(context),
                  ),
                  _buildM3SettingsItem(
                    icon: Icons.attach_money_rounded,
                    title: 'Currency',
                    description: 'Change default app currency',
                    iconColor: const Color(0xFF8B5000),
                    onTap: () => _handleCurrencyTap(context),
                  ),
                  _buildM3SettingsItem(
                    icon: Icons.widgets_rounded,
                    title: 'Widget',
                    description:
                        'Select what payables will display on home screen',
                    iconColor: const Color(0xFF006E1C),
                    onTap: () => _handleWidgetTap(context),
                    isLast: true,
                  ),
                ]),
                const SizedBox(height: 32),

                // M3 Data Management Section
                Text(
                  'Data Management',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w400,
                    color: highContrastDarkBlue,
                  ),
                ),
                const SizedBox(height: 20),
                _buildM3SettingsSection([
                  _buildM3SettingsItem(
                    icon: Icons.download_rounded,
                    title: 'Backup',
                    description: 'Backup all your subscription in .excel file',
                    iconColor: const Color(0xFF8E4EC6),
                    onTap: () => _handleBackupTap(context),
                    isFirst: true,
                  ),
                  _buildM3SettingsItem(
                    icon: Icons.restore_rounded,
                    title: 'Restore',
                    description: 'Restore all your subscription',
                    iconColor: const Color(0xFF984061),
                    onTap: () => _handleRestoreTap(context),
                    isLast: true,
                  ),
                ]),
                const SizedBox(height: 32),

                // M3 Support & Info Section
                Text(
                  'Support & Info',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w400,
                    color: highContrastDarkBlue,
                  ),
                ),
                const SizedBox(height: 20),
                _buildM3SettingsSection([
                  _buildM3SettingsItem(
                    icon: Icons.info_rounded,
                    title: 'About Payables',
                    description: 'Information and privacy policy',
                    iconColor: const Color(0xFF006B5D),
                    onTap: () => _handleAboutTap(context),
                    isFirst: true,
                  ),
                  _buildM3SettingsItem(
                    icon: Icons.delete_rounded,
                    title: 'Erase data',
                    description: 'Remove all data from the app',
                    iconColor: const Color(0xFFEF4444),
                    onTap: () => _handleEraseDataTap(context),
                    isDestructive: true,
                    isLast: true,
                  ),
                ]),
                SizedBox(height: 32 + MediaQuery.of(context).padding.bottom),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods for animated title positioning like dashboard screen
  // Cache constants to avoid repeated calculations
  static const double _expandedHeight = 200.0;
  static const double _collapsedThreshold = _expandedHeight - kToolbarHeight;

  double _getAnimationProgress() {
    return (_scrollOffset / _collapsedThreshold).clamp(0.0, 1.0);
  }

  double _getAnimatedTitleLeft() {
    final progress = _getAnimationProgress();
    return 16.0 + (40.0 * progress);
  }

  double _getAnimatedTitleBottom() {
    final progress = _getAnimationProgress();
    return 32.0 + (progress * -16.0);
  }

  double _getAnimatedTitleOpacity() {
    return 1.0 - _getAnimationProgress();
  }

  TextStyle _getAnimatedTitleStyle(BuildContext context) {
    final progress = _getAnimationProgress();

    // Cache font sizes to avoid repeated theme lookups
    const expandedSize = 36.0;
    const collapsedSize = 22.0;
    final animatedSize =
        expandedSize + ((collapsedSize - expandedSize) * progress);

    return TextStyle(
      fontSize: animatedSize,
      fontWeight: FontWeight.w400,
      color: highContrastDarkBlue,
    );
  }

  Widget _buildM3SettingsSection(List<Widget> items) {
    return Column(children: items);
  }

  Widget _buildM3SettingsItem({
    required IconData icon,
    required String title,
    required String description,
    required Color iconColor,
    required VoidCallback onTap,
    bool isDestructive = false,
    bool isFirst = false,
    bool isLast = false,
  }) {
    // Determine border radius based on position (like dashboard cards)
    BorderRadius borderRadius;
    if (isFirst && isLast) {
      // Single item: 24px all corners
      borderRadius = BorderRadius.circular(24);
    } else if (isFirst) {
      // Top card: 24px top corners, 5px bottom corners
      borderRadius = const BorderRadius.only(
        topLeft: Radius.circular(24),
        topRight: Radius.circular(24),
        bottomLeft: Radius.circular(5),
        bottomRight: Radius.circular(5),
      );
    } else if (isLast) {
      // Bottom card: 5px top corners, 24px bottom corners
      borderRadius = const BorderRadius.only(
        topLeft: Radius.circular(5),
        topRight: Radius.circular(5),
        bottomLeft: Radius.circular(24),
        bottomRight: Radius.circular(24),
      );
    } else {
      // Middle cards: 5px all corners
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
          onTap: onTap,
          borderRadius: borderRadius,
          splashColor: iconColor.withAlpha(31),
          highlightColor: iconColor.withAlpha(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: iconColor.withAlpha(41),
                    borderRadius: BorderRadius.circular(16),
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
                              color: isDestructive
                                  ? const Color(0xFFEF4444)
                                  : highContrastDarkBlue,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: darkColor,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: iconColor, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Handler methods for each setting item
  void _handleNotificationsTap(BuildContext context) {
    _showNotificationsBottomSheet(context);
  }

  void _showNotificationsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      enableDrag: true,
      isDismissible: true,
      useSafeArea: true,
      showDragHandle: false,
      barrierColor: Colors.black.withAlpha(128),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      builder: (context) => _buildNotificationsBottomSheet(context),
    );
  }

  Widget _buildNotificationsBottomSheet(BuildContext context) {
    bool notificationsEnabled =
        true; // This should be managed by state management
    bool paymentReminders = true;
    bool weeklySummary = false;
    bool budgetAlerts = true;

    return StatefulBuilder(
      builder: (context, setState) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // M3 Handle
              Container(
                width: 32,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 16),
                decoration: BoxDecoration(
                  color: darkColor.withAlpha(102),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // M3 Header with Icon
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6750A4).withAlpha(41),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.notifications_rounded,
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
                            'Notifications',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w500,
                                  color: highContrastDarkBlue,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Manage your notification preferences',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: darkColor,
                                  fontWeight: FontWeight.w400,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // M3 Content
              Flexible(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // M3 Main notification toggle - Enhanced Visibility
                        Container(
                          decoration: BoxDecoration(
                            color: lightColor.withAlpha(150),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: lightColor.withAlpha(100),
                              width: 1,
                            ),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  notificationsEnabled = !notificationsEnabled;
                                });
                              },
                              borderRadius: BorderRadius.circular(20),
                              splashColor: const Color(
                                0xFF6750A4,
                              ).withAlpha(31),
                              highlightColor: const Color(
                                0xFF6750A4,
                              ).withAlpha(20),
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: const Color(
                                          0xFF6750A4,
                                        ).withAlpha(41),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: const Icon(
                                        Icons.notifications_rounded,
                                        color: Color(0xFF6750A4),
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Push Notifications',
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w600,
                                                  color: highContrastDarkBlue,
                                                ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Receive app notifications',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium
                                                ?.copyWith(
                                                  color: darkColor,
                                                  fontWeight: FontWeight.w400,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Switch(
                                      value: notificationsEnabled,
                                      onChanged: (value) {
                                        setState(() {
                                          notificationsEnabled = value;
                                        });
                                      },
                                      activeColor: const Color(0xFF6750A4),
                                      activeTrackColor: const Color(
                                        0xFF6750A4,
                                      ).withAlpha(120),
                                      inactiveThumbColor: darkColor,
                                      inactiveTrackColor: lightColor,
                                      materialTapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        // M3 Notification types section
                        Text(
                          'Notification Types',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w500,
                                color: highContrastDarkBlue,
                              ),
                        ),
                        const SizedBox(height: 16),
                        _buildNotificationOptionsSection([
                          _buildNotificationOption(
                            'Payment Reminders',
                            'Get notified before payments are due',
                            Icons.payment_rounded,
                            paymentReminders,
                            (value) {
                              setState(() {
                                paymentReminders = value;
                              });
                            },
                            isFirst: true,
                          ),
                          _buildNotificationOption(
                            'Weekly Summary',
                            'Get weekly spending summaries',
                            Icons.summarize_rounded,
                            weeklySummary,
                            (value) {
                              setState(() {
                                weeklySummary = value;
                              });
                            },
                          ),
                          _buildNotificationOption(
                            'Budget Alerts',
                            'Get alerts when approaching budget limits',
                            Icons.warning_rounded,
                            budgetAlerts,
                            (value) {
                              setState(() {
                                budgetAlerts = value;
                              });
                            },
                            isLast: true,
                          ),
                        ]),
                      ],
                    ),
                  ),
                ),
              ),
              // M3 Safe Area with Navigation Bar Space
              SizedBox(height: MediaQuery.of(context).padding.bottom + 32),
            ],
          ),
        );
      },
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

    // Determine border radius based on position (like dashboard cards)
    BorderRadius borderRadius;
    if (isFirst && isLast) {
      // Single item: 24px all corners
      borderRadius = BorderRadius.circular(24);
    } else if (isFirst) {
      // Top card: 24px top corners, 5px bottom corners
      borderRadius = const BorderRadius.only(
        topLeft: Radius.circular(24),
        topRight: Radius.circular(24),
        bottomLeft: Radius.circular(5),
        bottomRight: Radius.circular(5),
      );
    } else if (isLast) {
      // Bottom card: 5px top corners, 24px bottom corners
      borderRadius = const BorderRadius.only(
        topLeft: Radius.circular(5),
        topRight: Radius.circular(5),
        bottomLeft: Radius.circular(24),
        bottomRight: Radius.circular(24),
      );
    } else {
      // Middle cards: 5px all corners
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
                              fontWeight: FontWeight.w600,
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

  // Helper method to get distinct colors for different notification types
  Color _getIconColor(IconData icon) {
    // Return specific colors based on icon type
    switch (icon) {
      case Icons.payment_rounded:
        return const Color(0xFF006A6B);
      case Icons.summarize_rounded:
        return const Color(0xFF8B5000);
      case Icons.warning_rounded:
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF6750A4);
    }
  }

  Widget _buildAppearanceSwitchOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required Function(bool) onChanged,
  }) {
    const iconColor = Color(0xFF8E4EC6);
    return Container(
      decoration: BoxDecoration(
        color: lightColor.withAlpha(150),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: lightColor.withAlpha(100), width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onChanged(!value),
          borderRadius: BorderRadius.circular(20),
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
                              fontWeight: FontWeight.w600,
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
                  value: value,
                  onChanged: onChanged,
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

  void _handleAppearanceTap(BuildContext context) {
    _showAppearanceBottomSheet(context);
  }

  void _showAppearanceBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      enableDrag: true,
      isDismissible: true,
      useSafeArea: true,
      showDragHandle: false,
      barrierColor: Colors.black.withAlpha(128),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      builder: (context) => _buildAppearanceBottomSheet(context),
    );
  }

  Widget _buildAppearanceBottomSheet(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return StatefulBuilder(
      builder: (context, setState) {
        String selectedTheme = themeProvider.themeMode
            .toString()
            .split('.')
            .last;
        bool dynamicColorEnabled =
            true; // This should be managed by state management

        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.80,
          ),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // M3 Handle
              Container(
                width: 32,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 16),
                decoration: BoxDecoration(
                  color: darkColor.withAlpha(102),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // M3 Header with Icon - Enhanced Visibility
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF006A6B).withAlpha(41),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.palette_rounded,
                        color: const Color(0xFF006A6B),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Appearance',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w500,
                                  color: highContrastDarkBlue,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Change app color appearance',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: darkColor,
                                  fontWeight: FontWeight.w400,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // M3 Content
              Flexible(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // M3 Theme Options Section
                        Text(
                          'Theme',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w500,
                                color: highContrastDarkBlue,
                              ),
                        ),
                        const SizedBox(height: 16),
                        _buildThemeOptionsSection([
                          _buildThemeOption(
                            'Light Mode',
                            'Clean and bright interface',
                            Icons.light_mode_rounded,
                            const Color(0xFFF59E0B),
                            'light',
                            selectedTheme,
                            (newTheme) {
                              // No need to call setState here anymore,
                              // the themeProvider will notify listeners
                            },
                            isFirst: true,
                          ),
                          _buildThemeOption(
                            'Dark Mode',
                            'Easy on the eyes in low light',
                            Icons.dark_mode_rounded,
                            const Color(0xFF6366F1),
                            'dark',
                            selectedTheme,
                            (newTheme) {
                              // No need to call setState here anymore
                            },
                          ),
                          _buildThemeOption(
                            'System',
                            'Adapts to your device settings',
                            Icons.settings_system_daydream_rounded,
                            const Color(0xFF8B5CF6),
                            'system',
                            selectedTheme,
                            (newTheme) {
                              // No need to call setState here anymore
                            },
                            isLast: true,
                          ),
                        ]),
                        const SizedBox(height: 24),
                        // M3 Dynamic Color Toggle
                        _buildAppearanceSwitchOption(
                          title: 'Dynamic Color',
                          subtitle: 'Colors based on your wallpaper',
                          icon: Icons.color_lens_rounded,
                          value: dynamicColorEnabled,
                          onChanged: (value) {
                            setState(() {
                              dynamicColorEnabled = value;
                            });
                          },
                        ),
                        const SizedBox(height: 24),
                        // M3 Info text with dashboard theme
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: userSelectedColor.withAlpha(100),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: userSelectedColor.withAlpha(120),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline_rounded,
                                color: darkColor,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Theme changes will take effect immediately',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: highContrastDarkBlue,
                                        fontWeight: FontWeight.w500,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // M3 Safe Area with Navigation Bar Space
              SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildThemeOptionsSection(List<Widget> items) {
    return Column(children: items);
  }

  Widget _buildThemeOption(
    String title,
    String subtitle,
    IconData icon,
    Color iconColor,
    String value,
    String selectedValue,
    Function(String) onThemeSelected, {
    bool isFirst = false,
    bool isLast = false,
  }) {
    bool isSelected = selectedValue == value;

    // Determine border radius based on position (like dashboard cards)
    BorderRadius borderRadius;
    if (isFirst && isLast) {
      // Single item: 24px all corners
      borderRadius = BorderRadius.circular(24);
    } else if (isFirst) {
      // Top card: 24px top corners, 5px bottom corners
      borderRadius = const BorderRadius.only(
        topLeft: Radius.circular(24),
        topRight: Radius.circular(24),
        bottomLeft: Radius.circular(5),
        bottomRight: Radius.circular(5),
      );
    } else if (isLast) {
      // Bottom card: 5px top corners, 24px bottom corners
      borderRadius = const BorderRadius.only(
        topLeft: Radius.circular(5),
        topRight: Radius.circular(5),
        bottomLeft: Radius.circular(24),
        bottomRight: Radius.circular(24),
      );
    } else {
      // Middle cards: 5px all corners
      borderRadius = BorderRadius.circular(5);
    }

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 2),
      child: Card(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: isSelected ? iconColor.withAlpha(20) : lightColor.withAlpha(150),
        shape: RoundedRectangleBorder(borderRadius: borderRadius),
        child: InkWell(
          onTap: () {
            late ThemeMode newThemeMode;
            switch (value) {
              case 'light':
                newThemeMode = ThemeMode.light;
                break;
              case 'dark':
                newThemeMode = ThemeMode.dark;
                break;
              case 'system':
              default:
                newThemeMode = ThemeMode.system;
                break;
            }
            Provider.of<ThemeProvider>(
              context,
              listen: false,
            ).setThemeMode(newThemeMode);
            // The onThemeSelected call is no longer needed here
          },
          borderRadius: borderRadius,
          splashColor: iconColor.withAlpha(31),
          highlightColor: iconColor.withAlpha(20),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: borderRadius,
              border: Border.all(
                color: isSelected ? iconColor : Colors.transparent,
                width: isSelected ? 2 : 0,
              ),
            ),
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
                                fontWeight: FontWeight.w600,
                                color: highContrastDarkBlue,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: darkColor,
                                fontWeight: FontWeight.w400,
                              ),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: iconColor,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleCurrencyTap(BuildContext context) {
    _showCurrencyBottomSheet(context);
  }

  void _showCurrencyBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      enableDrag: true,
      isDismissible: true,
      useSafeArea: true,
      showDragHandle: false,
      barrierColor: Colors.black.withAlpha(128),
      builder: (context) => _buildCurrencyBottomSheet(context),
    );
  }

  Widget _buildCurrencyBottomSheet(BuildContext context) {
    final currencyProvider = Provider.of<CurrencyProvider>(context);
    String selectedCurrency = currencyProvider.selectedCurrency;
    String searchQuery = '';
    TextEditingController searchController = TextEditingController();

    // Define all available currencies
    final allCurrencies = CurrencyDatabase.getCurrencies();

    return StatefulBuilder(
      builder: (context, setState) {
        // Filter currencies based on search query
        final filteredCurrencies = allCurrencies.where((currency) {
          if (searchQuery.isEmpty) return true;
          return currency.name.toLowerCase().contains(
                searchQuery.toLowerCase(),
              ) ||
              currency.code.toLowerCase().contains(searchQuery.toLowerCase()) ||
              currency.symbol.toLowerCase().contains(searchQuery.toLowerCase());
        }).toList();

        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.90,
          ),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // M3 Handle
              Container(
                width: 32,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 16),
                decoration: BoxDecoration(
                  color: darkColor.withAlpha(102),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // M3 Header with Icon
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8B5000).withAlpha(41),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.attach_money_rounded,
                        color: const Color(0xFF8B5000),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Currency',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w500,
                                  color: highContrastDarkBlue,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Change default app currency',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: darkColor,
                                  fontWeight: FontWeight.w400,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // M3 Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // M3 Search Box
                      Container(
                        decoration: BoxDecoration(
                          color: lightColor.withAlpha(100),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: darkColor.withAlpha(51),
                            width: 1,
                          ),
                        ),
                        child: TextField(
                          controller: searchController,
                          decoration: InputDecoration(
                            hintText: 'Search currencies...',
                            hintStyle: TextStyle(
                              color: darkColor.withAlpha(153),
                              fontSize: 16,
                            ),
                            prefixIcon: Icon(
                              Icons.search_rounded,
                              color: darkColor.withAlpha(153),
                              size: 20,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                          ),
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(color: highContrastDarkBlue),
                          onChanged: (value) {
                            setState(() {
                              searchQuery = value;
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                      // M3 Currency Options Section
                      Text(
                        'Currencies',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w500,
                              color: highContrastDarkBlue,
                            ),
                      ),
                      const SizedBox(height: 16),
                      _buildCurrencyOptionsSection(
                        filteredCurrencies,
                        selectedCurrency,
                        setState,
                      ),
                      if (filteredCurrencies.isEmpty) ...[
                        const SizedBox(height: 32),
                        Container(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            children: [
                              Icon(
                                Icons.search_off_rounded,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant.withAlpha(102),
                                size: 48,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No currencies found',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      color: darkColor.withAlpha(153),
                                      fontWeight: FontWeight.w500,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Try adjusting your search terms',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: darkColor.withAlpha(102)),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      // M3 Info text with dashboard theme
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: userSelectedColor.withAlpha(100),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: userSelectedColor.withAlpha(120),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              color: darkColor,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Currency changes will apply to new entries',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: highContrastDarkBlue,
                                      fontWeight: FontWeight.w500,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // M3 Safe Area with Navigation Bar Space
                      SizedBox(
                        height: MediaQuery.of(context).padding.bottom + 32,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCurrencyOptionsSection(
    List<Currency> currencies,
    String selectedCurrency,
    StateSetter setState,
  ) {
    return Column(
      children: [
        for (int i = 0; i < currencies.length; i++)
          _buildCurrencyOption(
            currencies[i],
            selectedCurrency,
            setState,
            isFirst: i == 0,
            isLast: i == currencies.length - 1,
          ),
      ],
    );
  }

  Widget _buildCurrencyOption(
    Currency currency,
    String selectedValue,
    StateSetter setState, {
    bool isFirst = false,
    bool isLast = false,
  }) {
    bool isSelected = selectedValue == currency.code;

    // Determine border radius based on position (like dashboard cards)
    BorderRadius borderRadius;
    if (isFirst && isLast) {
      // Single item: 24px all corners
      borderRadius = BorderRadius.circular(24);
    } else if (isFirst) {
      // Top card: 24px top corners, 5px bottom corners
      borderRadius = const BorderRadius.only(
        topLeft: Radius.circular(24),
        topRight: Radius.circular(24),
        bottomLeft: Radius.circular(5),
        bottomRight: Radius.circular(5),
      );
    } else if (isLast) {
      // Bottom card: 5px top corners, 24px bottom corners
      borderRadius = const BorderRadius.only(
        topLeft: Radius.circular(5),
        topRight: Radius.circular(5),
        bottomLeft: Radius.circular(24),
        bottomRight: Radius.circular(24),
      );
    } else {
      // Middle cards: 5px all corners
      borderRadius = BorderRadius.circular(5);
    }

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 2),
      child: Card(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: isSelected
            ? currency.color.withAlpha(20)
            : lightColor.withAlpha(150),
        shape: RoundedRectangleBorder(borderRadius: borderRadius),
        child: InkWell(
          onTap: () {
            setState(() {
              selectedValue = currency.code;
            });
            // Handle currency change
            Provider.of<CurrencyProvider>(
              context,
              listen: false,
            ).setCurrency(currency.code);
            if (context.mounted) {
              Navigator.pop(context);
            }
          },
          borderRadius: borderRadius,
          splashColor: currency.color.withAlpha(31),
          highlightColor: currency.color.withAlpha(20),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: borderRadius,
              border: Border.all(
                color: isSelected ? currency.color : Colors.transparent,
                width: isSelected ? 2 : 0,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: currency.color.withAlpha(41),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(currency.icon, color: currency.color, size: 20),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currency.name,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: highContrastDarkBlue,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${currency.code} (${currency.symbol})',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: darkColor,
                                fontWeight: FontWeight.w400,
                              ),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: currency.color,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleWidgetTap(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const WidgetSettingsScreen()),
    );
  }

  void _handleBackupTap(BuildContext context) {
    _showBackupBottomSheet(context);
  }

  void _handleRestoreTap(BuildContext context) {
    _showRestoreBottomSheet(context);
  }

  void _showBackupBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      enableDrag: true,
      isDismissible: true,
      useSafeArea: true,
      showDragHandle: false,
      barrierColor: Colors.black.withAlpha(128),
      builder: (context) => _buildBackupBottomSheet(context),
    );
  }

  void _showRestoreBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      enableDrag: true,
      isDismissible: true,
      useSafeArea: true,
      showDragHandle: false,
      barrierColor: Colors.black.withAlpha(128),
      builder: (context) => _buildRestoreBottomSheet(context),
    );
  }

  Widget _buildBackupBottomSheet(BuildContext context) {
    return StatefulBuilder(
      builder: (context, setState) {
        return Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // M3 Handle
              Container(
                width: 32,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 16),
                decoration: BoxDecoration(
                  color: darkColor.withAlpha(102),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // M3 Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF006B5D).withAlpha(41),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.backup_rounded,
                        color: const Color(0xFF006B5D),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Backup Data',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w500,
                                  color: highContrastDarkBlue,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Export your subscriptions and data',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: darkColor,
                                  fontWeight: FontWeight.w400,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // M3 Content
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildBackupOptionsSection([
                      {
                        'title': 'Excel Export',
                        'subtitle': 'Export all subscriptions to Excel file',
                        'icon': Icons.table_chart_rounded,
                        'color': const Color(0xFF8B5000),
                        'onTap': () {
                          // ignore: avoid_print
                          print('Excel export tapped');
                          if (!context.mounted) return;
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Excel export started...'),
                            ),
                          );
                        },
                      },
                      {
                        'title': 'JSON Export',
                        'subtitle': 'Export data in JSON format',
                        'icon': Icons.code_rounded,
                        'color': const Color(0xFF006E1C),
                        'onTap': () {
                          // ignore: avoid_print
                          print('JSON export tapped');
                          if (!context.mounted) return;
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('JSON export started...'),
                            ),
                          );
                        },
                      },
                      {
                        'title': 'PDF Report',
                        'subtitle': 'Generate PDF report of all subscriptions',
                        'icon': Icons.picture_as_pdf_rounded,
                        'color': const Color(0xFF984061),
                        'onTap': () {
                          // ignore: avoid_print
                          print('PDF export tapped');
                          if (!context.mounted) return;
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('PDF report generated...'),
                            ),
                          );
                        },
                      },
                    ]),
                    const SizedBox(height: 24),
                    // M3 Info Box
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: highContrastBlue.withAlpha(31),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: highContrastBlue.withAlpha(80),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            color: highContrastBlue,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Your backup files will be saved to your device\'s Downloads folder.',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: highContrastBlue,
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // M3 Safe Area with Navigation Bar Space
              SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRestoreBottomSheet(BuildContext context) {
    return StatefulBuilder(
      builder: (context, setState) {
        return Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // M3 Handle
              Container(
                width: 32,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 16),
                decoration: BoxDecoration(
                  color: darkColor.withAlpha(102),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // M3 Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8E4EC6).withAlpha(41),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.restore_rounded,
                        color: const Color(0xFF8E4EC6),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Restore Data',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w500,
                                  color: highContrastDarkBlue,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Import your subscriptions and data',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: darkColor,
                                  fontWeight: FontWeight.w400,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // M3 Content
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildRestoreOptionsSection([
                      {
                        'title': 'From Excel File',
                        'subtitle': 'Import subscriptions from Excel file',
                        'icon': Icons.upload_file_rounded,
                        'color': const Color(0xFF8B5000),
                        'onTap': () {
                          // ignore: avoid_print
                          print('Excel import tapped');
                          if (!context.mounted) return;
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Select Excel file to import...'),
                            ),
                          );
                        },
                      },
                      {
                        'title': 'From JSON File',
                        'subtitle': 'Import data from JSON backup file',
                        'icon': Icons.data_object_rounded,
                        'color': const Color(0xFF006E1C),
                        'onTap': () {
                          // ignore: avoid_print
                          print('JSON import tapped');
                          if (!context.mounted) return;
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Select JSON file to import...'),
                            ),
                          );
                        },
                      },
                      {
                        'title': 'From Cloud Backup',
                        'subtitle': 'Restore from your cloud backup',
                        'icon': Icons.cloud_download_rounded,
                        'color': const Color(0xFF006A6B),
                        'onTap': () {
                          // ignore: avoid_print
                          print('Cloud import tapped');
                          if (!context.mounted) return;
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Connecting to cloud backup...'),
                            ),
                          );
                        },
                      },
                    ]),
                    const SizedBox(height: 24),
                    // M3 Warning Box
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withAlpha(31),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFEF4444).withAlpha(80),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: const Color(0xFFEF4444),
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Restoring data will replace your current subscriptions. Consider backing up first.',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: const Color(0xFFEF4444),
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // M3 Safe Area with Navigation Bar Space
              SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBackupOptionsSection(List<Map<String, dynamic>> options) {
    return Column(
      children: [
        for (int i = 0; i < options.length; i++) ...[
          _buildBackupOptionCard(
            options[i]['title'] as String,
            options[i]['subtitle'] as String,
            options[i]['icon'] as IconData,
            options[i]['color'] as Color,
            options[i]['onTap'] as VoidCallback,
            isFirst: i == 0,
            isLast: i == options.length - 1,
          ),
          if (i < options.length - 1) const SizedBox(height: 2),
        ],
      ],
    );
  }

  Widget _buildBackupOptionCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap, {
    required bool isFirst,
    required bool isLast,
  }) {
    // Determine border radius based on position
    BorderRadius borderRadius;
    if (isFirst) {
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

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: lightColor.withAlpha(150),
      shape: RoundedRectangleBorder(borderRadius: borderRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        splashColor: color.withAlpha(31),
        highlightColor: color.withAlpha(20),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withAlpha(41),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: highContrastDarkBlue,
                        fontWeight: FontWeight.w500,
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRestoreOptionsSection(List<Map<String, dynamic>> options) {
    return Column(
      children: [
        for (int i = 0; i < options.length; i++) ...[
          _buildRestoreOptionCard(
            options[i]['title'] as String,
            options[i]['subtitle'] as String,
            options[i]['icon'] as IconData,
            options[i]['color'] as Color,
            options[i]['onTap'] as VoidCallback,
            isFirst: i == 0,
            isLast: i == options.length - 1,
          ),
          if (i < options.length - 1) const SizedBox(height: 2),
        ],
      ],
    );
  }

  Widget _buildRestoreOptionCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap, {
    required bool isFirst,
    required bool isLast,
  }) {
    // Determine border radius based on position
    BorderRadius borderRadius;
    if (isFirst) {
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

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: lightColor.withAlpha(150),
      shape: RoundedRectangleBorder(borderRadius: borderRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        splashColor: color.withAlpha(31),
        highlightColor: color.withAlpha(20),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withAlpha(41),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: highContrastDarkBlue,
                        fontWeight: FontWeight.w500,
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
            ],
          ),
        ),
      ),
    );
  }

  void _handleAboutTap(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AboutScreen()),
    );
  }

  void _handleEraseDataTap(BuildContext context) {
    // ignore: avoid_print
    print('Erase data tapped');
    _showEraseDataDialog(context);
  }

  void _showEraseDataDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          elevation: 8,
          shadowColor: Colors.black.withAlpha(40),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withAlpha(41),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.delete_forever_rounded,
                  color: const Color(0xFFEF4444),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'Erase All Data',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: highContrastDarkBlue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Are you sure you want to erase all data? This action will permanently delete:',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: darkColor,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 16),
              // List of what will be erased
              _buildEraseItem(Icons.subscriptions_rounded, 'All subscriptions'),
              const SizedBox(height: 8),
              _buildEraseItem(Icons.settings_rounded, 'All settings'),
              const SizedBox(height: 8),
              _buildEraseItem(Icons.analytics_rounded, 'All insights data'),
              const SizedBox(height: 16),
              // Warning container
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withAlpha(31),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFEF4444).withAlpha(80),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_rounded,
                      color: const Color(0xFFEF4444),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'This action cannot be undone.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: const Color(0xFFEF4444),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                side: BorderSide(color: darkColor),
              ),
              child: Text('Cancel', style: TextStyle(color: darkColor)),
            ),
            const SizedBox(width: 12),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                // Show success message
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'All data has been erased successfully',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                    backgroundColor: const Color(0xFFEF4444),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    margin: const EdgeInsets.all(16),
                  ),
                );
                // ignore: avoid_print
                print('Data erased');
              },
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Erase All Data',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEraseItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFFEF4444).withAlpha(153), size: 16),
        const SizedBox(width: 8),
        Text(
          text,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: darkColor.withAlpha(179),
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

class _ColorWheelWidget extends StatefulWidget {
  final Function(Color) onColorSelected;

  const _ColorWheelWidget({required this.onColorSelected});

  @override
  State<_ColorWheelWidget> createState() => _ColorWheelWidgetState();
}

class _ColorWheelWidgetState extends State<_ColorWheelWidget> {
  bool _showPreview = false;
  Color _previewColor = Colors.red;
  Offset _previewPosition = Offset.zero;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 280,
        height: 280,
        child: Stack(
          children: [
            // Color wheel
            CustomPaint(
              size: const Size(280, 280),
              painter: ColorWheelPainter(),
            ),
            // Gesture detector for color selection
            GestureDetector(
              onTapDown: (details) {
                _handleColorSelection(details.localPosition, true);
              },
              onLongPressStart: (details) {
                _handleColorSelection(details.localPosition, false);
                setState(() {
                  _showPreview = true;
                  _previewPosition = details.localPosition;
                });
              },
              onLongPressMoveUpdate: (details) {
                _handleColorSelection(details.localPosition, false);
                setState(() {
                  _previewPosition = details.localPosition;
                });
              },
              onLongPressEnd: (details) {
                setState(() {
                  _showPreview = false;
                });
                widget.onColorSelected(_previewColor);
                if (context.mounted) {
                  Navigator.pop(context);
                }
              },
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.grey.withAlpha(77),
                    width: 2,
                  ),
                ),
              ),
            ),
            // Color preview
            if (_showPreview)
              Positioned(
                left: _previewPosition.dx - 30,
                top: _previewPosition.dy - 70,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: _previewColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(77),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
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

  void _handleColorSelection(Offset position, bool shouldCommit) {
    final center = const Offset(140, 140); // Center of 280x280 circle
    final offset = position - center;
    final distance = offset.distance;

    // Only respond if within the circle (radius = 140)
    if (distance <= 140) {
      // Calculate angle (hue)
      double angle =
          (math.atan2(offset.dy, offset.dx) * 180 / math.pi + 360) % 360;

      // Calculate saturation based on distance from center
      double saturation = math.min(distance / 140, 1.0);

      // Use full brightness for vibrant colors
      double value = 1.0;

      Color selectedColor = HSVColor.fromAHSV(
        1.0,
        angle,
        saturation,
        value,
      ).toColor();

      if (shouldCommit) {
        widget.onColorSelected(selectedColor);
        if (context.mounted) {
          Navigator.pop(context);
        }
      } else {
        setState(() {
          _previewColor = selectedColor;
        });
      }
    }
  }
}

class ColorWheelPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final sweepGradient = const SweepGradient(
      colors: [
        Color(0xFFFF0000),
        Color(0xFFFFFF00),
        Color(0xFF00FF00),
        Color(0xFF00FFFF),
        Color(0xFF0000FF),
        Color(0xFFFF00FF),
        Color(0xFFFF0000),
      ],
    );
    final radialGradient = const RadialGradient(
      colors: [Colors.white, Colors.transparent],
      stops: [0.0, 1.0],
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()..shader = sweepGradient.createShader(rect),
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()..shader = radialGradient.createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
