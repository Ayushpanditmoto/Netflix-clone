'use client';

import Image from 'next/image';
import type { CSSProperties } from 'react';
import { createPortal } from 'react-dom';
import { memo, useEffect, useId, useRef, useState } from 'react';
import { useQuery, useQueryClient } from '@tanstack/react-query';
import type { Movie } from '@/types/tmdb';
import { backdropUrl, fetchTrailerKey, posterUrl, fetchMovieById } from '@/lib/tmdb';
import { useRouter } from 'next/navigation';
import { useUIStore } from '@/store';
import { QUERY_KEYS } from '@/lib/queryKeys';
import { saveWatchHistory } from '@/lib/watchHistory';

interface MovieTileProps {
  movie: Movie;
  onClick?: () => void;
  showTitle?: boolean;
  animationIndex?: number;
}

function MovieTile({ movie, onClick, showTitle = false, animationIndex = 0 }: MovieTileProps) {
  const imgUrl = posterUrl(movie) ?? backdropUrl(movie);
  const router = useRouter();
  const openMovie = useUIStore((state) => state.openMovie);
  const activePreviewKey = useUIStore((state) => state.activePreviewKey);
  const setActivePreview = useUIStore((state) => state.setActivePreview);
  const instanceId = useId();
  const previewKey = `${movie.mediaType}:${movie.id}:${instanceId}`;
  const tileRef = useRef<HTMLDivElement>(null);
  const closeTimer = useRef<ReturnType<typeof setTimeout> | null>(null);
  const [previewRect, setPreviewRect] = useState<DOMRect | null>(null);
  const queryClient = useQueryClient();
  const canPreview = isPreviewAllowed();

  const trailerQuery = useQuery({
    queryKey: QUERY_KEYS.trailer(movie.id, movie.mediaType),
    queryFn: () => fetchTrailerKey(movie.id, movie.mediaType),
    enabled: canPreview && activePreviewKey === previewKey,
    staleTime: Infinity,
    gcTime: 30 * 60 * 1000,
  });

  useEffect(() => () => {
    if (closeTimer.current) clearTimeout(closeTimer.current);
  }, []);

  const openPreview = () => {
    if (!canPreview) return;
    if (closeTimer.current) clearTimeout(closeTimer.current);
    setPreviewRect(tileRef.current?.getBoundingClientRect() ?? null);
    closeTimer.current = setTimeout(() => setActivePreview(previewKey), 1000);
  };

  const handleMouseEnter = () => {
    queryClient.prefetchQuery({
      queryKey: QUERY_KEYS.movie(movie.id, movie.mediaType),
      queryFn: () => fetchMovieById(movie.id, movie.mediaType),
      staleTime: 10 * 60 * 1000,
    });
    openPreview();
  };

  const closePreview = () => {
    if (closeTimer.current) clearTimeout(closeTimer.current);
    closeTimer.current = setTimeout(() => {
      if (activePreviewKey === previewKey) setActivePreview(null);
    }, 120);
  };

  useEffect(() => {
    if (activePreviewKey !== previewKey) return;
    const update = () => setPreviewRect(tileRef.current?.getBoundingClientRect() ?? null);
    window.addEventListener('resize', update);
    window.addEventListener('scroll', update, true);
    return () => {
      window.removeEventListener('resize', update);
      window.removeEventListener('scroll', update, true);
    };
  }, [activePreviewKey, previewKey]);

  const openWatchPage = () => {
    queryClient.prefetchQuery({
      queryKey: QUERY_KEYS.movie(movie.id, movie.mediaType),
      queryFn: () => fetchMovieById(movie.id, movie.mediaType),
      staleTime: 10 * 60 * 1000,
    });
    saveWatchHistory(movie);
    window.dispatchEvent(new Event('watch-history-updated'));
    onClick?.();
    router.push(`/watch/${movie.mediaType}/${movie.id}`);
  };

  return (
    <div
      ref={tileRef}
      id={`tile-${movie.mediaType}-${movie.id}`}
      className={`movie-tile ${showTitle ? 'movie-tile-with-title' : 'movie-tile-poster-only'} ${activePreviewKey === previewKey ? 'movie-tile-preview-active' : ''}`}
      style={{ '--card-index': Math.min(animationIndex, 11) } as CSSProperties}
      onMouseEnter={handleMouseEnter}
      onMouseLeave={closePreview}
    >
      <div
        className="movie-tile-main"
        onClick={openWatchPage}
        role="button"
        tabIndex={0}
        aria-label={`Watch ${movie.title}`}
        onKeyDown={(e) => e.key === 'Enter' && openWatchPage()}
      >
        <div className="movie-tile-art">
        {imgUrl ? (
          <Image
            src={imgUrl}
            alt={movie.title}
            fill
            sizes="(max-width: 480px) 120px, (max-width: 768px) 15vw, 170px"
            loading="lazy"
            className="movie-tile-poster"
            style={{ objectFit: 'cover' }}
          />
        ) : (
          <div className="movie-tile-fallback" aria-label={`${movie.title} artwork unavailable`}>
            <span aria-hidden="true">{movie.title.charAt(0).toUpperCase()}</span>
            <strong>{movie.title}</strong>
          </div>
        )}

          {/* Hover overlay */}
          <div className="movie-tile-overlay">
            <div className="movie-tile-play">
              <svg width="16" height="16" viewBox="0 0 24 24" fill="currentColor">
                <polygon points="5,3 19,12 5,21" />
              </svg>
            </div>
            {movie.voteAverage > 0 && (
              <span className="movie-tile-rating" aria-label={`TMDB rating ${movie.voteAverage.toFixed(1)}`}>
                ★ {movie.voteAverage.toFixed(1)}
              </span>
            )}
          </div>
        </div>

        {showTitle && (
          <div className="movie-tile-title" title={movie.title}>
            {movie.title}
          </div>
        )}
      </div>
      <button
        className="movie-tile-info"
        type="button"
        onClick={() => openMovie(movie)}
        aria-label={`More information about ${movie.title}`}
      >
        <InfoIcon />
      </button>
      {activePreviewKey === previewKey && previewRect && createPortal(
        <TrailerPreview
          movie={movie}
          backdrop={backdropUrl(movie) ?? imgUrl}
          trailerKey={trailerQuery.data ?? null}
          loading={trailerQuery.isLoading}
          position={previewRect}
          onMouseEnter={() => {
            if (closeTimer.current) clearTimeout(closeTimer.current);
          }}
          onMouseLeave={closePreview}
          onPlay={openWatchPage}
          onInfo={() => openMovie(movie)}
        />,
        document.body
      )}
    </div>
  );
}

export default memo(MovieTile, (previous, next) =>
  previous.movie === next.movie
  && previous.showTitle === next.showTitle
  && previous.animationIndex === next.animationIndex
  && previous.onClick === next.onClick,
);

interface TrailerPreviewProps {
  movie: Movie;
  backdrop: string | null;
  trailerKey: string | null;
  loading: boolean;
  position: DOMRect;
  onMouseEnter: () => void;
  onMouseLeave: () => void;
  onPlay: () => void;
  onInfo: () => void;
}

function TrailerPreview({ movie, backdrop, trailerKey, loading, position, onMouseEnter, onMouseLeave, onPlay, onInfo }: TrailerPreviewProps) {
  const iframeRef = useRef<HTMLIFrameElement>(null);
  const [muted, setMuted] = useState(true);
  const width = Math.min(280, window.innerWidth - 24);
  const left = Math.max(12, Math.min(position.left + position.width / 2 - width / 2, window.innerWidth - width - 12));
  const estimatedHeight = 170;
  const top = Math.max(12, Math.min(position.top + position.height / 2 - estimatedHeight / 2, window.innerHeight - estimatedHeight - 12));
  const embedUrl = trailerKey
    ? `https://www.youtube-nocookie.com/embed/${trailerKey}?autoplay=1&mute=1&controls=0&playsinline=1&rel=0&modestbranding=1&enablejsapi=1&origin=${encodeURIComponent(window.location.origin)}`
    : null;

  const sendPlayerCommand = (func: 'mute' | 'unMute') => {
    iframeRef.current?.contentWindow?.postMessage(JSON.stringify({ event: 'command', func, args: [] }), 'https://www.youtube-nocookie.com');
    setMuted(func === 'mute');
  };

  return (
    <div
      className="trailer-preview"
      style={{ left, top }}
      onMouseEnter={onMouseEnter}
      onMouseLeave={onMouseLeave}
      role="dialog"
      aria-label={`Preview ${movie.title}`}
    >
      <div className="trailer-preview-media">
        {backdrop && <Image src={backdrop} alt="" fill sizes="(max-width: 768px) 55vw, 410px" className="trailer-preview-backdrop" />}
        {embedUrl && !loading && (
          <iframe
            ref={iframeRef}
            className="trailer-preview-iframe"
            src={embedUrl}
            title={`${movie.title} trailer preview`}
            allow="autoplay; encrypted-media"
          />
        )}
        {!trailerKey && <span className="trailer-preview-fallback">Trailer unavailable</span>}
        {loading && <span className="trailer-preview-loading">Finding trailer…</span>}
        <div className="trailer-preview-shade" />
        {trailerKey && (
          <button
            type="button"
            className="trailer-preview-icon trailer-preview-mute"
            onClick={() => sendPlayerCommand(muted ? 'unMute' : 'mute')}
            aria-label={muted ? 'Unmute trailer' : 'Mute trailer'}
          >
            {muted ? <MutedIcon /> : <SoundIcon />}
          </button>
        )}
      </div>
      <div className="trailer-preview-actions">
        <button type="button" className="trailer-preview-play" onClick={onPlay} aria-label={`Watch ${movie.title}`}><PlayIcon /></button>
        <button type="button" className="trailer-preview-icon" aria-label="Add to My List"><PlusIcon /></button>
        <button type="button" className="trailer-preview-icon" aria-label="Like"><ThumbIcon /></button>
        <button type="button" className="trailer-preview-info" onClick={onInfo} aria-label={`More info about ${movie.title}`}>
          <ChevronIcon />
        </button>
      </div>
      <div className="trailer-preview-meta">
        <span className="trailer-preview-match">{Math.round(movie.voteAverage * 10)}% Match</span>
        <span>{movie.releaseDate?.slice(0, 4) || 'New'}</span>
        <span className="trailer-preview-badge">HD</span>
      </div>
    </div>
  );
}

function PlayIcon() {
  return <svg width="15" height="15" viewBox="0 0 24 24" fill="currentColor"><polygon points="5,3 19,12 5,21" /></svg>;
}
function PlusIcon() {
  return <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M12 5v14M5 12h14" /></svg>;
}
function ThumbIcon() {
  return <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M7 10v11M15 21H8a2 2 0 0 1-2-2v-9l5-7 1 1v6h6a2 2 0 0 1 2 2l-2 7a2 2 0 0 1-2 2z" /></svg>;
}
function ChevronIcon() {
  return <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M6 9l6 6 6-6" /></svg>;
}

function MutedIcon() {
  return <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M11 5 6 9H3v6h3l5 4V5ZM19 9l-4 6M15 9l4 6" /></svg>;
}

function SoundIcon() {
  return <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M11 5 6 9H3v6h3l5 4V5ZM15.5 8.5a5 5 0 0 1 0 7M18.5 5.5a9 9 0 0 1 0 13" /></svg>;
}

function InfoIcon() {
  return (
    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
      <circle cx="12" cy="12" r="9" /><path d="M12 11v5M12 8h.01" />
    </svg>
  );
}

function isPreviewAllowed() {
  if (typeof window === 'undefined') return false;
  const reducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
  const finePointer = window.matchMedia('(hover: hover) and (pointer: fine)').matches;
  const saveData = 'connection' in navigator && Boolean((navigator as Navigator & { connection?: { saveData?: boolean } }).connection?.saveData);
  return finePointer && !reducedMotion && !saveData;
}
