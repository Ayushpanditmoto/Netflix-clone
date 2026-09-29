import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/movie.dart';

const _tmdbApiKey = String.fromEnvironment(
  'TMDB_API_KEY',
  defaultValue: '9e7096a7575623aa30c66e9cc987e411',
);

final class TmdbRepository {
  TmdbRepository({http.Client? client, this.apiKey = _tmdbApiKey})
    : _client = client ?? http.Client();

  final http.Client _client;
  final String apiKey;

  Future<List<MovieSection>> homeSections() async {
    if (apiKey.isEmpty) return fallbackSections;

    final requests = <_SectionRequest>[
      const _SectionRequest(
        title: 'Trending this week',
        path: '/trending/all/week',
      ),
      const _SectionRequest(
        title: 'Now playing',
        path: '/movie/now_playing',
        mediaType: 'movie',
      ),
      const _SectionRequest(
        title: 'Trending movies',
        path: '/trending/movie/week',
        mediaType: 'movie',
      ),
      const _SectionRequest(
        title: 'Popular international movies',
        path: '/discover/movie',
        mediaType: 'movie',
        params: {
          'with_original_language': 'zh|ko|ja',
          'sort_by': 'popularity.desc',
          'include_adult': 'false',
        },
      ),
      const _SectionRequest(
        title: 'Popular movies',
        path: '/movie/popular',
        mediaType: 'movie',
      ),
      const _SectionRequest(
        title: 'Top rated movies',
        path: '/movie/top_rated',
        mediaType: 'movie',
      ),
      const _SectionRequest(
        title: 'Trending series',
        path: '/trending/tv/week',
        mediaType: 'tv',
      ),
      const _SectionRequest(
        title: 'Asian series',
        path: '/discover/tv',
        mediaType: 'tv',
        params: {
          'with_original_language': 'ko|ja|zh',
          'sort_by': 'popularity.desc',
          'include_adult': 'false',
          'first_air_date.gte': '2020-01-01',
        },
      ),
      const _SectionRequest(
        title: 'More Asian series',
        path: '/discover/tv',
        mediaType: 'tv',
        params: {
          'with_original_language': 'ko|ja|zh',
          'sort_by': 'popularity.desc',
          'include_adult': 'false',
          'first_air_date.gte': '2020-01-01',
          'page': '2',
        },
      ),
    ];

    final sections = await Future.wait(
      requests.map((request) => _loadSection(request)),
    );
    final available = sections.whereType<MovieSection>().toList(
      growable: false,
    );
    return available.isEmpty ? fallbackSections : available;
  }

  Future<MovieSection?> _loadSection(_SectionRequest request) async {
    try {
      final response = await _get(request.path, request.params);
      final movies = _movies(response, mediaType: request.mediaType)
          .where(
            (movie) => movie.mediaType == 'movie' || movie.mediaType == 'tv',
          )
          .toList(growable: false);
      if (movies.isEmpty) return null;
      return MovieSection(title: request.title, movies: movies);
    } catch (_) {
      return null;
    }
  }

  Future<List<Movie>> search(String query) async {
    final cleaned = query.trim();
    if (cleaned.isEmpty) return const [];
    if (apiKey.isEmpty) {
      final all = fallbackSections.expand((section) => section.movies);
      return all
          .where(
            (movie) =>
                movie.title.toLowerCase().contains(cleaned.toLowerCase()),
          )
          .toList(growable: false);
    }

    try {
      final response = await _get('/search/multi', {
        'query': cleaned,
        'include_adult': 'false',
      });
      return _movies(response)
          .where(
            (movie) => movie.mediaType == 'movie' || movie.mediaType == 'tv',
          )
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  Future<Map<String, dynamic>> _get(
    String path, [
    Map<String, String>? params,
  ]) async {
    final uri = Uri.https('api.themoviedb.org', '/3$path', {
      'api_key': apiKey,
      'language': 'en-US',
      ...?params,
    });
    final response = await _client.get(uri);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('TMDB request failed with ${response.statusCode}');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  List<Movie> _movies(Map<String, dynamic> response, {String? mediaType}) {
    final results = (response['results'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(
          (json) =>
              mediaType == null ? json : {...json, 'media_type': mediaType},
        )
        .map(Movie.fromTmdb)
        .where(
          (movie) => movie.posterPath != null || movie.backdropPath != null,
        )
        .toList(growable: false);
    return results;
  }
}

final class _SectionRequest {
  const _SectionRequest({
    required this.title,
    required this.path,
    this.mediaType,
    this.params,
  });

  final String title;
  final String path;
  final String? mediaType;
  final Map<String, String>? params;
}

const fallbackSections = [
  MovieSection(
    title: 'Trending now',
    movies: [
      Movie(
        id: 872585,
        title: 'Oppenheimer',
        overview: 'The story of J. Robert Oppenheimer and the creation of the atomic bomb.',
        posterPath: '/8Gxv8gSFCU0XGDykEGv7zR1n2ua.jpg',
        backdropPath: '/fm6KqXpk3M2HVveHwCrBSSBaO0V.jpg',
        releaseDate: '2023-07-19',
        voteAverage: 8.1,
      ),
      Movie(
        id: 603692,
        title: 'John Wick: Chapter 4',
        overview: 'John Wick uncovers a path to defeating the High Table.',
        posterPath: '/vZloFAK7NmvMGKE7VkF5UHaz0I.jpg',
        backdropPath: '/i3OTGmLNOZIo4SRQLVfLjeWegB6.jpg',
        releaseDate: '2023-03-22',
        voteAverage: 7.7,
      ),
      Movie(
        id: 76600,
        title: 'Avatar: The Way of Water',
        overview: 'Jake Sully and Neytiri fight to keep their family safe on Pandora.',
        posterPath: '/t6HIqrRAclMCA60NsSmeqe9RmNV.jpg',
        backdropPath: '/s16H6tpK2utvwDtzZ8Qy4qm5Emw.jpg',
        releaseDate: '2022-12-14',
        voteAverage: 7.6,
      ),
    ],
  ),
  MovieSection(
    title: 'Popular on StreamFlix',
    movies: [
      Movie(
        id: 550,
        title: 'Fight Club',
        overview: 'An insomniac office worker and a soap maker form an underground fight club.',
        posterPath: '/pB8BM7pdSp6B6Ih7QZ4DrQ3PmJK.jpg',
        backdropPath: '/hZkgoQYus5vegHoetLkCJzb17zJ.jpg',
        releaseDate: '1999-10-15',
        voteAverage: 8.4,
      ),
      Movie(
        id: 155,
        title: 'The Dark Knight',
        overview: 'Batman faces the Joker, a criminal mastermind plunging Gotham into chaos.',
        posterPath: '/qJ2tW6WMUDux911r6m7haRef0WH.jpg',
        backdropPath: '/nMKdUUepR0i5zn0y1T4CsSB5chy.jpg',
        releaseDate: '2008-07-16',
        voteAverage: 8.5,
      ),
      Movie(
        id: 13,
        title: 'Forrest Gump',
        overview: 'A kind-hearted Alabama man finds himself present at major historical events.',
        posterPath: '/arw2vcBveWOVZr6pxd9XTd1TdQa.jpg',
        backdropPath: '/3h1JZGDhZ8nzxdgvkxha0qBqi05.jpg',
        releaseDate: '1994-06-23',
        voteAverage: 8.5,
      ),
    ],
  ),
  MovieSection(
    title: 'Series picks',
    movies: [
      Movie(
        id: 1399,
        title: 'Game of Thrones',
        overview: 'Noble families vie for control of the Iron Throne.',
        posterPath: '/1XS1oqL89opfnbLl8WnZY1O1uJx.jpg',
        backdropPath: '/2OMB0ynKlyIenMJWI2Dy9IWT4c.jpg',
        releaseDate: '2011-04-17',
        voteAverage: 8.4,
        mediaType: 'tv',
      ),
      Movie(
        id: 66732,
        title: 'Stranger Things',
        overview:
            'A small town uncovers secret experiments and supernatural forces.',
        posterPath: '/uOOtwVbSr4QDjAGIifLDwpb2Pdl.jpg',
        backdropPath: '/56v2KjBlU4XaOv9rVYEQypROD7P.jpg',
        releaseDate: '2016-07-15',
        voteAverage: 8.6,
        mediaType: 'tv',
      ),
      Movie(
        id: 94997,
        title: 'House of the Dragon',
        overview: 'The story of House Targaryen, set centuries before Game of Thrones.',
        posterPath: '/z2yahl2uefxDCl0nogcRBstwruJ.jpg',
        backdropPath: '/etj8E2o0Bud0HkONVQPjyCkIvpv.jpg',
        releaseDate: '2022-08-21',
        voteAverage: 8.4,
        mediaType: 'tv',
      ),
    ],
  ),
];
