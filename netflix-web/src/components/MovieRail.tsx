'use client';

import { useState, useRef, useCallback } from 'react';
import type { MovieSection } from '@/types/tmdb';
import { fetchSection } from '@/lib/tmdb';
import { useSectionStore } from '@/store';
import MovieTile from './MovieTile';

interface MovieRailProps {
  section: MovieSection;
  sectionIndex: number;
}

export default function MovieRail({ section, sectionIndex }: MovieRailProps) {
  const scrollRef = useRef<HTMLDivElement>(null);
  const [loadingMore, setLoadingMore] = useState(false);
  const [localSection, setLocalSection] = useState(section);
  const appendToSection = useSectionStore((s) => s.appendToSection);

  const hasMore = localSection.request != null && localSection.page < localSection.totalPages;

  const loadMore = useCallback(async () => {
    if (loadingMore || !hasMore || !localSection.request) return;
    setLoadingMore(true);
    try {
      const next = await fetchSection(localSection.request, localSection.page + 1);
      setLocalSection((prev) => {
        const seenIds = new Set(prev.movies.map((m) => `${m.mediaType}:${m.id}`));
        const merged = [
          ...prev.movies,
          ...next.movies.filter((m) => {
            const key = `${m.mediaType}:${m.id}`;
            if (seenIds.has(key)) return false;
            seenIds.add(key);
            return true;
          }),
        ];
        return { ...prev, movies: merged, page: next.page, totalPages: next.totalPages };
      });
      appendToSection(sectionIndex, next.movies, next.page, next.totalPages);
    } catch {
      // silently fail
    } finally {
      setLoadingMore(false);
    }
  }, [loadingMore, hasMore, localSection, sectionIndex, appendToSection]);

  const onScroll = useCallback(() => {
    const el = scrollRef.current;
    if (!el) return;
    if (el.scrollLeft + el.clientWidth >= el.scrollWidth - 300) {
      loadMore();
    }
  }, [loadMore]);

  const scrollRail = (direction: 'next' | 'previous') => {
    scrollRef.current?.scrollBy({
      left: direction === 'next' ? scrollRef.current.clientWidth * 0.82 : -scrollRef.current.clientWidth * 0.82,
      behavior: 'smooth',
    });
  };

  return (
    <section className="section-rail" aria-label={localSection.title}>
      <div className="section-header">
        <h2 className="section-title">{localSection.title}</h2>
        <div className="section-controls">
          <button className="rail-arrow" type="button" onClick={() => scrollRail('previous')} aria-label={`Scroll ${localSection.title} left`}>
            <ChevronIcon direction="left" />
          </button>
          <button className="rail-arrow" type="button" onClick={() => scrollRail('next')} aria-label={`Scroll ${localSection.title} right`}>
            <ChevronIcon />
          </button>
        </div>
      </div>

      <div
        ref={scrollRef}
        className="rail-scroll"
        onScroll={onScroll}
        role="list"
        aria-label={`${localSection.title} movie list`}
      >
        {localSection.movies.map((movie, index) => (
          <MovieTile
            key={`${movie.mediaType}:${movie.id}`}
            movie={movie}
            animationIndex={index}
          />
        ))}

        {/* Load more / spinner tile */}
        {hasMore && (
          <div
            id={`rail-load-more-${sectionIndex}`}
            className={`movie-tile rail-load-more-tile ${loadingMore ? 'shimmer' : ''}`}
            onClick={loadingMore ? undefined : loadMore}
            onKeyDown={(event) => {
              if (!loadingMore && (event.key === 'Enter' || event.key === ' ')) {
                event.preventDefault();
                loadMore();
              }
            }}
            role="button"
            tabIndex={0}
            aria-label="Load more"
          >
            {loadingMore ? <span className="rail-loading-label">Loading more…</span> : (
              <>
                <GridIcon />
                See all
              </>
            )}
          </div>
        )}
      </div>
    </section>
  );
}

function ChevronIcon({ direction = 'right' }: { direction?: 'left' | 'right' }) {
  return (
    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
      <polyline points={direction === 'left' ? '15,18 9,12 15,6' : '9,18 15,12 9,6'} />
    </svg>
  );
}

function GridIcon() {
  return (
    <svg width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <rect x="3" y="3" width="7" height="7" /><rect x="14" y="3" width="7" height="7" />
      <rect x="14" y="14" width="7" height="7" /><rect x="3" y="14" width="7" height="7" />
    </svg>
  );
}
