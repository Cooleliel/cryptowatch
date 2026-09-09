import 'package:cryptowatch/app/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget app() {
    return const ProviderScope(child: CryptoWatchApp());
  }

  testWidgets("L'application démarre sur l'écran de marché", (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(app());
    expect(find.text('CryptoWatch'), findsOneWidget);
  });

  testWidgets("Les onglets naviguent entre Marché et Watchlist", (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(app());

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Watchlist'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Ma watchlist'), findsOneWidget);

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Marché'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('CryptoWatch'), findsOneWidget);
  });
}
