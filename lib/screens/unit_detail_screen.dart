import 'package:flutter/cupertino.dart';
import '../models/word_pair.dart';
import '../services/vocabulary_service.dart';

/// 单元详情页 —— 逐词选择/取消，切换默写方向
class UnitDetailScreen extends StatefulWidget {
  final VocabularyService vocab;
  final String book;
  final String unit;

  const UnitDetailScreen({
    super.key,
    required this.vocab,
    required this.book,
    required this.unit,
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

  int get _selCount => _words.where((w) => w.selected).length;

  @override
  Widget build(BuildContext context) {
    final allSel = _words.every((w) => w.selected);
    final allCnToEn = _words.every(
      (w) => w.direction == DictateDirection.cnToEn,
    );

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
                  for (final w in _words) {
                    w.selected = !allSel;
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
                    Icon(
                      allCnToEn
                          ? CupertinoIcons.arrow_2_squarepath
                          : CupertinoIcons.arrow_2_squarepath,
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
                '$_selCount/${_words.length} 词',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),

        // 单词列表
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _words.length,
            itemBuilder: (_, i) {
              final w = _words[i];
              final isCnToEn = w.direction == DictateDirection.cnToEn;

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
                    border: Border.all(
                      color: w.selected
                          ? CupertinoColors.activeBlue.withAlpha(60)
                          : CupertinoColors.systemGrey5,
                    ),
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          w.selected = !w.selected;
                          _refresh();
                        },
                        child: Icon(
                          w.selected
                              ? CupertinoIcons.checkmark_circle_fill
                              : CupertinoIcons.circle,
                          size: 20,
                          color: w.selected
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
                                color: w.selected
                                    ? null
                                    : CupertinoColors.systemGrey,
                              ),
                            ),
                            Text(
                              w.chinese,
                              style: TextStyle(
                                fontSize: 12,
                                color: w.selected
                                    ? CupertinoColors.secondaryLabel
                                    : CupertinoColors.systemGrey3,
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
              );
            },
          ),
        ),
      ],
    );
  }
}
