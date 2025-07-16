import 'package:flutter/material.dart';
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

  // New state variables from dashboard
  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0.0;

  // Search controllers
  final _genericSearchController = TextEditingController();
  final _presetsSearchController = TextEditingController();
  final _genericSearchFocusNode = FocusNode();
  final _presetsSearchFocusNode = FocusNode();
  final _genericSearchQuery = ValueNotifier<String>('');
  final _presetsSearchQuery = ValueNotifier<String>('');

  // Custom Icons
  final _customIconDb = CustomIconDatabase();
  List<Map<String, dynamic>> _customIcons = [];
  bool _isLoadingCustomIcons = true;

  // New color getters from dashboard
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
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() => setState(() {}));
    _initializeDatabase();
    _scrollController.addListener(_onScroll);
    _loadCustomIcons();

    _genericSearchController.addListener(
      () => _genericSearchQuery.value = _genericSearchController.text,
    );
    _presetsSearchController.addListener(
      () => _presetsSearchQuery.value = _presetsSearchController.text,
    );
  }

  void _onScroll() {
    final newOffset = _scrollController.offset;
    if ((newOffset - _scrollOffset).abs() > 1.0) {
      setState(() {
        _scrollOffset = newOffset;
      });
    }
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

      // Initialize database and examine structure
      await DatabaseHelper.database;

      // Get all tables
      _databaseTables = await DatabaseHelper.getAllTables();

      // Get icons
      _databaseIcons = await DatabaseHelper.getSubscriptionIcons();

      // If no specific icon data, try to get data from all tables
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
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _genericSearchController.dispose();
    _presetsSearchController.dispose();
    _genericSearchFocusNode.dispose();
    _presetsSearchFocusNode.dispose();
    _genericSearchQuery.dispose();
    _presetsSearchQuery.dispose();
    super.dispose();
  }

  // Animation helpers
  static const double _expandedHeight = 60.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: NestedScrollView(
        controller: _scrollController,
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return <Widget>[
            SliverAppBar(
              expandedHeight: _expandedHeight,
              floating: true,
              pinned: true,
              snap: false,
              elevation: 0,
              backgroundColor: backgroundColor,
              surfaceTintColor: Colors.transparent,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: Container(color: backgroundColor),
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _SearchBarDelegate(
                backgroundColor: backgroundColor,
                height: _tabController.index != 2 ? 60.0 : 0.0,
                child: _tabController.index != 2
                    ? _buildSearchBarForCurrentTab()
                    : const SizedBox.shrink(),
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildGenericIconsTab(),
            _buildPresetIconsTab(),
            _buildCustomIconsTab(),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        color: backgroundColor,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 30),
            child: TabBar(
              dividerColor: Colors.transparent,
              controller: _tabController,
              tabs: const [
                Tab(text: 'Generic'),
                Tab(text: 'Presets'),
                Tab(text: 'Custom'),
              ],
              labelStyle: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              unselectedLabelStyle: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
              labelColor: highContrastBlue,
              unselectedLabelColor: darkColor,
              indicator: _TopUnderlineTabIndicator(
                borderSide: BorderSide(color: highContrastBlue, width: 3),
                borderRadius: const BorderRadius.all(Radius.circular(12)),
              ),
              splashBorderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBarForCurrentTab() {
    final isGeneric = _tabController.index == 0;
    final controller = isGeneric
        ? _genericSearchController
        : _presetsSearchController;
    final focusNode = isGeneric
        ? _genericSearchFocusNode
        : _presetsSearchFocusNode;
    final hintText = isGeneric ? 'Search icons...' : 'Search services...';

    return GestureDetector(
      onTap: () {
        if (focusNode.hasFocus) {
          focusNode.unfocus();
        }
      },
      child: Container(
        color: backgroundColor,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(fontSize: 14, color: darkColor),
            prefixIcon: Icon(Icons.search_rounded, color: darkColor, size: 22),
            suffixIcon: controller.text.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear_rounded, color: darkColor, size: 22),
                    onPressed: () => controller.clear(),
                  )
                : null,
            filled: true,
            fillColor: lightColor.withAlpha(150),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.all(0),
          ),
        ),
      ),
    );
  }

  Widget _buildGenericIconsTab() {
    final Map<String, IconData> genericIcons = {
      'Attach Money': Icons.attach_money_rounded,
      'Bar Chart': Icons.bar_chart_rounded,
      'Bicycle': Icons.directions_bike_rounded,
      'Book': Icons.book_rounded,
      'Bookmark': Icons.bookmark_rounded,
      'Brush': Icons.brush_rounded,
      'Build': Icons.build_rounded,
      'Bus': Icons.directions_bus_rounded,
      'Cake': Icons.cake_rounded,
      'Calendar': Icons.calendar_today_rounded,
      'Camera': Icons.camera_rounded,
      'Car': Icons.directions_car_rounded,
      'Category': Icons.category_rounded,
      'Cloud': Icons.cloud_rounded,
      'Coffee': Icons.local_cafe_rounded,
      'Computer': Icons.computer_rounded,
      'Credit Card': Icons.credit_card_rounded,
      'Devices': Icons.devices_rounded,
      'Event': Icons.event_rounded,
      'Fast Forward': Icons.fast_forward_rounded,
      'Fast Rewind': Icons.fast_rewind_rounded,
      'Favorite': Icons.favorite_rounded,
      'Fitness': Icons.fitness_center_rounded,
      'Flight': Icons.flight_rounded,
      'Gaming': Icons.sports_esports_rounded,
      'Gas Station': Icons.local_gas_station_rounded,
      'Group': Icons.group_rounded,
      'Headphones': Icons.headphones_rounded,
      'Home': Icons.home_rounded,
      'Hospital': Icons.local_hospital_rounded,
      'Hotel': Icons.hotel_rounded,
      'Lightbulb': Icons.lightbulb_rounded,
      'Location': Icons.location_on_rounded,
      'Mail': Icons.mail_rounded,
      'Map': Icons.map_rounded,
      'Memory': Icons.memory_rounded,
      'Mic': Icons.mic_rounded,
      'Movie': Icons.movie_rounded,
      'Music Library': Icons.library_music_rounded,
      'Music Note': Icons.music_note_rounded,
      'Music Queue': Icons.queue_music_rounded,
      'Notifications': Icons.notifications_rounded,
      'Park': Icons.park_rounded,
      'Pause': Icons.pause_rounded,
      'Pets': Icons.pets_rounded,
      'Phone': Icons.phone_rounded,
      'Photo Camera': Icons.photo_camera_rounded,
      'Pie Chart': Icons.pie_chart_rounded,
      'Pizza': Icons.local_pizza_rounded,
      'Play Circle': Icons.play_circle_filled_rounded,
      'Playlist': Icons.playlist_play_rounded,
      'Radio': Icons.radio_rounded,
      'Receipt': Icons.receipt_long_rounded,
      'Repeat': Icons.repeat_rounded,
      'Restaurant': Icons.restaurant_rounded,
      'School': Icons.school_rounded,
      'Security': Icons.security_rounded,
      'Settings': Icons.settings_rounded,
      'Share': Icons.share_rounded,
      'Shopping Bag': Icons.shopping_bag_rounded,
      'Shopping Cart': Icons.shopping_cart_rounded,
      'Show Chart': Icons.show_chart_rounded,
      'Shuffle': Icons.shuffle_rounded,
      'Skip Next': Icons.skip_next_rounded,
      'Skip Previous': Icons.skip_previous_rounded,
      'Speaker': Icons.speaker_rounded,
      'Star': Icons.star_rounded,
      'Stop': Icons.stop_rounded,
      'Storage': Icons.storage_rounded,
      'Tablet': Icons.tablet_rounded,
      'Theaters': Icons.theaters_rounded,
      'Train': Icons.train_rounded,
      'Traffic': Icons.traffic_rounded,
      'TV': Icons.tv_rounded,
      'Videocam': Icons.videocam_rounded,
      'Voice Over': Icons.record_voice_over_rounded,
      'Volume Up': Icons.volume_up_rounded,
      'VPN Key': Icons.vpn_key_rounded,
      'Walk': Icons.directions_walk_rounded,
      'Wallet': Icons.account_balance_wallet_rounded,
      'Watch': Icons.watch_rounded,
      'Water Drop': Icons.water_drop_rounded,
      'Wifi': Icons.wifi_rounded,
      'Work': Icons.work_rounded,
    };

    return ValueListenableBuilder<String>(
      valueListenable: _genericSearchQuery,
      builder: (context, searchQuery, _) {
        final filteredIcons = genericIcons.entries.where((entry) {
          final iconName = entry.key.toLowerCase();
          return iconName.contains(searchQuery.toLowerCase());
        }).toList();

        return Container(
          color: backgroundColor,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Generic Icons',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w400,
                  color: highContrastDarkBlue,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Choose from a collection of common icons',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: darkColor),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: filteredIcons.isEmpty
                    ? Center(
                        child: Text(
                          'No icons found',
                          style: Theme.of(
                            context,
                          ).textTheme.titleMedium?.copyWith(color: darkColor),
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.only(bottom: 32),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 6,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                            ),
                        itemCount: filteredIcons.length,
                        itemBuilder: (context, index) {
                          final iconEntry = filteredIcons[index];
                          final icon = iconEntry.value;
                          final isSelected = widget.selectedIcon == icon;

                          return GestureDetector(
                            onTap: () {
                              widget.onIconSelected(icon);
                              Navigator.pop(context);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? highContrastBlue
                                    : lightColor.withAlpha(150),
                                borderRadius: BorderRadius.circular(16),
                                border: isSelected
                                    ? Border.all(
                                        color: highContrastBlue.withAlpha(150),
                                        width: 2,
                                      )
                                    : Border.all(
                                        color: Colors.transparent,
                                        width: 2,
                                      ),
                              ),
                              child: Icon(
                                icon,
                                size: 28,
                                color: isSelected ? Colors.white : darkColor,
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPresetIconsTab() {
    return ValueListenableBuilder<String>(
      valueListenable: _presetsSearchQuery,
      builder: (context, searchQuery, _) {
        final filteredIcons = _databaseIcons.where((icon) {
          final iconName = icon['name']?.toString().toLowerCase() ?? '';
          return iconName.contains(searchQuery.toLowerCase());
        }).toList();

        return GestureDetector(
          onTap: () {
            // Unfocus search bar when tapping outside
            if (_presetsSearchFocusNode.hasFocus) {
              _presetsSearchFocusNode.unfocus();
            }
          },
          child: Container(
            color: backgroundColor,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Preset Icons',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w400,
                    color: highContrastDarkBlue,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Choose from a list of popular services',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: darkColor),
                ),
                const SizedBox(height: 20),

                // Content Area
                _isLoadingDatabase
                    ? const Center(child: CircularProgressIndicator())
                    : _databaseError
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline_rounded,
                              size: 48,
                              color: Colors.red[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Error Loading Presets',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: highContrastDarkBlue,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Could not load the icon database.\nPlease check your connection or try again later.',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: darkColor),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: _initializeDatabase,
                              icon: const Icon(Icons.refresh_rounded),
                              label: const Text('Retry'),
                              style: ElevatedButton.styleFrom(
                                foregroundColor: Colors.white,
                                backgroundColor: highContrastBlue,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : filteredIcons.isEmpty
                    ? Center(
                        child: Text(
                          'No services found',
                          style: Theme.of(
                            context,
                          ).textTheme.titleMedium?.copyWith(color: darkColor),
                        ),
                      )
                    : Expanded(
                        child: GridView.builder(
                          padding: const EdgeInsets.only(bottom: 32),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 5,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                              ),
                          itemCount: filteredIcons.length,
                          itemBuilder: (context, index) {
                            final iconData = filteredIcons[index];
                            final iconName = iconData['name'] ?? 'Unknown';

                            // Placeholder for icon from database
                            final IconData icon = IconData(
                              iconData['code_point'] ?? 0,
                              fontFamily: 'MaterialIcons',
                            );
                            final isSelected = widget.selectedIcon == icon;

                            return Tooltip(
                              message: iconName,
                              child: GestureDetector(
                                onTap: () {
                                  widget.onIconSelected(icon);
                                  Navigator.pop(context);
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? highContrastBlue
                                        : lightColor.withAlpha(150),
                                    borderRadius: BorderRadius.circular(16),
                                    border: isSelected
                                        ? Border.all(
                                            color: highContrastBlue.withAlpha(
                                              150,
                                            ),
                                            width: 2,
                                          )
                                        : Border.all(
                                            color: Colors.transparent,
                                            width: 2,
                                          ),
                                  ),
                                  child: Icon(
                                    icon,
                                    size: 32,
                                    color: isSelected
                                        ? Colors.white
                                        : darkColor,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
              ],
            ),
          ),
        );
      },
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
          _loadCustomIcons(); // Refresh the list
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error picking icon: $e')));
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
          const SnackBar(
            content: Text(
              'Photo library permission is required to pick icons.',
            ),
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

  Widget _buildCustomIconsTab() {
    return Container(
      color: backgroundColor,
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Custom Icons',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w400,
              color: highContrastDarkBlue,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Upload your own icon from your gallery',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: darkColor),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: _isLoadingCustomIcons
                ? const Center(child: CircularProgressIndicator())
                : _customIcons.isEmpty
                ? Center(child: _buildUploadButton())
                : GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 5,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                    itemCount: _customIcons.length + 1, // +1 for the button
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return _buildUploadButton(isGridItem: true);
                      }
                      final iconData = _customIcons[index - 1];
                      final path = iconData['path'] as String;
                      final id = iconData['id'] as int;
                      final file = File(path);

                      return GestureDetector(
                        onTap: () {
                          widget.onIconSelected(file);
                          Navigator.pop(context);
                        },
                        onLongPress: () => _deleteCustomIcon(id, path),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            image: DecorationImage(
                              image: FileImage(file),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadButton({bool isGridItem = false}) {
    if (isGridItem) {
      return GestureDetector(
        onTap: _pickAndSaveIcon,
        child: Container(
          decoration: BoxDecoration(
            color: lightColor.withAlpha(100),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: darkColor.withAlpha(51), width: 1),
          ),
          child: Icon(
            Icons.add_photo_alternate_outlined,
            size: 32,
            color: darkColor.withAlpha(102),
          ),
        ),
      );
    }
    return Center(
      child: GestureDetector(
        onTap: _pickAndSaveIcon,
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: lightColor.withAlpha(100),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: darkColor.withAlpha(51), width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.cloud_upload_outlined,
                size: 64,
                color: darkColor.withAlpha(102),
              ),
              const SizedBox(height: 16),
              Text(
                'Upload from Gallery',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: highContrastDarkBlue,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tap here to select a custom icon from your device.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: darkColor.withAlpha(153),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchBarDelegate extends SliverPersistentHeaderDelegate {
  const _SearchBarDelegate({
    required this.child,
    required this.backgroundColor,
    required this.height,
  });

  final Widget child;
  final Color backgroundColor;
  final double height;

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(color: backgroundColor, child: child);
  }

  @override
  bool shouldRebuild(_SearchBarDelegate oldDelegate) {
    return child != oldDelegate.child ||
        backgroundColor != oldDelegate.backgroundColor ||
        height != oldDelegate.height;
  }
}

class _TopUnderlineTabIndicator extends Decoration {
  const _TopUnderlineTabIndicator({
    this.borderSide = const BorderSide(width: 2.0, color: Colors.white),
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
  });

  final BorderSide borderSide;

  final BorderRadiusGeometry borderRadius;

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) {
    return _TopUnderlinePainter(this, onChanged);
  }
}

class _TopUnderlinePainter extends BoxPainter {
  _TopUnderlinePainter(this.decoration, VoidCallback? onChanged)
    : super(onChanged);

  final _TopUnderlineTabIndicator decoration;

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    assert(configuration.size != null);
    final Rect rect = offset & configuration.size!;
    final Rect indicator = rect;

    final Rect topIndicator = Rect.fromLTWH(
      indicator.left,
      indicator.top,
      indicator.width,
      decoration.borderSide.width,
    );

    final Paint paint = decoration.borderSide.toPaint()
      ..strokeCap = StrokeCap.round;
    final RRect rrect = RRect.fromRectAndCorners(
      topIndicator,
      topLeft: (decoration.borderRadius as BorderRadius).topLeft,
      topRight: (decoration.borderRadius as BorderRadius).topRight,
      bottomLeft: (decoration.borderRadius as BorderRadius).bottomLeft,
      bottomRight: (decoration.borderRadius as BorderRadius).bottomRight,
    );
    canvas.drawRRect(rrect, paint);
  }
}
