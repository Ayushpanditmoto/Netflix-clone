'use client';

import { useCallback, useEffect, useRef, useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { fetchSearchPage } from '@/lib/tmdb';
import { QUERY_KEYS } from '@/lib/queryKeys';
import { useUIStore, useSearchStore } from '@/store';
import MovieTile from './MovieTile';

export default function SearchView() {
  const { searchQuery, setSearchQuery } = useUIStore();
  const { movies, page, totalPages, isLoadingMore, setResults, appendResults, setLoadingMore, reset } =
    useSearchStore();

  const inputRef = useRef<HTMLInputElement>(null);
  const loadMoreRef = useRef<HTMLDivElement>(null);
  const [debouncedQuery, setDebouncedQuery] = useState(searchQuery);
  const [loadMoreError, setLoadMoreError] = useState(false);

  useEffect(() => {
    const timer = window.setTimeout(() => setDebouncedQuery(searchQuery), 280);
    return () => window.clearTimeout(timer);
  }, [searchQuery]);

  // Debounced first-page fetch via TanStack Query
  const { data, isLoading, isError, isFetching } = useQuery({
    queryKey: QUERY_KEYS.search(debouncedQuery, 1),
    queryFn: () => fetchSearchPage(debouncedQuery, 1),
    enabled: debouncedQuery.trim().length > 0,
    staleTime: 2 * 60 * 1000,
  });

  // Sync query result into Zustand
  useEffect(() => {
    if (data) {
      setResults({ movies: data.movies, page: data.page, totalPages: data.totalPages });
    }
  }, [data, setResults]);

  // Clear when query emptied
  useEffect(() => {
    if (!debouncedQuery.trim()) reset();
  }, [debouncedQuery, reset]);

  // Auto-focus input
  useEffect(() => {
    inputRef.current?.focus();
  }, []);

  const hasMore = page < totalPages;

  const loadMore = useCallback(async () => {
    if (isLoadingMore || !hasMore) return;
    setLoadingMore(true);
    setLoadMoreError(false);
    try {
      const next = await fetchSearchPage(searchQuery, page + 1);
      appendResults(next.movies, next.page, next.totalPages);
    } catch {
      setLoadingMore(false);
      setLoadMoreError(true);
    }
  }, [appendResults, hasMore, isLoadingMore, page, searchQuery, setLoadingMore]);

  useEffect(() => {
    const sentinel = loadMoreRef.current;
    if (!sentinel || !hasMore || !searchQuery.trim()) return;

    const observer = new IntersectionObserver(
      ([entry]) => {
        if (entry.isIntersecting) void loadMore();
      },
      { rootMargin: '320px 0px' },
    );
    observer.observe(sentinel);
    return () => observer.disconnect();
  }, [hasMore, isLoadingMore, loadMore, page, searchQuery]);

  return (
    <div className="search-view">
      {/* Search bar */}
      <div className="search-bar">
        <SearchIcon />
        <input
          ref={inputRef}
          id="search-view-input"
          type="search"
          placeholder="Search movies, series, actors…"
          value={searchQuery}
          onChange={(e) => setSearchQuery(e.target.value)}
          aria-label="Search"
        />
        {searchQuery && (
          <button
            id="search-clear-btn"
            onClick={() => { setSearchQuery(''); reset(); }}
            className="search-clear"
            aria-label="Clear search"
          >
            <CloseIcon />
          </button>
        )}
      </div>

      {/* States */}
      {!searchQuery.trim() && (
        <div className="search-empty error-state">
          <span className="search-empty-icon">🎬</span>
          <h2 className="error-state-title">Search Netflix</h2>
          <p className="error-state-sub">Find movies, series and more</p>
        </div>
      )}

      {(isLoading || isFetching) && searchQuery.trim() && (
        <div className="search-grid">
          {Array.from({ length: 12 }).map((_, i) => (
            <div
              key={i}
              className="shimmer skeleton-poster"
              style={{ width: '100%', aspectRatio: '2/3' }}
            />
          ))}
        </div>
      )}

      {isError && (
        <div className="error-state">
          <span className="error-state-icon">📡</span>
          <h2 className="error-state-title">Search unavailable</h2>
          <p className="error-state-sub">Could not reach TMDB. Please try again later.</p>
        </div>
      )}

      {!isLoading && !isFetching && !isError && searchQuery.trim() && movies.length === 0 && (
        <div className="error-state">
          <span className="search-empty-icon">🔍</span>
          <h2 className="error-state-title">No results found</h2>
          <p className="error-state-sub">Try a different title or keyword</p>
        </div>
      )}

      {movies.length > 0 && (
        <>
          <div className="search-grid" role="list" aria-label="Search results">
                {movies.map((movie, index) => (
              <MovieTile
                key={`${movie.mediaType}:${movie.id}`}
                movie={movie}
                showTitle
                    animationIndex={index}
              />
            ))}
          </div>

          {/* Load more */}
          <div ref={loadMoreRef} className="search-load-more" aria-live="polite">
            {isLoadingMore ? (
              <div className="search-more-skeletons" aria-label="Loading more results">
                {Array.from({ length: 4 }).map((_, index) => <div key={index} className="shimmer skeleton-poster" />)}
              </div>
            ) : loadMoreError ? (
              <button className="btn btn-secondary" onClick={loadMore}>Retry loading results</button>
            ) : hasMore ? (
              <span className="search-load-hint">Scroll for more results</span>
            ) : (
              <span style={{ color: 'var(--text-muted)', fontSize: 13 }}>End of results</span>
            )}
          </div>
        </>
      )}
    </div>
  );
}

function SearchIcon() {
  return (
    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <circle cx="11" cy="11" r="8" /><line x1="21" y1="21" x2="16.65" y2="16.65" />
    </svg>
  );
}

function CloseIcon() {
  return (
    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round">
      <line x1="18" y1="6" x2="6" y2="18" /><line x1="6" y1="6" x2="18" y2="18" />
    </svg>
  );
}
