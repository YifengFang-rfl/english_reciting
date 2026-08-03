import 'package:flutter/cupertino.dart';

import '../services/custom_dict_service.dart';
import '../utils/custom_dict_import.dart';

/// 自定义词典首页 —— 管理词表：新建 / 导入 / 删除，点击进入词表
class CustomDictScreen extends StatefulWidget {
  final CustomDictService service;
  final void Function(String name) onOpenDict;

  const CustomDictScreen({
    super.key,
    required this.service,
    required this.onOpenDict,
  });

  @override
  State<CustomDictScreen> createState() => _CustomDictScreenState();
}

class _CustomDictScreenState extends State<CustomDictScreen> {
  /// 新建词表：同时填写词表名称和批量单词（每行：英文,中文释义）
  Future<void> _createDict() async {
    final nameCtrl = TextEditingController();
    final wordsCtrl = TextEditingController();
    final result = await showCupertinoDialog<({String name, String text})>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('新建词表'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CupertinoTextField(
              controller: nameCtrl,
              placeholder: '词表名称，如：我的生词本',
              autofocus: true,
            ),
            const SizedBox(height: 10),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '批量单词（每行一个：英文,中文释义）',
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
            child: const Text('创建'),
            onPressed: () => Navigator.pop(ctx, (
              name: nameCtrl.text.trim(),
              text: wordsCtrl.text,
            )),
          ),
        ],
      ),
    );
    if (result == null) return;
    if (result.name.isEmpty) return;
    final ok = await widget.service.createDict(result.name);
    if (!ok) {
      if (mounted) {
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
      return;
    }
    final words = CustomDictService.parseWords(result.text);
    if (words.isNotEmpty) {
      await widget.service.importWords(result.name, words);
    }
    if (mounted) {
      widget.onOpenDict(result.name);
    }
  }

  /// 导入词表（文件 / 粘贴文本），导入后直接进入该词表
  Future<void> _import() async {
    final picked = await pickWordsToImport(context);
    if (picked == null || !mounted) return;
    final suggested = picked.suggestedName.isNotEmpty
        ? picked.suggestedName
        : '导入词表 ${widget.service.dictCount + 1}';
    final name = await askDictName(context, suggested: suggested);
    if (name == null || !mounted) return;
    await widget.service.createDict(name); // 已存在则忽略
    await widget.service.importWords(name, picked.words);
    if (mounted) {
      widget.onOpenDict(name);
    }
  }

  /// 删除词表（带确认）
  Future<void> _deleteDict(String name) async {
    final dict = widget.service.find(name);
    final ok = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('删除词表'),
        content: Text('确定要删除「$name」及其 ${dict?.count ?? 0} 个单词吗？'),
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
      await widget.service.deleteDict(name);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.service,
      builder: (context, _) {
        final dicts = widget.service.dicts;

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
                      '手动编入或导入英语单词表',
                      style: TextStyle(
                        fontSize: 12,
                        color: CupertinoColors.secondaryLabel,
                      ),
                    ),
                  ),
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    minimumSize: Size.zero,
                    onPressed: _createDict,
                    child: const Text('新建词表', style: TextStyle(fontSize: 13)),
                  ),
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    minimumSize: Size.zero,
                    onPressed: _import,
                    child: const Text('导入词表', style: TextStyle(fontSize: 13)),
                  ),
                ],
              ),
            ),

            // 词表列表
            Expanded(
              child: dicts.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            CupertinoIcons.doc_text,
                            size: 48,
                            color: CupertinoColors.systemGrey3,
                          ),
                          SizedBox(height: 12),
                          Text(
                            '还没有词表',
                            style: TextStyle(
                              fontSize: 15,
                              color: CupertinoColors.secondaryLabel,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '点「新建词表」创建，或「导入词表」从文件/文本导入',
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
                      itemCount: dicts.length,
                      itemBuilder: (_, i) {
                        final d = dicts[i];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => widget.onOpenDict(d.name),
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
                                    CupertinoIcons.doc_text,
                                    size: 28,
                                    color: CupertinoColors.activeBlue,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          d.name,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Text(
                                          '${d.count} 词',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color:
                                                CupertinoColors.secondaryLabel,
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
                                    onPressed: () => _deleteDict(d.name),
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
      },
    );
  }
}
