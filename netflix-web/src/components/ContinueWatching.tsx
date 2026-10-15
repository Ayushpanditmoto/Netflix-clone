'use client';

import { useEffect, useState } from 'react';
import type { WatchHistoryItem } from '@/lib/watchHistory';
import { readWatchHistory } from '@/lib/watchHistory';
import MovieTile from './MovieTile';

export default function ContinueWatching() {
  const [history, setHistory] = useState<WatchHistoryItem[]>([]);

  useEffect(() => {
    const refresh = () => setHistory(readWatchHistory());
    refresh();
    window.addEventListener('focus', refresh);
    window.addEventListener('watch-history-updated', refresh);
    return () => {
      window.removeEventListener('focus', refresh);
      window.removeEventListener('watch-history-updated', refresh);
    };
  }, []);

  if (history.length === 0) return null;

  return (
    <section className="continue-watching" aria-labelledby="continue-watching-title">
      <div className="section-header">
        <div>
          <h2 id="continue-watching-title" className="section-title">Continue Watching</h2>
          <p className="section-subtitle">Pick up where you left off</p>
        </div>
      </div>
      <div className="rail-scroll" role="list" aria-label="Continue watching">
        {history.map((item, index) => (
          <div className="continue-item" key={`${item.movie.mediaType}:${item.movie.id}`}>
            <MovieTile movie={item.movie} animationIndex={index} />
            {item.season && item.episode && (
              <span className="continue-episode">Resume S{item.season} E{item.episode}</span>
            )}
          </div>
        ))}
      </div>
    </section>
  );
}
