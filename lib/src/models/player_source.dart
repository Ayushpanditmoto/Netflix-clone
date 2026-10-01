class PlayerSource {
  const PlayerSource({
    required this.name,
    required this.host,
    required this.urlBuilder,
    this.episodeUrlBuilder,
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

  Uri urlFor(int tmdbId, String mediaType, {int? season, int? episode}) {
    if (season != null && episode != null && episodeUrlBuilder != null) {
      return episodeUrlBuilder!(tmdbId, season, episode);
    }
    return urlBuilder(tmdbId, mediaType);
  }
}

final playerSources = <PlayerSource>[
  PlayerSource(
    name: 'VidSrc',
    host: 'vidsrc.me',
    urlBuilder: (id, mediaType) =>
        Uri.parse('https://vidsrc.me/embed/$mediaType/$id'),
    // VidSrc documents /embed/tv/{id}/{season}/{episode}.
    episodeUrlBuilder: (id, season, episode) =>
        Uri.parse('https://vidsrc.me/embed/tv/$id/$season/$episode'),
  ),
  PlayerSource(
    name: 'CineSrc / NexVid',
    host: 'cinesrc.st',
    // The /embed path is the documented player page and the one the resolver
    // verifies against; /{type}/{id} is not a guaranteed embed route.
    urlBuilder: (id, mediaType) =>
        Uri.parse('https://cinesrc.st/embed/$mediaType/$id'),
    episodeUrlBuilder: (id, season, episode) =>
        Uri.parse('https://cinesrc.st/embed/tv/$id?season=$season&episode=$episode'),
  ),
  PlayerSource(
    name: 'FilmU',
    host: 'embed.filmu.in',
    urlBuilder: (id, mediaType) =>
        Uri.parse('https://embed.filmu.in/$mediaType/$id'),
  ),
  PlayerSource(
    name: 'PlayAPI',
    host: 'player.playapi.eu.cc',
    urlBuilder: (id, mediaType) =>
        Uri.parse('https://player.playapi.eu.cc/embed/$mediaType/$id'),
  ),
  PlayerSource(
    name: 'VidGod / NHD',
    host: 'vidgod.net',
    urlBuilder: (id, mediaType) =>
        Uri.parse('https://vidgod.net/embed/$mediaType/$id'),
  ),
  PlayerSource(
    name: 'Peachify Premium',
    host: 'peachify.top',
    urlBuilder: (id, mediaType) =>
        Uri.parse('https://peachify.top/embed/$mediaType/$id'),
  ),
];
