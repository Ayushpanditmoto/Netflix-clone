'use client';

import Image from 'next/image';
import type { Movie } from '@/types/tmdb';
import { backdropUrl, posterUrl, movieYear } from '@/lib/tmdb';
import { useUIStore } from '@/store';
import { useRouter } from 'next/navigation';

interface HeroBannerProps {
  movie: Movie;
}

export default function HeroBanner({ movie }: HeroBannerProps) {
  const { openMovie } = useUIStore();
  const router = useRouter();
  const imgUrl = backdropUrl(movie) ?? posterUrl(movie) ?? '';

  return (
    <section className="hero" aria-label="Featured content">
      {imgUrl && (
        <Image
          src={imgUrl}
          alt={movie.title}
          fill
          priority
          sizes="100vw"
          className="hero-image"
          style={{ objectFit: 'cover', objectPosition: 'center top' }}
        />
      )}
      <div className="hero-gradient" aria-hidden="true" />

      <div className="hero-content">
        <div className="hero-badge">
          <span>⬤</span>
          {movie.mediaType === 'tv' ? 'Series' : 'Movie'}
        </div>

        <h1 className="hero-title">{movie.title}</h1>

        <div className="hero-meta" role="list">
          <span className="hero-chip" role="listitem">{movieYear(movie)}</span>
          <span className="hero-chip" role="listitem">
            ★ {movie.voteAverage.toFixed(1)} TMDB
          </span>
          <span className="hero-chip" role="listitem">
            {movie.mediaType === 'tv' ? 'TV Series' : 'Film'}
          </span>
        </div>

        {movie.overview && (
          <p className="hero-overview">{movie.overview}</p>
        )}

        <div className="hero-actions">
          <button
            id={`hero-play-${movie.id}`}
            className="btn btn-primary"
            onClick={() => router.push(`/watch/${movie.mediaType}/${movie.id}`)}
            aria-label={`Play ${movie.title}`}
          >
            <PlayIcon />
            Play
          </button>
          <button
            id={`hero-info-${movie.id}`}
            className="btn btn-secondary"
            onClick={() => openMovie(movie)}
            aria-label={`More info about ${movie.title}`}
          >
            <InfoIcon />
            More Info
          </button>
        </div>
      </div>
    </section>
  );
}

function PlayIcon() {
  return (
    <svg width="20" height="20" viewBox="0 0 24 24" fill="currentColor">
      <polygon points="5,3 19,12 5,21" />
    </svg>
  );
}

function InfoIcon() {
  return (
    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <circle cx="12" cy="12" r="10" />
      <line x1="12" y1="8" x2="12" y2="12" />
      <line x1="12" y1="16" x2="12.01" y2="16" />
    </svg>
  );
}
