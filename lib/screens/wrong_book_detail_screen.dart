import 'package:flutter/cupertino.dart';
import '../models/cart.dart';
import '../models/word_pair.dart';
import '../services/cart_service.dart';
import '../services/wrong_word_service.dart';

/// 单个错词本详情 —— 样式与内置课本一致：点单词加入默写单词表，长按删除
class WrongBookDetailScreen extends StatefulWidget {
  final WrongWordService wrongWordService;
  final CartService cart;
  final String bookName;

  const WrongBookDetailScreen({
    super.key,
    required this.wrongWordService,
    required this.cart,
    required this.bookName,
  });

  @override
  State<WrongBookDetailScreen> createState() => _WrongBookDetailScreenState();
}

class _WrongBookDetailScreenState extends State<WrongBookDetailScreen> {
  void _refresh() => setState(() {});

  void _toggleCart(WordEntry w) {
    if (widget.cart.contains(w)) {
      widget.cart.removeWord(w);
    } else {
      widget.cart.add(w, CartSource.wrongWord);
    }
    _refresh();
  }

  /// 全选 / 取消
  void _toggleAll(List<WordEntry> words) {
    if (words.every(widget.cart.contains)) {
      widget.cart.removeAll(words);
    } else {
      widget.cart.addAll(words, CartSource.wrongWord);
    }
    _refresh();
  }

  /// 切换所有错词的默写方向
  void _toggleAllDirection(List<WordEntry> words, bool allCnToEn) {
    for (final w in words) {
      w.direction = allCnToEn
          ? DictateDirection.enToCn
          : DictateDirection.cnToEn;
    }
    _refresh();
  }

  /// 长按删除错词（带确认）
  Future<void> _confirmDelete(WordEntry w) async {
    final ok = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('删除错词'),
        content: Text('确定要从「${widget.bookName}」删除 ${w.english} 吗？'),
        actions: [
          CupertinoDialogAction(
            child: const Text('取消'),
            onPressed: () => Navigator.pop(ctx, false),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('删除'),
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );
    if (ok == true) {
      widget.cart.removeWord(w);
      widget.wrongWordService.removeFrom(widget.bookName, w);
      _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final words = widget.wrongWordService.wordsOf(widget.bookName);

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
              '该错词本为空',
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

    final selCount = words.where(widget.cart.contains).length;
    final allSel = words.every(widget.cart.contains);
    final allCnToEn = words.every(
      (w) => w.direction == DictateDirection.cnToEn,
    );

    return Column(
      children: [
        // 工具栏（与内置课本一致）
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
          child: Row(
            children: [
              CupertinoButton(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                minimumSize: Size.zero,
                onPressed: () => _toggleAll(words),
                child: Text(
                  allSel ? '取消' : '全选',
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 1,
                height: 18,
                color: CupertinoColors.systemGrey4,
              ),
              const SizedBox(width: 12),
              CupertinoButton(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                minimumSize: Size.zero,
                onPressed: () => _toggleAllDirection(words, allCnToEn),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      CupertinoIcons.arrow_2_squarepath,
                      size: 14,
                      color: CupertinoColors.activeBlue,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      allCnToEn ? '全部默中文' : '全部默英文',
                      style: const TextStyle(
                        fontSize: 14,
                        color: CupertinoColors.activeBlue,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              CupertinoButton(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                minimumSize: Size.zero,
                onPressed: () {
                  widget.wrongWordService.clearBook(widget.bookName);
                  _refresh();
                },
                child: const Text(
                  '清空',
                  style: TextStyle(
                    fontSize: 13,
                    color: CupertinoColors.destructiveRed,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '$selCount/${words.length} 词',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),

        // 编辑提示
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 2),
          child: Row(
            children: [
              const Icon(
                CupertinoIcons.info_circle,
                size: 14,
                color: CupertinoColors.secondaryLabel,
              ),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  '点单词加入默写单词表，长按删除',
                  style: TextStyle(
                    fontSize: 12,
                    color: CupertinoColors.secondaryLabel,
                  ),
                ),
              ),
            ],
          ),
        ),

        // 单词列表（与内置课本一致）
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            itemCount: words.length,
            itemBuilder: (_, i) {
              final w = words[i];
              final isCnToEn = w.direction == DictateDirection.cnToEn;
              final inCart = widget.cart.contains(w);

              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _toggleCart(w),
                onLongPress: () => _confirmDelete(w),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: inCart
                          ? CupertinoColors.activeBlue.withAlpha(14)
                          : CupertinoColors.secondarySystemBackground
                                .resolveFrom(context),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: inCart
                            ? CupertinoColors.activeBlue.withAlpha(90)
                            : CupertinoColors.systemGrey5,
                        width: inCart ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        // 点菜状态图标：已选 = 对勾，未选 = 加号
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 180),
                          transitionBuilder: (child, anim) =>
                              ScaleTransition(scale: anim, child: child),
                          child: Icon(
                            inCart
                                ? CupertinoIcons.checkmark_circle_fill
                                : CupertinoIcons.plus_circle,
                            key: ValueKey<bool>(inCart),
                            size: 22,
                            color: inCart
                                ? CupertinoColors.activeBlue
                                : CupertinoColors.systemGrey4,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                w.english,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: inCart
                                      ? null
                                      : CupertinoColors.systemGrey,
                                ),
                              ),
                              Text(
                                w.chinese,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: inCart
                                      ? CupertinoColors.secondaryLabel
                                      : CupertinoColors.systemGrey3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (inCart)
                          Container(
                            margin: const EdgeInsets.only(right: 6),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: CupertinoColors.activeBlue,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              '已选',
                              style: TextStyle(
                                fontSize: 11,
                                color: CupertinoColors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        CupertinoButton(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          minimumSize: Size.zero,
                          color: isCnToEn
                              ? CupertinoColors.activeOrange.withAlpha(40)
                              : CupertinoColors.activeBlue.withAlpha(40),
                          borderRadius: BorderRadius.circular(6),
                          onPressed: () {
                            w.direction = isCnToEn
                                ? DictateDirection.enToCn
                                : DictateDirection.cnToEn;
                            _refresh();
                          },
                          child: Text(
                            isCnToEn ? '默英文' : '默中文',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isCnToEn
                                  ? CupertinoColors.activeOrange
                                  : CupertinoColors.activeBlue,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
