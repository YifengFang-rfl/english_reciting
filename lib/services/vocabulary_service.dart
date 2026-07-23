import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart' show rootBundle;
import '../models/word_pair.dart';

/// 课本-单元摘要（不可变）
class BookUnit {
  final String book;
  final String unit;
  final int wordCount;

  const BookUnit({
    required this.book,
    required this.unit,
    required this.wordCount,
  });
  String get key => '$book|$unit';
}

/// 人教版高中英语词汇服务 —— 管理所有单词及选中状态
class VocabularyService {
  List<WordEntry> _allWords = [];
  List<BookUnit> _bookUnits = [];

  List<BookUnit> get bookUnits => _bookUnits;
  bool get isLoaded => _allWords.isNotEmpty;

  Future<void> load() async {
    final jsonStr = await rootBundle.loadString('assets/vocabulary_rj_s.json');
    final list = jsonDecode(jsonStr) as List<dynamic>;
    _allWords = list
        .map((e) => WordEntry.fromVocabularyJson(e as Map<String, dynamic>))
        .toList();

    final map = <String, Map<String, int>>{};
    for (final w in _allWords) {
      map.putIfAbsent(w.book, () => {});
      map[w.book]!.update(w.unit, (v) => v + 1, ifAbsent: () => 1);
    }

    _bookUnits = <BookUnit>[];
    for (final book in map.keys) {
      for (final unit in map[book]!.keys) {
        _bookUnits.add(
          BookUnit(book: book, unit: unit, wordCount: map[book]![unit]!),
        );
      }
    }
    _bookUnits.sort((a, b) {
      final c = a.book.compareTo(b.book);
      return c != 0 ? c : a.unit.compareTo(b.unit);
    });
  }

  List<String> get books =>
      _bookUnits.map((u) => u.book).toSet().toList()..sort();
  List<BookUnit> unitsOfBook(String book) =>
      _bookUnits.where((u) => u.book == book).toList();
  List<WordEntry> wordsOfUnit(String book, String unit) =>
      _allWords.where((w) => w.book == book && w.unit == unit).toList();

  bool isUnitFullySelected(String book, String unit) =>
      wordsOfUnit(book, unit).every((w) => w.selected);
  bool isUnitPartiallySelected(String book, String unit) {
    final ws = wordsOfUnit(book, unit);
    final n = ws.where((w) => w.selected).length;
    return n > 0 && n < ws.length;
  }

  int selectedInUnit(String book, String unit) =>
      wordsOfUnit(book, unit).where((w) => w.selected).length;

  void toggleUnit(String book, String unit) {
    final select = !isUnitFullySelected(book, unit);
    for (final w in wordsOfUnit(book, unit)) {
      w.selected = select;
    }
  }

  void toggleBook(String book) {
    final select = !_allWords
        .where((w) => w.book == book)
        .every((w) => w.selected);
    for (final w in _allWords.where((w) => w.book == book)) {
      w.selected = select;
    }
  }

  void selectAllUnits(bool selected) {
    for (final w in _allWords) {
      w.selected = selected;
    }
  }

  bool isBookFullySelected(String book) =>
      _allWords.where((w) => w.book == book).every((w) => w.selected);

  List<WordEntry> get selectedWords =>
      _allWords.where((w) => w.selected).toList();
  int get selectedWordCount => selectedWords.length;
  bool get hasSelection => selectedWords.isNotEmpty;

  List<WordEntry> randomPick(int count) {
    final pool = selectedWords.toList();
    pool.shuffle(Random());
    return pool.take(min(count, pool.length)).toList();
  }

  void resetSelection() {
    for (final w in _allWords) {
      w.selected = false;
    }
  }
}
