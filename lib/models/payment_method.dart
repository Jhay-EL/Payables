import 'package:flutter/material.dart';

class PaymentMethod {
  final int? id;
  final String name;
  final String cardName;
  final String lastFourDigits;
  final int iconCodePoint;
  final DateTime createdAt;
  final DateTime updatedAt;

  PaymentMethod({
    this.id,
    required this.name,
    required this.cardName,
    required this.lastFourDigits,
    required this.iconCodePoint,
    required this.createdAt,
    required this.updatedAt,
  });

  // Create a copy with updated fields
  PaymentMethod copyWith({
    int? id,
    String? name,
    String? cardName,
    String? lastFourDigits,
    int? iconCodePoint,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PaymentMethod(
      id: id ?? this.id,
      name: name ?? this.name,
      cardName: cardName ?? this.cardName,
      lastFourDigits: lastFourDigits ?? this.lastFourDigits,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Convert to Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'card_name': cardName,
      'last_four_digits': lastFourDigits,
      'icon_code_point': iconCodePoint,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  // Create from Map (database retrieval)
  factory PaymentMethod.fromMap(Map<String, dynamic> map) {
    return PaymentMethod(
      id: map['id'] as int?,
      name: map['name'] as String,
      cardName: map['card_name'] as String,
      lastFourDigits: map['last_four_digits'] as String,
      iconCodePoint: map['icon_code_point'] as int,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
    );
  }

  // Convert to Map for use in UI (similar to existing structure)
  Map<String, dynamic> toUIMap() {
    return {
      'name': name,
      'icon': IconData(iconCodePoint, fontFamily: 'MaterialIcons'),
      'isCustom': true,
      'cardName': cardName,
      'lastFourDigits': lastFourDigits,
    };
  }

  // Get the icon as IconData
  IconData get icon => IconData(iconCodePoint, fontFamily: 'MaterialIcons');

  @override
  String toString() {
    return 'PaymentMethod{id: $id, name: $name, cardName: $cardName, lastFourDigits: $lastFourDigits, iconCodePoint: $iconCodePoint}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PaymentMethod &&
        other.id == id &&
        other.name == name &&
        other.cardName == cardName &&
        other.lastFourDigits == lastFourDigits &&
        other.iconCodePoint == iconCodePoint;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        cardName.hashCode ^
        lastFourDigits.hashCode ^
        iconCodePoint.hashCode;
  }
}
