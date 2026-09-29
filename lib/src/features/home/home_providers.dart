import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/movie.dart';
import '../../services/tmdb_repository.dart';

final tmdbRepositoryProvider = Provider<TmdbRepository>(
  (ref) => TmdbRepository(),
);

final homeSectionsProvider = FutureProvider<List<MovieSection>>((ref) {
  return ref.watch(tmdbRepositoryProvider).homeSections();
});

final searchQueryProvider = StateProvider<String>((ref) => '');

final searchResultsProvider = FutureProvider.autoDispose<List<Movie>>((ref) {
  final query = ref.watch(searchQueryProvider);
  return ref.watch(tmdbRepositoryProvider).search(query);
});
