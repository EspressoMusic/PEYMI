import 'package:bakery_shop_app/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Bakery opens in English by default', (WidgetTester tester) async {
    await tester.pumpWidget(const BakeryApp());
    await tester.pump();

    expect(find.text('Menu'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
  });
}
