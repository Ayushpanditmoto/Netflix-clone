import type { Movie } from '@/types/tmdb';

export interface WatchHistoryItem {
  movie: Movie;
  season?: number;
  episode?: number;
  watchedAt: number;
}

const STORAGE_KEY = 'netflix-watch-history';
const MAX_ITEMS = 12;

export function readWatchHistory(): WatchHistoryItem[] {
  if (typeof window === 'undefined') return [];
  try {
    const parsed = JSON.parse(window.localStorage.getItem(STORAGE_KEY) ?? '[]') as WatchHistoryItem[];
    return Array.isArray(parsed)
      ? parsed.filter((item) => item?.movie?.id && item.movie.mediaType)
      : [];
  } catch {
    return [];
  }
}

export function saveWatchHistory(movie: Movie, season?: number, episode?: number): void {
  if (typeof window === 'undefined') return;
  const next: WatchHistoryItem = { movie, season, episode, watchedAt: Date.now() };
  const history = readWatchHistory().filter(
    (item) => `${item.movie.mediaType}:${item.movie.id}` !== `${movie.mediaType}:${movie.id}`,
  );
  window.localStorage.setItem(STORAGE_KEY, JSON.stringify([next, ...history].slice(0, MAX_ITEMS)));
}
