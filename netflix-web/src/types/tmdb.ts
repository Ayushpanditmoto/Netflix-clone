// ── TMDB core entities ─────────────────────────────────────────────────────

export interface Movie {
  id: number;
  title: string;
  overview: string;
  posterPath: string | null;
  backdropPath: string | null;
  releaseDate: string;
  voteAverage: number;
  mediaType: 'movie' | 'tv';
  genreIds?: number[];
}

export interface Season {
  number: number;
  name: string;
  episodeCount: number;
  overview: string;
  posterPath: string | null;
  airDate: string;
}

export interface Episode {
  id: number;
  number: number;
  seasonNumber: number;
  title: string;
  overview: string;
  stillPath: string | null;
  airDate: string;
  runtime: number | null;
  voteAverage: number;
}

export interface MoviePage {
  movies: Movie[];
  page: number;
  totalPages: number;
}

export interface SectionRequest {
  title: string;
  path: string;
  mediaType?: 'movie' | 'tv';
  params?: Record<string, string>;
}

export interface MovieSection {
  title: string;
  movies: Movie[];
  request?: SectionRequest;
  page: number;
  totalPages: number;
}

// ── TMDB raw API shapes ────────────────────────────────────────────────────

export interface TmdbMovieRaw {
  id: number;
  title?: string;
  name?: string;
  original_title?: string;
  overview?: string;
  poster_path?: string | null;
  backdrop_path?: string | null;
  release_date?: string;
  first_air_date?: string;
  vote_average?: number;
  media_type?: string;
  genre_ids?: number[];
}

export interface TmdbPageResponse {
  results: TmdbMovieRaw[];
  page: number;
  total_pages: number;
}

export interface TmdbSeasonRaw {
  season_number: number;
  name?: string;
  episode_count?: number;
  overview?: string;
  poster_path?: string | null;
  air_date?: string;
}

export interface TmdbEpisodeRaw {
  id?: number;
  episode_number?: number;
  season_number?: number;
  name?: string;
  overview?: string;
  still_path?: string | null;
  air_date?: string;
  runtime?: number | null;
  vote_average?: number;
}

export interface TmdbSeriesDetailResponse {
  seasons?: TmdbSeasonRaw[];
}

export interface TmdbSeasonDetailResponse {
  episodes?: TmdbEpisodeRaw[];
}

export interface TmdbVideosResponse {
  results: Array<{
    key: string;
    site: string;
    type: string;
    official: boolean;
  }>;
}

// ── Player sources ─────────────────────────────────────────────────────────

export interface PlayerSource {
  name: string;
  host: string;
  buildUrl: (id: number, mediaType: string) => string;
  buildEpisodeUrl?: (id: number, season: number, episode: number) => string;
}

export function urlFor(
  source: PlayerSource,
  id: number,
  mediaType: string,
  season?: number,
  episode?: number
): string {
  if (season != null && episode != null && source.buildEpisodeUrl) {
    return source.buildEpisodeUrl(id, season, episode);
  }
  return source.buildUrl(id, mediaType);
}

// ── Search state ───────────────────────────────────────────────────────────

export interface SearchResultsState {
  movies: Movie[];
  page: number;
  totalPages: number;
  isLoadingMore: boolean;
  query: string;
}
