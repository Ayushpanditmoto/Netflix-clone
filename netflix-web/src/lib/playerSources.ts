import type { PlayerSource } from '@/types/tmdb';

export const PLAYER_SOURCES: PlayerSource[] = [
  {
    name: 'Vidbolt',
    host: 'vidbolt.pro',
    buildUrl: (id, mediaType) => `https://vidbolt.pro/${mediaType}/${id}`,
    buildEpisodeUrl: (id, season, episode) =>
      `https://vidbolt.pro/tv/${id}/${season}/${episode}`,
  },
  {
    name: 'Vidrift',
    host: 'embed.vidrift.net',
    buildUrl: (id, mediaType) =>
      `https://embed.vidrift.net/embed/${mediaType}/${id}`,
    buildEpisodeUrl: (id, season, episode) =>
      `https://embed.vidrift.net/embed/tv/${id}/${season}/${episode}`,
  },
  {
    name: 'VidSrc',
    host: 'vidsrc.me',
    buildUrl: (id, mediaType) => `https://vidsrc.me/embed/${mediaType}/${id}`,
    buildEpisodeUrl: (id, season, episode) =>
      `https://vidsrc.me/embed/tv/${id}/${season}/${episode}`,
  },
  {
    name: 'CineSrc / NexVid',
    host: 'cinesrc.st',
    buildUrl: (id, mediaType) => `https://cinesrc.st/embed/${mediaType}/${id}`,
    buildEpisodeUrl: (id, season, episode) =>
      `https://cinesrc.st/embed/tv/${id}?season=${season}&episode=${episode}`,
  },
  {
    name: 'Bingr',
    host: 'bingr.one',
    buildUrl: (id, mediaType) => `https://bingr.one/watch/${mediaType}/${id}`,
    buildEpisodeUrl: (id, season, episode) =>
      `https://bingr.one/watch/tv/${id}/${season}/${episode}`,
  },
];

export const DEFAULT_PLAYER_SOURCE_NAME = 'Vidrift';
