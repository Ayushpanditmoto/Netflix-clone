import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/movie.dart';
import '../../widgets/poster_image.dart';
import '../player/player_sheet.dart';
import 'home_providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sections = ref.watch(homeSectionsProvider);
    final query = ref.watch(searchQueryProvider);
    final isSearching = query.trim().isNotEmpty;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        titleSpacing: 16,
        title: const Text(
          'STREAMFLIX',
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
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) =>
              _ErrorState(onRetry: () => ref.invalidate(homeSectionsProvider)),
          data: (sections) {
            if (sections.isEmpty) {
              return _ErrorState(
                onRetry: () => ref.invalidate(homeSectionsProvider),
              );
            }
            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _HeroBanner(movie: sections.first.movies.first),
                ),
                SliverToBoxAdapter(child: _SearchBar()),
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

class _SearchBar extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 18),
      child: TextField(
        onChanged: (value) =>
            ref.read(searchQueryProvider.notifier).state = value,
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
      loading: () => const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stackTrace) =>
          const _EmptyMessage(message: 'Search is unavailable right now.'),
      data: (movies) {
        if (movies.isEmpty) {
          return const _EmptyMessage(message: 'No matching titles found.');
        }
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth > 950
                  ? 6
                  : constraints.maxWidth > 650
                  ? 4
                  : 3;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: movies.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  childAspectRatio: 0.58,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 18,
                ),
                itemBuilder: (context, index) =>
                    _MovieTile(movie: movies[index], showTitle: true),
              );
            },
          ),
        );
      },
    );
  }
}

class _MovieRail extends StatelessWidget {
  const _MovieRail({required this.section});

  final MovieSection section;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              section.title,
              style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 252,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: section.movies.length,
              separatorBuilder: (context, index) => const SizedBox(width: 12),
              itemBuilder: (context, index) => SizedBox(
                width: 142,
                child: _MovieTile(movie: section.movies[index]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MovieTile extends StatelessWidget {
  const _MovieTile({required this.movie, this.showTitle = false});

  final Movie movie;
  final bool showTitle;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => showMovieDetails(context, movie),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: PosterImage(imageUrl: movie.posterUrl)),
          if (showTitle) ...[
            const SizedBox(height: 8),
            Text(
              movie.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ],
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
