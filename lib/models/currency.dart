import 'package:flutter/material.dart';

class Currency {
  final String name;
  final String code;
  final String symbol;
  final IconData icon;
  final Color color;

  const Currency({
    required this.name,
    required this.code,
    required this.symbol,
    required this.icon,
    required this.color,
  });
}
