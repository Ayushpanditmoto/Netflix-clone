/// Builds a full TMDB image URL for [path] at the given [size].
///
/// Lives apart from [Movie] so series metadata can reuse the exact same CDN
/// rules instead of duplicating the base URL string.
String? tmdbImageUrl(String? path, String size) {
  if (path == null || path.isEmpty) return null;
  return 'https://image.tmdb.org/t/p/$size$path';
}

class Movie {
  const Movie({
    required this.id,
    required this.title,
    required this.overview,
    required this.posterPath,
    required this.backdropPath,
    required this.releaseDate,
    required this.voteAverage,
    this.mediaType = 'movie',
  });

  final int id;
  final String title;
  final String overview;
  final String? posterPath;
  final String? backdropPath;
  final String releaseDate;
  final double voteAverage;
  final String mediaType;

  String get year =>
      releaseDate.length >= 4 ? releaseDate.substring(0, 4) : 'New';
  String? get posterUrl => tmdbImageUrl(posterPath, 'w500');
  String? get backdropUrl => tmdbImageUrl(backdropPath, 'w1280');

  factory Movie.fromTmdb(Map<String, dynamic> json) {
    final title =
        json['title'] ?? json['name'] ?? json['original_title'] ?? 'Untitled';
    final releaseDate = json['release_date'] ?? json['first_air_date'] ?? '';

    return Movie(
      id: json['id'] as int,
      title: title as String,
      overview: (json['overview'] ?? '') as String,
      posterPath: json['poster_path'] as String?,
      backdropPath: json['backdrop_path'] as String?,
      releaseDate: releaseDate as String,
      voteAverage: ((json['vote_average'] ?? 0) as num).toDouble(),
      mediaType: (json['media_type'] ?? 'movie') as String,
    );
  }
}

/// A single season of a series, as listed by `/tv/{id}`.
///
/// Season `0` is TMDB's "Specials" bucket, so it is kept in the list rather
/// than filtered out.
class Season {
  const Season({
    required this.number,
    required this.name,
    required this.episodeCount,
    this.overview = '',
    this.posterPath,
    this.airDate = '',
  });

  final int number;
  final String name;
  final int episodeCount;
  final String overview;
  final String? posterPath;
  final String airDate;

  String? get posterUrl => tmdbImageUrl(posterPath, 'w300');

  /// TMDB labels season 0 "Specials"; the rest arrive as "Season N".
  factory Season.fromTmdb(Map<String, dynamic> json) {
    final number = (json['season_number'] as num?)?.toInt() ?? 0;
    final name = (json['name'] as String?)?.trim();
    return Season(
      number: number,
      name: name == null || name.isEmpty
          ? (number == 0 ? 'Specials' : 'Season $number')
          : name,
      episodeCount: (json['episode_count'] as num?)?.toInt() ?? 0,
      overview: (json['overview'] ?? '') as String,
      posterPath: json['poster_path'] as String?,
      airDate: (json['air_date'] ?? '') as String,
    );
  }
}

/// One episode of a season, as listed by `/tv/{id}/season/{n}`.
class Episode {
  const Episode({
    required this.id,
    required this.number,
    required this.seasonNumber,
    required this.title,
    this.overview = '',
    this.stillPath,
    this.airDate = '',
    this.runtime,
    this.voteAverage = 0,
  });

  final int id;
  final int number;
  final int seasonNumber;
  final String title;
  final String overview;
  final String? stillPath;
  final String airDate;
  final int? runtime;
  final double voteAverage;

  String? get stillUrl => tmdbImageUrl(stillPath, 'w300');

  /// `2011-04-17` rendered as `Apr 17, 2011`, or an empty string when TMDB has
  /// no air date for the episode yet.
  String get airDateLabel {
    if (airDate.length < 10) return '';
    final parsed = DateTime.tryParse(airDate);
    if (parsed == null) return '';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[parsed.month - 1]} ${parsed.day}, ${parsed.year}';
  }

  /// e.g. `1x02`, the notation streaming sites use in their episode lists.
  String get code => '${seasonNumber}x${number.toString().padLeft(2, '0')}';

  factory Episode.fromTmdb(Map<String, dynamic> json) {
    return Episode(
      id: (json['id'] as num?)?.toInt() ?? 0,
      number: (json['episode_number'] as num?)?.toInt() ?? 0,
      seasonNumber: (json['season_number'] as num?)?.toInt() ?? 0,
      title: (json['name'] ?? 'Episode') as String,
      overview: (json['overview'] ?? '') as String,
      stillPath: json['still_path'] as String?,
      airDate: (json['air_date'] ?? '') as String,
      runtime: (json['runtime'] as num?)?.toInt(),
      voteAverage: ((json['vote_average'] ?? 0) as num).toDouble(),
    );
  }
}

/// A single page of movies returned by a paginated TMDB endpoint.
class MoviePage {
  const MoviePage({required this.movies, this.page = 1, this.totalPages = 1});

  final List<Movie> movies;
  final int page;
  final int totalPages;

  bool get hasMore => page < totalPages;
}

/// Describes a paginated TMDB collection, so a section can be fetched again
/// with `page + 1` when the user reaches the end of a rail.
class SectionRequest {
  const SectionRequest({
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

class MovieSection {
  const MovieSection({
    required this.title,
    required this.movies,
    this.request,
    this.page = 1,
    this.totalPages = 1,
  });

  final String title;
  final List<Movie> movies;

  /// `null` for the offline fallback catalog, which cannot be paginated.
  final SectionRequest? request;
  final int page;
  final int totalPages;

  bool get hasMore => request != null && page < totalPages;

  MovieSection copyWith({List<Movie>? movies, int? page, int? totalPages}) {
    return MovieSection(
      title: title,
      movies: movies ?? this.movies,
      request: request,
      page: page ?? this.page,
      totalPages: totalPages ?? this.totalPages,
    );
  }

  /// Appends a newly loaded page, skipping titles that are already present.
  MovieSection append(MoviePage next) {
    return copyWith(
      movies: mergeMovies(movies, next.movies),
      page: next.page,
      totalPages: next.totalPages,
    );
  }
}

/// Concatenates [movies] and [incoming] while dropping duplicates, so the
/// same title never appears twice after paging.
List<Movie> mergeMovies(List<Movie> movies, List<Movie> incoming) {
  final seen = <String>{for (final movie in movies) _movieKey(movie)};
  return [...movies, ...incoming.where((movie) => seen.add(_movieKey(movie)))];
}

String _movieKey(Movie movie) => '${movie.mediaType}:${movie.id}';
