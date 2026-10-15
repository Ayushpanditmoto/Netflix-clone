# Netflix Clone — Next.js Web App

A Netflix-style movie & series streaming UI, ported from the Flutter app to the web using **Next.js 15 · TypeScript · TanStack Query · Zustand**.

## Features

- **Home** — hero banner + infinite horizontal rails for trending, now playing, popular, top-rated, Asian collections
- **Detail Modal** — synopsis, meta chips, YouTube trailer embed, seasons + episode list
- **Player** — inline iframe player with 6 switchable embed sources
- **Search** — debounced TanStack Query search with load-more pagination
- **Shimmer skeletons** — native CSS animation placeholders on first paint
- **Offline fallback** — built-in catalog if TMDB is unreachable
- **Dark Netflix-inspired theme** — custom CSS design system, no Tailwind

## Stack

| Concern | Choice |
|---|---|
| Framework | Next.js 16 (App Router) |
| Language | TypeScript |
| Server-state / data fetching | TanStack React Query v5 |
| Client state | Zustand v5 |
| Styling | Vanilla CSS (custom design system) |
| Images | `next/image` (TMDB CDN) |
| HTTP | Native `fetch` with `next: { revalidate }` |
| Metadata | TMDB API |

## Project structure

```
src/
  app/
    globals.css        # Design system — tokens, components, animations
    layout.tsx         # Root layout + QueryClientProvider
    page.tsx           # Home page (Hero + Rails + Modals)
  components/
    Navbar.tsx         # Sticky, scroll-aware navbar
    HeroBanner.tsx     # Full-bleed hero with gradient
    MovieRail.tsx      # Horizontal scroll rail + infinite page loading
    MovieTile.tsx      # Poster tile with hover overlay
    SearchView.tsx     # Search input + paginated grid
    DetailModal.tsx    # Detail panel (trailer, seasons, episodes)
    PlayerModal.tsx    # Embed player + source switcher
    HomeSkeleton.tsx   # Loading skeletons
    Providers.tsx      # TanStack Query provider
  lib/
    tmdb.ts            # TMDB API service (all fetch functions)
    playerSources.ts   # Embed source definitions
    queryKeys.ts       # Query key factory
  store/
    index.ts           # Zustand stores (UI + Search + Sections)
  types/
    tmdb.ts            # TypeScript types for all TMDB entities
```

## Getting started

```sh
cd netflix-web
npm install
npm run dev
# → http://localhost:3000
```

## Configuration

Set your own TMDB API key in `.env.local`:

```env
NEXT_PUBLIC_TMDB_API_KEY=your_key_here
```

Get a free key at [developer.themoviedb.org](https://developer.themoviedb.org/).

## Disclaimer

Educational project only. Not affiliated with Netflix, Inc. Movie metadata from TMDB.
