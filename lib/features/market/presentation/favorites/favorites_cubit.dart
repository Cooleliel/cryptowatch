import 'package:bloc/bloc.dart';

import 'favorites_state.dart';

class FavoritesCubit extends Cubit<FavoritesState> {
  FavoritesCubit() : super(const FavoritesState());

  void toggleFavorite(String cryptoId) {
    final ids = Set<String>.from(state.favoriteIds);
    if (ids.contains(cryptoId)) {
      ids.remove(cryptoId);
    } else {
      ids.add(cryptoId);
    }

    emit(FavoritesState(favoriteIds: ids));
  }

  bool isFavorite(String cryptoId) {
    return state.favoriteIds.contains(cryptoId);
  }
}
