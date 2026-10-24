'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { useUIStore } from '@/store';

export default function Navbar() {
  const router = useRouter();
  const [scrolled, setScrolled] = useState(false);
  const { activeTab, setActiveTab, searchQuery, setSearchQuery } = useUIStore();

  useEffect(() => {
    const onScroll = () => setScrolled(window.scrollY > 50);
    window.addEventListener('scroll', onScroll, { passive: true });
    return () => window.removeEventListener('scroll', onScroll);
  }, []);

  useEffect(() => {
    const onKeyDown = (event: KeyboardEvent) => {
      const target = event.target as HTMLElement;
      if (target.matches('input, textarea, select, [contenteditable="true"]')) return;
      if (event.key.length === 1 && !event.ctrlKey && !event.metaKey && !event.altKey) {
        event.preventDefault();
        setActiveTab('search');
        setSearchQuery(event.key);
      } else if (event.key === '/' && !event.metaKey && !event.ctrlKey && !event.altKey) {
        event.preventDefault();
        setActiveTab('search');
      }
    };
    window.addEventListener('keydown', onKeyDown);
    return () => window.removeEventListener('keydown', onKeyDown);
  }, [setActiveTab, setSearchQuery]);

  return (
    <nav className={`navbar ${scrolled ? 'scrolled' : ''}`} aria-label="Main navigation">
      <span
        className="navbar-logo"
        onClick={() => { setActiveTab('home'); router.push('/'); }}
        role="button"
        tabIndex={0}
        aria-label="Go to home"
        onKeyDown={(event) => {
          if (event.key === 'Enter' || event.key === ' ') setActiveTab('home');
        }}
      >
        NETFLIX
      </span>

      <ul className="navbar-links" role="list">
        {(['home', 'search', 'trending'] as const).map((tab) => (
          <li
            key={tab}
            className={activeTab === tab ? 'active' : ''}
            onClick={() => { setActiveTab(tab); router.push(tab === 'home' ? '/' : `/?tab=${tab}`); }}
            onKeyDown={(event) => {
              if (event.key === 'Enter' || event.key === ' ') {
                event.preventDefault();
                setActiveTab(tab);
              }
            }}
            role="button"
            tabIndex={0}
            aria-current={activeTab === tab ? 'page' : undefined}
          >
            {tab.charAt(0).toUpperCase() + tab.slice(1)}
          </li>
        ))}
      </ul>

      <div className="navbar-spacer" />

      {/* Inline search for desktop */}
      {activeTab === 'search' && (
        <div className="navbar-search-field">
          <div className="search-bar" style={{ margin: 0 }}>
            <SearchIcon />
            <input
              id="navbar-search-input"
              autoFocus
              type="search"
              placeholder="Search titles…"
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              aria-label="Search movies and series"
            />
          </div>
        </div>
      )}

      {activeTab !== 'search' && (
        <button
          id="navbar-search-btn"
          className="navbar-search-icon"
          onClick={() => { setActiveTab('search'); router.push('/?tab=search'); }}
          aria-label="Open search"
        >
          <SearchIcon />
        </button>
      )}
    </nav>
  );
}

function SearchIcon() {
  return (
    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <circle cx="11" cy="11" r="8" />
      <line x1="21" y1="21" x2="16.65" y2="16.65" />
    </svg>
  );
}
