import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';

import '../models/word_pair.dart';
import '../services/custom_dict_service.dart';

/// 让用户选择导入来源（文件 / 粘贴文本），返回解析好的单词和推荐词表名。
/// 取消或没有解析到单词时返回 null。
Future<({List<WordEntry> words, String suggestedName})?> pickWordsToImport(
  BuildContext context,
) async {
  final action = await showCupertinoModalPopup<String>(
    context: context,
    builder: (ctx) => CupertinoActionSheet(
      title: const Text('导入词表'),
      message: const Text('每行一个单词，可用逗号或制表符分隔中文释义\n例如：apple,苹果'),
      actions: [
        CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(ctx, 'file'),
          child: const Text('从文件导入'),
        ),
        CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(ctx, 'paste'),
          child: const Text('粘贴文本导入'),
        ),
      ],
      cancelButton: CupertinoActionSheetAction(
        onPressed: () => Navigator.pop(ctx),
        child: const Text('取消'),
      ),
    ),
  );
  if (action == null) return null;

  if (action == 'file') {
    final picked = await _pickFileWords();
    if (picked == null) return null;
    return (words: picked.$1, suggestedName: picked.$2);
  }

  if (!context.mounted) return null;
  final text = await _pasteText(context);
  if (text == null) return null;
  final words = CustomDictService.parseWords(text);
  if (words.isEmpty) return null;
  return (words: words, suggestedName: '');
}

/// 从文件选择器读取并解析单词（跨平台：依赖文件字节数据）
Future<(List<WordEntry>, String)?> _pickFileWords() async {
  try {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['txt', 'csv', 'tsv'],
      withData: true,
    );
    if (result == null) return null;
    final file = result.files.single;
    final bytes = file.bytes;
    if (bytes == null) return null;
    final words = CustomDictService.parseWords(utf8.decode(bytes));
    if (words.isEmpty) return null;
    final name = file.name;
    final dot = name.lastIndexOf('.');
    final suggested = dot > 0 ? name.substring(0, dot) : name;
    return (words, suggested);
  } catch (e) {
    debugPrint('[CustomDict] pick file error: $e');
    return null;
  }
}

Future<String?> _pasteText(BuildContext context) async {
  final controller = TextEditingController();
  final text = await showCupertinoDialog<String>(
    context: context,
    builder: (ctx) => CupertinoAlertDialog(
      title: const Text('粘贴词表'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            '每行一个单词，可用逗号或制表符分隔中文释义',
            style: TextStyle(
              fontSize: 12,
              color: CupertinoColors.secondaryLabel,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: 260,
            height: 160,
            child: CupertinoTextField(
              controller: controller,
              maxLines: 8,
              textAlignVertical: TextAlignVertical.top,
              placeholder: 'apple,苹果\nbook,书',
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
          child: const Text('确定'),
          onPressed: () => Navigator.pop(ctx, controller.text),
        ),
      ],
    ),
  );
  return text;
}

/// 询问保存到哪个词表（预填建议名）；取消或空名返回 null
Future<String?> askDictName(
  BuildContext context, {
  required String suggested,
}) async {
  final controller = TextEditingController(text: suggested);
  final name = await showCupertinoDialog<String>(
    context: context,
    builder: (ctx) => CupertinoAlertDialog(
      title: const Text('保存到词表'),
      content: CupertinoTextField(
        controller: controller,
        placeholder: '词表名称',
        autofocus: true,
      ),
      actions: [
        CupertinoDialogAction(
          child: const Text('取消'),
          onPressed: () => Navigator.pop(ctx),
        ),
        CupertinoDialogAction(
          isDefaultAction: true,
          child: const Text('保存'),
          onPressed: () => Navigator.pop(ctx, controller.text.trim()),
        ),
      ],
    ),
  );
  if (name == null || name.isEmpty) return null;
  return name;
}
