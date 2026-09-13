import 'package:cryptowatch/features/market/presentation/favorites/favorites_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FavoritesCubit toggleFavorite ajoute puis retire un identifiant', () {
    final cubit = FavoritesCubit();

    expect(cubit.state.favoriteIds, isEmpty);

    cubit.toggleFavorite('bitcoin');
    expect(cubit.state.favoriteIds, contains('bitcoin'));
    expect(cubit.isFavorite('bitcoin'), isTrue);

    cubit.toggleFavorite('bitcoin');
    expect(cubit.state.favoriteIds, isEmpty);
    expect(cubit.isFavorite('bitcoin'), isFalse);
  });
}
