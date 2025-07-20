import 'package:flutter/material.dart';
import 'package:payables/data/currency_provider.dart';
import 'package:provider/provider.dart';
import 'addsubs_screen.dart';
import '../data/subscription_database.dart';
import '../models/subscription.dart';
import 'dart:io';
import '../models/currency.dart';
import '../data/currency_database.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

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
        ? const Color(0xFFB3C5D7)
        : const Color(0xFF477BA5);
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
        : const Color(0xFF001A27);
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

      final subscriptions = await SubscriptionDatabase.getAllSubscriptions();

      setState(() {
        _subscriptions = subscriptions;
        _filteredSubscriptions = List.from(_subscriptions);
        _isLoading = false;
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
          CustomScrollView(
            controller: _scrollController,
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
                      builder: (context) => const AddSubsScreen(),
                    ),
                  ).then((result) {
                    if (result == true) {
                      _loadSubscriptions();
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
              Row(
                children: [
                  Text(
                    'This month',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: darkColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.play_arrow_rounded, color: darkColor, size: 20),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${_getCurrencySymbol(selectedDisplayCurrency)}${_totalMonthlyAmount.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: highContrastDarkBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Updated just now',
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
                icon: Icon(Icons.keyboard_arrow_down_rounded, color: darkColor),
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
                      child: Text(
                        '${currency.code} (${currency.symbol})',
                        style: TextStyle(
                          color: highContrastDarkBlue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList();
                },
                color: backgroundColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                splashRadius: 20,
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
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_vert_rounded,
        color: highContrastDarkBlue,
        size: 24,
      ),
      splashRadius: 24,
      offset: const Offset(0, 50),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 8,
      color: backgroundColor,
      surfaceTintColor: lightColor,
      shadowColor: Colors.black.withAlpha(40),
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
              MaterialPageRoute(builder: (context) => const AddSubsScreen()),
            ).then((result) {
              // Reload subscriptions if a new one was added
              if (result == true) {
                _loadSubscriptions();
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
          text: 'Search Payables',
          icon: Icons.search_rounded,
          color: highContrastBlue,
        ),
        _buildM3PopupMenuItem(
          value: 'add',
          text: 'Add Payable',
          icon: Icons.add_circle_rounded,
          color: const Color(0xFF10B981),
        ),
        _buildM3PopupMenuItem(
          value: 'filter',
          text: 'Filter',
          icon: Icons.filter_list_rounded,
          color: const Color(0xFF3B82F6),
        ),
        _buildM3PopupMenuItem(
          value: 'sort',
          text: 'Sort',
          icon: Icons.sort_rounded,
          color: const Color(0xFF8B5CF6),
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
    return PopupMenuItem<String>(
      value: value,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: highContrastDarkBlue,
              ),
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
            child: CircularProgressIndicator(color: highContrastBlue),
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

    Widget iconContent;
    if (subscription.iconFilePath != null) {
      iconContent = ClipRRect(
        borderRadius: BorderRadius.circular(16.0),
        child: Image.file(
          File(subscription.iconFilePath!),
          width: 24,
          height: 24,
          fit: BoxFit.cover,
        ),
      );
    } else {
      iconContent = Icon(
        IconData(
          subscription.iconCodePoint ?? 0xe047, // Default to category icon
          fontFamily: 'MaterialIcons',
        ),
        size: 24,
        color: Colors.white,
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
          _showSubscriptionDetailsPopup(subscription);
        },
        borderRadius: borderRadius,
        splashColor: Colors.white.withAlpha(51),
        highlightColor: Colors.white.withAlpha(26),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              // Icon with enhanced styling
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withAlpha(153),
                      Colors.white.withAlpha(128),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: iconContent,
              ),
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

  void _showSubscriptionDetailsPopup(Subscription subscription) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black.withAlpha(153),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return Center(
          child: Material(
            type: MaterialType.transparency,
            child: Container(
              margin: const EdgeInsets.all(20),
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.9,
                maxWidth: MediaQuery.of(context).size.width - 40,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(26),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: _SubscriptionEditPopup(
                  subscription: subscription,
                  onSave: (updatedSubscription) async {
                    try {
                      await SubscriptionDatabase.updateSubscription(
                        updatedSubscription,
                      );
                      if (!context.mounted) return;
                      Navigator.of(context).pop();
                      _loadSubscriptions(); // Refresh the list
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Payable updated successfully!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error updating subscription: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  onCancel: () => Navigator.of(context).pop(),
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return SlideTransition(
          position: Tween(
            begin: const Offset(0, 1),
            end: const Offset(0, 0),
          ).animate(CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic)),
          child: FadeTransition(opacity: anim1, child: child),
        );
      },
    );
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

class _SubscriptionEditPopup extends StatefulWidget {
  final Subscription subscription;
  final Function(Subscription) onSave;
  final VoidCallback onCancel;

  const _SubscriptionEditPopup({
    required this.subscription,
    required this.onSave,
    required this.onCancel,
  });

  @override
  State<_SubscriptionEditPopup> createState() => _SubscriptionEditPopupState();
}

class _SubscriptionEditPopupState extends State<_SubscriptionEditPopup> {
  late TextEditingController _titleController;
  late TextEditingController _amountController;
  late TextEditingController _websiteController;
  late TextEditingController _descriptionController;
  late TextEditingController _notesController;

  late String _selectedCurrency;
  late String _selectedBillingCycle;
  late String _selectedPaymentMethod;
  late String _selectedCategory;
  late DateTime _billingDate;
  late DateTime? _endDate;
  late Object _selectedIcon;
  late Color _selectedColor;

  bool _isEditing = false;

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
        ? const Color(0xFFB3C5D7)
        : const Color(0xFF477BA5);
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
        : const Color(0xFF001A27);
  }

  @override
  void initState() {
    super.initState();

    // Initialize controllers with current subscription data
    _titleController = TextEditingController(text: widget.subscription.title);
    _amountController = TextEditingController(
      text: widget.subscription.amount.toString(),
    );
    _websiteController = TextEditingController(
      text: widget.subscription.websiteLink ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.subscription.shortDescription ?? '',
    );
    _notesController = TextEditingController(
      text: widget.subscription.notes ?? '',
    );

    // Initialize dropdown and other values
    _selectedCurrency = widget.subscription.currency;
    _selectedBillingCycle = widget.subscription.billingCycle;
    _selectedPaymentMethod = widget.subscription.paymentMethod;
    _selectedCategory = widget.subscription.category;
    _billingDate = widget.subscription.billingDate;
    _endDate = widget.subscription.endDate;
    if (widget.subscription.iconFilePath != null) {
      _selectedIcon = File(widget.subscription.iconFilePath!);
    } else {
      _selectedIcon = IconData(
        widget.subscription.iconCodePoint ?? 0xe047,
        fontFamily: 'MaterialIcons',
      );
    }
    _selectedColor = Color(widget.subscription.colorValue);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _websiteController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _saveChanges() {
    // Validate required fields
    if (_titleController.text.trim().isEmpty) {
      _showErrorSnackBar('Please enter a payable title');
      return;
    }

    double? amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      _showErrorSnackBar('Please enter a valid amount');
      return;
    }

    // Create updated subscription
    final updatedSubscription = widget.subscription.copyWith(
      title: _titleController.text.trim(),
      amount: amount,
      currency: _selectedCurrency,
      billingDate: _billingDate,
      endDate: _endDate,
      billingCycle: _selectedBillingCycle,
      paymentMethod: _selectedPaymentMethod,
      websiteLink: _websiteController.text.trim().isEmpty
          ? null
          : _websiteController.text.trim(),
      shortDescription: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      category: _selectedCategory,
      iconCodePoint: _selectedIcon is IconData
          ? (_selectedIcon as IconData).codePoint
          : null,
      iconFilePath: _selectedIcon is File ? (_selectedIcon as File).path : null,
      colorValue: _selectedColor.toARGB32(),
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      updatedAt: DateTime.now(),
    );

    widget.onSave(updatedSubscription);
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  String _getBillingInfo() {
    DateTime now = DateTime.now();
    DateTime billingDate = _billingDate;

    // Calculate next billing date
    while (billingDate.isBefore(now)) {
      switch (_selectedBillingCycle) {
        case 'Daily':
          billingDate = billingDate.add(const Duration(days: 1));
          break;
        case 'Weekly':
          billingDate = billingDate.add(const Duration(days: 7));
          break;
        case 'Monthly':
          billingDate = DateTime(
            billingDate.year,
            billingDate.month + 1,
            billingDate.day,
          );
          break;
        case 'Yearly':
          billingDate = DateTime(
            billingDate.year + 1,
            billingDate.month,
            billingDate.day,
          );
          break;
      }
    }

    int daysUntilBilling = billingDate.difference(now).inDays;

    if (daysUntilBilling == 0) {
      return 'Due today';
    } else if (daysUntilBilling == 1) {
      return 'Due tomorrow';
    } else if (daysUntilBilling <= 7) {
      return 'Due in $daysUntilBilling days';
    } else if (daysUntilBilling <= 30) {
      int weeks = (daysUntilBilling / 7).floor();
      return weeks == 1 ? 'Due in 1 week' : 'Due in $weeks weeks';
    } else {
      int months = (daysUntilBilling / 30).floor();
      return months == 1 ? 'Due in 1 month' : 'Due in $months months';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header with controls - M3 styling
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: lightColor.withAlpha(100),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _selectedColor.withAlpha(41),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: _selectedIcon is IconData
                    ? Icon(
                        _selectedIcon as IconData,
                        color: _selectedColor,
                        size: 24,
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(16.0),
                        child: Image.file(
                          _selectedIcon as File,
                          width: 24,
                          height: 24,
                          fit: BoxFit.cover,
                        ),
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isEditing ? 'Edit Payable' : 'Payable Details',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.w500,
                            color: highContrastDarkBlue,
                            letterSpacing: -0.5,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _isEditing
                          ? 'Make changes to your payable'
                          : 'View and edit payable information',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: darkColor.withAlpha(179),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              if (!_isEditing) ...[
                IconButton(
                  onPressed: () {
                    setState(() {
                      _isEditing = true;
                    });
                  },
                  icon: const Icon(Icons.edit_rounded, size: 20),
                  style: IconButton.styleFrom(
                    backgroundColor: highContrastBlue.withAlpha(41),
                    foregroundColor: highContrastBlue,
                    padding: const EdgeInsets.all(12),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              IconButton(
                onPressed: widget.onCancel,
                icon: const Icon(Icons.close_rounded, size: 20),
                style: IconButton.styleFrom(
                  backgroundColor: darkColor.withAlpha(26),
                  foregroundColor: darkColor,
                  padding: const EdgeInsets.all(12),
                ),
              ),
            ],
          ),
        ),

        // Card Preview - Enhanced M3 styling
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_selectedColor, _selectedColor.withAlpha(230)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: _selectedColor.withAlpha(77),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                // Icon
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(128),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: _selectedIcon is IconData
                      ? Icon(
                          _selectedIcon as IconData,
                          size: 22,
                          color: Colors.white,
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(10.0),
                          child: Image.file(
                            _selectedIcon as File,
                            width: 22,
                            height: 22,
                            fit: BoxFit.cover,
                          ),
                        ),
                ),
                const SizedBox(width: 14),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _titleController.text.isEmpty
                            ? 'Payable Title'
                            : _titleController.text,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _descriptionController.text.isEmpty
                            ? _selectedCategory
                            : _descriptionController.text,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withAlpha(128),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 14,
                            color: Colors.white.withAlpha(128),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _getBillingInfo(),
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withAlpha(128),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Price
                Text(
                  _amountController.text.isEmpty
                      ? '$_selectedCurrency 0.00'
                      : '$_selectedCurrency ${_amountController.text}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Edit Form or Details View
        Flexible(child: _isEditing ? _buildEditForm() : _buildDetailsView()),

        // Bottom buttons for editing mode - M3 styling
        if (_isEditing)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: lightColor.withAlpha(80),
              border: Border(
                top: BorderSide(color: darkColor.withAlpha(51), width: 1),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _isEditing = false;
                        // Reset to original values
                        _titleController.text = widget.subscription.title;
                        _amountController.text = widget.subscription.amount
                            .toString();
                        _websiteController.text =
                            widget.subscription.websiteLink ?? '';
                        _descriptionController.text =
                            widget.subscription.shortDescription ?? '';
                        _notesController.text = widget.subscription.notes ?? '';
                        _selectedCurrency = widget.subscription.currency;
                        _selectedBillingCycle =
                            widget.subscription.billingCycle;
                        _selectedPaymentMethod =
                            widget.subscription.paymentMethod;
                        _selectedCategory = widget.subscription.category;
                        _billingDate = widget.subscription.billingDate;
                        _endDate = widget.subscription.endDate;
                        if (widget.subscription.iconFilePath != null) {
                          _selectedIcon = File(
                            widget.subscription.iconFilePath!,
                          );
                        } else {
                          _selectedIcon = IconData(
                            widget.subscription.iconCodePoint ?? 0xe047,
                            fontFamily: 'MaterialIcons',
                          );
                        }
                        _selectedColor = Color(widget.subscription.colorValue);
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      side: BorderSide(color: darkColor),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: darkColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FilledButton(
                    onPressed: _saveChanges,
                    style: FilledButton.styleFrom(
                      backgroundColor: _selectedColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Save Changes',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildEditForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Basic Information
          _buildTextField(
            controller: _titleController,
            hint: 'Title',
            onChanged: (value) => setState(() {}),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                flex: 1,
                child: _buildDropdownField(
                  value: _selectedCurrency,
                  items: ['EUR', 'USD', 'GBP', 'JPY', 'CAD', 'AUD'],
                  onChanged: (value) {
                    setState(() {
                      _selectedCurrency = value!;
                    });
                  },
                  label: 'Currency',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: _buildTextField(
                  controller: _amountController,
                  hint: '0.00',
                  keyboardType: TextInputType.number,
                  onChanged: (value) => setState(() {}),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _descriptionController,
            hint: 'Short description',
            onChanged: (value) => setState(() {}),
          ),
          const SizedBox(height: 16),
          _buildDropdownField(
            value: _selectedCategory,
            items: [
              'Not set',
              'Entertainment',
              'Productivity',
              'Health',
              'Finance',
              'Education',
            ],
            onChanged: (value) {
              setState(() {
                _selectedCategory = value!;
              });
            },
            label: 'Category',
          ),
          const SizedBox(height: 16),
          _buildDropdownField(
            value: _selectedBillingCycle,
            items: ['Daily', 'Weekly', 'Monthly', 'Yearly'],
            onChanged: (value) {
              setState(() {
                _selectedBillingCycle = value!;
              });
            },
            label: 'Billing Cycle',
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _websiteController,
            hint: 'Website link (optional)',
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _notesController,
            hint: 'Notes (optional)',
            maxLines: 3,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildDetailsView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.subscription.shortDescription != null) ...[
            _buildDetailItem(
              'Description',
              widget.subscription.shortDescription!,
              Icons.description_rounded,
            ),
            const SizedBox(height: 16),
          ],
          _buildDetailItem(
            'Billing Cycle',
            widget.subscription.billingCycle,
            Icons.loop_rounded,
          ),
          const SizedBox(height: 16),
          _buildDetailItem(
            'Next Billing Date',
            _formatDate(widget.subscription.billingDate),
            Icons.calendar_today_rounded,
          ),
          const SizedBox(height: 16),
          if (widget.subscription.endDate != null) ...[
            _buildDetailItem(
              'End Date',
              _formatDate(widget.subscription.endDate!),
              Icons.event_rounded,
            ),
            const SizedBox(height: 16),
          ],
          _buildDetailItem(
            'Payment Method',
            widget.subscription.paymentMethod,
            Icons.credit_card_rounded,
          ),
          const SizedBox(height: 16),
          _buildDetailItem(
            'Category',
            widget.subscription.category,
            Icons.category_rounded,
          ),
          const SizedBox(height: 16),
          if (widget.subscription.websiteLink != null) ...[
            _buildDetailItem(
              'Website',
              widget.subscription.websiteLink!,
              Icons.link_rounded,
              isLink: true,
            ),
            const SizedBox(height: 16),
          ],
          if (widget.subscription.notes != null &&
              widget.subscription.notes!.isNotEmpty) ...[
            _buildDetailItem(
              'Notes',
              widget.subscription.notes!,
              Icons.note_rounded,
            ),
            const SizedBox(height: 16),
          ],
          _buildDetailItem(
            'Created',
            _formatDate(widget.subscription.createdAt),
            Icons.add_circle_outline_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    int maxLines = 1,
    Function(String)? onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: lightColor.withAlpha(100),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: darkColor.withAlpha(51), width: 1),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        onChanged: onChanged,
        style: TextStyle(
          fontSize: 16,
          color: highContrastDarkBlue,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(18),
          hintText: hint,
          hintStyle: TextStyle(
            color: darkColor.withAlpha(153),
            fontSize: 16,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    String? label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      decoration: BoxDecoration(
        color: lightColor.withAlpha(100),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: darkColor.withAlpha(51), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label != null) ...[
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: darkColor.withAlpha(179),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
          ],
          DropdownButtonFormField<String>(
            value: value,
            items: items.map((item) {
              return DropdownMenuItem(
                value: item,
                child: Text(
                  item,
                  style: TextStyle(
                    fontSize: 16,
                    color: highContrastDarkBlue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
            onChanged: onChanged,
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
              isDense: true,
            ),
            dropdownColor: backgroundColor,
            style: TextStyle(
              fontSize: 16,
              color: highContrastDarkBlue,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(
    String label,
    String value,
    IconData icon, {
    bool isLink = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: lightColor.withAlpha(100),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: darkColor.withAlpha(51), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 40,
            child: Icon(icon, size: 20, color: _selectedColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: darkColor.withAlpha(179),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: isLink ? highContrastBlue : highContrastDarkBlue,
                    decoration: isLink ? TextDecoration.underline : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
