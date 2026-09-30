import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/movie.dart';
import '../../widgets/movie_tile.dart';
import '../../widgets/poster_image.dart';
import '../../widgets/shimmer.dart';
import '../player/player_sheet.dart';
import 'home_providers.dart';
import 'section_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  /// Reaching the bottom of the grid loads the next page of search results.
  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels < position.maxScrollExtent - 400) return;
    if (ref.read(searchQueryProvider).trim().isEmpty) return;
    ref.read(searchResultsProvider.notifier).loadMore();
  }

  @override
  Widget build(BuildContext context) {
    final sections = ref.watch(homeSectionsProvider);
    final query = ref.watch(searchQueryProvider);
    final isSearching = query.trim().isNotEmpty;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        titleSpacing: 16,
        title: const Text(
          'NETFLIX',
          style: TextStyle(
            color: Color(0xFFE50914),
            fontSize: 24,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => ref.invalidate(homeSectionsProvider),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: sections.when(
          loading: () => const _HomeSkeleton(),
          error: (error, _) =>
              _ErrorState(onRetry: () => ref.invalidate(homeSectionsProvider)),
          data: (sections) {
            if (sections.isEmpty) {
              return _ErrorState(
                onRetry: () => ref.invalidate(homeSectionsProvider),
              );
            }
            return CustomScrollView(
              controller: _scrollController,
              // Dragging the shelves (or a rail) closes the keyboard.
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              slivers: [
                SliverToBoxAdapter(
                  child: _HeroBanner(movie: sections.first.movies.first),
                ),
                const SliverToBoxAdapter(child: _SearchBar()),
                if (isSearching)
                  const SliverToBoxAdapter(child: _SearchResults())
                else
                  for (final section in sections)
                    SliverToBoxAdapter(child: _MovieRail(section: section)),
                const SliverToBoxAdapter(child: SizedBox(height: 28)),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _HeroBanner extends StatelessWidget {
  const _HeroBanner({required this.movie});

  final Movie movie;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final height = width > 700 ? 520.0 : 440.0;

    return SizedBox(
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          PosterImage(
            imageUrl: movie.backdropUrl ?? movie.posterUrl,
            borderRadius: 0,
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black38, Color(0xA0000000), Color(0xFF090909)],
              ),
            ),
          ),
          Positioned(
            left: 20,
            right: width > 900 ? width * 0.45 : 20,
            bottom: 34,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  movie.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: width > 700 ? 52 : 38,
                    height: 1,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    _MetaChip(text: movie.year),
                    _MetaChip(
                      text: movie.mediaType == 'tv' ? 'Series' : 'Movie',
                    ),
                    _MetaChip(
                      text: '${movie.voteAverage.toStringAsFixed(1)} TMDB',
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  movie.overview,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70, height: 1.4),
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 12,
                  runSpacing: 10,
                  children: [
                    FilledButton.icon(
                      onPressed: () => showPlayerSheet(context, movie),
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: const Text('Play'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => showMovieDetails(context, movie),
                      icon: const Icon(Icons.info_outline),
                      label: const Text('Details'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchBar extends ConsumerStatefulWidget {
  const _SearchBar();

  @override
  ConsumerState<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends ConsumerState<_SearchBar> {
  static const _debounceDelay = Duration(milliseconds: 300);

  final FocusNode _focusNode = FocusNode();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _focusNode.dispose();
    super.dispose();
  }

  /// Waits for a typing pause before searching, so typing a word issues one
  /// request instead of one per keystroke.
  void _onChanged(String value) {
    _debounce?.cancel();
    if (value.trim().isEmpty) {
      // Clearing the field snaps straight back to the shelves.
      ref.read(searchQueryProvider.notifier).state = value;
      return;
    }
    _debounce = Timer(_debounceDelay, () {
      if (!mounted) return;
      ref.read(searchQueryProvider.notifier).state = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 18),
      child: TextField(
        focusNode: _focusNode,
        textInputAction: TextInputAction.search,
        onChanged: _onChanged,
        // Flutter only releases focus on tap-outside for mouse/stylus; on
        // phones a tap elsewhere leaves the keyboard up, so do it explicitly.
        onTapOutside: (_) => _focusNode.unfocus(),
        onSubmitted: (_) => _focusNode.unfocus(),
        decoration: const InputDecoration(
          prefixIcon: Icon(Icons.search),
          hintText: 'Search movies and series',
        ),
      ),
    );
  }
}

class _SearchResults extends ConsumerWidget {
  const _SearchResults();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final results = ref.watch(searchResultsProvider);

    return results.when(
      loading: () => const _GridSkeleton(),
      error: (error, stackTrace) => const _EmptyMessage(
        message: 'Search is unavailable right now.',
      ),
      data: (state) {
        if (state.movies.isEmpty) {
          return const _EmptyMessage(message: 'No matching titles found.');
        }
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns = math.max(
                    2,
                    (constraints.maxWidth / 140).floor(),
                  );
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: state.movies.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      childAspectRatio: 0.58,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 18,
                    ),
                    itemBuilder: (context, index) {
                      final movie = state.movies[index];
                      return MovieTile(
                        movie: movie,
                        showTitle: true,
                        onTap: () => showMovieDetails(context, movie),
                      );
                    },
                  );
                },
              ),
              Padding(
                padding: const EdgeInsets.only(top: 18, bottom: 8),
                child: Center(child: _SearchFooter(state: state)),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SearchFooter extends ConsumerWidget {
  const _SearchFooter({required this.state});

  final SearchResultsState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (state.isLoadingMore) {
      return const SizedBox(
        width: 132,
        child: Shimmer(child: ShimmerBox(height: 8, borderRadius: 99)),
      );
    }
    if (!state.hasMore) {
      return const Text(
        'End of results',
        style: TextStyle(color: Colors.white54),
      );
    }
    return TextButton(
      onPressed: () => ref.read(searchResultsProvider.notifier).loadMore(),
      child: const Text('Load more'),
    );
  }
}

class _MovieRail extends ConsumerStatefulWidget {
  const _MovieRail({required this.section});

  final MovieSection section;

  @override
  ConsumerState<_MovieRail> createState() => _MovieRailState();
}

class _MovieRailState extends ConsumerState<_MovieRail> {
  final ScrollController _controller = ScrollController();
  late MovieSection _section;
  bool _loadingMore = false;

  @override
  void initState() {
    super.initState();
    _section = widget.section;
    _controller.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(covariant _MovieRail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.section, widget.section)) {
      _section = widget.section;
      _loadingMore = false;
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onScroll);
    _controller.dispose();
    super.dispose();
  }

  /// Sliding the rail to its end point pulls in the next TMDB page.
  void _onScroll() {
    if (!_controller.hasClients) return;
    final position = _controller.position;
    if (position.pixels < position.maxScrollExtent - 200) return;
    _loadMore();
  }

  Future<void> _loadMore() async {
    final request = _section.request;
    if (request == null || _loadingMore || !_section.hasMore) return;

    setState(() => _loadingMore = true);
    final next = await ref
        .read(tmdbRepositoryProvider)
        .loadSectionPage(request, _section.page + 1);
    if (!mounted) return;

    setState(() {
      _loadingMore = false;
      _section = next != null && next.movies.isNotEmpty
          ? _section.append(
              MoviePage(
                movies: next.movies,
                page: next.page,
                totalPages: next.totalPages,
              ),
            )
          : _section.copyWith(totalPages: _section.page);
    });
  }

  void _openSection() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => SectionScreen(section: _section)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canBrowseAll = _section.request != null;
    final itemCount = _section.movies.length + (canBrowseAll ? 1 : 0);

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _section.title,
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (canBrowseAll)
                  TextButton(
                    onPressed: _openSection,
                    child: const Text('See all'),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 252,
            child: ListView.separated(
              controller: _controller,
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: itemCount,
              separatorBuilder: (context, index) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                if (index >= _section.movies.length) {
                  return SizedBox(
                    width: 142,
                    child: _SeeAllTile(
                      loading: _loadingMore,
                      onPressed: _openSection,
                    ),
                  );
                }
                final movie = _section.movies[index];
                return SizedBox(
                  width: 142,
                  child: MovieTile(
                    movie: movie,
                    onTap: () => showMovieDetails(context, movie),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Trailing rail tile: shows a spinner while the next page loads, otherwise
/// the "See all" shortcut into the full section list.
class _SeeAllTile extends StatelessWidget {
  const _SeeAllTile({required this.loading, required this.onPressed});

  final bool loading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Shimmer(child: ShimmerBox());
    }
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onPressed,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFF1D1D1D),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.grid_view_rounded, size: 30, color: Colors.white70),
              SizedBox(height: 10),
              Text(
                'See all',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        child: Text(
          text,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _EmptyMessage extends StatelessWidget {
  const _EmptyMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Text(message, style: const TextStyle(color: Colors.white60)),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 44, color: Colors.white54),
            const SizedBox(height: 14),
            const Text(
              'Could not load movies.',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 14),
            FilledButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}

/// Full-screen skeleton shown while the first page of shelves is loading.
class _HomeSkeleton extends StatelessWidget {
  const _HomeSkeleton();

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final heroHeight = width > 700 ? 520.0 : 440.0;

    return ListView(
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        Shimmer(
          child: SizedBox(
            height: heroHeight,
            child: const ShimmerBox(borderRadius: 0),
          ),
        ),
        const SizedBox(height: 18),
        for (var i = 0; i < 3; i++) const _SkeletonRail(),
      ],
    );
  }
}

class _SkeletonRail extends StatelessWidget {
  const _SkeletonRail();

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: ShimmerBox(width: 180, height: 20),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 252,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 6,
                separatorBuilder: (context, index) => const SizedBox(width: 12),
                itemBuilder: (context, index) =>
                    const SizedBox(width: 142, child: ShimmerBox()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Grid skeleton shown while a search request is in flight.
class _GridSkeleton extends StatelessWidget {
  const _GridSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = math.max(2, (constraints.maxWidth / 140).floor());
          return Shimmer(
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: columns * 2,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                childAspectRatio: 0.58,
                crossAxisSpacing: 12,
                mainAxisSpacing: 18,
              ),
              itemBuilder: (context, index) => const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: ShimmerBox()),
                  SizedBox(height: 8),
                  ShimmerBox(height: 12),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
