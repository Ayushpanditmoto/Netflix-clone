import type {
  Movie,
  MoviePage,
  MovieSection,
  Season,
  Episode,
  SectionRequest,
  TmdbMovieRaw,
  TmdbPageResponse,
  TmdbSeasonRaw,
  TmdbEpisodeRaw,
  TmdbSeriesDetailResponse,
  TmdbSeasonDetailResponse,
  TmdbVideosResponse,
} from '@/types/tmdb';

// ── Config ──────────────────────────────────────────────────────────────────

const TMDB_API_KEY =
  process.env.NEXT_PUBLIC_TMDB_API_KEY ?? '9e7096a7575623aa30c66e9cc987e411';
const BASE_URL = 'https://api.themoviedb.org/3';
const IMAGE_BASE = 'https://image.tmdb.org/t/p';

export function tmdbImageUrl(path: string | null | undefined, size: string): string | null {
  if (!path) return null;
  return `${IMAGE_BASE}/${size}${path}`;
}

export function posterUrl(m: Movie): string | null {
  return tmdbImageUrl(m.posterPath, 'w500');
}

export function backdropUrl(m: Movie): string | null {
  return tmdbImageUrl(m.backdropPath, 'w1280');
}

export function movieYear(m: Movie): string {
  return m.releaseDate?.length >= 4 ? m.releaseDate.substring(0, 4) : 'New';
}

// ── Raw helpers ──────────────────────────────────────────────────────────────

function movieFromRaw(raw: TmdbMovieRaw, overrideMediaType?: string): Movie {
  return {
    id: raw.id,
    title: raw.title ?? raw.name ?? raw.original_title ?? 'Untitled',
    overview: raw.overview ?? '',
    posterPath: raw.poster_path ?? null,
    backdropPath: raw.backdrop_path ?? null,
    releaseDate: raw.release_date ?? raw.first_air_date ?? '',
    voteAverage: raw.vote_average ?? 0,
    mediaType: (overrideMediaType ?? raw.media_type ?? 'movie') as 'movie' | 'tv',
    genreIds: raw.genre_ids,
  };
}

export async function fetchMovieById(id: number, mediaType: 'movie' | 'tv'): Promise<Movie> {
  const data = await get<TmdbMovieRaw>(`/${mediaType}/${id}`);
  return movieFromRaw(data, mediaType);
}

export async function fetchSimilarMovies(id: number, mediaType: 'movie' | 'tv'): Promise<Movie[]> {
  const data = await get<TmdbPageResponse>(`/${mediaType}/${id}/similar`);
  return pageFromResponse(data, mediaType).movies;
}

function seasonFromRaw(raw: TmdbSeasonRaw): Season {
  const number = raw.season_number ?? 0;
  const name = raw.name?.trim();
  return {
    number,
    name: name || (number === 0 ? 'Specials' : `Season ${number}`),
    episodeCount: raw.episode_count ?? 0,
    overview: raw.overview ?? '',
    posterPath: raw.poster_path ?? null,
    airDate: raw.air_date ?? '',
  };
}

function episodeFromRaw(raw: TmdbEpisodeRaw): Episode {
  return {
    id: raw.id ?? 0,
    number: raw.episode_number ?? 0,
    seasonNumber: raw.season_number ?? 0,
    title: raw.name ?? 'Episode',
    overview: raw.overview ?? '',
    stillPath: raw.still_path ?? null,
    airDate: raw.air_date ?? '',
    runtime: raw.runtime ?? null,
    voteAverage: raw.vote_average ?? 0,
  };
}

function pageFromResponse(data: TmdbPageResponse, overrideMediaType?: string): MoviePage {
  const movies = (data.results ?? [])
    .map((r) => movieFromRaw(r, overrideMediaType))
    .filter((m) => m.mediaType === 'movie' || m.mediaType === 'tv')
    .filter((m) => m.posterPath || m.backdropPath);
  return { movies, page: data.page ?? 1, totalPages: data.total_pages ?? 1 };
}

// ── HTTP ─────────────────────────────────────────────────────────────────────

async function get<T>(path: string, params: Record<string, string> = {}): Promise<T> {
  // Route through the Next.js proxy at /api/tmdb to avoid CORS issues
  // and keep the API key server-side.
  const isServer = typeof window === 'undefined';

  if (isServer) {
    // Server-side: call TMDB directly (in Server Components / Route Handlers)
    const url = new URL(`${BASE_URL}${path}`);
    url.searchParams.set('api_key', TMDB_API_KEY);
    url.searchParams.set('language', 'en-US');
    for (const [k, v] of Object.entries(params)) {
      url.searchParams.set(k, v);
    }
    const res = await fetch(url.toString(), { next: { revalidate: 300 } });
    if (!res.ok) throw new Error(`TMDB ${res.status}: ${path}`);
    return res.json() as Promise<T>;
  }

  // Client-side: go through the local API proxy to avoid CORS
  const proxyUrl = new URL('/api/tmdb', window.location.origin);
  proxyUrl.searchParams.set('path', path);
  for (const [k, v] of Object.entries(params)) {
    proxyUrl.searchParams.set(k, v);
  }
  const res = await fetch(proxyUrl.toString());
  if (!res.ok) throw new Error(`TMDB proxy ${res.status}: ${path}`);
  return res.json() as Promise<T>;
}

// ── Section requests ─────────────────────────────────────────────────────────

export const SECTION_REQUESTS: SectionRequest[] = [
  { title: 'Trending this week', path: '/trending/all/week' },
  { title: 'Now playing', path: '/movie/now_playing', mediaType: 'movie' },
  { title: 'Trending movies', path: '/trending/movie/week', mediaType: 'movie' },
  {
    title: 'Popular international movies',
    path: '/discover/movie',
    mediaType: 'movie',
    params: { with_original_language: 'zh|ko|ja', sort_by: 'popularity.desc', include_adult: 'false' },
  },
  { title: 'Popular movies', path: '/movie/popular', mediaType: 'movie' },
  { title: 'Top rated movies', path: '/movie/top_rated', mediaType: 'movie' },
  { title: 'Trending series', path: '/trending/tv/week', mediaType: 'tv' },
  {
    title: 'Asian series',
    path: '/discover/tv',
    mediaType: 'tv',
    params: {
      with_original_language: 'ko|ja|zh',
      sort_by: 'popularity.desc',
      include_adult: 'false',
      'first_air_date.gte': '2020-01-01',
    },
  },
];

// ── Public API ───────────────────────────────────────────────────────────────

export async function fetchHomeSections(): Promise<MovieSection[]> {
  const results = await Promise.allSettled(
    SECTION_REQUESTS.map((req) => fetchSection(req, 1))
  );
  const sections = results
    .map((r) => (r.status === 'fulfilled' ? r.value : null))
    .filter((s): s is MovieSection => s !== null && s.movies.length > 0);
  return sections.length > 0 ? sections : FALLBACK_SECTIONS;
}

export async function fetchSection(req: SectionRequest, page: number): Promise<MovieSection> {
  const params: Record<string, string> = { ...(req.params ?? {}) };
  if (page > 1) params.page = String(page);
  const data = await get<TmdbPageResponse>(req.path, params);
  const result = pageFromResponse(data, req.mediaType);
  return {
    title: req.title,
    movies: result.movies,
    request: req,
    page: result.page,
    totalPages: result.totalPages,
  };
}

export async function fetchSearchPage(query: string, page = 1): Promise<MoviePage> {
  if (!query.trim()) return { movies: [], page: 1, totalPages: 1 };
  const params: Record<string, string> = { query: query.trim(), include_adult: 'false' };
  if (page > 1) params.page = String(page);
  const data = await get<TmdbPageResponse>('/search/multi', params);
  return pageFromResponse(data);
}

export async function fetchSeasons(seriesId: number): Promise<Season[]> {
  const data = await get<TmdbSeriesDetailResponse>(`/tv/${seriesId}`);
  return (data.seasons ?? []).map(seasonFromRaw);
}

export async function fetchEpisodes(seriesId: number, seasonNumber: number): Promise<Episode[]> {
  const data = await get<TmdbSeasonDetailResponse>(
    `/tv/${seriesId}/season/${seasonNumber}`
  );
  return (data.episodes ?? [])
    .map(episodeFromRaw)
    .filter((e) => e.number > 0)
    .sort((a, b) => a.number - b.number);
}

export async function fetchTrailerKey(id: number, mediaType: string): Promise<string | null> {
  const data = await get<TmdbVideosResponse>(`/${mediaType}/${id}/videos`);
  const officialTrailers = (data.results ?? []).filter(
    (v) =>
      v.site === 'YouTube' &&
      v.type === 'Trailer' &&
      v.official &&
      /^[a-zA-Z0-9_-]{11}$/.test(v.key)
  );
  return officialTrailers[0]?.key ?? null;
}

// ── Fallback catalog ─────────────────────────────────────────────────────────

export const FALLBACK_SECTIONS: MovieSection[] = [
  {
    title: 'Trending now',
    movies: [
      {
        id: 872585, title: 'Oppenheimer',
        overview: 'The story of J. Robert Oppenheimer and the creation of the atomic bomb.',
        posterPath: '/8Gxv8gSFCU0XGDykEGv7zR1n2ua.jpg',
        backdropPath: '/fm6KqXpk3M2HVveHwCrBSSBaO0V.jpg',
        releaseDate: '2023-07-19', voteAverage: 8.1, mediaType: 'movie',
      },
      {
        id: 603692, title: 'John Wick: Chapter 4',
        overview: 'John Wick uncovers a path to defeating the High Table.',
        posterPath: '/vZloFAK7NmvMGKE7VkF5UHaz0I.jpg',
        backdropPath: '/i3OTGmLNOZIo4SRQLVfLjeWegB6.jpg',
        releaseDate: '2023-03-22', voteAverage: 7.7, mediaType: 'movie',
      },
      {
        id: 76600, title: 'Avatar: The Way of Water',
        overview: 'Jake Sully and Neytiri fight to keep their family safe on Pandora.',
        posterPath: '/t6HIqrRAclMCA60NsSmeqe9RmNV.jpg',
        backdropPath: '/s16H6tpK2utvwDtzZ8Qy4qm5Emw.jpg',
        releaseDate: '2022-12-14', voteAverage: 7.6, mediaType: 'movie',
      },
    ],
    page: 1, totalPages: 1,
  },
  {
    title: 'Popular on Netflix',
    movies: [
      {
        id: 550, title: 'Fight Club',
        overview: 'An insomniac office worker and a soap maker form an underground fight club.',
        posterPath: '/pB8BM7pdSp6B6Ih7QZ4DrQ3PmJK.jpg',
        backdropPath: '/hZkgoQYus5vegHoetLkCJzb17zJ.jpg',
        releaseDate: '1999-10-15', voteAverage: 8.4, mediaType: 'movie',
      },
      {
        id: 155, title: 'The Dark Knight',
        overview: 'Batman faces the Joker, a criminal mastermind plunging Gotham into chaos.',
        posterPath: '/qJ2tW6WMUDux911r6m7haRef0WH.jpg',
        backdropPath: '/nMKdUUepR0i5zn0y1T4CsSB5chy.jpg',
        releaseDate: '2008-07-16', voteAverage: 8.5, mediaType: 'movie',
      },
    ],
    page: 1, totalPages: 1,
  },
  {
    title: 'Series picks',
    movies: [
      {
        id: 1399, title: 'Game of Thrones',
        overview: 'Noble families vie for control of the Iron Throne.',
        posterPath: '/1XS1oqL89opfnbLl8WnZY1O1uJx.jpg',
        backdropPath: '/2OMB0ynKlyIenMJWI2Dy9IWT4c.jpg',
        releaseDate: '2011-04-17', voteAverage: 8.4, mediaType: 'tv',
      },
      {
        id: 66732, title: 'Stranger Things',
        overview: 'A small town uncovers secret experiments and supernatural forces.',
        posterPath: '/uOOtwVbSr4QDjAGIifLDwpb2Pdl.jpg',
        backdropPath: '/56v2KjBlU4XaOv9rVYEQypROD7P.jpg',
        releaseDate: '2016-07-15', voteAverage: 8.6, mediaType: 'tv',
      },
    ],
    page: 1, totalPages: 1,
  },
];
