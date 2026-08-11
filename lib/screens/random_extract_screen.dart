import 'package:flutter/cupertino.dart';
import '../models/cart.dart';
import '../models/word_pair.dart';
import '../services/cart_service.dart';
import '../services/custom_dict_service.dart';
import '../services/vocabulary_service.dart';
import '../services/wrong_word_service.dart';

/// 抽取来源类型
enum ExtractSource { textbook, customDict, wrongWord }

/// 随机抽取页 —— 从课本/自定义词典/错词本随机抽取，勾选想要的部分加入默写单词表
class RandomExtractScreen extends StatefulWidget {
  final VocabularyService vocab;
  final CustomDictService custom;
  final WrongWordService wrong;
  final CartService cart;
  final ExtractSource defaultSource;

  const RandomExtractScreen({
    super.key,
    required this.vocab,
    required this.custom,
    required this.wrong,
    required this.cart,
    this.defaultSource = ExtractSource.textbook,
  });

  @override
  State<RandomExtractScreen> createState() => _RandomExtractScreenState();
}

class _RandomExtractScreenState extends State<RandomExtractScreen> {
  final _countController = TextEditingController(text: '20');
  List<WordEntry> _drawn = [];
  final Set<String> _picked = {}; // 已勾选要加入默写单词表的英文

  late ExtractSource _source = widget.defaultSource;

  bool _selectAll = true; // 课本：默认全部
  final Set<String> _selected = {}; // 课本：手动选中的单元 key: "book|unit"

  bool _selectAllDicts = true; // 自定义词典：默认全部
  final Set<String> _selectedDicts = {}; // 自定义词典：选中的词表名

  bool _selectAllWrong = true; // 错词本：默认全部
  final Set<String> _selectedWrong = {}; // 错词本：选中的错词本名

  VocabularyService get _v => widget.vocab;

  @override
  void dispose() {
    _countController.dispose();
    super.dispose();
  }

  int get _pickedCount => _picked.length;

  /// 当前抽取范围内的单词池
  List<WordEntry> get _pool {
    switch (_source) {
      case ExtractSource.textbook:
        if (_selectAll) return _v.allWords;
        final keys = _selected;
        return _v.allWords
            .where((w) => keys.contains('${w.book}|${w.unit}'))
            .toList();
      case ExtractSource.customDict:
        final names = _selectAllDicts
            ? widget.custom.dicts.map((d) => d.name).toSet()
            : _selectedDicts;
        return widget.custom.dicts
            .where((d) => names.contains(d.name))
            .expand((d) => d.words)
            .toList();
      case ExtractSource.wrongWord:
        final names = _selectAllWrong
            ? widget.wrong.books.map((b) => b.name).toSet()
            : _selectedWrong;
        return widget.wrong.books
            .where((b) => names.contains(b.name))
            .expand((b) => b.words)
            .toList();
    }
  }

  int get _poolCount => _pool.length;

  /// 抽取范围摘要文案
  String get _rangeSummary {
    switch (_source) {
      case ExtractSource.textbook:
        return _selectAll
            ? '全部课本 · 共 $_poolCount 词'
            : '已选 ${_selected.length} 个单元 · 共 $_poolCount 词';
      case ExtractSource.customDict:
        return _selectAllDicts
            ? '全部自定义词典 · 共 $_poolCount 词'
            : '已选 ${_selectedDicts.length} 个词典 · 共 $_poolCount 词';
      case ExtractSource.wrongWord:
        return _selectAllWrong
            ? '全部错词本 · 共 $_poolCount 词'
            : '已选 ${_selectedWrong.length} 个错词本 · 共 $_poolCount 词';
    }
  }

  /// 打开抽取范围选择（课本/自定义词典/错词本）
  void _openRangePicker() {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => _RangePickerSheet(
        vocab: _v,
        custom: widget.custom,
        wrong: widget.wrong,
        source: _source,
        selectAll: _selectAll,
        selected: _selected,
        selectAllDicts: _selectAllDicts,
        selectedDicts: _selectedDicts,
        selectAllWrong: _selectAllWrong,
        selectedWrong: _selectedWrong,
        onDone: (
          source,
          selectAll,
          selected,
          selectAllDicts,
          selectedDicts,
          selectAllWrong,
          selectedWrong,
        ) {
          setState(() {
            _source = source;
            _selectAll = selectAll;
            _selected
              ..clear()
              ..addAll(selected);
            _selectAllDicts = selectAllDicts;
            _selectedDicts
              ..clear()
              ..addAll(selectedDicts);
            _selectAllWrong = selectAllWrong;
            _selectedWrong
              ..clear()
              ..addAll(selectedWrong);
            _drawn = [];
            _picked.clear();
          });
        },
      ),
    );
  }

  /// 抽取一批随机单词（从已选范围内）
  void _draw() {
    final n = int.tryParse(_countController.text.trim()) ?? 0;
    if (n <= 0) return;
    final pool = List<WordEntry>.of(_pool);
    if (pool.isEmpty) return;
    pool.shuffle();
    setState(() {
      _drawn = pool.take(n).toList();
      // 抽取的单词默认全部勾选，方便一键加入购物车
      _picked
        ..clear()
        ..addAll(_drawn.map((w) => w.english));
    });
  }

  /// 把勾选的单词加入购物车（来源：随机抽取）
  void _addPickedToCart() {
    final selected = _drawn.where((w) => _picked.contains(w.english)).toList();
    if (selected.isEmpty) return;
    widget.cart.addAll(selected, CartSource.random);
    setState(() => _picked.clear());
    showCupertinoDialog<void>(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('已加入默写单词表'),
        content: Text('${selected.length} 个单词已加入默写单词表（来源：随机抽取）'),
        actions: [
          CupertinoDialogAction(
            child: const Text('好的'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalInCart = widget.cart.count;

    return Column(
      children: [
        // 抽取范围：选择从哪些课本/单元抽取
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _openRangePicker,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: CupertinoColors.secondarySystemBackground.resolveFrom(
                  context,
                ),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: CupertinoColors.systemGrey5),
              ),
              child: Row(
                children: [
                  const Icon(
                    CupertinoIcons.line_horizontal_3_decrease,
                    size: 16,
                    color: CupertinoColors.activeBlue,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    '抽取范围',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _rangeSummary,
                      style: const TextStyle(
                        fontSize: 12,
                        color: CupertinoColors.secondaryLabel,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(
                    CupertinoIcons.chevron_down,
                    size: 14,
                    color: CupertinoColors.systemGrey3,
                  ),
                ],
              ),
            ),
          ),
        ),

        // 控制栏：数量 + 抽取按钮
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
          child: Row(
            children: [
              const Text('抽取', style: TextStyle(fontSize: 14)),
              const SizedBox(width: 8),
              SizedBox(
                width: 64,
                child: CupertinoTextField(
                  controller: _countController,
                  placeholder: '数量',
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  padding: const EdgeInsets.symmetric(
                    vertical: 6,
                    horizontal: 8,
                  ),
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              const SizedBox(width: 6),
              const Text('词', style: TextStyle(fontSize: 14)),
              const Spacer(),
              CupertinoButton.filled(
                onPressed: _poolCount > 0 ? _draw : null,
                child: const Text('随机抽取'),
              ),
            ],
          ),
        ),

        // 提示
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Text(
            _drawn.isEmpty
                ? '设置抽取数量后点击「随机抽取」，再勾选想要加入默写单词表的单词'
                : '已抽取 ${_drawn.length} 词（默认全选），可点击取消勾选',
            style: const TextStyle(
              fontSize: 12,
              color: CupertinoColors.secondaryLabel,
            ),
          ),
        ),

        // 抽取结果列表
        Expanded(
          child: _drawn.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        CupertinoIcons.shuffle,
                        size: 48,
                        color: CupertinoColors.systemGrey3,
                      ),
                      SizedBox(height: 12),
                      Text(
                        '还没有抽取单词',
                        style: TextStyle(
                          fontSize: 15,
                          color: CupertinoColors.secondaryLabel,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  itemCount: _drawn.length,
                  itemBuilder: (_, i) {
                    final w = _drawn[i];
                    final picked = _picked.contains(w.english);
                    final inCart = widget.cart.contains(w);

                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        setState(() {
                          picked
                              ? _picked.remove(w.english)
                              : _picked.add(w.english);
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: picked
                                ? CupertinoColors.activeBlue.withAlpha(14)
                                : CupertinoColors.secondarySystemBackground
                                      .resolveFrom(context),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: picked
                                  ? CupertinoColors.activeBlue.withAlpha(90)
                                  : CupertinoColors.systemGrey5,
                              width: picked ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                picked
                                    ? CupertinoIcons.checkmark_circle_fill
                                    : CupertinoIcons.circle,
                                size: 20,
                                color: picked
                                    ? CupertinoColors.activeBlue
                                    : CupertinoColors.systemGrey4,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      w.english,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      w.chinese,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: CupertinoColors.secondaryLabel,
                                      ),
                                    ),
                                    Text(
                                      '${w.book} · ${w.unit}',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: CupertinoColors.systemGrey3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (inCart)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: CupertinoColors.systemGreen
                                        .withAlpha(30),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    '已在默写单词表',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: CupertinoColors.systemGreen,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),

        // 底部：加入购物车
        if (_drawn.isNotEmpty)
          Container(
            decoration: BoxDecoration(
              color: CupertinoColors.secondarySystemBackground.resolveFrom(
                context,
              ),
              border: Border(
                top: BorderSide(color: CupertinoColors.systemGrey5),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: CupertinoButton.filled(
                      onPressed: _pickedCount > 0 ? _addPickedToCart : null,
                      child: Text(
                        _pickedCount > 0
                            ? '加入默写单词表（$_pickedCount 词）'
                            : '勾选单词后加入默写单词表',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '默写单词表共 $totalInCart 词',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// 抽取范围选择弹层 —— 选择来源（课本/自定义词典/错词本）及范围内的具体项
class _RangePickerSheet extends StatefulWidget {
  final VocabularyService vocab;
  final CustomDictService custom;
  final WrongWordService wrong;
  final ExtractSource source;
  final bool selectAll;
  final Set<String> selected;
  final bool selectAllDicts;
  final Set<String> selectedDicts;
  final bool selectAllWrong;
  final Set<String> selectedWrong;
  final void Function(
    ExtractSource source,
    bool selectAll,
    Set<String> selected,
    bool selectAllDicts,
    Set<String> selectedDicts,
    bool selectAllWrong,
    Set<String> selectedWrong,
  )
  onDone;

  const _RangePickerSheet({
    required this.vocab,
    required this.custom,
    required this.wrong,
    required this.source,
    required this.selectAll,
    required this.selected,
    required this.selectAllDicts,
    required this.selectedDicts,
    required this.selectAllWrong,
    required this.selectedWrong,
    required this.onDone,
  });

  @override
  State<_RangePickerSheet> createState() => _RangePickerSheetState();
}

class _RangePickerSheetState extends State<_RangePickerSheet> {
  late ExtractSource _source = widget.source;
  late bool _selectAll = widget.selectAll;
  late final Set<String> _selected = Set.of(widget.selected);
  late bool _selectAllDicts = widget.selectAllDicts;
  late final Set<String> _selectedDicts = Set.of(widget.selectedDicts);
  late bool _selectAllWrong = widget.selectAllWrong;
  late final Set<String> _selectedWrong = Set.of(widget.selectedWrong);
  final Set<String> _expandedBooks = {};

  VocabularyService get _v => widget.vocab;

  // ── 课本来源 ──
  bool _unitSelected(String book, String unit) =>
      _selectAll || _selected.contains('$book|$unit');

  bool _bookFully(String book) =>
      _v.unitsOfBook(book).every((u) => _unitSelected(book, u.unit));

  bool _bookPartial(String book) =>
      _v.unitsOfBook(book).any((u) => _unitSelected(book, u.unit));

  void _toggleAll() {
    setState(() {
      _selectAll = !_selectAll;
      if (_selectAll) _selected.clear();
    });
  }

  void _toggleUnit(String book, String unit) {
    setState(() {
      if (_selectAll) {
        _selectAll = false;
        _selected
          ..clear()
          ..add('$book|$unit');
      } else {
        final key = '$book|$unit';
        _selected.contains(key) ? _selected.remove(key) : _selected.add(key);
      }
    });
  }

  void _toggleBook(String book) {
    setState(() {
      final keys = _v.unitsOfBook(book).map((u) => '$book|${u.unit}').toSet();
      if (_selectAll) {
        _selectAll = false;
        _selected
          ..clear()
          ..addAll(keys);
      } else if (_bookFully(book)) {
        _selected.removeAll(keys);
      } else {
        _selected.addAll(keys);
      }
    });
  }

  void _toggleExpand(String book) {
    setState(() {
      _expandedBooks.contains(book)
          ? _expandedBooks.remove(book)
          : _expandedBooks.add(book);
    });
  }

  // ── 自定义词典来源 ──
  void _toggleAllDicts() {
    setState(() {
      _selectAllDicts = !_selectAllDicts;
      if (_selectAllDicts) _selectedDicts.clear();
    });
  }

  void _toggleDict(String name) {
    setState(() {
      if (_selectAllDicts) {
        _selectAllDicts = false;
        _selectedDicts
          ..clear()
          ..add(name);
      } else {
        _selectedDicts.contains(name)
            ? _selectedDicts.remove(name)
            : _selectedDicts.add(name);
      }
    });
  }

  // ── 错词本来源 ──
  void _toggleAllWrong() {
    setState(() {
      _selectAllWrong = !_selectAllWrong;
      if (_selectAllWrong) _selectedWrong.clear();
    });
  }

  void _toggleWrongBook(String name) {
    setState(() {
      if (_selectAllWrong) {
        _selectAllWrong = false;
        _selectedWrong
          ..clear()
          ..add(name);
      } else {
        _selectedWrong.contains(name)
            ? _selectedWrong.remove(name)
            : _selectedWrong.add(name);
      }
    });
  }

  void _confirm() {
    widget.onDone(
      _source,
      _selectAll,
      _selected,
      _selectAllDicts,
      _selectedDicts,
      _selectAllWrong,
      _selectedWrong,
    );
    Navigator.of(context).pop();
  }

  bool get _canConfirm => switch (_source) {
    ExtractSource.textbook => _selectAll || _selected.isNotEmpty,
    ExtractSource.customDict => _selectAllDicts || _selectedDicts.isNotEmpty,
    ExtractSource.wrongWord => _selectAllWrong || _selectedWrong.isNotEmpty,
  };

  String get _confirmLabel => switch (_source) {
    ExtractSource.textbook =>
      _selectAll ? '使用全部课本' : '使用已选 ${_selected.length} 个单元',
    ExtractSource.customDict =>
      _selectAllDicts ? '使用全部自定义词典' : '使用已选 ${_selectedDicts.length} 个词典',
    ExtractSource.wrongWord => _selectAllWrong
        ? '使用全部错词本（${widget.wrong.count} 词）'
        : '使用已选 ${_selectedWrong.length} 个错词本',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 520,
      decoration: const BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      child: Column(
        children: [
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: CupertinoColors.systemGrey4,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Text(
                '选择抽取范围',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: const Icon(
                  CupertinoIcons.xmark,
                  size: 18,
                  color: CupertinoColors.secondaryLabel,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '选择从哪里随机抽取单词',
              style: TextStyle(
                fontSize: 11,
                color: CupertinoColors.secondaryLabel,
              ),
            ),
          ),
          const SizedBox(height: 10),
          // 来源切换
          CupertinoSegmentedControl<ExtractSource>(
            groupValue: _source,
            onValueChanged: (v) => setState(() => _source = v),
            children: const {
              ExtractSource.textbook: Text('课本'),
              ExtractSource.customDict: Text('自定义'),
              ExtractSource.wrongWord: Text('错词本'),
            },
          ),
          const SizedBox(height: 12),
          Expanded(child: _buildSourceBody()),
          const SizedBox(height: 10),
          CupertinoButton.filled(
            onPressed: _canConfirm ? _confirm : null,
            child: Text(_confirmLabel),
          ),
        ],
      ),
    );
  }

  Widget _buildSourceBody() {
    switch (_source) {
      case ExtractSource.textbook:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _allToggleRow(
              selected: _selectAll,
              title: '全部课本',
              count: '${_v.allWords.length} 词',
              onTap: _toggleAll,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                children: [for (final book in _v.books) _bookTile(book)],
              ),
            ),
          ],
        );
      case ExtractSource.customDict:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _allToggleRow(
              selected: _selectAllDicts,
              title: '全部自定义词典',
              count: '${widget.custom.dicts.fold(0, (s, d) => s + d.count)} 词',
              onTap: _toggleAllDicts,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: widget.custom.dicts.isEmpty
                  ? const Center(
                      child: Text(
                        '还没有自定义词典',
                        style: TextStyle(
                          fontSize: 13,
                          color: CupertinoColors.secondaryLabel,
                        ),
                      ),
                    )
                  : ListView(
                      children: [
                        for (final d in widget.custom.dicts) _dictTile(d),
                      ],
                    ),
            ),
          ],
        );
      case ExtractSource.wrongWord:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _allToggleRow(
              selected: _selectAllWrong,
              title: '全部错词本',
              count: '${widget.wrong.count} 词',
              onTap: _toggleAllWrong,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: widget.wrong.books.isEmpty
                  ? const Center(
                      child: Text(
                        '还没有错词本',
                        style: TextStyle(
                          fontSize: 13,
                          color: CupertinoColors.secondaryLabel,
                        ),
                      ),
                    )
                  : ListView(
                      children: [
                        for (final b in widget.wrong.books)
                          _wrongBookTile(b),
                      ],
                    ),
            ),
          ],
        );
    }
  }

  Widget _allToggleRow({
    required bool selected,
    required String title,
    required String count,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: CupertinoColors.secondarySystemBackground.resolveFrom(context),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected
                ? CupertinoColors.activeBlue.withAlpha(90)
                : CupertinoColors.systemGrey5,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected
                  ? CupertinoIcons.checkmark_circle_fill
                  : CupertinoIcons.circle,
              size: 20,
              color: selected
                  ? CupertinoColors.activeBlue
                  : CupertinoColors.systemGrey4,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              count,
              style: const TextStyle(
                fontSize: 12,
                color: CupertinoColors.secondaryLabel,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dictTile(CustomDict d) {
    final sel = _selectAllDicts || _selectedDicts.contains(d.name);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _toggleDict(d.name),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
        child: Row(
          children: [
            Icon(
              sel
                  ? CupertinoIcons.checkmark_circle_fill
                  : CupertinoIcons.circle,
              size: 18,
              color: sel
                  ? CupertinoColors.activeBlue
                  : CupertinoColors.systemGrey4,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                d.name,
                style: TextStyle(
                  fontSize: 14,
                  color: sel ? null : CupertinoColors.systemGrey,
                ),
              ),
            ),
            Text(
              '${d.count} 词',
              style: const TextStyle(
                fontSize: 12,
                color: CupertinoColors.secondaryLabel,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _wrongBookTile(WrongBook b) {
    final sel = _selectAllWrong || _selectedWrong.contains(b.name);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _toggleWrongBook(b.name),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
        child: Row(
          children: [
            Icon(
              sel
                  ? CupertinoIcons.checkmark_circle_fill
                  : CupertinoIcons.circle,
              size: 18,
              color: sel
                  ? CupertinoColors.activeBlue
                  : CupertinoColors.systemGrey4,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                b.name,
                style: TextStyle(
                  fontSize: 14,
                  color: sel ? null : CupertinoColors.systemGrey,
                ),
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
    );
  }

  Widget _bookTile(String book) {
    final fully = _bookFully(book);
    final partial = _bookPartial(book);
    final expanded = _expandedBooks.contains(book);
    final units = _v.unitsOfBook(book);
    final total = units.fold(0, (s, u) => s + u.wordCount);

    IconData icon;
    if (fully) {
      icon = CupertinoIcons.checkmark_circle_fill;
    } else if (partial) {
      icon = CupertinoIcons.circle_lefthalf_fill;
    } else {
      icon = CupertinoIcons.circle;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _toggleExpand(book),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => _toggleBook(book),
                  child: Icon(
                    icon,
                    size: 20,
                    color: fully || partial
                        ? CupertinoColors.activeBlue
                        : CupertinoColors.systemGrey4,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    book,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  '$total 词',
                  style: const TextStyle(
                    fontSize: 12,
                    color: CupertinoColors.secondaryLabel,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  expanded
                      ? CupertinoIcons.chevron_up
                      : CupertinoIcons.chevron_down,
                  size: 14,
                  color: CupertinoColors.systemGrey3,
                ),
              ],
            ),
          ),
        ),
        if (expanded)
          ...units.map((u) {
            final sel = _unitSelected(book, u.unit);
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _toggleUnit(book, u.unit),
              child: Padding(
                padding: const EdgeInsets.only(left: 30, top: 4, bottom: 4),
                child: Row(
                  children: [
                    Icon(
                      sel
                          ? CupertinoIcons.checkmark_circle_fill
                          : CupertinoIcons.circle,
                      size: 18,
                      color: sel
                          ? CupertinoColors.activeBlue
                          : CupertinoColors.systemGrey4,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        u.unit,
                        style: TextStyle(
                          fontSize: 14,
                          color: sel ? null : CupertinoColors.systemGrey,
                        ),
                      ),
                    ),
                    Text(
                      '${u.wordCount} 词',
                      style: const TextStyle(
                        fontSize: 12,
                        color: CupertinoColors.secondaryLabel,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }
}
