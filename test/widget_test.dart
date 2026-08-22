import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:english_reciting/screens/home_screen.dart';

void _noop() {}

void main() {
  testWidgets('Home screen renders entry options', (WidgetTester tester) async {
    await tester.pumpWidget(
      CupertinoApp(
        home: HomeScreen(
          onBuiltIn: _noop,
          onCustom: _noop,
          onWrongWords: _noop,
          onOpenGithub: _noop,
        ),
      ),
    );

    // 显示标题
    expect(find.text('英语默写助手'), findsWidgets);

    // 显示三个入口：教材 / 错词本 / 自定义词典
    expect(find.text('人教版教材'), findsOneWidget);
    expect(find.text('错词本'), findsOneWidget);
    expect(find.text('自定义词典'), findsOneWidget);

    // 显示 GitHub 求 Star 链接
    expect(find.text('如果对您有帮助，希望给我一个 Star'), findsOneWidget);
  });
}
