import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/word_pair.dart';

/// 默写单词表 PDF 生成服务
///
/// 把购物车里选好的单词生成一份学生默写用纸：
/// 每个词显示默写提示（报中文 = 中文释义，报英文 = 英文单词），
/// 提示后面紧跟一条短横线供书写答案，每行排两个单词，省纸。
class DictationPdfService {
  /// 横线字符：全角下划线，字形连续无间隙
  static const String _lineChar = '＿';

  /// 每条横线的长度（全角字符个数）
  static const int _lineLen = 6;

  static ByteData? _fontCache;

  /// 加载内置中文字体（支持中文释义），只加载一次
  static Future<ByteData> _loadFont() async {
    return _fontCache ??= await rootBundle.load(
      'assets/fonts/NotoSansSC-Regular.ttf',
    );
  }

  /// 生成默写单词表 PDF
  ///
  /// [title] 默认「默写单词表」，[subtitle] 默认显示词数与生成时间。
  Future<Uint8List> buildWorksheet({
    required List<WordEntry> words,
    String title = '默写单词表',
    String? subtitle,
  }) async {
    final font = pw.Font.ttf(await _loadFont());
    final theme = pw.ThemeData.withFont(base: font, bold: font);
    final now = DateTime.now();

    final allCnToEn =
        words.isNotEmpty &&
        words.every((w) => w.direction == DictateDirection.cnToEn);
    final allEnToCn =
        words.isNotEmpty &&
        words.every((w) => w.direction == DictateDirection.enToCn);
    final mixedDirections = words.isNotEmpty && !allCnToEn && !allEnToCn;
    final directionHint = allCnToEn
        ? '要求：看中文释义，写出英文单词'
        : allEnToCn
        ? '要求：看英文单词，写出中文释义'
        : null;

    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 44, vertical: 38),
        theme: theme,
        // 词量多时（如全册 2569 词）会拆成很多页
        maxPages: 500,
        header: (ctx) => ctx.pageNumber > 1
            ? pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 8),
                child: pw.Row(
                  children: [
                    pw.Expanded(
                      child: pw.Text(
                        '$title（续）',
                        style: pw.TextStyle(
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                    pw.Text(
                      '共 ${words.length} 词',
                      style: pw.TextStyle(
                        fontSize: 9,
                        color: PdfColors.grey600,
                      ),
                    ),
                  ],
                ),
              )
            : pw.SizedBox.shrink(),
        footer: (ctx) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            '第 ${ctx.pageNumber} 页',
            style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          ),
        ),
        build: (ctx) => [
          ..._buildHeader(
            title: title,
            subtitle:
                subtitle ?? '共 ${words.length} 词 · 生成于 ${_formatDateTime(now)}',
            directionHint: directionHint,
          ),
          for (var i = 0; i < words.length; i += 2)
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: _buildEntry(
                    i,
                    words[i],
                    mixedDirections: mixedDirections,
                  ),
                ),
                pw.SizedBox(width: 24),
                pw.Expanded(
                  child: i + 1 < words.length
                      ? _buildEntry(
                          i + 1,
                          words[i + 1],
                          mixedDirections: mixedDirections,
                        )
                      : pw.SizedBox.shrink(),
                ),
              ],
            ),
        ],
      ),
    );
    return doc.save();
  }

  /// 首页抬头：标题 + 词数/时间 + 班级姓名日期填写栏
  List<pw.Widget> _buildHeader({
    required String title,
    required String subtitle,
    String? directionHint,
  }) {
    return [
      pw.Text(
        title,
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
      ),
      pw.SizedBox(height: 6),
      pw.Text(
        subtitle,
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
      ),
      if (directionHint != null) ...[
        pw.SizedBox(height: 3),
        pw.Text(
          directionHint,
          textAlign: pw.TextAlign.center,
          style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
        ),
      ],
      pw.SizedBox(height: 14),
      pw.Row(
        children: [
          for (final label in const ['班级', '姓名', '日期'])
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    label,
                    style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                  ),
                  pw.Container(
                    margin: const pw.EdgeInsets.only(top: 2),
                    width: 92,
                    height: 14,
                    decoration: const pw.BoxDecoration(
                      border: pw.Border(bottom: pw.BorderSide(width: 0.8)),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      pw.SizedBox(height: 8),
      pw.Divider(height: 1, thickness: 1.2),
      pw.SizedBox(height: 10),
    ];
  }

  /// 单个默写条目：序号 + 提示内容，下方一条横线供书写
  pw.Widget _buildEntry(
    int index,
    WordEntry word, {
    required bool mixedDirections,
  }) {
    final suffix = mixedDirections
        ? word.direction == DictateDirection.cnToEn
              ? '（写英文）'
              : '（写中文）'
        : null;
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 12),
      child: pw.RichText(
        text: pw.TextSpan(
          text: '${index + 1}. ${word.prompt}',
          style: pw.TextStyle(fontSize: 12),
          children: [
            if (suffix != null)
              pw.TextSpan(
                text: '  $suffix',
                style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
              ),
            // 横线紧跟内容，同一行，长度固定
            pw.TextSpan(text: '  ${_lineChar * _lineLen}'),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${dt.year}-${two(dt.month)}-${two(dt.day)} '
        '${two(dt.hour)}:${two(dt.minute)}';
  }
}
