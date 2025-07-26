class Subscription {
  final int? id;
  final String title;
  final String currency;
  final double amount;
  final DateTime billingDate;
  final DateTime? endDate;
  final String billingCycle; // 'Daily', 'Weekly', 'Monthly', 'Yearly'
  final String type;
  final String paymentMethod;
  final String? websiteLink;
  final String? shortDescription;
  final String category;
  final int? iconCodePoint; // Store IconData.codePoint
  final String? iconFilePath; // Store path for custom image icons
  final int colorValue; // Store Color.value
  final String? notes;
  final String status; // 'active', 'paused', 'finished'
  final int alertDays; // Days before billing date to send notification
  final DateTime createdAt;
  final DateTime updatedAt;

  Subscription({
    this.id,
    required this.title,
    this.currency = 'EUR',
    this.amount = 0.0,
    required this.billingDate,
    this.endDate,
    this.billingCycle = 'Monthly',
    this.type = 'Recurring',
    this.paymentMethod = 'Not set',
    this.websiteLink,
    this.shortDescription,
    required this.category,
    this.iconCodePoint,
    this.iconFilePath,
    required this.colorValue,
    this.notes,
    this.status = 'active',
    this.alertDays = 1, // Default to 1 day before
    required this.createdAt,
    required this.updatedAt,
  });

  // Convert Subscription to Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'currency': currency,
      'amount': amount,
      'billing_date': billingDate.millisecondsSinceEpoch,
      'end_date': endDate?.millisecondsSinceEpoch,
      'billing_cycle': billingCycle,
      'type': type,
      'payment_method': paymentMethod,
      'website_link': websiteLink,
      'short_description': shortDescription,
      'category': category,
      'icon_code_point': iconCodePoint,
      'icon_file_path': iconFilePath,
      'color_value': colorValue,
      'notes': notes,
      'status': status,
      'alert_days': alertDays,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  // Create Subscription from Map (database result)
  factory Subscription.fromMap(Map<String, dynamic> map) {
    return Subscription(
      id: map['id']?.toInt(),
      title: map['title'] ?? '',
      currency: map['currency'] ?? 'EUR',
      amount: map['amount']?.toDouble() ?? 0.0,
      billingDate: DateTime.fromMillisecondsSinceEpoch(map['billing_date']),
      endDate: map['end_date'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['end_date'])
          : null,
      billingCycle: map['billing_cycle'] ?? 'Monthly',
      type: map['type'] ?? 'Recurring',
      paymentMethod: map['payment_method'] ?? 'Not set',
      websiteLink: map['website_link'],
      shortDescription: map['short_description'],
      category: map['category'] ?? 'Not set',
      iconCodePoint: map['icon_code_point']?.toInt(),
      iconFilePath: map['icon_file_path'],
      colorValue: map['color_value']?.toInt() ?? 0xFF000000, // default black
      notes: map['notes'],
      status: map['status'] ?? 'active',
      alertDays: map['alert_days']?.toInt() ?? 1, // Default to 1 day
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at']),
    );
  }

  // Create a copy with updated fields
  Subscription copyWith({
    int? id,
    String? title,
    String? currency,
    double? amount,
    DateTime? billingDate,
    DateTime? endDate,
    String? billingCycle,
    String? type,
    String? paymentMethod,
    String? websiteLink,
    String? shortDescription,
    String? category,
    int? iconCodePoint,
    String? iconFilePath,
    int? colorValue,
    String? notes,
    String? status,
    int? alertDays,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Subscription(
      id: id ?? this.id,
      title: title ?? this.title,
      currency: currency ?? this.currency,
      amount: amount ?? this.amount,
      billingDate: billingDate ?? this.billingDate,
      endDate: endDate ?? this.endDate,
      billingCycle: billingCycle ?? this.billingCycle,
      type: type ?? this.type,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      websiteLink: websiteLink ?? this.websiteLink,
      shortDescription: shortDescription ?? this.shortDescription,
      category: category ?? this.category,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      iconFilePath: iconFilePath ?? this.iconFilePath,
      colorValue: colorValue ?? this.colorValue,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      alertDays: alertDays ?? this.alertDays,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Subscription(id: $id, title: $title, amount: $amount, currency: $currency)';
  }
}
