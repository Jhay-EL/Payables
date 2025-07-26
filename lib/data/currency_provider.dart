import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CurrencyProvider with ChangeNotifier {
  static const String _currencyKey = 'selected_currency';
  String _selectedCurrency = 'USD'; // Default currency

  String get selectedCurrency => _selectedCurrency;

  CurrencyProvider() {
    _loadCurrency();
  }

  Future<void> _loadCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    _selectedCurrency = prefs.getString(_currencyKey) ?? 'USD';
    notifyListeners();
  }

  Future<void> setCurrency(String currencyCode) async {
    _selectedCurrency = currencyCode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currencyKey, currencyCode);
    notifyListeners();
  }

  // Clear currency preference and reset to default
  static Future<void> clearCurrencyPreference() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currencyKey);
  }
}
