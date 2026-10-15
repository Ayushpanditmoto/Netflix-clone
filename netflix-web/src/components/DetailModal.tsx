'use client';

import Image from 'next/image';
import { useEffect, useRef, useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import type { Movie, Episode } from '@/types/tmdb';
import { backdropUrl, posterUrl, movieYear, tmdbImageUrl } from '@/lib/tmdb';
import { fetchSeasons, fetchEpisodes, fetchTrailerKey } from '@/lib/tmdb';
import { QUERY_KEYS } from '@/lib/queryKeys';
import { useUIStore } from '@/store';

export default function DetailModal() {
  const { selectedMovie, closeMovie, openPlayer } = useUIStore();
  if (!selectedMovie) return null;
  return <DetailModalInner movie={selectedMovie} onClose={closeMovie} onPlay={openPlayer} />;
}

interface DetailModalInnerProps {
  movie: Movie;
  onClose: () => void;
  onPlay: (movie: Movie, season?: number, episode?: number) => void;
}

function DetailModalInner({ movie, onClose, onPlay }: DetailModalInnerProps) {
  const isTv = movie.mediaType === 'tv';
  const imgUrl = backdropUrl(movie) ?? posterUrl(movie);
  const closeButtonRef = useRef<HTMLButtonElement>(null);

  useEffect(() => {
    closeButtonRef.current?.focus();
    const onKeyDown = (event: KeyboardEvent) => {
      if (event.key === 'Escape') onClose();
    };
    window.addEventListener('keydown', onKeyDown);
    return () => window.removeEventListener('keydown', onKeyDown);
  }, [onClose]);

  const { data: trailerKey } = useQuery({
    queryKey: QUERY_KEYS.trailer(movie.id, movie.mediaType),
    queryFn: () => fetchTrailerKey(movie.id, movie.mediaType),
    staleTime: Infinity,
  });

  return (
    <div
      className="modal-backdrop"
      onClick={(e) => e.target === e.currentTarget && onClose()}
      role="dialog"
      aria-modal="true"
      aria-label={`Details for ${movie.title}`}
    >
      <div className="modal-panel">
        {/* Hero */}
        <div className="modal-hero">
          {imgUrl && (
            <Image
              src={imgUrl}
              alt={movie.title}
              fill
              sizes="860px"
              style={{ objectFit: 'cover', objectPosition: 'center top' }}
              priority
            />
          )}
          <div className="modal-hero-gradient" />
          <div className="modal-hero-content">
            <h2 className="modal-title">{movie.title}</h2>
          </div>
          <button
            id="modal-close-btn"
            className="modal-close"
            ref={closeButtonRef}
            onClick={onClose}
            aria-label="Close details"
          >
            <CloseIcon />
          </button>
        </div>

        {/* Body */}
        <div className="modal-body">
          <div className="modal-meta">
            <span className="hero-chip">{movieYear(movie)}</span>
            <span className="hero-chip">★ {movie.voteAverage.toFixed(1)} TMDB</span>
            <span className="hero-chip">{isTv ? 'TV Series' : 'Movie'}</span>
          </div>

          <div className="modal-actions">
            <button
              id={`modal-play-${movie.id}`}
              className="btn btn-primary"
              onClick={() => { onClose(); onPlay(movie); }}
              aria-label={`Play ${movie.title}`}
            >
              <PlayIcon />
              Play
            </button>
            <button
              id={`modal-watchlist-${movie.id}`}
              className="btn btn-secondary"
              aria-label={`Add ${movie.title} to watchlist`}
            >
              <PlusIcon />
              My List
            </button>
          </div>

          {movie.overview && (
            <p className="modal-overview">{movie.overview}</p>
          )}

          {trailerKey && (
            <div style={{ marginBottom: 20 }}>
              <h3 className="modal-section-title">Trailer</h3>
              <div className="trailer-wrap">
                <iframe
                  id={`trailer-${movie.id}`}
                  src={`https://www.youtube-nocookie.com/embed/${trailerKey}?rel=0&modestbranding=1`}
                  title={`${movie.title} trailer`}
                  allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
                  allowFullScreen
                />
              </div>
            </div>
          )}

          {isTv && <EpisodeSection movie={movie} onPlay={onPlay} onClose={onClose} />}
        </div>
      </div>
    </div>
  );
}

// ── Episode section ──────────────────────────────────────────────────────────

interface EpisodeSectionProps {
  movie: Movie;
  onPlay: (movie: Movie, season?: number, episode?: number) => void;
  onClose: () => void;
}

function EpisodeSection({ movie, onPlay, onClose }: EpisodeSectionProps) {
  const [selectedSeason, setSelectedSeason] = useState<number | null>(null);

  const { data: seasons, isLoading: loadingSeasons, isError: errorSeasons, refetch: retrySeasons } =
    useQuery({
      queryKey: QUERY_KEYS.seasons(movie.id),
      queryFn: () => fetchSeasons(movie.id),
      staleTime: Infinity,
    });

  // Pick the default season (newest non-specials)
  const resolvedSeasonNumber = selectedSeason ?? (() => {
    if (!seasons?.length) return null;
    const real = seasons.filter((s) => s.number > 0);
    return real.length > 0 ? real[real.length - 1].number : seasons[0].number;
  })();

  const { data: episodes, isLoading: loadingEps, isError: errorEps, refetch: retryEps } =
    useQuery({
      queryKey: QUERY_KEYS.episodes(movie.id, resolvedSeasonNumber ?? 0),
      queryFn: () => fetchEpisodes(movie.id, resolvedSeasonNumber!),
      enabled: resolvedSeasonNumber != null,
      staleTime: Infinity,
    });

  if (loadingSeasons) {
    return (
      <div>
        <h3 className="modal-section-title">Episodes</h3>
        <div className="season-tabs episode-season-skeletons" aria-label="Loading seasons">
          {Array.from({ length: 4 }).map((_, index) => <span key={index} className="shimmer episode-season-skeleton" />)}
        </div>
      </div>
    );
  }

  if (errorSeasons) {
    return (
      <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 16 }}>
        <button className="btn btn-ghost" onClick={() => retrySeasons()} aria-label="Retry loading seasons">
          ↻ Retry seasons
        </button>
      </div>
    );
  }

  if (!seasons?.length) return null;

  return (
    <div>
      <h3 className="modal-section-title">Episodes</h3>

      {/* Season tabs */}
      <div className="season-tabs" role="tablist" aria-label="Season selector">
        {seasons.map((s) => (
          <button
            key={s.number}
            id={`season-tab-${movie.id}-${s.number}`}
            className={`season-tab ${resolvedSeasonNumber === s.number ? 'active' : ''}`}
            onClick={() => setSelectedSeason(s.number)}
            role="tab"
            aria-selected={resolvedSeasonNumber === s.number}
            aria-controls={`season-panel-${s.number}`}
          >
            {s.name}
          </button>
        ))}
      </div>

      {/* Episode list */}
      {loadingEps ? (
        <div className="episode-list" aria-label="Loading episodes">
          {Array.from({ length: 4 }).map((_, i) => (
            <div key={i} className="episode-card-skeleton shimmer" />
          ))}
        </div>
      ) : errorEps ? (
        <button className="btn btn-ghost" onClick={() => retryEps()} aria-label="Retry loading episodes">
          ↻ Retry episodes
        </button>
      ) : (
        <div
          id={`season-panel-${resolvedSeasonNumber}`}
          className="episode-list"
          role="tabpanel"
          aria-label={`Season ${resolvedSeasonNumber} episodes`}
        >
          {episodes?.map((ep) => (
            <EpisodeCard
              key={ep.id}
              episode={ep}
              onPlay={() => {
                onClose();
                onPlay(movie, ep.seasonNumber, ep.number);
              }}
            />
          ))}
        </div>
      )}
    </div>
  );
}

function EpisodeCard({ episode, onPlay }: { episode: Episode; onPlay: () => void }) {
  const stillImg = tmdbImageUrl(episode.stillPath, 'w300');
  const airLabel = episode.airDate?.length >= 10
    ? new Date(episode.airDate).toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' })
    : '';

  return (
    <div
      id={`episode-${episode.id}`}
      className="episode-card"
      onClick={onPlay}
      role="button"
      tabIndex={0}
      aria-label={`Play S${episode.seasonNumber}E${episode.number}: ${episode.title}`}
      onKeyDown={(e) => e.key === 'Enter' && onPlay()}
    >
      <div style={{ position: 'relative', width: 110, aspectRatio: '16/9', flexShrink: 0 }}>
        {stillImg ? (
          <Image
            src={stillImg}
            alt={episode.title}
            fill
            sizes="110px"
            className="episode-still"
            style={{ objectFit: 'cover', borderRadius: 4 }}
          />
        ) : (
          <div className="episode-still shimmer" />
        )}
        {/* Play overlay */}
        <div style={{
          position: 'absolute', inset: 0, display: 'flex', alignItems: 'center', justifyContent: 'center',
          opacity: 0, transition: 'opacity 200ms', borderRadius: 4, background: 'rgba(0,0,0,0.5)'
        }}
          className="episode-play-overlay"
        >
          <svg width="22" height="22" viewBox="0 0 24 24" fill="white">
            <polygon points="5,3 19,12 5,21" />
          </svg>
        </div>
      </div>
      <div className="episode-info">
        <div className="episode-code">
          S{episode.seasonNumber}:E{episode.number}
          {episode.runtime ? ` • ${episode.runtime}m` : ''}
          {airLabel ? ` • ${airLabel}` : ''}
        </div>
        <div className="episode-title">{episode.title}</div>
        {episode.overview && (
          <div className="episode-overview">{episode.overview}</div>
        )}
      </div>
    </div>
  );
}

// ── Icons ────────────────────────────────────────────────────────────────────

function CloseIcon() {
  return (
    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round">
      <line x1="18" y1="6" x2="6" y2="18" /><line x1="6" y1="6" x2="18" y2="18" />
    </svg>
  );
}

function PlayIcon() {
  return (
    <svg width="18" height="18" viewBox="0 0 24 24" fill="currentColor">
      <polygon points="5,3 19,12 5,21" />
    </svg>
  );
}

function PlusIcon() {
  return (
    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round">
      <line x1="12" y1="5" x2="12" y2="19" /><line x1="5" y1="12" x2="19" y2="12" />
    </svg>
  );
}
