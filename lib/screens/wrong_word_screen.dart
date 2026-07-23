import 'package:flutter/cupertino.dart';
import '../services/wrong_word_service.dart';
import '../services/tts_service.dart';
import '../screens/player_screen.dart';

/// 错词本页面 —— 查看/管理错词，可批量移除或重新默写
class WrongWordScreen extends StatefulWidget {
  final WrongWordService wrongWordService;
  final TtsService tts;

  const WrongWordScreen({
    super.key,
    required this.wrongWordService,
    required this.tts,
  });

  @override
  State<WrongWordScreen> createState() => _WrongWordScreenState();
}

class _WrongWordScreenState extends State<WrongWordScreen> {
  void _refresh() => setState(() {});

  void _startDictation() {
    if (widget.wrongWordService.isEmpty) return;
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (_) => CupertinoPageScaffold(
          navigationBar: const CupertinoNavigationBar(middle: Text('错词默写')),
          child: SafeArea(
            child: PlayerScreen(
              words: widget.wrongWordService.words.toList(),
              tts: widget.tts,
              onExit: () => Navigator.pop(context),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final words = widget.wrongWordService.words;

    if (words.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              CupertinoIcons.tray,
              size: 48,
              color: CupertinoColors.systemGrey3,
            ),
            SizedBox(height: 12),
            Text(
              '错词本为空',
              style: TextStyle(
                fontSize: 16,
                color: CupertinoColors.secondaryLabel,
              ),
            ),
            SizedBox(height: 4),
            Text(
              '默写完成后可将错词加入本子',
              style: TextStyle(
                fontSize: 13,
                color: CupertinoColors.tertiaryLabel,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // 工具栏
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
          child: Row(
            children: [
              Text(
                '共 ${words.length} 词',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              CupertinoButton(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                minimumSize: Size.zero,
                onPressed: () {
                  widget.wrongWordService.clear();
                  _refresh();
                },
                child: const Text(
                  '清空',
                  style: TextStyle(
                    fontSize: 14,
                    color: CupertinoColors.destructiveRed,
                  ),
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: words.length,
            itemBuilder: (_, i) {
              final w = words[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: CupertinoColors.secondarySystemBackground
                        .resolveFrom(context),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              w.english,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              w.chinese,
                              style: const TextStyle(
                                fontSize: 12,
                                color: CupertinoColors.secondaryLabel,
                              ),
                            ),
                          ],
                        ),
                      ),
                      CupertinoButton(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        minimumSize: Size.zero,
                        onPressed: () {
                          widget.wrongWordService.remove(w);
                          _refresh();
                        },
                        child: const Icon(
                          CupertinoIcons.delete,
                          size: 18,
                          color: CupertinoColors.systemGrey3,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        Padding(
          padding: const EdgeInsets.all(16),
          child: CupertinoButton.filled(
            onPressed: _startDictation,
            child: Text('重新默写（${words.length} 词）'),
          ),
        ),
      ],
    );
  }
}
