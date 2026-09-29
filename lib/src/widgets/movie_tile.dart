import 'package:flutter/material.dart';

import '../models/movie.dart';
import 'poster_image.dart';

/// A poster tile used by the home rails, the search grid and the "See all"
/// screen. [onTap] is injected so this widget stays free of feature imports.
class MovieTile extends StatelessWidget {
  const MovieTile({
    required this.movie,
    this.showTitle = false,
    this.onTap,
    super.key,
  });

  final Movie movie;
  final bool showTitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
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
