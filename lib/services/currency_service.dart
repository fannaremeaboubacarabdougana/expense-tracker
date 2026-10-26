import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CurrencyService extends ChangeNotifier {
  static const String _currencyKey = 'selected_currency';

  static const Map<String, String> currencies = {
    'GHS': 'GH₵',
    'USD': '\$',
    'EUR': '€',
    'GBP': '£',
    'NGN': '₦',
    'XOF': 'CFA',
  };

  String _currencyCode = 'GHS';

  String get currencyCode => _currencyCode;

  String get currencySymbol => currencies[_currencyCode] ?? 'GH₵';

  Future<void> loadCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_currencyKey);

    if (saved != null && currencies.containsKey(saved)) {
      _currencyCode = saved;
    }

    notifyListeners();
  }

  Future<void> setCurrency(String code) async {
    if (!currencies.containsKey(code)) {
      throw ArgumentError('Unsupported currency: $code');
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currencyKey, code);

    _currencyCode = code;
    notifyListeners();
  }

  String formatAmount(double amount) {
    return '$currencySymbol${amount.toStringAsFixed(2)}';
  }
}
