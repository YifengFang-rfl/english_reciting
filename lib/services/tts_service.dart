import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_tts/flutter_tts.dart';

import 'web_tts_stub.dart' if (dart.library.js_interop) 'web_tts.dart';

enum TtsState { idle, playing, paused }

/// 跨平台 TTS 服务 —— macOS/iOS 直接用系统语音，Android/Windows 切换语言
class TtsService {
  final FlutterTts _tts = FlutterTts();
  final AudioPlayer _audio = AudioPlayer();
  final WebTts _webTts = WebTts();

  /// 本地音频索引：assets/audio/index.txt 中的文件名（含扩展名）集合
  final Set<String> _audioIndex = {};

  bool _ready = false;
  // macOS/iOS 直接用系统语音，恒为 true；Android 上根据引擎实际支持情况检测
  bool _englishAvailable = true;
  bool _chineseAvailable = true;
  List<String> _availableLanguages = const [];
  TtsState _state = TtsState.idle;

  bool get isReady => _ready;
  bool get englishAvailable => _englishAvailable;
  bool get chineseAvailable => _chineseAvailable;
  List<String> get availableLanguages => _availableLanguages;
  TtsState get state => _state;
  bool get isSpeaking => _state == TtsState.playing;
  bool get isPaused => _state == TtsState.paused;
  bool get isIdle => _state == TtsState.idle;

  VoidCallback? onComplete;

  /// 朗读因设备缺少相应语言语音而失败时触发（Android）
  VoidCallback? onUnavailable;

  /// macOS/iOS 直接用系统语音，无需手动切换语言
  bool get _isAppleDesktop =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.macOS ||
          defaultTargetPlatform == TargetPlatform.iOS);

  /// flutter_tts 不支持 web，网页版仅依赖本地音频
  bool get _ttsSupported => !kIsWeb;

  /// 移动端浏览器（手机/平板）：Edge 在线神经语音仅桌面浏览器可用，需跳过
  bool get _isMobileWeb =>
      kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.android);

  Future<void> init() async {
    try {
      _tts.setCompletionHandler(() {
        // stop() 会先把 _state 置为 idle，此处拦截避免 stop 误触发 onComplete
        if (_state != TtsState.playing) return;
        _state = TtsState.idle;
        onComplete?.call();
      });
      _tts.setErrorHandler((msg) {
        debugPrint('[TtsService] error: $msg');
        _state = TtsState.idle;
      });
      // 本地音频完成回调（仅在播放中触发，避免 stop() 误触发）
      _audio.onPlayerComplete.listen((_) {
        if (_state != TtsState.playing) return;
        _state = TtsState.idle;
        onComplete?.call();
      });
      // 浏览器 TTS 完成回调
      _webTts.onComplete = () {
        // stop() 会先把 _state 置为 idle，此处拦截避免 stop 误触发 onComplete
        if (_state != TtsState.playing) return;
        _state = TtsState.idle;
        onComplete?.call();
      };
      if (kIsWeb) {
        await _webTts.init();
      }
      await _loadAudioIndex();
      await _tts.setPitch(1.0);
      await _tts.setSpeechRate(0.5);
      await _tts.setVolume(1.0);
      if (!_isAppleDesktop && _ttsSupported) {
        await _initAndroid();
      }
      debugPrint(
        '[TtsService] ready on ${kIsWeb ? 'web' : defaultTargetPlatform.name}',
      );
    } catch (e) {
      debugPrint('[TtsService] init error: $e');
    }
    _ready = true;
  }

  /// 加载本地音频索引（不存在则静默跳过，全部走 TTS 回退）
  Future<void> _loadAudioIndex() async {
    try {
      final txt = await rootBundle.loadString('assets/audio/index.txt');
      for (final line in txt.split('\n')) {
        final f = line.trim();
        if (f.isNotEmpty) _audioIndex.add(f);
      }
      debugPrint('[TtsService] 本地音频索引: ${_audioIndex.length} 个');
    } catch (e) {
      debugPrint('[TtsService] 未找到本地音频索引，回退 TTS: $e');
    }
  }

  /// 文件名安全化，与 tool/synthesize_audio.py 保持一致
  String _sanitize(String w) {
    var s = w.replaceAll(RegExp(r"[^A-Za-z0-9'\-]+"), '_');
    s = s.replaceAll(RegExp(r'^_+|_+$'), '');
    return s.isEmpty ? 'word' : s;
  }

  /// 尝试播放指定文件名的本地音频；找不到则返回 false
  Future<bool> _playLocalAudioFile(String fname) async {
    if (!_audioIndex.contains(fname)) return false;
    if (kIsWeb) {
      // 网页版：用原生 HTMLAudioElement 播放本地 m4a，
      // 等待真正开始播放；失败则回退浏览器语音合成
      try {
        final url = await AudioCache.instance.loadPath('audio/$fname');
        _state = TtsState.playing;
        final ok = await _webTts.playLocal(url);
        if (!ok) _state = TtsState.idle;
        return ok;
      } catch (e) {
        debugPrint('[TtsService] 网页本地音频失败: $e');
        _state = TtsState.idle;
        return false;
      }
    }
    try {
      await _tts.stop();
      await _audio.stop();
      await _audio.play(AssetSource('audio/$fname'));
      _state = TtsState.playing;
      return true;
    } catch (e) {
      debugPrint('[TtsService] 本地音频播放失败: $e');
      _state = TtsState.idle;
      return false;
    }
  }

  /// Android：探测引擎支持的语音包，避免朗读静默失败
  Future<void> _initAndroid() async {
    try {
      final langs = await _tts.getLanguages;
      if (langs is List) {
        _availableLanguages = langs.cast<String>();
      }
    } catch (_) {}
    try {
      _englishAvailable = await _tts.isLanguageAvailable('en-US') == true;
    } catch (_) {}
    try {
      _chineseAvailable = await _tts.isLanguageAvailable('zh-CN') == true;
    } catch (_) {}
    // 若英文可用则设为当前语言
    if (_englishAvailable) {
      try {
        await _tts.setLanguage('en-US');
      } catch (_) {}
    }
    debugPrint(
      '[TtsService] android langs=$_availableLanguages '
      'en=$_englishAvailable zh=$_chineseAvailable',
    );
  }

  /// 返回是否成功发起朗读。优先使用本地音频，缺失时回退 TTS。
  /// Android 上两者都不可用时返回 false 并触发 [onUnavailable]。
  Future<bool> speakEnglish(String text) async {
    if (!_ready) return false;
    // 网页端优先级：自然语音(Edge/Chrome 在线) → 内嵌音频 → 系统语音
    if (kIsWeb) {
      if (!_isMobileWeb && _webTts.hasNaturalVoice('en-US')) {
        _state = TtsState.playing;
        final ok = await _webTts.speakEnglish(text);
        if (!ok) _state = TtsState.idle;
        return ok;
      }
      // 内嵌音频（不依赖设备 TTS 引擎）
      if (await _playLocalAudioFile('${_sanitize(text)}.m4a')) return true;
      // 系统语音回退
      _state = TtsState.playing;
      final ok = await _webTts.speakEnglish(text);
      if (!ok) _state = TtsState.idle;
      return ok;
    }
    // 1) 优先本地音频（不依赖设备 TTS 引擎）
    if (await _playLocalAudioFile('${_sanitize(text)}.m4a')) return true;
    // 2) 回退 TTS（web 不支持 flutter_tts）
    if (!_ttsSupported) return false;
    if (!_isAppleDesktop && !_englishAvailable) {
      _state = TtsState.idle;
      onUnavailable?.call();
      return false;
    }
    try {
      if (!_isAppleDesktop) {
        await _tts.setLanguage('en-US');
      }
      await _tts.setPitch(1.0);
      await _tts.setSpeechRate(0.40);
      _state = TtsState.playing;
      await _tts.speak(text);
      return true;
    } catch (e) {
      debugPrint('[TtsService] speakEnglish error: $e');
      _state = TtsState.idle;
      return false;
    }
  }

  /// 返回是否成功发起朗读。优先使用本地中文音频，缺失时回退 TTS。
  /// [english] 用于定位对应单词的中文音频（<英文名>_cn.m4a）。
  Future<bool> speakChinese(String text, {String? english}) async {
    if (!_ready) return false;
    // 归一化中文文本：去掉词性前缀、竖线，确保朗读干净的普通话
    final t = _normalizeChinese(text);
    // 网页端优先级：自然语音(普通话) → 内嵌中文音频 → 系统语音
    if (kIsWeb) {
      if (!_isMobileWeb && _webTts.hasNaturalVoice('zh-CN')) {
        _state = TtsState.playing;
        final ok = await _webTts.speakChinese(t);
        if (!ok) _state = TtsState.idle;
        return ok;
      }
      // 内嵌中文音频
      if (english != null && english.isNotEmpty) {
        if (await _playLocalAudioFile('${_sanitize(english)}_cn.m4a')) {
          return true;
        }
      }
      // 系统语音回退
      _state = TtsState.playing;
      final ok = await _webTts.speakChinese(t);
      if (!ok) _state = TtsState.idle;
      return ok;
    }
    // 1) 优先本地中文音频（不依赖设备 TTS 引擎）
    if (english != null && english.isNotEmpty) {
      if (await _playLocalAudioFile('${_sanitize(english)}_cn.m4a')) {
        return true;
      }
    }
    // 2) 回退 TTS（web 不支持 flutter_tts）
    if (!_ttsSupported) return false;
    if (!_isAppleDesktop && !_chineseAvailable) {
      _state = TtsState.idle;
      onUnavailable?.call();
      return false;
    }
    try {
      if (!_isAppleDesktop) {
        await _tts.setLanguage('zh-CN');
      }
      await _tts.setPitch(1.05);
      await _tts.setSpeechRate(0.48);
      _state = TtsState.playing;
      await _tts.speak(t);
      return true;
    } catch (e) {
      debugPrint('[TtsService] speakChinese error: $e');
      _state = TtsState.idle;
      return false;
    }
  }

  /// 中文朗读文本归一化：去掉词性前缀（如 "n."）、竖线分隔、多余空白
  String _normalizeChinese(String text) {
    var t = text.replaceAll(RegExp(r'[a-zA-Z]+\.\s*'), '');
    t = t.replaceAll('|', ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
    return t.isEmpty ? text : t;
  }

  Future<void> pause() async {
    if (_state != TtsState.playing) return;
    try {
      if (kIsWeb) {
        await _webTts.pause();
      } else {
        await _tts.pause();
      }
      await _audio.pause();
      _state = TtsState.paused;
    } catch (_) {}
  }

  Future<void> stop() async {
    try {
      _state = TtsState.idle;
      if (kIsWeb) {
        await _webTts.stop();
      } else {
        await _tts.stop();
      }
      await _audio.stop();
    } catch (_) {}
  }

  void dispose() {
    _tts.stop();
    _audio.stop();
    _webTts.dispose();
    _ready = false;
  }
}
