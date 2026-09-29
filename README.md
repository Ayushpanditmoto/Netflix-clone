# Streamflix

A Flutter movie and series browser with Riverpod state management and TMDB
metadata.

## Run

The app includes a default TMDB key for the live home collections:

```sh
flutter run
```

You can override it with another TMDB key at build time:

```sh
flutter run --dart-define=TMDB_API_KEY=your_tmdb_key
```

The home screen loads trending, now-playing, popular, top-rated, and Asian
movie and series collections from TMDB. It falls back to a small offline catalog
when TMDB is unavailable.

## Checks

```sh
flutter analyze
flutter test
flutter build web --dart-define=TMDB_API_KEY=your_tmdb_key
```
