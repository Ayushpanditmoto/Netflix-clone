import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/movie.dart';

enum PlaybackMode { full, mini }

class PlaybackSession {
  const PlaybackSession({
    required this.movie,
    this.season,
    this.episode,
    this.mode = PlaybackMode.full,
  });

  final Movie movie;
  final int? season;
  final int? episode;
  final PlaybackMode mode;

  PlaybackSession copyWith({PlaybackMode? mode}) {
    return PlaybackSession(
      movie: movie,
      season: season,
      episode: episode,
      mode: mode ?? this.mode,
    );
  }
}

class PlaybackController extends Notifier<PlaybackSession?> {
  @override
  PlaybackSession? build() => null;

  void start(Movie movie, {int? season, int? episode}) {
    state = PlaybackSession(movie: movie, season: season, episode: episode);
  }

  void minimize() {
    if (state != null) state = state!.copyWith(mode: PlaybackMode.mini);
  }

  void expand() {
    if (state != null) state = state!.copyWith(mode: PlaybackMode.full);
  }

  void close() => state = null;
}

final playbackControllerProvider =
    NotifierProvider<PlaybackController, PlaybackSession?>(
      PlaybackController.new,
    );
