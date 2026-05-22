// Lightweight TTS service wrapper using flutter_tts
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  TtsService._internal();
  static final TtsService instance = TtsService._internal();

  final FlutterTts _tts = FlutterTts();
  bool _initialized = false;
  bool _isSpeaking = false;
  Completer<void>? _activeCompleter;

  Future<void> init() async {
    if (_initialized) return;
    try {
      // Set handlers
      _tts.setStartHandler(() {
        _isSpeaking = true;
      });
      _tts.setCompletionHandler(() {
        _isSpeaking = false;
        _activeCompleter?.complete();
        _activeCompleter = null;
      });
      _tts.setErrorHandler((msg) {
        _isSpeaking = false;
        _activeCompleter?.completeError(Exception(msg));
        _activeCompleter = null;
      });

      // Preferred language: Telugu (India). If unavailable, flutter_tts may fall back.
      try {
        await _tts.setLanguage('te-IN');
      } catch (_) {
        try {
          await _tts.setLanguage('te');
        } catch (_) {
          // ignore: best-effort fallback
        }
      }

      // Friendly defaults
      await _tts.setSpeechRate(0.45);
      await _tts.setPitch(1.0);
    } catch (e) {
      // Do not throw — keep service usable with fallback behaviour
      debugPrint('TtsService.init failed: $e');
    }

    _initialized = true;
  }

  Future<void> speak(String text) async {
    await init();
    if (text.isEmpty) return;

    // If already speaking, stop first
    if (_isSpeaking) {
      try {
        await _tts.stop();
      } catch (_) {}
    }

    _activeCompleter = Completer<void>();
    try {
      final res = await _tts.speak(text);
      // Some platforms return immediately; we wait for completion handler when possible.
      if (res == 1 || res == '1') {
        // wait for completion or timeout
        try {
          await _activeCompleter!.future.timeout(const Duration(seconds: 8));
        } catch (_) {
          // timeout or other error — swallow
        }
      }
    } catch (e) {
      _activeCompleter = null;
      debugPrint('TtsService.speak failed: $e');
    }
  }

  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (_) {}
    _isSpeaking = false;
    _activeCompleter?.complete();
    _activeCompleter = null;
  }
}
