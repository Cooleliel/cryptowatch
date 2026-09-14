import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cryptowatch/features/market/presentation/providers/market_filter_provider.dart';
import 'package:cryptowatch/features/market/presentation/providers/market_filter_state.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer();
  });

  tearDown(() => container.dispose());

  test('état initial : query vide, aucun tri, ordre descendant par défaut', () {
    final state = container.read(marketFilterProvider);
    expect(state.query, '');
    expect(state.sortField, isNull);
    expect(state.sortDescending, true);
  });

  test('setQuery met à jour le texte de recherche', () {
    container.read(marketFilterProvider.notifier).setQuery('bitcoin');
    expect(container.read(marketFilterProvider).query, 'bitcoin');
  });

  test('setQuery ne déclenche pas de rebuild si la valeur est identique', () {
    final notifier = container.read(marketFilterProvider.notifier);
    notifier.setQuery('eth');

    var notified = 0;
    container.listen(marketFilterProvider, (_, _) => notified++);
    notifier.setQuery('eth'); // même valeur

    expect(notified, 0);
  });

  test('premier setSortField active le tri en ordre descendant', () {
    container.read(marketFilterProvider.notifier).setSortField(
      MarketSortField.price,
    );
    final state = container.read(marketFilterProvider);
    expect(state.sortField, MarketSortField.price);
    expect(state.sortDescending, true);
  });

  test('un second appel sur le même critère inverse l\'ordre', () {
    final notifier = container.read(marketFilterProvider.notifier);
    notifier.setSortField(MarketSortField.variation);
    notifier.setSortField(MarketSortField.variation);

    final state = container.read(marketFilterProvider);
    expect(state.sortField, MarketSortField.variation);
    expect(state.sortDescending, false);
  });

  test('changer de critère réinitialise l\'ordre à descendant', () {
    final notifier = container.read(marketFilterProvider.notifier);
    notifier.setSortField(MarketSortField.price);
    notifier.setSortField(MarketSortField.price); // passe en ascendant
    notifier.setSortField(MarketSortField.marketCap); // nouveau critère

    final state = container.read(marketFilterProvider);
    expect(state.sortField, MarketSortField.marketCap);
    expect(state.sortDescending, true);
  });
}