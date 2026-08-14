import 'package:flutter/cupertino.dart';
import '../models/cart.dart';

/// 全局购物车栏：左下角购物车 + 右侧“开始默写”（结账）
/// 购物车是全局的，可以跨课本/单元累积已选单词。
class CartBar extends StatelessWidget {
  final int count;
  final VoidCallback onOpenCart;
  final VoidCallback onCheckout;
  final String hint;

  const CartBar({
    super.key,
    required this.count,
    required this.onOpenCart,
    required this.onCheckout,
    this.hint = '点击默写单词表查看 / 移除',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: CupertinoColors.secondarySystemBackground.resolveFrom(context),
        border: Border(top: BorderSide(color: CupertinoColors.systemGrey5)),
      ),
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // 左下角购物车按钮
            GestureDetector(
              onTap: onOpenCart,
              behavior: HitTestBehavior.opaque,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: CupertinoColors.activeBlue,
                    ),
                    child: const Icon(
                      CupertinoIcons.list_bullet,
                      color: CupertinoColors.white,
                      size: 22,
                    ),
                  ),
                  if (count > 0)
                    Positioned(
                      right: -2,
                      top: -2,
                      child: CountBadge(count: count),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '默写单词表 · 共 $count 词',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    hint,
                    style: const TextStyle(
                      fontSize: 11,
                      color: CupertinoColors.secondaryLabel,
                    ),
                  ),
                ],
              ),
            ),
            CupertinoButton.filled(
              onPressed: count > 0 ? onCheckout : null,
              child: const Text('开始默写'),
            ),
          ],
        ),
      ),
    );
  }
}

/// 购物车角标
class CountBadge extends StatelessWidget {
  final int count;

  const CountBadge({super.key, required this.count});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      transitionBuilder: (child, anim) =>
          ScaleTransition(scale: anim, child: child),
      child: Container(
        key: ValueKey<int>(count),
        constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
        decoration: BoxDecoration(
          color: CupertinoColors.systemRed,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Text(
          '$count',
          style: const TextStyle(
            color: CupertinoColors.white,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

/// 全局购物车弹层：按“来源”分组（课本·单元 / 错词本 / 随机抽取），
/// 点击分组展开查看具体单词，可移除，可结账开始默写。
class CartSheet extends StatefulWidget {
  final List<CartItem> items;
  final void Function(CartItem item) onRemove;
  final VoidCallback onCheckout;
  final VoidCallback? onClearAll;
  final Future<void> Function(List<CartItem> items)? onExportPdf;

  const CartSheet({
    super.key,
    required this.items,
    required this.onRemove,
    required this.onCheckout,
    this.onClearAll,
    this.onExportPdf,
  });

  @override
  State<CartSheet> createState() => _CartSheetState();
}

class _CartSheetState extends State<CartSheet> {
  late final List<CartItem> _items = List.of(widget.items);
  final Set<String> _expanded = {};

  void _remove(CartItem item) {
    setState(() => _items.remove(item));
    widget.onRemove(item);
    if (_items.isEmpty) {
      Navigator.of(context).pop();
    }
  }

  /// 关闭弹层后生成并分享默写单词表 PDF
  Future<void> _exportPdf() async {
    final items = List<CartItem>.of(_items);
    Navigator.of(context).pop();
    await widget.onExportPdf?.call(items);
  }

  /// 一键清空购物车（带确认）
  Future<void> _confirmClear() async {
    final ok = await showCupertinoDialog<bool>(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('清空默写单词表'),
        content: Text('确定要清空默写单词表里的 ${_items.length} 个单词吗？'),
        actions: [
          CupertinoDialogAction(
            child: const Text('取消'),
            onPressed: () => Navigator.pop(context, false),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('清空'),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );
    if (ok == true) {
      if (!mounted) return;
      widget.onClearAll?.call();
      Navigator.of(context).pop(); // 关闭购物车弹层
    }
  }

  IconData _sourceIcon(CartSource source) => switch (source) {
    CartSource.textbook => CupertinoIcons.book,
    CartSource.wrongWord => CupertinoIcons.tray_fill,
    CartSource.random => CupertinoIcons.shuffle,
    CartSource.customDict => CupertinoIcons.doc_text,
  };

  @override
  Widget build(BuildContext context) {
    final count = _items.length;

    // 按来源分组（保持加入顺序）
    final groups = <String, List<CartItem>>{};
    final order = <String>[];
    for (final item in _items) {
      final key = item.sourceLabel;
      if (!groups.containsKey(key)) {
        groups[key] = [];
        order.add(key);
      }
      groups[key]!.add(item);
    }

    return Container(
      height: 460,
      decoration: const BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      child: Column(
        children: [
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: CupertinoColors.systemGrey4,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(
                CupertinoIcons.list_bullet,
                size: 18,
                color: CupertinoColors.activeBlue,
              ),
              const SizedBox(width: 6),
              Text(
                '默写单词表（共 $count 词）',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (count > 0 && widget.onClearAll != null)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _confirmClear,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    child: Text(
                      '清空',
                      style: TextStyle(
                        fontSize: 13,
                        color: CupertinoColors.destructiveRed,
                      ),
                    ),
                  ),
                ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: const Icon(
                  CupertinoIcons.xmark,
                  size: 18,
                  color: CupertinoColors.secondaryLabel,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '点击来源分组展开单词',
              style: TextStyle(
                fontSize: 11,
                color: CupertinoColors.secondaryLabel,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _items.isEmpty
                ? const Center(
                    child: Text(
                      '默写单词表还是空的，去加点单词吧',
                      style: TextStyle(
                        fontSize: 13,
                        color: CupertinoColors.secondaryLabel,
                      ),
                    ),
                  )
                : ListView(
                    children: [
                      for (final key in order)
                        _groupTile(
                          key: key,
                          items: groups[key]!,
                          icon: _sourceIcon(groups[key]!.first.source),
                          expanded: _expanded.contains(key),
                        ),
                    ],
                  ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: CupertinoButton(
                  color: CupertinoColors.secondarySystemBackground.resolveFrom(
                    context,
                  ),
                  borderRadius: BorderRadius.circular(10),
                  onPressed: count > 0 ? _exportPdf : null,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        CupertinoIcons.doc_text_search,
                        size: 18,
                        color: CupertinoColors.activeBlue,
                      ),
                      SizedBox(width: 6),
                      Text(
                        '导出 PDF',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: CupertinoColors.activeBlue,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CupertinoButton.filled(
                  onPressed: count > 0 ? widget.onCheckout : null,
                  child: Text('开始默写（$count 词）'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _groupTile({
    required String key,
    required List<CartItem> items,
    required IconData icon,
    required bool expanded,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: CupertinoColors.secondarySystemBackground.resolveFrom(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: expanded
              ? CupertinoColors.activeBlue.withAlpha(80)
              : CupertinoColors.systemGrey5,
        ),
      ),
      child: Column(
        children: [
          // 分组标题（来源）—— 点击展开/收起
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() {
              expanded ? _expanded.remove(key) : _expanded.add(key);
            }),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Row(
                children: [
                  Icon(icon, size: 18, color: CupertinoColors.activeBlue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      key,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    '${items.length} 词',
                    style: const TextStyle(
                      fontSize: 12,
                      color: CupertinoColors.secondaryLabel,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    expanded
                        ? CupertinoIcons.chevron_up
                        : CupertinoIcons.chevron_down,
                    size: 14,
                    color: CupertinoColors.systemGrey3,
                  ),
                ],
              ),
            ),
          ),
          if (expanded)
            ...items.map(
              (item) => Container(
                margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemBackground.resolveFrom(context),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: CupertinoColors.systemGrey5),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.word.english,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            item.word.chinese,
                            style: const TextStyle(
                              fontSize: 12,
                              color: CupertinoColors.secondaryLabel,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // 减号：从购物车移除该单词
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      onPressed: () => _remove(item),
                      child: const Icon(
                        CupertinoIcons.minus_circle,
                        size: 22,
                        color: CupertinoColors.systemRed,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
