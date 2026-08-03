import 'package:flutter/cupertino.dart';

import '../services/wrong_word_service.dart';

/// 错词本首页 —— 管理多个错词本：新建 / 删除，点击进入错词本
class WrongWordScreen extends StatefulWidget {
  final WrongWordService wrongWordService;
  final void Function(String name) onOpenBook;

  const WrongWordScreen({
    super.key,
    required this.wrongWordService,
    required this.onOpenBook,
  });

  @override
  State<WrongWordScreen> createState() => _WrongWordScreenState();
}

class _WrongWordScreenState extends State<WrongWordScreen> {
  void _refresh() => setState(() {});

  /// 新建错词本
  Future<void> _createBook() async {
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
              placeholder: '错词本名称，如：单词拼写',
              autofocus: true,
            ),
            const SizedBox(height: 8),
            const Text(
              '默写完成后可将错词加入本子',
              style: TextStyle(
                fontSize: 12,
                color: CupertinoColors.secondaryLabel,
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
            child: const Text('创建'),
            onPressed: () => Navigator.pop(ctx, nameCtrl.text.trim()),
          ),
        ],
      ),
    );
    if (result == null || result.isEmpty) return;
    final ok = await widget.wrongWordService.createBook(result);
    if (!mounted) return;
    if (ok) {
      _refresh();
      widget.onOpenBook(result);
    } else {
      showCupertinoDialog<void>(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: const Text('无法创建'),
          content: const Text('该名称已存在或名称无效'),
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

  /// 删除错词本（带确认）
  Future<void> _deleteBook(String name) async {
    final book = widget.wrongWordService.find(name);
    final ok = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('删除错词本'),
        content: Text('确定要删除「$name」及其 ${book?.count ?? 0} 个错词吗？'),
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
      await widget.wrongWordService.deleteBook(name);
      _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final books = widget.wrongWordService.books;

    return Column(
      children: [
        // 工具栏
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
                  '默写完成后可将错词加入本子',
                  style: TextStyle(
                    fontSize: 12,
                    color: CupertinoColors.secondaryLabel,
                  ),
                ),
              ),
              CupertinoButton(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                minimumSize: Size.zero,
                onPressed: _createBook,
                child: const Text('新建错词本', style: TextStyle(fontSize: 13)),
              ),
            ],
          ),
        ),

        // 错词本列表
        Expanded(
          child: books.isEmpty
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
                        '还没有错词本',
                        style: TextStyle(
                          fontSize: 15,
                          color: CupertinoColors.secondaryLabel,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '点「新建错词本」创建',
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
                  itemCount: books.length,
                  itemBuilder: (_, i) {
                    final b = books[i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => widget.onOpenBook(b.name),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: CupertinoColors.secondarySystemBackground
                                .resolveFrom(context),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: CupertinoColors.systemGrey5,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                CupertinoIcons.tray,
                                size: 28,
                                color: CupertinoColors.activeBlue,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      b.name,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      '${b.count} 词',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: CupertinoColors.secondaryLabel,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              CupertinoButton(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 4,
                                ),
                                minimumSize: Size.zero,
                                onPressed: () => _deleteBook(b.name),
                                child: const Icon(
                                  CupertinoIcons.delete,
                                  size: 18,
                                  color: CupertinoColors.systemGrey3,
                                ),
                              ),
                              const Icon(
                                CupertinoIcons.chevron_right,
                                size: 14,
                                color: CupertinoColors.systemGrey3,
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
