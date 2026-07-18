import 'package:flutter_test/flutter_test.dart';

import 'package:learn/app.dart';

void main() {
  testWidgets('YuXin app renders core navigation', (WidgetTester tester) async {
    await tester.pumpWidget(const YuXinApp());
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('愈芯 AI'), findsOneWidget);
    expect(find.text('首页'), findsOneWidget);
    expect(find.text('聊天'), findsOneWidget);
    expect(find.text('记录'), findsOneWidget);
    expect(find.text('通用陪伴'), findsOneWidget);
  });
}
