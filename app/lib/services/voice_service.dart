import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:logger/logger.dart';

final voiceServiceProvider = Provider<VoiceService>((ref) {
  return VoiceService();
});

final voiceListeningProvider = StateProvider<bool>((ref) => false);
final recognizedTextProvider = StateProvider<String>((ref) => '');
final confidenceProvider = StateProvider<double>((ref) => 0.0);

/// 語音識別服務（支援即時回饋 + 手動停止）
class VoiceService {
  final stt.SpeechToText _speechToText = stt.SpeechToText();
  final Logger _logger = Logger();
  bool _isInitialized = false;

  /// 即時辨識結果回呼
  void Function(String text, bool isFinal)? onResult;

  /// 狀態變更回呼
  void Function(String status)? onStatus;

  /// 初始化語音服務
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      _isInitialized = await _speechToText.initialize(
        onError: (error) {
          _logger.e('Speech error: ${error.errorMsg}');
          onStatus?.call('error');
        },
        onStatus: (status) {
          _logger.d('Speech status: $status');
          onStatus?.call(status);
        },
      );

      if (_isInitialized) {
        _logger.i('語音服務初始化成功 (Web Speech API)');
      } else {
        _logger.w('語音服務初始化失敗 — 瀏覽器可能不支援');
      }

      return _isInitialized;
    } catch (e) {
      _logger.e('Failed to initialize speech: $e');
      return false;
    }
  }

  /// 開始監聽（即時回傳部分結果）
  Future<void> startListening({
    String localeId = 'zh_TW',
    Duration listenFor = const Duration(seconds: 30),
  }) async {
    await _initializeIfNeeded();

    if (!_isInitialized) {
      onStatus?.call('not_supported');
      return;
    }

    try {
      await _speechToText.listen(
        onResult: (result) {
          final text = result.recognizedWords;
          final isFinal = result.finalResult;
          debugPrint('🎙️ [${isFinal ? "FINAL" : "partial"}] $text');
          onResult?.call(text, isFinal);
        },
        localeId: localeId,
        listenFor: listenFor,
        pauseFor: const Duration(seconds: 4),
        listenOptions: stt.SpeechListenOptions(
          partialResults: true,
          cancelOnError: false,
          autoPunctuation: true,
        ),
      );
    } catch (e) {
      _logger.e('Error starting listening: $e');
      onStatus?.call('error');
    }
  }

  /// 停止監聽（手動）
  Future<String> stopListening() async {
    try {
      await _speechToText.stop();
      return _speechToText.lastRecognizedWords;
    } catch (e) {
      _logger.e('Error stopping: $e');
      return '';
    }
  }

  /// 舊的單次監聽介面（保持相容）
  Future<String> listenOnce({
    String localeId = 'zh_TW',
    Duration timeout = const Duration(seconds: 15),
  }) async {
    final completer = Completer<String>();

    onResult = (text, isFinal) {
      if (isFinal && !completer.isCompleted) {
        completer.complete(text);
      }
    };

    await startListening(localeId: localeId, listenFor: timeout);

    // 超時保護
    Future.delayed(timeout + const Duration(seconds: 2), () {
      if (!completer.isCompleted) {
        final last = _speechToText.lastRecognizedWords;
        completer.complete(last);
      }
    });

    return completer.future;
  }

  bool get isListening => _speechToText.isListening;
  bool get isNotListening => !_speechToText.isListening;
  bool get isAvailable => _isInitialized;

  Future<List<String>> getAvailableLanguages() async {
    try {
      final locales = await _speechToText.locales();
      return locales.map((l) => l.localeId).toList();
    } catch (e) {
      return [];
    }
  }

  void dispose() {
    try {
      _speechToText.stop();
    } catch (_) {}
  }

  Future<void> _initializeIfNeeded() async {
    if (!_isInitialized) await initialize();
  }
}

// 保留舊的 stream provider（相容性）
final voiceStreamProvider = StreamProvider<String>((ref) async* {
  yield '';
});

final currentListeningTextProvider = StateProvider.autoDispose<String>((ref) {
  return '';
});
