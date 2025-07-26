import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:payables/models/currency.dart';
import 'package:payables/data/currency_database.dart';
import 'package:payables/data/currency_provider.dart';

class CurrencySettingsScreen extends StatefulWidget {
  const CurrencySettingsScreen({super.key});

  @override
  State<CurrencySettingsScreen> createState() => _CurrencySettingsScreenState();
}

class _CurrencySettingsScreenState extends State<CurrencySettingsScreen> {
  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0.0;
  String searchQuery = '';
  final TextEditingController searchController = TextEditingController();
  bool _isSearchVisible = false;

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
    searchController.dispose();
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
    final currencyProvider = Provider.of<CurrencyProvider>(context);
    String selectedCurrency = currencyProvider.selectedCurrency;
    final allCurrencies = CurrencyDatabase.getCurrencies();

    // Filter currencies based on search query
    final filteredCurrencies = allCurrencies.where((currency) {
      if (searchQuery.isEmpty) return true;
      return currency.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
          currency.code.toLowerCase().contains(searchQuery.toLowerCase()) ||
          currency.symbol.toLowerCase().contains(searchQuery.toLowerCase());
    }).toList();

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
            actions: [
              if (!_isSearchVisible)
                Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: RepaintBoundary(
                    child: IconButton(
                      onPressed: () {
                        setState(() {
                          _isSearchVisible = true;
                        });
                        // Focus the search field after a short delay
                        Future.delayed(const Duration(milliseconds: 100), () {
                          if (mounted) {
                            // Remove focus from any current field
                            FocusManager.instance.primaryFocus?.unfocus();
                          }
                        });
                      },
                      icon: Icon(
                        Icons.search_rounded,
                        color: highContrastDarkBlue,
                        size: 24,
                      ),
                      splashRadius: 24,
                    ),
                  ),
                ),
              if (_isSearchVisible)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 56.0, right: 16.0),
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: lightColor.withAlpha(100),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: darkColor.withAlpha(51),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 16.0),
                            child: Icon(
                              Icons.search_rounded,
                              color: darkColor.withAlpha(153),
                              size: 20,
                            ),
                          ),
                          Expanded(
                            child: TextField(
                              controller: searchController,
                              autofocus: true,
                              decoration: InputDecoration(
                                hintText: 'Search currencies...',
                                hintStyle: TextStyle(
                                  color: darkColor.withAlpha(153),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w400,
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                              ),
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(
                                    color: highContrastDarkBlue,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w400,
                                  ),
                              onChanged: (value) {
                                setState(() {
                                  searchQuery = value;
                                });
                              },
                              onSubmitted: (value) {
                                setState(() {
                                  _isSearchVisible = false;
                                });
                              },
                            ),
                          ),
                          if (searchQuery.isNotEmpty)
                            IconButton(
                              onPressed: () {
                                searchController.clear();
                                setState(() {
                                  searchQuery = '';
                                });
                              },
                              icon: Icon(
                                Icons.clear_rounded,
                                color: darkColor.withAlpha(153),
                                size: 20,
                              ),
                              padding: const EdgeInsets.all(8),
                              constraints: const BoxConstraints(
                                minWidth: 40,
                                minHeight: 40,
                              ),
                            ),
                          IconButton(
                            onPressed: () {
                              searchController.clear();
                              setState(() {
                                searchQuery = '';
                                _isSearchVisible = false;
                              });
                            },
                            icon: Icon(
                              Icons.close_rounded,
                              color: darkColor.withAlpha(153),
                              size: 20,
                            ),
                            padding: const EdgeInsets.all(8),
                            constraints: const BoxConstraints(
                              minWidth: 40,
                              minHeight: 40,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: RepaintBoundary(
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(color: backgroundColor),
                    ),
                    // Animated Currency Settings Title
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
                                    'Currency',
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
          // M3 Expressive Currency Settings Content
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 32.0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Currencies Section
                Text(
                  'Currencies',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w400,
                    color: highContrastDarkBlue,
                  ),
                ),
                const SizedBox(height: 20),
                _buildCurrencyOptionsSection(
                  filteredCurrencies,
                  selectedCurrency,
                ),
                if (filteredCurrencies.isEmpty) ...[
                  const SizedBox(height: 32),
                  _buildEmptyState(),
                ],
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

  Widget _buildCurrencyOptionsSection(
    List<Currency> currencies,
    String selectedCurrency,
  ) {
    return _buildM3SettingsSection([
      for (int i = 0; i < currencies.length; i++)
        _buildCurrencyOption(
          currencies[i],
          selectedCurrency,
          isFirst: i == 0,
          isLast: i == currencies.length - 1,
        ),
    ]);
  }

  Widget _buildCurrencyOption(
    Currency currency,
    String selectedValue, {
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
                                fontWeight: FontWeight.w500,
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

  Widget _buildEmptyState() {
    return Container(
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
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: darkColor.withAlpha(153),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search terms',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: darkColor.withAlpha(102)),
          ),
        ],
      ),
    );
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
              'Currency changes will apply to new entries',
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
}
