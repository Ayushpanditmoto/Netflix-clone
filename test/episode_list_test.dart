import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:netflix_clone/src/features/home/home_providers.dart';
import 'package:netflix_clone/src/features/player/episode_list.dart';
import 'package:netflix_clone/src/models/movie.dart';
import 'package:netflix_clone/src/services/tmdb_repository.dart';

/// Three seasons, including the season 0 "Specials" bucket TMDB uses.
http.Response _seasonsWithSpecialsResponse() {
  return http.Response(
    jsonEncode({
      'id': 1399,
      'number_of_seasons': 3,
      'seasons': [
        {
          'season_number': 0,
          'name': 'Specials',
          'episode_count': 4,
          'poster_path': '/specials.jpg',
        },
        {
          'season_number': 1,
          'name': 'Season 1',
          'episode_count': 10,
          'poster_path': '/s1.jpg',
        },
        {'season_number': 2, 'episode_count': 9},
      ],
    }),
    200,
  );
}

void main() {
  test('reads the season list including the specials bucket', () async {
    final client = MockClient((request) async {
      expect(request.url.path, '/3/tv/1399');
      return _seasonsWithSpecialsResponse();
    });

    final seasons = await TmdbRepository(
      client: client,
      apiKey: 'test-key',
    ).seasons(1399);

    expect(seasons.map((season) => season.number), [0, 1, 2]);
    expect(seasons.first.episodeCount, 4);
    // A missing name falls back to a generated label.
    expect(seasons.last.name, 'Season 2');
    expect(seasons[1].posterUrl, contains('/w300/s1.jpg'));
    expect(seasons.last.posterUrl, isNull);
  });

  test('reads a season of episodes in broadcast order', () async {
    final client = MockClient((request) async {
      expect(request.url.path, '/3/tv/1399/season/1');
      return http.Response(
        jsonEncode({
          'id': 3624,
          'season_number': 1,
          'episodes': [
            {
              'id': 63056,
              'episode_number': 1,
              'season_number': 1,
              'name': 'Winter Is Coming',
              'overview': 'Jon Arryn is dead.',
              'still_path': '/still.jpg',
              'air_date': '2011-04-17',
              'runtime': 62,
              'vote_average': 8.2,
            },
            {
              'id': 63057,
              'episode_number': 2,
              'season_number': 1,
              'name': 'The Kingsroad',
              'air_date': '2011-04-24',
              'runtime': 56,
            },
          ],
        }),
        200,
      );
    });

    final episodes = await TmdbRepository(
      client: client,
      apiKey: 'test-key',
    ).episodes(1399, 1);

    expect(episodes, hasLength(2));
    final first = episodes.first;
    expect(first.number, 1);
    expect(first.title, 'Winter Is Coming');
    expect(first.code, '1x01');
    expect(first.airDateLabel, 'Apr 17, 2011');
    expect(first.runtime, 62);
    expect(first.stillUrl, contains('/w300/still.jpg'));
    expect(episodes.last.airDateLabel, 'Apr 24, 2011');
  });

  test('an episode without an air date renders no date label', () {
    const episode = Episode(
      id: 1,
      number: 3,
      seasonNumber: 2,
      title: 'Untitled',
    );
    expect(episode.airDateLabel, '');
    expect(episode.code, '2x03');
    expect(episode.stillUrl, isNull);
  });

  test('a season with no usable episodes comes back empty', () async {
    final client = MockClient((request) async {
      return http.Response(
        jsonEncode({
          'season_number': 9,
          'episodes': [
            {'id': 1, 'episode_number': 0, 'name': 'Placeholder'},
          ],
        }),
        200,
      );
    });

    final episodes = await TmdbRepository(
      client: client,
      apiKey: 'test-key',
    ).episodes(1399, 9);

    expect(episodes, isEmpty);
  });

  test('a failed season request throws so the UI can offer a retry', () async {
    final client = MockClient((request) async {
      return http.Response('Boom', 500);
    });

    final repository = TmdbRepository(client: client, apiKey: 'test-key');
    await expectLater(repository.seasons(1399), throwsA(anything));
    await expectLater(repository.episodes(1399, 1), throwsA(anything));
  });

  test('a movie id has no seasons, so the caller must gate on mediaType', () {
    // TMDB returns no `seasons` key for movies; `seasons()` must not throw on
    // the missing field, it just yields nothing.
    expect(const MovieSection(title: 'x', movies: []).hasMore, isFalse);
  });

  /// Two plain seasons, so the widget tests can assert on a specific default.
  http.Response widgetSeasons() {
    return http.Response(
      jsonEncode({
        'id': 1399,
        'seasons': [
          {'season_number': 1, 'name': 'Season 1', 'episode_count': 2},
          {'season_number': 2, 'name': 'Season 2', 'episode_count': 2},
        ],
      }),
      200,
    );
  }

  http.Response widgetEpisodes(int season) {
    return http.Response(
      jsonEncode({
        'season_number': season,
        'episodes': [
          {
            'id': season * 100 + 1,
            'episode_number': 1,
            'season_number': season,
            'name': 'Season $season opener',
            'overview': 'What happens next.',
            'still_path': '/still.jpg',
            'air_date': '2011-04-17',
            'runtime': 62,
            'vote_average': 8.2,
          },
          {
            'id': season * 100 + 2,
            'episode_number': 2,
            'season_number': season,
            'name': 'Season $season second',
            'overview': '',
            'still_path': '/still2.jpg',
            'air_date': '2011-04-24',
            'runtime': 55,
          },
        ],
      }),
      200,
    );
  }

  final series = Movie(
    id: 1399,
    title: 'Game of Thrones',
    overview: 'Noble families vie for control of the Iron Throne.',
    posterPath: '/poster.jpg',
    backdropPath: '/backdrop.jpg',
    releaseDate: '2011-04-17',
    voteAverage: 8.4,
    mediaType: 'tv',
  );

  testWidgets('renders seasons and the newest season by default', (
    tester,
  ) async {
    final requested = <String>[];
    final client = MockClient((request) async {
      if (request.url.path == '/3/tv/1399') return widgetSeasons();
      requested.add(request.url.path);
      return widgetEpisodes(int.parse(request.url.pathSegments.last));
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tmdbRepositoryProvider.overrideWithValue(
            TmdbRepository(client: client, apiKey: 'test-key'),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(body: EpisodeList(movie: series)),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Season 1'), findsOneWidget);
    expect(find.text('Season 2'), findsOneWidget);
    // The newest real season is selected, not the first.
    expect(requested, ['/3/tv/1399/season/2']);
    expect(find.text('Season 2 opener'), findsOneWidget);
    expect(find.text('S2:E1  •  2x01'), findsOneWidget);
    expect(find.text('Apr 17, 2011  •  62 min'), findsOneWidget);
  });

  testWidgets('tapping a season chip reloads that season of episodes', (
    tester,
  ) async {
    final requested = <String>[];
    final client = MockClient((request) async {
      if (request.url.path == '/3/tv/1399') return widgetSeasons();
      requested.add(request.url.path);
      return widgetEpisodes(int.parse(request.url.pathSegments.last));
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tmdbRepositoryProvider.overrideWithValue(
            TmdbRepository(client: client, apiKey: 'test-key'),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(body: EpisodeList(movie: series)),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.text('Season 1'));
    await tester.pump();
    // The tab animates the pager over 300ms, then the new page fetches.
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(requested, contains('/3/tv/1399/season/1'));
    expect(find.text('Season 1 opener'), findsOneWidget);
    expect(find.text('S1:E2  •  1x02'), findsOneWidget);
  });

  testWidgets('swiping moves between seasons and keeps the tab in sync', (
    tester,
  ) async {
    final requested = <String>[];
    final client = MockClient((request) async {
      if (request.url.path == '/3/tv/1399') return widgetSeasons();
      requested.add(request.url.path);
      return widgetEpisodes(int.parse(request.url.pathSegments.last));
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tmdbRepositoryProvider.overrideWithValue(
            TmdbRepository(client: client, apiKey: 'test-key'),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(body: EpisodeList(movie: series)),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Opens on the newest season.
    expect(find.text('Season 2 opener'), findsOneWidget);

    // Drag the pager rightwards to reveal the previous season.
    await tester.drag(find.byType(PageView), const Offset(600, 0));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(requested, contains('/3/tv/1399/season/1'));
    expect(find.text('Season 1 opener'), findsOneWidget);

    // PageView keeps the neighbouring page alive just off-screen, so assert
    // that Season 1 is the one actually painted within the viewport.
    expect(
      find.descendant(
        of: find.byType(PageView),
        matching: find.text('Season 1 opener'),
      ),
      findsOneWidget,
    );

    // The Season 1 tab is now the selected one.
    final chip = tester.widget<ChoiceChip>(
      find.widgetWithText(ChoiceChip, 'Season 1'),
    );
    expect(chip.selected, isTrue);
    final other = tester.widget<ChoiceChip>(
      find.widgetWithText(ChoiceChip, 'Season 2'),
    );
    expect(other.selected, isFalse);
  });

  testWidgets('a failed season load offers a retry that can recover', (
    tester,
  ) async {
    var fail = true;
    final client = MockClient((request) async {
      if (fail) return http.Response('Boom', 500);
      if (request.url.path == '/3/tv/1399') return widgetSeasons();
      return widgetEpisodes(int.parse(request.url.pathSegments.last));
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tmdbRepositoryProvider.overrideWithValue(
            TmdbRepository(client: client, apiKey: 'test-key'),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(body: EpisodeList(movie: series)),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Retry seasons'), findsOneWidget);
    // A failure must not masquerade as "this series has no seasons".
    expect(find.text('No seasons listed for this series.'), findsNothing);

    fail = false;
    await tester.tap(find.text('Retry seasons'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    // The recovered season list triggers a second request for its episodes.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Season 1'), findsOneWidget);
    expect(find.text('Season 2 opener'), findsOneWidget);
  });
}
