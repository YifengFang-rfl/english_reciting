import 'package:flutter/cupertino.dart';
import '../models/word_pair.dart';
import '../services/vocabulary_service.dart';

/// 课本/单元选择页 —— 支持多选、连续选、随机抽取
class BookSelectionScreen extends StatefulWidget {
  final VocabularyService vocab;
  final void Function(String book, String unit) onEnterUnit;
  final void Function(List<WordEntry> words) onStartDictation;

  const BookSelectionScreen({
    super.key,
    required this.vocab,
    required this.onEnterUnit,
    required this.onStartDictation,
  });

  @override
  State<BookSelectionScreen> createState() => _BookSelectionScreenState();
}

class _BookSelectionScreenState extends State<BookSelectionScreen> {
  final _randomController = TextEditingController();
  bool _randomMode = false;
  final _expandedBooks = <String>{}; // 记录展开的课本

  VocabularyService get _v => widget.vocab;

  @override
  void dispose() {
    _randomController.dispose();
    super.dispose();
  }

  void _refresh() => setState(() {});

  void _start() {
    List<WordEntry> words;
    if (_randomMode) {
      final n = int.tryParse(_randomController.text.trim()) ?? 0;
      if (n <= 0) return;
      words = _v.randomPick(n);
    } else {
      words = _v.selectedWords;
    }
    if (words.isEmpty) return;
    widget.onStartDictation(words);
  }

  @override
  Widget build(BuildContext context) {
    final books = _v.books;
    final totalSel = _v.selectedWordCount;

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
                  _v.selectAllUnits(true);
                  _refresh();
                },
                child: const Text('全选', style: TextStyle(fontSize: 13)),
              ),
              CupertinoButton(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                minimumSize: Size.zero,
                onPressed: () {
                  _v.selectAllUnits(false);
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
              final fullySel = _v.isBookFullySelected(book);
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
                        onToggle: () {
                          _v.toggleBook(book);
                          _refresh();
                        },
                      ),
                    ),
                    if (expanded) ...[
                      const SizedBox(height: 4),
                      ...units.asMap().entries.map((e) {
                        final u = e.value;
                        final fully = _v.isUnitFullySelected(book, u.unit);
                        final partial = _v.isUnitPartiallySelected(
                          book,
                          u.unit,
                        );
                        final selCount = _v.selectedInUnit(book, u.unit);

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
                                  onTap: () {
                                    _v.toggleUnit(book, u.unit);
                                    _refresh();
                                  },
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    CupertinoSwitch(
                      value: _randomMode,
                      onChanged: (v) => setState(() => _randomMode = v),
                    ),
                    const SizedBox(width: 6),
                    const Text('随机抽取', style: TextStyle(fontSize: 14)),
                    const Spacer(),
                    if (_randomMode) ...[
                      SizedBox(
                        width: 60,
                        child: CupertinoTextField(
                          controller: _randomController,
                          placeholder: '数量',
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          padding: const EdgeInsets.symmetric(
                            vertical: 6,
                            horizontal: 8,
                          ),
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      const Text(' 词  ', style: TextStyle(fontSize: 14)),
                    ],
                    Text(
                      '共 $totalSel 词',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                CupertinoButton.filled(
                  onPressed:
                      (_v.hasSelection ||
                          (_randomMode &&
                              (int.tryParse(_randomController.text.trim()) ??
                                      0) >
                                  0))
                      ? _start
                      : null,
                  child: Text(_randomMode ? '随机抽取并开始' : '开始默写（$totalSel 词）'),
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
