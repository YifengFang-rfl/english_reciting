import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

enum TtsState { idle, playing, paused }

/// 跨平台 TTS 服务 —— macOS/iOS 直接用系统语音，Android/Windows 切换语言
class TtsService {
  final FlutterTts _tts = FlutterTts();

  bool _ready = false;
  TtsState _state = TtsState.idle;

  bool get isReady => _ready;
  TtsState get state => _state;
  bool get isSpeaking => _state == TtsState.playing;
  bool get isPaused => _state == TtsState.paused;
  bool get isIdle => _state == TtsState.idle;

  VoidCallback? onComplete;

  Future<void> init() async {
    try {
      _tts.setCompletionHandler(() {
        _state = TtsState.idle;
        onComplete?.call();
      });
      _tts.setErrorHandler((msg) {
        debugPrint('[TtsService] error: $msg');
        _state = TtsState.idle;
      });
      await _tts.setPitch(1.0);
      await _tts.setSpeechRate(0.5);
      await _tts.setVolume(1.0);
      if (!Platform.isMacOS && !Platform.isIOS) {
        await _tts.setLanguage('en-US');
      }
      debugPrint('[TtsService] ready on ${Platform.operatingSystem}');
    } catch (e) {
      debugPrint('[TtsService] init error: $e');
    }
    _ready = true;
  }

  Future<void> speakEnglish(String text) async {
    if (!_ready) return;
    try {
      if (!Platform.isMacOS && !Platform.isIOS) {
        await _tts.setLanguage('en-US');
      }
      await _tts.setPitch(1.0);
      await _tts.setSpeechRate(0.40);
      _state = TtsState.playing;
      await _tts.speak(text);
    } catch (e) {
      debugPrint('[TtsService] speakEnglish error: $e');
      _state = TtsState.idle;
    }
  }

  Future<void> speakChinese(String text) async {
    if (!_ready) return;
    var t = text.replaceAll(RegExp(r'[a-zA-Z]+\.\s*'), '');
    t = t.replaceAll('|', ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
    if (t.isEmpty) t = text;
    try {
      if (!Platform.isMacOS && !Platform.isIOS) {
        await _tts.setLanguage('zh-CN');
      }
      await _tts.setPitch(1.05);
      await _tts.setSpeechRate(0.48);
      _state = TtsState.playing;
      await _tts.speak(t);
    } catch (e) {
      debugPrint('[TtsService] speakChinese error: $e');
      _state = TtsState.idle;
    }
  }

  Future<void> pause() async {
    if (_state != TtsState.playing) return;
    try {
      await _tts.pause();
      _state = TtsState.paused;
    } catch (_) {}
  }

  Future<void> stop() async {
    try {
      _state = TtsState.idle;
      await _tts.stop();
    } catch (_) {}
  }

  void dispose() {
    _tts.stop();
    _ready = false;
  }
}
