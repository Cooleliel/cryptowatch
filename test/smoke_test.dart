import 'package:cryptowatch/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets("L'application démarre sans erreur", (WidgetTester tester) async {
    await tester.pumpWidget(const MainApp());
    expect(find.byType(MainApp), findsOneWidget);
  });
}
