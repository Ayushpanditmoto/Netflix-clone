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

class MovieSection {
  const MovieSection({required this.title, required this.movies});

  final String title;
  final List<Movie> movies;
}
