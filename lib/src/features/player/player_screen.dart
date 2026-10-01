import 'package:flutter/material.dart';

import '../../models/movie.dart';
import '../../models/player_source.dart';
import '../../widgets/poster_image.dart';
import 'embed_player_view.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({
    super.key,
    required this.movie,
    this.season,
    this.episode,
  });

  final Movie movie;

  /// Set when the user picked a specific episode from the details sheet. Both
  /// are null for a movie or a series opened at season level.
  final int? season;
  final int? episode;

  bool get isEpisode => season != null && episode != null;

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  String? _openingSource;

  /// Source currently loaded in the inline player. Switching this rebuilds the
  /// embed with a new key, which releases the previous WebView and stops its
  /// audio before the next one starts.
  PlayerSource? _selected;

  void _select(PlayerSource source) {
    setState(() {
      _selected = source;
      _openingSource = source.name;
    });
  }

  Uri? _urlFor(PlayerSource source) {
    try {
      return source.urlFor(
        widget.movie.id,
        widget.movie.mediaType,
        season: widget.season,
        episode: widget.episode,
      );
    } on Object {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final heroHeight = (width * 9 / 16).clamp(200.0, 380.0);

    return Scaffold(
      backgroundColor: const Color(0xFF090909),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.only(bottom: 32),
            children: [
              _Hero(
                height: heroHeight,
                imageUrl: widget.movie.backdropUrl ?? widget.movie.posterUrl,
              ),
              Transform.translate(
                offset: const Offset(0, -28),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.movie.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 26,
                          height: 1.15,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _MetaRow(movie: widget.movie),
                      if (widget.isEpisode) ...[
                        const SizedBox(height: 12),
                        _EpisodeChip(
                          season: widget.season!,
                          episode: widget.episode!,
                        ),
                      ],
                      const SizedBox(height: 22),
                      _InlinePlayer(
                        selected: _selected,
                        url: _selected == null ? null : _urlFor(_selected!),
                      ),
                      const SizedBox(height: 26),
                      Row(
                        children: [
                          Text(
                            'Sources',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.4,
                              color: Colors.white.withValues(alpha: 0.6),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${playerSources.length} available',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white38,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      for (final source in playerSources)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _SourceTile(
                            source: source,
                            busy: _openingSource == source.name,
                            selected: _selected?.name == source.name,
                            onTap: () => _select(source),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // Keeps the back button legible over a bright backdrop.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Container(
                height: kToolbarHeight + MediaQuery.paddingOf(context).top,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.7),
                      Colors.black.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Fixed 16:9 stage that previews the selected source in place.
///
/// Exactly one embed is alive at a time: the [ValueKey] includes the source
/// name, so switching sources rebuilds the subtree and releases the previous
/// platform WebView. Keeping several alive would leave multiple audio tracks
/// playing and hold a lot of memory.
class _InlinePlayer extends StatelessWidget {
  const _InlinePlayer({required this.selected, this.url});

  final PlayerSource? selected;
  final Uri? url;

  @override
  Widget build(BuildContext context) {
    final source = selected;
    final target = url;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: DecoratedBox(
              decoration: const BoxDecoration(color: Colors.black),
              child: target == null
                  ? const _PlayerPlaceholder()
                  : Stack(
                      fit: StackFit.expand,
                      children: [
                        EmbedPlayerView(
                          key: ValueKey('embed-${source!.name}'),
                          url: target,
                        ),
                      ],
                    ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          source == null
              ? 'Pick a source to start playing'
              : 'Now playing from ${source.name}',
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _PlayerPlaceholder extends StatelessWidget {
  const _PlayerPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.18),
                width: 1.5,
              ),
            ),
            child: const Icon(
              Icons.play_arrow_rounded,
              size: 32,
              color: Colors.white38,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Select a source',
            style: TextStyle(color: Colors.white38, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

/// Backdrop artwork that fades into the page background.
class _Hero extends StatelessWidget {
  const _Hero({required this.height, this.imageUrl});

  final double height;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          PosterImage(imageUrl: imageUrl, borderRadius: 0),
          // Fades to the scaffold colour so the title below reads cleanly.
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0, 0.55, 1],
                colors: [
                  Color(0x66000000),
                  Color(0x1A000000),
                  Color(0xFF090909),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Year, rating, media type and a short overview under the title.
class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.movie});

  final Movie movie;

  @override
  Widget build(BuildContext context) {
    final isSeries = movie.mediaType == 'tv';
    const secondary = TextStyle(
      color: Colors.white70,
      fontWeight: FontWeight.w600,
    );
    return Row(
      children: [
        Text(movie.year, style: secondary),
        const _Dot(),
        Icon(Icons.star_rounded, size: 16, color: Colors.amber),
        const SizedBox(width: 4),
        Text(movie.voteAverage.toStringAsFixed(1), style: secondary),
        const _Dot(),
        Icon(
          isSeries ? Icons.tv_rounded : Icons.movie_outlined,
          size: 15,
          color: Colors.white54,
        ),
        const SizedBox(width: 5),
        Text(
          isSeries ? 'Series' : 'Movie',
          style: const TextStyle(color: Colors.white54),
        ),
        if (movie.overview.isNotEmpty) ...[
          const _Dot(),
          Expanded(
            child: Text(
              movie.overview,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white38, height: 1.35),
            ),
          ),
        ],
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(horizontal: 8),
    child: Text('•', style: TextStyle(color: Colors.white24)),
  );
}

/// Season/episode pill for a series opened on a specific episode.
class _EpisodeChip extends StatelessWidget {
  const _EpisodeChip({required this.season, required this.episode});

  final int season;
  final int episode;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFE50914).withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: const Color(0xFFE50914).withValues(alpha: 0.45),
        ),
      ),
      child: Text(
        'Season $season  ·  Episode $episode',
        style: const TextStyle(
          color: Color(0xFFE50914),
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

/// One selectable playback provider.
class _SourceTile extends StatelessWidget {
  const _SourceTile({
    required this.source,
    required this.onTap,
    this.busy = false,
    this.selected = false,
  });

  final PlayerSource source;
  final VoidCallback onTap;
  final bool busy;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 160),
      opacity: busy ? 0.6 : 1,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? const Color(0xFFE50914) : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Material(
          color: busy ? const Color(0xFF241012) : const Color(0xFF161616),
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: busy ? null : onTap,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE50914).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      color: Color(0xFFE50914),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          source.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          source.host,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 22,
                    height: 22,
                    child: busy
                        ? const CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFFE50914),
                          )
                        : const Icon(
                            Icons.chevron_right_rounded,
                            color: Colors.white38,
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
