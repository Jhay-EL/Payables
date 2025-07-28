import 'package:flutter/material.dart';
import 'dart:async';
import 'package:payables/data/subscription_database.dart';
import 'package:payables/models/subscription.dart';
import 'package:payables/widgets/optimized_payable_card.dart';
import 'package:payables/utils/performance_utils.dart';
import 'package:payables/ui/subscription_details_screen.dart';
import 'package:payables/ui/addsubs_screen.dart';

class OptimizedSubscriptionScreen extends StatefulWidget {
  final List<Map<String, dynamic>>? categories;
  final String? title;

  const OptimizedSubscriptionScreen({super.key, this.categories, this.title});

  @override
  State<OptimizedSubscriptionScreen> createState() =>
      _OptimizedSubscriptionScreenState();
}

class _OptimizedSubscriptionScreenState
    extends State<OptimizedSubscriptionScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  List<Subscription> _subscriptions = [];
  List<Subscription> _filteredSubscriptions = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String? _activeCategoryFilter;
  String? _activeStatusFilter;

  // Performance optimizations
  Timer? _searchDebounceTimer;

  @override
  void initState() {
    super.initState();
    _loadSubscriptions();
    _setupSearchListener();
  }

  void _setupSearchListener() {
    _searchController.addListener(() {
      _searchDebounceTimer?.cancel();
      _searchDebounceTimer = Timer(const Duration(milliseconds: 300), () {
        if (mounted) {
          setState(() {
            _searchQuery = _searchController.text;
          });
          _filterSubscriptions();
        }
      });
    });
  }

  Future<void> _loadSubscriptions() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Use performance measurement
      PerformanceUtils.measurePerformance('Load Subscriptions', () async {
        final subscriptions = await SubscriptionDatabase.getAllSubscriptions();

        if (mounted) {
          setState(() {
            _subscriptions = subscriptions;
            _filteredSubscriptions = subscriptions;
            _isLoading = false;
          });
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _filterSubscriptions() {
    if (!mounted) return;

    PerformanceUtils.measurePerformance('Filter Subscriptions', () {
      List<Subscription> filtered = _subscriptions;

      // Apply search filter
      if (_searchQuery.isNotEmpty) {
        filtered = filtered.where((subscription) {
          return subscription.title.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ) ||
              (subscription.shortDescription?.toLowerCase().contains(
                    _searchQuery.toLowerCase(),
                  ) ??
                  false) ||
              subscription.category.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              );
        }).toList();
      }

      // Apply category filter
      if (_activeCategoryFilter != null && _activeCategoryFilter != 'All') {
        filtered = filtered.where((subscription) {
          return subscription.category == _activeCategoryFilter;
        }).toList();
      }

      // Apply status filter
      if (_activeStatusFilter != null && _activeStatusFilter != 'All') {
        filtered = filtered.where((subscription) {
          return subscription.status == _activeStatusFilter;
        }).toList();
      }

      setState(() {
        _filteredSubscriptions = filtered;
      });
    });
  }

  void _onSubscriptionTap(Subscription subscription) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            SubscriptionDetailsScreen(subscription: subscription),
      ),
    );

    if (result == true) {
      _loadSubscriptions();
    }
  }

  void _onAddSubscription() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddSubsScreen(categories: widget.categories),
      ),
    );

    if (result == true) {
      _loadSubscriptions();
    }
  }

  @override
  void dispose() {
    _searchDebounceTimer?.cancel();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(widget.title ?? 'Subscriptions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _onAddSubscription,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and filter section
          _buildSearchAndFilterSection(),

          // Subscriptions list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildSubscriptionsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilterSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Search bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search subscriptions...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('All', null, _activeCategoryFilter),
                if (widget.categories != null) ...[
                  for (final category in widget.categories!)
                    _buildFilterChip(
                      category['name'],
                      category['name'],
                      _activeCategoryFilter,
                    ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Status filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('All', null, _activeStatusFilter),
                _buildFilterChip('Active', 'active', _activeStatusFilter),
                _buildFilterChip('Paused', 'paused', _activeStatusFilter),
                _buildFilterChip('Finished', 'finished', _activeStatusFilter),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String? value, String? activeFilter) {
    final isSelected = activeFilter == value;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            if (value == null) {
              _activeCategoryFilter = null;
              _activeStatusFilter = null;
            } else if (['active', 'paused', 'finished'].contains(value)) {
              _activeStatusFilter = selected ? value : null;
            } else {
              _activeCategoryFilter = selected ? value : null;
            }
          });
          _filterSubscriptions();
        },
      ),
    );
  }

  Widget _buildSubscriptionsList() {
    if (_filteredSubscriptions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.subscriptions_outlined,
              size: 64,
              color: Theme.of(context).disabledColor,
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No subscriptions found'
                  : 'No subscriptions',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (_searchQuery.isEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Add your first subscription to get started',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).disabledColor,
                ),
              ),
            ],
          ],
        ),
      );
    }

    return PerformanceUtils.buildOptimizedList(
      items: _filteredSubscriptions,
      itemBuilder: (context, subscription, index) {
        return OptimizedPayableCard(
          subscription: subscription,
          onTap: () => _onSubscriptionTap(subscription),
        );
      },
      controller: _scrollController,
    );
  }
}
