import 'package:flutter/cupertino.dart';
import '../models/cart.dart';
import '../models/word_pair.dart';
import '../services/cart_service.dart';
import '../services/vocabulary_service.dart';

/// 单元详情页 —— 像点菜一样选词：点单词 = 加入购物车
class UnitDetailScreen extends StatefulWidget {
  final VocabularyService vocab;
  final String book;
  final String unit;
  final CartService cart;

  const UnitDetailScreen({
    super.key,
    required this.vocab,
    required this.book,
    required this.unit,
    required this.cart,
  });

  @override
  State<UnitDetailScreen> createState() => _UnitDetailScreenState();
}

class _UnitDetailScreenState extends State<UnitDetailScreen> {
  late List<WordEntry> _words;

  VocabularyService get _v => widget.vocab;

  @override
  void initState() {
    super.initState();
    _words = _v.wordsOfUnit(widget.book, widget.unit);
  }

  void _refresh() => setState(() {});

  /// 本单元已加入购物车的单词数
  int get _selCount => _words.where((w) => widget.cart.contains(w)).length;

  /// 将本单元所有单词加入购物车
  void _addAllToCart() => widget.cart.addAll(_words, CartSource.textbook);

  /// 将本单元所有单词移出购物车
  void _removeAllFromCart() => widget.cart.removeAll(_words);

  @override
  Widget build(BuildContext context) {
    final allSel = _words.every((w) => widget.cart.contains(w));
    final allCnToEn = _words.every(
      (w) => w.direction == DictateDirection.cnToEn,
    );
    final selCount = _selCount;

    return Column(
      children: [
        // 工具栏
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
          child: Row(
            children: [
              CupertinoButton(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                minimumSize: Size.zero,
                onPressed: () {
                  if (allSel) {
                    _removeAllFromCart();
                  } else {
                    _addAllToCart();
                  }
                  _refresh();
                },
                child: Text(
                  allSel ? '取消全选' : '全选',
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
                onPressed: () {
                  for (final w in _words) {
                    w.direction = allCnToEn
                        ? DictateDirection.enToCn
                        : DictateDirection.cnToEn;
                  }
                  _refresh();
                },
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
              Text(
                '$selCount/${_words.length} 词',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),

        // 单词菜单 —— 点一下就像点菜一样加入购物车
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            itemCount: _words.length,
            itemBuilder: (_, i) {
              final w = _words[i];
              final isCnToEn = w.direction == DictateDirection.cnToEn;
              final inCart = widget.cart.contains(w);

              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  if (inCart) {
                    widget.cart.removeWord(w);
                  } else {
                    widget.cart.add(w, CartSource.textbook);
                  }
                  _refresh();
                },
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
                        // 点菜状态图标：已点 = 对勾，未点 = 加号
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
                              '已点',
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
