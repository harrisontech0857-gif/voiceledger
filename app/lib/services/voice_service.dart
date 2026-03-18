import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:logger/logger.dart';

final voiceServiceProvider = Provider<VoiceService>((ref) {
  return VoiceService();
});

final voiceListeningProvider = StateProvider<bool>((ref) => false);

final recognizedTextProvider = StateProvider<String>((ref) => '');

final confidenceProvider = StateProvider<double>((ref) => 0.0);

class VoiceService {
  final stt.SpeechToText _speechToText = stt.SpeechToText();
  final Logger _logger = Logger();
  bool _isInitialized = false;

  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      _isInitialized = await _speechToText.initialize(
        onError: (error) {
          _logger.e('Speech to text error: $error');
        },
        onStatus: (status) {
          _logger.d('Speech to text status: $status');
        },
      );
      return _isInitialized;
    } catch (e) {
      _logger.e('Failed to initialize speech to text: $e');
      return false;
    }
  }

  Stream<String> startListening({String localeId = 'zh_TW'}) async* {
    await _initializeIfNeeded();

    _speechToText.listen(
      onResult: (result) {
        // Results handled via periodic polling below
      },
      localeId: localeId,
      listenFor: const Duration(minutes: 5),
      pauseFor: const Duration(seconds: 3),
      partialResults: true,
    );

    final endTime = DateTime.now().add(const Duration(minutes: 5));
    while (DateTime.now().isBefore(endTime) && _speechToText.isListening) {
      yield _speechToText.lastRecognizedWords;
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  Future<String> listenOnce({
    String localeId = 'zh_TW',
    Duration timeout = const Duration(seconds: 30),
  }) async {
    try {
      await _initializeIfNeeded();

      final completer = Stream.periodic(const Duration(milliseconds: 100));

      _speechToText.listen(
        onResult: (result) {
          // Handled by stream
        },
        localeId: localeId,
        listenFor: timeout,
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
      );

      await Future.delayed(timeout);
      return _speechToText.lastRecognizedWords;
    } catch (e) {
      _logger.e('Error during voice listening: $e');
      return '';
    }
  }

  Future<void> stopListening() async {
    try {
      await _speechToText.stop();
    } catch (e) {
      _logger.e('Error stopping voice listening: $e');
    }
  }

  bool get isListening => _speechToText.isListening;

  bool get isNotListening => !_speechToText.isListening;

  Future<void> _initializeIfNeeded() async {
    if (!_isInitialized) {
      await initialize();
    }
  }

  Future<List<String>> getAvailableLanguages() async {
    try {
      final locales = await _speechToText.locales();
      return locales.map((l) => l.localeId).toList();
    } catch (e) {
      _logger.e('Error getting available languages: $e');
      return [];
    }
  }

  void dispose() {
    try {
      _speechToText.stop();
    } catch (e) {
      _logger.e('Error disposing speech service: $e');
    }
  }
}

// Providers for listening state management
final voiceStreamProvider = StreamProvider<String>((ref) async* {
  final voiceService = ref.watch(voiceServiceProvider);
  await voiceService.initialize();

  yield* voiceService.startListening();
});

final currentListeningTextProvider = StateProvider.autoDispose<String>((ref) {
  return '';
});
