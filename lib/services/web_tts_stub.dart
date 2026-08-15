/// 非 Web 平台的 [WebTts] 占位实现（条件导入的回退分支）。
///
/// 与 lib/services/web_tts.dart 保持相同接口；在 Android/iOS/macOS/Windows 上
/// 不引入 package:web，直接返回不支持。
class WebTts {
  void Function()? onComplete;

  bool get isSupported => false;

  Future<bool> init() async => false;

  Future<bool> speakEnglish(String text) async => false;

  Future<bool> speakChinese(String text) async => false;

  Future<void> pause() async {}

  Future<void> stop() async {}

  void dispose() {}
}
