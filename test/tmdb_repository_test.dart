import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:netflix_clone/src/services/tmdb_repository.dart';

void main() {
  test('loads all home collections with the correct TMDB filters', () async {
    final requestedUris = <Uri>[];
    final client = MockClient((request) async {
      requestedUris.add(request.url);
      return http.Response(
        jsonEncode({
          'results': [
            {
              'id': requestedUris.length,
              'title': 'Title ${requestedUris.length}',
              'overview': 'Overview',
              'poster_path': '/poster.jpg',
              'backdrop_path': '/backdrop.jpg',
              'release_date': '2026-01-01',
              'vote_average': 8.0,
              if (request.url.path == '/3/trending/all/week')
                'media_type': 'movie',
            },
          ],
        }),
        200,
      );
    });
    final repository = TmdbRepository(client: client, apiKey: 'test-key');

    final sections = await repository.homeSections();

    expect(sections, hasLength(9));
    expect(sections.first.title, 'Trending this week');
    expect(sections.last.title, 'More Asian series');
    expect(sections[1].movies.single.mediaType, 'movie');
    expect(sections[6].movies.single.mediaType, 'tv');

    final internationalMovies = requestedUris.singleWhere(
      (uri) => uri.path == '/3/discover/movie',
    );
    expect(
      internationalMovies.queryParameters['with_original_language'],
      'zh|ko|ja',
    );

    final asianSeriesPageTwo = requestedUris.singleWhere(
      (uri) =>
          uri.path == '/3/discover/tv' && uri.queryParameters['page'] == '2',
    );
    expect(
      asianSeriesPageTwo.queryParameters['first_air_date.gte'],
      '2020-01-01',
    );
  });

  test('keeps available collections when one request fails', () async {
    final client = MockClient((request) async {
      if (request.url.path == '/3/movie/now_playing') {
        return http.Response('Unavailable', 503);
      }
      return http.Response(
        jsonEncode({
          'results': [
            {
              'id': request.url.path.hashCode,
              'title': 'Available title',
              'overview': '',
              'poster_path': '/poster.jpg',
              'release_date': '2026-01-01',
              'vote_average': 7.0,
              if (request.url.path == '/3/trending/all/week')
                'media_type': 'movie',
            },
          ],
        }),
        200,
      );
    });

    final sections = await TmdbRepository(
      client: client,
      apiKey: 'test-key',
    ).homeSections();

    expect(sections, hasLength(8));
    expect(
      sections.map((section) => section.title),
      isNot(contains('Now playing')),
    );
  });

  test('exposes paging cursors and loads later pages on demand', () async {
    final requestedUris = <Uri>[];
    final client = MockClient((request) async {
      requestedUris.add(request.url);
      final page = int.parse(request.url.queryParameters['page'] ?? '1');
      return http.Response(
        jsonEncode({
          'page': page,
          'total_pages': 5,
          'results': [
            {
              'id': page * 100,
              'title': 'Page $page title',
              'overview': '',
              'poster_path': '/poster.jpg',
              'release_date': '2026-01-01',
              'vote_average': 7.0,
              if (request.url.path == '/3/trending/all/week')
                'media_type': 'movie',
            },
          ],
        }),
        200,
      );
    });
    final repository = TmdbRepository(client: client, apiKey: 'test-key');

    final sections = await repository.homeSections();
    final first = sections.first;

    expect(first.page, 1);
    expect(first.totalPages, 5);
    expect(first.hasMore, isTrue);

    final next = await repository.loadSectionPage(
      first.request!,
      first.page + 1,
    );

    expect(next, isNotNull);
    expect(next!.page, 2);
    expect(next.movies.single.title, 'Page 2 title');
    expect(
      requestedUris.last.queryParameters['page'],
      '2',
      reason: 'load more should request the next TMDB page',
    );
  });

  test('search pages through results and reports when more remain', () async {
    final requestedUris = <Uri>[];
    final client = MockClient((request) async {
      requestedUris.add(request.url);
      final page = int.parse(request.url.queryParameters['page'] ?? '1');
      return http.Response(
        jsonEncode({
          'page': page,
          'total_pages': 3,
          'results': [
            {
              'id': page,
              'title': 'Result $page',
              'overview': '',
              'poster_path': '/poster.jpg',
              'release_date': '2026-01-01',
              'vote_average': 6.0,
              'media_type': 'movie',
            },
          ],
        }),
        200,
      );
    });
    final repository = TmdbRepository(client: client, apiKey: 'test-key');

    final first = await repository.searchPage('batman');
    expect(first.page, 1);
    expect(first.totalPages, 3);
    expect(first.hasMore, isTrue);
    expect(first.movies.single.title, 'Result 1');

    final second = await repository.searchPage('batman', page: 2);
    expect(second.page, 2);
    expect(second.movies.single.title, 'Result 2');
    expect(requestedUris.last.queryParameters['page'], '2');

    final blank = await repository.searchPage('   ');
    expect(blank.movies, isEmpty);
  });
}
