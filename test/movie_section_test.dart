import 'package:flutter_test/flutter_test.dart';
import 'package:netflix_clone/src/models/movie.dart';

Movie _movie(int id, {String mediaType = 'movie'}) => Movie(
  id: id,
  title: 'Title $id',
  overview: '',
  posterPath: '/poster.jpg',
  backdropPath: null,
  releaseDate: '2026-01-01',
  voteAverage: 7,
  mediaType: mediaType,
);

void main() {
  test('append merges the next page without duplicating titles', () {
    final section = MovieSection(
      title: 'Trending',
      movies: [_movie(1), _movie(2)],
      request: const SectionRequest(
        title: 'Trending',
        path: '/trending/all/week',
      ),
    );

    final merged = section.append(
      MoviePage(movies: [_movie(2), _movie(3)], page: 2, totalPages: 4),
    );

    expect(merged.movies.map((movie) => movie.id), [1, 2, 3]);
    expect(merged.page, 2);
    expect(merged.totalPages, 4);
    expect(merged.hasMore, isTrue);
  });

  test('a movie and a series sharing an id are kept separate', () {
    final movies = mergeMovies([_movie(5)], [_movie(5, mediaType: 'tv')]);
    expect(movies, hasLength(2));
  });

  test('fallback sections without a request cannot page further', () {
    const section = MovieSection(title: 'Offline', movies: []);
    expect(section.hasMore, isFalse);
  });
}
