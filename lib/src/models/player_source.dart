class PlayerSource {
  const PlayerSource({
    required this.name,
    required this.host,
    required this.urlBuilder,
  });

  final String name;
  final String host;
  final Uri Function(int tmdbId, String mediaType) urlBuilder;
}

final playerSources = <PlayerSource>[
  PlayerSource(
    name: 'VidSrc',
    host: 'vidsrc.me',
    urlBuilder: (id, mediaType) =>
        Uri.parse('https://vidsrc.me/embed/$mediaType/$id'),
  ),
  PlayerSource(
    name: 'CineSrc / NexVid',
    host: 'cinesrc.st',
    urlBuilder: (id, mediaType) =>
        Uri.parse('https://cinesrc.st/$mediaType/$id'),
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
