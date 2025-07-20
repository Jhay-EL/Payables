import 'dart:io';
import 'package:flutter/material.dart';
import 'package:payables/models/subscription.dart';
import 'package:payables/data/subscription_database.dart';

class SubscriptionDetailsScreen extends StatefulWidget {
  final Subscription subscription;

  const SubscriptionDetailsScreen({super.key, required this.subscription});

  @override
  State<SubscriptionDetailsScreen> createState() =>
      _SubscriptionDetailsScreenState();
}

class _SubscriptionDetailsScreenState extends State<SubscriptionDetailsScreen> {
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

  void _saveChanges() async {
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
      colorValue: _selectedColor.value,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      updatedAt: DateTime.now(),
    );

    try {
      await SubscriptionDatabase.updateSubscription(updatedSubscription);
      if (!mounted) return;
      Navigator.of(context).pop(true); // Pop with a result to indicate success
    } catch (e) {
      _showErrorSnackBar('Error updating subscription: $e');
    }
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
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: BackButton(color: highContrastDarkBlue),
        title: Text(
          _isEditing ? 'Edit Payable' : 'Payable Details',
          style: TextStyle(
            color: highContrastDarkBlue,
            fontWeight: FontWeight.w500,
          ),
        ),
        actions: [
          if (!_isEditing)
            TextButton(
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
              child: Text(
                'Edit',
                style: TextStyle(
                  color: highContrastBlue,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
          const SizedBox(width: 16),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Card Preview
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: _buildCardPreview(),
                    ),
                    // Details or Edit Form
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: _isEditing
                          ? _buildEditForm()
                          : _buildDetailsView(),
                    ),
                  ],
                ),
              ),
            ),
            if (_isEditing) _buildEditModeButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildCardPreview() {
    return Container(
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
                ? Icon(_selectedIcon as IconData, size: 22, color: Colors.white)
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
    );
  }

  Widget _buildEditForm() {
    return Column(
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
    );
  }

  Widget _buildDetailsView() {
    return Column(
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
        const SizedBox(height: 30),
      ],
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

  Widget _buildEditModeButtons() {
    return Container(
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
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
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
