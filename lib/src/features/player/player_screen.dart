import 'package:flutter/material.dart';

import '../../models/movie.dart';
import '../../models/player_source.dart';
import 'embed_player_view.dart';
import 'episode_list.dart';

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
  /// Source currently loaded in the inline player.
  PlayerSource _selected = defaultPlayerSource;
  double _pullDownDistance = 0;

  /// Mutable season/episode — updated in-place when user taps an episode row
  /// so we stay on this screen instead of pushing a new PlayerScreen.
  late int? _season =
      widget.season ?? (widget.movie.mediaType == 'tv' ? 1 : null);
  late int? _episode =
      widget.episode ?? (widget.movie.mediaType == 'tv' ? 1 : null);

  bool get _isEpisode => _season != null && _episode != null;

  void _select(PlayerSource source) {
    setState(() => _selected = source);
  }

  /// Switches to a new episode in the same player screen.
  void _playEpisode(int season, int episode) {
    setState(() {
      _season = season;
      _episode = episode;
      // Keep the same source but reload the embed (new ValueKey will do it).
    });
  }

  void _closeAfterSwipe() {
    if (!mounted) return;
    _pullDownDistance = 0;
    Navigator.of(context).pop();
  }

  Uri? _urlFor(PlayerSource source) {
    try {
      return source.urlFor(
        widget.movie.id,
        widget.movie.mediaType,
        season: _season,
        episode: _episode,
      );
    } on Object {
      return null;
    }
  }

  /// Opens the source-picker bottom sheet (mirrors the web PlayerModal source list).
  Future<void> _showSourcePicker() async {
    await showModalBottomSheet<PlayerSource>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _SourcePickerSheet(
        sources: playerSources,
        selected: _selected,
        onSelect: (source) {
          Navigator.of(context).pop();
          _select(source);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF090909),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const SizedBox(height: 28),
            _InlinePlayer(
              selected: _selected,
              season: _season,
              episode: _episode,
              url: _urlFor(_selected),
            ),
            Expanded(
              child: NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  if (notification is OverscrollNotification &&
                      notification.metrics.pixels <= 0 &&
                      notification.overscroll < 0) {
                    _pullDownDistance += -notification.overscroll;
                    if (_pullDownDistance >= 80) {
                      _closeAfterSwipe();
                    }
                  } else if (notification is ScrollEndNotification) {
                    _pullDownDistance = 0;
                  }
                  return false;
                },
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(0, 16, 0, 32),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
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
                          const SizedBox(height: 18),

                          // ── 1. Episode and source controls ─────────────────────
                          if (_isEpisode)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: _EpisodeChip(
                                    season: _season!,
                                    episode: _episode!,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  flex: 2,
                                  child: _SourceSelectorBar(
                                    selected: _selected,
                                    totalSources: playerSources.length,
                                    onTap: _showSourcePicker,
                                    compact: true,
                                  ),
                                ),
                              ],
                            )
                          else
                            _SourceSelectorBar(
                              selected: _selected,
                              totalSources: playerSources.length,
                              onTap: _showSourcePicker,
                            ),
                          if (widget.movie.overview.isNotEmpty) ...[
                            const SizedBox(height: 18),
                            Text(
                              widget.movie.overview,
                              maxLines: 4,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white70,
                                height: 1.45,
                              ),
                            ),
                          ],
                          const SizedBox(height: 24),

                          // ── 2. Episodes (TV series only) ───────────────────────
                          if (widget.movie.mediaType == 'tv') ...[
                            Row(
                              children: [
                                const Text(
                                  'Episodes',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const Spacer(),
                                if (_isEpisode)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE50914)
                                          .withValues(alpha: 0.14),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: const Color(0xFFE50914)
                                            .withValues(alpha: 0.45),
                                      ),
                                    ),
                                    child: Text(
                                      'Playing · S$_season E$_episode',
                                      style: const TextStyle(
                                        color: Color(0xFFE50914),
                                        fontWeight: FontWeight.w800,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            EpisodeList(
                              movie: widget.movie,
                              onEpisodeTap: _playEpisode,
                            ),
                            const SizedBox(height: 8),
                          ],

                          // ── Disclaimer ─────────────────────────────────────────
                          Text(
                            '⚠️ Educational demo only. Sources are third-party embeds not operated by this project.',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white.withValues(alpha: 0.28),
                              height: 1.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Compact source-selector bar
// ─────────────────────────────────────────────────────────────────────────────

class _SourceSelectorBar extends StatelessWidget {
  const _SourceSelectorBar({
    required this.selected,
    required this.totalSources,
    required this.onTap,
    this.compact = false,
  });

  final PlayerSource? selected;
  final int totalSources;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final hasSelection = selected != null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.fromLTRB(
          compact ? 10 : 14,
          compact ? 8 : 12,
          compact ? 10 : 14,
          compact ? 8 : 12,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF161616),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasSelection
                ? const Color(0xFFE50914).withValues(alpha: 0.55)
                : Colors.white.withValues(alpha: 0.1),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: compact ? 30 : 38,
              height: compact ? 30 : 38,
              decoration: BoxDecoration(
                color: hasSelection
                    ? const Color(0xFFE50914).withValues(alpha: 0.15)
                    : Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                hasSelection
                    ? Icons.play_arrow_rounded
                    : Icons.video_library_outlined,
                color: hasSelection ? const Color(0xFFE50914) : Colors.white38,
                size: compact ? 18 : 22,
              ),
            ),
            SizedBox(width: compact ? 7 : 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!compact)
                    Text(
                      hasSelection ? 'Now playing from' : 'Select a source',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.45),
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                  if (hasSelection) ...[
                    if (!compact) const SizedBox(height: 2),
                    Text(
                      selected!.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    if (!compact)
                      Text(
                        selected!.host,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white38,
                        ),
                      ),
                  ],
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!compact)
                  Text(
                    hasSelection ? 'Change' : '$totalSources available',
                    style: TextStyle(
                      fontSize: 12,
                      color: hasSelection
                          ? const Color(0xFFE50914)
                          : Colors.white38,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                const SizedBox(height: 2),
                const Icon(
                  Icons.expand_more_rounded,
                  size: 18,
                  color: Colors.white38,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom-sheet source picker
// ─────────────────────────────────────────────────────────────────────────────

class _SourcePickerSheet extends StatelessWidget {
  const _SourcePickerSheet({
    required this.sources,
    required this.onSelect,
    this.selected,
  });

  final List<PlayerSource> sources;
  final PlayerSource? selected;
  final ValueChanged<PlayerSource> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      decoration: const BoxDecoration(
        color: Color(0xFF121212),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
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
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Row(
              children: [
                const Text(
                  'SOURCES',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.6,
                    color: Colors.white60,
                  ),
                ),
                const Spacer(),
                Text(
                  '${sources.length} available',
                  style: const TextStyle(fontSize: 12, color: Colors.white38),
                ),
              ],
            ),
          ),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.55,
            ),
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              itemCount: sources.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final source = sources[i];
                final isSelected = selected?.name == source.name;
                return _SourceSheetTile(
                  source: source,
                  isSelected: isSelected,
                  onTap: () => onSelect(source),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SourceSheetTile extends StatelessWidget {
  const _SourceSheetTile({
    required this.source,
    required this.onTap,
    this.isSelected = false,
  });

  final PlayerSource source;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? const Color(0xFFE50914) : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: Material(
        color: isSelected ? const Color(0xFF241012) : const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
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
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFFE50914)
                        : Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isSelected ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Inline player (16:9 embed stage)
// ─────────────────────────────────────────────────────────────────────────────

class _InlinePlayer extends StatelessWidget {
  const _InlinePlayer({
    required this.selected,
    this.url,
    this.season,
    this.episode,
  });

  final PlayerSource? selected;
  final Uri? url;
  final int? season;
  final int? episode;

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
                  : EmbedPlayerView(
                      key: ValueKey('embed-${source!.name}-$season-$episode'),
                      url: target,
                      requiresIframe: source.requiresIframe,
                    ),
            ),
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
            'Select a source to start playing',
            style: TextStyle(color: Colors.white38, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Metadata row
// ─────────────────────────────────────────────────────────────────────────────

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
        const Icon(Icons.star_rounded, size: 16, color: Colors.amber),
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

// ─────────────────────────────────────────────────────────────────────────────
// Episode chip
// ─────────────────────────────────────────────────────────────────────────────

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
