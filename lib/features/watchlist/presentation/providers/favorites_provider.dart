import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Identifiants des cryptos marquées en favori
class FavoritesNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => const <String>{};

  void toggleFavorite(String cryptoId) {
    state = state.contains(cryptoId)
        ? (Set<String>.of(state)..remove(cryptoId))
        : (Set<String>.of(state)..add(cryptoId));
  }
}

final favoritesProvider = NotifierProvider<FavoritesNotifier, Set<String>>(
  FavoritesNotifier.new,
);
