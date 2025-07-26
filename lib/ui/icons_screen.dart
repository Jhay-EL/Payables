import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../data/database_helper.dart';
import '../data/custom_icon_database.dart';

class IconsScreen extends StatefulWidget {
  final Object? selectedIcon;
  final Function(Object) onIconSelected;

  const IconsScreen({
    super.key,
    this.selectedIcon,
    required this.onIconSelected,
  });

  @override
  State<IconsScreen> createState() => _IconsScreenState();
}

class _IconsScreenState extends State<IconsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoadingDatabase = true;
  bool _databaseError = false;
  List<Map<String, dynamic>> _databaseIcons = [];
  List<String> _databaseTables = [];

  // Search controllers
  final _genericSearchController = TextEditingController();
  final _presetsSearchController = TextEditingController();
  final _genericSearchFocusNode = FocusNode();
  final _presetsSearchFocusNode = FocusNode();
  final _genericSearchQuery = ValueNotifier<String>('');
  final _presetsSearchQuery = ValueNotifier<String>('');

  // Search visibility state
  bool _isSearchVisible = false;

  // Custom Icons
  final _customIconDb = CustomIconDatabase();
  List<Map<String, dynamic>> _customIcons = [];
  bool _isLoadingCustomIcons = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {
        // Hide search when switching tabs
        if (_isSearchVisible) {
          _isSearchVisible = false;
          _genericSearchController.clear();
          _presetsSearchController.clear();
          _genericSearchQuery.value = '';
          _presetsSearchQuery.value = '';
        }
      });
    });
    _initializeDatabase();
    _loadCustomIcons();

    _genericSearchController.addListener(
      () => _genericSearchQuery.value = _genericSearchController.text,
    );
    _presetsSearchController.addListener(
      () => _presetsSearchQuery.value = _presetsSearchController.text,
    );
  }

  Future<void> _loadCustomIcons() async {
    setState(() => _isLoadingCustomIcons = true);
    final icons = await _customIconDb.getIcons();
    if (mounted) {
      setState(() {
        _customIcons = icons;
        _isLoadingCustomIcons = false;
      });
    }
  }

  Future<void> _initializeDatabase() async {
    try {
      setState(() {
        _isLoadingDatabase = true;
        _databaseError = false;
      });

      await DatabaseHelper.database;
      _databaseTables = await DatabaseHelper.getAllTables();
      _databaseIcons = await DatabaseHelper.getSubscriptionIcons();

      if (_databaseIcons.isEmpty && _databaseTables.isNotEmpty) {
        for (String tableName in _databaseTables) {
          await DatabaseHelper.getTableData(tableName);
        }
      }

      if (!mounted) return;
      setState(() {
        _isLoadingDatabase = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingDatabase = false;
        _databaseError = true;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _genericSearchController.dispose();
    _presetsSearchController.dispose();
    _genericSearchFocusNode.dispose();
    _presetsSearchFocusNode.dispose();
    _genericSearchQuery.dispose();
    _presetsSearchQuery.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF121212)
          : const Color(0xFFF2F7FF),
      appBar: AppBar(
        title: !_isSearchVisible
            ? Text(
                'Choose Icon',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              )
            : null,
        backgroundColor: isDark
            ? const Color(0xFF121212)
            : const Color(0xFFF2F7FF),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // Search Icon Button - Animated visibility to prevent overlap
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: (!_isSearchVisible && _tabController.index != 2)
                ? IconButton(
                    key: const ValueKey('search_button'),
                    icon: Icon(
                      Icons.search_rounded,
                      color: colorScheme.onSurface,
                    ),
                    onPressed: () {
                      setState(() {
                        _isSearchVisible = true;
                      });
                      // Focus the search field after a short delay
                      Future.delayed(const Duration(milliseconds: 100), () {
                        if (mounted) {
                          FocusManager.instance.primaryFocus?.unfocus();
                        }
                      });
                    },
                  ).animate().fadeIn(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                  )
                : const SizedBox.shrink(),
          ),
          // Animated Search Bar with circle-to-oblong expansion
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 120),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return AnimatedBuilder(
                animation: animation,
                builder: (context, child) {
                  return Transform.scale(
                    scaleX: Tween<double>(begin: 0.1, end: 1.0)
                        .animate(
                          CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeOutCubic,
                          ),
                        )
                        .value,
                    scaleY: Tween<double>(begin: 0.1, end: 1.0)
                        .animate(
                          CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeOutCubic,
                          ),
                        )
                        .value,
                    child: Opacity(opacity: animation.value, child: child),
                  );
                },
                child: child,
              );
            },
            child: _isSearchVisible && _tabController.index != 2
                ? SizedBox(
                        key: const ValueKey('search'),
                        width: MediaQuery.of(context).size.width - 60,
                        child: Padding(
                          padding: const EdgeInsets.only(
                            left: 4.0,
                            right: 16.0,
                          ),
                          child: Container(
                            height: 48,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? colorScheme.surfaceContainerHighest
                                        .withValues(alpha: 0.6)
                                  : colorScheme.surfaceContainerHighest
                                        .withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: colorScheme.outline.withValues(
                                  alpha: 0.3,
                                ),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(left: 16.0),
                                  child:
                                      Icon(
                                        Icons.search_rounded,
                                        color: colorScheme.onSurfaceVariant,
                                        size: 22,
                                      ).animate().fadeIn(
                                        duration: const Duration(
                                          milliseconds: 80,
                                        ),
                                        delay: const Duration(milliseconds: 40),
                                      ),
                                ),
                                Expanded(
                                  child:
                                      Container(
                                        height: 48,
                                        alignment: Alignment.center,
                                        child: TextField(
                                          controller: _tabController.index == 0
                                              ? _genericSearchController
                                              : _presetsSearchController,
                                          focusNode: _tabController.index == 0
                                              ? _genericSearchFocusNode
                                              : _presetsSearchFocusNode,
                                          autofocus: true,
                                          decoration: InputDecoration(
                                            hintText: _tabController.index == 0
                                                ? 'Search icons...'
                                                : 'Search services...',
                                            hintStyle: TextStyle(
                                              color:
                                                  colorScheme.onSurfaceVariant,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w400,
                                            ),
                                            border: InputBorder.none,
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                  vertical: 0,
                                                ),
                                            isDense: true,
                                          ),
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyLarge
                                              ?.copyWith(
                                                color: colorScheme.onSurface,
                                                fontSize: 16,
                                                fontWeight: FontWeight.w400,
                                              ),
                                          onChanged: (value) {
                                            if (_tabController.index == 0) {
                                              _genericSearchQuery.value = value;
                                            } else {
                                              _presetsSearchQuery.value = value;
                                            }
                                          },
                                          onSubmitted: (value) {
                                            setState(() {
                                              _isSearchVisible = false;
                                            });
                                          },
                                        ),
                                      ).animate().fadeIn(
                                        duration: const Duration(
                                          milliseconds: 120,
                                        ),
                                        delay: const Duration(milliseconds: 60),
                                      ),
                                ),
                                if ((_tabController.index == 0 &&
                                        _genericSearchController
                                            .text
                                            .isNotEmpty) ||
                                    (_tabController.index == 1 &&
                                        _presetsSearchController
                                            .text
                                            .isNotEmpty))
                                  IconButton(
                                    onPressed: () {
                                      if (_tabController.index == 0) {
                                        _genericSearchController.clear();
                                        _genericSearchQuery.value = '';
                                      } else {
                                        _presetsSearchController.clear();
                                        _presetsSearchQuery.value = '';
                                      }
                                    },
                                    icon:
                                        Icon(
                                          Icons.clear_rounded,
                                          color: colorScheme.onSurfaceVariant,
                                          size: 22,
                                        ).animate().scale(
                                          duration: const Duration(
                                            milliseconds: 200,
                                          ),
                                          curve: Curves.easeOutBack,
                                        ),
                                    padding: const EdgeInsets.all(8),
                                    constraints: const BoxConstraints(
                                      minWidth: 40,
                                      minHeight: 40,
                                    ),
                                  ),
                                IconButton(
                                  onPressed: () {
                                    if (_tabController.index == 0) {
                                      _genericSearchController.clear();
                                      _genericSearchQuery.value = '';
                                    } else {
                                      _presetsSearchController.clear();
                                      _presetsSearchQuery.value = '';
                                    }
                                    setState(() {
                                      _isSearchVisible = false;
                                    });
                                  },
                                  icon:
                                      Icon(
                                        Icons.close_rounded,
                                        color: colorScheme.onSurfaceVariant,
                                        size: 22,
                                      ).animate().rotate(
                                        duration: const Duration(
                                          milliseconds: 300,
                                        ),
                                        curve: Curves.easeInOut,
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
                      )
                      .animate()
                      .scale(
                        begin: const Offset(0.1, 0.1),
                        duration: const Duration(milliseconds: 120),
                        curve: Curves.easeOutCubic,
                      )
                      .fadeIn(
                        duration: const Duration(milliseconds: 100),
                        delay: const Duration(milliseconds: 30),
                      )
                : const SizedBox.shrink(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildGenericIconsTab(),
                _buildPresetIconsTab(),
                _buildCustomIconsTab(),
              ],
            ),
          ),
          // Material 3 Navigation Bar - Full Width
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: 8,
              bottom: 8 + MediaQuery.of(context).padding.bottom,
            ),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              border: Border(
                top: BorderSide(
                  color: colorScheme.outline.withValues(alpha: 0.12),
                  width: 0.5,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildNavigationItem(
                    0,
                    'Generic',
                    Icons.category_rounded,
                  ),
                ),
                Expanded(
                  child: _buildNavigationItem(1, 'Presets', Icons.apps_rounded),
                ),
                Expanded(
                  child: _buildNavigationItem(
                    2,
                    'Custom',
                    Icons.photo_library_rounded,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenericIconsTab() {
    final Map<String, IconData> genericIcons = {
      'Money': Icons.attach_money_rounded,
      'Chart': Icons.bar_chart_rounded,
      'Transport': Icons.directions_bike_rounded,
      'Book': Icons.book_rounded,
      'Bookmark': Icons.bookmark_rounded,
      'Art': Icons.brush_rounded,
      'Tools': Icons.build_rounded,
      'Bus': Icons.directions_bus_rounded,
      'Food': Icons.cake_rounded,
      'Calendar': Icons.calendar_today_rounded,
      'Camera': Icons.camera_rounded,
      'Car': Icons.directions_car_rounded,
      'Category': Icons.category_rounded,
      'Cloud': Icons.cloud_rounded,
      'Coffee': Icons.local_cafe_rounded,
      'Computer': Icons.computer_rounded,
      'Card': Icons.credit_card_rounded,
      'Devices': Icons.devices_rounded,
      'Event': Icons.event_rounded,
      'Media': Icons.fast_forward_rounded,
      'Heart': Icons.favorite_rounded,
      'Fitness': Icons.fitness_center_rounded,
      'Flight': Icons.flight_rounded,
      'Gaming': Icons.sports_esports_rounded,
      'Gas': Icons.local_gas_station_rounded,
      'Group': Icons.group_rounded,
      'Music': Icons.headphones_rounded,
      'Home': Icons.home_rounded,
      'Hospital': Icons.local_hospital_rounded,
      'Hotel': Icons.hotel_rounded,
      'Light': Icons.lightbulb_rounded,
      'Location': Icons.location_on_rounded,
      'Mail': Icons.mail_rounded,
      'Map': Icons.map_rounded,
      'Memory': Icons.memory_rounded,
      'Mic': Icons.mic_rounded,
      'Movie': Icons.movie_rounded,
      'Library': Icons.library_music_rounded,
      'Note': Icons.music_note_rounded,
      'Queue': Icons.queue_music_rounded,
      'Notifications': Icons.notifications_rounded,
      'Park': Icons.park_rounded,
      'Pause': Icons.pause_rounded,
      'Pets': Icons.pets_rounded,
      'Phone': Icons.phone_rounded,
      'Photo': Icons.photo_camera_rounded,

      'Pizza': Icons.local_pizza_rounded,
      'Play': Icons.play_circle_filled_rounded,
      'Playlist': Icons.playlist_play_rounded,
      'Radio': Icons.radio_rounded,
      'Receipt': Icons.receipt_long_rounded,
      'Repeat': Icons.repeat_rounded,
      'Restaurant': Icons.restaurant_rounded,
      'School': Icons.school_rounded,
      'Security': Icons.security_rounded,
      'Settings': Icons.settings_rounded,
      'Share': Icons.share_rounded,
      'Shopping': Icons.shopping_bag_rounded,
      'Cart': Icons.shopping_cart_rounded,
      'Trending': Icons.show_chart_rounded,
      'Shuffle': Icons.shuffle_rounded,
      'Next': Icons.skip_next_rounded,
      'Previous': Icons.skip_previous_rounded,
      'Speaker': Icons.speaker_rounded,
      'Star': Icons.star_rounded,
      'Stop': Icons.stop_rounded,
      'Storage': Icons.storage_rounded,
      'Tablet': Icons.tablet_rounded,
      'Theaters': Icons.theaters_rounded,
      'Train': Icons.train_rounded,
      'Traffic': Icons.traffic_rounded,
      'TV': Icons.tv_rounded,
      'Video': Icons.videocam_rounded,
      'Voice': Icons.record_voice_over_rounded,
      'Volume': Icons.volume_up_rounded,
      'Key': Icons.vpn_key_rounded,
      'Walk': Icons.directions_walk_rounded,
      'Wallet': Icons.account_balance_wallet_rounded,
      'Watch': Icons.watch_rounded,
      'Water': Icons.water_drop_rounded,
      'WiFi': Icons.wifi_rounded,
      'Work': Icons.work_rounded,
    };

    return ValueListenableBuilder<String>(
      valueListenable: _genericSearchQuery,
      builder: (context, searchQuery, _) {
        final filteredIcons = genericIcons.entries.where((entry) {
          final iconName = entry.key.toLowerCase();
          return iconName.contains(searchQuery.toLowerCase());
        }).toList();

        if (filteredIcons.isEmpty) {
          return _buildEmptyState(
            icon: Icons.search_off_rounded,
            title: 'No icons found',
            subtitle: 'Try adjusting your search terms',
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 6,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1,
          ),
          itemCount: filteredIcons.length,
          itemBuilder: (context, index) {
            final iconEntry = filteredIcons[index];
            final icon = iconEntry.value;
            final isSelected = widget.selectedIcon == icon;

            return _buildIconCard(
              icon: icon,
              isSelected: isSelected,
              onTap: () {
                widget.onIconSelected(icon);
                Navigator.pop(context);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildPresetIconsTab() {
    return ValueListenableBuilder<String>(
      valueListenable: _presetsSearchQuery,
      builder: (context, searchQuery, _) {
        if (_isLoadingDatabase) {
          return const Center(child: CircularProgressIndicator());
        }

        if (_databaseError) {
          return _buildErrorState();
        }

        final filteredIcons = _databaseIcons.where((icon) {
          final iconName = icon['name']?.toString().toLowerCase() ?? '';
          return iconName.contains(searchQuery.toLowerCase());
        }).toList();

        if (filteredIcons.isEmpty) {
          return _buildEmptyState(
            icon: Icons.category_outlined,
            title: 'No services found',
            subtitle: 'Try adjusting your search terms',
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1,
          ),
          itemCount: filteredIcons.length,
          itemBuilder: (context, index) {
            final iconData = filteredIcons[index];
            final iconName = iconData['name'] ?? 'Unknown';
            final IconData icon = IconData(
              iconData['code_point'] ?? 0,
              fontFamily: 'MaterialIcons',
            );
            final isSelected = widget.selectedIcon == icon;

            return Tooltip(
              message: iconName,
              child: _buildIconCard(
                icon: icon,
                isSelected: isSelected,
                onTap: () {
                  widget.onIconSelected(icon);
                  Navigator.pop(context);
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCustomIconsTab() {
    if (_isLoadingCustomIcons) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_customIcons.isEmpty) {
      return _buildUploadButton();
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1,
      ),
      itemCount: _customIcons.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return _buildUploadButton(isGridItem: true);
        }

        final iconData = _customIcons[index - 1];
        final path = iconData['path'] as String;
        final id = iconData['id'] as int;
        final file = File(path);
        final isSelected = widget.selectedIcon == file;

        return GestureDetector(
          onTap: () {
            widget.onIconSelected(file);
            Navigator.pop(context);
          },
          onLongPress: () => _deleteCustomIcon(id, path),
          child: _buildCustomIconCard(file: file, isSelected: isSelected),
        );
      },
    );
  }

  Widget _buildIconCard({
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child:
            Container(
              decoration: BoxDecoration(
                color: isSelected
                    ? colorScheme.primary
                    : isDark
                    ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.4)
                    : colorScheme.surfaceContainerHighest.withValues(
                        alpha: 0.3,
                      ),
                borderRadius: BorderRadius.circular(16),
                border: isSelected
                    ? Border.all(color: colorScheme.primary, width: 2)
                    : isDark
                    ? Border.all(
                        color: colorScheme.outline.withValues(alpha: 0.2),
                        width: 1,
                      )
                    : null,
                boxShadow: isDark && !isSelected
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                icon,
                size: 28,
                color: isSelected
                    ? colorScheme.onPrimary
                    : colorScheme.onSurfaceVariant,
              ),
            ).animate().scale(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              begin: const Offset(0.95, 0.95),
              end: const Offset(1.0, 1.0),
            ),
      ),
    );
  }

  Widget _buildCustomIconCard({required File file, required bool isSelected}) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        child:
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: isSelected
                    ? Border.all(color: colorScheme.primary, width: 2)
                    : isDark
                    ? Border.all(
                        color: colorScheme.outline.withValues(alpha: 0.3),
                        width: 1,
                      )
                    : null,
                boxShadow: isDark && !isSelected
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
                image: DecorationImage(
                  image: FileImage(file),
                  fit: BoxFit.contain,
                ),
              ),
            ).animate().scale(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              begin: const Offset(0.95, 0.95),
              end: const Offset(1.0, 1.0),
            ),
      ),
    );
  }

  Widget _buildUploadButton({bool isGridItem = false}) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (isGridItem) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _pickAndSaveIcon,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              color: isDark
                  ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.4)
                  : colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? colorScheme.outline.withValues(alpha: 0.4)
                    : colorScheme.outline.withValues(alpha: 0.3),
                width: 1,
              ),
              boxShadow: isDark
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              Icons.add_photo_alternate_outlined,
              size: 32,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 80, 0, 100),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark
                    ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.4)
                    : colorScheme.surfaceContainerHighest.withValues(
                        alpha: 0.3,
                      ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark
                      ? colorScheme.outline.withValues(alpha: 0.4)
                      : colorScheme.outline.withValues(alpha: 0.3),
                  width: 1,
                ),
                boxShadow: isDark
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                Icons.cloud_upload_outlined,
                size: 48,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Upload from Gallery',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap here to select a custom icon from your device',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _pickAndSaveIcon,
              icon: const Icon(Icons.add_photo_alternate_rounded),
              label: const Text('Choose Icon'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? action,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(32, 32, 32, 100),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            if (action != null) ...[const SizedBox(height: 24), action],
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(32, 32, 32, 100),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Error Loading Presets',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Could not load the icon database.\nPlease check your connection or try again later.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _initializeDatabase,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndSaveIcon() async {
    final status = await Permission.photos.request();

    if (status.isGranted) {
      try {
        final result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['jpg', 'jpeg', 'png', 'ico'],
        );

        if (result != null && result.files.single.path != null) {
          final path = result.files.single.path!;
          await _customIconDb.insertIcon(path);
          _loadCustomIcons();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error picking icon: $e'),
              backgroundColor: Theme.of(context).colorScheme.errorContainer,
            ),
          );
        }
      }
    } else if (status.isPermanentlyDenied) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Permission Denied'),
            content: const Text(
              'Please grant access to your photo library in app settings to select custom icons.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  openAppSettings();
                  Navigator.pop(context);
                },
                child: const Text('Open Settings'),
              ),
            ],
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Photo library permission is required to pick icons.',
            ),
            backgroundColor: Theme.of(context).colorScheme.errorContainer,
          ),
        );
      }
    }
  }

  Future<void> _deleteCustomIcon(int id, String path) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Icon?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _customIconDb.deleteIcon(id, path);
      _loadCustomIcons();
    }
  }

  Widget _buildNavigationItem(int index, String label, IconData icon) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSelected = _tabController.index == index;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          _tabController.animateTo(index);
        },
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon with selection indicator
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                padding: EdgeInsets.symmetric(
                  horizontal: isSelected ? 12 : 0,
                  vertical: isSelected ? 8 : 0,
                ),
                decoration: isSelected
                    ? BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(16),
                      )
                    : null,
                child: Icon(
                  icon,
                  color: isSelected
                      ? colorScheme.onPrimaryContainer
                      : colorScheme.onSurfaceVariant,
                  size: 24,
                ),
              ),
              const SizedBox(height: 4),
              // Label with proper typography
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: Theme.of(context).textTheme.labelSmall!.copyWith(
                  color: isSelected
                      ? colorScheme.onSurface
                      : colorScheme.onSurfaceVariant,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
                child: Text(label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
