import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/word_pair.dart';

/// 错词本 —— 一个具名错词本
class WrongBook {
  final String name;
  final List<WordEntry> words;

  WrongBook({required this.name, required this.words});

  int get count => words.length;
}

/// 错词本服务 —— 管理多个错词本，持久化到本地
class WrongWordService {
  static const _prefsKey = 'wrong_books_v1';
  static const _legacyPrefsKey = 'wrong_words_v1';
  static const defaultBookName = '错词本';

  final List<WrongBook> _books = [];

  List<WrongBook> get books => List.unmodifiable(_books);
  int get bookCount => _books.length;

  /// 全部错词本是否都为空
  bool get isEmpty => _books.every((b) => b.words.isEmpty);

  /// 全部错词总数（跨所有错词本）
  int get count => _books.fold(0, (sum, b) => sum + b.words.length);

  /// 所有错词（跨所有错词本）
  List<WordEntry> get words => [for (final b in _books) ...b.words];

  WrongBook? find(String name) {
    for (final b in _books) {
      if (b.name == name) return b;
    }
    return null;
  }

  List<WordEntry> wordsOf(String name) => find(name)?.words ?? const [];

  /// 返回默认错词本，不存在则创建
  WrongBook _defaultBook() {
    final existing = find(defaultBookName);
    if (existing != null) return existing;
    final book = WrongBook(name: defaultBookName, words: []);
    _books.add(book);
    return book;
  }

  /// 从本地存储加载错词本（兼容旧版扁平数据）
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null) {
      // 迁移旧版：扁平单词列表 → 默认错词本
      final legacy = prefs.getString(_legacyPrefsKey);
      if (legacy != null) {
        try {
          final list = jsonDecode(legacy) as List<dynamic>;
          _books.add(
            WrongBook(name: defaultBookName, words: _decodeWordList(list)),
          );
          await _save();
        } catch (e) {
          debugPrint('[WrongWordService] legacy load error: $e');
        }
      }
      return;
    }
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      _books.clear();
      for (final item in list.cast<Map<String, dynamic>>()) {
        final name = item['name'] as String;
        final words = _decodeWordList(item['words'] as List<dynamic>? ?? []);
        _books.add(WrongBook(name: name, words: words));
      }
    } catch (e) {
      debugPrint('[WrongWordService] load error: $e');
    }
  }

  List<WordEntry> _decodeWordList(List<dynamic> items) {
    final result = <WordEntry>[];
    for (final w in items) {
      final m = w as Map<String, dynamic>;
      result.add(
        WordEntry(
          book: m['book'] as String? ?? '',
          unit: m['unit'] as String? ?? '',
          english: m['english'] as String,
          chinese: m['chinese'] as String? ?? '',
          direction: m['direction'] == 'enToCn'
              ? DictateDirection.enToCn
              : DictateDirection.cnToEn,
        ),
      );
    }
    return result;
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final data = _books
        .map(
          (b) => {
            'name': b.name,
            'words': b.words
                .map(
                  (w) => {
                    'book': w.book,
                    'unit': w.unit,
                    'english': w.english,
                    'chinese': w.chinese,
                    'direction': w.direction.name,
                  },
                )
                .toList(),
          },
        )
        .toList();
    await prefs.setString(_prefsKey, jsonEncode(data));
  }

  /// 新建错词本；重名或空名返回 false
  Future<bool> createBook(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return false;
    if (find(trimmed) != null) return false;
    _books.add(WrongBook(name: trimmed, words: []));
    _save();
    return true;
  }

  /// 删除错词本（连同其单词）
  Future<void> deleteBook(String name) async {
    _books.removeWhere((b) => b.name == name);
    _save();
  }

  /// 添加一个错词到默认错词本（已存在则跳过）
  void add(WordEntry word) {
    final book = _defaultBook();
    if (!book.words.any((w) => w.english == word.english)) {
      book.words.add(word);
      _save();
    }
  }

  /// 批量添加到默认错词本
  void addAll(Iterable<WordEntry> words) {
    final book = _defaultBook();
    var changed = false;
    for (final w in words) {
      if (!book.words.any((x) => x.english == w.english)) {
        book.words.add(w);
        changed = true;
      }
    }
    if (changed) _save();
  }

  /// 添加一个错词到指定错词本（已存在则跳过）
  void addTo(String bookName, WordEntry word) {
    final book = find(bookName);
    if (book == null) return;
    if (!book.words.any((w) => w.english == word.english)) {
      book.words.add(word);
      _save();
    }
  }

  /// 批量添加到指定错词本（已存在则跳过）
  void addAllTo(String bookName, Iterable<WordEntry> words) {
    final book = find(bookName);
    if (book == null) return;
    var changed = false;
    for (final w in words) {
      if (!book.words.any((x) => x.english == w.english)) {
        book.words.add(w);
        changed = true;
      }
    }
    if (changed) _save();
  }

  /// 从所有错词本移除一个错词
  void remove(WordEntry word) {
    var changed = false;
    for (final b in _books) {
      final before = b.words.length;
      b.words.removeWhere((w) => w.english == word.english);
      if (b.words.length != before) changed = true;
    }
    if (changed) _save();
  }

  /// 从指定错词本移除一个错词
  void removeFrom(String bookName, WordEntry word) {
    final book = find(bookName);
    if (book == null) return;
    final before = book.words.length;
    book.words.removeWhere((w) => w.english == word.english);
    if (book.words.length != before) _save();
  }

  /// 清空指定错词本
  void clearBook(String bookName) {
    final book = find(bookName);
    if (book == null || book.words.isEmpty) return;
    book.words.clear();
    _save();
  }

  /// 清空所有错词本
  void clear() {
    var changed = false;
    for (final b in _books) {
      if (b.words.isNotEmpty) {
        b.words.clear();
        changed = true;
      }
    }
    if (changed) _save();
  }
}
