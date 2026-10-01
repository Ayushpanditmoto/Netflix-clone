import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:netflix_clone/src/features/player/player_screen.dart';
import 'package:netflix_clone/src/models/movie.dart';

Movie _movie({String mediaType = 'movie'}) => Movie(
      id: 1084242,
      title: 'Example Title',
      overview: 'A short overview that should be visible on the picker.',
      posterPath: null,
      backdropPath: null,
      releaseDate: '2010-07-16',
      voteAverage: 8.5,
      mediaType: mediaType,
    );

Widget _host(Movie movie, {int? season, int? episode}) => MaterialApp(
      home: PlayerScreen(movie: movie, season: season, episode: episode),
    );

void main() {
  testWidgets('lists every configured source with its host', (tester) async {
    await tester.pumpWidget(_host(_movie()));

    expect(find.text('Example Title'), findsOneWidget);
    expect(find.text('2010'), findsOneWidget);
    expect(find.text('8.5'), findsOneWidget);
    expect(find.text('Movie'), findsOneWidget);

    // Every provider is offered, each with a visible host label.
    for (final host in [
      'vidsrc.me',
      'cinesrc.st',
      'embed.filmu.in',
      'player.playapi.eu.cc',
      'vidgod.net',
      'peachify.top',
    ]) {
      expect(find.text(host), findsOneWidget, reason: 'missing $host');
    }
  });

  testWidgets('shows the season and episode pill for an episode', (tester) async {
    await tester.pumpWidget(
      _host(_movie(mediaType: 'tv'), season: 2, episode: 4),
    );

    expect(find.text('Series'), findsOneWidget);
    expect(find.text('Season 2  ·  Episode 4'), findsOneWidget);
  });

  testWidgets('omits the episode pill for a movie', (tester) async {
    await tester.pumpWidget(_host(_movie()));
    expect(find.textContaining('Season'), findsNothing);
  });

  testWidgets('shows a 16:9 placeholder until a source is chosen', (tester) async {
    await tester.pumpWidget(_host(_movie()));

    expect(find.text('Pick a source to start playing'), findsOneWidget);
    expect(find.text('Select a source'), findsOneWidget);

    final stage = tester.widget<AspectRatio>(find.byType(AspectRatio).first);
    expect(stage.aspectRatio, 16 / 9);
  });

  // Selecting a source mounts a real WebView, which needs a platform
  // implementation that widget tests do not provide, so that path is verified on
  // device instead.
}