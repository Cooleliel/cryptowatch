import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:cryptowatch/features/crypto_detail/data/repositories/price_history_repository.dart';
import 'package:cryptowatch/features/crypto_detail/domain/price_point.dart';
import 'package:cryptowatch/features/crypto_detail/presentation/providers/price_history_provider.dart';
import 'package:cryptowatch/features/crypto_detail/presentation/providers/price_history_state.dart';
import 'package:cryptowatch/features/market/data/market_exception.dart';

class MockPriceHistoryRepository extends Mock
    implements PriceHistoryRepository {}

void main() {
  late MockPriceHistoryRepository mockRepository;
  late ProviderContainer container;

  final samplePoints = [
    PricePoint(time: DateTime(2026, 9, 4), price: 64000),
    PricePoint(time: DateTime(2026, 9, 10), price: 67000),
  ];

  setUp(() {
    mockRepository = MockPriceHistoryRepository();
    container = ProviderContainer(
      overrides: [
        priceHistoryRepositoryProvider.overrideWithValue(mockRepository),
      ],
    );
  });

  tearDown(() => container.dispose());

  test('passe à PriceHistoryLoaded avec les points en cas de succès', () async {
    when(() => mockRepository.fetchLast7Days('bitcoin'))
        .thenAnswer((_) async => samplePoints);

    await container.read(priceHistoryProvider('bitcoin').notifier).retry();

    final state = container.read(priceHistoryProvider('bitcoin'));
    expect(state, isA<PriceHistoryLoaded>());
    expect((state as PriceHistoryLoaded).points, samplePoints);
    expect(state.prices, [64000.0, 67000.0]);
  });

  test('passe à PriceHistoryError si le repository lève', () async {
    when(() => mockRepository.fetchLast7Days('bitcoin'))
        .thenThrow(const NetworkException('offline'));

    await container.read(priceHistoryProvider('bitcoin').notifier).retry();

    final state = container.read(priceHistoryProvider('bitcoin'));
    expect(state, isA<PriceHistoryError>());
    expect(
      (state as PriceHistoryError).message,
      contains('connexion'),
    );
  });

  test('distingue un 429 d\'une panne réseau', () async {
    when(() => mockRepository.fetchLast7Days('bitcoin'))
        .thenThrow(const RateLimitException());

    await container.read(priceHistoryProvider('bitcoin').notifier).retry();

    final state = container.read(priceHistoryProvider('bitcoin'));
    expect(state, isA<PriceHistoryError>());
    expect(
      (state as PriceHistoryError).message,
      contains('Trop de requêtes'),
    );
  });

  test('passe à PriceHistoryError s\'il y a moins de 2 points', () async {
    when(() => mockRepository.fetchLast7Days('bitcoin')).thenAnswer(
      (_) async => [PricePoint(time: DateTime(2026, 9, 4), price: 64000)],
    );

    await container.read(priceHistoryProvider('bitcoin').notifier).retry();

    expect(
      container.read(priceHistoryProvider('bitcoin')),
      isA<PriceHistoryError>(),
    );
  });
}
