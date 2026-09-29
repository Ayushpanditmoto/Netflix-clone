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
  String? get posterUrl => _tmdbImage(posterPath, 'w500');
  String? get backdropUrl => _tmdbImage(backdropPath, 'w1280');

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

  static String? _tmdbImage(String? path, String size) {
    if (path == null || path.isEmpty) return null;
    return 'https://image.tmdb.org/t/p/$size$path';
  }
}

/// A single page of movies returned by a paginated TMDB endpoint.
class MoviePage {
  const MoviePage({
    required this.movies,
    this.page = 1,
    this.totalPages = 1,
  });

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

  MovieSection copyWith({
    List<Movie>? movies,
    int? page,
    int? totalPages,
  }) {
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
  return [
    ...movies,
    ...incoming.where((movie) => seen.add(_movieKey(movie))),
  ];
}

String _movieKey(Movie movie) => '${movie.mediaType}:${movie.id}';
