import 'package:flutter/cupertino.dart';
import '../models/cart.dart';
import '../services/cart_service.dart';
import '../services/vocabulary_service.dart';

/// 课本/单元选择页 —— 支持多选、连续选、随机抽取
class BookSelectionScreen extends StatefulWidget {
  final VocabularyService vocab;
  final CartService cart;
  final void Function(String book, String unit) onEnterUnit;
  final VoidCallback onRandomExtract;

  const BookSelectionScreen({
    super.key,
    required this.vocab,
    required this.cart,
    required this.onEnterUnit,
    required this.onRandomExtract,
  });

  @override
  State<BookSelectionScreen> createState() => _BookSelectionScreenState();
}

class _BookSelectionScreenState extends State<BookSelectionScreen> {
  final _expandedBooks = <String>{}; // 记录展开的课本

  VocabularyService get _v => widget.vocab;

  void _refresh() => setState(() {});

  bool _bookFullySelected(String book) =>
      _v.wordsOfBook(book).every((w) => widget.cart.contains(w));

  bool _unitFully(String book, String unit) =>
      _v.wordsOfUnit(book, unit).every((w) => widget.cart.contains(w));

  bool _unitPartial(String book, String unit) {
    final ws = _v.wordsOfUnit(book, unit);
    final n = ws.where((w) => widget.cart.contains(w)).length;
    return n > 0 && n < ws.length;
  }

  int _unitSelCount(String book, String unit) =>
      _v.wordsOfUnit(book, unit).where((w) => widget.cart.contains(w)).length;

  void _toggleUnit(String book, String unit) {
    final ws = _v.wordsOfUnit(book, unit);
    if (_unitFully(book, unit)) {
      widget.cart.removeAll(ws);
    } else {
      widget.cart.addAll(ws, CartSource.textbook);
    }
    _refresh();
  }

  void _toggleBook(String book) {
    final ws = _v.wordsOfBook(book);
    if (_bookFullySelected(book)) {
      widget.cart.removeAll(ws);
    } else {
      widget.cart.addAll(ws, CartSource.textbook);
    }
    _refresh();
  }

  /// 全选：把所有课本的单词加入购物车
  void _selectAllBooks() =>
      widget.cart.addAll(_v.allWords, CartSource.textbook);

  /// 取消：移除所有课本来源的单词（保留错词本/随机抽取）
  void _clearTextbook() => widget.cart.clearSource(CartSource.textbook);

  @override
  Widget build(BuildContext context) {
    final books = _v.books;
    final totalSel = widget.cart.count;

    return Column(
      children: [
        // 顶部工具栏
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
          child: Row(
            children: [
              const Icon(
                CupertinoIcons.info_circle,
                size: 16,
                color: CupertinoColors.secondaryLabel,
              ),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  '点击单元可进入逐词选择',
                  style: TextStyle(
                    fontSize: 12,
                    color: CupertinoColors.secondaryLabel,
                  ),
                ),
              ),
              CupertinoButton(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                minimumSize: Size.zero,
                onPressed: () {
                  _selectAllBooks();
                  _refresh();
                },
                child: const Text('全选', style: TextStyle(fontSize: 13)),
              ),
              CupertinoButton(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                minimumSize: Size.zero,
                onPressed: () {
                  _clearTextbook();
                  _refresh();
                },
                child: const Text('取消', style: TextStyle(fontSize: 13)),
              ),
            ],
          ),
        ),

        // 课本-单元列表
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: books.length,
            itemBuilder: (ctx, bookIdx) {
              final book = books[bookIdx];
              final units = _v.unitsOfBook(book);
              final fullySel = _bookFullySelected(book);
              final expanded = _expandedBooks.contains(book);

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          expanded
                              ? _expandedBooks.remove(book)
                              : _expandedBooks.add(book);
                        });
                      },
                      child: _BookBar(
                        book: book,
                        unitCount: units.length,
                        totalWords: units.fold(0, (s, u) => s + u.wordCount),
                        fullySelected: fullySel,
                        expanded: expanded,
                        onToggle: () => _toggleBook(book),
                      ),
                    ),
                    if (expanded) ...[
                      const SizedBox(height: 4),
                      ...units.asMap().entries.map((e) {
                        final u = e.value;
                        final fully = _unitFully(book, u.unit);
                        final partial = _unitPartial(book, u.unit);
                        final selCount = _unitSelCount(book, u.unit);

                        IconData icon;
                        if (fully) {
                          icon = CupertinoIcons.checkmark_circle_fill;
                        } else if (partial) {
                          icon = CupertinoIcons.circle_lefthalf_fill;
                        } else {
                          icon = CupertinoIcons.circle;
                        }

                        return GestureDetector(
                          onTap: () => widget.onEnterUnit(book, u.unit),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              border: Border(
                                left: BorderSide(
                                  color: fully || partial
                                      ? CupertinoColors.activeBlue
                                      : CupertinoColors.systemGrey5,
                                  width: 3,
                                ),
                                bottom: e.key == units.length - 1
                                    ? BorderSide.none
                                    : BorderSide(
                                        color: CupertinoColors.systemGrey6,
                                        width: 0.5,
                                      ),
                              ),
                            ),
                            child: Row(
                              children: [
                                GestureDetector(
                                  onTap: () => _toggleUnit(book, u.unit),
                                  child: Icon(
                                    icon,
                                    size: 20,
                                    color: fully || partial
                                        ? CupertinoColors.activeBlue
                                        : CupertinoColors.systemGrey4,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    u.unit,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: fully || partial
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ),
                                if (partial)
                                  Text(
                                    '$selCount/',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: CupertinoColors.secondaryLabel,
                                    ),
                                  ),
                                Text(
                                  '${u.wordCount}词',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: partial
                                        ? CupertinoColors.activeBlue
                                        : CupertinoColors.secondaryLabel,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  CupertinoIcons.chevron_right,
                                  size: 14,
                                  color: CupertinoColors.systemGrey3,
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ], // if (expanded)
                  ],
                ),
              );
            },
          ),
        ),

        // 底部区域
        Container(
          decoration: BoxDecoration(
            color: CupertinoColors.secondarySystemBackground.resolveFrom(
              context,
            ),
            border: Border(top: BorderSide(color: CupertinoColors.systemGrey5)),
          ),
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                // 进入随机抽取页面
                CupertinoButton(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  color: CupertinoColors.activeBlue.withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                  onPressed: widget.onRandomExtract,
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        CupertinoIcons.shuffle,
                        size: 16,
                        color: CupertinoColors.activeBlue,
                      ),
                      SizedBox(width: 6),
                      Text(
                        '随机抽取',
                        style: TextStyle(
                          fontSize: 14,
                          color: CupertinoColors.activeBlue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  '共 $totalSel 词',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _BookBar extends StatelessWidget {
  final String book;
  final int unitCount;
  final int totalWords;
  final bool fullySelected;
  final bool expanded;
  final VoidCallback onToggle;

  const _BookBar({
    required this.book,
    required this.unitCount,
    required this.totalWords,
    required this.fullySelected,
    required this.expanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onToggle,
            child: Icon(
              fullySelected
                  ? CupertinoIcons.checkmark_circle_fill
                  : CupertinoIcons.circle,
              size: 20,
              color: fullySelected
                  ? CupertinoColors.activeBlue
                  : CupertinoColors.systemGrey3,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              book,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
          ),
          Text(
            '$unitCount单元 · $totalWords词',
            style: const TextStyle(
              fontSize: 12,
              color: CupertinoColors.secondaryLabel,
            ),
          ),
          const SizedBox(width: 8),
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            minimumSize: Size.zero,
            onPressed: onToggle,
            child: Text(
              fullySelected ? '取消' : '全选',
              style: const TextStyle(fontSize: 13),
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            expanded ? CupertinoIcons.chevron_up : CupertinoIcons.chevron_down,
            size: 16,
            color: CupertinoColors.systemGrey3,
          ),
        ],
      ),
    );
  }
}
