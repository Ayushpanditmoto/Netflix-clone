export const QUERY_KEYS = {
  homeSections: ['home-sections'] as const,
  section: (path: string, page: number) => ['section', path, page] as const,
  search: (query: string, page: number) => ['search', query, page] as const,
  seasons: (seriesId: number) => ['seasons', seriesId] as const,
  episodes: (seriesId: number, season: number) => ['episodes', seriesId, season] as const,
  trailer: (id: number, mediaType: string) => ['trailer', id, mediaType] as const,
  movie: (id: number, mediaType: string) => ['movie', id, mediaType] as const,
  similar: (id: number, mediaType: string) => ['similar', id, mediaType] as const,
} as const;
