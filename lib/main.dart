import 'package:flutter/cupertino.dart';
import 'package:printing/printing.dart';

import 'models/word_pair.dart';
import 'services/cart_service.dart';
import 'services/custom_dict_service.dart';
import 'services/dictation_pdf_service.dart';
import 'services/tts_service.dart';
import 'services/vocabulary_service.dart';
import 'services/wrong_word_service.dart';
import 'screens/home_screen.dart';
import 'screens/book_selection_screen.dart';
import 'screens/custom_dict_detail_screen.dart';
import 'screens/custom_dict_screen.dart';
import 'screens/random_extract_screen.dart';
import 'screens/unit_detail_screen.dart';
import 'screens/player_screen.dart';
import 'screens/dictation_result_screen.dart';
import 'screens/wrong_book_detail_screen.dart';
import 'screens/wrong_word_screen.dart';
import 'widgets/cart_widgets.dart';
import 'widgets/random_extract_button.dart';

void main() => runApp(const DictationApp());

class DictationApp extends StatelessWidget {
  const DictationApp({super.key});

  @override
  Widget build(BuildContext context) => const CupertinoApp(
    title: '英语听写',
    // 界面按浅色设计，强制浅色模式，避免系统深色模式下文字/背景对比度不足看不清
    theme: CupertinoThemeData(brightness: Brightness.light),
    home: DictationCoordinator(),
  );
}

enum AppPhase {
  home,
  bookSelection,
  unitDetail,
  randomExtract,
  customDict,
  customDictDetail,
  player,
  result,
  wrongWords,
  wrongBookDetail,
}

class DictationCoordinator extends StatefulWidget {
  const DictationCoordinator({super.key});

  @override
  State<DictationCoordinator> createState() => _DictationCoordinatorState();
}

class _DictationCoordinatorState extends State<DictationCoordinator> {
  final _tts = TtsService();
  final _vocab = VocabularyService();
  final _wrong = WrongWordService();
  final _cart = CartService();
  final _custom = CustomDictService();
  final _pdf = DictationPdfService();
  AppPhase _phase = AppPhase.home;
  List<WordEntry> _dictationWords = [];
  bool _ready = false;
  String _detailBook = '';
  String _detailUnit = '';
  String _detailDictName = '';
  String _detailWrongBook = '';
  ExtractSource _randomDefaultSource = ExtractSource.textbook;
  AppPhase _randomExtractOrigin = AppPhase.bookSelection;

  @override
  void initState() {
    super.initState();
    _tts.init().then((_) {
      _vocab.load().then((_) {
        if (mounted) setState(() => _ready = true);
      });
      _custom.load();
      _wrong.load();
    });
  }

  @override
  void dispose() {
    _tts.dispose();
    super.dispose();
  }

  void _goBuiltIn() => setState(() => _phase = AppPhase.bookSelection);
  void _goCustom() => setState(() => _phase = AppPhase.customDict);
  void _goWrongWords() => setState(() => _phase = AppPhase.wrongWords);

  /// 进入某个错词本详情
  void _openWrongBook(String name) {
    _detailWrongBook = name;
    setState(() => _phase = AppPhase.wrongBookDetail);
  }

  /// 从错词本详情返回错词本列表
  void _backToWrongBooks() {
    _tts.stop();
    setState(() => _phase = AppPhase.wrongWords);
  }

  void _goRandomExtract() =>
      _goRandomExtractWith(ExtractSource.textbook, AppPhase.bookSelection);

  /// 进入随机抽取页并设置默认来源与返回目标
  void _goRandomExtractWith(ExtractSource source, AppPhase origin) {
    _randomDefaultSource = source;
    _randomExtractOrigin = origin;
    setState(() => _phase = AppPhase.randomExtract);
  }

  void _goRandomFromWrong() =>
      _goRandomExtractWith(ExtractSource.wrongWord, AppPhase.wrongWords);
  void _goRandomFromCustom() =>
      _goRandomExtractWith(ExtractSource.customDict, AppPhase.customDict);

  /// 从随机抽取页返回进入前的界面
  void _backFromRandomExtract() {
    _tts.stop();
    setState(() => _phase = _randomExtractOrigin);
  }

  void _openCustomDict(String name) {
    _detailDictName = name;
    setState(() => _phase = AppPhase.customDictDetail);
  }

  void _backToCustomDictList() {
    _tts.stop();
    setState(() => _phase = AppPhase.customDict);
  }

  void _enterUnit(String book, String unit) {
    _detailBook = book;
    _detailUnit = unit;
    setState(() => _phase = AppPhase.unitDetail);
  }

  void _backToBookSelection() {
    _tts.stop();
    setState(() => _phase = AppPhase.bookSelection);
  }

  void _startDictation(List<WordEntry> words) {
    if (words.isEmpty) return;
    _dictationWords = words;
    setState(() => _phase = AppPhase.player);
  }

  /// 打开全局购物车
  void _openCart() {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => CartSheet(
        items: _cart.items,
        onRemove: (item) {
          _cart.removeItem(item);
          setState(() {});
        },
        onCheckout: () {
          Navigator.of(ctx).pop();
          _startDictation(_cart.words);
        },
        onClearAll: _cart.clear,
        onExportPdf: (items) =>
            _exportDictationPdf(items.map((e) => e.word).toList()),
      ),
    );
  }

  /// 生成并分享默写单词表 PDF（关闭购物车弹层后执行）
  Future<void> _exportDictationPdf(List<WordEntry> words) async {
    if (words.isEmpty || !mounted) return;

    showCupertinoDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const CupertinoAlertDialog(
        content: Row(
          children: [
            CupertinoActivityIndicator(),
            SizedBox(width: 16),
            Text('正在生成 PDF…'),
          ],
        ),
      ),
    );

    try {
      final bytes = await _pdf.buildWorksheet(words: words);
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop(); // 关闭生成中提示
      await Printing.sharePdf(
        bytes: bytes,
        filename: _pdfFileName(DateTime.now()),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop(); // 关闭生成中提示
      showCupertinoDialog<void>(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: const Text('导出失败'),
          content: Text('生成默写单词表 PDF 时出错：$e'),
          actions: [
            CupertinoDialogAction(
              child: const Text('好的'),
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
      );
    }
  }

  String _pdfFileName(DateTime now) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '默写单词表_${now.year}${two(now.month)}${two(now.day)}'
        '_${two(now.hour)}${two(now.minute)}.pdf';
  }

  void _onPlayerComplete() {
    setState(() => _phase = AppPhase.result);
  }

  /// 返回首页（保留购物车，方便继续从错词本等加入单词）
  void _goHome() {
    _tts.stop();
    setState(() => _phase = AppPhase.home);
  }

  String get _title {
    switch (_phase) {
      case AppPhase.home:
        return '英语听写';
      case AppPhase.bookSelection:
        return '选择课本和单元';
      case AppPhase.unitDetail:
        return _detailUnit;
      case AppPhase.randomExtract:
        return '随机抽取';
      case AppPhase.customDict:
        return '自定义词典';
      case AppPhase.customDictDetail:
        return _detailDictName;
      case AppPhase.player:
        return '默写中 ${(_dictationWords.isNotEmpty ? '1' : '0')}/${_dictationWords.length}';
      case AppPhase.result:
        return '默写完成';
      case AppPhase.wrongWords:
        return '错词本';
      case AppPhase.wrongBookDetail:
        return _detailWrongBook;
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(_title),
        leading: _phase == AppPhase.bookSelection
            ? GestureDetector(
                onTap: _goHome,
                child: const Icon(CupertinoIcons.chevron_back),
              )
            : _phase == AppPhase.randomExtract
            ? GestureDetector(
                onTap: _backFromRandomExtract,
                child: const Icon(CupertinoIcons.chevron_back),
              )
            : _phase == AppPhase.unitDetail
            ? GestureDetector(
                onTap: _backToBookSelection,
                child: const Icon(CupertinoIcons.chevron_back),
              )
            : _phase == AppPhase.customDictDetail
            ? GestureDetector(
                onTap: _backToCustomDictList,
                child: const Icon(CupertinoIcons.chevron_back),
              )
            : _phase == AppPhase.wrongBookDetail
            ? GestureDetector(
                onTap: _backToWrongBooks,
                child: const Icon(CupertinoIcons.chevron_back),
              )
            : _phase == AppPhase.customDict || _phase == AppPhase.wrongWords
            ? GestureDetector(
                onTap: () => setState(() => _phase = AppPhase.home),
                child: const Icon(CupertinoIcons.chevron_back),
              )
            : null,
        trailing: _phase == AppPhase.bookSelection
            ? RandomExtractButton(onPressed: _goRandomExtract)
            : _phase == AppPhase.customDict
            ? RandomExtractButton(onPressed: _goRandomFromCustom)
            : _phase == AppPhase.wrongWords
            ? RandomExtractButton(onPressed: _goRandomFromWrong)
            : null,
      ),
      child: SafeArea(
        child: Column(
          children: [
            Expanded(child: _buildBody()),
            // 全局购物车栏：有选词后才显示（首页 / 选书 / 选词 / 错词本）
            ListenableBuilder(
              listenable: _cart,
              builder: (context, _) {
                final showCart =
                    _cart.count > 0 &&
                    (_phase == AppPhase.home ||
                        _phase == AppPhase.bookSelection ||
                        _phase == AppPhase.unitDetail ||
                        _phase == AppPhase.randomExtract ||
                        _phase == AppPhase.customDict ||
                        _phase == AppPhase.customDictDetail ||
                        _phase == AppPhase.wrongWords ||
                        _phase == AppPhase.wrongBookDetail);
                if (!showCart) return const SizedBox.shrink();
                return CartBar(
                  count: _cart.count,
                  onOpenCart: _openCart,
                  onCheckout: () => _startDictation(_cart.words),
                  onExportPdf: () => _exportDictationPdf(_cart.words),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (!_ready) return const Center(child: CupertinoActivityIndicator());

    switch (_phase) {
      case AppPhase.home:
        return HomeScreen(
          onBuiltIn: _goBuiltIn,
          onCustom: _goCustom,
          onWrongWords: _goWrongWords,
          wrongWordCount: _wrong.count,
        );
      case AppPhase.bookSelection:
        return BookSelectionScreen(
          vocab: _vocab,
          cart: _cart,
          onEnterUnit: _enterUnit,
        );
      case AppPhase.unitDetail:
        return UnitDetailScreen(
          vocab: _vocab,
          cart: _cart,
          book: _detailBook,
          unit: _detailUnit,
        );
      case AppPhase.randomExtract:
        return RandomExtractScreen(
          vocab: _vocab,
          custom: _custom,
          wrong: _wrong,
          cart: _cart,
          defaultSource: _randomDefaultSource,
        );
      case AppPhase.customDict:
        return CustomDictScreen(service: _custom, onOpenDict: _openCustomDict);
      case AppPhase.customDictDetail:
        return CustomDictDetailScreen(
          service: _custom,
          cart: _cart,
          dictName: _detailDictName,
        );
      case AppPhase.player:
        return PlayerScreen(
          words: _dictationWords,
          tts: _tts,
          onExit: _backToBookSelection,
          onComplete: _onPlayerComplete,
        );
      case AppPhase.result:
        return DictationResultScreen(
          words: _dictationWords,
          wrongWordService: _wrong,
          onBackHome: _goHome,
        );
      case AppPhase.wrongWords:
        return WrongWordScreen(
          wrongWordService: _wrong,
          onOpenBook: _openWrongBook,
        );
      case AppPhase.wrongBookDetail:
        return WrongBookDetailScreen(
          wrongWordService: _wrong,
          cart: _cart,
          bookName: _detailWrongBook,
        );
    }
  }
}
