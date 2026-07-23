import 'package:flutter/cupertino.dart';

import 'models/word_pair.dart';
import 'services/tts_service.dart';
import 'services/vocabulary_service.dart';
import 'services/wrong_word_service.dart';
import 'screens/home_screen.dart';
import 'screens/book_selection_screen.dart';
import 'screens/unit_detail_screen.dart';
import 'screens/player_screen.dart';
import 'screens/dictation_result_screen.dart';
import 'screens/wrong_word_screen.dart';

void main() => runApp(const DictationApp());

class DictationApp extends StatelessWidget {
  const DictationApp({super.key});

  @override
  Widget build(BuildContext context) =>
      const CupertinoApp(title: '英语默写助手', home: DictationCoordinator());
}

enum AppPhase { home, bookSelection, unitDetail, player, result, wrongWords }

class DictationCoordinator extends StatefulWidget {
  const DictationCoordinator({super.key});

  @override
  State<DictationCoordinator> createState() => _DictationCoordinatorState();
}

class _DictationCoordinatorState extends State<DictationCoordinator> {
  final _tts = TtsService();
  final _vocab = VocabularyService();
  final _wrong = WrongWordService();
  AppPhase _phase = AppPhase.home;
  List<WordEntry> _dictationWords = [];
  bool _ready = false;
  String _detailBook = '';
  String _detailUnit = '';

  @override
  void initState() {
    super.initState();
    _tts.init().then((_) {
      _vocab.load().then((_) {
        if (mounted) setState(() => _ready = true);
      });
    });
  }

  @override
  void dispose() {
    _tts.dispose();
    super.dispose();
  }

  void _goBuiltIn() => setState(() => _phase = AppPhase.bookSelection);
  void _goCustom() {}
  void _goWrongWords() => setState(() => _phase = AppPhase.wrongWords);

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
    _dictationWords = words;
    setState(() => _phase = AppPhase.player);
  }

  void _onPlayerComplete() {
    setState(() => _phase = AppPhase.result);
  }

  void _reset() {
    _tts.stop();
    _vocab.resetSelection();
    setState(() {
      _phase = AppPhase.home;
      _dictationWords = [];
    });
  }

  String get _title {
    switch (_phase) {
      case AppPhase.home:
        return '英语默写助手';
      case AppPhase.bookSelection:
        return '选择课本和单元';
      case AppPhase.unitDetail:
        return _detailUnit;
      case AppPhase.player:
        return '默写中 ${(_dictationWords.isNotEmpty ? '1' : '0')}/${_dictationWords.length}';
      case AppPhase.result:
        return '默写完成';
      case AppPhase.wrongWords:
        return '错词本';
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(_title),
        leading: _phase == AppPhase.unitDetail
            ? GestureDetector(
                onTap: _backToBookSelection,
                child: const Icon(CupertinoIcons.chevron_back),
              )
            : _phase == AppPhase.wrongWords
            ? GestureDetector(
                onTap: () => setState(() => _phase = AppPhase.home),
                child: const Icon(CupertinoIcons.chevron_back),
              )
            : null,
        trailing:
            _phase == AppPhase.bookSelection ||
                _phase == AppPhase.unitDetail ||
                _phase == AppPhase.result
            ? GestureDetector(
                onTap: _reset,
                child: const Icon(CupertinoIcons.home),
              )
            : null,
      ),
      child: SafeArea(child: _buildBody()),
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
          onEnterUnit: _enterUnit,
          onStartDictation: _startDictation,
        );
      case AppPhase.unitDetail:
        return UnitDetailScreen(
          vocab: _vocab,
          book: _detailBook,
          unit: _detailUnit,
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
          onBackToSelect: _backToBookSelection,
          onBackHome: _reset,
        );
      case AppPhase.wrongWords:
        return WrongWordScreen(wrongWordService: _wrong, tts: _tts);
    }
  }
}
