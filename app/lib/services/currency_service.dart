import 'package:intl/intl.dart';

class CurrencyService {
  static const Map<String, String> supportedCurrencies = {
    'TWD': 'NT\$',
    'USD': '\$',
    'JPY': '¥',
    'EUR': '€',
    'CNY': '¥',
    'KRW': '₩',
    'GBP': '£',
  };

  /// 取得所有支持的幣別代碼
  static List<String> get availableCurrencies =>
      supportedCurrencies.keys.toList();

  /// 根據幣別代碼取得符號
  static String getSymbol(String currency) {
    return supportedCurrencies[currency.toUpperCase()] ?? currency;
  }

  /// 檢查是否為支持的幣別
  static bool isSupported(String currency) {
    return supportedCurrencies.containsKey(currency.toUpperCase());
  }

  /// 格式化金額，包含幣別符號和適當的小數位
  static String formatAmount(double amount, String currency) {
    final currencyCode = currency.toUpperCase();

    if (!isSupported(currencyCode)) {
      return '${amount.toStringAsFixed(2)} $currency';
    }

    final symbol = getSymbol(currencyCode);

    // 根據幣別決定小數位數
    int decimalPlaces = 2;
    if (currencyCode == 'JPY' ||
        currencyCode == 'KRW' ||
        currencyCode == 'CNY') {
      decimalPlaces = 0;
    }

    final formatter = NumberFormat.currency(
      symbol: '',
      decimalDigits: decimalPlaces,
      locale: _getLocaleForCurrency(currencyCode),
    );

    return '$symbol${formatter.format(amount).trim()}';
  }

  /// 根據幣別取得適當的語言環境
  static String _getLocaleForCurrency(String currencyCode) {
    switch (currencyCode) {
      case 'TWD':
        return 'zh_TW';
      case 'CNY':
        return 'zh_CN';
      case 'JPY':
        return 'ja_JP';
      case 'KRW':
        return 'ko_KR';
      case 'EUR':
        return 'de_DE';
      case 'GBP':
        return 'en_GB';
      case 'USD':
      default:
        return 'en_US';
    }
  }

  /// 解析金額字串（移除幣別符號）
  static double? parseAmount(String amountStr) {
    // 移除常見的幣別符號
    String cleaned = amountStr.replaceAll(RegExp(r'[^\d.\-]'), '');
    return double.tryParse(cleaned);
  }
}
