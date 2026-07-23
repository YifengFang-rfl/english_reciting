import 'package:flutter_test/flutter_test.dart';

import 'package:english_reciting/main.dart';

void main() {
  testWidgets('App renders input screen by default', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const DictationApp());

    // 默认进入输入页面，显示标题
    expect(find.text('输入单词'), findsOneWidget);

    // 显示输入提示
    expect(find.text('下一步：选择默写方向'), findsOneWidget);
  });
}
