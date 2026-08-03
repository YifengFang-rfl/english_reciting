import 'package:flutter/cupertino.dart';
import '../models/cart.dart';
import '../services/cart_service.dart';
import '../services/vocabulary_service.dart';

/// 课本/单元选择页 —— 支持多选、连续选、随机抽取
class BookSelectionScreen extends StatefulWidget {
  final VocabularyService vocab;
  final CartService cart;
  final void Function(String book, String unit) onEnterUnit;

  const BookSelectionScreen({
    super.key,
    required this.vocab,
    required this.cart,
    required this.onEnterUnit,
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

  bool _bookPartial(String book) {
    final ws = _v.wordsOfBook(book);
    final n = ws.where((w) => widget.cart.contains(w)).length;
    return n > 0 && n < ws.length;
  }

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

  /// 全部课本是否都已加入购物车
  bool get _allBooksSelected =>
      _v.allWords.every((w) => widget.cart.contains(w));

  /// 全选 / 取消全选：把全部课本单词加入或移出购物车
  void _toggleAllBooks() {
    if (_allBooksSelected) {
      widget.cart.clearSource(CartSource.textbook);
    } else {
      widget.cart.addAll(_v.allWords, CartSource.textbook);
    }
  }

  @override
  Widget build(BuildContext context) {
    final books = _v.books;

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
                  _toggleAllBooks();
                  _refresh();
                },
                child: Text(
                  _allBooksSelected ? '取消全选' : '全选',
                  style: const TextStyle(fontSize: 13),
                ),
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
              final partialSel = _bookPartial(book);
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
                        partialSelected: partialSel,
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
      ],
    );
  }
}

class _BookBar extends StatelessWidget {
  final String book;
  final int unitCount;
  final int totalWords;
  final bool fullySelected;
  final bool partialSelected;
  final bool expanded;
  final VoidCallback onToggle;

  const _BookBar({
    required this.book,
    required this.unitCount,
    required this.totalWords,
    required this.fullySelected,
    required this.partialSelected,
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
                  : partialSelected
                  ? CupertinoIcons.circle_lefthalf_fill
                  : CupertinoIcons.circle,
              size: 20,
              color: fullySelected || partialSelected
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
