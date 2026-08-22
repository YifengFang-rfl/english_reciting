// ─── 默写方向枚举 ────────────────────────────────────────

enum DictateDirection {
  /// 报中文：朗读中文发音 → 学生写英文拼写
  cnToEn,

  /// 报英文：朗读英文发音 → 学生写中文释义
  enToCn,
}

// ─── 单词对模型 ──────────────────────────────────────────

class WordPair {
  final String english;
  final String chinese;
  DictateDirection direction;

  WordPair({
    required this.english,
    required this.chinese,
    this.direction = DictateDirection.cnToEn,
  });

  /// 当前题目的提示内容
  String get prompt => direction == DictateDirection.cnToEn ? chinese : english;

  /// 当前题目的正确答案
  String get answer => direction == DictateDirection.cnToEn ? english : chinese;

  /// 从 vocabulary_rj_s.json 的条目构造
  factory WordPair.fromVocabularyJson(Map<String, dynamic> json) {
    final meanings = json['meanings'] as List<dynamic>;
    final first = meanings.first as Map<String, dynamic>;
    final chinese = first['chinese'] as String;
    return WordPair(english: json['english'] as String, chinese: chinese);
  }
}

// ─── 带课本/单元信息的单词条目 ────────────────────────────

class WordEntry extends WordPair {
  final String book;
  final String unit;

  WordEntry({
    required this.book,
    required this.unit,
    required super.english,
    required super.chinese,
    super.direction = DictateDirection.cnToEn,
  });

  factory WordEntry.fromVocabularyJson(Map<String, dynamic> json) {
    final meanings = json['meanings'] as List<dynamic>;
    // 拼接所有释义："n. 交换；交流  |  vt. 交换；交易"
    final texts = meanings
        .map((m) {
          final pos = (m as Map<String, dynamic>)['pos'] as String;
          final cn = m['chinese'] as String;
          return '$pos $cn';
        })
        .join('  |  ');
    return WordEntry(
      book: json['book'] as String,
      unit: json['unit'] as String,
      english: json['english'] as String,
      chinese: texts,
    );
  }
}
