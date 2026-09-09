import 'package:flutter_test/flutter_test.dart';

import 'package:cryptowatch/main.dart';

void main() {
  testWidgets("La fiche Bitcoin affiche le mockup", (WidgetTester tester) async {
    await tester.pumpWidget(const MainApp());

    expect(find.text('Bitcoin'), findsOneWidget);
    expect(find.text('Rang 1'), findsOneWidget);
    expect(find.text(r'$112 840,52'), findsOneWidget);
    expect(find.text('+2,4 % sur 24 h'), findsOneWidget);
    expect(find.text('Plus haut 24 h'), findsOneWidget);
    expect(find.text(r'$114 120'), findsOneWidget);
    expect(find.text('Plus bas 24 h'), findsOneWidget);
    expect(find.text(r'$109 480'), findsOneWidget);
    expect(find.text('Volume 24 h'), findsOneWidget);
    expect(find.text(r'$38,2 Md'), findsOneWidget);
    expect(find.text('Capitalisation'), findsOneWidget);
    expect(find.text(r'$2 230 Md'), findsOneWidget);
  });
}
