'use client';

import { useState } from 'react';
import Image from 'next/image';
import type { Movie } from '@/types/tmdb';
import { PLAYER_SOURCES } from '@/lib/playerSources';
import { urlFor } from '@/types/tmdb';
import { useUIStore } from '@/store';
import { backdropUrl, posterUrl, movieYear } from '@/lib/tmdb';

export default function PlayerModal() {
  const { playerMovie, playerSeason, playerEpisode, closePlayer } = useUIStore();
  if (!playerMovie) return null;

  return (
    <PlayerModalInner
      movie={playerMovie}
      season={playerSeason}
      episode={playerEpisode}
      onClose={closePlayer}
    />
  );
}

interface PlayerModalInnerProps {
  movie: Movie;
  season?: number;
  episode?: number;
  onClose: () => void;
}

function PlayerModalInner({ movie, season, episode, onClose }: PlayerModalInnerProps) {
  const [selectedSource, setSelectedSource] = useState<string | null>(null);
  const isEpisode = season != null && episode != null;
  const imgUrl = backdropUrl(movie) ?? posterUrl(movie);

  const activeSource = PLAYER_SOURCES.find((s) => s.name === selectedSource);
  const embedUrl = activeSource
    ? urlFor(activeSource, movie.id, movie.mediaType, season, episode)
    : null;

  return (
    <div
      className="modal-backdrop"
      style={{ alignItems: 'flex-start', overflowY: 'auto', padding: '60px 16px 24px' }}
      onClick={(e) => e.target === e.currentTarget && onClose()}
      role="dialog"
      aria-modal="true"
      aria-label={`Player for ${movie.title}`}
    >
      <div
        className="modal-panel"
        style={{
          maxWidth: 900,
          maxHeight: 'none',
          margin: '0 auto',
        }}
      >
        {/* Backdrop */}
        <div style={{ position: 'relative', height: 'clamp(220px, 35vw, 360px)', flexShrink: 0 }}>
          {imgUrl && (
            <Image
              src={imgUrl}
              alt={movie.title}
              fill
              sizes="900px"
              style={{ objectFit: 'cover', objectPosition: 'center top' }}
            />
          )}
          <div style={{
            position: 'absolute', inset: 0,
            background: 'linear-gradient(to bottom, rgba(0,0,0,0.3) 0%, rgba(20,20,20,0.95) 100%)'
          }} />
          <button
            id="player-close-btn"
            className="modal-close"
            onClick={onClose}
            aria-label="Close player"
          >
            <CloseIcon />
          </button>
        </div>

        {/* Player content */}
        <div style={{ padding: '20px 24px 28px', overflowY: 'auto' }}>
          <h2 style={{ fontSize: 'clamp(1.3rem, 3vw, 2rem)', fontWeight: 900, marginBottom: 8 }}>
            {movie.title}
          </h2>

          <div style={{ display: 'flex', flexWrap: 'wrap', gap: 8, marginBottom: 16 }}>
            <span className="hero-chip">{movieYear(movie)}</span>
            <span className="hero-chip">★ {movie.voteAverage.toFixed(1)}</span>
            <span className="hero-chip">{movie.mediaType === 'tv' ? 'TV Series' : 'Movie'}</span>
            {isEpisode && (
              <span className="hero-chip" style={{ color: 'var(--netflix-red)' }}>
                S{season} E{episode}
              </span>
            )}
          </div>

          {/* Embed player */}
          <div className="player-embed" style={{ marginBottom: 12 }}>
            {embedUrl ? (
              <iframe
                id={`player-embed-${selectedSource}`}
                key={`${selectedSource}-${movie.id}-${season}-${episode}`}
                src={embedUrl}
                title={`${movie.title} player`}
                allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; fullscreen"
                allowFullScreen
                sandbox="allow-scripts allow-same-origin allow-forms allow-pointer-lock allow-popups allow-top-navigation"
              />
            ) : (
              <div className="player-embed-placeholder">
                <div style={{
                  width: 64, height: 64, borderRadius: '50%',
                  border: '2px solid rgba(255,255,255,0.15)',
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                }}>
                  <svg width="30" height="30" viewBox="0 0 24 24" fill="rgba(255,255,255,0.3)">
                    <polygon points="5,3 19,12 5,21" />
                  </svg>
                </div>
                <span style={{ fontSize: 13 }}>Select a source below to start playing</span>
              </div>
            )}
          </div>

          {embedUrl && (
            <p className="player-embed-hint">
              Now playing from <strong>{selectedSource}</strong> · If it doesn&apos;t load, try another source.
            </p>
          )}

          {/* Source list */}
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 10 }}>
            <span className="source-label">SOURCES</span>
            <span style={{ fontSize: 12, color: 'var(--text-muted)' }}>
              {PLAYER_SOURCES.length} available
            </span>
          </div>

          <div className="source-list">
            {PLAYER_SOURCES.map((source) => (
              <div
                key={source.name}
                id={`source-${source.name.replace(/\s/g, '-').toLowerCase()}`}
                className={`source-tile ${selectedSource === source.name ? 'selected' : ''}`}
                onClick={() => setSelectedSource(source.name)}
                role="button"
                tabIndex={0}
                aria-label={`Select ${source.name} as player source`}
                onKeyDown={(e) => e.key === 'Enter' && setSelectedSource(source.name)}
              >
                <div className="source-icon">
                  <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                    <polygon points="23 7 16 12 23 17 23 7" />
                    <rect x="1" y="5" width="15" height="14" rx="2" ry="2" />
                  </svg>
                </div>
                <div>
                  <div className="source-name">{source.name}</div>
                  <div className="source-host">{source.host}</div>
                </div>
                <div style={{ flex: 1 }} />
                <div className={`source-play-btn ${selectedSource === source.name ? '' : ''}`}
                  style={{
                    background: selectedSource === source.name ? 'var(--netflix-red)' : 'rgba(255,255,255,0.08)',
                  }}
                >
                  <svg width="14" height="14" viewBox="0 0 24 24" fill="currentColor">
                    <polygon points="5,3 19,12 5,21" />
                  </svg>
                </div>
              </div>
            ))}
          </div>

          {/* Disclaimer */}
          <p style={{ fontSize: 11, color: 'var(--text-muted)', marginTop: 16, lineHeight: 1.6 }}>
            ⚠️ Educational demo only. Sources are third-party embeds not operated by this project.
          </p>
        </div>
      </div>
    </div>
  );
}

function CloseIcon() {
  return (
    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round">
      <line x1="18" y1="6" x2="6" y2="18" /><line x1="6" y1="6" x2="18" y2="18" />
    </svg>
  );
}
