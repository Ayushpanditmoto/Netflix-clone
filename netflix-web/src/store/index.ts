import { create } from 'zustand';
import type { Movie, MovieSection, SearchResultsState } from '@/types/tmdb';

// ── UI Store ──────────────────────────────────────────────────────────────────

interface UIState {
  // Search
  searchQuery: string;
  setSearchQuery: (q: string) => void;

  // Modal / detail panel
  selectedMovie: Movie | null;
  openMovie: (movie: Movie) => void;
  closeMovie: () => void;

  // Player sheet
  playerMovie: Movie | null;
  playerSeason: number | undefined;
  playerEpisode: number | undefined;
  openPlayer: (movie: Movie, season?: number, episode?: number) => void;
  closePlayer: () => void;

  // Mobile nav
  activeTab: 'home' | 'search' | 'trending';
  setActiveTab: (tab: 'home' | 'search' | 'trending') => void;

  // Desktop trailer preview
  activePreviewKey: string | null;
  setActivePreview: (key: string | null) => void;
}

export const useUIStore = create<UIState>()((set) => ({
  searchQuery: '',
  setSearchQuery: (q) => set({ searchQuery: q }),

  selectedMovie: null,
  openMovie: (movie) => set({ selectedMovie: movie }),
  closeMovie: () => set({ selectedMovie: null }),

  playerMovie: null,
  playerSeason: undefined,
  playerEpisode: undefined,
  openPlayer: (movie, season, episode) =>
    set({ playerMovie: movie, playerSeason: season, playerEpisode: episode }),
  closePlayer: () =>
    set({ playerMovie: null, playerSeason: undefined, playerEpisode: undefined }),

  activeTab: 'home',
  setActiveTab: (tab) => set({ activeTab: tab }),
  activePreviewKey: null,
  setActivePreview: (key) => set({ activePreviewKey: key }),
}));

// ── Search Store ──────────────────────────────────────────────────────────────

interface SearchStore extends SearchResultsState {
  setResults: (results: Pick<SearchResultsState, 'movies' | 'page' | 'totalPages'>) => void;
  appendResults: (movies: Movie[], page: number, totalPages: number) => void;
  setLoadingMore: (v: boolean) => void;
  reset: () => void;
}

const searchDefaults: SearchResultsState = {
  movies: [],
  page: 1,
  totalPages: 1,
  isLoadingMore: false,
  query: '',
};

export const useSearchStore = create<SearchStore>()((set) => ({
  ...searchDefaults,
  setResults: ({ movies, page, totalPages }) =>
    set({ movies, page, totalPages, isLoadingMore: false }),
  appendResults: (newMovies, page, totalPages) =>
    set((state) => {
      const seenIds = new Set(state.movies.map((m) => `${m.mediaType}:${m.id}`));
      const merged = [
        ...state.movies,
        ...newMovies.filter((m) => {
          const key = `${m.mediaType}:${m.id}`;
          if (seenIds.has(key)) return false;
          seenIds.add(key);
          return true;
        }),
      ];
      return { movies: merged, page, totalPages, isLoadingMore: false };
    }),
  setLoadingMore: (v) => set({ isLoadingMore: v }),
  reset: () => set(searchDefaults),
}));

// ── Section Store (rail paging) ───────────────────────────────────────────────

interface SectionStore {
  sections: MovieSection[];
  setSections: (sections: MovieSection[]) => void;
  appendToSection: (index: number, movies: Movie[], page: number, totalPages: number) => void;
}

export const useSectionStore = create<SectionStore>()((set) => ({
  sections: [],
  setSections: (sections) => set({ sections }),
  appendToSection: (index, newMovies, page, totalPages) =>
    set((state) => {
      const sections = [...state.sections];
      const section = sections[index];
      if (!section) return state;
      const seenIds = new Set(section.movies.map((m) => `${m.mediaType}:${m.id}`));
      const merged = [
        ...section.movies,
        ...newMovies.filter((m) => {
          const key = `${m.mediaType}:${m.id}`;
          if (seenIds.has(key)) return false;
          seenIds.add(key);
          return true;
        }),
      ];
      sections[index] = { ...section, movies: merged, page, totalPages };
      return { sections };
    }),
}));
