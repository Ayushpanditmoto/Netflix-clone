import 'package:flutter/material.dart';

import '../../models/movie.dart';
import '../../widgets/poster_image.dart';
import 'player_screen.dart';

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

void showPlayerSheet(BuildContext context, Movie movie) {
  FocusManager.instance.primaryFocus?.unfocus();
  Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => PlayerScreen(movie: movie)));
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
            const SizedBox(height: 18),
            AspectRatio(
              aspectRatio: 16 / 9,
              child: PosterImage(
                imageUrl: movie.backdropUrl ?? movie.posterUrl,
              ),
            ),
            const SizedBox(height: 18),
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
            FilledButton.icon(
              onPressed: () {
                Navigator.pop(context);
                showPlayerSheet(context, movie);
              },
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Play'),
            ),
          ],
        );
      },
    );
  }
}
