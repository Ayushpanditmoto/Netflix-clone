import 'package:flutter/material.dart';

import '../../models/movie.dart';
import '../../models/player_source.dart';
import 'embed_player_view.dart';
import 'player_screen.dart';

class PlayerSession extends ChangeNotifier {
  Movie? movie;
  PlayerSource source = defaultPlayerSource;
  int? season;
  int? episode;
  bool isMinimized = false;

  bool get isActive => movie != null;

  void start({
    required Movie value,
    required PlayerSource selectedSource,
    int? selectedSeason,
    int? selectedEpisode,
  }) {
    movie = value;
    source = selectedSource;
    season = selectedSeason;
    episode = selectedEpisode;
    isMinimized = false;
    notifyListeners();
  }

  void update({
    required PlayerSource selectedSource,
    int? selectedSeason,
    int? selectedEpisode,
  }) {
    source = selectedSource;
    season = selectedSeason;
    episode = selectedEpisode;
    notifyListeners();
  }

  void minimize() {
    if (!isActive) return;
    isMinimized = true;
    notifyListeners();
  }

  void restore() {
    if (!isActive) return;
    isMinimized = false;
    notifyListeners();
  }

  void stop() {
    movie = null;
    isMinimized = false;
    notifyListeners();
  }
}

class PlayerHost extends StatefulWidget {
  const PlayerHost({super.key, required this.child});

  final Widget child;

  @override
  State<PlayerHost> createState() => _PlayerHostState();
}

class _PlayerHostState extends State<PlayerHost> {
  final session = PlayerSession();

  @override
  Widget build(BuildContext context) {
    return PlayerSessionScope(
      session: session,
      child: Stack(
        children: [
          widget.child,
          AnimatedBuilder(
            animation: session,
            builder: (context, _) {
              if (!session.isActive || !session.isMinimized) {
                return const SizedBox.shrink();
              }
              return _MiniPlayer(session: session);
            },
          ),
        ],
      ),
    );
  }
}

class PlayerSessionScope extends InheritedNotifier<PlayerSession> {
  const PlayerSessionScope({
    super.key,
    required PlayerSession session,
    required super.child,
  }) : super(notifier: session);

  static PlayerSession of(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<PlayerSessionScope>()!
      .notifier!;
}

class _MiniPlayer extends StatelessWidget {
  const _MiniPlayer({required this.session});

  final PlayerSession session;

  @override
  Widget build(BuildContext context) {
    final movie = session.movie!;
    final url = session.source.urlFor(
      movie.id,
      movie.mediaType,
      season: session.season,
      episode: session.episode,
    );

    return Positioned(
      left: 10,
      right: 10,
      bottom: 10,
      child: Material(
        color: const Color(0xFF202020),
        elevation: 12,
        borderRadius: BorderRadius.circular(10),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            session.restore();
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => PlayerScreen(
                  movie: movie,
                  season: session.season,
                  episode: session.episode,
                ),
              ),
            );
          },
          child: Row(
            children: [
              SizedBox(
                width: 112,
                height: 64,
                child: EmbedPlayerView(
                  key: ValueKey(
                    'mini-${movie.id}-${session.source.name}-'
                    '${session.season}-${session.episode}',
                  ),
                  url: url,
                  requiresIframe: session.source.requiresIframe,
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    movie.mediaType == 'tv' && session.season != null
                        ? '${movie.title} · S${session.season} E${session.episode}'
                        : movie.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Stop playback',
                onPressed: session.stop,
                icon: const Icon(Icons.close),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
