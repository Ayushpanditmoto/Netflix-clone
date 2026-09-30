import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'episode_list.dart';
import 'youtube_trailer.dart';

import '../../models/movie.dart';
import 'player_screen.dart';
import '../home/home_providers.dart';

/// Season list for a series. Only ever watched for `mediaType == 'tv'`.
final seasonsProvider = FutureProvider.autoDispose.family<List<Season>, int>((
  ref,
  seriesId,
) {
  return ref.watch(tmdbRepositoryProvider).seasons(seriesId);
});

/// Episodes of the selected season. Keyed by (seriesId, seasonNumber) so
/// switching seasons cancels and replaces the previous request.
final episodesProvider = FutureProvider.autoDispose
    .family<List<Episode>, ({int seriesId, int seasonNumber})>((ref, key) {
      return ref
          .watch(tmdbRepositoryProvider)
          .episodes(key.seriesId, key.seasonNumber);
    });

final trailerProvider = FutureProvider.autoDispose
    .family<String?, ({int id, String type})>((ref, title) {
      return ref.watch(tmdbRepositoryProvider).trailerKey(title.id, title.type);
    });

void showMovieDetails(BuildContext context, Movie movie) {
  // Reached from a poster tap, so drop the search field's focus first or the
  // keyboard would stay up over the sheet.
  FocusManager.instance.primaryFocus?.unfocus();
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF121212),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
    ),
    builder: (context) => _MovieDetailsSheet(movie: movie),
  );
}

void showPlayerSheet(
  BuildContext context,
  Movie movie, {
  int? season,
  int? episode,
}) {
  FocusManager.instance.primaryFocus?.unfocus();
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) =>
          PlayerScreen(movie: movie, season: season, episode: episode),
    ),
  );
}

class _MovieDetailsSheet extends StatelessWidget {
  const _MovieDetailsSheet({required this.movie});

  final Movie movie;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.72,
      minChildSize: 0.45,
      maxChildSize: 0.94,
      builder: (context, controller) {
        return ListView(
          controller: controller,
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          children: [
            Center(
              child: Container(
                height: 4,
                width: 44,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              movie.title,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              '${movie.year}  •  ${movie.mediaType == 'tv' ? 'Series' : 'Movie'}  •  TMDB ${movie.voteAverage.toStringAsFixed(1)}',
              style: const TextStyle(
                color: Colors.white60,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              movie.overview,
              style: const TextStyle(height: 1.45, color: Colors.white70),
            ),
            const SizedBox(height: 20),
            _TrailerPreview(movie: movie),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: () {
                Navigator.pop(context);
                showPlayerSheet(context, movie);
              },
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Play'),
            ),
            // Seasons only exist for series; a movie would 404 on the endpoint.
            // Listed after Play so the primary action stays above the fold.
            if (movie.mediaType == 'tv') ...[
              const SizedBox(height: 24),
              const Text(
                'Episodes',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              EpisodeList(movie: movie),
            ],
          ],
        );
      },
    );
  }
}

class _TrailerPreview extends ConsumerWidget {
  const _TrailerPreview({required this.movie});
  final Movie movie;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = trailerProvider((id: movie.id, type: movie.mediaType));
    return ref
        .watch(provider)
        .when(
          loading: () => const Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: LinearProgressIndicator(),
          ),
          error: (_, stack) => TextButton.icon(
            onPressed: () => ref.invalidate(provider),
            icon: const Icon(Icons.refresh),
            label: const Text('Retry trailer'),
          ),
          data: (key) {
            if (key == null) {
              return const Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: Text(
                  'No trailer available',
                  style: TextStyle(color: Colors.white54),
                ),
              );
            }
            return Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Trailer',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  YoutubeTrailer(key: ValueKey(key), videoId: key),
                ],
              ),
            );
          },
        );
  }
}
