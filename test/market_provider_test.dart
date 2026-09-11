import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';

import 'package:cryptowatch/features/market/data/repositories/market_repository.dart';
import 'package:cryptowatch/features/market/domain/crypto.dart';
import 'package:cryptowatch/features/market/presentation/providers/market_provider.dart';
import 'package:cryptowatch/features/market/presentation/providers/market_state.dart';
import 'package:cryptowatch/shared/errors/app_exception.dart';
import 'package:cryptowatch/shared/logging/app_logger_provider.dart';

class MockMarketRepository extends Mock implements MarketRepository {}

void main() {
  late MockMarketRepository mockRepository;
  late ProviderContainer container;

  final sampleCryptos = [
    Crypto(
      id: 'bitcoin',
      name: 'Bitcoin',
      symbol: 'btc',
      currentPrice: 45000.0,
      lastUpdated: DateTime(2026, 1, 1),
    ),
    Crypto(
      id: 'ethereum',
      name: 'Ethereum',
      symbol: 'eth',
      currentPrice: 3000.0,
      lastUpdated: DateTime(2026, 1, 1),
    ),
  ];

  setUp(() {
    mockRepository = MockMarketRepository();
    container = ProviderContainer(
      overrides: [
        marketRepositoryProvider.overrideWithValue(mockRepository),
      ],
    );
  });

  tearDown(() => container.dispose());

  test('état initial est MarketLoading avant résolution du fetch', () {
    when(() => mockRepository.fetchTopCryptos())
        .thenAnswer((_) async => sampleCryptos);

    container.read(marketProvider.notifier); // déclenche le build/constructeur
    expect(container.read(marketProvider), isA<MarketLoading>());
  });

  test('passe à MarketLoaded avec les cryptos en cas de succès', () async {
    when(() => mockRepository.fetchTopCryptos())
        .thenAnswer((_) async => sampleCryptos);

    // Attend la résolution du Future lancé dans le constructeur du Notifier
    await container.read(marketProvider.notifier).retry();

    final state = container.read(marketProvider);
    expect(state, isA<MarketLoaded>());
    expect((state as MarketLoaded).cryptos, sampleCryptos);
  });

  test('passe à MarketError en cas d\'exception du repository', () async {
    when(() => mockRepository.fetchTopCryptos())
        .thenThrow(Exception('Network error'));

    await container.read(marketProvider.notifier).retry();

    final state = container.read(marketProvider);
    expect(state, isA<MarketError>());
  });

  test('retry() relance le chargement et repasse par MarketLoading', () async {
    when(() => mockRepository.fetchTopCryptos())
        .thenAnswer((_) async => sampleCryptos);

    final notifier = container.read(marketProvider.notifier);
    final future = notifier.retry();

    expect(container.read(marketProvider), isA<MarketLoading>());
    await future;
    expect(container.read(marketProvider), isA<MarketLoaded>());
  });

  test('MarketLoaded contient une liste vide si le repository renvoie []', () async {
    when(() => mockRepository.fetchTopCryptos())
        .thenAnswer((_) async => []);

    await container.read(marketProvider.notifier).retry();

    final state = container.read(marketProvider) as MarketLoaded;
    expect(state.cryptos, isEmpty);
  });

  test('setQuery filtre par nom sans modifier la liste brute', () async {
    when(() => mockRepository.fetchTopCryptos())
        .thenAnswer((_) async => sampleCryptos);

    await container.read(marketProvider.notifier).retry();
    container.read(marketProvider.notifier).setQuery('bit');

    final state = container.read(marketProvider) as MarketLoaded;
    expect(state.cryptos, sampleCryptos);
    expect(state.visibleCryptos, [sampleCryptos.first]);
  });

  test('setQuery filtre par symbole sans tenir compte de la casse', () async {
    when(() => mockRepository.fetchTopCryptos())
        .thenAnswer((_) async => sampleCryptos);

    await container.read(marketProvider.notifier).retry();
    container.read(marketProvider.notifier).setQuery('ETH');

    final state = container.read(marketProvider) as MarketLoaded;
    expect(state.visibleCryptos.single.symbol, 'eth');
  });

  test('setQuery sans correspondance laisse visibleCryptos vide', () async {
    when(() => mockRepository.fetchTopCryptos())
        .thenAnswer((_) async => sampleCryptos);

    await container.read(marketProvider.notifier).retry();
    container.read(marketProvider.notifier).setQuery('solana');

    final state = container.read(marketProvider) as MarketLoaded;
    expect(state.visibleCryptos, isEmpty);
    expect(state.cryptos, hasLength(2));
  });

  test('query vide réaffiche toute la liste', () async {
    when(() => mockRepository.fetchTopCryptos())
        .thenAnswer((_) async => sampleCryptos);

    await container.read(marketProvider.notifier).retry();
    container.read(marketProvider.notifier).setQuery('eth');
    container.read(marketProvider.notifier).setQuery('');

    final state = container.read(marketProvider) as MarketLoaded;
    expect(state.visibleCryptos, sampleCryptos);
  });

  test('retry réinitialise la recherche', () async {
    when(() => mockRepository.fetchTopCryptos())
        .thenAnswer((_) async => sampleCryptos);

    await container.read(marketProvider.notifier).retry();
    container.read(marketProvider.notifier).setQuery('eth');
    await container.read(marketProvider.notifier).retry();

    final state = container.read(marketProvider) as MarketLoaded;
    expect(state.query, isEmpty);
    expect(state.visibleCryptos, sampleCryptos);
  });

  test('setQuery est ignoré en MarketError', () async {
    when(() => mockRepository.fetchTopCryptos())
        .thenThrow(Exception('Network error'));

    await container.read(marketProvider.notifier).retry();
    container.read(marketProvider.notifier).setQuery('btc');
    expect(container.read(marketProvider), isA<MarketError>());
  });

  test('visibleCryptos ignore les espaces autour de la query', () {
    final loaded = MarketLoaded(sampleCryptos, query: '  ETH  ');
    expect(loaded.visibleCryptos.single.name, 'Ethereum');
  });

  test('trie par prix décroissant sans modifier la liste brute', () async {
    when(() => mockRepository.fetchTopCryptos())
        .thenAnswer((_) async => sampleCryptos);

    await container.read(marketProvider.notifier).retry();
    container.read(marketProvider.notifier).setSortField(MarketSortField.price);

    final state = container.read(marketProvider) as MarketLoaded;
    expect(state.cryptos, sampleCryptos);
    expect(state.visibleCryptos.map((c) => c.id), ['bitcoin', 'ethereum']);
  });

  test('un second tap inverse l\'ordre du même critère', () async {
    when(() => mockRepository.fetchTopCryptos())
        .thenAnswer((_) async => sampleCryptos);

    await container.read(marketProvider.notifier).retry();
    container.read(marketProvider.notifier).setSortField(MarketSortField.price);
    container.read(marketProvider.notifier).setSortField(MarketSortField.price);

    final state = container.read(marketProvider) as MarketLoaded;
    expect(state.sortDescending, isFalse);
    expect(state.visibleCryptos.map((c) => c.id), ['ethereum', 'bitcoin']);
  });

  test('trie par variation et place les valeurs nulles à la fin', () {
    final cryptos = [
      Crypto(
        id: 'bitcoin',
        name: 'Bitcoin',
        symbol: 'btc',
        currentPrice: 1,
        priceChangePercentage24h: 2.0,
        lastUpdated: DateTime(2026, 1, 1),
      ),
      Crypto(
        id: 'tether',
        name: 'Tether',
        symbol: 'usdt',
        currentPrice: 1,
        lastUpdated: DateTime(2026, 1, 1),
      ),
      Crypto(
        id: 'solana',
        name: 'Solana',
        symbol: 'sol',
        currentPrice: 1,
        priceChangePercentage24h: 8.0,
        lastUpdated: DateTime(2026, 1, 1),
      ),
    ];

    final loaded = MarketLoaded(
      cryptos,
      sortField: MarketSortField.variation,
    );

    expect(loaded.visibleCryptos.map((c) => c.id), [
      'solana',
      'bitcoin',
      'tether',
    ]);
  });

  test('trie par capitalisation décroissante', () {
    final cryptos = [
      Crypto(
        id: 'ethereum',
        name: 'Ethereum',
        symbol: 'eth',
        currentPrice: 1,
        marketCap: 400,
        lastUpdated: DateTime(2026, 1, 1),
      ),
      Crypto(
        id: 'bitcoin',
        name: 'Bitcoin',
        symbol: 'btc',
        currentPrice: 1,
        marketCap: 900,
        lastUpdated: DateTime(2026, 1, 1),
      ),
    ];

    final loaded = MarketLoaded(
      cryptos,
      sortField: MarketSortField.marketCap,
    );

    expect(loaded.visibleCryptos.map((c) => c.id), ['bitcoin', 'ethereum']);
  });

  test('le tri s\'applique après le filtre', () {
    final cryptos = [
      Crypto(
        id: 'bitcoin',
        name: 'Bitcoin',
        symbol: 'btc',
        currentPrice: 45000,
        lastUpdated: DateTime(2026, 1, 1),
      ),
      Crypto(
        id: 'binancecoin',
        name: 'BNB',
        symbol: 'bnb',
        currentPrice: 600,
        lastUpdated: DateTime(2026, 1, 1),
      ),
      Crypto(
        id: 'ethereum',
        name: 'Ethereum',
        symbol: 'eth',
        currentPrice: 3000,
        lastUpdated: DateTime(2026, 1, 1),
      ),
    ];

    final loaded = MarketLoaded(
      cryptos,
      query: 'b',
      sortField: MarketSortField.price,
    );

    expect(loaded.visibleCryptos.map((c) => c.id), ['bitcoin', 'binancecoin']);
  });

  test('retry réinitialise le tri', () async {
    when(() => mockRepository.fetchTopCryptos())
        .thenAnswer((_) async => sampleCryptos);

    await container.read(marketProvider.notifier).retry();
    container.read(marketProvider.notifier).setSortField(MarketSortField.price);
    await container.read(marketProvider.notifier).retry();

    final state = container.read(marketProvider) as MarketLoaded;
    expect(state.sortField, isNull);
    expect(state.visibleCryptos, sampleCryptos);
  });

  test('setSortField est ignoré en MarketError', () async {
    when(() => mockRepository.fetchTopCryptos())
        .thenThrow(Exception('Network error'));

    await container.read(marketProvider.notifier).retry();
    container.read(marketProvider.notifier).setSortField(MarketSortField.price);
    expect(container.read(marketProvider), isA<MarketError>());
  });

  group('un message juste par type de panne', () {
    Future<String> messageFor(AppException error) async {
      when(() => mockRepository.fetchTopCryptos()).thenThrow(error);
      await container.read(marketProvider.notifier).retry();
      return (container.read(marketProvider) as MarketError).message;
    }

    test('NetworkException parle de connexion', () async {
      final message = await messageFor(const NetworkException('offline'));
      expect(message.toLowerCase(), contains('connexion'));
    });

    test('RateLimitException parle de requetes, pas de connexion', () async {
      final message = await messageFor(const RateLimitException());
      expect(message.toLowerCase(), contains('requ'));
      expect(
        message.toLowerCase(),
        isNot(contains('connexion')),
        reason: 'un 429 ne doit pas envoyer chercher un probleme de reseau',
      );
    });

    test('RequestTimeoutException parle de delai', () async {
      final message = await messageFor(
        const RequestTimeoutException(Duration(seconds: 10)),
      );
      expect(message.toLowerCase(), contains('temps'));
    });

    test('ServerException parle du service', () async {
      final message = await messageFor(const ServerException(500));
      expect(message.toLowerCase(), contains('service'));
    });

    test('InvalidDataException parle de reponse inattendue', () async {
      final message = await messageFor(const InvalidDataException('format'));
      expect(message.toLowerCase(), contains('inattendue'));
    });

    test('deux pannes differentes ne donnent pas le meme message', () async {
      final network = await messageFor(const NetworkException('offline'));
      final rateLimit = await messageFor(const RateLimitException());
      expect(network, isNot(equals(rateLimit)));
    });
  });

  group('aucune erreur silencieuse dans le provider', () {
    late List<String> traces;
    late List<Object?> causes;
    late ProviderContainer tracedContainer;

    setUp(() {
      traces = <String>[];
      causes = <Object?>[];
      tracedContainer = ProviderContainer(
        overrides: [
          marketRepositoryProvider.overrideWithValue(mockRepository),
          appLogProvider.overrideWithValue((
            String message, {
            Object? error,
            StackTrace? stackTrace,
          }) {
            traces.add(message);
            causes.add(error);
          }),
        ],
      );
    });

    tearDown(() => tracedContainer.dispose());

    test('une AppException laisse une trace portant la cause', () async {
      when(() => mockRepository.fetchTopCryptos())
          .thenThrow(const RateLimitException());

      await tracedContainer.read(marketProvider.notifier).retry();

      expect(traces, isNotEmpty);
      expect(causes.whereType<RateLimitException>(), isNotEmpty);
    });

    test('une erreur inattendue est tracee, pas avalee', () async {
      final unexpected = StateError('bug interne');
      when(() => mockRepository.fetchTopCryptos()).thenThrow(unexpected);

      await tracedContainer.read(marketProvider.notifier).retry();

      expect(tracedContainer.read(marketProvider), isA<MarketError>());
      expect(traces, isNotEmpty, reason: 'rien ne doit disparaitre en silence');
      expect(causes, contains(unexpected));
    });

    test('un chargement reussi ne trace rien', () async {
      when(() => mockRepository.fetchTopCryptos())
          .thenAnswer((_) async => sampleCryptos);

      await tracedContainer.read(marketProvider.notifier).retry();

      expect(traces, isEmpty);
    });
  });
}