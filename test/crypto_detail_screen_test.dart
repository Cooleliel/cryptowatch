import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:cryptowatch/features/crypto_detail/data/repositories/price_history_repository.dart';
import 'package:cryptowatch/features/crypto_detail/domain/price_point.dart';
import 'package:cryptowatch/features/crypto_detail/presentation/providers/price_history_provider.dart';
import 'package:cryptowatch/features/crypto_detail/presentation/screens/crypto_detail_screen.dart';
import 'package:cryptowatch/features/crypto_detail/presentation/widgets/week_line_chart.dart';
import 'package:cryptowatch/shared/errors/app_exception.dart';

class MockPriceHistoryRepository extends Mock
    implements PriceHistoryRepository {}

void main() {
  final samplePoints = [
    PricePoint(time: DateTime(2026, 9, 4), price: 64000),
    PricePoint(time: DateTime(2026, 9, 5), price: 65100),
    PricePoint(time: DateTime(2026, 9, 6), price: 64800),
  ];

  late MockPriceHistoryRepository mockRepository;

  setUp(() {
    mockRepository = MockPriceHistoryRepository();
  });

  Widget app() {
    return ProviderScope(
      overrides: [
        priceHistoryRepositoryProvider.overrideWithValue(mockRepository),
      ],
      child: const MaterialApp(home: CryptoDetailScreen()),
    );
  }

  testWidgets("La fiche Bitcoin affiche le mockup et la courbe réelle",
      (WidgetTester tester) async {
    when(() => mockRepository.fetchLast7Days('bitcoin'))
        .thenAnswer((_) async => samplePoints);

    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    expect(find.text('Bitcoin'), findsOneWidget);
    expect(find.text('Rang 1'), findsOneWidget);
    expect(find.text(r'$112 840,52'), findsOneWidget);
    expect(find.byType(WeekLineChart), findsOneWidget);
    expect(find.text('Plus haut 24 h'), findsOneWidget);
    expect(find.text(r'$2 230 Md'), findsOneWidget);
  });

  testWidgets('affiche un indicateur pendant le chargement de la courbe',
      (WidgetTester tester) async {
    when(() => mockRepository.fetchLast7Days('bitcoin')).thenAnswer(
      (_) => Completer<List<PricePoint>>().future,
    );

    await tester.pumpWidget(app());
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(WeekLineChart), findsNothing);
  });

  testWidgets("affiche Réessayer si l'historique échoue",
      (WidgetTester tester) async {
    when(() => mockRepository.fetchLast7Days('bitcoin'))
        .thenThrow(const NetworkException('offline'));

    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    expect(find.text('Réessayer'), findsOneWidget);
    expect(find.byType(WeekLineChart), findsNothing);
  });
}
