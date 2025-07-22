import 'package:flutter/material.dart';
import 'package:payables/data/currency_provider.dart';
import 'package:payables/ui/subscription_details_screen.dart';
import 'package:provider/provider.dart';
import 'addsubs_screen.dart';
import '../data/subscription_database.dart';
import '../models/subscription.dart';
import 'dart:io';
import '../models/currency.dart';
import '../data/currency_database.dart';

class SubscriptionScreen extends StatefulWidget {
  final List<Map<String, dynamic>>? categories;
  final String? title;
  const SubscriptionScreen({super.key, this.categories, this.title});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  bool _isSearchOpen = false;
  List<Subscription> _subscriptions = [];
  List<Subscription> _filteredSubscriptions = [];
  double _scrollOffset = 0.0;
  double _totalMonthlyAmount = 0.0;
  String? _activeBillingCycleFilter;
  String? _activeCategoryFilter;
  DateTime _lastUpdated = DateTime.now();

  // Sorting state
  SortBy _sortBy = SortBy.createdDate;
  SortDirection _sortDirection = SortDirection.descending;

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
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Move the subscription loading here to ensure context is available for Provider
    _loadSubscriptions();
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _searchController.addListener(() {
      _filterSubscriptions(_searchController.text);
    });
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

  void _calculateTotalMonthlyAmount() {
    double total = 0;
    final selectedDisplayCurrency = Provider.of<CurrencyProvider>(
      context,
      listen: false,
    ).selectedCurrency;
    for (final subscription in _subscriptions) {
      if (subscription.currency == selectedDisplayCurrency) {
        total += _getMonthlyAmount(subscription);
      }
    }
    if (mounted) {
      setState(() {
        _totalMonthlyAmount = total;
      });
    }
  }

  Future<void> _loadSubscriptions() async {
    try {
      setState(() {
        _isLoading = true;
      });

      List<Subscription> subscriptions;

      // Handle special titles for paused and finished subscriptions
      if (widget.title == 'Paused') {
        subscriptions = await SubscriptionDatabase.getPausedSubscriptions();
      } else if (widget.title == 'Finished') {
        subscriptions = await SubscriptionDatabase.getFinishedSubscriptions();
      } else {
        subscriptions = await SubscriptionDatabase.getAllSubscriptions();
      }

      setState(() {
        _subscriptions = subscriptions;
        _filteredSubscriptions = List.from(_subscriptions);
        _isLoading = false;
        _lastUpdated = DateTime.now();
      });
      _calculateTotalMonthlyAmount();
    } catch (e) {
      debugPrint('Error loading subscriptions: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterSubscriptions(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredSubscriptions = List.from(_subscriptions);
      } else {
        _filteredSubscriptions = _subscriptions.where((subscription) {
          final titleMatches = subscription.title.toLowerCase().contains(
            query.toLowerCase(),
          );
          final descriptionMatches =
              subscription.shortDescription?.toLowerCase().contains(
                query.toLowerCase(),
              ) ??
              false;
          final categoryMatches = subscription.category.toLowerCase().contains(
            query.toLowerCase(),
          );

          return titleMatches || descriptionMatches || categoryMatches;
        }).toList();
      }

      // Apply filters if they are active
      if (_activeBillingCycleFilter != null) {
        _filteredSubscriptions = _filteredSubscriptions
            .where((s) => s.billingCycle == _activeBillingCycleFilter)
            .toList();
      }
      if (_activeCategoryFilter != null) {
        _filteredSubscriptions = _filteredSubscriptions
            .where((s) => s.category == _activeCategoryFilter)
            .toList();
      }

      // Apply sorting
      _sortSubscriptions();
    });
  }

  void _sortSubscriptions() {
    _filteredSubscriptions.sort((a, b) {
      int comparison;
      switch (_sortBy) {
        case SortBy.title:
          comparison = a.title.toLowerCase().compareTo(b.title.toLowerCase());
          break;
        case SortBy.amount:
          comparison = a.amount.compareTo(b.amount);
          break;
        case SortBy.nextBilling:
          comparison = a.billingDate.compareTo(b.billingDate);
          break;
        case SortBy.createdDate:
          comparison = a.createdAt.compareTo(b.createdAt);
          break;
      }
      // Apply direction
      return _sortDirection == SortDirection.ascending
          ? comparison
          : -comparison;
    });
  }

  void _showSearchBottomSheet() {
    setState(() {
      _isSearchOpen = true;
    });
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return _buildM3SearchInterface();
      },
    ).whenComplete(() {
      _searchController.clear();
      setState(() {
        _isSearchOpen = false;
      });
    });
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return _buildM3FilterInterface();
      },
    );
  }

  void _showSortBottomSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return _buildM3SortInterface();
      },
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: () async {
              await _loadSubscriptions();
            },
            color: highContrastBlue,
            backgroundColor: backgroundColor,
            strokeWidth: 2.0,
            displacement: 16.0,
            child: CustomScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // M3 Expressive Large Flexible App Bar
                SliverAppBar(
                  floating: false,
                  pinned: true,
                  snap: false,
                  elevation: 0,
                  surfaceTintColor: lightColor,
                  backgroundColor: backgroundColor,
                  leading: BackButton(color: highContrastDarkBlue),
                  title: widget.title != null
                      ? Text(
                          widget.title!,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: highContrastDarkBlue,
                              ),
                        )
                      : null,
                  actions: [
                    Padding(
                      padding: const EdgeInsets.only(right: 16.0),
                      child: _buildM3PopupMenu(),
                    ),
                  ],
                ),
                // M3 Expressive Dashboard Content
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 32.0),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _buildTotalAmountCard(),
                      const SizedBox(height: 24),
                      _buildSubscriptionsContent(),
                      SizedBox(
                        height: 32 + MediaQuery.of(context).padding.bottom,
                      ),
                    ]),
                  ),
                ),
              ],
            ),
          ),
          // Empty State
          if (!_isLoading && _filteredSubscriptions.isEmpty && !_isSearchOpen)
            _buildEmptyState(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _subscriptions.isEmpty ? 'No Payables Yet' : 'No Results Found',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w500,
                color: highContrastDarkBlue,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _subscriptions.isEmpty
                  ? 'Add your first payable to get started tracking your recurring payments.'
                  : 'Try adjusting your search terms or clearing the search.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: darkColor.withAlpha(153),
                height: 1.5,
              ),
            ),
            if (_subscriptions.isEmpty) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          AddSubsScreen(categories: widget.categories),
                    ),
                  ).then((result) async {
                    if (result == true || result == 'categories_updated') {
                      if (mounted) {
                        await _loadSubscriptions();
                      }
                    }
                  });
                },
                icon: Icon(Icons.add_rounded, color: Colors.white),
                label: Text(
                  'Add Payable',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: highContrastBlue,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTotalAmountCard() {
    final currencyProvider = Provider.of<CurrencyProvider>(context);
    final selectedDisplayCurrency = currencyProvider.selectedCurrency;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'This month',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: darkColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${_getCurrencySymbol(selectedDisplayCurrency)}${_totalMonthlyAmount.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  color: highContrastDarkBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _formatLastUpdated(),
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: darkColor),
              ),
            ],
          ),
          _buildCurrencyDropdown(),
        ],
      ),
    );
  }

  String _getCurrencySymbol(String currencyCode) {
    final currency = CurrencyDatabase.getCurrencyByCode(currencyCode);
    return currency?.symbol ?? currencyCode;
  }

  String _formatLastUpdated() {
    final now = DateTime.now();
    final difference = now.difference(_lastUpdated);

    if (difference.inMinutes < 1) {
      return 'Updated just now';
    } else if (difference.inMinutes == 1) {
      return 'Updated 1 minute ago';
    } else if (difference.inMinutes < 60) {
      return 'Updated ${difference.inMinutes} minutes ago';
    } else if (difference.inHours == 1) {
      return 'Updated 1 hour ago';
    } else if (difference.inHours < 24) {
      return 'Updated ${difference.inHours} hours ago';
    } else if (difference.inDays == 1) {
      return 'Updated 1 day ago';
    } else {
      return 'Updated ${difference.inDays} days ago';
    }
  }

  Widget _buildCurrencyDropdown() {
    final currencyProvider = Provider.of<CurrencyProvider>(context);
    final selectedDisplayCurrency = currencyProvider.selectedCurrency;

    return Container(
      decoration: BoxDecoration(
        color: lightColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: darkColor.withAlpha(50), width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            // Main Action Button
            InkWell(
              onTap: () {
                // This could be a shortcut action, e.g., cycle through favorite currencies
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  selectedDisplayCurrency,
                  style: TextStyle(
                    color: highContrastDarkBlue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            // Divider
            Container(width: 1, height: 24, color: darkColor.withAlpha(50)),
            // Popup Menu Button for currency selection
            Material(
              color: Colors.transparent,
              child: PopupMenuButton<String>(
                icon: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: darkColor,
                  size: 24,
                ),
                onSelected: (String newValue) {
                  currencyProvider.setCurrency(newValue);
                  _calculateTotalMonthlyAmount();
                },
                itemBuilder: (BuildContext context) {
                  return CurrencyDatabase.getCurrencies().map((
                    Currency currency,
                  ) {
                    return PopupMenuItem<String>(
                      value: currency.code,
                      // Material 3 List Item Specifications
                      height: 48, // 48dp list item height
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12, // 12dp left/right padding
                      ),
                      child: Text(
                        '${currency.code} (${currency.symbol})',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w400,
                          color: highContrastDarkBlue,
                        ),
                        // Material 3 text alignment specifications
                        textAlign: TextAlign.start, // Start-aligned horizontal
                      ),
                    );
                  }).toList();
                },
                // Material 3 Menu Container Specifications
                constraints: const BoxConstraints(
                  minWidth: 112, // 112dp min width
                  maxWidth: 280, // 280dp max width
                ),
                color: backgroundColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4), // 4dp corner radius
                ),
                splashRadius: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildM3SearchInterface() {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(26),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Search field with M3 styling
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: lightColor.withAlpha(100),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: darkColor.withAlpha(51),
                            width: 1,
                          ),
                        ),
                        child: TextField(
                          controller: _searchController,
                          autofocus: true,
                          style: TextStyle(
                            color: highContrastDarkBlue,
                            fontSize: 16,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Search subscriptions...',
                            hintStyle: TextStyle(
                              color: darkColor.withAlpha(153),
                            ),
                            prefixIcon: Icon(
                              Icons.search_rounded,
                              color: darkColor,
                              size: 20,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: highContrastBlue,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildM3PopupMenu() {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    return PopupMenuButton<String>(
      icon: Container(
        width: 48, // 48dp minimum touch target
        height: 48,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: Colors.transparent,
        ),
        child: Icon(
          Icons.more_vert_rounded,
          color: const Color(0xFF43474e),
          size: 24, // 24dp icon size as per Material 3
        ),
      ),
      splashRadius: 24,
      offset: const Offset(0, 50),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          12,
        ), // 12dp corner radius for modern look
      ),
      elevation: 8,
      color: isDark
          ? const Color(0xFF1E1E1E)
          : const Color(0xFFFFFFFF), // Dynamic background
      surfaceTintColor: Colors.transparent, // Remove surface tint
      shadowColor: isDark
          ? const Color(0x40000000) // Darker shadow for dark mode
          : const Color(
              0x1F000000,
            ), // Material 3 menu shadow color (12% opacity black)
      constraints: const BoxConstraints(
        minWidth: 112, // Material 3 min width
        maxWidth: 280, // Material 3 max width
      ),
      // Custom Material 3 expressive transitions
      popUpAnimationStyle: AnimationStyle(
        duration: const Duration(milliseconds: 300),
        reverseDuration: const Duration(milliseconds: 250),
        curve: Curves.easeInOutCubicEmphasized,
        reverseCurve: Curves.easeInCubic,
      ),
      onSelected: (String value) {
        switch (value) {
          case 'search':
            _showSearchBottomSheet();
            break;
          case 'add':
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    AddSubsScreen(categories: widget.categories),
              ),
            ).then((result) async {
              // Reload subscriptions if a new one was added
              if (result == true || result == 'categories_updated') {
                if (mounted) {
                  await _loadSubscriptions();
                }
              }
            });
            break;
          case 'filter':
            _showFilterBottomSheet();
            break;
          case 'sort':
            _showSortBottomSheet();
            break;
        }
      },
      itemBuilder: (BuildContext context) => [
        _buildM3PopupMenuItem(
          value: 'search',
          text: 'Search',
          icon: Icons.search_rounded,
          color: const Color(0xFF43474e),
        ),
        _buildM3PopupMenuItem(
          value: 'add',
          text: 'Add',
          icon: Icons.add_circle_rounded,
          color: const Color(0xFF43474e),
        ),
        _buildM3PopupMenuItem(
          value: 'filter',
          text: 'Filter',
          icon: Icons.filter_list_rounded,
          color: const Color(0xFF43474e),
        ),
        _buildM3PopupMenuItem(
          value: 'sort',
          text: 'Sort',
          icon: Icons.sort_rounded,
          color: const Color(0xFF43474e),
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
    final isDark = brightness == Brightness.dark;

    return PopupMenuItem<String>(
      value: value,
      // Material 3 List Item Specifications
      height: 48, // 48dp list item height
      padding: const EdgeInsets.symmetric(
        horizontal: 16, // 16dp left/right padding for better spacing
        vertical: 8, // 8dp vertical padding
      ),
      child: Row(
        children: [
          // Leading icon without background
          Icon(
            icon,
            color: isDark ? Colors.white.withAlpha(230) : color,
            size: 24, // 24dp icon size as per Material 3
          ),
          const SizedBox(width: 16), // 16dp padding between elements
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w400,
                color: isDark
                    ? Colors.white.withAlpha(230)
                    : highContrastDarkBlue,
              ),
              // Material 3 text alignment specifications
              textAlign: TextAlign.start,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionsContent() {
    if (_isLoading) {
      return Card(
        elevation: 0,
        color: lightColor.withAlpha(150),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Center(
            child: CircularProgressIndicator(
              color: highContrastBlue,
              strokeWidth: 2.0,
            ),
          ),
        ),
      );
    }
    if (_filteredSubscriptions.isEmpty) {
      return const SizedBox.shrink(); // Empty state is handled by the Stack now
    }
    return _buildSubscriptionsList();
  }

  Widget _buildM3FilterInterface() {
    return StatefulBuilder(
      builder: (BuildContext context, StateSetter setState) {
        return Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              24.0,
              16.0,
              24.0,
              24.0 + MediaQuery.of(context).padding.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16.0),
                    decoration: BoxDecoration(
                      color: darkColor.withAlpha(102),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  'Filter Payables',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: highContrastDarkBlue,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'By Billing Cycle',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: darkColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8.0,
                  runSpacing: 8.0,
                  children: ['Daily', 'Weekly', 'Monthly', 'Yearly']
                      .map(
                        (cycle) => FilterChip(
                          label: Text(cycle),
                          selected: _activeBillingCycleFilter == cycle,
                          onSelected: (selected) {
                            setState(() {
                              _activeBillingCycleFilter = selected
                                  ? cycle
                                  : null;
                            });
                          },
                          backgroundColor: lightColor.withAlpha(100),
                          selectedColor: highContrastBlue,
                          labelStyle: TextStyle(
                            color: _activeBillingCycleFilter == cycle
                                ? Colors.white
                                : highContrastDarkBlue,
                            fontWeight: FontWeight.w600,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: _activeBillingCycleFilter == cycle
                                  ? Colors.transparent
                                  : darkColor.withAlpha(51),
                              width: 1,
                            ),
                          ),
                          showCheckmark: true,
                          checkmarkColor: Colors.white,
                          selectedShadowColor: highContrastBlue.withAlpha(100),
                          elevation: _activeBillingCycleFilter == cycle ? 4 : 0,
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 24),
                Text(
                  'By Category',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: darkColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8.0,
                  runSpacing: 8.0,
                  children:
                      [
                            'Entertainment',
                            'Productivity',
                            'Health',
                            'Finance',
                            'Education',
                            'Not set',
                          ]
                          .map(
                            (category) => FilterChip(
                              label: Text(category),
                              selected: _activeCategoryFilter == category,
                              onSelected: (selected) {
                                setState(() {
                                  _activeCategoryFilter = selected
                                      ? category
                                      : null;
                                });
                              },
                              backgroundColor: lightColor.withAlpha(100),
                              selectedColor: highContrastBlue,
                              labelStyle: TextStyle(
                                color: _activeCategoryFilter == category
                                    ? Colors.white
                                    : highContrastDarkBlue,
                                fontWeight: FontWeight.w600,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(
                                  color: _activeCategoryFilter == category
                                      ? Colors.transparent
                                      : darkColor.withAlpha(51),
                                  width: 1,
                                ),
                              ),
                              showCheckmark: true,
                              checkmarkColor: Colors.white,
                              selectedShadowColor: highContrastBlue.withAlpha(
                                100,
                              ),
                              elevation: _activeCategoryFilter == category
                                  ? 4
                                  : 0,
                            ),
                          )
                          .toList(),
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _activeBillingCycleFilter = null;
                            _activeCategoryFilter = null;
                          });
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          side: BorderSide(color: darkColor),
                          foregroundColor: darkColor,
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        child: const Text('Reset'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          this.setState(() {
                            _filterSubscriptions(_searchController.text);
                          });
                          Navigator.pop(context);
                        },
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          backgroundColor: highContrastBlue,
                          foregroundColor: Colors.white,
                          elevation: 2,
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        child: const Text('Apply Filters'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildM3SortInterface() {
    return StatefulBuilder(
      builder: (BuildContext context, StateSetter setState) {
        return Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              24.0,
              16.0,
              24.0,
              24.0 + MediaQuery.of(context).padding.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16.0),
                    decoration: BoxDecoration(
                      color: darkColor.withAlpha(102),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  'Sort Payables',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: highContrastDarkBlue,
                  ),
                ),
                const SizedBox(height: 24),

                // Sort By section
                Text(
                  'Sort By',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: darkColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8.0,
                  runSpacing: 8.0,
                  children: SortBy.values
                      .map(
                        (sortBy) => FilterChip(
                          label: Text(sortBy.displayName),
                          selected: _sortBy == sortBy,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _sortBy = sortBy;
                              });
                            }
                          },
                          showCheckmark: true,
                          checkmarkColor: Colors.white,
                          backgroundColor: lightColor.withAlpha(100),
                          selectedColor: highContrastBlue,
                          labelStyle: TextStyle(
                            color: _sortBy == sortBy
                                ? Colors.white
                                : highContrastDarkBlue,
                            fontWeight: FontWeight.w600,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: _sortBy == sortBy
                                  ? Colors.transparent
                                  : darkColor.withAlpha(51),
                              width: 1,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),

                const SizedBox(height: 24),

                // Direction section
                Text(
                  'Direction',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: darkColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8.0,
                  runSpacing: 8.0,
                  children: SortDirection.values
                      .map(
                        (direction) => FilterChip(
                          label: Text(direction.displayName),
                          selected: _sortDirection == direction,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _sortDirection = direction;
                              });
                            }
                          },
                          avatar: Icon(
                            direction == SortDirection.ascending
                                ? Icons.arrow_upward_rounded
                                : Icons.arrow_downward_rounded,
                            size: 16,
                            color: _sortDirection == direction
                                ? Colors.white
                                : highContrastDarkBlue,
                          ),
                          showCheckmark: false,
                          backgroundColor: lightColor.withAlpha(100),
                          selectedColor: highContrastBlue,
                          labelStyle: TextStyle(
                            color: _sortDirection == direction
                                ? Colors.white
                                : highContrastDarkBlue,
                            fontWeight: FontWeight.w600,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: _sortDirection == direction
                                  ? Colors.transparent
                                  : darkColor.withAlpha(51),
                              width: 1,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),

                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _sortBy = SortBy.createdDate;
                            _sortDirection = SortDirection.descending;
                          });
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          side: BorderSide(color: darkColor),
                          foregroundColor: darkColor,
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        child: const Text('Reset'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          this.setState(() {
                            _filterSubscriptions(_searchController.text);
                          });
                          Navigator.pop(context);
                        },
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          backgroundColor: highContrastBlue,
                          foregroundColor: Colors.white,
                          elevation: 2,
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        child: const Text('Apply'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSubscriptionsList() {
    return Column(
      children: [
        for (int i = 0; i < _filteredSubscriptions.length; i++) ...[
          _buildM3SubscriptionCard(
            _filteredSubscriptions[i],
            index: i,
            isLast: i == _filteredSubscriptions.length - 1,
          ),
          if (i < _filteredSubscriptions.length - 1) const SizedBox(height: 2),
        ],
      ],
    );
  }

  Widget _buildM3SubscriptionCard(
    Subscription subscription, {
    required int index,
    required bool isLast,
  }) {
    final color = Color(subscription.colorValue);
    final dueDate = _formatDueDate(subscription.billingDate);
    final price =
        '${subscription.currency} ${subscription.amount.toStringAsFixed(2)}';

    Widget iconWidget;
    if (subscription.iconFilePath != null) {
      iconWidget = SizedBox(
        width: 48,
        height: 48,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16.0),
          child: Image.file(
            File(subscription.iconFilePath!),
            fit: BoxFit.contain,
          ),
        ),
      );
    } else {
      iconWidget = Container(
        width: 48,
        height: 48,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white.withAlpha(153), Colors.white.withAlpha(128)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(
          IconData(
            subscription.iconCodePoint ?? 0xe047, // Default to category icon
            fontFamily: 'MaterialIcons',
          ),
          size: 24,
          color: Colors.white,
        ),
      );
    }

    // Determine border radius based on position - stacked card pattern
    BorderRadius borderRadius;
    if (index == 0 && _filteredSubscriptions.length == 1) {
      // Single card: 24px all corners
      borderRadius = BorderRadius.circular(24);
    } else if (index == 0) {
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
      color: color,
      shape: RoundedRectangleBorder(borderRadius: borderRadius),
      child: InkWell(
        onTap: () {
          _navigateToSubscriptionDetails(subscription);
        },
        borderRadius: borderRadius,
        splashColor: Colors.white.withAlpha(51),
        highlightColor: Colors.white.withAlpha(26),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              // Icon with enhanced styling
              iconWidget,
              const SizedBox(width: 16),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subscription.title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subscription.shortDescription ?? subscription.category,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withAlpha(179),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_rounded,
                          size: 16,
                          color: Colors.white.withAlpha(179),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          dueDate,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Colors.white.withAlpha(179),
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Price with enhanced styling
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(41),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withAlpha(77),
                    width: 1,
                  ),
                ),
                child: Text(
                  price,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToSubscriptionDetails(Subscription subscription) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SubscriptionDetailsScreen(
          subscription: subscription,
          categories: widget.categories,
        ),
      ),
    );

    if (result == true || result == 'categories_updated') {
      _loadSubscriptions(); // Refresh the list if changes were saved

      // If categories were updated, we might need to refresh the categories list
      // This will be handled by the parent screen (dashboard) when it receives the result
    }
  }

  String _formatDueDate(DateTime billingDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final billingDay = DateTime(
      billingDate.year,
      billingDate.month,
      billingDate.day,
    );

    final difference = billingDay.difference(today).inDays;

    if (difference == 0) {
      return 'Due today';
    } else if (difference == 1) {
      return 'Due tomorrow';
    } else if (difference > 1 && difference <= 7) {
      return 'Due in $difference days';
    } else if (difference > 7 && difference <= 30) {
      final weeks = (difference / 7).floor();
      return weeks == 1 ? 'Due in 1 week' : 'Due in $weeks weeks';
    } else if (difference > 30) {
      final months = (difference / 30).floor();
      return months == 1 ? 'Due in 1 month' : 'Due in $months months';
    } else {
      // Past due
      final daysPast = difference.abs();
      if (daysPast == 1) {
        return 'Due yesterday';
      } else if (daysPast <= 7) {
        return '$daysPast days overdue';
      } else {
        return 'Overdue';
      }
    }
  }
}

enum SortBy {
  title,
  amount,
  nextBilling,
  createdDate;

  String get displayName {
    switch (this) {
      case SortBy.title:
        return 'Title';
      case SortBy.amount:
        return 'Amount';
      case SortBy.nextBilling:
        return 'Next Billing';
      case SortBy.createdDate:
        return 'Date Added';
    }
  }
}

enum SortDirection {
  ascending,
  descending;

  String get displayName {
    switch (this) {
      case SortDirection.ascending:
        return 'Ascending';
      case SortDirection.descending:
        return 'Descending';
    }
  }
}
