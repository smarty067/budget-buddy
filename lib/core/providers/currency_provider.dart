import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Currency metadata model.
class CurrencyInfo {
  final String code;
  final String symbol;
  final String name;
  final String flag;

  const CurrencyInfo({
    required this.code,
    required this.symbol,
    required this.name,
    required this.flag,
  });
}

/// Supported currencies in Budget Buddy.
final availableCurrencies = <CurrencyInfo>[
  const CurrencyInfo(code: 'INR', symbol: '₹', name: 'Indian Rupee', flag: '🇮🇳'),
  const CurrencyInfo(code: 'USD', symbol: '\$', name: 'US Dollar', flag: '🇺🇸'),
  const CurrencyInfo(code: 'EUR', symbol: '€', name: 'Euro', flag: '🇪🇺'),
  const CurrencyInfo(code: 'GBP', symbol: '£', name: 'British Pound', flag: '🇬🇧'),
  const CurrencyInfo(code: 'AED', symbol: 'AED', name: 'UAE Dirham', flag: '🇦🇪'),
  const CurrencyInfo(code: 'CAD', symbol: 'CA\$', name: 'Canadian Dollar', flag: '🇨🇦'),
  const CurrencyInfo(code: 'AUD', symbol: 'AU\$', name: 'Australian Dollar', flag: '🇦🇺'),
  const CurrencyInfo(code: 'SGD', symbol: 'SG\$', name: 'Singapore Dollar', flag: '🇸🇬'),
  const CurrencyInfo(code: 'JPY', symbol: '¥', name: 'Japanese Yen', flag: '🇯🇵'),
  const CurrencyInfo(code: 'SAR', symbol: 'SAR', name: 'Saudi Riyal', flag: '🇸🇦'),
  const CurrencyInfo(code: 'CNY', symbol: 'CN¥', name: 'Chinese Yuan', flag: '🇨🇳'),
  const CurrencyInfo(code: 'BDT', symbol: '৳', name: 'Bangladeshi Taka', flag: '🇧🇩'),
  const CurrencyInfo(code: 'PKR', symbol: 'Rs', name: 'Pakistani Rupee', flag: '🇵🇰'),
  const CurrencyInfo(code: 'NPR', symbol: 'रू', name: 'Nepalese Rupee', flag: '🇳🇵'),
];

/// Notifier that manages the user's selected currency with Hive local storage persistence.
class CurrencyNotifier extends StateNotifier<CurrencyInfo> {
  CurrencyNotifier() : super(availableCurrencies.first) {
    _loadFromStorage();
  }

  static const _boxName = 'settings_box';
  static const _currencyKey = 'selected_currency_code';

  Future<void> _loadFromStorage() async {
    try {
      final box = await Hive.openBox(_boxName);
      final savedCode = box.get(_currencyKey) as String?;
      if (savedCode != null) {
        final match = availableCurrencies.firstWhere(
          (c) => c.code == savedCode,
          orElse: () => availableCurrencies.first,
        );
        state = match;
      }
    } catch (_) {
      // Default to INR if reading fails
    }
  }

  Future<void> setCurrency(CurrencyInfo currency) async {
    state = currency;
    try {
      final box = await Hive.openBox(_boxName);
      await box.put(_currencyKey, currency.code);
    } catch (_) {}
  }
}

/// State provider for selected Currency.
final currencyProvider =
    StateNotifierProvider<CurrencyNotifier, CurrencyInfo>((ref) {
  return CurrencyNotifier();
});

/// Convenience provider returning the current currency symbol (e.g. '₹', '$').
final currencySymbolProvider = Provider<String>((ref) {
  return ref.watch(currencyProvider).symbol;
});
