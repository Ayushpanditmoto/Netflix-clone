'use client';

import { useParams, useRouter } from 'next/navigation';
import { useEffect, useMemo, useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import Image from 'next/image';
import { PLAYER_SOURCES } from '@/lib/playerSources';
import { urlFor } from '@/types/tmdb';
import { QUERY_KEYS } from '@/lib/queryKeys';
import { fetchEpisodes, fetchMovieById, fetchSeasons, fetchSimilarMovies, movieYear, tmdbImageUrl } from '@/lib/tmdb';
import type { Episode } from '@/types/tmdb';
import MovieTile from '@/components/MovieTile';
import { saveWatchHistory } from '@/lib/watchHistory';

export default function WatchPage() {
  const params = useParams<{ mediaType: string; id: string }>();
  const router = useRouter();
  const mediaType = params.mediaType === 'tv' ? 'tv' : 'movie';
  const id = Number(params.id);
  const [sourceName, setSourceName] = useState(PLAYER_SOURCES[0]?.name ?? '');
  const [selectedSeason, setSelectedSeason] = useState<number>();
  const [episode, setEpisode] = useState<{ season: number; number: number }>();
  const [playerKey, setPlayerKey] = useState(0);

  const movieQuery = useQuery({
    queryKey: QUERY_KEYS.movie(id, mediaType),
    queryFn: () => fetchMovieById(id, mediaType),
    enabled: Number.isFinite(id) && id > 0,
    staleTime: 10 * 60 * 1000,
  });
  const movie = movieQuery.data;
  const similarQuery = useQuery({
    queryKey: QUERY_KEYS.similar(id, mediaType),
    queryFn: () => fetchSimilarMovies(id, mediaType),
    enabled: !!movie,
    staleTime: 10 * 60 * 1000,
  });
  const seasonsQuery = useQuery({
    queryKey: QUERY_KEYS.seasons(id),
    queryFn: () => fetchSeasons(id),
    enabled: mediaType === 'tv' && !!movie,
    staleTime: Infinity,
  });
  const seasonNumber = selectedSeason ?? seasonsQuery.data?.find((season) => season.number > 0)?.number;
  const episodesQuery = useQuery({
    queryKey: QUERY_KEYS.episodes(id, seasonNumber ?? 0),
    queryFn: () => fetchEpisodes(id, seasonNumber!),
    enabled: mediaType === 'tv' && seasonNumber != null,
    staleTime: Infinity,
  });

  const activeSource = PLAYER_SOURCES.find((source) => source.name === sourceName) ?? PLAYER_SOURCES[0];
  const embedUrl = movie && activeSource
    ? urlFor(activeSource, movie.id, movie.mediaType, episode?.season, episode?.number)
    : null;

  useEffect(() => {
    if (mediaType !== 'tv') return;
    const timer = window.setTimeout(() => {
      const saved = window.localStorage.getItem(`watch:${mediaType}:${id}`);
      if (!saved) return;
      try {
        const savedEpisode = JSON.parse(saved) as { season?: number; number?: number };
        if (savedEpisode.season && savedEpisode.season > 0 && savedEpisode.number && savedEpisode.number > 0) {
          setSelectedSeason(savedEpisode.season);
          setEpisode({ season: savedEpisode.season, number: savedEpisode.number });
        }
      } catch { /* Ignore invalid saved episode state. */ }
    }, 0);
    return () => window.clearTimeout(timer);
  }, [id, mediaType]);

  useEffect(() => {
    const timer = window.setTimeout(() => {
      const savedSource = window.localStorage.getItem(`source:${mediaType}`);
      if (savedSource && PLAYER_SOURCES.some((source) => source.name === savedSource)) {
        setSourceName(savedSource);
      }
    }, 0);
    return () => window.clearTimeout(timer);
  }, [mediaType]);

  useEffect(() => {
    if (movie && episode) window.localStorage.setItem(`watch:${movie.mediaType}:${movie.id}`, JSON.stringify(episode));
  }, [episode, movie]);

  useEffect(() => {
    if (mediaType !== 'tv' || !seasonNumber || !episodesQuery.data?.length) return;
    const firstEpisode = episodesQuery.data[0];
    if (episode && episode.season === seasonNumber) return;
    const timer = window.setTimeout(() => {
      setEpisode({ season: firstEpisode.seasonNumber, number: firstEpisode.number });
    }, 0);
    return () => window.clearTimeout(timer);
  }, [episode, episodesQuery.data, mediaType, seasonNumber]);

  useEffect(() => {
    if (!movie) return;
    saveWatchHistory(movie, episode?.season, episode?.number);
    window.dispatchEvent(new Event('watch-history-updated'));
  }, [episode, movie]);

  const nextEpisode = useMemo(() => {
    if (!episode || !episodesQuery.data) return undefined;
    const index = episodesQuery.data.findIndex((item) => item.number === episode.number);
    const next = episodesQuery.data[index + 1];
    return next ? { season: next.seasonNumber, number: next.number } : undefined;
  }, [episode, episodesQuery.data]);
  const previousEpisode = useMemo(() => {
    if (!episode || !episodesQuery.data) return undefined;
    const index = episodesQuery.data.findIndex((item) => item.number === episode.number);
    const previous = episodesQuery.data[index - 1];
    return previous ? { season: previous.seasonNumber, number: previous.number } : undefined;
  }, [episode, episodesQuery.data]);

  if (movieQuery.isLoading) return <WatchSkeleton />;
  if (movieQuery.isError || !movie) return <WatchError onBack={() => router.back()} />;

  return (
    <main className="watch-page">
      <div className="watch-shell">
        <div className="watch-topbar">
          <button className="watch-back" type="button" onClick={() => router.back()} aria-label="Go back">
            <BackIcon /> Back
          </button>
          <div className="watch-context" aria-live="polite">
            <strong>{movie.title}</strong>
            {episode && <span>S{episode.season} E{episode.number}</span>}
          </div>
          <div className="watch-topbar-source">
            <label className="watch-source-label" htmlFor="watch-source-select">
              <span className="watch-source-dot" aria-hidden="true" />
              {activeSource?.name ?? 'Server'}
            </label>
            <select
              id="watch-source-select"
              className="watch-source-select"
              value={sourceName}
              onChange={(event) => {
                const nextSource = event.target.value;
                setSourceName(nextSource);
                window.localStorage.setItem(`source:${mediaType}`, nextSource);
                setPlayerKey((key) => key + 1);
              }}
            >
              {PLAYER_SOURCES.map((source) => <option key={source.name} value={source.name}>{source.name} · {source.host}</option>)}
            </select>
          </div>
        </div>
        <section className="watch-player-wrap" aria-label={`${movie.title} video player`}>
          {embedUrl && <WatchPlayer key={`${embedUrl}-${playerKey}`} src={embedUrl} title={movie.title} />}
        </section>
        <div className="watch-player-caption">
          <span>{episode ? `Watching episode ${episode.number}` : 'Ready to watch'}</span>
          <span className="watch-player-caption-actions">
            <span>Source: {activeSource?.name ?? 'Unavailable'}</span>
            <button type="button" className="watch-retry" onClick={() => setPlayerKey((key) => key + 1)}>
              Reload player
            </button>
          </span>
        </div>

        <section className="watch-details">
          <div>
            <h1 className="watch-title">{movie.title}</h1>
            <div className="hero-meta">
              <span className="hero-chip">{movieYear(movie)}</span>
              <span className="hero-chip">★ {movie.voteAverage.toFixed(1)} TMDB</span>
              <span className="hero-chip">{mediaType === 'tv' ? 'TV Series' : 'Movie'}</span>
              {episode && <span className="hero-chip">S{episode.season} E{episode.number}</span>}
            </div>
            <details className="watch-copy" open>
              <summary>About this title</summary>
              <p>{movie.overview || 'No synopsis is available for this title yet.'}</p>
            </details>
            {(previousEpisode || nextEpisode) && (
              <div className="watch-episode-actions">
                {previousEpisode && <button className="btn btn-secondary" type="button" onClick={() => setEpisode(previousEpisode)}>Previous episode</button>}
                {nextEpisode && <button className="btn btn-secondary" type="button" onClick={() => setEpisode(nextEpisode)}>Next episode</button>}
              </div>
            )}
          </div>
        </section>

        {mediaType === 'tv' && (
          <TvSelector
            seasons={seasonsQuery.data ?? []}
            selectedSeason={seasonNumber}
            episodes={episodesQuery.data ?? []}
            selectedEpisode={episode?.number}
            loadingSeasons={seasonsQuery.isLoading}
            loadingEpisodes={episodesQuery.isLoading}
            episodesError={episodesQuery.isError}
            onSeasonChange={(season) => { setSelectedSeason(season); setEpisode(undefined); }}
            onEpisodeChange={(number) => setEpisode({ season: seasonNumber!, number })}
          />
        )}

        {similarQuery.data && similarQuery.data.length > 0 && (
          <section className="watch-recommendations" aria-labelledby="recommendations-heading">
            <div className="section-header watch-section-header"><h2 id="recommendations-heading" className="section-title">More like this</h2></div>
            <div className="watch-recommendation-grid">
              {similarQuery.data.slice(0, 12).map((item) => <MovieTile key={`${item.mediaType}:${item.id}`} movie={item} showTitle />)}
            </div>
          </section>
        )}
      </div>
    </main>
  );
}

function TvSelector({ seasons, selectedSeason, episodes, selectedEpisode, loadingSeasons, loadingEpisodes, episodesError, onSeasonChange, onEpisodeChange }: { seasons: { number: number; name: string; episodeCount: number }[]; selectedSeason?: number; episodes: Episode[]; selectedEpisode?: number; loadingSeasons: boolean; loadingEpisodes: boolean; episodesError: boolean; onSeasonChange: (season: number) => void; onEpisodeChange: (episode: number) => void }) {
  const realSeasons = seasons.filter((season) => season.number > 0);
  return (
    <aside className="watch-selector">
      <div className="watch-selector-heading">
        <div>
          <h2>Episodes</h2>
          <p>{selectedEpisode ? `Currently watching episode ${selectedEpisode}` : 'Choose an episode to start watching'}</p>
        </div>
        {selectedSeason && <span className="watch-season-count">{episodes.length || '…'} episodes</span>}
      </div>
      {loadingSeasons ? <div className="watch-season-skeletons" aria-label="Loading seasons">
        {Array.from({ length: 4 }).map((_, index) => <span key={index} className="shimmer watch-season-skeleton" />)}
      </div> : (
        <div className="watch-selector-list">
          {realSeasons.map((season) => <button key={season.number} className={`watch-selector-button ${selectedSeason === season.number ? 'active' : ''}`} type="button" onClick={() => onSeasonChange(season.number)}>{season.name}<small>{season.episodeCount} eps</small></button>)}
        </div>
      )}
      {loadingEpisodes && <div className="watch-episodes" aria-label="Loading episodes">
        {Array.from({ length: 6 }).map((_, index) => <div key={index} className="watch-episode-skeleton shimmer" />)}
      </div>}
      {episodesError && <p className="watch-selector-message">Episodes could not be loaded. Try selecting the season again.</p>}
      {!loadingEpisodes && !episodesError && selectedSeason && episodes.length === 0 && <p className="watch-selector-message">No episodes are available for this season.</p>}
      {!loadingEpisodes && !episodesError && episodes.length > 0 && (
        <div className="watch-episodes">
          {episodes.map((item) => {
            const stillUrl = tmdbImageUrl(item.stillPath, 'w300');
            return (
              <button key={item.number} className={`watch-episode ${selectedEpisode === item.number ? 'active' : ''}`} type="button" onClick={() => onEpisodeChange(item.number)}>
                <span className="watch-episode-art">
                  {stillUrl ? <Image src={stillUrl} alt="" fill sizes="120px" /> : <span className="watch-episode-art-fallback">{item.number}</span>}
                </span>
                <span className="watch-episode-copy">
                  <strong>Episode {item.number}</strong>
                  <span>{item.title}</span>
                </span>
                <span className="watch-episode-play"><PlayIcon /></span>
              </button>
            );
          })}
        </div>
      )}
    </aside>
  );
}

function WatchPlayer({ src, title }: { src: string; title: string }) {
  const [showLoading, setShowLoading] = useState(true);

  useEffect(() => {
    // Cross-origin embeds do not reliably expose their playback/load state.
    // Keep the skeleton brief, then never cover a provider that may already be playing.
    const timer = window.setTimeout(() => setShowLoading(false), 1200);
    return () => window.clearTimeout(timer);
  }, []);

  return (
    <>
      <iframe src={src} title={`${title} player`} allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; fullscreen" allowFullScreen />
      {showLoading && <div className="watch-player-skeleton" aria-live="polite"><span>Preparing playback…</span></div>}
    </>
  );
}

function WatchSkeleton() { return <main className="watch-page"><div className="watch-shell"><div className="watch-player-wrap shimmer" /><div className="shimmer watch-skeleton-title" /><div className="shimmer watch-skeleton-copy" /></div></main>; }
function WatchError({ onBack }: { onBack: () => void }) { return <main className="watch-page"><div className="error-state"><span className="error-state-icon">📡</span><h1 className="error-state-title">This title is unavailable</h1><p className="error-state-sub">We could not load the movie information.</p><button className="btn btn-secondary" type="button" onClick={onBack}>Go back</button></div></main>; }
function BackIcon() { return <svg width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="m15 18-6-6 6-6" /></svg>; }
function PlayIcon() { return <svg width="15" height="15" viewBox="0 0 24 24" fill="currentColor"><polygon points="5,3 19,12 5,21" /></svg>; }
