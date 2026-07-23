import '../models/word_pair.dart';

/// 错词本服务 —— 内存存储，管理错词列表
class WrongWordService {
  final List<WordEntry> _words = [];

  List<WordEntry> get words => List.unmodifiable(_words);
  int get count => _words.length;
  bool get isEmpty => _words.isEmpty;

  /// 添加一个错词（已存在则跳过）
  void add(WordEntry word) {
    if (!_words.any((w) => w.english == word.english)) {
      _words.add(word);
    }
  }

  /// 批量添加
  void addAll(Iterable<WordEntry> words) {
    for (final w in words) {
      add(w);
    }
  }

  /// 移除一个错词
  void remove(WordEntry word) {
    _words.removeWhere((w) => w.english == word.english);
  }

  /// 清空错词本
  void clear() => _words.clear();
}
