import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/movie.dart';
import '../../widgets/movie_tile.dart';
import '../../widgets/shimmer.dart';
import '../player/player_sheet.dart';
import 'home_providers.dart';

/// Full-screen "See all" view for a single rail. Loads the next TMDB page
/// automatically as the user scrolls towards the bottom.
class SectionScreen extends ConsumerStatefulWidget {
  const SectionScreen({super.key, required this.section});

  final MovieSection section;

  @override
  ConsumerState<SectionScreen> createState() => _SectionScreenState();
}

class _SectionScreenState extends ConsumerState<SectionScreen> {
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
  void dispose() {
    _controller.removeListener(_onScroll);
    _controller.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_controller.hasClients) return;
    final position = _controller.position;
    if (position.pixels < position.maxScrollExtent - 400) return;
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
          // Nothing came back: stop paging instead of looping forever.
          : _section.copyWith(totalPages: _section.page);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_section.title)),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final columns = math.max(2, (constraints.maxWidth / 140).floor());
          return GridView.builder(
            controller: _controller,
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            itemCount: _section.movies.length + (_loadingMore ? columns : 0),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              childAspectRatio: 0.58,
              crossAxisSpacing: 12,
              mainAxisSpacing: 18,
            ),
            itemBuilder: (context, index) {
              if (index >= _section.movies.length) {
                return const PosterPlaceholder(showTitle: true);
              }
              final movie = _section.movies[index];
              return MovieTile(
                movie: movie,
                showTitle: true,
                onTap: () => showMovieDetails(context, movie),
              );
            },
          );
        },
      ),
    );
  }
}
