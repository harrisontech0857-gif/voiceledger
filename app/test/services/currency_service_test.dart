import 'package:flutter_test/flutter_test.dart';
import 'package:voiceledger/services/currency_service.dart';

void main() {
  group('CurrencyService', () {
    group('getSymbol', () {
      test('TWD 回傳 NT\$', () {
        expect(CurrencyService.getSymbol('TWD'), 'NT\$');
      });

      test('USD 回傳 \$', () {
        expect(CurrencyService.getSymbol('USD'), '\$');
      });

      test('JPY 回傳 ¥', () {
        expect(CurrencyService.getSymbol('JPY'), '¥');
      });

      test('EUR 回傳 €', () {
        expect(CurrencyService.getSymbol('EUR'), '€');
      });

      test('不支援的幣別回傳原始代碼', () {
        expect(CurrencyService.getSymbol('BTC'), 'BTC');
      });

      test('大小寫不敏感', () {
        expect(CurrencyService.getSymbol('twd'), 'NT\$');
        expect(CurrencyService.getSymbol('Usd'), '\$');
      });
    });

    group('isSupported', () {
      test('支援的幣別回傳 true', () {
        expect(CurrencyService.isSupported('TWD'), true);
        expect(CurrencyService.isSupported('USD'), true);
        expect(CurrencyService.isSupported('JPY'), true);
        expect(CurrencyService.isSupported('EUR'), true);
        expect(CurrencyService.isSupported('CNY'), true);
        expect(CurrencyService.isSupported('KRW'), true);
        expect(CurrencyService.isSupported('GBP'), true);
      });

      test('不支援的幣別回傳 false', () {
        expect(CurrencyService.isSupported('BTC'), false);
        expect(CurrencyService.isSupported('ETH'), false);
        expect(CurrencyService.isSupported(''), false);
      });
    });

    group('formatAmount', () {
      test('TWD 格式化含 NT\$ 前綴', () {
        final result = CurrencyService.formatAmount(1500.5, 'TWD');
        expect(result, contains('NT\$'));
        expect(result, contains('1,500'));
      });

      test('JPY 無小數點', () {
        final result = CurrencyService.formatAmount(1500.99, 'JPY');
        expect(result, contains('¥'));
        // JPY 不應包含小數點
        expect(result.contains('.'), false);
      });

      test('USD 有兩位小數', () {
        final result = CurrencyService.formatAmount(42.50, 'USD');
        expect(result, contains('\$'));
        expect(result, contains('42.50'));
      });

      test('不支援的幣別顯示原始代碼', () {
        final result = CurrencyService.formatAmount(100, 'BTC');
        expect(result, contains('BTC'));
        expect(result, contains('100.00'));
      });
    });

    group('parseAmount', () {
      test('解析純數字', () {
        expect(CurrencyService.parseAmount('1500'), 1500);
      });

      test('解析帶符號金額', () {
        expect(CurrencyService.parseAmount('NT\$1500'), 1500);
        expect(CurrencyService.parseAmount('\$42.50'), 42.50);
        expect(CurrencyService.parseAmount('€100.00'), 100.00);
      });

      test('解析帶逗號金額', () {
        expect(CurrencyService.parseAmount('1,500.50'), 1500.50);
      });

      test('空字串回傳 null', () {
        expect(CurrencyService.parseAmount(''), isNull);
      });

      test('純文字回傳 null', () {
        expect(CurrencyService.parseAmount('abc'), isNull);
      });
    });

    group('availableCurrencies', () {
      test('包含 7 種幣別', () {
        expect(CurrencyService.availableCurrencies.length, 7);
      });

      test('包含 TWD', () {
        expect(CurrencyService.availableCurrencies, contains('TWD'));
      });
    });
  });
}
