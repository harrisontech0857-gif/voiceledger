import 'package:flutter_test/flutter_test.dart';
import 'package:voiceledger/services/voice_service.dart';

void main() {
  group('VoiceService Tests', () {
    late VoiceService service;

    setUp(() {
      service = VoiceService();
    });

    group('initialization', () {
      test('should start as not initialized', () {
        expect(service.isAvailable, isFalse);
        expect(service.isListening, isFalse);
        expect(service.isNotListening, isTrue);
      });

      test('accumulatedText should be empty initially', () {
        expect(service.accumulatedText, isEmpty);
      });

      test('manualStopMode should default to true', () {
        expect(service.manualStopMode, isTrue);
      });
    });

    group('state properties', () {
      test('isNotListening should be inverse of isListening', () {
        expect(service.isNotListening, equals(!service.isListening));
      });
    });

    group('callbacks', () {
      test('should accept onResult callback', () {
        String? receivedText;
        bool? wasFinal;

        service.onResult = (text, isFinal) {
          receivedText = text;
          wasFinal = isFinal;
        };

        // Manually invoke callback to test wiring
        service.onResult?.call('測試文字', true);

        expect(receivedText, equals('測試文字'));
        expect(wasFinal, isTrue);
      });

      test('should accept onStatus callback', () {
        String? receivedStatus;

        service.onStatus = (status) {
          receivedStatus = status;
        };

        service.onStatus?.call('listening');
        expect(receivedStatus, equals('listening'));
      });
    });

    group('dispose', () {
      test('should not throw when disposed without initialization', () {
        expect(() => service.dispose(), returnsNormally);
      });
    });

    group('getAvailableLanguages', () {
      test('should return a list (may be empty in test env)', () async {
        // In test env, speech_to_text won't be available
        final languages = await service.getAvailableLanguages();
        expect(languages, isA<List<String>>());
      });
    });
  });
}
