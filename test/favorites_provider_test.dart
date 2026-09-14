import 'package:cryptowatch/features/watchlist/presentation/providers/favorites_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('toggleFavorite ajoute puis retire un identifiant', () {
    final ProviderContainer container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(favoritesProvider), isEmpty);

    container.read(favoritesProvider.notifier).toggleFavorite('bitcoin');
    expect(container.read(favoritesProvider), contains('bitcoin'));

    container.read(favoritesProvider.notifier).toggleFavorite('bitcoin');
    expect(container.read(favoritesProvider), isEmpty);
  });

  test('deux cryptos se togglent indépendamment', () {
    final ProviderContainer container = ProviderContainer();
    addTearDown(container.dispose);

    final FavoritesNotifier notifier = container.read(
      favoritesProvider.notifier,
    );
    notifier.toggleFavorite('bitcoin');
    notifier.toggleFavorite('ethereum');
    notifier.toggleFavorite('bitcoin');

    expect(container.read(favoritesProvider), <String>{'ethereum'});
  });
}
