'use client';

import { useQuery } from '@tanstack/react-query';
import { useEffect } from 'react';
import { QUERY_KEYS } from '@/lib/queryKeys';
import { fetchHomeSections } from '@/lib/tmdb';
import { useUIStore, useSectionStore } from '@/store';
import Navbar from '@/components/Navbar';
import HeroBanner from '@/components/HeroBanner';
import MovieRail from '@/components/MovieRail';
import SearchView from '@/components/SearchView';
import DetailModal from '@/components/DetailModal';
import PlayerModal from '@/components/PlayerModal';
import HomeSkeleton from '@/components/HomeSkeleton';
import ContinueWatching from '@/components/ContinueWatching';

export default function HomePage() {
  const { activeTab } = useUIStore();
  const { sections, setSections } = useSectionStore();

  const { data, isLoading, isError, refetch } = useQuery({
    queryKey: QUERY_KEYS.homeSections,
    queryFn: fetchHomeSections,
    staleTime: 5 * 60 * 1000,
  });

  // Sync to Zustand so rails can update themselves
  useEffect(() => {
    if (data) setSections(data);
  }, [data, setSections]);

  const displaySections = sections.length > 0 ? sections : (data ?? []);

  return (
    <div className="page-container">
      <Navbar />

      <main id="main-content">
        {activeTab === 'search' ? (
          <SearchView />
        ) : (
          <>
            {isLoading && <HomeSkeleton />}

            {isError && (
              <div className="error-state" style={{ paddingTop: 120 }}>
                <span className="error-state-icon">📡</span>
                <h1 className="error-state-title">Could not load movies</h1>
                <p className="error-state-sub">Check your connection and try again</p>
                <button
                  id="home-retry-btn"
                  className="btn btn-primary"
                  onClick={() => refetch()}
                  aria-label="Retry loading"
                >
                  Try again
                </button>
              </div>
            )}

            {!isLoading && !isError && displaySections.length > 0 && (
              <>
                {/* Hero — first movie of first section */}
                <HeroBanner movie={displaySections[0].movies[0]} />

                {/* Rails */}
                <div className="home-content">
                  <ContinueWatching />
                  {displaySections.map((section, i) => (
                    <MovieRail key={section.title} section={section} sectionIndex={i} />
                  ))}
                </div>
              </>
            )}
          </>
        )}

        {/* Footer */}
        {activeTab !== 'search' && !isLoading && !isError && (
          <footer className="footer">
            <p className="footer-disclaimer">
              <strong style={{ color: 'var(--text-secondary)' }}>Disclaimer:</strong> This is an
              unofficial educational project built with Next.js + TypeScript + TanStack Query +
              Zustand. All movie metadata is provided by{' '}
              <a
                href="https://www.themoviedb.org"
                target="_blank"
                rel="noopener noreferrer"
                style={{ color: 'var(--netflix-red)' }}
              >
                TMDB
              </a>
              . Netflix is a trademark of Netflix, Inc. This project is not affiliated with or
              endorsed by Netflix.
            </p>
          </footer>
        )}
      </main>

      {/* Modals */}
      <DetailModal />
      <PlayerModal />
    </div>
  );
}
