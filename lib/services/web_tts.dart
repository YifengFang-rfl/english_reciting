import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// 浏览器内置 TTS（Web Speech API，Edge / Chrome / Safari 通用）。
/// 完全免费、无需 Key：语音由浏览器/系统提供，Edge 还会附带微软在线神经语音。
///
/// 本文件仅在 Web 平台编译（通过条件导入），非 Web 平台见 [web_tts_stub.dart]。
class WebTts {
  void Function()? onComplete;

  bool _ready = false;

  bool get isSupported => true;

  web.SpeechSynthesis get _synth => web.window.speechSynthesis;

  Future<bool> init() async {
    try {
      // 部分浏览器首次 getVoices() 返回空列表，需等 voiceschanged 后再取一次
      _synth.getVoices();
      _synth.onvoiceschanged = ((web.Event e) => _synth.getVoices()).toJS;
    } catch (_) {}
    _ready = true;
    return true;
  }

  Future<bool> speakEnglish(String text) =>
      _speak(text, lang: 'en-US', rate: 0.9, pitch: 1.0);

  Future<bool> speakChinese(String text) =>
      _speak(text, lang: 'zh-CN', rate: 0.9, pitch: 1.05);

  Future<bool> _speak(
    String text, {
    required String lang,
    required double rate,
    required double pitch,
  }) async {
    if (!_ready || text.trim().isEmpty) return false;
    try {
      _synth.cancel();
      final u = web.SpeechSynthesisUtterance(text);
      u.lang = lang;
      u.rate = rate;
      u.pitch = pitch;
      u.volume = 1.0;
      final voice = _pickVoice(lang);
      if (voice != null) u.voice = voice;
      u.onend = ((web.Event e) => onComplete?.call()).toJS;
      u.onerror = ((web.Event e) => onComplete?.call()).toJS;
      _synth.speak(u);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// 选语音：优先带 "Natural/Online" 的自然语音（Edge 在线神经语音音质更好），
  /// 否则按语言前缀取浏览器默认语音。
  web.SpeechSynthesisVoice? _pickVoice(String lang) {
    try {
      final voices = _synth.getVoices().toDart;
      if (voices.isEmpty) return null;
      final prefix = lang.split('-').first.toLowerCase();
      for (final v in voices) {
        final vl = v.lang.toLowerCase();
        final name = v.name.toLowerCase();
        if (vl.startsWith(prefix) &&
            (name.contains('natural') || name.contains('online'))) {
          return v;
        }
      }
      for (final v in voices) {
        if (v.lang.toLowerCase().startsWith(prefix)) return v;
      }
    } catch (_) {}
    return null;
  }

  Future<void> pause() async {
    try {
      _synth.pause();
    } catch (_) {}
  }

  Future<void> stop() async {
    try {
      _synth.cancel();
    } catch (_) {}
  }

  void dispose() {
    _ready = false;
  }
}
