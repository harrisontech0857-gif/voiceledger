import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:logger/logger.dart';

final voiceServiceProvider = Provider<VoiceService>((ref) {
  return VoiceService();
});

final voiceListeningProvider = StateProvider<bool>((ref) => false);

final recognizedTextProvider = StateProvider<String>((ref) => '');

final confidenceProvider = StateProvider<double>((ref) => 0.0);

/// 語音識別服務
///
/// 使用 speech_to_text 套件進行語音轉文字
class VoiceService {
  final stt.SpeechToText _speechToText = stt.SpeechToText();
  final Logger _logger = Logger();
  bool _isInitialized = false;

  /// 初始化語音服務
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

  /// 開始監聽語音（單次）
  Future<String> listenOnce({
    String localeId = 'zh_TW',
    Duration timeout = const Duration(seconds: 30),
  }) async {
    try {
      await _initializeIfNeeded();

      _speechToText.listen(
        onResult: (result) {
          // 結果由 lastRecognizedWords 提供
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

  /// 停止監聽
  Future<void> stopListening() async {
    try {
      await _speechToText.stop();
    } catch (e) {
      _logger.e('Error stopping voice listening: $e');
    }
  }

  /// 取得監聽狀態
  bool get isListening => _speechToText.isListening;

  bool get isNotListening => !_speechToText.isListening;

  /// 取得可用語言列表
  Future<List<String>> getAvailableLanguages() async {
    try {
      final locales = await _speechToText.locales();
      return locales.map((l) => l.localeId).toList();
    } catch (e) {
      _logger.e('Error getting available languages: $e');
      return [];
    }
  }

  /// 清理資源
  void dispose() {
    try {
      _speechToText.stop();
    } catch (e) {
      _logger.e('Error disposing speech service: $e');
    }
  }

  /// 內部初始化函數
  Future<void> _initializeIfNeeded() async {
    if (!_isInitialized) {
      await initialize();
    }
  }
}

// 用於聲明式監聽的提供者
final voiceStreamProvider = StreamProvider<String>((ref) async* {
  final voiceService = ref.watch(voiceServiceProvider);
  await voiceService.initialize();

  // 提供者實現
  yield '';
});

final currentListeningTextProvider = StateProvider.autoDispose<String>((ref) {
  return '';
});
