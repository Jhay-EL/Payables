import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:payables/utils/theme_provider.dart';
import '../utils/material3_color_system.dart';

class AppearanceSettingsScreen extends StatefulWidget {
  const AppearanceSettingsScreen({super.key});

  @override
  State<AppearanceSettingsScreen> createState() =>
      _AppearanceSettingsScreenState();
}

class _AppearanceSettingsScreenState extends State<AppearanceSettingsScreen> {
  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0.0;

  // Material 3 expressive color system
  Color get backgroundColor {
    final brightness = Theme.of(context).brightness;
    return Material3ColorSystem.getSurfaceColor(brightness);
  }

  Color get lightColor {
    final brightness = Theme.of(context).brightness;
    return Material3ColorSystem.getSurfaceVariantColor(brightness);
  }

  Color get darkColor {
    final brightness = Theme.of(context).brightness;
    return Material3ColorSystem.getOnSurfaceVariantColor(brightness);
  }

  Color get userSelectedColor {
    final brightness = Theme.of(context).brightness;
    return Material3ColorSystem.getPrimaryContainerColor(brightness);
  }

  Color get highContrastBlue {
    final brightness = Theme.of(context).brightness;
    return Material3ColorSystem.getPrimaryColor(brightness);
  }

  Color get highContrastDarkBlue {
    final brightness = Theme.of(context).brightness;
    return Material3ColorSystem.getOnSurfaceColor(brightness);
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
            surfaceTintColor: Material3ColorSystem.getSurfaceTintColor(
              Theme.of(context).brightness,
            ),
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
                    // Animated Appearance Settings Title
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
                                    'Appearance',
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
                                    color: highContrastDarkBlue.withValues(
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
          // M3 Expressive Appearance Settings Content
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 32.0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Theme Section
                Text(
                  'Theme',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w400,
                    color: highContrastDarkBlue,
                  ),
                ),
                const SizedBox(height: 20),
                _buildThemeOptionsSection(),
                const SizedBox(height: 32),
                // Dynamic Color Section
                Text(
                  'Dynamic Color',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w400,
                    color: highContrastDarkBlue,
                  ),
                ),
                const SizedBox(height: 20),
                _buildDynamicColorSection(),
                const SizedBox(height: 32),
                // Info Section
                _buildInfoSection(),
                SizedBox(height: 32 + MediaQuery.of(context).padding.bottom),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOptionsSection() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    String selectedTheme = themeProvider.themeMode.toString().split('.').last;

    return _buildM3SettingsSection([
      _buildThemeOption(
        'Light Mode',
        'Clean and bright interface',
        Icons.light_mode_rounded,
        const Color(0xFFF59E0B),
        'light',
        selectedTheme,
        (newTheme) {
          late ThemeMode newThemeMode;
          switch (newTheme) {
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
          late ThemeMode newThemeMode;
          switch (newTheme) {
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
          late ThemeMode newThemeMode;
          switch (newTheme) {
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
        },
        isLast: true,
      ),
    ]);
  }

  Widget _buildDynamicColorSection() {
    bool dynamicColorEnabled =
        true; // This should be managed by state management

    return _buildM3SettingsSection([
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
        isFirst: true,
        isLast: true,
      ),
    ]);
  }

  Widget _buildInfoSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: userSelectedColor.withAlpha(100),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: userSelectedColor.withAlpha(120), width: 1),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: darkColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Theme changes will take effect immediately',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: highContrastDarkBlue,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildM3SettingsSection(List<Widget> items) {
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
          onTap: () => onThemeSelected(value),
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
                                fontWeight: FontWeight.w500,
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

  Widget _buildAppearanceSwitchOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required Function(bool) onChanged,
    bool isFirst = false,
    bool isLast = false,
  }) {
    const iconColor = Color(0xFF8E4EC6);
    return Container(
      decoration: BoxDecoration(
        color: lightColor.withAlpha(150),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: lightColor.withAlpha(100), width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onChanged(!value),
          borderRadius: BorderRadius.circular(24),
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
}
