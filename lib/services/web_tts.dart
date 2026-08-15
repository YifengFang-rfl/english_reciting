import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// 浏览器内置 TTS（Web Speech API，Edge / Chrome / Safari 通用）。
/// 完全免费、无需 Key：语音由浏览器/系统提供，Edge 还会附带微软在线神经语音。
///
/// 本文件仅在 Web 平台编译（通过条件导入），非 Web 平台见 [web_tts_stub.dart]。
class WebTts {
  void Function()? onComplete;

  bool _ready = false;

  /// 当前正在播放的本地音频元素（网页端本地 m4a 用原生 HTMLAudioElement 播放，
  /// 绕开 audioplayers 的 AudioContext 路由与乐观返回，失败可回退语音合成）
  web.HTMLAudioElement? _audioEl;

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

  /// 是否存在该语言的 Edge 神经语音（语音名含 Natural/Online，即 Edge 在线语音）。
  /// 用于网页端优先级判断：Edge 神经语音 → 内嵌音频 → 系统语音。
  bool hasEdgeVoice(String lang) {
    try {
      final voices = _synth.getVoices().toDart;
      final langLower = lang.toLowerCase();
      for (final v in voices) {
        final name = v.name.toLowerCase();
        // Edge 在线神经语音均为 Microsoft 出品，且带 Natural/Online 标记
        if (v.lang.toLowerCase().startsWith(langLower) &&
            name.contains('microsoft') &&
            (name.contains('natural') || name.contains('online'))) {
          return true;
        }
      }
    } catch (_) {}
    return false;
  }

  bool _isNatural(web.SpeechSynthesisVoice v) {
    final name = v.name.toLowerCase();
    return name.contains('natural') || name.contains('online');
  }

  /// 选语音：优先带 "Natural/Online" 的自然语音（Edge 在线神经语音音质更好），
  /// 且优先完整语言（如 zh-cn 普通话），其次语言族；都没有则返回 null。
  web.SpeechSynthesisVoice? _pickVoice(String lang) {
    try {
      final voices = _synth.getVoices().toDart;
      if (voices.isEmpty) return null;
      final langLower = lang.toLowerCase(); // 完整语言，如 zh-cn（普通话）
      final family = langLower.split('-').first; // 语言族，如 zh
      // 1) 完整语言的自然/在线神经语音（普通话优先）
      for (final v in voices) {
        if (v.lang.toLowerCase().startsWith(langLower) && _isNatural(v)) {
          return v;
        }
      }
      // 2) 语言族的自然/在线神经语音
      for (final v in voices) {
        if (v.lang.toLowerCase().startsWith(family) && _isNatural(v)) {
          return v;
        }
      }
      // 3) 完整语言的任意语音
      for (final v in voices) {
        if (v.lang.toLowerCase().startsWith(langLower)) return v;
      }
      // 4) 语言族的任意语音
      for (final v in voices) {
        if (v.lang.toLowerCase().startsWith(family)) return v;
      }
    } catch (_) {}
    return null;
  }

  /// 播放本地音频文件（已 resolve 的 assets URL）。
  /// 等待真正开始播放才返回 true；解码失败 / 自动播放被拦截 / 超时返回 false。
  Future<bool> playLocal(String url) async {
    try {
      _stopAudioEl();
      final el = web.HTMLAudioElement();
      _audioEl = el;
      el.preload = 'auto';
      el.crossOrigin = 'anonymous';
      el.src = url;
      el.onended = ((web.Event e) => onComplete?.call()).toJS;

      final completer = Completer<bool>();
      late final void Function(web.Event) onStarted;
      Timer? timer;
      void done(bool ok) {
        el.onplaying = null;
        el.onerror = null;
        timer?.cancel();
        if (!completer.isCompleted) completer.complete(ok);
      }

      onStarted = (_) => done(true);
      el.onplaying = onStarted.toJS;
      el.onerror = ((web.Event e) => done(false)).toJS;
      timer = Timer(const Duration(seconds: 8), () => done(false));

      try {
        await el.play().toDart;
      } catch (_) {
        // play() 被浏览器自动播放策略拒绝 → 回退
        done(false);
      }
      return completer.future;
    } catch (_) {
      return false;
    }
  }

  void _stopAudioEl() {
    final el = _audioEl;
    if (el == null) return;
    el.onended = null;
    el.pause();
    el.src = '';
    el.remove();
    _audioEl = null;
  }

  Future<void> pause() async {
    try {
      _synth.pause();
      _audioEl?.pause();
    } catch (_) {}
  }

  Future<void> stop() async {
    try {
      _synth.cancel();
      _stopAudioEl();
    } catch (_) {}
  }

  void dispose() {
    _ready = false;
    _stopAudioEl();
  }
}
