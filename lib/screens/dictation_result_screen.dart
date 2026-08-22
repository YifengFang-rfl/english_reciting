import 'package:flutter/cupertino.dart';
import '../models/word_pair.dart';
import '../services/wrong_word_service.dart';

/// 默写完成结果页 —— 查看刚默写的单词，勾选加入错词本
class DictationResultScreen extends StatefulWidget {
  final List<WordEntry> words;
  final WrongWordService wrongWordService;
  final VoidCallback onBackHome;

  const DictationResultScreen({
    super.key,
    required this.words,
    required this.wrongWordService,
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

  /// 选择要加入的错词本；返回 null 表示取消
  Future<String?> _pickWrongBook() {
    final books = widget.wrongWordService.books;
    return showCupertinoModalPopup<String>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: const Text('加入错词本'),
        message: const Text('选择要加入哪个错词本'),
        actions: [
          for (final b in books)
            CupertinoActionSheetAction(
              onPressed: () => Navigator.pop(ctx, b.name),
              child: Text('${b.name}（${b.count} 词）'),
            ),
          CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(ctx, '__new__'),
            child: const Text('新建错词本…'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.pop(ctx),
          child: const Text('取消'),
        ),
      ),
    );
  }

  /// 新建错词本并返回名称；取消返回 null，重名则直接复用
  Future<String?> _createBookAndReturnName() async {
    final nameCtrl = TextEditingController();
    final result = await showCupertinoDialog<String>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('新建错词本'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CupertinoTextField(
              controller: nameCtrl,
              placeholder: '错词本名称',
              autofocus: true,
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
            child: const Text('创建'),
            onPressed: () => Navigator.pop(ctx, nameCtrl.text.trim()),
          ),
        ],
      ),
    );
    if (result == null || result.isEmpty) return null;
    if (widget.wrongWordService.find(result) != null) return result;
    final ok = await widget.wrongWordService.createBook(result);
    return ok ? result : null;
  }

  Future<void> _addToWrongWords() async {
    final service = widget.wrongWordService;
    String? bookName;
    if (service.books.isEmpty) {
      // 还没有错词本，直接进入新建
      bookName = await _createBookAndReturnName();
      if (bookName == null) return;
    } else {
      final picked = await _pickWrongBook();
      if (picked == null) return;
      bookName = picked == '__new__'
          ? await _createBookAndReturnName()
          : picked;
      if (bookName == null) return;
    }

    service.addAllTo(bookName, [
      for (var i = 0; i < widget.words.length; i++)
        if (_checked[i]) widget.words[i],
    ]);
    if (!mounted) return;
    setState(() {});
    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('已添加'),
        content: Text('$_checkedCount 个单词已加入「$bookName」'),
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
                  _checked.every((c) => c) ? '取消' : '全选为错词',
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
                              ? '报中文'
                              : '报英文',
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
                  onPressed: widget.onBackHome,
                  child: const Text('返回首页'),
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
