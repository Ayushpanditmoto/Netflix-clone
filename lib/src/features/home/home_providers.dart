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

/// Accumulated search results plus the paging cursor used by "load more".
class SearchResultsState {
  const SearchResultsState({
    this.movies = const [],
    this.page = 1,
    this.totalPages = 1,
    this.isLoadingMore = false,
  });

  final List<Movie> movies;
  final int page;
  final int totalPages;
  final bool isLoadingMore;

  bool get hasMore => page < totalPages;

  SearchResultsState copyWith({
    List<Movie>? movies,
    int? page,
    int? totalPages,
    bool? isLoadingMore,
  }) {
    return SearchResultsState(
      movies: movies ?? this.movies,
      page: page ?? this.page,
      totalPages: totalPages ?? this.totalPages,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

class SearchController extends AutoDisposeAsyncNotifier<SearchResultsState> {
  /// Bumped on every (re)build. A page request captures this value and drops
  /// its response if a newer build has since happened, so an in-flight page
  /// from an older query can never overwrite newer results.
  int _buildId = 0;

  /// Cleared when this notifier is rebuilt *or* disposed.
  ///
  /// Note: Riverpod runs `ref.onDispose` callbacks on every rebuild, not just
  /// on disposal. A plain one-way `_disposed = true` flag therefore latches
  /// permanently after the first keystroke and silently swallows every later
  /// page response, which is why paging appeared to do nothing.
  bool _active = false;

  @override
  Future<SearchResultsState> build() async {
    final buildId = ++_buildId;
    _active = true;
    ref.onDispose(() {
      if (buildId == _buildId) _active = false;
    });

    final query = ref.watch(searchQueryProvider).trim();
    if (query.isEmpty) return const SearchResultsState();

    final result = await ref.watch(tmdbRepositoryProvider).searchPage(query);
    return SearchResultsState(
      movies: result.movies,
      page: result.page,
      totalPages: result.totalPages,
    );
  }

  /// Fetches the next page and appends it to the current results.
  Future<void> loadMore() async {
    final buildId = _buildId;
    final current = state.valueOrNull;
    if (current == null || !current.hasMore || current.isLoadingMore) return;

    final query = ref.read(searchQueryProvider).trim();
    if (query.isEmpty) return;

    state = AsyncData(current.copyWith(isLoadingMore: true));
    try {
      final result = await ref
          .read(tmdbRepositoryProvider)
          .searchPage(query, page: current.page + 1);
      // Superseded by a newer query, or torn down while in flight. Either way
      // the fresh build owns the state now, so leave it alone.
      if (!_active || buildId != _buildId) return;
      state = AsyncData(
        current.copyWith(
          movies: mergeMovies(current.movies, result.movies),
          page: result.page,
          totalPages: result.totalPages,
          isLoadingMore: false,
        ),
      );
    } catch (_) {
      if (!_active || buildId != _buildId) return;
      // Keep the paging cursor intact so the same page can be retried.
      state = AsyncData(current.copyWith(isLoadingMore: false));
    }
  }
}

final searchResultsProvider =
    AsyncNotifierProvider.autoDispose<SearchController, SearchResultsState>(
      SearchController.new,
    );
