import 'package:flutter_test/flutter_test.dart';
import 'package:app_gastos/main.dart';

void main() {
  testWidgets('App renders splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const GastosApp());
    expect(find.text('App Gastos'), findsOneWidget);
  });
}
