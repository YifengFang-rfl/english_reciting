import 'package:flutter/cupertino.dart';

import '../models/cart.dart';
import '../models/word_pair.dart';
import '../services/cart_service.dart';
import '../services/custom_dict_service.dart';
import '../utils/custom_dict_import.dart';

/// 自定义词典详情页 —— 查看/编辑某个词表的单词，可加购到购物车
class CustomDictDetailScreen extends StatefulWidget {
  final CustomDictService service;
  final CartService cart;
  final String dictName;

  const CustomDictDetailScreen({
    super.key,
    required this.service,
    required this.cart,
    required this.dictName,
  });

  @override
  State<CustomDictDetailScreen> createState() => _CustomDictDetailScreenState();
}

class _CustomDictDetailScreenState extends State<CustomDictDetailScreen> {
  /// 批量添加单词（每行：英文,中文释义）
  Future<void> _addWord() async {
    final wordsCtrl = TextEditingController();
    final text = await showCupertinoDialog<String>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('添加单词'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '每行一个：英文,中文释义',
                style: TextStyle(
                  fontSize: 12,
                  color: CupertinoColors.secondaryLabel,
                ),
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: 270,
              height: 180,
              child: CupertinoTextField(
                controller: wordsCtrl,
                maxLines: 8,
                textAlignVertical: TextAlignVertical.top,
                placeholder: 'apple,苹果\nbook,书\ntake off',
              ),
            ),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('取消'),
            onPressed: () => Navigator.pop(ctx),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('添加'),
            onPressed: () => Navigator.pop(ctx, wordsCtrl.text),
          ),
        ],
      ),
    );
    if (text == null || text.trim().isEmpty) return;
    final words = CustomDictService.parseWords(text);
    if (words.isEmpty) return;
    await widget.service.importWords(widget.dictName, words);
    if (mounted) {
      _refresh();
      showCupertinoDialog<void>(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: const Text('已添加'),
          content: Text('已向「${widget.dictName}」添加 ${words.length} 个单词'),
          actions: [
            CupertinoDialogAction(
              child: const Text('好的'),
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
      );
    }
  }

  /// 导入单词到当前词表
  Future<void> _import() async {
    final picked = await pickWordsToImport(context);
    if (picked == null || !mounted) return;
    await widget.service.importWords(widget.dictName, picked.words);
    if (mounted) {
      _refresh();
      showCupertinoDialog<void>(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: const Text('导入完成'),
          content: Text('已向「${widget.dictName}」导入 ${picked.words.length} 个单词'),
          actions: [
            CupertinoDialogAction(
              child: const Text('好的'),
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
      );
    }
  }

  void _refresh() => setState(() {});

  void _toggleCart(WordEntry w) {
    if (widget.cart.contains(w)) {
      widget.cart.removeWord(w);
    } else {
      widget.cart.add(w, CartSource.customDict);
    }
    _refresh();
  }

  /// 全选 / 取消全选（加入/移出购物车）
  void _toggleAll(List<WordEntry> words) {
    if (words.every(widget.cart.contains)) {
      widget.cart.removeAll(words);
    } else {
      widget.cart.addAll(words, CartSource.customDict);
    }
    _refresh();
  }

  /// 切换所有单词的默写方向
  void _toggleAllDirection(List<WordEntry> words, bool allCnToEn) {
    for (final w in words) {
      w.direction = allCnToEn
          ? DictateDirection.enToCn
          : DictateDirection.cnToEn;
    }
    _refresh();
  }

  /// 长按删除单词（带确认）
  Future<void> _confirmDelete(WordEntry w) async {
    final ok = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('删除单词'),
        content: Text('确定要从「${widget.dictName}」删除 ${w.english} 吗？'),
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
      await widget.service.removeWord(widget.dictName, w.english);
      if (mounted) _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final words = widget.service.wordsOf(widget.dictName);
    final selCount = words.where(widget.cart.contains).length;
    final allSel = words.isNotEmpty && words.every(widget.cart.contains);
    final allCnToEn =
        words.isNotEmpty &&
        words.every((w) => w.direction == DictateDirection.cnToEn);

    return Column(
      children: [
        // 工具栏（与内置词典一致）
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
          child: Row(
            children: [
              CupertinoButton(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                minimumSize: Size.zero,
                onPressed: words.isEmpty ? null : () => _toggleAll(words),
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
                onPressed: words.isEmpty
                    ? null
                    : () => _toggleAllDirection(words, allCnToEn),
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
                      allCnToEn ? '全部报英文' : '全部报中文',
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
                '$selCount/${words.length} 词',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),

        // 编辑行：提示 + 导入 / 添加单词
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
              CupertinoButton(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                minimumSize: Size.zero,
                onPressed: _import,
                child: const Text('导入', style: TextStyle(fontSize: 13)),
              ),
              CupertinoButton(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                minimumSize: Size.zero,
                onPressed: _addWord,
                child: const Text('添加单词', style: TextStyle(fontSize: 13)),
              ),
            ],
          ),
        ),

        // 单词列表（与内置词典一致：点一下加入购物车）
        Expanded(
          child: words.isEmpty
              ? const Center(
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
                        '这个词表还是空的',
                        style: TextStyle(
                          fontSize: 15,
                          color: CupertinoColors.secondaryLabel,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '点「添加单词」手动编入，或「导入」词表',
                        style: TextStyle(
                          fontSize: 12,
                          color: CupertinoColors.tertiaryLabel,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
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
                                      w.chinese.isEmpty ? '（无释义）' : w.chinese,
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
                                  isCnToEn ? '报中文' : '报英文',
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
