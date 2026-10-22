class PlayerSource {
  const PlayerSource({
    required this.name,
    required this.host,
    required this.urlBuilder,
    this.episodeUrlBuilder,
    this.requiresIframe = false,
  });

  final String name;
  final String host;

  /// Series- or movie-level embed URL.
  final Uri Function(int tmdbId, String mediaType) urlBuilder;

  /// Optional episode-aware URL for series. When null the source is opened at
  /// series level, which is the correct fallback: most embed providers render
  /// their own season/episode picker inside the player.
  ///
  /// Passing the episode through is a progressive enhancement, so a provider
  /// that does not understand the extra path segments simply shows its own
  /// picker rather than breaking.
  final Uri Function(int tmdbId, int season, int episode)? episodeUrlBuilder;
  final bool requiresIframe;

  Uri urlFor(int tmdbId, String mediaType, {int? season, int? episode}) {
    if (season != null && episode != null && episodeUrlBuilder != null) {
      return episodeUrlBuilder!(tmdbId, season, episode);
    }
    return urlBuilder(tmdbId, mediaType);
  }
}

final playerSources = <PlayerSource>[
  PlayerSource(
    name: 'Vidbolt',
    host: 'vidbolt.pro',
    requiresIframe: true,
    urlBuilder: (id, mediaType) =>
        Uri.parse('https://vidbolt.pro/$mediaType/$id'),
    episodeUrlBuilder: (id, season, episode) =>
        Uri.parse('https://vidbolt.pro/tv/$id/$season/$episode'),
  ),
  PlayerSource(
    name: 'Vidrift',
    host: 'embed.vidrift.net',
    urlBuilder: (id, mediaType) =>
        Uri.parse('https://embed.vidrift.net/embed/$mediaType/$id'),
    episodeUrlBuilder: (id, season, episode) =>
        Uri.parse('https://embed.vidrift.net/embed/tv/$id/$season/$episode'),
  ),
  PlayerSource(
    name: 'VidSrc',
    host: 'vidsrc.me',
    urlBuilder: (id, mediaType) =>
        Uri.parse('https://vidsrc.me/embed/$mediaType/$id'),
    episodeUrlBuilder: (id, season, episode) =>
        Uri.parse('https://vidsrc.me/embed/tv/$id/$season/$episode'),
  ),
  PlayerSource(
    name: 'CineSrc / NexVid',
    host: 'cinesrc.st',
    urlBuilder: (id, mediaType) =>
        Uri.parse('https://cinesrc.st/embed/$mediaType/$id'),
    episodeUrlBuilder: (id, season, episode) => Uri.parse(
      'https://cinesrc.st/embed/tv/$id?season=$season&episode=$episode',
    ),
  ),
];

final defaultPlayerSource = playerSources.firstWhere(
  (source) => source.name == 'Vidrift',
);
