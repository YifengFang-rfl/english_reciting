import 'package:flutter/foundation.dart';
import '../models/cart.dart';
import '../models/word_pair.dart';

/// 全局购物车服务 —— 跨课本/错词本/随机抽取累积选中的单词
class CartService extends ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => List.unmodifiable(_items);
  int get count => _items.length;
  bool get isEmpty => _items.isEmpty;
  List<WordEntry> get words => _items.map((e) => e.word).toList();

  /// 是否已加入购物车（按英文去重）
  bool contains(WordEntry w) => containsEnglish(w.english);
  bool containsEnglish(String english) =>
      _items.any((i) => i.word.english == english);

  /// 加入购物车（已存在同词则跳过）
  void add(WordEntry w, CartSource source) {
    if (contains(w)) return;
    _items.add(CartItem(word: w, source: source));
    notifyListeners();
  }

  /// 批量加入（按英文去重）
  void addAll(Iterable<WordEntry> words, CartSource source) {
    var changed = false;
    for (final w in words) {
      if (!contains(w)) {
        _items.add(CartItem(word: w, source: source));
        changed = true;
      }
    }
    if (changed) notifyListeners();
  }

  /// 移除一个条目（购物车弹层里的精确移除）
  void removeItem(CartItem item) {
    if (_items.remove(item)) notifyListeners();
  }

  /// 按单词移除（同一英文的条目全部移除）
  void removeWord(WordEntry w) => removeEnglish(w.english);
  void removeEnglish(String english) {
    final before = _items.length;
    _items.removeWhere((i) => i.word.english == english);
    if (_items.length != before) notifyListeners();
  }

  /// 批量移除（按英文去重，一次通知）
  void removeAll(Iterable<WordEntry> words) {
    final targets = words.map((w) => w.english).toSet();
    final before = _items.length;
    _items.removeWhere((i) => targets.contains(i.word.english));
    if (_items.length != before) notifyListeners();
  }

  /// 移除某个来源的所有条目（如：取消所有课本来源的单词）
  void clearSource(CartSource source) {
    final before = _items.length;
    _items.removeWhere((i) => i.source == source);
    if (_items.length != before) notifyListeners();
  }

  void clear() {
    if (_items.isEmpty) return;
    _items.clear();
    notifyListeners();
  }
}
