import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:payables/models/subscription.dart';

class SubscriptionDetailsScreen extends StatefulWidget {
  final Subscription subscription;

  const SubscriptionDetailsScreen({super.key, required this.subscription});

  @override
  State<SubscriptionDetailsScreen> createState() =>
      _SubscriptionDetailsScreenState();
}

class _SubscriptionDetailsScreenState extends State<SubscriptionDetailsScreen> {
  late TextEditingController _notesController;
  late Color _selectedColor;

  // Dynamic color system that adapts to dark/light mode
  Color get backgroundColor {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark
        ? const Color(0xFF121212)
        : const Color(0xFFF2F7FF);
  }

  Color get cardColor {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark
        ? const Color(0xFF1E1E1E)
        : const Color(0xFFE2EFFF);
  }

  Color get textColor {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark
        ? Colors.white
        : const Color(0xFF333333);
  }

  Color get secondaryTextColor {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark
        ? Colors.white70
        : const Color(0xFF666666);
  }

  // Menu-specific colors
  Color get highContrastDarkBlue {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark
        ? const Color(0xFFE3F2FD)
        : const Color(0xFF001A27);
  }

  Color get highContrastBlue {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark
        ? const Color(0xFF4FC3F7)
        : const Color(0xFF00AFEC);
  }

  Color get lightColor {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark
        ? const Color(0xFF1E1E1E)
        : const Color(0xFFD7EAFF);
  }

  @override
  void initState() {
    super.initState();

    _notesController = TextEditingController(
      text: widget.subscription.notes ?? '',
    );
    _selectedColor = Color(widget.subscription.colorValue);
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  String _getBillingInfo() {
    DateTime now = DateTime.now();
    DateTime billingDate = widget.subscription.billingDate;

    // Calculate next billing date
    while (billingDate.isBefore(now)) {
      switch (widget.subscription.billingCycle) {
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

  String _getNextPaymentDate() {
    DateTime now = DateTime.now();
    DateTime billingDate = widget.subscription.billingDate;

    // Calculate next billing date
    while (billingDate.isBefore(now)) {
      switch (widget.subscription.billingCycle) {
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

    return _formatDate(billingDate);
  }

  double _getTotalAmount() {
    // Calculate total based on billing cycle and start date
    DateTime now = DateTime.now();
    DateTime startDate = widget.subscription.createdAt;
    double monthlyAmount = widget.subscription.amount;

    if (widget.subscription.billingCycle == 'Monthly') {
      int months = (now.difference(startDate).inDays / 30).floor();
      return monthlyAmount * months;
    } else if (widget.subscription.billingCycle == 'Yearly') {
      int years = (now.difference(startDate).inDays / 365).floor();
      return monthlyAmount * 12 * years;
    } else if (widget.subscription.billingCycle == 'Weekly') {
      int weeks = (now.difference(startDate).inDays / 7).floor();
      return monthlyAmount * weeks;
    } else {
      int days = now.difference(startDate).inDays;
      return monthlyAmount * days;
    }
  }

  String _getSubscriptionDuration() {
    DateTime now = DateTime.now();
    DateTime startDate = widget.subscription.createdAt;
    int days = now.difference(startDate).inDays;

    if (days < 30) {
      return '$days days';
    } else if (days < 365) {
      int months = (days / 30).floor();
      return months == 1 ? '1 month' : '$months months';
    } else {
      int years = (days / 365).floor();
      int remainingMonths = ((days % 365) / 30).floor();
      if (remainingMonths == 0) {
        return years == 1 ? '1 year' : '$years years';
      } else {
        return '$years year${years > 1 ? 's' : ''} and $remainingMonths month${remainingMonths > 1 ? 's' : ''}';
      }
    }
  }

  int _getTotalPayments() {
    DateTime now = DateTime.now();
    DateTime startDate = widget.subscription.createdAt;

    if (widget.subscription.billingCycle == 'Monthly') {
      return (now.difference(startDate).inDays / 30).floor();
    } else if (widget.subscription.billingCycle == 'Yearly') {
      return (now.difference(startDate).inDays / 365).floor();
    } else if (widget.subscription.billingCycle == 'Weekly') {
      return (now.difference(startDate).inDays / 7).floor();
    } else {
      return now.difference(startDate).inDays;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
          color: textColor,
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: PopupMenuButton<String>(
              icon: Icon(
                Icons.more_vert_rounded,
                color: highContrastDarkBlue,
                size: 24,
              ),
              splashRadius: 24,
              offset: const Offset(0, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 8,
              color: backgroundColor,
              surfaceTintColor: lightColor,
              shadowColor: Colors.black.withAlpha(40),
              itemBuilder: (BuildContext context) => [
                _buildMenuItem(
                  value: 'edit',
                  icon: Icons.edit_rounded,
                  label: 'Edit',
                  iconColor: highContrastBlue,
                ),
                _buildMenuItem(
                  value: 'pause',
                  icon: Icons.pause_rounded,
                  label: 'Pause',
                  iconColor: const Color(0xFF10B981), // Emerald green
                ),
                _buildMenuItem(
                  value: 'duplicate',
                  icon: Icons.copy_rounded,
                  label: 'Duplicate',
                  iconColor: const Color(0xFF3B82F6), // Blue
                ),
                _buildMenuItem(
                  value: 'delete',
                  icon: Icons.delete_rounded,
                  label: 'Delete',
                  iconColor: const Color(0xFFEF4444), // Red
                ),
              ],
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    _handleEdit();
                    break;
                  case 'pause':
                    _handlePause();
                    break;
                  case 'duplicate':
                    _handleDuplicate();
                    break;
                  case 'delete':
                    _handleDelete();
                    break;
                }
              },
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Subscription Header Card
              _buildSubscriptionHeader(),
              const SizedBox(height: 40),

              // Subscription Details Section
              _buildSectionTitle('Subscription Details'),
              const SizedBox(height: 20),
              _buildSubscriptionDetails(),
              const SizedBox(height: 24),

              // Billing Information Section
              _buildSectionTitle('Billing Information'),
              const SizedBox(height: 20),
              _buildBillingInformation(),
              const SizedBox(height: 24),

              // Category Section
              _buildSectionTitle('Category'),
              const SizedBox(height: 20),
              _buildCategoryCard(),
              const SizedBox(height: 24),

              // Notes Section
              _buildSectionTitle('Notes'),
              const SizedBox(height: 20),
              _buildNotesCard(),
              const SizedBox(height: 24),

              // Summary Section
              const SizedBox(height: 32),
              _buildSummarySection(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubscriptionHeader() {
    return Row(
      children: [
        // Icon
        _buildAdaptiveIcon(),
        const SizedBox(width: 20),

        // Title and Description
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.subscription.title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w400,
                  color: textColor,
                ),
              ),
              if (widget.subscription.shortDescription != null) ...[
                const SizedBox(height: 8),
                Text(
                  widget.subscription.shortDescription!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: secondaryTextColor,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ],
          ),
        ),

        // Status Button
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.green,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Active',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.w400,
        color: textColor,
      ),
    );
  }

  Widget _buildSubscriptionDetails() {
    final details = [
      {
        'label': 'Amount',
        'value':
            '${widget.subscription.currency} ${widget.subscription.amount.toStringAsFixed(2)}',
      },
      {'label': 'Billing cycle', 'value': widget.subscription.billingCycle},
      {'label': 'Due in', 'value': _getBillingInfo().replaceAll('Due ', '')},
      {'label': 'Next payment', 'value': _getNextPaymentDate()},
      {'label': 'Payment method', 'value': widget.subscription.paymentMethod},
    ];

    return Column(
      children: [
        for (int i = 0; i < details.length; i++) ...[
          _buildStackedCard(
            index: i,
            isLast: i == details.length - 1,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  details[i]['label']!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: secondaryTextColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  details[i]['value']!,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildBillingInformation() {
    final billingInfo = [
      {
        'label': 'Total',
        'value':
            '${widget.subscription.currency} ${_getTotalAmount().toStringAsFixed(2)}',
      },
      {'label': 'Due in', 'value': _getBillingInfo().replaceAll('Due ', '')},
      {
        'label': 'Start date',
        'value': _formatDate(widget.subscription.createdAt),
      },
      {
        'label': 'End date',
        'value': widget.subscription.endDate != null
            ? _formatDate(widget.subscription.endDate!)
            : 'n/a',
      },
    ];

    return Column(
      children: [
        for (int i = 0; i < billingInfo.length; i++) ...[
          _buildStackedCard(
            index: i,
            isLast: i == billingInfo.length - 1,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  billingInfo[i]['label']!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: secondaryTextColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  billingInfo[i]['value']!,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStackedCard({
    required Widget child,
    required int index,
    required bool isLast,
    Color? backgroundColor,
    VoidCallback? onTap,
  }) {
    // Use the new card color
    final cardBackgroundColor = backgroundColor ?? cardColor;

    // Position-based border radius
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

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 2),
      child: Card(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: cardBackgroundColor,
        shape: RoundedRectangleBorder(borderRadius: borderRadius),
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius,
          child: Padding(padding: const EdgeInsets.all(28), child: child),
        ),
      ),
    );
  }

  Widget _buildCategoryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 5,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Category',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: secondaryTextColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            widget.subscription.category,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesCard() {
    return Container(
      width: double.infinity,
      height: 144, // 3x bigger (48 * 3)
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 5,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child:
          widget.subscription.notes != null &&
              widget.subscription.notes!.isNotEmpty
          ? Text(
              widget.subscription.notes!,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: textColor,
                fontWeight: FontWeight.w400,
              ),
            )
          : Text(
              'No notes added',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: secondaryTextColor,
                fontWeight: FontWeight.w400,
                fontStyle: FontStyle.italic,
              ),
            ),
    );
  }

  Widget _buildSummarySection() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Total payments made',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: secondaryTextColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '${_getTotalPayments()}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: textColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Subscribed for',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: secondaryTextColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              _getSubscriptionDuration(),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: textColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Detect if image is bright or dark for automatic color inversion
  Future<bool> _isImageBright(String imagePath) async {
    try {
      final File file = File(imagePath);
      if (!await file.exists()) return false;

      final Uint8List bytes = await file.readAsBytes();
      final ui.Codec codec = await ui.instantiateImageCodec(bytes);
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      final ui.Image image = frameInfo.image;

      // Sample pixels to determine brightness
      final ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      if (byteData == null) return false;

      final Uint8List pixels = byteData.buffer.asUint8List();
      int totalBrightness = 0;
      int sampleCount = 0;

      // Sample every 10th pixel to avoid performance issues
      for (int i = 0; i < pixels.length; i += 40) {
        if (i + 3 < pixels.length) {
          final int r = pixels[i];
          final int g = pixels[i + 1];
          final int b = pixels[i + 2];
          final int brightness = ((r + g + b) / 3).round();
          totalBrightness += brightness;
          sampleCount++;
        }
      }

      if (sampleCount == 0) return false;
      final double averageBrightness = totalBrightness / sampleCount;

      // Consider bright if average brightness > 128
      return averageBrightness > 128;
    } catch (e) {
      return false;
    }
  }

  // Adaptive icon widget that automatically inverts colors based on brightness
  Widget _buildAdaptiveIcon() {
    if (widget.subscription.iconFilePath != null) {
      return FutureBuilder<bool>(
        future: _isImageBright(widget.subscription.iconFilePath!),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final bool isBright = snapshot.data!;
            final bool isDarkMode =
                Theme.of(context).brightness == Brightness.dark;

            // Invert colors if needed
            if ((isBright && !isDarkMode) || (!isBright && isDarkMode)) {
              // Invert colors for better contrast
              return ColorFiltered(
                colorFilter: const ColorFilter.matrix([
                  -1,
                  0,
                  0,
                  0,
                  255,
                  0,
                  -1,
                  0,
                  0,
                  255,
                  0,
                  0,
                  -1,
                  0,
                  255,
                  0,
                  0,
                  0,
                  1,
                  0,
                ]),
                child: Image.file(
                  File(widget.subscription.iconFilePath!),
                  width: 48,
                  height: 48,
                  fit: BoxFit.contain,
                ),
              );
            } else {
              // No color filter needed
              return Image.file(
                File(widget.subscription.iconFilePath!),
                width: 48,
                height: 48,
                fit: BoxFit.contain,
              );
            }
          }

          // Fallback while loading
          return Image.file(
            File(widget.subscription.iconFilePath!),
            width: 48,
            height: 48,
            fit: BoxFit.contain,
          );
        },
      );
    } else {
      // For material icons, use the subscription color
      return Icon(
        IconData(
          widget.subscription.iconCodePoint ?? 0xe047,
          fontFamily: 'MaterialIcons',
        ),
        size: 48,
        color: _selectedColor,
      );
    }
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

  PopupMenuItem<String> _buildMenuItem({
    required String value,
    required IconData icon,
    required String label,
    required Color iconColor,
  }) {
    return PopupMenuItem<String>(
      value: value,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: SizedBox(
        height: 40,
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 18, color: iconColor),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: highContrastDarkBlue,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Menu action handlers
  void _handleEdit() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Edit ${widget.subscription.title}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _handlePause() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Pause ${widget.subscription.title}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _handleDuplicate() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Duplicate ${widget.subscription.title}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _handleDelete() {
    // Show confirmation dialog before deleting
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Subscription'),
          content: Text(
            'Are you sure you want to delete "${widget.subscription.title}"? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${widget.subscription.title} deleted'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              child: Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}
