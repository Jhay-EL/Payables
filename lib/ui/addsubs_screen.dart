import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';

import 'icons_screen.dart';
import '../data/subscription_database.dart';
import '../data/payment_method_database.dart';
import '../models/subscription.dart';
import '../models/payment_method.dart';
import '../data/currency_database.dart';
import 'package:provider/provider.dart';
import '../data/currency_provider.dart';
import 'color_picker_screen.dart';

class AddSubsScreen extends StatefulWidget {
  final List<Map<String, dynamic>>? categories;
  final Subscription? subscriptionToEdit;
  const AddSubsScreen({super.key, this.categories, this.subscriptionToEdit});

  @override
  State<AddSubsScreen> createState() => _AddSubsScreenState();
}

class _AddSubsScreenState extends State<AddSubsScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _websiteController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  String _selectedBillingCycle = 'Monthly';
  String _selectedPaymentMethod = 'Not set';
  final List<Map<String, dynamic>> _paymentMethods = [
    {
      'name': 'Not set',
      'icon': Icons.do_not_disturb_on_rounded,
      'isCustom': false,
    },
    {
      'name': 'Credit Card',
      'icon': Icons.credit_card_rounded,
      'isCustom': false,
    },
    {'name': 'PayPal', 'icon': Icons.paypal_rounded, 'isCustom': false},
    {'name': 'Google Pay', 'icon': Icons.wallet_rounded, 'isCustom': false},
    {'name': 'Apple Pay', 'icon': Icons.apple_rounded, 'isCustom': false},
  ];

  List<Map<String, dynamic>> _customPaymentMethods = [];
  String _selectedCategory = 'Not set';
  String _selectedType = 'Recurring';
  bool _isLoadingPaymentMethods = false;

  List<Map<String, dynamic>> get allPaymentMethods => [
    ..._paymentMethods,
    ..._customPaymentMethods,
  ];
  DateTime? _billingDate = DateTime.now().add(const Duration(days: 1));
  DateTime? _endDate;
  Object _selectedIcon = Icons.category_rounded;
  Color _selectedColor = const Color(0xFF6B7280);

  List<Map<String, dynamic>> _categories = [];

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

  Color get _previewTextColor {
    return _selectedColor.computeLuminance() > 0.5
        ? const Color(0xFF111827) // A very dark gray, almost black
        : Colors.white;
  }

  @override
  void initState() {
    super.initState();
    _initializeCategories();
    _titleController.addListener(() => setState(() {}));
    _amountController.addListener(() => setState(() {}));
    _descriptionController.addListener(() => setState(() {}));
    _websiteController.addListener(() => setState(() {}));
    _loadCustomPaymentMethods();

    // If editing an existing subscription, populate the fields
    if (widget.subscriptionToEdit != null) {
      _populateFieldsForEdit();
    }
  }

  void _initializeCategories() {
    List<Map<String, dynamic>> dashboardCategories;
    if (widget.categories != null && widget.categories!.isNotEmpty) {
      dashboardCategories = widget.categories!.map((c) {
        return {
          'name': c['name'],
          'icon': c['icon'],
          'color': c['originalColor'] ?? c['color'],
        };
      }).toList();
    } else {
      dashboardCategories = [];
    }

    // Create a map to track unique category names and keep the first occurrence
    Map<String, Map<String, dynamic>> uniqueCategories = {};

    // Add "Not set" as the first category
    uniqueCategories['Not set'] = {
      'name': 'Not set',
      'icon': Icons.category_rounded,
      'color': const Color(0xFF6B7280),
    };

    // Add dashboard categories, keeping only the first occurrence of each name
    for (final category in dashboardCategories) {
      final name = category['name'] as String;
      if (!uniqueCategories.containsKey(name)) {
        uniqueCategories[name] = category;
      }
    }

    // If editing a subscription, ensure its category is included
    if (widget.subscriptionToEdit != null) {
      final subscriptionCategory = widget.subscriptionToEdit!.category;
      if (!uniqueCategories.containsKey(subscriptionCategory)) {
        uniqueCategories[subscriptionCategory] = {
          'name': subscriptionCategory,
          'icon': Icons.category_rounded,
          'color': const Color(0xFF6B7280),
        };
      }
    }

    _categories = uniqueCategories.values.toList();
  }

  void _populateFieldsForEdit() {
    final subscription = widget.subscriptionToEdit!;

    _titleController.text = subscription.title;
    _amountController.text = subscription.amount.toString();
    _descriptionController.text = subscription.shortDescription ?? '';
    _websiteController.text = subscription.websiteLink ?? '';
    _notesController.text = subscription.notes ?? '';

    _selectedBillingCycle = subscription.billingCycle;
    _selectedPaymentMethod = subscription.paymentMethod;
    _selectedCategory = subscription.category;
    _selectedType = subscription.type;
    _billingDate = subscription.billingDate;
    _endDate = subscription.endDate;
    _selectedColor = Color(subscription.colorValue);

    // Handle icon
    if (subscription.iconFilePath != null) {
      _selectedIcon = File(subscription.iconFilePath!);
    } else if (subscription.iconCodePoint != null) {
      _selectedIcon = IconData(
        subscription.iconCodePoint!,
        fontFamily: 'MaterialIcons',
      );
    }
  }

  // Load custom payment methods from database
  Future<void> _loadCustomPaymentMethods() async {
    setState(() => _isLoadingPaymentMethods = true);
    try {
      final paymentMethods = await PaymentMethodDatabase.getAllPaymentMethods();
      setState(() {
        _customPaymentMethods = paymentMethods
            .map((pm) => pm.toUIMap())
            .toList();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading payment methods'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } finally {
      setState(() => _isLoadingPaymentMethods = false);
    }
  }

  @override
  void dispose() {
    _titleController.removeListener(() => setState(() {}));
    _amountController.removeListener(() => setState(() {}));
    _descriptionController.removeListener(() => setState(() {}));
    _websiteController.removeListener(() => setState(() {}));
    _titleController.dispose();
    _amountController.dispose();
    _websiteController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveSubscription() async {
    if (_titleController.text.trim().isEmpty) {
      _showErrorSnackBar('Please enter a payable title');
      return;
    }

    if (_amountController.text.trim().isEmpty) {
      _showErrorSnackBar('Please enter an amount');
      return;
    }

    double? amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      _showErrorSnackBar('Please enter a valid amount');
      return;
    }

    try {
      _showLoadingDialog();

      if (widget.subscriptionToEdit != null) {
        // Update existing subscription
        final updatedSubscription = widget.subscriptionToEdit!.copyWith(
          title: _titleController.text.trim(),
          currency: Provider.of<CurrencyProvider>(
            context,
            listen: false,
          ).selectedCurrency,
          amount: amount,
          billingDate:
              _billingDate ?? DateTime.now().add(const Duration(days: 1)),
          endDate: _endDate,
          billingCycle: _selectedBillingCycle,
          type: _selectedType,
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
          iconFilePath: _selectedIcon is File
              ? (_selectedIcon as File).path
              : null,
          colorValue: _selectedColor.toARGB32(),
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
          updatedAt: DateTime.now(),
        );

        await SubscriptionDatabase.updateSubscription(updatedSubscription);
      } else {
        // Create new subscription
        final subscription = Subscription(
          title: _titleController.text.trim(),
          currency: Provider.of<CurrencyProvider>(
            context,
            listen: false,
          ).selectedCurrency,
          amount: amount,
          billingDate:
              _billingDate ?? DateTime.now().add(const Duration(days: 1)),
          endDate: _endDate,
          billingCycle: _selectedBillingCycle,
          type: _selectedType,
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
          iconFilePath: _selectedIcon is File
              ? (_selectedIcon as File).path
              : null,
          colorValue: _selectedColor.toARGB32(),
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final id = await SubscriptionDatabase.insertSubscription(subscription);

        // Verify the subscription was saved by querying it
        final savedSubscription =
            await SubscriptionDatabase.getSubscriptionById(id);
        if (savedSubscription != null) {
        } else {}
      }

      // Check if a new category was added
      bool categoryWasAdded = false;
      if (widget.subscriptionToEdit == null) {
        // For new subscriptions, check if the selected category is not in the original categories list
        final originalCategoryNames =
            widget.categories?.map((c) => c['name'] as String).toSet() ??
            <String>{};
        if (!originalCategoryNames.contains(_selectedCategory) &&
            _selectedCategory != 'Not set') {
          categoryWasAdded = true;
        }
      }

      if (!mounted) return;

      // Ensure database is fully committed
      await SubscriptionDatabase.ensureDatabaseSync();

      if (!mounted) return;
      Navigator.of(context).pop();
      _showSuccessSnackBar(
        widget.subscriptionToEdit != null
            ? 'Payable updated successfully!'
            : 'Payable saved successfully!',
      );

      // Wait a bit longer to ensure database is ready
      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;
      // Return true if subscription was saved, and also indicate if categories were modified
      Navigator.of(context).pop(categoryWasAdded ? 'categories_updated' : true);
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      _showErrorSnackBar(
        widget.subscriptionToEdit != null
            ? 'Failed to update payable. Please try again.'
            : 'Failed to save payable. Please try again.',
      );
    }
  }

  Future<void> _launchURL() async {
    final url = _websiteController.text.trim();
    if (url.isEmpty) return;

    final Uri uri = Uri.parse(url.startsWith('http') ? url : 'https://$url');

    if (!mounted) return;
    if (!await launchUrl(uri)) {
      if (!mounted) return;
      _showErrorSnackBar('Could not launch $url');
    }
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  color: highContrastBlue,
                  strokeWidth: 3,
                ),
                const SizedBox(height: 16),
                Text(
                  'Saving payable...',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: highContrastDarkBlue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  String _getBillingInfo() {
    if (_billingDate == null) {
      return 'No billing date set';
    }

    DateTime now = DateTime.now();
    DateTime billingDate = _billingDate!;

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
      return 'Due in 1 day';
    } else {
      return 'Due in $daysUntilBilling days';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: backgroundColor,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        title: Text(
          widget.subscriptionToEdit != null ? 'Edit Payable' : 'Add Payable',
          style: TextStyle(
            color: highContrastDarkBlue,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: TextButton(
              onPressed: _saveSubscription,
              style: TextButton.styleFrom(
                foregroundColor: highContrastDarkBlue,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                widget.subscriptionToEdit != null ? 'Update' : 'Save',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
            ),
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            _buildPreviewCard(),
            const SizedBox(height: 24),
            _buildBasicInformationCard(),
            const SizedBox(height: 32),
            _buildBillingInformationCard(),
            const SizedBox(height: 32),
            _buildCategoryAndPaymentCard(),
            const SizedBox(height: 32),
            _buildCustomizationCard(),
            const SizedBox(height: 32),
            _buildAdditionalDetailsCard(),
            const SizedBox(height: 64),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewCard() {
    final title = _titleController.text.isEmpty
        ? 'New Payable'
        : _titleController.text;
    final description = _descriptionController.text.isNotEmpty
        ? _descriptionController.text
        : _selectedCategory;
    final dueDate = _getBillingInfo();
    final selectedCurrency = Provider.of<CurrencyProvider>(
      context,
    ).selectedCurrency;
    final price = _amountController.text.isEmpty
        ? '$selectedCurrency 0.00'
        : '$selectedCurrency ${_amountController.text}';

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: _selectedColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            // Icon with enhanced styling
            _selectedIcon is File
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.file(
                      _selectedIcon as File,
                      width: 48,
                      height: 48,
                      fit: BoxFit.contain,
                    ),
                  )
                : Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _previewTextColor.withAlpha(153),
                          _previewTextColor.withAlpha(128),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(26),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      _selectedIcon as IconData,
                      size: 24,
                      color: _previewTextColor,
                    ),
                  ),
            const SizedBox(width: 16),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: _previewTextColor,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: _previewTextColor.withAlpha(179),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        size: 16,
                        color: _previewTextColor.withAlpha(179),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        dueDate,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: _previewTextColor.withAlpha(179),
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _previewTextColor.withAlpha(38),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _previewTextColor.withAlpha(77),
                  width: 1,
                ),
              ),
              child: Text(
                price,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: _previewTextColor,
                  letterSpacing: -0.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInformationCard() {
    final currencyProvider = Provider.of<CurrencyProvider>(context);
    final selectedCurrency = currencyProvider.selectedCurrency;
    final selectedCurrencyObject = CurrencyDatabase.getCurrencyByCode(
      selectedCurrency,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'Basic Information',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: highContrastDarkBlue,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        _buildM3TextField(
          controller: _titleController,
          label: 'Title',
          hint: 'e.g. Spotify Premium',
          icon: Icons.title_rounded,
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: _buildM3TextField(
                controller: _amountController,
                label: 'Amount',
                hint: '19.99',
                icon: selectedCurrencyObject?.icon ?? Icons.euro_rounded,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 1,
              child: _buildM3DropdownField(
                label: 'Currency',
                value: selectedCurrency,
                items: CurrencyDatabase.getCurrencies()
                    .map((c) => c.code)
                    .toList(),
                onChanged: (value) => currencyProvider.setCurrency(value!),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildM3TextField(
          controller: _descriptionController,
          label: 'Description',
          hint: 'e.g. Family plan',
          icon: Icons.description_rounded,
        ),
      ],
    );
  }

  Widget _buildBillingInformationCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Segmented button for subscription type
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<String>(
            segments: const [
              ButtonSegment<String>(
                value: 'Recurring',
                label: Text('Recurring'),
                icon: Icon(Icons.sync_rounded, size: 18),
              ),
              ButtonSegment<String>(
                value: 'One time',
                label: Text('One time'),
                icon: Icon(Icons.event_rounded, size: 18),
              ),
            ],
            selected: {_selectedType},
            onSelectionChanged: (Set<String> selection) {
              setState(() {
                _selectedType = selection.first;
              });
            },
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
                if (states.contains(WidgetState.selected)) {
                  return highContrastBlue;
                }
                return lightColor.withAlpha(100);
              }),
              foregroundColor: WidgetStateProperty.resolveWith<Color>((states) {
                if (states.contains(WidgetState.selected)) {
                  return Colors.white;
                }
                return highContrastDarkBlue;
              }),
              side: WidgetStateProperty.all(
                BorderSide(color: darkColor.withAlpha(77), width: 1),
              ),
              shape: WidgetStateProperty.all(
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'Billing Information',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: highContrastDarkBlue,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        _buildM3DateField(
          label: 'Billing Date',
          date: _billingDate,
          onTap: () async {
            final pickedDate = await showDatePicker(
              context: context,
              initialDate:
                  _billingDate ?? DateTime.now().add(const Duration(days: 1)),
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: Theme.of(
                      context,
                    ).colorScheme.copyWith(primary: highContrastBlue),
                  ),
                  child: child!,
                );
              },
            );
            if (pickedDate != null) {
              setState(() => _billingDate = pickedDate);
            }
          },
          clearable: true,
          onClear: () => setState(() => _billingDate = null),
        ),
        if (_selectedType == 'Recurring') ...[
          const SizedBox(height: 16),
          _buildM3DateField(
            label: 'End Date (Optional)',
            date: _endDate,
            onTap: () async {
              final pickedDate = await showDatePicker(
                context: context,
                initialDate:
                    _endDate ?? DateTime.now().add(const Duration(days: 365)),
                firstDate: DateTime.now(),
                lastDate: DateTime(2100),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: Theme.of(
                        context,
                      ).colorScheme.copyWith(primary: highContrastBlue),
                    ),
                    child: child!,
                  );
                },
              );
              if (pickedDate != null) {
                setState(() => _endDate = pickedDate);
              }
            },
            clearable: true,
            onClear: () => setState(() => _endDate = null),
          ),
          const SizedBox(height: 16),
          _buildBillingCyclePicker(),
        ],
      ],
    );
  }

  Widget _buildCategoryAndPaymentCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'Category & Payment',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: highContrastDarkBlue,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        _buildCategoryPicker(),
        const SizedBox(height: 16),
        _buildPaymentMethodPicker(),
      ],
    );
  }

  Widget _buildAdditionalDetailsCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'Additional Details',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: highContrastDarkBlue,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        _buildM3TextField(
          controller: _websiteController,
          label: 'Website (Optional)',
          hint: 'e.g. spotify.com',
          icon: Icons.link_rounded,
          suffixIcon: _websiteController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.open_in_new_rounded,
                    color: highContrastBlue,
                  ),
                  onPressed: _launchURL,
                  style: IconButton.styleFrom(
                    backgroundColor: highContrastBlue.withAlpha(31),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                )
              : null,
        ),
        const SizedBox(height: 16),
        _buildM3TextField(
          controller: _notesController,
          label: 'Notes (Optional)',
          hint: 'Add any extra details here...',
          icon: Icons.note_alt_rounded,
          maxLines: 8,
          minLines: 5,
        ),
      ],
    );
  }

  Widget _buildCustomizationCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'Customization',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: highContrastDarkBlue,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        // Icon & Color Card
        Card(
          elevation: 0,
          color: backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
            side: BorderSide(color: darkColor.withAlpha(77), width: 1),
          ),
          child: InkWell(
            onTap: () => _showColorPickerDialog(),
            borderRadius: BorderRadius.circular(4),
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _selectedColor.withAlpha(31),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.palette_rounded,
                      color: _selectedColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Color',
                          style: TextStyle(
                            color: highContrastDarkBlue,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Choose theme color for your payable',
                          style: TextStyle(
                            color: darkColor.withAlpha(153),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: darkColor.withAlpha(153),
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Choose Icon Card
        Card(
          elevation: 0,
          color: backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
            side: BorderSide(color: darkColor.withAlpha(77), width: 1),
          ),
          child: InkWell(
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => IconsScreen(
                    selectedIcon: _selectedIcon,
                    onIconSelected: (icon) {
                      setState(() {
                        _selectedIcon = icon;
                      });
                    },
                  ),
                ),
              );
            },
            borderRadius: BorderRadius.circular(4),
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: darkColor.withAlpha(31),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: _selectedIcon is IconData
                        ? Icon(
                            _selectedIcon as IconData,
                            color: darkColor,
                            size: 24,
                          )
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              _selectedIcon as File,
                              fit: BoxFit.contain,
                              width: 24,
                              height: 24,
                            ),
                          ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Choose Icon',
                          style: TextStyle(
                            color: highContrastDarkBlue,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Browse and select from icon library',
                          style: TextStyle(
                            color: darkColor.withAlpha(153),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: darkColor.withAlpha(153),
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildM3TextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    int? minLines,
    TextInputType? keyboardType,
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      minLines: minLines,
      keyboardType: keyboardType,
      textAlign: TextAlign.left,
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
        color: highContrastDarkBlue,
        fontWeight: FontWeight.w400,
        fontSize: 16,
        height: 1.5,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: WidgetStateTextStyle.resolveWith((states) {
          if (states.contains(WidgetState.focused)) {
            return TextStyle(
              color: highContrastBlue,
              fontWeight: FontWeight.w400,
              fontSize: 12,
            );
          }
          return TextStyle(
            color: darkColor.withAlpha(153),
            fontWeight: FontWeight.w400,
            fontSize: 16,
          );
        }),
        hintText: hint,
        hintStyle: TextStyle(
          color: darkColor.withAlpha(153),
          fontWeight: FontWeight.w400,
          fontSize: 16,
        ),
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 16, right: 16),
          child: Icon(icon, color: darkColor.withAlpha(179), size: 24),
        ),
        prefixIconConstraints: const BoxConstraints(
          minWidth: 56,
          minHeight: 56,
        ),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Theme.of(context).brightness == Brightness.dark
            ? lightColor.withAlpha(20)
            : const Color(0xFFECF4FF),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(color: darkColor.withAlpha(77), width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(color: darkColor.withAlpha(77), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(color: highContrastBlue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: Color(0xFFB3261E), width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: Color(0xFFB3261E), width: 2),
        ),
        contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        isDense: false,
      ),
    );
  }

  Widget _buildM3DropdownField({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      onChanged: onChanged,
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
        color: highContrastDarkBlue,
        fontWeight: FontWeight.w400,
        fontSize: 16,
        height: 1.5,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: WidgetStateTextStyle.resolveWith((states) {
          if (states.contains(WidgetState.focused)) {
            return TextStyle(
              color: highContrastBlue,
              fontWeight: FontWeight.w400,
              fontSize: 12,
            );
          }
          return TextStyle(
            color: darkColor.withAlpha(153),
            fontWeight: FontWeight.w400,
            fontSize: 16,
          );
        }),
        filled: true,
        fillColor: Theme.of(context).brightness == Brightness.dark
            ? lightColor.withAlpha(20)
            : const Color(0xFFECF4FF),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(color: darkColor.withAlpha(77), width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(color: darkColor.withAlpha(77), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(color: highContrastBlue, width: 2),
        ),
        contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        isDense: false,
      ),
      dropdownColor: backgroundColor,
      items: items.map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(
            value,
            style: TextStyle(
              color: highContrastDarkBlue,
              fontWeight: FontWeight.w400,
              fontSize: 16,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildM3DateField({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
    bool clearable = false,
    VoidCallback? onClear,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? lightColor.withAlpha(20)
              : const Color(0xFFECF4FF),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: darkColor.withAlpha(77), width: 1),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_rounded,
              color: darkColor.withAlpha(179),
              size: 24,
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: date != null
                          ? highContrastBlue
                          : darkColor.withAlpha(153),
                      fontWeight: FontWeight.w400,
                      fontSize: date != null ? 12 : 16,
                    ),
                  ).animate().fadeIn(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                  ),
                  if (date != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      '${date.day}/${date.month}/${date.year}',
                      style: TextStyle(
                        color: highContrastDarkBlue,
                        fontWeight: FontWeight.w400,
                        fontSize: 16,
                        height: 1.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            if (clearable && date != null && onClear != null) ...[
              const SizedBox(width: 8),
              InkWell(
                onTap: onClear,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  child: Icon(
                    Icons.clear_rounded,
                    color: darkColor.withAlpha(153),
                    size: 20,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showColorPickerDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ColorPickerScreen(
          initialColor: _selectedColor,
          currentTitle: _titleController.text,
          currentIcon: _selectedIcon,
          currentAmount: _amountController.text,
          currentDescription: _descriptionController.text,
          currentDueDate: _getBillingInfo(),
          onColorSelected: (color) {
            setState(() {
              _selectedColor = color;
            });
          },
        ),
      ),
    );
  }

  Widget _buildCategoryPicker() {
    return _buildM3DropdownField(
      label: 'Category',
      value: _selectedCategory,
      items: _categories.map((c) => c['name'] as String).toList(),
      onChanged: (value) {
        setState(() {
          _selectedCategory = value!;
        });
      },
    );
  }

  Widget _buildBillingCyclePicker() {
    return _buildM3DropdownField(
      label: 'Billing Cycle',
      value: _selectedBillingCycle,
      items: ['Daily', 'Weekly', 'Monthly', 'Yearly'],
      onChanged: (value) => setState(() => _selectedBillingCycle = value!),
    );
  }

  Widget _buildPaymentMethodPicker() {
    return InkWell(
      onTap: () => _showPaymentMethodSheet(),
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: backgroundColor.withAlpha(120),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: darkColor.withAlpha(77), width: 1),
        ),
        child: Row(
          children: [
            Icon(Icons.payment_rounded, color: darkColor, size: 24),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Payment Method',
                    style: TextStyle(
                      color: darkColor,
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _selectedPaymentMethod,
                    style: TextStyle(
                      color: highContrastDarkBlue,
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_drop_down_rounded, color: darkColor, size: 24),
          ],
        ),
      ),
    );
  }

  void _showPaymentMethodSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Bottom sheet handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: darkColor.withAlpha(102),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Header section
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Payment Methods',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  color: highContrastDarkBlue,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 24,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Choose how you\'ll pay for this payable',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: darkColor.withAlpha(153),
                                  fontSize: 14,
                                ),
                          ),
                        ],
                      ),
                    ),
                    // Action buttons in header
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: darkColor.withAlpha(31),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            onPressed: _isLoadingPaymentMethods
                                ? null
                                : () async {
                                    await _loadCustomPaymentMethods();
                                  },
                            icon: Icon(
                              Icons.refresh_rounded,
                              color: darkColor,
                              size: 20,
                            ),
                            tooltip: 'Refresh Payment Methods',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: highContrastBlue,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _showAddPaymentMethodDialog();
                            },
                            icon: Icon(
                              Icons.add_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                            tooltip: 'Add Payment Method',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // All payment methods section
                Row(
                  children: [
                    Text(
                      'All Methods',
                      style: TextStyle(
                        color: darkColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const Spacer(),
                    if (_customPaymentMethods.isNotEmpty)
                      Text(
                        '${allPaymentMethods.length} methods',
                        style: TextStyle(
                          color: darkColor.withAlpha(153),
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                // Payment methods list - Stacked Card Design
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.6,
                  ),
                  child: _isLoadingPaymentMethods
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(
                                  color: highContrastBlue,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Loading payment methods...',
                                  style: TextStyle(
                                    color: darkColor,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : SingleChildScrollView(
                          child: Column(
                            children: [
                              for (
                                int index = 0;
                                index < allPaymentMethods.length;
                                index++
                              ) ...[
                                _buildStackedPaymentMethodCard(
                                  method: allPaymentMethods[index],
                                  index: index,
                                  isLast: index == allPaymentMethods.length - 1,
                                  onTap: () {
                                    setState(() {
                                      _selectedPaymentMethod =
                                          allPaymentMethods[index]['name']
                                              as String;
                                    });
                                    Navigator.pop(context);
                                  },
                                  onManage: () {
                                    Navigator.pop(context);
                                    _showManagePaymentMethodDialog(
                                      allPaymentMethods[index],
                                    );
                                  },
                                ),
                              ],
                            ],
                          ),
                        ),
                ),
                const SizedBox(height: 16),
                SizedBox(height: MediaQuery.of(context).padding.bottom),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStackedPaymentMethodCard({
    required Map<String, dynamic> method,
    required int index,
    required bool isLast,
    required VoidCallback onTap,
    required VoidCallback onManage,
  }) {
    final isSelected = _selectedPaymentMethod == method['name'];

    // Dynamic background color (adapts to theme)
    final cardBackgroundColor = isSelected
        ? highContrastBlue.withAlpha(31)
        : (Theme.of(context).brightness == Brightness.dark
              ? lightColor.withAlpha(50)
              : lightColor.withAlpha(50));

    // Position-based border radius for stacked effect
    BorderRadius borderRadius;
    if (index == 0) {
      // First card: 24px top corners, 5px bottom corners
      borderRadius = const BorderRadius.only(
        topLeft: Radius.circular(24),
        topRight: Radius.circular(24),
        bottomLeft: Radius.circular(5),
        bottomRight: Radius.circular(5),
      );
    } else if (isLast) {
      // Last card: 5px top corners, 24px bottom corners
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
        color: cardBackgroundColor,
        shape: RoundedRectangleBorder(borderRadius: borderRadius),
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius,
          splashColor: isSelected
              ? highContrastBlue.withAlpha(31)
              : highContrastBlue.withAlpha(20),
          highlightColor: isSelected
              ? highContrastBlue.withAlpha(20)
              : highContrastBlue.withAlpha(15),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Leading icon
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? highContrastBlue.withAlpha(41)
                        : darkColor.withAlpha(31),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    method['icon'] as IconData,
                    color: isSelected ? highContrastBlue : darkColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                // Title and subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        method['name'] as String,
                        style: TextStyle(
                          color: highContrastDarkBlue,
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                        ),
                      ),
                      if (method['isCustom'] == true) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Custom payment method',
                          style: TextStyle(
                            color: darkColor.withAlpha(153),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Trailing elements
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isSelected)
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: highContrastBlue,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    if (method['isCustom'] == true) ...[
                      if (isSelected) const SizedBox(width: 8),
                      IconButton(
                        icon: Icon(
                          Icons.more_vert_rounded,
                          color: darkColor.withAlpha(153),
                          size: 18,
                        ),
                        onPressed: onManage,
                        style: IconButton.styleFrom(
                          minimumSize: const Size(32, 32),
                          padding: const EdgeInsets.all(6),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAddPaymentMethodDialog() {
    final TextEditingController cardNameController = TextEditingController();
    final TextEditingController lastFourDigitsController =
        TextEditingController();
    IconData selectedIcon = Icons.credit_card_rounded;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.all(24),
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.9,
                  maxHeight: MediaQuery.of(context).size.height * 0.8,
                ),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(25),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header Section
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
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
                              color: highContrastBlue.withAlpha(41),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              Icons.add_card_rounded,
                              color: highContrastBlue,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Add Payment Method',
                                  style: TextStyle(
                                    color: highContrastDarkBlue,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 20,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Create a custom payment method',
                                  style: TextStyle(
                                    color: darkColor.withAlpha(179),
                                    fontWeight: FontWeight.w400,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Content Section
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Card Details Section
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: lightColor.withAlpha(50),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: darkColor.withAlpha(51),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.credit_card_rounded,
                                        color: highContrastBlue,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Card Details',
                                        style: TextStyle(
                                          color: highContrastDarkBlue,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  TextField(
                                    controller: cardNameController,
                                    style: TextStyle(
                                      color: highContrastDarkBlue,
                                      fontWeight: FontWeight.w400,
                                      fontSize: 16,
                                    ),
                                    decoration: InputDecoration(
                                      labelText: 'Card Name',
                                      hintText: 'e.g. Chase Visa, Mastercard',
                                      prefixIcon: Icon(
                                        Icons.badge_rounded,
                                        color: darkColor.withAlpha(179),
                                      ),
                                      filled: true,
                                      fillColor:
                                          Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? lightColor.withAlpha(20)
                                          : const Color(0xFFECF4FF),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: darkColor.withAlpha(77),
                                          width: 1,
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: darkColor.withAlpha(77),
                                          width: 1,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: highContrastBlue,
                                          width: 2,
                                        ),
                                      ),
                                      contentPadding: const EdgeInsets.fromLTRB(
                                        16,
                                        16,
                                        16,
                                        16,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  TextField(
                                    controller: lastFourDigitsController,
                                    keyboardType: TextInputType.number,
                                    maxLength: 4,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                    ],
                                    style: TextStyle(
                                      color: highContrastDarkBlue,
                                      fontWeight: FontWeight.w400,
                                      fontSize: 16,
                                    ),
                                    decoration: InputDecoration(
                                      labelText: 'Last 4 Digits',
                                      hintText: '1234',
                                      prefixIcon: Icon(
                                        Icons.numbers_rounded,
                                        color: darkColor.withAlpha(179),
                                      ),
                                      filled: true,
                                      fillColor:
                                          Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? lightColor.withAlpha(20)
                                          : const Color(0xFFECF4FF),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: darkColor.withAlpha(77),
                                          width: 1,
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: darkColor.withAlpha(77),
                                          width: 1,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: highContrastBlue,
                                          width: 2,
                                        ),
                                      ),
                                      contentPadding: const EdgeInsets.fromLTRB(
                                        16,
                                        16,
                                        16,
                                        16,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Icon Selection Section
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: lightColor.withAlpha(50),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: darkColor.withAlpha(51),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.palette_rounded,
                                        color: highContrastBlue,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Choose Icon',
                                        style: TextStyle(
                                          color: highContrastDarkBlue,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Select an icon to represent your payment method',
                                    style: TextStyle(
                                      color: darkColor.withAlpha(153),
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  GridView.count(
                                    crossAxisCount: 4,
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    crossAxisSpacing: 12,
                                    mainAxisSpacing: 12,
                                    childAspectRatio: 1,
                                    children:
                                        [
                                          Icons.credit_card_rounded,
                                          Icons.account_balance_wallet_rounded,
                                          Icons.payment_rounded,
                                          Icons.card_membership_rounded,
                                          Icons.account_balance_rounded,
                                          Icons.savings_rounded,
                                          Icons.money_rounded,
                                          Icons.attach_money_rounded,
                                        ].map((icon) {
                                          final isSelected =
                                              selectedIcon == icon;
                                          return GestureDetector(
                                            onTap: () {
                                              setState(() {
                                                selectedIcon = icon;
                                              });
                                            },
                                            child:
                                                Container(
                                                  padding: const EdgeInsets.all(
                                                    16,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: isSelected
                                                        ? highContrastBlue
                                                              .withAlpha(31)
                                                        : backgroundColor,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          16,
                                                        ),
                                                    border: Border.all(
                                                      color: isSelected
                                                          ? highContrastBlue
                                                          : darkColor.withAlpha(
                                                              77,
                                                            ),
                                                      width: isSelected ? 2 : 1,
                                                    ),
                                                  ),
                                                  child: Icon(
                                                    icon,
                                                    color: isSelected
                                                        ? highContrastBlue
                                                        : darkColor,
                                                    size: 28,
                                                  ),
                                                ).animate().scale(
                                                  duration: const Duration(
                                                    milliseconds: 200,
                                                  ),
                                                  curve: Curves.easeOutCubic,
                                                  begin: const Offset(
                                                    0.95,
                                                    0.95,
                                                  ),
                                                  end: const Offset(1.0, 1.0),
                                                ),
                                          );
                                        }).toList(),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Actions Section
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: lightColor.withAlpha(25),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(28),
                          bottomRight: Radius.circular(28),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () => Navigator.pop(context),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 14,
                                ),
                                backgroundColor: lightColor.withAlpha(100),
                                foregroundColor: darkColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'Cancel',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                if (cardNameController.text.trim().isNotEmpty &&
                                    lastFourDigitsController.text
                                            .trim()
                                            .length ==
                                        4) {
                                  final navigator = Navigator.of(context);
                                  final scaffoldMessenger =
                                      ScaffoldMessenger.of(context);
                                  try {
                                    final paymentMethodName =
                                        '${cardNameController.text.trim()} •••• ${lastFourDigitsController.text.trim()}';

                                    // Create payment method object
                                    final paymentMethod = PaymentMethod(
                                      name: paymentMethodName,
                                      cardName: cardNameController.text.trim(),
                                      lastFourDigits: lastFourDigitsController
                                          .text
                                          .trim(),
                                      iconCodePoint: selectedIcon.codePoint,
                                      createdAt: DateTime.now(),
                                      updatedAt: DateTime.now(),
                                    );

                                    // Save to database
                                    await PaymentMethodDatabase.insertPaymentMethod(
                                      paymentMethod,
                                    );

                                    // Reload payment methods from database
                                    await _loadCustomPaymentMethods();

                                    if (!mounted) return;
                                    setState(() {
                                      _selectedPaymentMethod =
                                          paymentMethodName;
                                    });

                                    navigator.pop();
                                  } catch (e) {
                                    scaffoldMessenger.showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Error saving payment method',
                                        ),
                                      ),
                                    );
                                  }
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 14,
                                ),
                                backgroundColor: highContrastBlue,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.add_rounded, size: 18),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      'Add Method',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showManagePaymentMethodDialog(Map<String, dynamic> method) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(24),
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.9,
            ),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(25),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header Section
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
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
                          color: darkColor.withAlpha(41),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          method['icon'] as IconData,
                          color: darkColor,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              method['name'] as String,
                              style: TextStyle(
                                color: highContrastDarkBlue,
                                fontWeight: FontWeight.w600,
                                fontSize: 20,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Manage your payment method',
                              style: TextStyle(
                                color: darkColor.withAlpha(179),
                                fontWeight: FontWeight.w400,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Content Section
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Column(
                    children: [
                      // Edit Option
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: lightColor.withAlpha(50),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: highContrastBlue.withAlpha(77),
                            width: 1,
                          ),
                        ),
                        child: InkWell(
                          onTap: () {
                            Navigator.pop(context);
                            _showEditPaymentMethodDialog(method);
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: highContrastBlue.withAlpha(41),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.edit_rounded,
                                    color: highContrastBlue,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Edit',
                                        style: TextStyle(
                                          color: highContrastDarkBlue,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Update details and icon',
                                        style: TextStyle(
                                          color: darkColor.withAlpha(153),
                                          fontWeight: FontWeight.w400,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  color: highContrastBlue,
                                  size: 16,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Delete Option
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withAlpha(15),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFFEF4444).withAlpha(77),
                            width: 1,
                          ),
                        ),
                        child: InkWell(
                          onTap: () async {
                            final navigator = Navigator.of(context);
                            final scaffoldMessenger = ScaffoldMessenger.of(
                              context,
                            );
                            try {
                              final methodName = method['name'] as String;

                              // Delete from database
                              await PaymentMethodDatabase.deletePaymentMethodByName(
                                methodName,
                              );

                              // Reload payment methods from database
                              await _loadCustomPaymentMethods();

                              if (!mounted) return;
                              setState(() {
                                // Reset to default if the deleted method was selected
                                if (_selectedPaymentMethod == methodName) {
                                  _selectedPaymentMethod = 'Not set';
                                }
                              });

                              navigator.pop();
                            } catch (e) {
                              if (mounted) {
                                scaffoldMessenger.showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Error deleting payment method',
                                    ),
                                  ),
                                );
                              }
                            }
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFFEF4444,
                                    ).withAlpha(41),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.delete_rounded,
                                    color: const Color(0xFFEF4444),
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Delete',
                                        style: TextStyle(
                                          color: const Color(0xFFEF4444),
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Remove this method permanently',
                                        style: TextStyle(
                                          color: const Color(
                                            0xFFEF4444,
                                          ).withAlpha(179),
                                          fontWeight: FontWeight.w400,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  color: const Color(0xFFEF4444),
                                  size: 16,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Actions Section
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: lightColor.withAlpha(25),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(28),
                      bottomRight: Radius.circular(28),
                    ),
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 14,
                        ),
                        backgroundColor: lightColor.withAlpha(100),
                        foregroundColor: darkColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showEditPaymentMethodDialog(Map<String, dynamic> method) {
    final TextEditingController cardNameController = TextEditingController(
      text: method['cardName'] as String,
    );
    final TextEditingController lastFourDigitsController =
        TextEditingController(text: method['lastFourDigits'] as String);
    IconData selectedIcon = method['icon'] as IconData;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.all(24),
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.9,
                  maxHeight: MediaQuery.of(context).size.height * 0.8,
                ),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(25),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header Section
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
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
                              color: highContrastBlue.withAlpha(41),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              Icons.edit_rounded,
                              color: highContrastBlue,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Edit Payment Method',
                                  style: TextStyle(
                                    color: highContrastDarkBlue,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 20,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Update your payment method details',
                                  style: TextStyle(
                                    color: darkColor.withAlpha(179),
                                    fontWeight: FontWeight.w400,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Content Section
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Card Details Section
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: lightColor.withAlpha(50),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: darkColor.withAlpha(51),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.credit_card_rounded,
                                        color: highContrastBlue,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Card Details',
                                        style: TextStyle(
                                          color: highContrastDarkBlue,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  TextField(
                                    controller: cardNameController,
                                    style: TextStyle(
                                      color: highContrastDarkBlue,
                                      fontWeight: FontWeight.w400,
                                      fontSize: 16,
                                    ),
                                    decoration: InputDecoration(
                                      labelText: 'Card Name',
                                      hintText: 'e.g. Chase Visa, Mastercard',
                                      prefixIcon: Icon(
                                        Icons.badge_rounded,
                                        color: darkColor.withAlpha(179),
                                      ),
                                      filled: true,
                                      fillColor:
                                          Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? lightColor.withAlpha(20)
                                          : const Color(0xFFECF4FF),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: darkColor.withAlpha(77),
                                          width: 1,
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: darkColor.withAlpha(77),
                                          width: 1,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: highContrastBlue,
                                          width: 2,
                                        ),
                                      ),
                                      contentPadding: const EdgeInsets.fromLTRB(
                                        16,
                                        16,
                                        16,
                                        16,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  TextField(
                                    controller: lastFourDigitsController,
                                    keyboardType: TextInputType.number,
                                    maxLength: 4,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                    ],
                                    style: TextStyle(
                                      color: highContrastDarkBlue,
                                      fontWeight: FontWeight.w400,
                                      fontSize: 16,
                                    ),
                                    decoration: InputDecoration(
                                      labelText: 'Last 4 Digits',
                                      hintText: '1234',
                                      prefixIcon: Icon(
                                        Icons.numbers_rounded,
                                        color: darkColor.withAlpha(179),
                                      ),
                                      filled: true,
                                      fillColor:
                                          Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? lightColor.withAlpha(20)
                                          : const Color(0xFFECF4FF),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: darkColor.withAlpha(77),
                                          width: 1,
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: darkColor.withAlpha(77),
                                          width: 1,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: highContrastBlue,
                                          width: 2,
                                        ),
                                      ),
                                      contentPadding: const EdgeInsets.fromLTRB(
                                        16,
                                        16,
                                        16,
                                        16,
                                      ),
                                      counterText: '',
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Icon Selection Section
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: lightColor.withAlpha(50),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: darkColor.withAlpha(51),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.palette_rounded,
                                        color: highContrastBlue,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Choose Icon',
                                        style: TextStyle(
                                          color: highContrastDarkBlue,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Select an icon to represent your payment method',
                                    style: TextStyle(
                                      color: darkColor.withAlpha(153),
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  GridView.count(
                                    crossAxisCount: 4,
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    crossAxisSpacing: 12,
                                    mainAxisSpacing: 12,
                                    childAspectRatio: 1,
                                    children:
                                        [
                                          Icons.credit_card_rounded,
                                          Icons.account_balance_wallet_rounded,
                                          Icons.payment_rounded,
                                          Icons.card_membership_rounded,
                                          Icons.account_balance_rounded,
                                          Icons.savings_rounded,
                                          Icons.money_rounded,
                                          Icons.attach_money_rounded,
                                        ].map((icon) {
                                          final isSelected =
                                              selectedIcon == icon;
                                          return GestureDetector(
                                            onTap: () {
                                              setState(() {
                                                selectedIcon = icon;
                                              });
                                            },
                                            child:
                                                Container(
                                                  padding: const EdgeInsets.all(
                                                    16,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: isSelected
                                                        ? highContrastBlue
                                                              .withAlpha(31)
                                                        : backgroundColor,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          16,
                                                        ),
                                                    border: Border.all(
                                                      color: isSelected
                                                          ? highContrastBlue
                                                          : darkColor.withAlpha(
                                                              77,
                                                            ),
                                                      width: isSelected ? 2 : 1,
                                                    ),
                                                  ),
                                                  child: Icon(
                                                    icon,
                                                    color: isSelected
                                                        ? highContrastBlue
                                                        : darkColor,
                                                    size: 28,
                                                  ),
                                                ).animate().scale(
                                                  duration: const Duration(
                                                    milliseconds: 200,
                                                  ),
                                                  curve: Curves.easeOutCubic,
                                                  begin: const Offset(
                                                    0.95,
                                                    0.95,
                                                  ),
                                                  end: const Offset(1.0, 1.0),
                                                ),
                                          );
                                        }).toList(),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Actions Section
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: lightColor.withAlpha(25),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(28),
                          bottomRight: Radius.circular(28),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () => Navigator.pop(context),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 14,
                                ),
                                backgroundColor: lightColor.withAlpha(100),
                                foregroundColor: darkColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'Cancel',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                if (cardNameController.text.trim().isNotEmpty &&
                                    lastFourDigitsController.text
                                            .trim()
                                            .length ==
                                        4) {
                                  final navigator = Navigator.of(context);
                                  final scaffoldMessenger =
                                      ScaffoldMessenger.of(context);
                                  try {
                                    final oldName = method['name'] as String;
                                    final newName =
                                        '${cardNameController.text.trim()} •••• ${lastFourDigitsController.text.trim()}';

                                    // Get the original payment method from database
                                    final originalPaymentMethod =
                                        await PaymentMethodDatabase.getPaymentMethodByName(
                                          oldName,
                                        );

                                    if (originalPaymentMethod != null) {
                                      // Update payment method
                                      final updatedPaymentMethod =
                                          originalPaymentMethod.copyWith(
                                            name: newName,
                                            cardName: cardNameController.text
                                                .trim(),
                                            lastFourDigits:
                                                lastFourDigitsController.text
                                                    .trim(),
                                            iconCodePoint:
                                                selectedIcon.codePoint,
                                            updatedAt: DateTime.now(),
                                          );

                                      // Save to database
                                      await PaymentMethodDatabase.updatePaymentMethod(
                                        updatedPaymentMethod,
                                      );

                                      // Reload payment methods from database
                                      await _loadCustomPaymentMethods();

                                      if (!mounted) return;
                                      setState(() {
                                        // Update selected payment method if it was the one being edited
                                        if (_selectedPaymentMethod == oldName) {
                                          _selectedPaymentMethod = newName;
                                        }
                                      });
                                    }

                                    navigator.pop();
                                  } catch (e) {
                                    scaffoldMessenger.showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Error updating payment method',
                                        ),
                                      ),
                                    );
                                  }
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 14,
                                ),
                                backgroundColor: highContrastBlue,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.save_rounded, size: 18),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      'Save Changes',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
