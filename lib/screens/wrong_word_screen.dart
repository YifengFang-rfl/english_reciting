import 'package:flutter/cupertino.dart';
import '../models/cart.dart';
import '../services/cart_service.dart';
import '../services/wrong_word_service.dart';
import '../services/tts_service.dart';
import '../screens/player_screen.dart';

/// 错词本页面 —— 查看/管理错词，可加入购物车、批量移除或重新默写
class WrongWordScreen extends StatefulWidget {
  final WrongWordService wrongWordService;
  final CartService cart;
  final TtsService tts;

  const WrongWordScreen({
    super.key,
    required this.wrongWordService,
    required this.cart,
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
                  widget.cart.addAll(words, CartSource.wrongWord);
                  _refresh();
                },
                child: const Text(
                  '全部加购',
                  style: TextStyle(
                    fontSize: 14,
                    color: CupertinoColors.activeBlue,
                  ),
                ),
              ),
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
                      // 加入购物车 / 已加入
                      CupertinoButton(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        minimumSize: Size.zero,
                        color: widget.cart.contains(w)
                            ? CupertinoColors.activeBlue.withAlpha(40)
                            : null,
                        borderRadius: BorderRadius.circular(6),
                        onPressed: () {
                          if (widget.cart.contains(w)) {
                            widget.cart.removeWord(w);
                          } else {
                            widget.cart.add(w, CartSource.wrongWord);
                          }
                          _refresh();
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              widget.cart.contains(w)
                                  ? CupertinoIcons.checkmark_circle_fill
                                  : CupertinoIcons.plus_circle,
                              size: 16,
                              color: widget.cart.contains(w)
                                  ? CupertinoColors.activeBlue
                                  : CupertinoColors.systemGrey3,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              widget.cart.contains(w) ? '已加购' : '加购',
                              style: TextStyle(
                                fontSize: 12,
                                color: widget.cart.contains(w)
                                    ? CupertinoColors.activeBlue
                                    : CupertinoColors.systemGrey,
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
