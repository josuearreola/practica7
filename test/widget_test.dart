import 'package:flutter_test/flutter_test.dart';
import 'package:practica7/main.dart';

void main() {
  testWidgets('Practica7 smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const Practica7App());
    expect(find.textContaining('Práctica 7'), findsOneWidget);
  });
}
