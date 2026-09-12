class FavoritesState {
  final Set<String> favoriteIds;

  const FavoritesState({this.favoriteIds = const <String>{}});

  FavoritesState copyWith({Set<String>? favoriteIds}) {
    return FavoritesState(
      favoriteIds: favoriteIds ?? this.favoriteIds,
    );
  }
}
