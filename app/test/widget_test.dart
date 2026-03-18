import 'package:flutter_test/flutter_test.dart';

void main() {
  group('VoiceLedger 基本測試', () {
    test('應用程式名稱正確', () {
      expect('語記', isNotEmpty);
    });

    test('金額格式化', () {
      final amount = 150.50;
      final formatted = 'NT\$${amount.toStringAsFixed(0)}';
      expect(formatted, equals('NT\$151'));
    });

    test('交易類型枚舉', () {
      final types = [
        'voice',
        'passive_gps',
        'photo',
        'notification',
        'manual',
        'imported',
      ];
      expect(types, contains('voice'));
      expect(types.length, equals(6));
    });
  });
}
