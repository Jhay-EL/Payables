import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:payables/data/subscription_database.dart';
import 'package:payables/data/category_preferences_database.dart';
import 'package:payables/models/subscription.dart';
import 'package:payables/ui/addsubs_screen.dart';
import 'package:payables/ui/subscription_screen.dart';
import 'package:payables/ui/settings_screen.dart';

import 'package:payables/utils/snackbar_service.dart';
import 'package:payables/utils/dashboard_refresh_provider.dart';
import 'package:payables/utils/material3_color_system.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with WidgetsBindingObserver {
  final ScrollController _scrollController = ScrollController();
  bool _isCategoryHidden = false;
  bool _isInsightsHidden = false;
  bool _isPausedFinishedHidden = false;
  bool _isEditMode = false;
  bool _isLoading = true;
  double _scrollOffset = 0.0;

  // Cache color calculations to avoid repeated theme lookups
  late Color _backgroundColor;
  late Color _lightColor;
  late Color _darkColor;
  late Color _userSelectedColor;
  late Color _highContrastBlue;
  late Color _highContrastDarkBlue;

  // Real subscription data
  List<Subscription> _subscriptions = [];
  List<Subscription> _pausedSubscriptions = [];
  List<Subscription> _finishedSubscriptions = [];
  int _totalSubscriptions = 0;
  int _thisWeekCount = 0;
  int _thisMonthCount = 0;

  // Cache default categories to avoid recreating them
  static final List<Map<String, dynamic>> _defaultCategories = [
    {
      'icon': Icons.play_circle_filled_rounded,
      'name': 'Entertainment',
      'count': 0,
      'color': Material3ColorSystem.categoryColors[0],
      'originalColor': Material3ColorSystem.categoryColors[0],
      'originalBackgroundColor':
          Material3ColorSystem.categoryBackgroundColors[0],
    },
    {
      'icon': Icons.cloud_upload_rounded,
      'name': 'Cloud & Software',
      'count': 0,
      'color': Material3ColorSystem.categoryColors[1],
      'originalColor': Material3ColorSystem.categoryColors[1],
      'originalBackgroundColor':
          Material3ColorSystem.categoryBackgroundColors[1],
    },
    {
      'icon': Icons.bolt_rounded,
      'name': 'Utilities & Household',
      'count': 0,
      'color': Material3ColorSystem.categoryColors[2],
      'originalColor': Material3ColorSystem.categoryColors[2],
      'originalBackgroundColor':
          Material3ColorSystem.categoryBackgroundColors[2],
    },
    {
      'icon': Icons.phone_android_rounded,
      'name': 'Mobile & Connectivity',
      'count': 0,
      'color': Material3ColorSystem.categoryColors[3],
      'originalColor': Material3ColorSystem.categoryColors[3],
      'originalBackgroundColor':
          Material3ColorSystem.categoryBackgroundColors[3],
    },
    {
      'icon': Icons.account_balance_wallet_rounded,
      'name': 'Insurance & Finance',
      'count': 0,
      'color': Material3ColorSystem.categoryColors[4],
      'originalColor': Material3ColorSystem.categoryColors[4],
      'originalBackgroundColor':
          Material3ColorSystem.categoryBackgroundColors[4],
    },
  ];

  List<Map<String, dynamic>> _categories = List.from(_defaultCategories);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadSubscriptionData();
    _scrollController.addListener(_onScroll);

    // Listen to dashboard refresh notifications
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final refreshProvider = Provider.of<DashboardRefreshProvider>(
        context,
        listen: false,
      );
      refreshProvider.addListener(_onDashboardRefreshRequested);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Cache color calculations once when dependencies change
    _cacheColors();
  }

  void _cacheColors() {
    final brightness = Theme.of(context).brightness;

    // Use Material 3 color system for adaptive colors
    _backgroundColor = Material3ColorSystem.getSurfaceColor(brightness);
    _lightColor = Material3ColorSystem.getSurfaceVariantColor(brightness);
    _darkColor = Material3ColorSystem.getOnSurfaceVariantColor(brightness);
    _userSelectedColor = Material3ColorSystem.getPrimaryContainerColor(
      brightness,
    );
    _highContrastBlue = Material3ColorSystem.getPrimaryColor(brightness);
    _highContrastDarkBlue = Material3ColorSystem.getOnSurfaceColor(brightness);
  }

  // Public method to refresh dashboard data (can be called from other screens)
  Future<void> refreshDashboard() async {
    await _refreshDashboardData();
  }

  // Enhanced method to refresh dashboard with better error handling and state management
  Future<void> _refreshDashboardWithDelay() async {
    if (!mounted) return;

    try {
      // Reduced delay for better performance
      await Future.delayed(const Duration(milliseconds: 10));
      await _refreshDashboardData();
    } catch (e) {
      // If first attempt fails, try again with shorter delay
      if (mounted) {
        await Future.delayed(const Duration(milliseconds: 100));
        await _refreshDashboardData();
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Refresh data when app comes back to foreground
    if (state == AppLifecycleState.resumed) {
      _refreshDashboardWithDelay();
    }
  }

  void _onScroll() {
    // Only update if the change is significant enough to warrant a rebuild
    final newOffset = _scrollController.offset;
    // Use a larger threshold to reduce rebuild frequency
    if ((newOffset - _scrollOffset).abs() > 10.0) {
      setState(() {
        _scrollOffset = newOffset;
      });
    }
  }

  void _onDashboardRefreshRequested() {
    if (mounted) {
      _refreshDashboardWithDelay();
    }
  }

  Future<void> _refreshDashboardData() async {
    if (!mounted) return;

    try {
      // Minimal delay for better performance
      await Future.delayed(const Duration(milliseconds: 5));

      // Load fresh data
      await _loadSubscriptionData();
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      // If refresh fails, try again after a longer delay
      if (mounted) {
        await Future.delayed(const Duration(milliseconds: 200));
        await _loadSubscriptionData();
      }
    }
  }

  Future<void> _loadSubscriptionData() async {
    if (!mounted) return;

    // Only show loading on first load, not on refresh
    if (_subscriptions.isEmpty) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      // Use a small delay to prevent UI blocking
      await Future.delayed(const Duration(milliseconds: 10));

      // Load all dashboard data in a single optimized call
      final dashboardData = await SubscriptionDatabase.getDashboardData();

      if (!mounted) return;

      final allSubscriptions =
          dashboardData['allSubscriptions'] as List<Subscription>;
      final activeSubscriptions =
          dashboardData['activeSubscriptions'] as List<Subscription>;
      final pausedSubscriptions =
          dashboardData['pausedSubscriptions'] as List<Subscription>;
      final finishedSubscriptions =
          dashboardData['finishedSubscriptions'] as List<Subscription>;

      final counts = dashboardData['counts'] as Map<String, int>;
      final categoryCounts =
          dashboardData['categoryCounts'] as Map<String, int>;

      final thisWeekCount = counts['thisWeek'] ?? 0;
      final thisMonthCount = counts['thisMonth'] ?? 0;

      // Get category preferences from database
      final hiddenCategories =
          await CategoryPreferencesDatabase.getHiddenCategories();
      final categoryCustomizations =
          await CategoryPreferencesDatabase.getAllCategoryCustomizations();

      // Create a new list of categories with updated counts, preserving custom changes
      final List<Map<String, dynamic>> updatedCategories = [];
      final defaultCategoryNames = _defaultCategories
          .map((c) => c['name'])
          .toSet();

      // Create a map of existing categories to preserve their settings
      final Map<String, Map<String, dynamic>> existingCategories = {};
      for (final category in _categories) {
        final categoryName = category['name'].toString();
        existingCategories[categoryName] = Map<String, dynamic>.from(category);
      }

      // Process default categories first (only if they exist in subscriptions or have custom settings)
      for (final category in _defaultCategories) {
        final categoryName = category['name'].toString();
        final count = categoryCounts[categoryName] ?? 0;

        // Skip hidden categories
        if (hiddenCategories.contains(categoryName)) {
          continue;
        }

        // Only include default categories if they have subscriptions or custom settings
        if (count > 0 || existingCategories.containsKey(categoryName)) {
          // Check if we have existing custom settings for this category
          if (existingCategories.containsKey(categoryName)) {
            final existingCategory = existingCategories[categoryName]!;
            updatedCategories.add({
              'name': categoryName,
              'icon': existingCategory['icon'] ?? category['icon'],
              'count': count,
              'color': existingCategory['color'] ?? category['color'],
              'originalColor':
                  existingCategory['originalColor'] ??
                  category['originalColor'],
              'originalBackgroundColor':
                  existingCategory['originalBackgroundColor'] ??
                  category['originalBackgroundColor'],
            });
          } else {
            // Use default settings
            final newCategory = Map<String, dynamic>.from(category);
            newCategory['count'] = count;
            updatedCategories.add(newCategory);
          }
        }
      }

      // Add categories from subscriptions that are not in the default list
      categoryCounts.forEach((categoryName, count) {
        if (!defaultCategoryNames.contains(categoryName) &&
            categoryName != 'Not set') {
          // Skip hidden categories
          if (hiddenCategories.contains(categoryName)) {
            return;
          }

          // Check if we have customizations from preferences database
          final customization = categoryCustomizations[categoryName];
          if (customization != null) {
            updatedCategories.add({
              'name': categoryName,
              'icon': IconData(
                customization['icon_code_point'] ??
                    Icons.category_rounded.codePoint,
                fontFamily: 'MaterialIcons',
              ),
              'count': count,
              'color': customization['color_value'] != null
                  ? Color(customization['color_value'])
                  : Material3ColorSystem.getOnSurfaceVariantColor(
                      Theme.of(context).brightness,
                    ),
              'originalColor': customization['color_value'] != null
                  ? Color(customization['color_value'])
                  : Material3ColorSystem.getOnSurfaceVariantColor(
                      Theme.of(context).brightness,
                    ),
              'originalBackgroundColor':
                  customization['background_color_value'] != null
                  ? Color(customization['background_color_value'])
                  : Material3ColorSystem.getSurfaceVariantColor(
                      Theme.of(context).brightness,
                    ),
            });
          } else {
            // Check if we have existing custom settings for this category
            if (existingCategories.containsKey(categoryName)) {
              final existingCategory = existingCategories[categoryName]!;
              updatedCategories.add({
                'name': categoryName,
                'icon': existingCategory['icon'] ?? Icons.category_rounded,
                'count': count,
                'color':
                    existingCategory['color'] ??
                    Material3ColorSystem.getOnSurfaceVariantColor(
                      Theme.of(context).brightness,
                    ),
                'originalColor':
                    existingCategory['originalColor'] ??
                    Material3ColorSystem.getOnSurfaceVariantColor(
                      Theme.of(context).brightness,
                    ),
                'originalBackgroundColor':
                    existingCategory['originalBackgroundColor'] ??
                    Material3ColorSystem.getSurfaceVariantColor(
                      Theme.of(context).brightness,
                    ),
              });
            } else {
              // New category, use defaults
              updatedCategories.add({
                'name': categoryName,
                'icon': Icons.category_rounded,
                'count': count,
                'color': Material3ColorSystem.getOnSurfaceVariantColor(
                  Theme.of(context).brightness,
                ),
                'originalColor': Material3ColorSystem.getOnSurfaceVariantColor(
                  Theme.of(context).brightness,
                ),
                'originalBackgroundColor':
                    Material3ColorSystem.getSurfaceVariantColor(
                      Theme.of(context).brightness,
                    ),
              });
            }
          }
        }
      });

      if (mounted) {
        setState(() {
          _subscriptions = allSubscriptions;
          _pausedSubscriptions = pausedSubscriptions;
          _finishedSubscriptions = finishedSubscriptions;
          _totalSubscriptions = activeSubscriptions
              .length; // Only count active subscriptions for "All"
          _thisWeekCount = thisWeekCount;
          _thisMonthCount = thisMonthCount;
          _categories = updatedCategories;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  double _getMonthlyAmount(Subscription subscription) {
    switch (subscription.billingCycle.toLowerCase()) {
      case 'daily':
        return subscription.amount * 30;
      case 'weekly':
        return subscription.amount * 4.33;
      case 'monthly':
        return subscription.amount;
      case 'yearly':
        return subscription.amount / 12;
      default:
        return subscription.amount;
    }
  }

  // Helper methods for animated title positioning like settings screen
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
      color: _highContrastDarkBlue,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();

    // Remove dashboard refresh listener
    try {
      final refreshProvider = Provider.of<DashboardRefreshProvider>(
        context,
        listen: false,
      );
      refreshProvider.removeListener(_onDashboardRefreshRequested);
    } catch (e) {
      // Ignore errors if provider is not available
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Show loading screen for first load
    if (_isLoading && _subscriptions.isEmpty) {
      return Scaffold(
        backgroundColor: _backgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_highContrastBlue, _userSelectedColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_rounded,
                  color: Colors.white,
                  size: 40,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Loading Payables...',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: _highContrastDarkBlue,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(_highContrastBlue),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _backgroundColor,
      body: CustomScrollView(
        // Add physics for smoother scrolling
        physics: const AlwaysScrollableScrollPhysics(),
        controller: _scrollController,
        slivers: [
          // M3 Expressive Large Flexible App Bar
          SliverAppBar(
            expandedHeight: 200.0,
            floating: false,
            pinned: true,
            snap: false,
            elevation: 0,
            surfaceTintColor: Material3ColorSystem.getSurfaceTintColor(
              Theme.of(context).brightness,
            ),
            backgroundColor: _backgroundColor,
            automaticallyImplyLeading: false,
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: _buildM3PopupMenu(),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: RepaintBoundary(
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(color: _backgroundColor),
                    ),
                    // Animated Payables Title with enhanced flutter_animate
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
                                    'Payables',
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
                                    color: _highContrastDarkBlue.withValues(
                                      alpha: 0.3,
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
          // M3 Expressive Dashboard Content
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 32.0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // M3 Overview Section
                Text(
                      'Overview',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.w400,
                            color: _highContrastDarkBlue,
                          ),
                    )
                    .animate()
                    .fadeIn(
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.easeOutCubic,
                    )
                    .slideX(
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeOutCubic,
                      begin: -0.2,
                      end: 0.0,
                    ),
                const SizedBox(height: 20),
                _buildM3OverviewSection(),
                const SizedBox(height: 32),

                // M3 Category Section
                if (!_isCategoryHidden) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                            'Categories',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w400,
                                  color: _highContrastDarkBlue,
                                ),
                          )
                          .animate()
                          .fadeIn(
                            duration: const Duration(milliseconds: 600),
                            curve: Curves.easeOutCubic,
                          )
                          .slideX(
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeOutCubic,
                            begin: -0.2,
                            end: 0.0,
                          ),
                      // Save button (only in edit mode)
                      if (_isEditMode) ...[
                        FilledButton.icon(
                          onPressed: () {
                            setState(() {
                              _isEditMode = false;
                            });
                            // Show success message
                            SnackbarService.showSuccess(
                              context,
                              'Changes saved successfully',
                            );
                          },
                          icon: Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                          label: Text(
                            'Save',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor:
                                Material3ColorSystem.getTertiaryColor(
                                  Theme.of(context).brightness,
                                ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildM3CategorySection(),
                  const SizedBox(height: 32),
                ],

                // M3 Paused/Finished Payables Section
                if (!_isPausedFinishedHidden &&
                    (_pausedSubscriptions.isNotEmpty ||
                        _finishedSubscriptions.isNotEmpty)) ...[
                  Text(
                    'Paused/Finished Payables',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w400,
                      color: _highContrastDarkBlue,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildM3PausedFinishedSection(),
                  const SizedBox(height: 32),
                ],

                // M3 Insights Section
                if (!_isInsightsHidden) ...[
                  Text(
                        'Insights',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.w400,
                              color: _highContrastDarkBlue,
                            ),
                      )
                      .animate()
                      .fadeIn(
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.easeOutCubic,
                      )
                      .slideX(
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeOutCubic,
                        begin: -0.2,
                        end: 0.0,
                      ),
                  const SizedBox(height: 20),
                  _buildM3InsightsSection(),
                ],

                SizedBox(height: 32 + MediaQuery.of(context).padding.bottom),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildM3OverviewSection() {
    if (_isLoading) {
      return Card(
        elevation: 0,
        color: _lightColor.withAlpha(150),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: const Padding(
          padding: EdgeInsets.all(32.0),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return Column(
      children: [
        _buildM3OverviewCard(
              icon: Icons.dashboard_rounded,
              title: 'All',
              subtitle: 'View all payables',
              count: _totalSubscriptions,
              color: _darkColor,
              isFirst: true,
              isLast: false,
            )
            .animate()
            .fadeIn(
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
            )
            .slideY(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutCubic,
              begin: 0.3,
              end: 0.0,
            ),
        const SizedBox(height: 2),
        _buildM3OverviewCard(
              icon: Icons.date_range_rounded,
              title: 'This Week',
              subtitle: 'Due in 7 days',
              count: _thisWeekCount,
              color: _darkColor,
              isFirst: false,
              isLast: false,
            )
            .animate()
            .fadeIn(
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
            )
            .slideY(
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOutCubic,
              begin: 0.3,
              end: 0.0,
            ),
        const SizedBox(height: 2),
        _buildM3OverviewCard(
              icon: Icons.calendar_month_rounded,
              title: 'This Month',
              subtitle: 'Due in 30 days',
              count: _thisMonthCount,
              color: _darkColor,
              isFirst: false,
              isLast: true,
            )
            .animate()
            .fadeIn(
              duration: const Duration(milliseconds: 1000),
              curve: Curves.easeOutCubic,
            )
            .slideY(
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              begin: 0.3,
              end: 0.0,
            ),
      ],
    );
  }

  Widget _buildM3OverviewCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required int count,
    required Color color,
    required bool isFirst,
    required bool isLast,
  }) {
    // Use consistent custom colors for all cards
    Color cardBackgroundColor = _lightColor.withAlpha(150);
    Color iconColor = _darkColor;

    // Determine border radius based on position
    BorderRadius borderRadius;
    if (isFirst) {
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

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: cardBackgroundColor,
      shape: RoundedRectangleBorder(borderRadius: borderRadius),
      child: InkWell(
        onTap: () => _handleOverviewCardTap(title),
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
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: _highContrastDarkBlue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: _darkColor,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: iconColor.withAlpha(31),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  count.toString(),
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: iconColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildM3CategorySection() {
    if (_isEditMode) {
      return ReorderableListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _categories.length,
        onReorder: (int oldIndex, int newIndex) {
          setState(() {
            if (newIndex > oldIndex) {
              newIndex -= 1;
            }
            final Map<String, dynamic> item = _categories.removeAt(oldIndex);
            _categories.insert(newIndex, item);
          });
        },
        itemBuilder: (context, index) {
          final category = _categories[index];
          return _buildM3CategoryItem(
            category['icon'],
            category['name'],
            category['count'],
            category['color'],
            index: index,
            isLast: index == _categories.length - 1,
            key: ValueKey(category['name']),
            originalColor: category['originalColor'],
            originalBackgroundColor: category['originalBackgroundColor'],
          );
        },
      );
    }

    return Column(
      children: [
        ..._categories.asMap().entries.map((entry) {
          int index = entry.key;
          Map<String, dynamic> category = entry.value;
          return _buildM3CategoryItem(
                category['icon'],
                category['name'],
                category['count'],
                category['color'],
                index: index,
                isLast: index == _categories.length - 1,
                originalColor: category['originalColor'],
                originalBackgroundColor: category['originalBackgroundColor'],
              )
              .animate()
              .fadeIn(
                duration: Duration(milliseconds: 600 + (index * 100)),
                curve: Curves.easeOutCubic,
              )
              .slideY(
                duration: Duration(milliseconds: 500 + (index * 100)),
                curve: Curves.easeOutCubic,
                begin: 0.3,
                end: 0.0,
              );
        }),
      ],
    );
  }

  // Get distinct colors for each category using Material 3 design language
  Color _getCategoryColor(int index) {
    return Material3ColorSystem.getCategoryColor(index);
  }

  Color _getCategoryBackgroundColor(int index) {
    return Material3ColorSystem.getCategoryBackgroundColor(index);
  }

  Widget _buildM3CategoryItem(
    IconData icon,
    String name,
    int count,
    Color color, {
    required int index,
    bool isLast = false,
    Key? key,
    Color? originalColor,
    Color? originalBackgroundColor,
  }) {
    final categoryColor = originalColor ?? _getCategoryColor(index);
    final categoryBackgroundColor =
        originalBackgroundColor ?? _getCategoryBackgroundColor(index);

    // In dark mode, use consistent background like overview cards
    final cardBackgroundColor = Theme.of(context).brightness == Brightness.dark
        ? _lightColor.withAlpha(150) // Same as overview cards
        : categoryBackgroundColor.withAlpha(120); // Colorful in light mode

    // Determine border radius based on position
    BorderRadius borderRadius;
    if (index == 0) {
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
      key: key,
      padding: EdgeInsets.only(bottom: isLast ? 0 : 2),
      child: Card(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: cardBackgroundColor,
        shape: RoundedRectangleBorder(borderRadius: borderRadius),
        child: InkWell(
          onTap: _isEditMode ? null : () => _handleCategoryTap(name),
          borderRadius: borderRadius,
          splashColor: _isEditMode ? null : categoryColor.withAlpha(31),
          highlightColor: _isEditMode ? null : categoryColor.withAlpha(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Reorder icon (only in edit mode)
                if (_isEditMode) ...[
                  ReorderableDragStartListener(
                    index: index,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _darkColor.withAlpha(41),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.drag_handle_rounded,
                        color: _darkColor,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                // Category icon (only in non-edit mode)
                if (!_isEditMode) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: categoryColor.withAlpha(41),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(icon, color: categoryColor, size: 20),
                  ),
                  const SizedBox(width: 16),
                ],
                Expanded(
                  child: Text(
                    name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: _highContrastDarkBlue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (count > 0) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: categoryColor.withAlpha(31),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      count.toString(),
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: categoryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                // Edit mode action icons
                if (_isEditMode) ...[
                  InkWell(
                    onTap: () => _handleCategoryEdit(name, index),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _highContrastBlue.withAlpha(41),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.edit_rounded,
                        color: _highContrastBlue,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  InkWell(
                    onTap: () => _handleCategoryDelete(name, index),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Material3ColorSystem.getErrorColor(
                          Theme.of(context).brightness,
                        ).withAlpha(41),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.delete_rounded,
                        color: Material3ColorSystem.getErrorColor(
                          Theme.of(context).brightness,
                        ),
                        size: 20,
                      ),
                    ),
                  ),
                ] else ...[
                  Icon(
                    Icons.chevron_right_rounded,
                    color: categoryColor,
                    size: 20,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildM3InsightsSection() {
    if (_isLoading) {
      return Card(
        elevation: 0,
        color: _lightColor.withAlpha(150),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: const Padding(
          padding: EdgeInsets.all(32.0),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return Card(
          elevation: 0,
          margin: EdgeInsets.zero,
          color: _lightColor.withAlpha(150),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // M3 Expressive Header
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Spending Insights',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  color: _highContrastDarkBlue,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: -0.5,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Monthly breakdown by category',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: _darkColor.withAlpha(179),
                                  fontWeight: FontWeight.w400,
                                ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: _userSelectedColor.withAlpha(100),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _userSelectedColor.withAlpha(120),
                          width: 1.5,
                        ),
                      ),
                      child: IconButton(
                        onPressed: () => _handleInsightsFilter(),
                        icon: Icon(
                          Icons.tune_rounded,
                          size: 20,
                          color: _darkColor,
                        ),
                        style: IconButton.styleFrom(
                          padding: const EdgeInsets.all(12),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                // M3 Expressive Chart Content
                RepaintBoundary(child: _buildM3ExpressiveChart()),
                if (_subscriptions.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _buildM3ExpressiveAxisLabels(),
                ],
              ],
            ),
          ),
        )
        .animate()
        .fadeIn(
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeOutCubic,
        )
        .slideY(
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeOutCubic,
          begin: 0.3,
          end: 0.0,
        );
  }

  Widget _buildM3ExpressiveChart() {
    if (_subscriptions.isEmpty) {
      return Container(
        constraints: const BoxConstraints(minHeight: 160, maxHeight: 180),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Material3ColorSystem.getPrimaryColor(
                Theme.of(context).brightness,
              ).withAlpha(25),
              Material3ColorSystem.getSecondaryColor(
                Theme.of(context).brightness,
              ).withAlpha(20),
              Material3ColorSystem.getTertiaryColor(
                Theme.of(context).brightness,
              ).withAlpha(15),
            ],
          ),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: Material3ColorSystem.getPrimaryColor(
              Theme.of(context).brightness,
            ).withAlpha(40),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Material3ColorSystem.getPrimaryColor(
                Theme.of(context).brightness,
              ).withAlpha(15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Enhanced background pattern
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  color: Colors.transparent,
                ),
                child: CustomPaint(
                  painter: _EnhancedInsightsPatternPainter(
                    color: Material3ColorSystem.getPrimaryColor(
                      Theme.of(context).brightness,
                    ).withAlpha(12),
                  ),
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Enhanced icon with glow effect
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Material3ColorSystem.getPrimaryColor(
                            Theme.of(context).brightness,
                          ).withAlpha(50),
                          Material3ColorSystem.getSecondaryColor(
                            Theme.of(context).brightness,
                          ).withAlpha(40),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Material3ColorSystem.getPrimaryColor(
                            Theme.of(context).brightness,
                          ).withAlpha(30),
                          blurRadius: 12,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.analytics_outlined,
                      size: 28,
                      color: Material3ColorSystem.getPrimaryColor(
                        Theme.of(context).brightness,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Enhanced title with better typography
                  Text(
                    'No Insights Yet',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: _highContrastDarkBlue,
                      fontWeight: FontWeight
                          .w500, // Material 3: medium weight for titles
                      letterSpacing: -0.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  // Enhanced subtitle
                  Text(
                    'Add subscriptions to see spending patterns',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: _darkColor.withAlpha(179),
                      fontWeight: FontWeight
                          .w400, // Material 3: regular weight for body text
                      height: 1.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Calculate category spending (only active subscriptions)
    Map<String, double> categorySpending = {};
    for (final subscription in _subscriptions) {
      // Only include active subscriptions in the chart
      if (subscription.status == 'active') {
        final category = subscription.category;
        final monthlyAmount = _getMonthlyAmount(subscription);
        categorySpending[category] =
            (categorySpending[category] ?? 0) + monthlyAmount;
      }
    }

    // Find max spending for scaling
    double maxSpending = 0;
    for (final spending in categorySpending.values) {
      if (spending > maxSpending) {
        maxSpending = spending;
      }
    }

    if (maxSpending == 0) maxSpending = 100;

    // Build chart bars
    List<Widget> chartBars = [];
    for (int i = 0; i < _categories.length; i++) {
      final categoryName = _categories[i]['name'].toString();
      final spending = categorySpending[categoryName] ?? 0.0;

      if (spending > 0) {
        chartBars.add(
          _buildM3ExpressiveChartBar(
            categoryName,
            spending,
            maxSpending,
            i,
            categoryColor: _categories[i]['originalColor'],
            categoryBackgroundColor: _categories[i]['originalBackgroundColor'],
          ),
        );
      }
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _backgroundColor.withAlpha(80),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _lightColor.withAlpha(100), width: 1),
      ),
      child: Column(
        children: chartBars.isEmpty
            ? [
                const SizedBox(height: 40),
                Icon(
                  Icons.bar_chart_rounded,
                  size: 48,
                  color: _darkColor.withAlpha(102),
                ),
                const SizedBox(height: 16),
                Text(
                  'No category data available',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: _darkColor.withAlpha(153),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 40),
              ]
            : [
                for (int i = 0; i < chartBars.length; i++) ...[
                  chartBars[i],
                  if (i < chartBars.length - 1) const SizedBox(height: 20),
                ],
              ],
      ),
    );
  }

  Widget _buildM3ExpressiveChartBar(
    String categoryName,
    double spending,
    double maxSpending,
    int index, {
    Color? categoryColor,
    Color? categoryBackgroundColor,
  }) {
    final finalCategoryColor = categoryColor ?? _getCategoryColor(index);
    final finalCategoryBackgroundColor =
        categoryBackgroundColor ?? _getCategoryBackgroundColor(index);
    final barWidth = spending / maxSpending;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category label and amount
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        finalCategoryColor.withAlpha(120),
                        finalCategoryColor.withAlpha(80),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: finalCategoryColor.withAlpha(40),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(
                    _categories[index]['icon'] as IconData,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  categoryName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: _highContrastDarkBlue,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    finalCategoryColor.withAlpha(100),
                    finalCategoryColor.withAlpha(60),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: finalCategoryColor.withAlpha(80),
                  width: 1,
                ),
              ),
              child: Text(
                '€${spending.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: finalCategoryColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Expressive progress bar
        Container(
          height: 12,
          decoration: BoxDecoration(
            color: finalCategoryBackgroundColor.withAlpha(60),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Stack(
            children: [
              Container(
                width: double.infinity,
                height: 12,
                decoration: BoxDecoration(
                  color: finalCategoryBackgroundColor.withAlpha(80),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: barWidth,
                child: Container(
                  height: 12,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        finalCategoryColor,
                        finalCategoryColor.withAlpha(200),
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(
                        color: finalCategoryColor.withAlpha(60),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Percentage indicator
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${(barWidth * 100).toStringAsFixed(1)}% of total',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: _darkColor.withAlpha(153),
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '${(spending / _getTotalSpending() * 100).toStringAsFixed(1)}% of budget',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: finalCategoryColor.withAlpha(179),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildM3ExpressiveAxisLabels() {
    final totalSpending = _getTotalSpending();
    final maxCategorySpending = _getMaxCategorySpending();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_lightColor.withAlpha(100), _backgroundColor.withAlpha(80)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _lightColor.withAlpha(120), width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildAxisLabelItem(
            icon: Icons.euro_rounded,
            label: 'Total Monthly',
            value: '€${totalSpending.toStringAsFixed(2)}',
            color: _highContrastBlue,
          ),
          Container(width: 1, height: 40, color: _darkColor.withAlpha(51)),
          _buildAxisLabelItem(
            icon: Icons.trending_up_rounded,
            label: 'Highest Category',
            value: '€${maxCategorySpending.toStringAsFixed(2)}',
            color: _darkColor,
          ),
          Container(width: 1, height: 40, color: _darkColor.withAlpha(51)),
          _buildAxisLabelItem(
            icon: Icons.category_rounded,
            label: 'Categories',
            value: _getActiveCategoriesCount().toString(),
            color: _userSelectedColor,
          ),
        ],
      ),
    );
  }

  Widget _buildAxisLabelItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withAlpha(41),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: _highContrastDarkBlue,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: _darkColor.withAlpha(153),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  double _getTotalSpending() {
    double total = 0;
    for (final subscription in _subscriptions) {
      // Only include active subscriptions in the total calculation
      if (subscription.status == 'active') {
        total += _getMonthlyAmount(subscription);
      }
    }
    return total;
  }

  double _getMaxCategorySpending() {
    Map<String, double> categorySpending = {};
    for (final subscription in _subscriptions) {
      // Only include active subscriptions in category spending calculations
      if (subscription.status == 'active') {
        final category = subscription.category;
        final monthlyAmount = _getMonthlyAmount(subscription);
        categorySpending[category] =
            (categorySpending[category] ?? 0) + monthlyAmount;
      }
    }

    double maxSpending = 0;
    for (final spending in categorySpending.values) {
      if (spending > maxSpending) {
        maxSpending = spending;
      }
    }
    return maxSpending;
  }

  int _getActiveCategoriesCount() {
    Map<String, double> categorySpending = {};
    for (final subscription in _subscriptions) {
      // Only include active subscriptions in category calculations
      if (subscription.status == 'active') {
        final category = subscription.category;
        final monthlyAmount = _getMonthlyAmount(subscription);
        categorySpending[category] =
            (categorySpending[category] ?? 0) + monthlyAmount;
      }
    }

    return categorySpending.values.where((spending) => spending > 0).length;
  }

  Widget _buildM3PausedFinishedSection() {
    if (_isLoading) {
      return Card(
        elevation: 0,
        color: _lightColor.withAlpha(150),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: const Padding(
          padding: EdgeInsets.all(32.0),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return Column(
      children: [
        // Paused Subscriptions
        if (_pausedSubscriptions.isNotEmpty) ...[
          _buildPausedFinishedCard(
            icon: Icons.pause_circle_filled_rounded,
            title: 'Paused',
            subtitle: 'Temporarily suspended payables',
            count: _pausedSubscriptions.length,
            color: Material3ColorSystem.getTertiaryColor(
              Theme.of(context).brightness,
            ), // Tertiary for paused
            subscriptions: _pausedSubscriptions,
            isFirst: true,
            isLast: _finishedSubscriptions.isEmpty,
          ),
          if (_finishedSubscriptions.isNotEmpty) const SizedBox(height: 2),
        ],
        // Finished Subscriptions
        if (_finishedSubscriptions.isNotEmpty) ...[
          _buildPausedFinishedCard(
            icon: Icons.check_circle_rounded,
            title: 'Finished',
            subtitle: 'Completed or expired payables',
            count: _finishedSubscriptions.length,
            color: Material3ColorSystem.getSecondaryColor(
              Theme.of(context).brightness,
            ), // Secondary for finished
            subscriptions: _finishedSubscriptions,
            isFirst: _pausedSubscriptions.isEmpty,
            isLast: true,
          ),
        ],
      ],
    );
  }

  Widget _buildPausedFinishedCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required int count,
    required Color color,
    required List<Subscription> subscriptions,
    required bool isFirst,
    required bool isLast,
  }) {
    // Determine border radius based on position
    BorderRadius borderRadius;
    if (isFirst && isLast) {
      // Single card: 24px all corners
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

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: _lightColor.withAlpha(150),
      shape: RoundedRectangleBorder(borderRadius: borderRadius),
      child: InkWell(
        onTap: () => _handlePausedFinishedTap(title, subscriptions),
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
                        color: _highContrastDarkBlue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: _darkColor,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: color.withAlpha(31),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  count.toString(),
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildM3PopupMenu() {
    final brightness = Theme.of(context).brightness;

    return PopupMenuButton<String>(
      icon: Container(
        width: 40, // Material 3: 40dp touch target
        height: 40,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.transparent,
        ),
        child: Icon(
          Icons.more_vert_rounded,
          color: Material3ColorSystem.getOnSurfaceColor(brightness),
          size: 24, // Material 3: 24dp icon size
        ),
      ),
      splashRadius: 20, // Material 3: 20dp splash radius
      offset: const Offset(
        0,
        16,
      ), // Material 3: 16dp offset from trigger for better spacing
      position: PopupMenuPosition.under, // Ensure menu appears below the icon
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4), // Material 3: 4dp corner radius
      ),
      elevation: 3, // Material 3: 3dp elevation
      color: Material3ColorSystem.getSurfaceVariantColor(
        brightness,
      ), // Material 3: surface container
      surfaceTintColor: Material3ColorSystem.getSurfaceTintColor(
        brightness,
      ), // Material 3: surface tint
      shadowColor: Material3ColorSystem.getShadowColor(
        brightness,
      ), // Material 3: shadow color
      constraints: const BoxConstraints(
        minWidth: 112, // Material 3: 112dp minimum width
        maxWidth: 280, // Material 3: 280dp maximum width
      ),
      // Material 3 expressive transitions with enhanced easing and duration
      popUpAnimationStyle: AnimationStyle(
        duration: const Duration(
          milliseconds: 300,
        ), // Material 3: 300ms for emphasis
        reverseDuration: const Duration(
          milliseconds: 250,
        ), // Material 3: 250ms reverse for emphasis
        curve: Curves
            .easeInOutCubicEmphasized, // Material 3: emphasized easing for emphasis
        reverseCurve:
            Curves.easeInCubic, // Material 3: ease-in-cubic for reverse
      ),
      onSelected: (String value) async {
        switch (value) {
          case 'add':
            _showAddOptionsBottomSheet();
            break;
          case 'edit':
            setState(() {
              _isEditMode = !_isEditMode;
            });
            break;
          case 'hide_panel':
            _showHidePanelBottomSheet();
            break;
          case 'settings':
            if (!mounted) return;
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SettingsScreen()),
            );
            // Refresh data when returning from settings
            if (result == true) {
              await _refreshDashboardWithDelay();
            }
        }
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        _buildM3PopupMenuItem(
          value: 'add',
          text: 'Add',
          icon: Icons.add_circle_rounded,
          color: Material3ColorSystem.getPrimaryColor(
            Theme.of(context).brightness,
          ),
        ),
        _buildM3PopupMenuItem(
          value: 'edit',
          text: _isEditMode ? 'Done Editing' : 'Edit',
          icon: _isEditMode ? Icons.check_circle_rounded : Icons.edit_rounded,
          color: Material3ColorSystem.getSecondaryColor(
            Theme.of(context).brightness,
          ),
        ),
        _buildM3PopupMenuItem(
          value: 'hide_panel',
          text: 'Hide Panel',
          icon: Icons.visibility_off_rounded,
          color: Material3ColorSystem.getTertiaryColor(
            Theme.of(context).brightness,
          ),
        ),
        _buildM3PopupMenuItem(
          value: 'settings',
          text: 'Settings',
          icon: Icons.settings_rounded,
          color: Material3ColorSystem.getOnSurfaceColor(
            Theme.of(context).brightness,
          ),
        ),
      ],
    );
  }

  PopupMenuEntry<String> _buildM3PopupMenuItem({
    required String value,
    required String text,
    required IconData icon,
    required Color color,
  }) {
    final brightness = Theme.of(context).brightness;

    return PopupMenuItem<String>(
      value: value,
      // Material 3 List Item Specifications
      height: 48, // Material 3: 48dp list item height
      padding: const EdgeInsets.symmetric(
        horizontal: 16, // Material 3: 16dp horizontal padding
        vertical: 8, // Material 3: 8dp vertical padding
      ),
      // Material 3 interaction states
      mouseCursor: SystemMouseCursors.click, // Hover state cursor
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: null, // Handled by PopupMenuItem
          borderRadius: BorderRadius.circular(
            4,
          ), // Material 3: 4dp corner radius
          splashColor: Material3ColorSystem.getPrimaryColor(
            brightness,
          ).withValues(alpha: 0.12), // Material 3: 12% primary color splash
          highlightColor: Material3ColorSystem.getPrimaryColor(
            brightness,
          ).withValues(alpha: 0.08), // Material 3: 8% primary color highlight
          child: Row(
            children: [
              // Leading icon with Material 3 color roles
              Icon(
                icon,
                color: color, // Use the semantic color passed from menu items
                size: 24, // Material 3: 24dp icon size
              ),
              const SizedBox(
                width: 12,
              ), // Material 3: 12dp spacing between icon and text
              Expanded(
                child: Text(
                  text,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w400, // Material 3: regular weight
                    color: Material3ColorSystem.getOnSurfaceColor(
                      brightness,
                    ), // Material 3: on-surface
                  ),
                  textAlign: TextAlign.start,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Handler methods
  void _handleOverviewCardTap(String title) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            SubscriptionScreen(categories: _categories, title: title),
      ),
    );

    // Refresh dashboard data for any relevant changes
    if (result == 'categories_updated' ||
        result == 'deleted' ||
        result == 'status_updated' ||
        result == 'duplicated' ||
        result == true) {
      await _refreshDashboardWithDelay();
    }
  }

  void _handlePausedFinishedTap(
    String title,
    List<Subscription> subscriptions,
  ) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            SubscriptionScreen(categories: _categories, title: title),
      ),
    );

    // Refresh dashboard data for any relevant changes
    if (result == 'categories_updated' ||
        result == 'deleted' ||
        result == 'status_updated' ||
        result == 'duplicated' ||
        result == true) {
      await _refreshDashboardWithDelay();
    }
  }

  void _showAddOptionsBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: _backgroundColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Bottom sheet handle
                Center(
                  child: Container(
                    width: 32,
                    height: 4,
                    decoration: BoxDecoration(
                      color: _darkColor.withAlpha(102),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Title Section
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _darkColor.withAlpha(41),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.add_circle_outline_rounded,
                        color: _darkColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Add New',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w500,
                                  color: _highContrastDarkBlue,
                                  letterSpacing: -0.5,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'What would you like to add?',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: _darkColor.withAlpha(179),
                                  fontWeight: FontWeight.w400,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Options
                _buildAddOptionCard(
                  title: 'Payable',
                  subtitle: 'Add a new subscription or bill',
                  icon: Icons.post_add_rounded,
                  color: _highContrastBlue,
                  onTap: () {
                    Navigator.pop(context); // Close bottom sheet
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            AddSubsScreen(categories: _categories),
                      ),
                    ).then((result) async {
                      // Reload subscription data if a new one was added, edited, or duplicated
                      if (result == true ||
                          result == 'categories_updated' ||
                          result == 'duplicated' ||
                          result == 'status_updated') {
                        await _refreshDashboardWithDelay();
                      }
                    });
                  },
                  isFirst: true,
                  isLast: false,
                ),
                const SizedBox(height: 2),
                _buildAddOptionCard(
                  title: 'Category',
                  subtitle: 'Create a new category for payables',
                  icon: Icons.create_new_folder_outlined,
                  color: _darkColor,
                  onTap: () {
                    Navigator.pop(context); // Close bottom sheet
                    _handleCategoryAdd();
                  },
                  isFirst: false,
                  isLast: true,
                ),

                SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAddOptionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
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
      color: _lightColor.withAlpha(150),
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
                        color: _highContrastDarkBlue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: _darkColor,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: color, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _handleCategoryTap(String categoryName) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            SubscriptionScreen(categories: _categories, title: categoryName),
      ),
    );

    // Refresh dashboard data for any relevant changes
    if (result == 'categories_updated' ||
        result == 'deleted' ||
        result == 'status_updated' ||
        result == 'duplicated' ||
        result == true) {
      await _refreshDashboardWithDelay();
    }
  }

  void _handleCategoryAdd() {
    // Controllers for editing
    final nameController = TextEditingController();
    IconData selectedIcon = Icons.category_rounded;
    Color selectedColor = const Color(0xFF6750A4);
    Color selectedBackgroundColor = const Color(0xFFEADDFF);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.9,
          decoration: BoxDecoration(
            color: _backgroundColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
          ),
          child: Column(
            children: [
              // Bottom sheet handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 32,
                height: 4,
                decoration: BoxDecoration(
                  color: _darkColor.withAlpha(102),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: selectedColor.withAlpha(41),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(selectedIcon, color: selectedColor, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Add Category',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w500,
                                  color: _highContrastDarkBlue,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Create a new category',
                            style: Theme.of(
                              context,
                            ).textTheme.bodyMedium?.copyWith(color: _darkColor),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name input
                      _buildEditSectionNoIcon(
                        'Category Name',
                        TextField(
                          controller: nameController,
                          decoration: InputDecoration(
                            hintText: 'Enter category name',
                            filled: true,
                            fillColor: _lightColor.withAlpha(100),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: _darkColor.withAlpha(51),
                                width: 1,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: selectedColor,
                                width: 2,
                              ),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: Material3ColorSystem.getErrorColor(
                                  Theme.of(context).brightness,
                                ),
                                width: 1,
                              ),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: Material3ColorSystem.getErrorColor(
                                  Theme.of(context).brightness,
                                ),
                                width: 2,
                              ),
                            ),
                            disabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Icon selection
                      _buildEditSectionNoIcon(
                        'Choose Icon',
                        _buildIconSelector(selectedIcon, selectedColor, () {
                          _showIconSelectionDialog(context, selectedIcon, (
                            icon,
                          ) {
                            setModalState(() {
                              selectedIcon = icon;
                            });
                          }, selectedColor);
                        }),
                      ),
                      const SizedBox(height: 32),
                      // Color selection
                      _buildEditSectionNoIcon(
                        'Choose Color',
                        _buildColorSelector(
                          selectedColor,
                          selectedBackgroundColor,
                          (color, bgColor) {
                            setModalState(() {
                              selectedColor = color;
                              selectedBackgroundColor = bgColor;
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Add bottom padding for navigation bar
                      SizedBox(height: MediaQuery.of(context).padding.bottom),
                    ],
                  ),
                ),
              ),
              // Actions
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: _lightColor.withAlpha(50),
                  border: Border(
                    top: BorderSide(color: _darkColor.withAlpha(51), width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          side: BorderSide(color: _darkColor),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(color: _darkColor),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: FilledButton(
                        onPressed: () async {
                          final categoryName = nameController.text.trim();

                          // Validate input
                          if (categoryName.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    Icon(
                                      Icons.error_rounded,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Category name cannot be empty',
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                                backgroundColor:
                                    Material3ColorSystem.getErrorColor(
                                      Theme.of(context).brightness,
                                    ),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                margin: const EdgeInsets.all(16),
                              ),
                            );
                            return;
                          }

                          // Check if category already exists
                          final existingCategory = _categories.firstWhere(
                            (cat) => cat['name'] == categoryName,
                            orElse: () => {},
                          );
                          if (existingCategory.isNotEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    Icon(
                                      Icons.error_rounded,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Category already exists',
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                                backgroundColor:
                                    Material3ColorSystem.getErrorColor(
                                      Theme.of(context).brightness,
                                    ),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                margin: const EdgeInsets.all(16),
                              ),
                            );
                            return;
                          }

                          Navigator.pop(context);

                          // Save category customizations to preferences database
                          await CategoryPreferencesDatabase.saveCategoryCustomization(
                            categoryName: categoryName,
                            iconCodePoint: selectedIcon.codePoint,
                            colorValue: selectedColor.toARGB32(),
                            backgroundColorValue: selectedBackgroundColor
                                .toARGB32(),
                          );

                          // Add the new category to the local state
                          setState(() {
                            _categories.add({
                              'name': categoryName,
                              'icon': selectedIcon,
                              'originalColor': selectedColor,
                              'originalBackgroundColor':
                                  selectedBackgroundColor,
                              'count': 0,
                              'color': Material3ColorSystem.getPrimaryColor(
                                Theme.of(context).brightness,
                              ),
                            });
                          });

                          // Refresh dashboard to ensure all data is up to date
                          await _refreshDashboardWithDelay();

                          // Show success message
                          if (context.mounted) {
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
                                      'Category added successfully',
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                                backgroundColor:
                                    Material3ColorSystem.getTertiaryColor(
                                      Theme.of(context).brightness,
                                    ),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                margin: const EdgeInsets.all(16),
                              ),
                            );
                          }
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: selectedColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Add Category',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Add bottom padding for navigation bar
              SizedBox(height: MediaQuery.of(context).padding.bottom),
            ],
          ),
        ),
      ),
    );
  }

  void _handleCategoryEdit(String categoryName, int index) {
    final category = _categories[index];

    // Controllers for editing
    final nameController = TextEditingController(text: categoryName);
    IconData selectedIcon = category['icon'] as IconData;
    Color selectedColor = category['originalColor'] as Color;
    Color selectedBackgroundColor =
        category['originalBackgroundColor'] as Color;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.9,
          decoration: BoxDecoration(
            color: _backgroundColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
          ),
          child: Column(
            children: [
              // Bottom sheet handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 32,
                height: 4,
                decoration: BoxDecoration(
                  color: _darkColor.withAlpha(102),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: selectedColor.withAlpha(41),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(selectedIcon, color: selectedColor, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Edit Category',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w500,
                                  color: _highContrastDarkBlue,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Customize name, icon, and color',
                            style: Theme.of(
                              context,
                            ).textTheme.bodyMedium?.copyWith(color: _darkColor),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name input
                      _buildEditSectionNoIcon(
                        'Category Name',
                        TextField(
                          controller: nameController,
                          decoration: InputDecoration(
                            hintText: 'Enter category name',
                            filled: true,
                            fillColor: _lightColor.withAlpha(100),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: _darkColor.withAlpha(51),
                                width: 1,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: selectedColor,
                                width: 2,
                              ),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: Material3ColorSystem.getErrorColor(
                                  Theme.of(context).brightness,
                                ),
                                width: 1,
                              ),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: Material3ColorSystem.getErrorColor(
                                  Theme.of(context).brightness,
                                ),
                                width: 2,
                              ),
                            ),
                            disabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Icon selection
                      _buildEditSectionNoIcon(
                        'Choose Icon',
                        _buildIconSelector(selectedIcon, selectedColor, () {
                          _showIconSelectionDialog(context, selectedIcon, (
                            icon,
                          ) {
                            setModalState(() {
                              selectedIcon = icon;
                            });
                          }, selectedColor);
                        }),
                      ),
                      const SizedBox(height: 32),
                      // Color selection
                      _buildEditSectionNoIcon(
                        'Choose Color',
                        _buildColorSelector(
                          selectedColor,
                          selectedBackgroundColor,
                          (color, bgColor) {
                            setModalState(() {
                              selectedColor = color;
                              selectedBackgroundColor = bgColor;
                            });
                          },
                          categoryName: nameController.text.trim(),
                          categoryIcon: selectedIcon,
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Add bottom padding for navigation bar
                      SizedBox(height: MediaQuery.of(context).padding.bottom),
                    ],
                  ),
                ),
              ),
              // Actions
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: _lightColor.withAlpha(50),
                  border: Border(
                    top: BorderSide(color: _darkColor.withAlpha(51), width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          side: BorderSide(color: _darkColor),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(color: _darkColor),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: FilledButton(
                        onPressed: () async {
                          final oldCategoryName = categoryName;
                          final newCategoryName = nameController.text.trim();

                          // Validate input
                          if (newCategoryName.isEmpty) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      Icon(
                                        Icons.error_rounded,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        'Category name cannot be empty',
                                        style: const TextStyle(
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                  backgroundColor:
                                      Material3ColorSystem.getErrorColor(
                                        Theme.of(context).brightness,
                                      ),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  margin: const EdgeInsets.all(16),
                                ),
                              );
                            }
                            return;
                          }

                          // Check if the new name conflicts with existing categories
                          final existingCategory = _categories.firstWhere(
                            (cat) =>
                                cat['name'] == newCategoryName &&
                                cat['name'] != oldCategoryName,
                            orElse: () => {},
                          );
                          if (existingCategory.isNotEmpty) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      Icon(
                                        Icons.error_rounded,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        'Category name already exists',
                                        style: const TextStyle(
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                  backgroundColor:
                                      Material3ColorSystem.getErrorColor(
                                        Theme.of(context).brightness,
                                      ),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  margin: const EdgeInsets.all(16),
                                ),
                              );
                            }
                            return;
                          }

                          Navigator.pop(context);

                          // Update all subscriptions in this category with the new color and name
                          try {
                            // First update the color
                            await SubscriptionDatabase.updateCategoryColor(
                              oldCategoryName,
                              selectedColor.toARGB32(),
                            );

                            // If the category name changed, also update the category name for all subscriptions
                            if (oldCategoryName != newCategoryName) {
                              await SubscriptionDatabase.updateCategoryForSubscriptions(
                                oldCategoryName,
                                newCategoryName,
                              );
                            }

                            // Save category customizations to preferences database
                            await CategoryPreferencesDatabase.saveCategoryCustomization(
                              categoryName: newCategoryName,
                              iconCodePoint: selectedIcon.codePoint,
                              colorValue: selectedColor.value,
                              backgroundColorValue:
                                  selectedBackgroundColor.value,
                            );
                          } catch (e) {
                            // Show error message
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      Icon(
                                        Icons.error_rounded,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        'Error updating category: ${e.toString()}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                  backgroundColor:
                                      Material3ColorSystem.getErrorColor(
                                        Theme.of(context).brightness,
                                      ),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  margin: const EdgeInsets.all(16),
                                ),
                              );
                            }
                            return;
                          }

                          // Update the local state after successful database operations
                          setState(() {
                            _categories[index] = {
                              ..._categories[index],
                              'name': newCategoryName,
                              'icon': selectedIcon,
                              'originalColor': selectedColor,
                              'originalBackgroundColor':
                                  selectedBackgroundColor,
                            };
                          });

                          // Refresh dashboard data to update counts and ensure consistency
                          await _refreshDashboardData();

                          // Show success message
                          if (context.mounted) {
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
                                      'Category updated successfully',
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                                backgroundColor:
                                    Material3ColorSystem.getTertiaryColor(
                                      Theme.of(context).brightness,
                                    ),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                margin: const EdgeInsets.all(16),
                              ),
                            );
                          }
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: selectedColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Save Changes',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Add bottom padding for navigation bar
              SizedBox(height: MediaQuery.of(context).padding.bottom),
            ],
          ),
        ),
      ),
    );
  }

  void _handleCategoryDelete(String categoryName, int index) {
    // Show confirmation dialog before deleting
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: _backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Material3ColorSystem.getErrorColor(
                    Theme.of(context).brightness,
                  ).withAlpha(41),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.delete_rounded,
                  color: Material3ColorSystem.getErrorColor(
                    Theme.of(context).brightness,
                  ),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'Delete Category',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: _highContrastDarkBlue,
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
                'Are you sure you want to delete the "$categoryName" category?',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: _darkColor,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Material3ColorSystem.getErrorColor(
                    Theme.of(context).brightness,
                  ).withAlpha(31),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Material3ColorSystem.getErrorColor(
                      Theme.of(context).brightness,
                    ).withAlpha(80),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_rounded,
                      color: Material3ColorSystem.getErrorColor(
                        Theme.of(context).brightness,
                      ),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'This action cannot be undone.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Material3ColorSystem.getErrorColor(
                            Theme.of(context).brightness,
                          ),
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
              onPressed: () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                side: BorderSide(color: _darkColor),
              ),
              child: Text('Cancel', style: TextStyle(color: _darkColor)),
            ),
            const SizedBox(width: 12),
            FilledButton(
              onPressed: () async {
                // For all categories (both default and custom), update subscriptions first, then hide the category
                try {
                  await SubscriptionDatabase.updateCategoryForSubscriptions(
                    categoryName,
                    'Not set',
                  );

                  // Hide the category in preferences database
                  await CategoryPreferencesDatabase.hideCategory(categoryName);

                  // Remove from UI after successful database update
                  setState(() {
                    _categories.removeWhere(
                      (cat) => cat['name'] == categoryName,
                    );
                  });
                } catch (e) {
                  // Show error message
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            Icon(
                              Icons.error_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Error updating subscriptions: ${e.toString()}',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                        backgroundColor: Material3ColorSystem.getErrorColor(
                          Theme.of(context).brightness,
                        ),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        margin: const EdgeInsets.all(16),
                      ),
                    );
                  }
                  return;
                }

                // Close the dialog
                if (context.mounted) {
                  Navigator.of(context).pop();
                }

                // Refresh dashboard to ensure all data is up to date
                await _refreshDashboardWithDelay();

                // Show success message
                if (context.mounted) {
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
                            'Category "$categoryName" deleted successfully',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                      backgroundColor: Material3ColorSystem.getTertiaryColor(
                        Theme.of(context).brightness,
                      ),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      margin: const EdgeInsets.all(16),
                    ),
                  );
                }
              },
              style: FilledButton.styleFrom(
                backgroundColor: Material3ColorSystem.getErrorColor(
                  Theme.of(context).brightness,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void _handleInsightsFilter() {}

  Widget _buildEditSectionNoIcon(String title, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: _highContrastDarkBlue,
          ),
        ),
        const SizedBox(height: 16),
        content,
      ],
    );
  }

  Widget _buildIconSelector(
    IconData selectedIcon,
    Color selectedColor,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _lightColor.withAlpha(100),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selectedColor.withAlpha(51), width: 1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: selectedColor.withAlpha(41),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(selectedIcon, color: selectedColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                'Tap to change icon',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: _darkColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: _darkColor, size: 20),
          ],
        ),
      ),
    );
  }

  void _showIconSelectionDialog(
    BuildContext context,
    IconData selectedIcon,
    Function(IconData) onIconSelected,
    Color selectedColor,
  ) {
    final searchController = TextEditingController();

    // Map icons to searchable terms for better search experience
    final Map<IconData, String> iconSearchTerms = {
      Icons.cloud_upload_rounded: 'cloud upload storage sync backup',
      Icons.play_circle_filled_rounded: 'play video entertainment media music',
      Icons.fitness_center_rounded: 'fitness gym health exercise workout',
      Icons.local_hospital_rounded: 'hospital medical health doctor',
      Icons.account_balance_wallet_rounded: 'wallet money finance payment card',
      Icons.code_rounded: 'code programming development tech',
      Icons.directions_car_rounded: 'car transport vehicle travel',
      Icons.bolt_rounded: 'bolt lightning power energy electricity',
      Icons.shopping_bag_rounded: 'shopping bag retail store purchase',
      Icons.restaurant_rounded: 'restaurant food dining eating',
      Icons.home_rounded: 'home house building residence',
      Icons.school_rounded: 'school education learning university',
      Icons.medical_services_rounded: 'medical health doctor hospital',
      Icons.pets_rounded: 'pets animals dog cat',
      Icons.flight_rounded: 'flight airplane travel transport',
      Icons.music_note_rounded: 'music audio sound entertainment',
      Icons.sports_esports_rounded: 'games gaming entertainment esports',
      Icons.camera_alt_rounded: 'camera photo picture image',
      Icons.book_rounded: 'book reading education learning',
      Icons.work_rounded: 'work office business job',
      Icons.beach_access_rounded: 'beach vacation travel leisure',
      Icons.sports_basketball_rounded: 'basketball sports game exercise',
      Icons.local_gas_station_rounded: 'gas station fuel car transport',
      Icons.phone_rounded: 'phone communication call contact',
      Icons.tv_rounded: 'tv television entertainment media',
      Icons.laptop_rounded: 'laptop computer technology work',
      Icons.watch_rounded: 'watch time clock accessory',
      Icons.headphones_rounded: 'headphones audio music sound',
      Icons.mic_rounded: 'microphone audio recording sound',
      Icons.speaker_rounded: 'speaker audio sound music',
      Icons.wifi_rounded: 'wifi internet connection network',
      Icons.bluetooth_rounded: 'bluetooth wireless connection',
      Icons.battery_charging_full_rounded: 'battery power energy charging',
      Icons.flash_on_rounded: 'flash light camera photography',
      Icons.star_rounded: 'star favorite rating quality',
      Icons.favorite_rounded: 'favorite heart love like',
      Icons.thumb_up_rounded: 'thumbs up like approval good',
      Icons.share_rounded: 'share social media communication',
      Icons.download_rounded: 'download save file transfer',
      Icons.upload_rounded: 'upload share file transfer',
      Icons.refresh_rounded: 'refresh reload update sync',
      Icons.sync_rounded: 'sync synchronize update backup',
      Icons.cloud_done_rounded: 'cloud storage backup sync complete',
      Icons.folder_rounded: 'folder file storage organization',
      Icons.description_rounded: 'document file text description',
      Icons.image_rounded: 'image photo picture gallery',
      Icons.video_library_rounded: 'video media entertainment library',
      Icons.audiotrack_rounded: 'audio music sound track',
      Icons.palette_rounded: 'palette color art design creative',
      Icons.brush_rounded: 'brush paint art design creative',
      Icons.design_services_rounded: 'design creative art services',
      Icons.architecture_rounded: 'architecture building design construction',
      Icons.engineering_rounded: 'engineering technical construction',
      Icons.science_rounded: 'science research laboratory experiment',
      Icons.psychology_rounded: 'psychology mind brain mental health',
      Icons.sports_soccer_rounded: 'soccer football sports game',
      Icons.sports_tennis_rounded: 'tennis sports game racket',
      Icons.sports_golf_rounded: 'golf sports game recreation',
      Icons.directions_bike_rounded: 'bike bicycle cycling transport exercise',
      Icons.directions_walk_rounded: 'walking walk exercise health',
      Icons.directions_run_rounded: 'running run exercise fitness',
      Icons.pool_rounded: 'pool swimming water recreation',
      Icons.spa_rounded: 'spa relaxation wellness health',
      Icons.self_improvement_rounded: 'self improvement meditation wellness',
      Icons.local_cafe_rounded: 'cafe coffee shop dining',
      Icons.local_dining_rounded: 'dining restaurant food eating',
      Icons.local_pizza_rounded: 'pizza food dining restaurant',
      Icons.local_bar_rounded: 'bar drinks alcohol entertainment',
      Icons.cake_rounded: 'cake dessert food celebration birthday',
      Icons.local_grocery_store_rounded: 'grocery store shopping food',
      Icons.local_pharmacy_rounded: 'pharmacy medicine health medical',
      Icons.local_florist_rounded: 'florist flowers plants nature',
      Icons.local_mall_rounded: 'mall shopping retail store',
      Icons.local_atm_rounded: 'atm money bank finance',
      Icons.business_rounded: 'business office work corporate',
      Icons.savings_rounded: 'savings money finance bank investment',
      Icons.payments_rounded: 'payments money finance transaction',
      Icons.credit_card_rounded: 'credit card payment finance money',
      Icons.receipt_long_rounded: 'receipt payment transaction record',
      Icons.shopping_cart_rounded: 'shopping cart retail purchase',
      Icons.storefront_rounded: 'store shop retail business',
      Icons.apartment_rounded: 'apartment building housing residence',
      Icons.house_rounded: 'house home building residence',
      Icons.nature_rounded: 'nature environment ecology green',
      Icons.park_rounded: 'park recreation nature outdoor',
      Icons.forest_rounded: 'forest nature trees environment',
      Icons.eco_rounded: 'eco environment green sustainability',
      Icons.recycling_rounded: 'recycling environment sustainability green',
      Icons.solar_power_rounded: 'solar power energy renewable green',
      Icons.electric_bolt_rounded: 'electric bolt power energy lightning',
      Icons.water_drop_rounded: 'water drop hydration environment',
      Icons.local_fire_department_rounded: 'fire department emergency safety',
      Icons.ac_unit_rounded: 'air conditioning cooling temperature',
      Icons.thermostat_rounded: 'thermostat temperature heating cooling',
      Icons.light_mode_rounded: 'light mode bright day theme',
      Icons.dark_mode_rounded: 'dark mode night theme',
      Icons.wb_sunny_rounded: 'sunny sun weather bright day',
      Icons.nights_stay_rounded: 'night moon dark evening',
      Icons.celebration_rounded: 'celebration party event festive',
      Icons.card_giftcard_rounded: 'gift card present celebration',
      Icons.redeem_rounded: 'redeem reward coupon discount',
      Icons.local_activity_rounded: 'activity entertainment event fun',
      Icons.event_rounded: 'event calendar schedule appointment',
      Icons.calendar_today_rounded: 'calendar date time schedule',
      Icons.schedule_rounded: 'schedule time clock appointment',
      Icons.timer_rounded: 'timer time countdown clock',
      Icons.alarm_rounded: 'alarm clock time wake up',
      Icons.access_time_rounded: 'time clock schedule',
      Icons.update_rounded: 'update refresh new version',
      Icons.history_rounded: 'history past time record',
      Icons.trending_up_rounded: 'trending up growth increase statistics',
      Icons.trending_down_rounded: 'trending down decrease statistics',
      Icons.show_chart_rounded: 'chart graph statistics data analytics',
      Icons.analytics_rounded: 'analytics data statistics insights',
      Icons.assessment_rounded: 'assessment evaluation analysis report',
      Icons.pie_chart_rounded: 'pie chart statistics data analytics',
      Icons.bar_chart_rounded: 'bar chart statistics data analytics',
      Icons.functions_rounded: 'functions math calculation formula',
      Icons.calculate_rounded: 'calculate math computation calculator',
      Icons.percent_rounded: 'percent percentage statistics math',
      Icons.euro_rounded: 'euro money currency finance',
      Icons.attach_money_rounded: 'money dollar currency finance',
      Icons.sell_rounded: 'sell sales business commerce',
      Icons.label_rounded: 'label tag category organization',
      Icons.local_offer_rounded: 'offer deal discount promotion',
      Icons.loyalty_rounded: 'loyalty rewards membership program',
      Icons.verified_user_rounded: 'verified user security trusted',
      Icons.security_rounded: 'security protection safety privacy',
      Icons.lock_rounded: 'lock security privacy protection',
      Icons.vpn_key_rounded: 'vpn key security access',
      Icons.fingerprint_rounded: 'fingerprint security biometric identity',
      Icons.face_rounded: 'face person user profile identity',
      Icons.person_rounded: 'person user profile account',
      Icons.group_rounded: 'group people team users',
      Icons.child_friendly_rounded: 'child friendly family kids',
      Icons.accessible_rounded: 'accessible disability inclusion',
      Icons.health_and_safety_rounded: 'health safety medical protection',
      Icons.medical_information_rounded: 'medical information health data',
      Icons.healing_rounded: 'healing health recovery medical',
      Icons.emergency_rounded: 'emergency urgent critical help',
      Icons.sports_martial_arts_rounded: 'martial arts sports fighting karate',
      Icons.sports_gymnastics_rounded: 'gymnastics sports exercise flexibility',
      Icons.sports_handball_rounded: 'handball sports game team',
      Icons.sports_hockey_rounded: 'hockey sports game ice',
      Icons.sports_rugby_rounded: 'rugby sports game team',
      Icons.sports_volleyball_rounded: 'volleyball sports game beach',
      Icons.sports_cricket_rounded: 'cricket sports game bat',
      Icons.sports_baseball_rounded: 'baseball sports game american',
      Icons.sports_football_rounded: 'football sports game american',
      Icons.casino_rounded: 'casino gambling entertainment games',
      Icons.toys_rounded: 'toys games children play',
      Icons.games_rounded: 'games entertainment play fun',
      Icons.extension_rounded: 'extension plugin addon extra',
      Icons.smart_toy_rounded: 'smart toy robot ai technology',
      Icons.rocket_launch_rounded: 'rocket launch space technology',
      Icons.satellite_rounded: 'satellite space communication technology',
      Icons.public_rounded: 'public world global internet',
      Icons.language_rounded: 'language translation international',
      Icons.translate_rounded: 'translate language communication',
      Icons.location_on_rounded: 'location map gps navigation',
      Icons.map_rounded: 'map navigation location geography',
      Icons.navigation_rounded: 'navigation gps direction location',
      Icons.explore_rounded: 'explore discovery adventure travel',
      Icons.travel_explore_rounded: 'travel explore adventure vacation',
      Icons.luggage_rounded: 'luggage travel vacation suitcase',
      Icons.backpack_rounded: 'backpack travel hiking adventure',
      Icons.hiking_rounded: 'hiking outdoor adventure nature',
      Icons.cabin_rounded: 'cabin house vacation retreat',
      Icons.deck_rounded: 'deck outdoor patio house',
      Icons.hot_tub_rounded: 'hot tub spa relaxation luxury',
      Icons.water_rounded: 'water liquid hydration swimming',
      Icons.waves_rounded: 'waves ocean sea water',
      Icons.surfing_rounded: 'surfing water sports ocean',
      Icons.sailing_rounded: 'sailing boat water recreation',
      Icons.kayaking_rounded: 'kayaking water sports adventure',
      Icons.rowing_rounded: 'rowing water sports exercise',
      Icons.scuba_diving_rounded: 'scuba diving underwater sports',
      Icons.kitesurfing_rounded: 'kitesurfing water sports wind',
      Icons.snowboarding_rounded: 'snowboarding winter sports snow',
      Icons.downhill_skiing_rounded: 'skiing winter sports snow downhill',
      Icons.sledding_rounded: 'sledding winter fun snow',
      Icons.ice_skating_rounded: 'ice skating winter sports recreation',
      Icons.skateboarding_rounded: 'skateboarding sports urban recreation',
      Icons.roller_skating_rounded: 'roller skating recreation sports',
      Icons.snowmobile_rounded: 'snowmobile winter vehicle snow',
      Icons.motorcycle_rounded: 'motorcycle vehicle transport bike',
      Icons.electric_scooter_rounded: 'electric scooter transport urban',
      Icons.electric_bike_rounded: 'electric bike transport eco',
      Icons.pedal_bike_rounded: 'bike bicycle pedal transport exercise',
      Icons.train_rounded: 'train transport railway travel',
      Icons.tram_rounded: 'tram transport urban railway',
      Icons.subway_rounded: 'subway metro underground transport',
      Icons.airport_shuttle_rounded: 'airport shuttle transport travel',
      Icons.flight_takeoff_rounded: 'flight takeoff airplane travel',
      Icons.flight_land_rounded: 'flight landing airplane travel',
      Icons.connecting_airports_rounded: 'connecting airports travel flight',
      Icons.rocket_rounded: 'rocket space launch technology',
      Icons.departure_board_rounded: 'departure board travel schedule',
      Icons.trip_origin_rounded: 'trip origin location start',
      Icons.alt_route_rounded: 'alternative route navigation map',
      Icons.route_rounded: 'route navigation path direction',
      Icons.traffic_rounded: 'traffic road transport congestion',
      Icons.local_shipping_rounded: 'shipping delivery transport package',
      Icons.delivery_dining_rounded: 'delivery food dining takeout',
      Icons.takeout_dining_rounded: 'takeout food dining restaurant',
      Icons.room_service_rounded: 'room service hotel hospitality',
      Icons.restaurant_menu_rounded: 'restaurant menu food dining',
      Icons.lunch_dining_rounded: 'lunch dining food meal',
      Icons.dinner_dining_rounded: 'dinner dining food meal',
      Icons.breakfast_dining_rounded: 'breakfast dining food meal',
      Icons.brunch_dining_rounded: 'brunch dining food meal',
      Icons.ramen_dining_rounded: 'ramen noodles dining asian food',
      Icons.rice_bowl_rounded: 'rice bowl asian food dining',
      Icons.bakery_dining_rounded: 'bakery bread food dining',
      Icons.liquor_rounded: 'liquor alcohol drinks bar',
      Icons.wine_bar_rounded: 'wine bar alcohol drinks',
      Icons.sports_bar_rounded: 'sports bar entertainment drinks',
      Icons.nightlife_rounded: 'nightlife party entertainment evening',
      Icons.festival_rounded: 'festival celebration event music',
      Icons.theater_comedy_rounded: 'theater comedy entertainment show',
      Icons.movie_rounded: 'movie cinema entertainment film',
      Icons.live_tv_rounded: 'live tv television broadcast',
      Icons.personal_video_rounded: 'personal video recording camera',
      Icons.video_call_rounded: 'video call communication meeting',
      Icons.videocam_rounded: 'video camera recording film',
      Icons.video_settings_rounded: 'video settings configuration camera',
      Icons.slow_motion_video_rounded: 'slow motion video camera effect',
      Icons.video_stable_rounded: 'video stable camera recording',
      Icons.hd_rounded: 'hd high definition video quality',
      Icons.sd_rounded: 'sd standard definition video quality',
      Icons.subscriptions_rounded: 'subscriptions recurring payments',
      Icons.library_books_rounded: 'library books reading education',
      Icons.auto_stories_rounded: 'auto stories reading books',
      Icons.menu_book_rounded: 'menu book reading restaurant',
      Icons.import_contacts_rounded: 'import contacts address book',
      Icons.bookmark_rounded: 'bookmark save favorite reading',
      Icons.bookmarks_rounded: 'bookmarks saved favorites',
      Icons.library_add_rounded: 'library add collection books',
      Icons.library_music_rounded: 'library music collection audio',
      Icons.queue_music_rounded: 'queue music playlist audio',
      Icons.playlist_add_rounded: 'playlist add music audio',
      Icons.playlist_play_rounded: 'playlist play music audio',
      Icons.shuffle_rounded: 'shuffle random music audio',
      Icons.repeat_rounded: 'repeat loop music audio',
      Icons.replay_rounded: 'replay restart music audio',
      Icons.forward_rounded: 'forward next music audio',
      Icons.fast_forward_rounded: 'fast forward music audio',
      Icons.fast_rewind_rounded: 'fast rewind music audio',
      Icons.skip_next_rounded: 'skip next music audio',
      Icons.skip_previous_rounded: 'skip previous music audio',
      Icons.play_arrow_rounded: 'play start music audio video',
      Icons.pause_rounded: 'pause stop music audio video',
      Icons.stop_rounded: 'stop end music audio video',
      Icons.volume_up_rounded: 'volume up loud audio sound',
      Icons.volume_down_rounded: 'volume down quiet audio sound',
      Icons.volume_mute_rounded: 'volume mute silent audio sound',
      Icons.volume_off_rounded: 'volume off silent audio sound',
      Icons.surround_sound_rounded: 'surround sound audio speaker',
      Icons.equalizer_rounded: 'equalizer audio music settings',
      Icons.graphic_eq_rounded: 'graphic equalizer audio music',
      Icons.radio_rounded: 'radio music audio broadcast',
      Icons.campaign_rounded: 'campaign marketing promotion announcement',
      Icons.notifications_rounded: 'notifications alerts messages',
      Icons.notifications_active_rounded: 'notifications active alerts',
      Icons.notifications_off_rounded: 'notifications off silent',
      Icons.vibration_rounded: 'vibration haptic feedback phone',
      Icons.do_not_disturb_rounded: 'do not disturb silent mode',
      Icons.priority_high_rounded: 'priority high important urgent',
      Icons.report_rounded: 'report issue problem feedback',
      Icons.flag_rounded: 'flag country location marker',
      Icons.outlined_flag_rounded: 'outlined flag marker location',
      Icons.tour_rounded: 'tour guide travel sightseeing',
      Icons.info_rounded: 'info information help details',
      Icons.help_rounded: 'help support assistance question',
      Icons.support_rounded: 'support help assistance customer',
      Icons.contact_support_rounded: 'contact support help assistance',
      Icons.quiz_rounded: 'quiz test question assessment',
      Icons.live_help_rounded: 'live help chat support',
      Icons.feedback_rounded: 'feedback review comment opinion',
      Icons.rate_review_rounded: 'rate review rating feedback',
      Icons.reviews_rounded: 'reviews ratings feedback comments',
      Icons.comment_rounded: 'comment message feedback discussion',
      Icons.chat_rounded: 'chat conversation message communication',
      Icons.chat_bubble_rounded: 'chat bubble message conversation',
      Icons.forum_rounded: 'forum discussion community conversation',
      Icons.question_answer_rounded: 'question answer help support',
      Icons.contact_phone_rounded: 'contact phone call communication',
      Icons.contact_mail_rounded: 'contact mail email communication',
      Icons.contacts_rounded: 'contacts address book people',
      Icons.recent_actors_rounded: 'recent actors people contacts',
      Icons.people_rounded: 'people group users contacts',
      Icons.people_alt_rounded: 'people alternative group users',
      Icons.people_outline_rounded: 'people outline group users',
      Icons.person_add_rounded: 'person add contact user new',
      Icons.person_remove_rounded: 'person remove contact user delete',
      Icons.person_search_rounded: 'person search find user contact',
      Icons.supervisor_account_rounded: 'supervisor account manager admin',
      Icons.admin_panel_settings_rounded: 'admin panel settings control',
      Icons.manage_accounts_rounded: 'manage accounts users administration',
      Icons.account_box_rounded: 'account box user profile',
      Icons.account_circle_rounded: 'account circle user profile',
      Icons.badge_rounded: 'badge identification credential',
      Icons.card_travel_rounded: 'card travel identification document',
      Icons.cases_rounded: 'cases legal business documents',
      Icons.work_outline_rounded: 'work outline job business',
      Icons.work_history_rounded: 'work history job experience',
      Icons.business_center_rounded: 'business center office work',
      Icons.corporate_fare_rounded: 'corporate fare business office',
      Icons.domain_rounded: 'domain website internet business',
      Icons.location_city_rounded: 'location city urban area',
      Icons.foundation_rounded: 'foundation building construction',
      Icons.factory_rounded: 'factory manufacturing industrial',
      Icons.precision_manufacturing_rounded:
          'precision manufacturing industrial',
      Icons.inventory_rounded: 'inventory stock warehouse items',
      Icons.warehouse_rounded: 'warehouse storage inventory',
      Icons.store_rounded: 'store shop retail business',
      Icons.shopping_basket_rounded: 'shopping basket retail purchase',
      Icons.add_shopping_cart_rounded: 'add shopping cart purchase',
      Icons.remove_shopping_cart_rounded: 'remove shopping cart delete',
      Icons.category_rounded: 'category classification organization',
      Icons.label_important_rounded: 'label important priority tag',
      Icons.point_of_sale_rounded: 'point of sale payment transaction',
      Icons.receipt_rounded: 'receipt payment record transaction',
      Icons.request_quote_rounded: 'request quote price estimate',
      Icons.price_check_rounded: 'price check cost verification',
      Icons.paid_rounded: 'paid payment completed money',
      Icons.payment_rounded: 'payment transaction money',
      Icons.account_balance_rounded: 'account balance bank money',
      Icons.monetization_on_rounded: 'monetization money profit revenue',
      Icons.trending_flat_rounded: 'trending flat stable statistics',
      Icons.bubble_chart_rounded: 'bubble chart statistics data',
      Icons.scatter_plot_rounded: 'scatter plot chart statistics',
      Icons.insights_rounded: 'insights analytics data intelligence',
      Icons.auto_graph_rounded: 'auto graph automatic chart',
      Icons.query_stats_rounded: 'query stats data analytics',
      Icons.monitor_rounded: 'monitor display screen computer',
      Icons.dashboard_rounded: 'dashboard control panel overview',
      Icons.speed_rounded: 'speed fast performance meter',
      Icons.tune_rounded: 'tune settings configuration adjust',
      Icons.settings_rounded: 'settings configuration preferences',
      Icons.settings_applications_rounded: 'settings applications apps',
      Icons.build_rounded: 'build construction tools development',
      Icons.construction_rounded: 'construction building work site',
      Icons.handyman_rounded: 'handyman repair maintenance fix',
      Icons.hardware_rounded: 'hardware tools equipment',
      Icons.plumbing_rounded: 'plumbing water pipes maintenance',
      Icons.electrical_services_rounded: 'electrical services power',
      Icons.cleaning_services_rounded: 'cleaning services maintenance',
      Icons.miscellaneous_services_rounded: 'miscellaneous services various',
      Icons.room_preferences_rounded: 'room preferences settings home',
      Icons.biotech_rounded: 'biotech biology technology science',
      Icons.class_rounded: 'class education school learning',
      Icons.subject_rounded: 'subject topic education school',
      Icons.assignment_rounded: 'assignment homework task work',
      Icons.assignment_turned_in_rounded: 'assignment turned in completed',
      Icons.grade_rounded: 'grade score rating evaluation',
      Icons.stars_rounded: 'stars rating quality favorite',
      Icons.military_tech_rounded: 'military tech defense technology',
      Icons.emoji_events_rounded: 'emoji events celebration trophy',
      Icons.workspace_premium_rounded: 'workspace premium office quality',
      Icons.verified_rounded: 'verified trusted authentic confirmed',
      Icons.new_releases_rounded: 'new releases fresh latest',
      Icons.auto_awesome_rounded: 'auto awesome magic automatic',
      Icons.auto_fix_high_rounded: 'auto fix repair automatic',
      Icons.tips_and_updates_rounded: 'tips updates advice help',
      Icons.lightbulb_rounded: 'lightbulb idea innovation bright',
      Icons.memory_rounded: 'memory storage computer brain',
      Icons.sentiment_very_satisfied_rounded: 'sentiment very satisfied happy',
      Icons.sentiment_satisfied_rounded: 'sentiment satisfied happy content',
      Icons.sentiment_neutral_rounded: 'sentiment neutral okay average',
      Icons.sentiment_dissatisfied_rounded: 'sentiment dissatisfied unhappy',
      Icons.sentiment_very_dissatisfied_rounded:
          'sentiment very dissatisfied angry',
      Icons.mood_rounded: 'mood emotion feeling state',
      Icons.mood_bad_rounded: 'mood bad sad unhappy',
      Icons.sick_rounded: 'sick ill health unwell',
      Icons.masks_rounded: 'masks protection health safety',
      Icons.sanitizer_rounded: 'sanitizer clean health hygiene',
      Icons.wash_rounded: 'wash clean hygiene health',
      Icons.back_hand_rounded: 'back hand gesture stop',
      Icons.front_hand_rounded: 'front hand gesture hello',
      Icons.waving_hand_rounded: 'waving hand greeting goodbye',
      Icons.thumb_up_alt_rounded: 'thumb up alternative like good',
      Icons.thumb_down_alt_rounded: 'thumb down alternative dislike bad',
      Icons.thumbs_up_down_rounded: 'thumbs up down rating feedback',
      Icons.handshake_rounded: 'handshake agreement partnership',
      Icons.gesture_rounded: 'gesture hand movement sign',
      Icons.pan_tool_rounded: 'pan tool hand interaction',
      Icons.touch_app_rounded: 'touch app interaction finger',
      Icons.swipe_rounded: 'swipe gesture movement touch',
      Icons.swipe_left_rounded: 'swipe left gesture navigation',
      Icons.swipe_right_rounded: 'swipe right gesture navigation',
      Icons.swipe_up_rounded: 'swipe up gesture navigation',
      Icons.swipe_down_rounded: 'swipe down gesture navigation',
      Icons.drag_handle_rounded: 'drag handle move interaction',
      Icons.open_with_rounded: 'open with expand interaction',
      Icons.all_out_rounded: 'all out maximum full complete',
      Icons.compress_rounded: 'compress reduce size smaller',
      Icons.expand_rounded: 'expand increase size larger',
      Icons.unfold_more_rounded: 'unfold more expand show',
      Icons.unfold_less_rounded: 'unfold less collapse hide',
      Icons.first_page_rounded: 'first page beginning start',
      Icons.last_page_rounded: 'last page ending finish',
      Icons.keyboard_arrow_left_rounded: 'keyboard arrow left navigation',
      Icons.keyboard_arrow_right_rounded: 'keyboard arrow right navigation',
      Icons.keyboard_arrow_up_rounded: 'keyboard arrow up navigation',
      Icons.keyboard_arrow_down_rounded: 'keyboard arrow down navigation',
      Icons.keyboard_double_arrow_left_rounded: 'keyboard double arrow left',
      Icons.keyboard_double_arrow_right_rounded: 'keyboard double arrow right',
      Icons.keyboard_double_arrow_up_rounded: 'keyboard double arrow up',
      Icons.keyboard_double_arrow_down_rounded: 'keyboard double arrow down',
      Icons.north_rounded: 'north direction compass navigation',
      Icons.south_rounded: 'south direction compass navigation',
      Icons.east_rounded: 'east direction compass navigation',
      Icons.west_rounded: 'west direction compass navigation',
      Icons.north_east_rounded: 'north east direction compass',
      Icons.north_west_rounded: 'north west direction compass',
      Icons.south_east_rounded: 'south east direction compass',
      Icons.south_west_rounded: 'south west direction compass',
      Icons.near_me_rounded: 'near me location proximity',
      Icons.explore_off_rounded: 'explore off navigation disabled',
      Icons.my_location_rounded: 'my location gps position',
      Icons.location_searching_rounded: 'location searching gps finding',
      Icons.gps_fixed_rounded: 'gps fixed location accurate',
      Icons.gps_not_fixed_rounded: 'gps not fixed location inaccurate',
      Icons.gps_off_rounded: 'gps off location disabled',
      Icons.place_rounded: 'place location marker position',
      Icons.pin_drop_rounded: 'pin drop location marker',
      Icons.room_rounded: 'room location place space',
      Icons.add_location_rounded: 'add location new marker',
      Icons.edit_location_rounded: 'edit location modify marker',
      Icons.wrong_location_rounded: 'wrong location incorrect marker',
      Icons.location_disabled_rounded: 'location disabled gps off',
      Icons.not_listed_location_rounded: 'not listed location unlisted',
      Icons.location_history_rounded: 'location history track record',
      Icons.beenhere_rounded: 'been here visited location',
      Icons.directions_rounded: 'directions navigation route path',
      Icons.edit_road_rounded: 'edit road modify path',
      Icons.satellite_alt_rounded: 'satellite alternative space',
      Icons.terrain_rounded: 'terrain landscape geography',
      Icons.layers_rounded: 'layers multiple levels stacked',
      Icons.layers_clear_rounded: 'layers clear remove levels',
      Icons.zoom_in_rounded: 'zoom in magnify closer',
      Icons.zoom_out_rounded: 'zoom out reduce farther',
      Icons.zoom_in_map_rounded: 'zoom in map magnify',
      Icons.zoom_out_map_rounded: 'zoom out map reduce',
      Icons.fullscreen_rounded: 'fullscreen expand complete view',
      Icons.fullscreen_exit_rounded: 'fullscreen exit reduce view',
      Icons.fit_screen_rounded: 'fit screen adjust size',
      Icons.center_focus_strong_rounded: 'center focus strong attention',
      Icons.center_focus_weak_rounded: 'center focus weak attention',
      Icons.crop_free_rounded: 'crop free unrestricted edit',
      Icons.crop_rounded: 'crop edit trim image',
      Icons.crop_square_rounded: 'crop square edit image',
      Icons.crop_landscape_rounded: 'crop landscape edit image',
      Icons.crop_portrait_rounded: 'crop portrait edit image',
      Icons.crop_din_rounded: 'crop din standard edit',
      Icons.crop_16_9_rounded: 'crop 16 9 widescreen edit',
      Icons.crop_3_2_rounded: 'crop 3 2 ratio edit',
      Icons.crop_5_4_rounded: 'crop 5 4 ratio edit',
      Icons.crop_7_5_rounded: 'crop 7 5 ratio edit',
      Icons.crop_original_rounded: 'crop original restore edit',
      Icons.aspect_ratio_rounded: 'aspect ratio size proportion',
      Icons.photo_size_select_actual_rounded: 'photo size select actual',
      Icons.photo_size_select_large_rounded: 'photo size select large',
      Icons.photo_size_select_small_rounded: 'photo size select small',
      Icons.rotate_left_rounded: 'rotate left turn counterclockwise',
      Icons.rotate_right_rounded: 'rotate right turn clockwise',
      Icons.rotate_90_degrees_ccw_rounded: 'rotate 90 degrees counterclockwise',
      Icons.rotate_90_degrees_cw_rounded: 'rotate 90 degrees clockwise',
      Icons.flip_rounded: 'flip reverse mirror image',
      Icons.flip_camera_android_rounded: 'flip camera android switch',
      Icons.flip_camera_ios_rounded: 'flip camera ios switch',
      Icons.camera_rounded: 'camera photo picture capture',
      Icons.camera_front_rounded: 'camera front selfie capture',
      Icons.camera_rear_rounded: 'camera rear back capture',
      Icons.camera_enhance_rounded: 'camera enhance improve quality',
      Icons.add_a_photo_rounded: 'add a photo new picture',
      Icons.photo_camera_rounded: 'photo camera capture picture',
      Icons.photo_camera_back_rounded: 'photo camera back rear',
      Icons.photo_camera_front_rounded: 'photo camera front selfie',
      Icons.cameraswitch_rounded: 'camera switch toggle front back',
      Icons.videocam_off_rounded: 'video camera off disabled',
      Icons.movie_creation_rounded: 'movie creation film making',
      Icons.movie_filter_rounded: 'movie filter film effect',
      Icons.auto_awesome_motion_rounded: 'auto awesome motion animation',
      Icons.animation_rounded: 'animation movement motion effect',
      Icons.gif_rounded: 'gif animation image format',
      Icons.slideshow_rounded: 'slideshow presentation images',
      Icons.view_carousel_rounded: 'view carousel slider images',
      Icons.view_stream_rounded: 'view stream continuous flow',
      Icons.view_module_rounded: 'view module grid layout',
      Icons.view_quilt_rounded: 'view quilt pattern layout',
      Icons.view_compact_rounded: 'view compact dense layout',
      Icons.view_comfortable_rounded: 'view comfortable spacious layout',
      Icons.view_agenda_rounded: 'view agenda list schedule',
      Icons.view_day_rounded: 'view day calendar schedule',
      Icons.view_week_rounded: 'view week calendar schedule',
      Icons.view_headline_rounded: 'view headline news article',
      Icons.view_sidebar_rounded: 'view sidebar panel layout',
      Icons.view_array_rounded: 'view array grid matrix',
      Icons.view_column_rounded: 'view column vertical layout',
      Icons.view_in_ar_rounded: 'view in ar augmented reality',
      Icons.threed_rotation_rounded: 'three d rotation 3d movement',
      Icons.threesixty_rounded: 'three sixty 360 degree full',
      Icons.vrpano_rounded: 'vr pano virtual reality panorama',
      Icons.panorama_rounded: 'panorama wide view landscape',
      Icons.panorama_fish_eye_rounded: 'panorama fish eye wide',
      Icons.panorama_horizontal_rounded: 'panorama horizontal wide',
      Icons.panorama_vertical_rounded: 'panorama vertical tall',
      Icons.panorama_wide_angle_rounded: 'panorama wide angle view',
      Icons.photo_rounded: 'photo picture image capture',
      Icons.photo_album_rounded: 'photo album collection gallery',
      Icons.photo_library_rounded: 'photo library collection images',
      Icons.collections_rounded: 'collections gallery albums group',
      Icons.collections_bookmark_rounded: 'collections bookmark saved',
      Icons.burst_mode_rounded: 'burst mode rapid photos',
      Icons.timer_3_rounded: 'timer 3 seconds countdown',
      Icons.timer_10_rounded: 'timer 10 seconds countdown',
      Icons.timer_off_rounded: 'timer off disabled countdown',
      Icons.timelapse_rounded: 'timelapse fast motion time',
      Icons.exposure_rounded: 'exposure camera light setting',
      Icons.exposure_neg_1_rounded: 'exposure negative 1 darker',
      Icons.exposure_neg_2_rounded: 'exposure negative 2 darker',
      Icons.exposure_plus_1_rounded: 'exposure plus 1 brighter',
      Icons.exposure_plus_2_rounded: 'exposure plus 2 brighter',
      Icons.exposure_zero_rounded: 'exposure zero normal neutral',
      Icons.wb_auto_rounded: 'white balance auto camera',
      Icons.wb_cloudy_rounded: 'white balance cloudy weather',
      Icons.wb_incandescent_rounded: 'white balance incandescent indoor',
      Icons.wb_iridescent_rounded: 'white balance iridescent rainbow',
      Icons.wb_shade_rounded: 'white balance shade shadow',
      Icons.wb_twilight_rounded: 'white balance twilight evening',
      Icons.flash_auto_rounded: 'flash auto camera automatic',
      Icons.flash_off_rounded: 'flash off camera disabled',
      Icons.hdr_auto_rounded: 'hdr auto camera automatic',
      Icons.hdr_off_rounded: 'hdr off camera disabled',
      Icons.hdr_on_rounded: 'hdr on camera enabled',
      Icons.hdr_strong_rounded: 'hdr strong camera enhanced',
      Icons.hdr_weak_rounded: 'hdr weak camera subtle',
      Icons.hdr_enhanced_select_rounded: 'hdr enhanced select camera',
      Icons.iso_rounded: 'iso camera sensitivity light',
      Icons.looks_rounded: 'looks style appearance filter',
      Icons.looks_one_rounded: 'looks one style filter',
      Icons.looks_two_rounded: 'looks two style filter',
      Icons.looks_3_rounded: 'looks 3 style filter',
      Icons.looks_4_rounded: 'looks 4 style filter',
      Icons.looks_5_rounded: 'looks 5 style filter',
      Icons.looks_6_rounded: 'looks 6 style filter',
      Icons.filter_rounded: 'filter effect modify enhance',
      Icons.filter_1_rounded: 'filter 1 effect enhance',
      Icons.filter_2_rounded: 'filter 2 effect enhance',
      Icons.filter_3_rounded: 'filter 3 effect enhance',
      Icons.filter_4_rounded: 'filter 4 effect enhance',
      Icons.filter_5_rounded: 'filter 5 effect enhance',
      Icons.filter_6_rounded: 'filter 6 effect enhance',
      Icons.filter_7_rounded: 'filter 7 effect enhance',
      Icons.filter_8_rounded: 'filter 8 effect enhance',
      Icons.filter_9_rounded: 'filter 9 effect enhance',
      Icons.filter_9_plus_rounded: 'filter 9 plus effect enhance',
      Icons.filter_b_and_w_rounded: 'filter black and white monochrome',
      Icons.filter_center_focus_rounded: 'filter center focus attention',
      Icons.filter_drama_rounded: 'filter drama artistic effect',
      Icons.filter_frames_rounded: 'filter frames border effect',
      Icons.filter_hdr_rounded: 'filter hdr enhanced dynamic',
      Icons.filter_none_rounded: 'filter none original natural',
      Icons.filter_tilt_shift_rounded: 'filter tilt shift miniature',
      Icons.filter_vintage_rounded: 'filter vintage retro old',
      Icons.gradient_rounded: 'gradient color transition blend',
      Icons.grain_rounded: 'grain texture film noise',
      Icons.grid_off_rounded: 'grid off disabled lines',
      Icons.grid_on_rounded: 'grid on enabled lines',
      Icons.grid_3x3_rounded: 'grid 3x3 nine squares',
      Icons.grid_4x4_rounded: 'grid 4x4 sixteen squares',
      Icons.grid_goldenratio_rounded: 'grid golden ratio proportion',
      Icons.music_off_rounded: 'music off disabled silent',
      Icons.note_rounded: 'note text memo reminder',
      Icons.note_add_rounded: 'note add new memo',
      Icons.note_alt_rounded: 'note alternative memo text',
      Icons.speaker_notes_rounded: 'speaker notes presentation text',
      Icons.speaker_notes_off_rounded: 'speaker notes off disabled',
    };

    final availableIcons = [
      Icons.cloud_upload_rounded,
      Icons.play_circle_filled_rounded,
      Icons.bolt_rounded,
      Icons.phone_rounded,
      Icons.account_balance_wallet_rounded,
      Icons.code_rounded,
      Icons.directions_car_rounded,
      Icons.shopping_bag_rounded,
      Icons.restaurant_rounded,
      Icons.home_rounded,
      Icons.school_rounded,
      Icons.medical_services_rounded,
      Icons.pets_rounded,
      Icons.flight_rounded,
      Icons.music_note_rounded,
      Icons.sports_esports_rounded,
      Icons.camera_alt_rounded,
      Icons.book_rounded,
      Icons.work_rounded,
      Icons.beach_access_rounded,
      Icons.sports_basketball_rounded,
      Icons.local_gas_station_rounded,
      Icons.tv_rounded,
      Icons.laptop_rounded,
      Icons.watch_rounded,
      Icons.headphones_rounded,
      Icons.mic_rounded,
      Icons.speaker_rounded,
      Icons.wifi_rounded,
      Icons.bluetooth_rounded,
      Icons.battery_charging_full_rounded,
      Icons.flash_on_rounded,
      Icons.star_rounded,
      Icons.favorite_rounded,
      Icons.thumb_up_rounded,
      Icons.share_rounded,
      Icons.download_rounded,
      Icons.upload_rounded,
      Icons.refresh_rounded,
      Icons.sync_rounded,
      Icons.cloud_done_rounded,
      Icons.folder_rounded,
      Icons.description_rounded,
      Icons.image_rounded,
      Icons.video_library_rounded,
      Icons.audiotrack_rounded,
      Icons.palette_rounded,
      Icons.brush_rounded,
      Icons.design_services_rounded,
      Icons.architecture_rounded,
      Icons.engineering_rounded,
      Icons.science_rounded,
      Icons.psychology_rounded,
      Icons.sports_soccer_rounded,
      Icons.sports_tennis_rounded,
      Icons.sports_golf_rounded,
      Icons.directions_bike_rounded,
      Icons.directions_walk_rounded,
      Icons.directions_run_rounded,
      Icons.pool_rounded,
      Icons.spa_rounded,
      Icons.self_improvement_rounded,
      Icons.local_cafe_rounded,
      Icons.local_dining_rounded,
      Icons.local_pizza_rounded,
      Icons.local_bar_rounded,
      Icons.cake_rounded,
      Icons.local_grocery_store_rounded,
      Icons.local_pharmacy_rounded,
      Icons.local_florist_rounded,
      Icons.local_mall_rounded,
      Icons.local_atm_rounded,
      Icons.business_rounded,
      Icons.savings_rounded,
      Icons.payments_rounded,
      Icons.credit_card_rounded,
      Icons.receipt_long_rounded,
      Icons.storefront_rounded,
      Icons.apartment_rounded,
      Icons.house_rounded,
      Icons.nature_rounded,
      Icons.park_rounded,
      Icons.forest_rounded,
      Icons.eco_rounded,
      Icons.recycling_rounded,
      Icons.solar_power_rounded,
      Icons.electric_bolt_rounded,
      Icons.water_drop_rounded,
      Icons.local_fire_department_rounded,
      Icons.ac_unit_rounded,
      Icons.thermostat_rounded,
      Icons.light_mode_rounded,
      Icons.dark_mode_rounded,
      Icons.wb_sunny_rounded,
      Icons.nights_stay_rounded,
      Icons.celebration_rounded,
      Icons.card_giftcard_rounded,
      Icons.redeem_rounded,
      Icons.local_activity_rounded,
      Icons.event_rounded,
      Icons.calendar_today_rounded,
      Icons.schedule_rounded,
      Icons.timer_rounded,
      Icons.alarm_rounded,
      Icons.access_time_rounded,
      Icons.update_rounded,
      Icons.history_rounded,
      Icons.trending_up_rounded,
      Icons.trending_down_rounded,
      Icons.show_chart_rounded,
      Icons.analytics_rounded,
      Icons.assessment_rounded,
      Icons.pie_chart_rounded,
      Icons.bar_chart_rounded,
      Icons.functions_rounded,
      Icons.calculate_rounded,
      Icons.percent_rounded,
      Icons.euro_rounded,
      Icons.attach_money_rounded,
      Icons.sell_rounded,
      Icons.label_rounded,
      Icons.local_offer_rounded,
      Icons.loyalty_rounded,
      Icons.verified_user_rounded,
      Icons.security_rounded,
      Icons.lock_rounded,
      Icons.vpn_key_rounded,
      Icons.fingerprint_rounded,
      Icons.face_rounded,
      Icons.person_rounded,
      Icons.group_rounded,
      Icons.child_friendly_rounded,
      Icons.accessible_rounded,
      Icons.health_and_safety_rounded,
      Icons.medical_information_rounded,
      Icons.healing_rounded,
      Icons.emergency_rounded,
      Icons.sports_martial_arts_rounded,
      Icons.sports_gymnastics_rounded,
      Icons.sports_handball_rounded,
      Icons.sports_hockey_rounded,
      Icons.sports_rugby_rounded,
      Icons.sports_volleyball_rounded,
      Icons.sports_cricket_rounded,
      Icons.sports_baseball_rounded,
      Icons.sports_football_rounded,
      Icons.casino_rounded,
      Icons.toys_rounded,
      Icons.games_rounded,
      Icons.extension_rounded,
      Icons.smart_toy_rounded,
      Icons.rocket_launch_rounded,
      Icons.satellite_rounded,
      Icons.public_rounded,
      Icons.language_rounded,
      Icons.translate_rounded,
      Icons.location_on_rounded,
      Icons.map_rounded,
      Icons.navigation_rounded,
      Icons.explore_rounded,
      Icons.travel_explore_rounded,
      Icons.luggage_rounded,
      Icons.backpack_rounded,
      Icons.hiking_rounded,
      Icons.cabin_rounded,
      Icons.deck_rounded,
      Icons.hot_tub_rounded,
      Icons.water_rounded,
      Icons.waves_rounded,
      Icons.surfing_rounded,
      Icons.sailing_rounded,
      Icons.kayaking_rounded,
      Icons.rowing_rounded,
      Icons.scuba_diving_rounded,
      Icons.kitesurfing_rounded,
      Icons.snowboarding_rounded,
      Icons.downhill_skiing_rounded,
      Icons.sledding_rounded,
      Icons.ice_skating_rounded,
      Icons.skateboarding_rounded,
      Icons.roller_skating_rounded,
      Icons.snowmobile_rounded,
      Icons.motorcycle_rounded,
      Icons.electric_scooter_rounded,
      Icons.electric_bike_rounded,
      Icons.pedal_bike_rounded,
      Icons.train_rounded,
      Icons.tram_rounded,
      Icons.subway_rounded,
      Icons.airport_shuttle_rounded,
      Icons.flight_takeoff_rounded,
      Icons.flight_land_rounded,
      Icons.connecting_airports_rounded,
      Icons.rocket_rounded,
      Icons.departure_board_rounded,
      Icons.trip_origin_rounded,
      Icons.alt_route_rounded,
      Icons.route_rounded,
      Icons.traffic_rounded,
      Icons.local_shipping_rounded,
      Icons.delivery_dining_rounded,
      Icons.takeout_dining_rounded,
      Icons.room_service_rounded,
      Icons.restaurant_menu_rounded,
      Icons.lunch_dining_rounded,
      Icons.dinner_dining_rounded,
      Icons.breakfast_dining_rounded,
      Icons.brunch_dining_rounded,
      Icons.ramen_dining_rounded,
      Icons.rice_bowl_rounded,
      Icons.bakery_dining_rounded,
      Icons.liquor_rounded,
      Icons.wine_bar_rounded,
      Icons.sports_bar_rounded,
      Icons.nightlife_rounded,
      Icons.festival_rounded,
      Icons.theater_comedy_rounded,
      Icons.movie_rounded,
      Icons.live_tv_rounded,
      Icons.personal_video_rounded,
      Icons.video_call_rounded,
      Icons.videocam_rounded,
      Icons.video_settings_rounded,
      Icons.slow_motion_video_rounded,
      Icons.video_stable_rounded,
      Icons.hd_rounded,
      Icons.sd_rounded,
      Icons.subscriptions_rounded,
      Icons.library_books_rounded,
      Icons.auto_stories_rounded,
      Icons.menu_book_rounded,
      Icons.import_contacts_rounded,
      Icons.bookmark_rounded,
      Icons.bookmarks_rounded,
      Icons.library_add_rounded,
      Icons.library_music_rounded,
      Icons.queue_music_rounded,
      Icons.playlist_add_rounded,
      Icons.playlist_play_rounded,
      Icons.shuffle_rounded,
      Icons.repeat_rounded,
      Icons.replay_rounded,
      Icons.forward_rounded,
      Icons.fast_forward_rounded,
      Icons.fast_rewind_rounded,
      Icons.skip_next_rounded,
      Icons.skip_previous_rounded,
      Icons.play_arrow_rounded,
      Icons.pause_rounded,
      Icons.stop_rounded,
      Icons.volume_up_rounded,
      Icons.volume_down_rounded,
      Icons.volume_mute_rounded,
      Icons.volume_off_rounded,
      Icons.surround_sound_rounded,
      Icons.equalizer_rounded,
      Icons.graphic_eq_rounded,
      Icons.radio_rounded,
      Icons.campaign_rounded,
      Icons.notifications_rounded,
      Icons.notifications_active_rounded,
      Icons.notifications_off_rounded,
      Icons.vibration_rounded,
      Icons.do_not_disturb_rounded,
      Icons.priority_high_rounded,
      Icons.report_rounded,
      Icons.flag_rounded,
      Icons.outlined_flag_rounded,
      Icons.tour_rounded,
      Icons.info_rounded,
      Icons.help_rounded,
      Icons.support_rounded,
      Icons.contact_support_rounded,
      Icons.quiz_rounded,
      Icons.live_help_rounded,
      Icons.feedback_rounded,
      Icons.rate_review_rounded,
      Icons.reviews_rounded,
      Icons.comment_rounded,
      Icons.chat_rounded,
      Icons.chat_bubble_rounded,
      Icons.forum_rounded,
      Icons.question_answer_rounded,
      Icons.contact_phone_rounded,
      Icons.contact_mail_rounded,
      Icons.contacts_rounded,
      Icons.recent_actors_rounded,
      Icons.people_rounded,
      Icons.people_alt_rounded,
      Icons.people_outline_rounded,
      Icons.person_add_rounded,
      Icons.person_remove_rounded,
      Icons.person_search_rounded,
      Icons.supervisor_account_rounded,
      Icons.admin_panel_settings_rounded,
      Icons.manage_accounts_rounded,
      Icons.account_box_rounded,
      Icons.account_circle_rounded,
      Icons.badge_rounded,
      Icons.card_travel_rounded,
      Icons.cases_rounded,
      Icons.work_outline_rounded,
      Icons.work_history_rounded,
      Icons.business_center_rounded,
      Icons.corporate_fare_rounded,
      Icons.domain_rounded,
      Icons.location_city_rounded,
      Icons.foundation_rounded,
      Icons.factory_rounded,
      Icons.precision_manufacturing_rounded,
      Icons.inventory_rounded,
      Icons.warehouse_rounded,
      Icons.store_rounded,
      Icons.shopping_basket_rounded,
      Icons.add_shopping_cart_rounded,
      Icons.remove_shopping_cart_rounded,
      Icons.category_rounded,
      Icons.label_important_rounded,
      Icons.point_of_sale_rounded,
      Icons.receipt_rounded,
      Icons.request_quote_rounded,
      Icons.price_check_rounded,
      Icons.paid_rounded,
      Icons.payment_rounded,
      Icons.account_balance_rounded,
      Icons.monetization_on_rounded,
      Icons.trending_flat_rounded,
      Icons.bubble_chart_rounded,
      Icons.scatter_plot_rounded,
      Icons.insights_rounded,
      Icons.auto_graph_rounded,
      Icons.query_stats_rounded,
      Icons.monitor_rounded,
      Icons.dashboard_rounded,
      Icons.speed_rounded,
      Icons.tune_rounded,
      Icons.settings_rounded,
      Icons.settings_applications_rounded,
      Icons.build_rounded,
      Icons.construction_rounded,
      Icons.handyman_rounded,
      Icons.hardware_rounded,
      Icons.plumbing_rounded,
      Icons.electrical_services_rounded,
      Icons.cleaning_services_rounded,
      Icons.miscellaneous_services_rounded,
      Icons.room_preferences_rounded,
      Icons.biotech_rounded,
      Icons.class_rounded,
      Icons.subject_rounded,
      Icons.assignment_rounded,
      Icons.assignment_turned_in_rounded,
      Icons.grade_rounded,
      Icons.stars_rounded,
      Icons.military_tech_rounded,
      Icons.emoji_events_rounded,
      Icons.workspace_premium_rounded,
      Icons.verified_rounded,
      Icons.new_releases_rounded,
      Icons.auto_awesome_rounded,
      Icons.auto_fix_high_rounded,
      Icons.tips_and_updates_rounded,
      Icons.lightbulb_rounded,
      Icons.memory_rounded,
      Icons.sentiment_very_satisfied_rounded,
      Icons.sentiment_satisfied_rounded,
      Icons.sentiment_neutral_rounded,
      Icons.sentiment_dissatisfied_rounded,
      Icons.sentiment_very_dissatisfied_rounded,
      Icons.mood_rounded,
      Icons.mood_bad_rounded,
      Icons.sick_rounded,
      Icons.masks_rounded,
      Icons.sanitizer_rounded,
      Icons.wash_rounded,
      Icons.back_hand_rounded,
      Icons.front_hand_rounded,
      Icons.waving_hand_rounded,
      Icons.thumb_up_alt_rounded,
      Icons.thumb_down_alt_rounded,
      Icons.thumbs_up_down_rounded,
      Icons.handshake_rounded,
      Icons.gesture_rounded,
      Icons.pan_tool_rounded,
      Icons.touch_app_rounded,
      Icons.swipe_rounded,
      Icons.swipe_left_rounded,
      Icons.swipe_right_rounded,
      Icons.swipe_up_rounded,
      Icons.swipe_down_rounded,
      Icons.drag_handle_rounded,
      Icons.open_with_rounded,
      Icons.all_out_rounded,
      Icons.compress_rounded,
      Icons.expand_rounded,
      Icons.unfold_more_rounded,
      Icons.unfold_less_rounded,
      Icons.first_page_rounded,
      Icons.last_page_rounded,
      Icons.keyboard_arrow_left_rounded,
      Icons.keyboard_arrow_right_rounded,
      Icons.keyboard_arrow_up_rounded,
      Icons.keyboard_arrow_down_rounded,
      Icons.keyboard_double_arrow_left_rounded,
      Icons.keyboard_double_arrow_right_rounded,
      Icons.keyboard_double_arrow_up_rounded,
      Icons.keyboard_double_arrow_down_rounded,
      Icons.north_rounded,
      Icons.south_rounded,
      Icons.east_rounded,
      Icons.west_rounded,
      Icons.north_east_rounded,
      Icons.north_west_rounded,
      Icons.south_east_rounded,
      Icons.south_west_rounded,
      Icons.near_me_rounded,
      Icons.explore_off_rounded,
      Icons.my_location_rounded,
      Icons.location_searching_rounded,
      Icons.gps_fixed_rounded,
      Icons.gps_not_fixed_rounded,
      Icons.gps_off_rounded,
      Icons.place_rounded,
      Icons.pin_drop_rounded,
      Icons.room_rounded,
      Icons.add_location_rounded,
      Icons.edit_location_rounded,
      Icons.wrong_location_rounded,
      Icons.location_disabled_rounded,
      Icons.not_listed_location_rounded,
      Icons.location_history_rounded,
      Icons.beenhere_rounded,
      Icons.directions_rounded,
      Icons.edit_road_rounded,
      Icons.satellite_alt_rounded,
      Icons.terrain_rounded,
      Icons.layers_rounded,
      Icons.layers_clear_rounded,
      Icons.zoom_in_rounded,
      Icons.zoom_out_rounded,
      Icons.zoom_in_map_rounded,
      Icons.zoom_out_map_rounded,
      Icons.fullscreen_rounded,
      Icons.fullscreen_exit_rounded,
      Icons.fit_screen_rounded,
      Icons.center_focus_strong_rounded,
      Icons.center_focus_weak_rounded,
      Icons.crop_free_rounded,
      Icons.crop_rounded,
      Icons.crop_square_rounded,
      Icons.crop_landscape_rounded,
      Icons.crop_portrait_rounded,
      Icons.crop_din_rounded,
      Icons.crop_16_9_rounded,
      Icons.crop_3_2_rounded,
      Icons.crop_5_4_rounded,
      Icons.crop_7_5_rounded,
      Icons.crop_original_rounded,
      Icons.aspect_ratio_rounded,
      Icons.photo_size_select_actual_rounded,
      Icons.photo_size_select_large_rounded,
      Icons.photo_size_select_small_rounded,
      Icons.rotate_left_rounded,
      Icons.rotate_right_rounded,
      Icons.rotate_90_degrees_ccw_rounded,
      Icons.rotate_90_degrees_cw_rounded,
      Icons.flip_rounded,
      Icons.flip_camera_android_rounded,
      Icons.flip_camera_ios_rounded,
      Icons.camera_rounded,
      Icons.camera_front_rounded,
      Icons.camera_rear_rounded,
      Icons.camera_enhance_rounded,
      Icons.add_a_photo_rounded,
      Icons.photo_camera_rounded,
      Icons.photo_camera_back_rounded,
      Icons.photo_camera_front_rounded,
      Icons.cameraswitch_rounded,
      Icons.videocam_off_rounded,
      Icons.movie_creation_rounded,
      Icons.movie_filter_rounded,
      Icons.auto_awesome_motion_rounded,
      Icons.animation_rounded,
      Icons.gif_rounded,
      Icons.slideshow_rounded,
      Icons.view_carousel_rounded,
      Icons.view_stream_rounded,
      Icons.view_module_rounded,
      Icons.view_quilt_rounded,
      Icons.view_compact_rounded,
      Icons.view_comfortable_rounded,
      Icons.view_agenda_rounded,
      Icons.view_day_rounded,
      Icons.view_week_rounded,
      Icons.view_headline_rounded,
      Icons.view_sidebar_rounded,
      Icons.view_array_rounded,
      Icons.view_column_rounded,
      Icons.view_in_ar_rounded,
      Icons.threed_rotation_rounded,
      Icons.threesixty_rounded,
      Icons.vrpano_rounded,
      Icons.panorama_rounded,
      Icons.panorama_fish_eye_rounded,
      Icons.panorama_horizontal_rounded,
      Icons.panorama_vertical_rounded,
      Icons.panorama_wide_angle_rounded,
      Icons.photo_rounded,
      Icons.photo_album_rounded,
      Icons.photo_library_rounded,
      Icons.collections_rounded,
      Icons.collections_bookmark_rounded,
      Icons.burst_mode_rounded,
      Icons.timer_3_rounded,
      Icons.timer_10_rounded,
      Icons.timer_off_rounded,
      Icons.timelapse_rounded,
      Icons.exposure_rounded,
      Icons.exposure_neg_1_rounded,
      Icons.exposure_neg_2_rounded,
      Icons.exposure_plus_1_rounded,
      Icons.exposure_plus_2_rounded,
      Icons.exposure_zero_rounded,
      Icons.wb_auto_rounded,
      Icons.wb_cloudy_rounded,
      Icons.wb_incandescent_rounded,
      Icons.wb_iridescent_rounded,
      Icons.wb_shade_rounded,
      Icons.wb_twilight_rounded,
      Icons.flash_auto_rounded,
      Icons.flash_off_rounded,
      Icons.hdr_auto_rounded,
      Icons.hdr_off_rounded,
      Icons.hdr_on_rounded,
      Icons.hdr_strong_rounded,
      Icons.hdr_weak_rounded,
      Icons.hdr_enhanced_select_rounded,
      Icons.iso_rounded,
      Icons.looks_rounded,
      Icons.looks_one_rounded,
      Icons.looks_two_rounded,
      Icons.looks_3_rounded,
      Icons.looks_4_rounded,
      Icons.looks_5_rounded,
      Icons.looks_6_rounded,
      Icons.filter_rounded,
      Icons.filter_1_rounded,
      Icons.filter_2_rounded,
      Icons.filter_3_rounded,
      Icons.filter_4_rounded,
      Icons.filter_5_rounded,
      Icons.filter_6_rounded,
      Icons.filter_7_rounded,
      Icons.filter_8_rounded,
      Icons.filter_9_rounded,
      Icons.filter_9_plus_rounded,
      Icons.filter_b_and_w_rounded,
      Icons.filter_center_focus_rounded,
      Icons.filter_drama_rounded,
      Icons.filter_frames_rounded,
      Icons.filter_hdr_rounded,
      Icons.filter_none_rounded,
      Icons.filter_tilt_shift_rounded,
      Icons.filter_vintage_rounded,
      Icons.gradient_rounded,
      Icons.grain_rounded,
      Icons.grid_off_rounded,
      Icons.grid_on_rounded,
      Icons.grid_3x3_rounded,
      Icons.grid_4x4_rounded,
      Icons.grid_goldenratio_rounded,
      Icons.music_off_rounded,
      Icons.my_library_add_rounded,
      Icons.my_library_books_rounded,
      Icons.my_library_music_rounded,
      Icons.note_rounded,
      Icons.note_add_rounded,
      Icons.note_alt_rounded,
      Icons.speaker_notes_rounded,
      Icons.speaker_notes_off_rounded,
    ];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            // Filter icons based on search
            List<IconData> filteredIcons = availableIcons;
            if (searchController.text.isNotEmpty) {
              final searchTerm = searchController.text.toLowerCase();
              filteredIcons = availableIcons.where((icon) {
                final searchTerms = iconSearchTerms[icon] ?? '';
                return searchTerms.toLowerCase().contains(searchTerm);
              }).toList();
            }

            return AlertDialog(
              backgroundColor: _backgroundColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              title: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Choose Icon',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: _highContrastDarkBlue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Search field
                  TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: 'Search icons...',
                      prefixIcon: Icon(Icons.search_rounded, color: _darkColor),
                      suffixIcon: searchController.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(
                                Icons.clear_rounded,
                                color: _darkColor,
                              ),
                              onPressed: () {
                                searchController.clear();
                                setState(() {});
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: _lightColor.withAlpha(100),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: selectedColor, width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: _highContrastDarkBlue,
                    ),
                    onChanged: (value) {
                      setState(() {});
                    },
                  ),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                height: 400,
                child: filteredIcons.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.search_off_rounded,
                              size: 48,
                              color: _darkColor.withAlpha(102),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No icons found',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    color: _darkColor.withAlpha(153),
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Try a different search term',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: _darkColor.withAlpha(102)),
                            ),
                          ],
                        ),
                      )
                    : GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 5,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: 1,
                            ),
                        itemCount: filteredIcons.length,
                        itemBuilder: (context, index) {
                          final icon = filteredIcons[index];
                          final isSelected = icon == selectedIcon;

                          return GestureDetector(
                            onTap: () {
                              onIconSelected(icon);
                              Navigator.of(context).pop();
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? _highContrastBlue.withAlpha(41)
                                    : _lightColor.withAlpha(100),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected
                                      ? _highContrastBlue
                                      : _darkColor.withAlpha(51),
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Icon(
                                icon,
                                color: isSelected
                                    ? selectedColor
                                    : selectedColor.withAlpha(153),
                                size: 32,
                              ),
                            ),
                          );
                        },
                      ),
              ),
              actions: [
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    side: BorderSide(color: _darkColor),
                  ),
                  child: Text('Cancel', style: TextStyle(color: _darkColor)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildColorSelector(
    Color selectedColor,
    Color selectedBackgroundColor,
    Function(Color, Color) onColorSelected, {
    String? categoryName,
    IconData? categoryIcon,
  }) {
    final colorPairs = Material3ColorSystem.categoryColors.asMap().entries.map((
      entry,
    ) {
      final index = entry.key;
      final color = entry.value;
      final backgroundColor =
          Material3ColorSystem.categoryBackgroundColors[index];
      return [color, backgroundColor];
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Color options
        Center(
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              // Material 3 Preset Colors
              ...colorPairs.map((colorPair) {
                final color = colorPair[0];
                final backgroundColor = colorPair[1];
                final isSelected = color == selectedColor;

                return GestureDetector(
                  onTap: () => onColorSelected(color, backgroundColor),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? _darkColor
                            : _darkColor.withAlpha(51),
                        width: isSelected ? 3 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: color.withAlpha(100),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: isSelected
                        ? Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 20,
                          )
                        : null,
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Info text
        Center(
          child: Text(
            '${colorPairs.length} Material 3 colors available',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: _darkColor.withAlpha(153),
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ],
    );
  }

  void _showHidePanelBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setModalState) {
          return Container(
            decoration: BoxDecoration(
              color: _backgroundColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(28),
                topRight: Radius.circular(28),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Bottom sheet handle
                  Center(
                    child: Container(
                      width: 32,
                      height: 4,
                      decoration: BoxDecoration(
                        color: _darkColor.withAlpha(102),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Title Section
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _darkColor.withAlpha(41),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          Icons.visibility_off_rounded,
                          color: _darkColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hide Panels',
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w500,
                                    color: _highContrastDarkBlue,
                                    letterSpacing: -0.5,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Toggle panels to show or hide them',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: _darkColor.withAlpha(179),
                                    fontWeight: FontWeight.w400,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Panel Options Section with Stacked Cards
                  Text(
                    'Panel Options',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: _highContrastDarkBlue,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Stacked Cards for Panel Options
                  _buildHidePanelStackedCards(
                    localCategoryHidden: _isCategoryHidden,
                    localInsightsHidden: _isInsightsHidden,
                    localPausedFinishedHidden: _isPausedFinishedHidden,
                    onCategoryChanged: (value) {
                      setState(() {
                        _isCategoryHidden = value;
                      });
                      setModalState(() {});
                    },
                    onInsightsChanged: (value) {
                      setState(() {
                        _isInsightsHidden = value;
                      });
                      setModalState(() {});
                    },
                    onPausedFinishedChanged: (value) {
                      setState(() {
                        _isPausedFinishedHidden = value;
                      });
                      setModalState(() {});
                    },
                  ),
                  SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHidePanelStackedCards({
    required bool localCategoryHidden,
    required bool localInsightsHidden,
    required bool localPausedFinishedHidden,
    required ValueChanged<bool> onCategoryChanged,
    required ValueChanged<bool> onInsightsChanged,
    required ValueChanged<bool> onPausedFinishedChanged,
  }) {
    final panelOptions = [
      {
        'title': 'Categories',
        'subtitle': 'Hide category breakdown section',
        'icon': Icons.category_rounded,
        'isHidden': localCategoryHidden,
        'color': _darkColor,
        'onChanged': onCategoryChanged,
      },
      {
        'title': 'Insights',
        'subtitle': 'Hide spending insights section',
        'icon': Icons.insights_rounded,
        'isHidden': localInsightsHidden,
        'color': _highContrastBlue,
        'onChanged': onInsightsChanged,
      },
      {
        'title': 'Paused/Finished',
        'subtitle': 'Hide paused and finished payables section',
        'icon': Icons.pause_circle_rounded,
        'isHidden': localPausedFinishedHidden,
        'color': Material3ColorSystem.getTertiaryColor(
          Theme.of(context).brightness,
        ), // Tertiary color for paused/finished
        'onChanged': onPausedFinishedChanged,
      },
    ];

    return Column(
      children: [
        for (int i = 0; i < panelOptions.length; i++) ...[
          _buildHidePanelCard(
            title: panelOptions[i]['title'] as String,
            subtitle: panelOptions[i]['subtitle'] as String,
            icon: panelOptions[i]['icon'] as IconData,
            isHidden: panelOptions[i]['isHidden'] as bool,
            color: panelOptions[i]['color'] as Color,
            onChanged: panelOptions[i]['onChanged'] as ValueChanged<bool>,
            index: i,
            isLast: i == panelOptions.length - 1,
          ),
          if (i < panelOptions.length - 1) const SizedBox(height: 2),
        ],
      ],
    );
  }

  Widget _buildHidePanelCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isHidden,
    required Color color,
    required ValueChanged<bool> onChanged,
    required int index,
    required bool isLast,
  }) {
    // Determine border radius based on position - matching dashboard stacked card pattern
    BorderRadius borderRadius;
    if (index == 0) {
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
      color: _lightColor.withAlpha(150),
      shape: RoundedRectangleBorder(borderRadius: borderRadius),
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
                      fontWeight: FontWeight.w500,
                      color: _highContrastDarkBlue,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: _darkColor,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // Custom styled switch
            Transform.scale(
              scale: 0.9,
              child: Switch(
                value: isHidden,
                onChanged: onChanged,
                activeColor: Colors.white,
                activeTrackColor: color,
                inactiveThumbColor: Colors.white,
                inactiveTrackColor: _lightColor.withAlpha(120),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EnhancedInsightsPatternPainter extends CustomPainter {
  final Color color;

  _EnhancedInsightsPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // Draw enhanced grid pattern with curves
    final gridSize = 25.0;

    // Vertical lines with slight curve
    for (double x = 0; x < size.width; x += gridSize) {
      final path = Path();
      path.moveTo(x, 0);
      path.quadraticBezierTo(x + 2, size.height / 2, x, size.height);
      canvas.drawPath(path, paint);
    }

    // Horizontal lines with slight curve
    for (double y = 0; y < size.height; y += gridSize) {
      final path = Path();
      path.moveTo(0, y);
      path.quadraticBezierTo(size.width / 2, y + 2, size.width, y);
      canvas.drawPath(path, paint);
    }

    // Draw enhanced dots at intersections with glow effect
    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final glowPaint = Paint()
      ..color = color.withAlpha(30)
      ..style = PaintingStyle.fill;

    for (double x = gridSize; x < size.width; x += gridSize) {
      for (double y = gridSize; y < size.height; y += gridSize) {
        // Draw glow effect
        canvas.drawCircle(Offset(x, y), 3.0, glowPaint);
        // Draw main dot
        canvas.drawCircle(Offset(x, y), 1.5, dotPaint);
      }
    }

    // Add subtle wave pattern
    final wavePaint = Paint()
      ..color = color.withAlpha(20)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < 3; i++) {
      final path = Path();
      final y = size.height * 0.3 + (i * 20);
      path.moveTo(0, y);

      for (double x = 0; x < size.width; x += 10) {
        path.lineTo(x, y + math.sin(x * 0.02) * 8);
      }

      canvas.drawPath(path, wavePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
