import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:netflix_clone/main.dart';
import 'package:netflix_clone/src/features/home/home_providers.dart';
import 'package:netflix_clone/src/services/tmdb_repository.dart';

/// One TMDB search page: 20 results, enough to make the grid scrollable.
http.Response _searchPage(String page, {int totalPages = 4}) {
  final pageNumber = int.parse(page);
  return http.Response(
    jsonEncode({
      'page': pageNumber,
      'total_pages': totalPages,
      'results': [
        for (var i = 0; i < 20; i++)
          {
            'id': (pageNumber - 1) * 20 + i,
            'title': 'Page $pageNumber item $i',
            'overview': '',
            'poster_path': '/poster.jpg',
            'release_date': '2026-01-01',
            'vote_average': 7.0,
            'media_type': 'movie',
          },
      ],
    }),
    200,
  );
}

http.Response _railsPage() {
  return http.Response(
    jsonEncode({
      'page': 1,
      'total_pages': 2,
      'results': [
        {
          'id': 1,
          'title': 'Rail title',
          'overview': '',
          'poster_path': '/poster.jpg',
          'release_date': '2026-01-01',
          'vote_average': 7.0,
          'media_type': 'movie',
        },
      ],
    }),
    200,
  );
}

void _usePhoneViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(400, 800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

Future<void> _pumpApp(WidgetTester tester, http.Client client) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        tmdbRepositoryProvider.overrideWithValue(
          TmdbRepository(client: client, apiKey: 'test-key'),
        ),
      ],
      child: const NetflixCloneApp(),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
}

/// Types one character at a time, the way a real keyboard does. Every keystroke
/// rebuilds the search provider, which is exactly what used to break paging.
Future<void> _typeSlowly(WidgetTester tester, String text) async {
  for (var i = 1; i <= text.length; i++) {
    await tester.enterText(find.byType(TextField), text.substring(0, i));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 40));
  }
  await tester.pump(const Duration(milliseconds: 400)); // debounce fires
  await tester.pump(const Duration(milliseconds: 50)); // request resolves
}

Future<void> _scrollDown(WidgetTester tester, {int times = 4}) async {
  for (var i = 0; i < times; i++) {
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -700));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
  }
}

void main() {
  testWidgets('loads and renders page 2 after a keystroke-by-keystroke search', (
    tester,
  ) async {
    _usePhoneViewport(tester);

    final requested = <String>[];
    final client = MockClient((request) async {
      if (request.url.path == '/3/search/multi') {
        final page = request.url.queryParameters['page'] ?? '1';
        requested.add(page);
        return _searchPage(page);
      }
      return _railsPage();
    });

    await _pumpApp(tester, client);
    await _typeSlowly(tester, 'bat');

    expect(find.text('Page 1 item 0'), findsOneWidget);
    expect(requested.every((page) => page == '1'), isTrue);

    await _scrollDown(tester);

    expect(requested, contains('2'));
    // The response must actually land in the state, not just be requested.
    expect(find.text('Page 2 item 0'), findsOneWidget);
    expect(find.text('Load more'), findsOneWidget);
    expect(find.text('End of results'), findsNothing);
  });

  testWidgets('debounces typing into a single search request', (tester) async {
    _usePhoneViewport(tester);

    final requested = <String>[];
    final client = MockClient((request) async {
      if (request.url.path == '/3/search/multi') {
        requested.add(request.url.queryParameters['page'] ?? '1');
        return _searchPage('1');
      }
      return _railsPage();
    });

    await _pumpApp(tester, client);
    await _typeSlowly(tester, 'batman');

    expect(
      requested,
      hasLength(1),
      reason: 'one request per typing pause, but sent $requested',
    );
  });

  testWidgets('a failed search page does not brick paging', (tester) async {
    _usePhoneViewport(tester);

    var failPageTwo = true;
    final client = MockClient((request) async {
      if (request.url.path == '/3/search/multi') {
        final page = request.url.queryParameters['page'] ?? '1';
        if (page == '2' && failPageTwo) {
          return http.Response('Rate limited', 429);
        }
        return _searchPage(page);
      }
      return _railsPage();
    });

    await _pumpApp(tester, client);
    await _typeSlowly(tester, 'bat');
    // Scroll all the way down: this pins us at the bottom, so the auto-load
    // fires once (and fails) and no further scroll events can be produced.
    await _scrollDown(tester, times: 6);

    // A failed page must not look like "no more results".
    expect(find.text('End of results'), findsNothing);

    // The cursor survived, so the retry can still page.
    failPageTwo = false;
    await tester.pump();
    await tester.tap(find.text('Load more'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Page 2 item 0'), findsOneWidget);
    expect(find.text('End of results'), findsNothing);
  });
}
