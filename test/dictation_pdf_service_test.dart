import 'package:flutter_test/flutter_test.dart';

import 'package:english_reciting/models/word_pair.dart';
import 'package:english_reciting/services/dictation_pdf_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('生成默写单词表 PDF', () async {
    final words = [
      WordEntry(
        book: '必修一',
        unit: 'Unit 1',
        english: 'exchange',
        chinese: 'n. 交换；交流  |  vt. 交换；交易',
        direction: DictateDirection.cnToEn,
      ),
      WordEntry(
        book: '必修一',
        unit: 'Unit 1',
        english: 'lecture',
        chinese: 'n. 讲座；讲课；教训',
        direction: DictateDirection.enToCn,
      ),
    ];

    final bytes = await DictationPdfService().buildWorksheet(words: words);

    expect(bytes.length, greaterThan(1000));
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
  });
}
