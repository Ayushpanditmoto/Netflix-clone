import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/movie.dart';
import '../../models/player_source.dart';
import '../../widgets/poster_image.dart';

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

  Future<void> _openSource(PlayerSource source) async {
    if (_openingSource != null) return;
    setState(() => _openingSource = source.name);

    final uri = source.urlFor(
      widget.movie.id,
      widget.movie.mediaType,
      season: widget.season,
      episode: widget.episode,
    );
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (!mounted) return;
    setState(() => _openingSource = null);
    if (!opened) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not open ${source.name}.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final previewHeight = (MediaQuery.sizeOf(context).width * 9 / 16).clamp(
      180.0,
      420.0,
    );

    return Scaffold(
      backgroundColor: const Color(0xFF090909),
      appBar: AppBar(title: const Text('Choose a source')),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 28),
          children: [
            SizedBox(
              height: previewHeight,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  PosterImage(
                    imageUrl:
                        widget.movie.backdropUrl ?? widget.movie.posterUrl,
                    borderRadius: 0,
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Color(0xE6090909)],
                      ),
                    ),
                  ),
                  const Center(
                    child: Icon(
                      Icons.play_circle_fill_rounded,
                      color: Colors.white,
                      size: 64,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.movie.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Select a playback source',
                    style: TextStyle(color: Colors.white60),
                  ),
                  if (widget.isEpisode)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        'Season ${widget.season} · Episode ${widget.episode}',
                        style: const TextStyle(
                          color: Color(0xFFE50914),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            for (final source in playerSources)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: ListTile(
                  minTileHeight: 64,
                  tileColor: const Color(0xFF1D1D1D),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  leading: const Icon(
                    Icons.play_circle_fill_rounded,
                    color: Color(0xFFE50914),
                  ),
                  title: Text(
                    source.name,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: Text(source.host),
                  trailing: _openingSource == source.name
                      ? const SizedBox.square(
                          dimension: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.open_in_new_rounded),
                  onTap: () => _openSource(source),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
