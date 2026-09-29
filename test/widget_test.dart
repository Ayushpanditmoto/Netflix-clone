import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:netflix_clone/main.dart';
import 'package:netflix_clone/src/features/home/home_providers.dart';
import 'package:netflix_clone/src/services/tmdb_repository.dart';
import 'package:netflix_clone/src/widgets/movie_tile.dart';
import 'package:netflix_clone/src/widgets/shimmer.dart';

http.Response _pageResponse({
  required int page,
  required int totalPages,
  required int id,
  required String title,
  bool withMediaType = false,
}) {
  return http.Response(
    jsonEncode({
      'page': page,
      'total_pages': totalPages,
      'results': [
        {
          'id': id,
          'title': title,
          'overview': '',
          'poster_path': '/poster.jpg',
          'release_date': '2026-01-01',
          'vote_average': 7.0,
          if (withMediaType) 'media_type': 'movie',
        },
      ],
    }),
    200,
  );
}

void main() {
  testWidgets('renders the StreamFlix home screen', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: NetflixCloneApp()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('STREAMFLIX'), findsOneWidget);
    expect(find.text('Search movies and series'), findsOneWidget);
    expect(find.text('Oppenheimer'), findsOneWidget);
  });

  testWidgets('opens See all from a rail end and pages search results', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final client = MockClient((request) async {
      final page = int.parse(request.url.queryParameters['page'] ?? '1');
      if (request.url.path == '/3/search/multi') {
        return _pageResponse(
          page: page,
          totalPages: 2,
          id: page,
          title: 'Search result $page',
        );
      }
      return _pageResponse(
        page: page,
        totalPages: 2,
        id: request.url.path.hashCode,
        title: 'Rail title',
        withMediaType: request.url.path == '/3/trending/all/week',
      );
    });

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

    // The first rail advertises "See all" at the end of the slider.
    expect(find.text('See all'), findsWidgets);
    await tester.tap(find.text('See all').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Trending this week'), findsWidgets);

    await tester.pageBack();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // Search results page in as the user scrolls through them. The field
    // debounces typing, so wait past it before expecting results.
    await tester.enterText(find.byType(TextField), 'bat');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Search result 1'), findsOneWidget);

    await tester.tap(find.text('Load more'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Search result 2'), findsOneWidget);
    expect(find.text('End of results'), findsOneWidget);
  });

  testWidgets('shows shimmer placeholders while the shelves load', (
    tester,
  ) async {
    final gate = Completer<void>();
    final client = MockClient((request) async {
      await gate.future;
      return _pageResponse(
        page: 1,
        totalPages: 2,
        id: request.url.path.hashCode,
        title: 'Rail title',
        withMediaType: request.url.path == '/3/trending/all/week',
      );
    });

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

    // While TMDB is still answering, the skeleton shimmers instead of
    // leaving the screen blank.
    expect(find.byType(ShaderMask), findsWidgets);
    expect(find.text('Rail title'), findsNothing);

    gate.complete();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Rail title'), findsOneWidget);
  });

  testWidgets('shimmer freezes instead of animating when motion is reduced', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: Scaffold(
            body: Center(
              child: Shimmer(child: ShimmerBox(width: 120, height: 20)),
            ),
          ),
        ),
      ),
    );

    expect(find.byType(ShaderMask), findsOneWidget);
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('drops search focus so the keyboard closes', (tester) async {
    tester.view.physicalSize = const Size(900, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final client = MockClient((request) async {
      return _pageResponse(
        page: 1,
        totalPages: 2,
        id: request.url.path.hashCode,
        title: 'Rail title',
        withMediaType: request.url.path == '/3/trending/all/week',
      );
    });

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

    // Tapping empty space (the hero art has no gesture handlers) relies purely
    // on the text field's own tap-outside handling. Flutter only does this by
    // default for mouse/stylus, so without onTapOutside the keyboard stayed up.
    await tester.showKeyboard(find.byType(TextField));
    expect(tester.testTextInput.isVisible, isTrue);

    await tester.tapAt(const Offset(450, 200));
    await tester.pump();
    expect(tester.testTextInput.isVisible, isFalse);

    // Swiping up while starting on the field itself: the pointer-down is inside
    // the field, so only keyboardDismissBehavior can close the keyboard. The
    // ScrollView default is `manual`, which is what left it pinned open.
    await tester.showKeyboard(find.byType(TextField));
    expect(tester.testTextInput.isVisible, isTrue);

    await tester.drag(find.byType(TextField), const Offset(0, -300));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.testTextInput.isVisible, isFalse);

    // Opening a title must release focus, otherwise the keyboard would sit on
    // top of the details sheet.
    await tester.showKeyboard(find.byType(TextField));
    expect(tester.testTextInput.isVisible, isTrue);

    await tester.tap(find.byType(MovieTile).first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.testTextInput.isVisible, isFalse);
  });
}

