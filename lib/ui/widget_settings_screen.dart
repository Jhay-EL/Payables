import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math' as math;

class WidgetSettingsScreen extends StatefulWidget {
  const WidgetSettingsScreen({super.key});

  @override
  State<WidgetSettingsScreen> createState() => _WidgetSettingsScreenState();
}

class _WidgetSettingsScreenState extends State<WidgetSettingsScreen> {
  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0.0;

  Color backgroundColor = const Color(0xFF2B2B2B);
  double transparency = 0.8;
  Color textColor = Colors.white;
  bool showTomorrow = true;
  bool showUpcoming = true;
  bool showTotal = true;

  // Dynamic color system that adapts to dark/light mode (matching dashboard)
  Color get dashboardBackgroundColor {
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
    final newOffset = _scrollController.offset;
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

  // Helper methods for animated title positioning
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: dashboardBackgroundColor,
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
            backgroundColor: dashboardBackgroundColor,
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
                      decoration: BoxDecoration(
                        color: dashboardBackgroundColor,
                      ),
                    ),
                    // Animated Widget Settings Title with flutter_animate
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
                                    'Widget Settings',
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
          // M3 Expressive Widget Settings Content
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 32.0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildWidgetPreviewSection(),
                const SizedBox(height: 32),
                // Section: Customization
                Text(
                  'Customization',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w400,
                    color: highContrastDarkBlue,
                  ),
                ),
                const SizedBox(height: 20),
                _buildWidgetCustomizationSection(),
                const SizedBox(height: 32),
                // Section: Options
                Text(
                  'Options',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w400,
                    color: highContrastDarkBlue,
                  ),
                ),
                const SizedBox(height: 20),
                _buildWidgetOptionsSection(),
                SizedBox(height: 32 + MediaQuery.of(context).padding.bottom),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWidgetPreviewSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF8E4EC6).withAlpha(41),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.widgets_rounded,
                color: const Color(0xFF8E4EC6),
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Home Screen Widget',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: highContrastDarkBlue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Live preview of your widget',
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
        const SizedBox(height: 24),
        // Widget Preview
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF87CEEB), Color(0xFF4682B4), Color(0xFF1E90FF)],
            ),
            borderRadius: BorderRadius.circular(28),
          ),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: backgroundColor.withAlpha((transparency * 255).round()),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left side - Tomorrow section
                    Expanded(
                      flex: 1,
                      child: Visibility(
                        visible: showTomorrow,
                        maintainState: true,
                        maintainAnimation: true,
                        maintainSize: true,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tomorrow',
                              style: TextStyle(
                                fontSize: 14,
                                color: textColor.withAlpha(204),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '€ 3.03',
                              style: TextStyle(
                                fontSize: 32,
                                color: textColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Right side - Upcoming section
                    Expanded(
                      flex: 1,
                      child: Visibility(
                        visible: showUpcoming,
                        maintainState: true,
                        maintainAnimation: true,
                        maintainSize: true,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  'Upcoming',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: textColor.withAlpha(204),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Icon(
                                  Icons.keyboard_arrow_down,
                                  color: textColor.withAlpha(204),
                                  size: 16,
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                _buildWidgetPayableItem(
                                  'Spotify',
                                  '₱ 199.99',
                                  textColor,
                                ),
                                _buildWidgetPayableItem(
                                  'Amazon',
                                  '€ 4,99',
                                  textColor,
                                ),
                                _buildWidgetPayableItem(
                                  'Youtube',
                                  '₱ 169.00',
                                  textColor,
                                ),
                                _buildWidgetPayableItem(
                                  'Crunchyroll',
                                  '₱ 199.00',
                                  textColor,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                Visibility(
                  visible: showTotal,
                  maintainState: true,
                  maintainAnimation: true,
                  maintainSize: true,
                  child: Column(
                    children: [
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: textColor.withAlpha(26),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '4 Upcoming Payables',
                          style: TextStyle(
                            fontSize: 12,
                            color: textColor,
                            fontWeight: FontWeight.w600,
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
      ],
    );
  }

  Widget _buildWidgetCustomizationSection() {
    return Column(
      children: [
        // Background Color
        _buildCustomizationOption(
          icon: Icons.palette_rounded,
          title: 'Background Color',
          subtitle: 'Choose widget background',
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: darkColor.withAlpha(51), width: 2),
            ),
          ),
          onTap: () => _showColorPicker(),
          isFirst: true,
          color: const Color(0xFF6750A4),
        ),
        const SizedBox(height: 2),
        // Transparency
        _buildTransparencyOption(),
        const SizedBox(height: 2),
        // Text Color
        _buildCustomizationOption(
          icon: Icons.format_color_text_rounded,
          title: 'Text Color',
          subtitle: 'Choose text color',
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: textColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: darkColor.withAlpha(51), width: 2),
            ),
          ),
          onTap: () => _showTextColorPicker(),
          isLast: true,
          color: const Color(0xFF8E4EC6),
        ),
      ],
    );
  }

  Widget _buildTransparencyOption() {
    const optionColor = Color(0xFF006A6B);

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: lightColor.withAlpha(150),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(5)),
      ),
      child: Padding(
        padding: const EdgeInsets.only(top: 20, left: 20, right: 20, bottom: 8),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: optionColor.withAlpha(41),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.opacity_rounded,
                    color: optionColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Transparency',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w500,
                              color: highContrastDarkBlue,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Adjust background opacity',
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
            Slider(
              value: transparency,
              min: 0.1,
              max: 1.0,
              divisions: 9,
              activeColor: optionColor,
              inactiveColor: optionColor.withAlpha(51),
              onChanged: (value) {
                setState(() {
                  transparency = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWidgetOptionsSection() {
    return Column(
      children: [
        _buildSwitchOption(
          icon: Icons.today_rounded,
          title: 'Show Tomorrow',
          subtitle: 'Display tomorrow\'s payments',
          value: showTomorrow,
          onChanged: (value) {
            setState(() {
              showTomorrow = value;
            });
          },
          isFirst: true,
          color: const Color(0xFF8B5000),
        ),
        const SizedBox(height: 2),
        _buildSwitchOption(
          icon: Icons.upcoming_rounded,
          title: 'Show Upcoming',
          subtitle: 'Display upcoming payments list',
          value: showUpcoming,
          onChanged: (value) {
            setState(() {
              showUpcoming = value;
            });
          },
          color: const Color(0xFF006E1C),
        ),
        const SizedBox(height: 2),
        _buildSwitchOption(
          icon: Icons.format_list_numbered_rounded,
          title: 'Show Payables Count',
          subtitle: 'Display the number of upcoming payables',
          value: showTotal,
          onChanged: (value) {
            setState(() {
              showTotal = value;
            });
          },
          isLast: true,
          color: const Color(0xFF984061),
        ),
      ],
    );
  }

  Widget _buildCustomizationOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget child,
    VoidCallback? onTap,
    bool isFirst = false,
    bool isLast = false,
    Color? color,
  }) {
    final optionColor = color ?? darkColor;

    // Determine border radius based on position (stacked card design)
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
      padding: EdgeInsets.zero,
      child: Card(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: lightColor.withAlpha(150),
        shape: RoundedRectangleBorder(borderRadius: borderRadius),
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius,
          splashColor: optionColor.withAlpha(31),
          highlightColor: optionColor.withAlpha(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: optionColor.withAlpha(41),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: optionColor, size: 20),
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
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
    bool isFirst = false,
    bool isLast = false,
    Color? color,
  }) {
    final optionColor = color ?? darkColor;

    // Determine border radius based on position (stacked card design)
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

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: lightColor.withAlpha(150),
      shape: RoundedRectangleBorder(borderRadius: borderRadius),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: optionColor.withAlpha(41),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: optionColor, size: 20),
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
              activeColor: optionColor,
              inactiveThumbColor: darkColor.withAlpha(102),
              inactiveTrackColor: lightColor.withAlpha(77),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWidgetPayableItem(String name, String amount, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            name,
            style: TextStyle(
              fontSize: 12,
              color: textColor.withAlpha(204),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            amount,
            style: TextStyle(
              fontSize: 12,
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _showColorPicker() {
    final List<Color> colors = [
      const Color(0xFF2B2B2B), // Dark
      const Color(0xFF1DB954), // Spotify green
      const Color(0xFF3B82F6), // Blue
      const Color(0xFFEF4444), // Red
      const Color(0xFFF59E0B), // Orange
      const Color(0xFF8B5CF6), // Purple
      const Color(0xFF06B6D4), // Cyan
      const Color(0xFFEC4899), // Pink
      const Color(0xFF84CC16), // Lime
      const Color(0xFF6B7280), // Gray
      const Color(0xFF0F172A), // Dark
      const Color(0xFFFBBF24), // Yellow
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: dashboardBackgroundColor,
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
                      color: const Color(0xFF6750A4).withAlpha(41),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.palette_rounded,
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
                          'Background Color',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w500,
                                color: highContrastDarkBlue,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Choose widget background color',
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
            // Color Grid
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  // Pre-defined Colors
                  ...colors.map((color) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          backgroundColor = color;
                        });
                        Navigator.pop(context);
                      },
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: backgroundColor == color
                                ? const Color(0xFF6750A4)
                                : Colors.transparent,
                            width: 3,
                          ),
                        ),
                        child: backgroundColor == color
                            ? Icon(Icons.check, color: Colors.white, size: 24)
                            : null,
                      ),
                    );
                  }),
                  // Custom Color Button
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context); // Close the bottom sheet
                      _showColorWheelDialog(
                        onColorSelected: (color) {
                          setState(() {
                            backgroundColor = color;
                          });
                        },
                        initialColor: backgroundColor,
                        title: 'Background Color',
                        icon: Icons.palette_rounded,
                        activeColor: const Color(0xFF6750A4),
                      );
                    },
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: darkColor.withAlpha(102),
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.color_lens_rounded,
                          color: const Color(0xFF6750A4),
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // M3 Safe Area
            SizedBox(height: MediaQuery.of(context).padding.bottom + 32),
          ],
        ),
      ),
    );
  }

  void _showTextColorPicker() {
    final List<Color> colors = [
      Colors.white,
      Colors.black,
      const Color(0xFF1DB954), // Green
      const Color(0xFF3B82F6), // Blue
      const Color(0xFFEF4444), // Red
      const Color(0xFFF59E0B), // Orange
      const Color(0xFF8B5CF6), // Purple
      const Color(0xFF06B6D4), // Cyan
      const Color(0xFFEC4899), // Pink
      const Color(0xFF84CC16), // Lime
      const Color(0xFFFBBF24), // Yellow
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: dashboardBackgroundColor,
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
                      Icons.format_color_text_rounded,
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
                          'Text Color',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w500,
                                color: highContrastDarkBlue,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Choose widget text color',
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
            // Color Grid
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  // Pre-defined Colors
                  ...colors.map((color) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          textColor = color;
                        });
                        Navigator.pop(context);
                      },
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: textColor == color
                                ? const Color(0xFF8E4EC6)
                                : Colors.transparent,
                            width: 3,
                          ),
                        ),
                        child: textColor == color
                            ? Icon(
                                Icons.check,
                                color: color == Colors.white
                                    ? Colors.black
                                    : Colors.white,
                                size: 24,
                              )
                            : null,
                      ),
                    );
                  }),
                  // Custom Color Button
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context); // Close the bottom sheet
                      _showColorWheelDialog(
                        onColorSelected: (color) {
                          setState(() {
                            textColor = color;
                          });
                        },
                        initialColor: textColor,
                        title: 'Text Color',
                        icon: Icons.format_color_text_rounded,
                        activeColor: const Color(0xFF8E4EC6),
                      );
                    },
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: darkColor.withAlpha(102),
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.color_lens_rounded,
                          color: const Color(0xFF8E4EC6),
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // M3 Safe Area
            SizedBox(height: MediaQuery.of(context).padding.bottom + 32),
          ],
        ),
      ),
    );
  }

  void _showColorWheelDialog({
    required Function(Color) onColorSelected,
    required Color initialColor,
    required String title,
    required IconData icon,
    required Color activeColor,
  }) {
    Color pickedColor = initialColor;
    final hexController = TextEditingController(
      text: initialColor
          .toARGB32()
          .toRadixString(16)
          .substring(2)
          .toUpperCase(),
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            void updateColor(Color newColor) {
              if (newColor == pickedColor) return;

              setState(() {
                pickedColor = newColor;
                final newHex = newColor
                    .toARGB32()
                    .toRadixString(16)
                    .substring(2)
                    .toUpperCase();
                if (hexController.text.toUpperCase() != newHex) {
                  hexController.text = newHex;
                  hexController.selection = TextSelection.fromPosition(
                    TextPosition(offset: hexController.text.length),
                  );
                }
              });
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              backgroundColor: dashboardBackgroundColor,
              title: Row(
                children: [
                  Icon(icon, color: activeColor, size: 24),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: highContrastDarkBlue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: pickedColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: darkColor.withAlpha(77),
                          width: 4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _ColorWheelWidget(
                      currentColor: pickedColor,
                      onColorChanged: updateColor,
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: hexController,
                      textAlign: TextAlign.center,
                      maxLength: 6,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: highContrastDarkBlue,
                        fontFamily: 'monospace',
                      ),
                      decoration: InputDecoration(
                        labelText: 'Hex Code',
                        prefixText: '#',
                        counterText: '',
                        filled: true,
                        fillColor: lightColor.withAlpha(100),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: activeColor, width: 2),
                        ),
                      ),
                      onChanged: (value) {
                        if (value.length == 6) {
                          try {
                            final newColor = Color(
                              int.parse('FF$value', radix: 16),
                            );
                            updateColor(newColor);
                          } catch (e) {
                            // Ignore invalid hex codes
                          }
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: highContrastDarkBlue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    onColorSelected(pickedColor);
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    'Select',
                    style: TextStyle(
                      color: activeColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _ColorWheelWidget extends StatelessWidget {
  final ValueChanged<Color> onColorChanged;
  final Color currentColor;

  const _ColorWheelWidget({
    required this.onColorChanged,
    required this.currentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onPanStart: (details) => _handleColorSelection(details.localPosition),
        onPanUpdate: (details) => _handleColorSelection(details.localPosition),
        onTapDown: (details) => _handleColorSelection(details.localPosition),
        child: CustomPaint(
          size: const Size(280, 280),
          painter: ColorWheelPainter(
            currentColor: currentColor,
            context: context,
          ),
        ),
      ),
    );
  }

  void _handleColorSelection(Offset position) {
    const size = 280.0;
    final center = const Offset(size / 2, size / 2);
    final offset = position - center;
    final distance = offset.distance;

    if (distance <= size / 2) {
      final double angle =
          (math.atan2(offset.dy, offset.dx) * 180 / math.pi + 360) % 360;
      final double saturation = math.min(distance / (size / 2), 1.0);
      const double value = 1.0;

      final Color selectedColor = HSVColor.fromAHSV(
        1.0,
        angle,
        saturation,
        value,
      ).toColor();

      onColorChanged(selectedColor);
    }
  }
}

class ColorWheelPainter extends CustomPainter {
  final Color currentColor;
  final BuildContext context;

  ColorWheelPainter({required this.currentColor, required this.context});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw the color wheel with reduced resolution for better performance
    for (int h = 0; h < 360; h += 3) {
      // Reduced hue resolution from 1 to 3 degrees
      final double hue = h.toDouble();
      for (int s = 0; s < radius; s += 2) {
        // Reduced saturation resolution from 1 to 2 pixels
        final double saturation = s / radius;
        final color = HSVColor.fromAHSV(1.0, hue, saturation, 1.0).toColor();
        final paint = Paint()..color = color;
        final angle = hue * (math.pi / 180);
        final x = center.dx + s * math.cos(angle);
        final y = center.dy + s * math.sin(angle);
        canvas.drawCircle(
          Offset(x, y),
          1.5,
          paint,
        ); // Slightly larger circles to fill gaps
      }
    }

    // Draw the selector
    final hsvColor = HSVColor.fromColor(currentColor);
    final angle = hsvColor.hue * math.pi / 180;
    final distance = hsvColor.saturation * radius;

    final selectorPosition = Offset(
      center.dx + distance * math.cos(angle),
      center.dy + distance * math.sin(angle),
    );

    final selectorPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(selectorPosition, 10, selectorPaint);

    final selectorBorderPaint = Paint()
      ..color = Theme.of(context).colorScheme.outline
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(selectorPosition, 10, selectorBorderPaint);
  }

  @override
  bool shouldRepaint(covariant ColorWheelPainter oldDelegate) {
    return oldDelegate.currentColor != currentColor;
  }
}
