import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:payables/models/subscription.dart';
import 'package:payables/data/subscription_database.dart';
import 'addsubs_screen.dart';

class SubscriptionDetailsScreen extends StatefulWidget {
  final Subscription subscription;
  final List<Map<String, dynamic>>? categories;

  const SubscriptionDetailsScreen({
    super.key,
    required this.subscription,
    this.categories,
  });

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
        : const Color(0xFF191c20);
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
    // Calculate total based on billing cycle and billing date (start date)
    DateTime now = DateTime.now();
    DateTime startDate = widget.subscription.billingDate;
    double amount = widget.subscription.amount;

    if (widget.subscription.billingCycle == 'Monthly') {
      // Calculate months from start date to current month
      int months =
          ((now.year - startDate.year) * 12 + now.month - startDate.month);
      if (now.day < startDate.day) {
        months--; // Don't count current month if billing day hasn't passed
      }
      return amount * months;
    } else if (widget.subscription.billingCycle == 'Yearly') {
      // Calculate years from start date to current year
      int years = now.year - startDate.year;
      if (now.month < startDate.month ||
          (now.month == startDate.month && now.day < startDate.day)) {
        years--; // Don't count current year if billing date hasn't passed
      }
      return amount * years;
    } else if (widget.subscription.billingCycle == 'Weekly') {
      // Calculate weeks from start date to current week
      int weeks = now.difference(startDate).inDays ~/ 7;
      return amount * weeks;
    } else {
      // Daily billing
      int days = now.difference(startDate).inDays;
      return amount * days;
    }
  }

  String _getSubscriptionDuration() {
    DateTime now = DateTime.now();
    DateTime startDate = widget.subscription.billingDate;
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
    DateTime startDate = widget.subscription.billingDate;

    if (widget.subscription.billingCycle == 'Monthly') {
      // Calculate months from start date to current month
      int months =
          ((now.year - startDate.year) * 12 + now.month - startDate.month);
      if (now.day < startDate.day) {
        months--; // Don't count current month if billing day hasn't passed
      }
      return months;
    } else if (widget.subscription.billingCycle == 'Yearly') {
      // Calculate years from start date to current year
      int years = now.year - startDate.year;
      if (now.month < startDate.month ||
          (now.month == startDate.month && now.day < startDate.day)) {
        years--; // Don't count current year if billing date hasn't passed
      }
      return years;
    } else if (widget.subscription.billingCycle == 'Weekly') {
      return now.difference(startDate).inDays ~/ 7;
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
              // Material 3 Menu Container Specifications
              constraints: const BoxConstraints(
                minWidth: 112, // 112dp min width
                maxWidth: 280, // 280dp max width
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  12,
                ), // 12dp corner radius for modern look
              ),
              elevation: 3,
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF1E1E1E)
                  : const Color(0xFFFFFFFF),
              surfaceTintColor: Colors.transparent,
              shadowColor: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0x40000000)
                  : const Color(0x1F000000),
              // Material 3 expressive transitions
              popUpAnimationStyle: AnimationStyle(
                duration: const Duration(milliseconds: 300),
                reverseDuration: const Duration(milliseconds: 250),
                curve: Curves.easeInOutCubicEmphasized,
                reverseCurve: Curves.easeInCubic,
              ),
              itemBuilder: (BuildContext context) => [
                _buildMenuItem(
                  value: 'edit',
                  icon: Icons.edit_rounded,
                  label: 'Edit',
                  iconColor: const Color(0xFF43474e),
                ),
                _buildMenuItem(
                  value: 'duplicate',
                  icon: Icons.copy_rounded,
                  label: 'Duplicate',
                  iconColor: const Color(0xFF43474e),
                ),
                if (widget.subscription.status == 'active')
                  _buildMenuItem(
                    value: 'pause',
                    icon: Icons.pause_circle_rounded,
                    label: 'Pause',
                    iconColor: const Color(0xFF43474e),
                  ),
                if (widget.subscription.status == 'paused')
                  _buildMenuItem(
                    value: 'resume',
                    icon: Icons.play_circle_rounded,
                    label: 'Resume',
                    iconColor: const Color(0xFF43474e),
                  ),
                if (widget.subscription.status != 'finished')
                  _buildMenuItem(
                    value: 'finish',
                    icon: Icons.check_circle_rounded,
                    label: 'Finish',
                    iconColor: const Color(0xFF43474e),
                  ),
                _buildMenuItem(
                  value: 'delete',
                  icon: Icons.delete_rounded,
                  label: 'Delete',
                  iconColor: const Color(0xFF43474e),
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
                  case 'resume':
                    _handleResume();
                    break;
                  case 'duplicate':
                    _handleDuplicate();
                    break;
                  case 'finish':
                    _handleFinish();
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
              const SizedBox(height: 12),
              _buildSubscriptionDetails(),
              const SizedBox(height: 32),

              // Billing Information Section
              _buildSectionTitle('Billing Information'),
              const SizedBox(height: 12),
              _buildBillingInformation(),
              const SizedBox(height: 32),

              // Category Section
              _buildSectionTitle('Category'),
              const SizedBox(height: 12),
              _buildCategoryCard(),
              const SizedBox(height: 32),

              // Notes Section
              _buildSectionTitle('Notes'),
              const SizedBox(height: 12),
              _buildNotesCard(),
              const SizedBox(height: 32),

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
        _buildAdaptiveIcon()
            .animate()
            .fadeIn(
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
            )
            .scale(
              duration: const Duration(milliseconds: 500),
              curve: Curves.elasticOut,
              begin: const Offset(0.8, 0.8),
              end: const Offset(1.0, 1.0),
            ),
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
                  )
                  .animate()
                  .fadeIn(
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeOutCubic,
                  )
                  .slideX(
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOutCubic,
                    begin: -0.3,
                    end: 0.0,
                  ),
              if (widget.subscription.shortDescription != null) ...[
                const SizedBox(height: 8),
                Text(
                      widget.subscription.shortDescription!,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: secondaryTextColor,
                        fontWeight: FontWeight.w400,
                      ),
                    )
                    .animate()
                    .fadeIn(
                      duration: const Duration(milliseconds: 1000),
                      curve: Curves.easeOutCubic,
                    )
                    .slideX(
                      duration: const Duration(milliseconds: 800),
                      curve: Curves.easeOutCubic,
                      begin: -0.3,
                      end: 0.0,
                    ),
              ],
            ],
          ),
        ),

        // Status Button
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: widget.subscription.status == 'paused'
                ? Colors.orange
                : widget.subscription.status == 'finished'
                ? Colors.grey
                : Colors.green,
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
                widget.subscription.status == 'paused'
                    ? 'Paused'
                    : widget.subscription.status == 'finished'
                    ? 'Finished'
                    : 'Active',
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w400,
          color: textColor,
        ),
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
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: secondaryTextColor,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                Text(
                  details[i]['value']!,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w500,
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
      {
        'label': 'Start date',
        'value': _formatDate(widget.subscription.billingDate),
      },
      {
        'label': 'End date',
        'value': widget.subscription.endDate != null
            ? _formatDate(widget.subscription.endDate!)
            : 'n/a',
      },
      {
        'label': 'Alert',
        'value': _formatAlertDays(widget.subscription.alertDays),
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
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: secondaryTextColor,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                Text(
                  billingInfo[i]['value']!,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w500,
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
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Category',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: secondaryTextColor,
              fontWeight: FontWeight.w400,
            ),
          ),
          Text(
            widget.subscription.category,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
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
                fontWeight: FontWeight.w400,
              ),
            ),
            Text(
              '${_getTotalPayments()}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: textColor,
                fontWeight: FontWeight.w500,
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
                fontWeight: FontWeight.w400,
              ),
            ),
            Text(
              _getSubscriptionDuration(),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: textColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Icon widget with shadow for better visibility
  Widget _buildAdaptiveIcon() {
    if (widget.subscription.iconFilePath != null) {
      return Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 4,
              offset: const Offset(0, 1),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Image.file(
          File(widget.subscription.iconFilePath!),
          width: 48,
          height: 48,
          fit: BoxFit.contain,
        ),
      );
    } else {
      // For material icons, use the subscription color with shadow
      return Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 4,
              offset: const Offset(0, 1),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Icon(
          IconData(
            widget.subscription.iconCodePoint ?? 0xe047,
            fontFamily: 'MaterialIcons',
          ),
          size: 48,
          color: _selectedColor,
        ),
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

  String _formatAlertDays(int alertDays) {
    if (alertDays == 0) {
      return 'On due date';
    } else if (alertDays == 1) {
      return '$alertDays day before';
    } else {
      return '$alertDays days before';
    }
  }

  PopupMenuItem<String> _buildMenuItem({
    required String value,
    required IconData icon,
    required String label,
    required Color iconColor,
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
            color: isDark ? Colors.white.withAlpha(230) : iconColor,
            size: 24, // 24dp icon size as per Material 3
          ),
          const SizedBox(width: 16), // 16dp padding between elements
          Expanded(
            child: Text(
              label,
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

  // Menu action handlers
  void _handleEdit() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddSubsScreen(
          subscriptionToEdit: widget.subscription,
          categories: widget.categories,
        ),
      ),
    );

    if (!mounted) return;

    if (result == true || result == 'categories_updated') {
      // Refresh the subscription details if changes were made
      Navigator.of(context).pop(result);
    }
  }

  void _handlePause() async {
    try {
      // Check if subscription has a valid ID
      if (widget.subscription.id == null) {
        throw Exception('Subscription ID is null');
      }

      // Update subscription status to paused
      await SubscriptionDatabase.updateSubscriptionStatus(
        widget.subscription.id!,
        'paused',
      );

      // Ensure database is synchronized
      await SubscriptionDatabase.ensureDatabaseSync();

      if (!mounted) return;

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${widget.subscription.title} paused successfully'),
          duration: const Duration(seconds: 2),
        ),
      );

      // Return result to indicate status change for parent screens to refresh
      Navigator.of(context).pop('status_updated');
    } catch (e) {
      if (!mounted) return;

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to pause ${widget.subscription.title}. Please try again.',
          ),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _handleResume() async {
    try {
      // Check if subscription has a valid ID
      if (widget.subscription.id == null) {
        throw Exception('Subscription ID is null');
      }

      // Update subscription status to active
      await SubscriptionDatabase.updateSubscriptionStatus(
        widget.subscription.id!,
        'active',
      );

      // Ensure database is synchronized
      await SubscriptionDatabase.ensureDatabaseSync();

      if (!mounted) return;

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${widget.subscription.title} resumed successfully'),
          duration: const Duration(seconds: 2),
        ),
      );

      // Return result to indicate status change for parent screens to refresh
      Navigator.of(context).pop('status_updated');
    } catch (e) {
      if (!mounted) return;

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to resume ${widget.subscription.title}. Please try again.',
          ),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _handleDuplicate() async {
    try {
      // Create a new subscription object without the ID to ensure it's not included in the database insert
      final newSubscription = Subscription(
        title: widget.subscription.title,
        currency: widget.subscription.currency,
        amount: widget.subscription.amount,
        billingDate:
            widget.subscription.billingDate, // Keep the original billing date
        endDate: widget.subscription.endDate,
        billingCycle: widget.subscription.billingCycle,
        type: widget.subscription.type,
        paymentMethod: widget.subscription.paymentMethod,
        websiteLink: widget.subscription.websiteLink,
        shortDescription: widget.subscription.shortDescription,
        category: widget.subscription.category,
        iconCodePoint: widget.subscription.iconCodePoint,
        iconFilePath: widget.subscription.iconFilePath,
        colorValue: widget.subscription.colorValue,
        notes: widget.subscription.notes,
        status: 'active', // Ensure it's active
        alertDays: widget.subscription.alertDays,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Save the duplicate to the database
      await SubscriptionDatabase.insertSubscription(newSubscription);

      // Ensure database is synchronized
      await SubscriptionDatabase.ensureDatabaseSync();

      if (!mounted) return;

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Text(
                '${widget.subscription.title} duplicated successfully',
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 3),
        ),
      );

      // Return result to indicate a new subscription was created for parent screens to refresh
      Navigator.of(context).pop('duplicated');
    } catch (e) {
      if (!mounted) return;

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Text(
                'Failed to duplicate ${widget.subscription.title}. Please try again.',
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _handleFinish() async {
    try {
      // Check if subscription has a valid ID
      if (widget.subscription.id == null) {
        throw Exception('Subscription ID is null');
      }

      // Update subscription status to finished
      await SubscriptionDatabase.updateSubscriptionStatus(
        widget.subscription.id!,
        'finished',
      );

      // Ensure database is synchronized
      await SubscriptionDatabase.ensureDatabaseSync();

      if (!mounted) return;

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${widget.subscription.title} finished successfully'),
          duration: const Duration(seconds: 2),
        ),
      );

      // Return result to indicate status change for parent screens to refresh
      Navigator.of(context).pop('status_updated');
    } catch (e) {
      if (!mounted) return;

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to finish ${widget.subscription.title}. Please try again.',
          ),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _handleDelete() {
    // Show confirmation dialog before deleting
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Delete Subscription'),
          content: Text(
            'Are you sure you want to delete "${widget.subscription.title}"? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(
                  dialogContext,
                ).pop(); // Close the confirmation dialog

                try {
                  // Check if subscription has a valid ID
                  if (widget.subscription.id == null) {
                    throw Exception('Subscription ID is null');
                  }

                  // Delete the subscription from the database
                  await SubscriptionDatabase.deleteSubscription(
                    widget.subscription.id!,
                  );

                  // Ensure database is synchronized
                  await SubscriptionDatabase.ensureDatabaseSync();

                  if (!mounted) return;

                  // Show success message
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '${widget.subscription.title} deleted successfully',
                      ),
                      duration: const Duration(seconds: 2),
                    ),
                  );

                  // Return result to indicate deletion for parent screens to refresh
                  Navigator.of(context).pop('deleted');
                } catch (e) {
                  if (!mounted) return;

                  // Show error message
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Failed to delete ${widget.subscription.title}. Please try again.',
                      ),
                      duration: const Duration(seconds: 2),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}
