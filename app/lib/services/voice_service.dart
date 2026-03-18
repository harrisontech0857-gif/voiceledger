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

  /// 是否啟用手動停止模式（不自動停止）
  bool manualStopMode = true;

  /// 累積的辨識文字（手動停止模式下跨段落累積）
  String _accumulatedText = '';

  /// 開始監聽（即時回傳部分結果）
  ///
  /// [manualStopMode] = true 時，不會因沉默而自動停止，
  /// 使用者必須手動按停止按鈕。
  Future<void> startListening({
    String localeId = 'zh_TW',
    Duration listenFor = const Duration(seconds: 120),
  }) async {
    await _initializeIfNeeded();

    if (!_isInitialized) {
      onStatus?.call('not_supported');
      return;
    }

    _accumulatedText = '';

    try {
      await _startListeningInternal(localeId: localeId, listenFor: listenFor);
    } catch (e) {
      _logger.e('Error starting listening: $e');
      onStatus?.call('error');
    }
  }

  /// 內部啟動/重啟監聽
  Future<void> _startListeningInternal({
    required String localeId,
    required Duration listenFor,
  }) async {
    await _speechToText.listen(
      onResult: (result) {
        final text = result.recognizedWords;
        final isFinal = result.finalResult;
        // 手動停止模式：累積已確認的片段
        if (isFinal && text.isNotEmpty && manualStopMode) {
          if (_accumulatedText.isNotEmpty) {
            _accumulatedText += '，$text';
          } else {
            _accumulatedText = text;
          }
          debugPrint('🎙️ [累積] $_accumulatedText');
        }
        // 回呼時顯示累積文字 + 當前片段
        final displayText = manualStopMode
            ? (_accumulatedText.isNotEmpty && !isFinal
                ? '$_accumulatedText，$text'
                : (isFinal ? _accumulatedText : text))
            : text;
        onResult?.call(displayText, isFinal);
      },
      localeId: localeId,
      listenFor: listenFor,
      pauseFor: const Duration(seconds: 60), // 設極長，實質不觸發
      listenOptions: stt.SpeechListenOptions(
        partialResults: true,
        cancelOnError: false,
        autoPunctuation: true,
      ),
    );
  }

  /// 語音引擎自動結束後重新啟動（手動停止模式專用）
  Future<void> restartListening({
    String localeId = 'zh_TW',
    Duration listenFor = const Duration(seconds: 120),
  }) async {
    if (!manualStopMode || !_isInitialized) return;
    try {
      // 短暫延遲讓引擎完全停止
      await Future.delayed(const Duration(milliseconds: 300));
      await _startListeningInternal(localeId: localeId, listenFor: listenFor);
      debugPrint('🎙️ [重啟監聽] 繼續累積...');
    } catch (e) {
      _logger.e('Error restarting listening: $e');
    }
  }

  /// 停止監聽（手動）— 回傳累積的完整文字
  Future<String> stopListening() async {
    try {
      await _speechToText.stop();
      // 手動停止模式：回傳累積文字（比 lastRecognizedWords 更完整）
      final result = manualStopMode && _accumulatedText.isNotEmpty
          ? _accumulatedText
          : _speechToText.lastRecognizedWords;
      _accumulatedText = '';
      return result;
    } catch (e) {
      _logger.e('Error stopping: $e');
      return _accumulatedText.isNotEmpty ? _accumulatedText : '';
    }
  }

  /// 取得當前累積文字
  String get accumulatedText => _accumulatedText;

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
