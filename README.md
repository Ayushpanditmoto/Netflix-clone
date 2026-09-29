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

Each row pages through TMDB: slide a rail to its end to pull in the next page, or
tap **See all** to open the full list, which keeps loading as you scroll. Search
results page in the same way as you scroll down.

Loading states are skeleton shimmers rather than spinners: the first paint shows
a hero-and-rails placeholder, each poster shimmers until its artwork arrives, and
later pages shimmer in as they load. Shimmer is implemented in-house with a
`ShaderMask` (`lib/src/widgets/shimmer.dart`) so no extra package is required.

## Checks

```sh
flutter analyze
flutter test
flutter build web --dart-define=TMDB_API_KEY=your_tmdb_key
```
