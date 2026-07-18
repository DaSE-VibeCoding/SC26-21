import 'package:flutter_test/flutter_test.dart';

import 'package:learn/app.dart';

void main() {
  testWidgets('YuXin app renders the main shell', (WidgetTester tester) async {
    await tester.pumpWidget(const YuXinApp());
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('YuXin AI'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Chat'), findsOneWidget);
    expect(find.text('Rescue'), findsOneWidget);
    expect(find.text('Memory'), findsOneWidget);
  });
}
