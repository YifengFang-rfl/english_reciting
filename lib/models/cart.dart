import 'word_pair.dart';

/// 购物车条目的来源
enum CartSource {
  /// 课本 · 单元里逐词点选的单词
  textbook,

  /// 从错词本加入的单词
  wrongWord,

  /// 随机抽取的单词
  random,

  /// 自定义词典里的单词
  customDict,
}

/// 购物车条目 —— 单词 + 来源
class CartItem {
  final WordEntry word;
  final CartSource source;

  const CartItem({required this.word, required this.source});

  /// 购物车分组标题，体现所选单词的来源
  String get sourceLabel => switch (source) {
    CartSource.textbook => '课本 · ${word.book} · ${word.unit}',
    CartSource.wrongWord => '错词本',
    CartSource.random => '随机抽取',
    CartSource.customDict => '自定义词典 · ${word.unit}',
  };
}
