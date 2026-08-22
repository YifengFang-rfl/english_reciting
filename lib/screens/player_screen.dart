import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../models/word_pair.dart';
import '../services/tts_service.dart';

/// 默写播放器 —— TTS 朗读单词，每词两遍，可配置停顿
class PlayerScreen extends StatefulWidget {
  final List<WordEntry> words;
  final TtsService tts;
  final VoidCallback onExit;
  final VoidCallback? onComplete;

  const PlayerScreen({
    super.key,
    required this.words,
    required this.tts,
    required this.onExit,
    this.onComplete,
  });

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  int _index = 0;
  int _repeat = 0; // 0 = 第一遍, 1 = 第二遍
  bool _playing = true;
  bool _paused = false;
  bool _isSpeaking = false;
  bool _revealed = false; // 是否亮出单词
  double _pauseSeconds = 8.0;
  Timer? _pauseTimer;
  int _pauseRemaining = 0;
  bool _ttsAlertShown = false;

  WordEntry get _currentWord => widget.words[_index];
  bool get _isLast => _index >= widget.words.length - 1;

  @override
  void initState() {
    super.initState();
    widget.tts.onComplete = () {
      if (!mounted) return;
      if (_repeat == 0) {
        // 第一遍读完 → 立即开始第二遍
        setState(() {
          _repeat = 1;
          _isSpeaking = false;
        });
        _speak();
      } else {
        // 第二遍读完 → 开始停顿
        setState(() {
          _isSpeaking = false;
        });
        _startPause();
      }
    };
    WidgetsBinding.instance.addPostFrameCallback((_) => _speak());
    _acquireWakelock();
  }

  @override
  void dispose() {
    _pauseTimer?.cancel();
    widget.tts.stop();
    _releaseWakelock();
    super.dispose();
  }

  /// 默写期间保持屏幕常亮，避免熄屏后 TTS 停止播报
  Future<void> _acquireWakelock() async {
    try {
      await WakelockPlus.enable();
    } catch (e) {
      debugPrint('[wakelock] enable failed: $e');
    }
  }

  void _releaseWakelock() {
    WakelockPlus.disable().catchError((_) {});
  }

  Future<void> _speak() async {
    if (!_playing || _paused) return;
    setState(() => _isSpeaking = true);
    final w = _currentWord;
    final ok = w.direction == DictateDirection.cnToEn
        ? await widget.tts.speakChinese(w.chinese, english: w.english)
        : await widget.tts.speakEnglish(w.english);
    if (!ok && mounted) {
      setState(() => _isSpeaking = false);
      _showTtsUnavailable();
    }
  }

  /// Android 上缺少对应语音包（无法朗读）时，提示用户如何修复
  void _showTtsUnavailable() {
    if (!mounted || _ttsAlertShown) return;
    _ttsAlertShown = true;
    showCupertinoDialog<void>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('无法朗读单词'),
        content: const Text(
          '当前设备缺少可用的语音引擎或语音包，导致无法朗读。\n\n'
          '请检查：\n'
          '① 打开 系统设置 → 辅助功能 → 文本转语音(TTS)\n'
          '② 确认已启用语音引擎，并已安装英文语音包\n'
          '③ 若内置引擎没有英文语音，可安装「讯飞语音」或「Google 文字转语音」，设为默认引擎\n'
          '④ 设置完成后点「重试」',
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () {
              Navigator.of(ctx).pop();
              _ttsAlertShown = false;
              if (_playing && !_paused) _speak();
            },
            child: const Text('重试'),
          ),
        ],
      ),
    );
  }

  void _startPause() {
    _pauseRemaining = _pauseSeconds.toInt();
    _tick();
    _pauseTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted || !_playing) {
        t.cancel();
        return;
      }
      if (_paused) return;
      _pauseRemaining--;
      _tick();
      if (_pauseRemaining <= 0) {
        t.cancel();
        _nextWord();
      }
    });
  }

  void _tick() => setState(() {});

  void _nextWord() {
    _pauseTimer?.cancel();
    if (_isLast) {
      setState(() => _playing = false);
      return;
    }
    setState(() {
      _index++;
      _repeat = 0;
      _pauseRemaining = 0;
      _revealed = false;
    });
    _speak();
  }

  void _togglePause() {
    setState(() {
      _paused = !_paused;
      if (_paused) {
        widget.tts.stop();
        _isSpeaking = false;
      } else {
        if (_isSpeaking) {
          _speak();
        }
        // 如果在停顿中被恢复，Timer 会自然继续
      }
    });
  }

  void _setPause(double v) {
    _pauseSeconds = v;
    if (_pauseRemaining > 0) {
      _pauseRemaining = v.toInt();
    }
    _refresh();
  }

  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    if (!_playing &&
        _index >= widget.words.length - 1 &&
        _pauseRemaining <= 0 &&
        !_isSpeaking) {
      return _buildCompleteView();
    }

    final w = _currentWord;
    final isCnToEn = w.direction == DictateDirection.cnToEn;
    final progress = (_index + (_repeat > 0 ? 0.5 : 0)) / widget.words.length;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 退出按钮
          Row(
            children: [
              CupertinoButton(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                onPressed: () {
                  _pauseTimer?.cancel();
                  widget.tts.stop();
                  widget.onExit();
                },
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      CupertinoIcons.chevron_back,
                      size: 18,
                      color: CupertinoColors.activeBlue,
                    ),
                    SizedBox(width: 2),
                    Text(
                      '退出',
                      style: TextStyle(
                        fontSize: 14,
                        color: CupertinoColors.activeBlue,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // 进度条
          _ProgressBar(progress: progress),
          const SizedBox(height: 24),

          // 当前单词卡片
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: CupertinoColors.secondarySystemBackground.resolveFrom(
                context,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                // 方向标签
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isCnToEn
                            ? CupertinoColors.activeOrange.withAlpha(30)
                            : CupertinoColors.activeBlue.withAlpha(30),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isCnToEn ? '报中文' : '报英文',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isCnToEn
                              ? CupertinoColors.activeOrange
                              : CupertinoColors.activeBlue,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 单词内容区 —— 固定高度避免切换时卡片跳动
                SizedBox(
                  height: 100,
                  child: _revealed
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              w.english,
                              style: const TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              w.chinese,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 14,
                                color: CupertinoColors.secondaryLabel,
                              ),
                            ),
                          ],
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              CupertinoIcons.eye_slash_fill,
                              size: 40,
                              color: CupertinoColors.systemGrey3,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              '单词已隐藏',
                              style: TextStyle(
                                fontSize: 16,
                                color: CupertinoColors.systemGrey3,
                              ),
                            ),
                          ],
                        ),
                ),

                const SizedBox(height: 14),

                // 亮出/隐藏按钮
                CupertinoButton(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  color: _revealed
                      ? CupertinoColors.systemGrey4
                      : CupertinoColors.activeBlue,
                  borderRadius: BorderRadius.circular(10),
                  onPressed: () => setState(() => _revealed = !_revealed),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _revealed
                            ? CupertinoIcons.eye_slash
                            : CupertinoIcons.eye,
                        size: 18,
                        color: _revealed
                            ? CupertinoColors.darkBackgroundGray
                            : CupertinoColors.white,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _revealed ? '隐藏' : '亮出单词',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: _revealed
                              ? CupertinoColors.darkBackgroundGray
                              : CupertinoColors.white,
                        ),
                      ),
                    ],
                  ),
                ),

                if (_isSpeaking || _pauseRemaining > 0) ...[
                  const SizedBox(height: 10),
                  if (_isSpeaking)
                    Column(
                      children: [
                        const CupertinoActivityIndicator(radius: 14),
                        const SizedBox(height: 8),
                        Text(
                          '朗读中 · 第${_repeat + 1}遍',
                          style: const TextStyle(
                            fontSize: 14,
                            color: CupertinoColors.secondaryLabel,
                          ),
                        ),
                      ],
                    )
                  else
                    Text(
                      '停顿 ${_pauseRemaining}s …',
                      style: const TextStyle(
                        fontSize: 16,
                        color: CupertinoColors.systemGrey,
                      ),
                    ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 进度信息（左对齐）
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '${_index + 1} / ${widget.words.length}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
          ),

          const Spacer(),

          // 停顿时间设置
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('停顿：', style: TextStyle(fontSize: 14)),
              CupertinoSegmentedControl<double>(
                groupValue: _pauseSeconds,
                onValueChanged: _setPause,
                children: {
                  3.0: const Text('3s', style: TextStyle(fontSize: 12)),
                  5.0: const Text('5s', style: TextStyle(fontSize: 12)),
                  8.0: const Text('8s', style: TextStyle(fontSize: 12)),
                  10.0: const Text('10s', style: TextStyle(fontSize: 12)),
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 控制按钮
          Center(
            child: CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 12),
              color: _paused
                  ? CupertinoColors.activeBlue
                  : CupertinoColors.destructiveRed,
              borderRadius: BorderRadius.circular(10),
              onPressed: _togglePause,
              child: Text(
                _paused ? '继续' : '暂停',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: CupertinoColors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompleteView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              CupertinoIcons.checkmark_seal_fill,
              size: 64,
              color: Color(0xFF34C759),
            ),
            const SizedBox(height: 16),
            const Text(
              '默写完成！',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '共 ${widget.words.length} 个单词',
              style: const TextStyle(
                fontSize: 14,
                color: CupertinoColors.secondaryLabel,
              ),
            ),
            const SizedBox(height: 32),
            CupertinoButton.filled(
              onPressed: () => widget.onComplete?.call(),
              child: const Text('查看单词列表'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final double progress;
  const _ProgressBar({required this.progress});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 6,
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey4,
        borderRadius: BorderRadius.circular(3),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: progress.clamp(0.0, 1.0),
        child: Container(
          decoration: BoxDecoration(
            color: CupertinoColors.activeBlue,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ),
    );
  }
}
