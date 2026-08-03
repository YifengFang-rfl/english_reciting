import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/word_pair.dart';

/// 自定义词典 —— 一个具名词表及其单词
class CustomDict {
  final String name;
  final List<WordEntry> words;

  CustomDict({required this.name, required this.words});

  int get count => words.length;
}

/// 自定义词典服务 —— 管理多个自定义词表，持久化到本地，支持文本词表解析
class CustomDictService extends ChangeNotifier {
  static const _prefsKey = 'custom_dicts_v1';
  static const bookName = '自定义词典';

  final List<CustomDict> _dicts = [];

  List<CustomDict> get dicts => List.unmodifiable(_dicts);
  bool get isEmpty => _dicts.isEmpty;
  int get dictCount => _dicts.length;

  CustomDict? find(String name) {
    for (final d in _dicts) {
      if (d.name == name) return d;
    }
    return null;
  }

  List<WordEntry> wordsOf(String name) => find(name)?.words ?? const [];

  /// 从本地存储加载
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null) return;
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      _dicts.clear();
      for (final item in list.cast<Map<String, dynamic>>()) {
        final name = item['name'] as String;
        final words = <WordEntry>[];
        for (final w in (item['words'] as List<dynamic>? ?? [])) {
          final m = w as Map<String, dynamic>;
          words.add(
            WordEntry(
              book: bookName,
              unit: name,
              english: m['english'] as String,
              chinese: m['chinese'] as String? ?? '',
            ),
          );
        }
        _dicts.add(CustomDict(name: name, words: words));
      }
      notifyListeners();
    } catch (e) {
      debugPrint('[CustomDictService] load error: $e');
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final data = _dicts
        .map(
          (d) => {
            'name': d.name,
            'words': d.words
                .map((w) => {'english': w.english, 'chinese': w.chinese})
                .toList(),
          },
        )
        .toList();
    await prefs.setString(_prefsKey, jsonEncode(data));
  }

  /// 新建词表；重名或空名返回 false
  Future<bool> createDict(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return false;
    if (find(trimmed) != null) return false;
    _dicts.add(CustomDict(name: trimmed, words: []));
    notifyListeners();
    await _save();
    return true;
  }

  Future<void> deleteDict(String name) async {
    _dicts.removeWhere((d) => d.name == name);
    notifyListeners();
    await _save();
  }

  /// 手动添加一个单词（按英文去重）
  Future<void> addWord(String dictName, String english, String chinese) async {
    final dict = find(dictName);
    if (dict == null) return;
    final e = english.trim();
    if (e.isEmpty) return;
    if (dict.words.any((w) => w.english == e)) return;
    dict.words.add(
      WordEntry(
        book: bookName,
        unit: dictName,
        english: e,
        chinese: chinese.trim(),
      ),
    );
    notifyListeners();
    await _save();
  }

  /// 批量导入单词到指定词表（按英文去重）
  Future<void> importWords(String dictName, List<WordEntry> words) async {
    final dict = find(dictName);
    if (dict == null) return;
    var added = 0;
    for (final w in words) {
      if (dict.words.any((x) => x.english == w.english)) continue;
      dict.words.add(
        WordEntry(
          book: bookName,
          unit: dictName,
          english: w.english,
          chinese: w.chinese,
        ),
      );
      added++;
    }
    if (added > 0) {
      notifyListeners();
      await _save();
    }
  }

  Future<void> removeWord(String dictName, String english) async {
    final dict = find(dictName);
    if (dict == null) return;
    final before = dict.words.length;
    dict.words.removeWhere((w) => w.english == english);
    if (dict.words.length != before) {
      notifyListeners();
      await _save();
    }
  }

  /// 解析词表文本：每行一个单词，可用逗号或制表符分隔中文释义
  /// 示例：apple,苹果   /   take off   /   book  书
  static List<WordEntry> parseWords(String text) {
    final result = <WordEntry>[];
    for (final raw in text.split('\n')) {
      final line = raw.trim();
      if (line.isEmpty) continue;
      var english = line;
      var chinese = '';
      var sep = line.indexOf('\t');
      if (sep == -1) sep = line.indexOf(',');
      if (sep == -1) sep = line.indexOf('，');
      if (sep != -1) {
        english = line.substring(0, sep).trim();
        chinese = line.substring(sep + 1).trim();
      }
      if (english.isEmpty) continue;
      result.add(
        WordEntry(book: bookName, unit: '', english: english, chinese: chinese),
      );
    }
    return result;
  }
}
