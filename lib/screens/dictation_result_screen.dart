import 'package:flutter/cupertino.dart';
import '../models/word_pair.dart';
import '../services/wrong_word_service.dart';

/// 默写完成结果页 —— 查看刚默写的单词，勾选加入错词本
class DictationResultScreen extends StatefulWidget {
  final List<WordEntry> words;
  final WrongWordService wrongWordService;
  final VoidCallback onBackToSelect;
  final VoidCallback onBackHome;

  const DictationResultScreen({
    super.key,
    required this.words,
    required this.wrongWordService,
    required this.onBackToSelect,
    required this.onBackHome,
  });

  @override
  State<DictationResultScreen> createState() => _DictationResultScreenState();
}

class _DictationResultScreenState extends State<DictationResultScreen> {
  late List<bool> _checked;

  @override
  void initState() {
    super.initState();
    _checked = List.filled(widget.words.length, false);
  }

  int get _checkedCount => _checked.where((c) => c).length;

  void _addToWrongWords() {
    for (var i = 0; i < widget.words.length; i++) {
      if (_checked[i]) {
        widget.wrongWordService.add(widget.words[i]);
      }
    }
    setState(() {});
    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('已添加'),
        content: Text('$_checkedCount 个单词已加入错词本'),
        actions: [
          CupertinoDialogAction(
            child: const Text('好的'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 工具栏
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
          child: Row(
            children: [
              Text(
                '共 ${widget.words.length} 词',
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
                  final all = _checked.every((c) => c);
                  for (var i = 0; i < _checked.length; i++) {
                    _checked[i] = !all;
                  }
                  setState(() {});
                },
                child: Text(
                  _checked.every((c) => c) ? '取消全选' : '全选为错词',
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: widget.words.length,
            itemBuilder: (_, i) {
              final w = widget.words[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: GestureDetector(
                  onTap: () {
                    _checked[i] = !_checked[i];
                    setState(() {});
                  },
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
                        color: _checked[i]
                            ? CupertinoColors.destructiveRed.withAlpha(80)
                            : CupertinoColors.systemGrey5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _checked[i]
                              ? CupertinoIcons.xmark_circle_fill
                              : CupertinoIcons.circle,
                          size: 20,
                          color: _checked[i]
                              ? CupertinoColors.destructiveRed
                              : CupertinoColors.systemGrey4,
                        ),
                        const SizedBox(width: 10),
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
                        Text(
                          w.direction == DictateDirection.cnToEn
                              ? '默英文'
                              : '默中文',
                          style: TextStyle(
                            fontSize: 12,
                            color: w.direction == DictateDirection.cnToEn
                                ? CupertinoColors.activeOrange
                                : CupertinoColors.activeBlue,
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

        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: CupertinoButton(
                  color: CupertinoColors.secondarySystemBackground.resolveFrom(
                    context,
                  ),
                  borderRadius: BorderRadius.circular(10),
                  onPressed: widget.onBackToSelect,
                  child: const Text('返回选书'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CupertinoButton.filled(
                  onPressed: _checkedCount > 0 ? _addToWrongWords : null,
                  child: Text(
                    _checkedCount > 0 ? '加入错词本 ($_checkedCount)' : '勾选错词',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
