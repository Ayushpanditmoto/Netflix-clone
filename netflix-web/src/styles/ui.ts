import { createGlobalStyle } from 'styled-components';

export const UIStyle = createGlobalStyle`
  .page-container { min-height: 100vh; background: ${({ theme }) => theme.colors.background}; }
  .navbar {
    position: fixed; inset: 0 0 auto; z-index: 100; display: flex; align-items: center;
    gap: clamp(1rem, 3vw, 2rem); height: 4.25rem; padding: 0 4%;
    background: linear-gradient(to bottom, rgba(0,0,0,.88), transparent);
    transition: background ${({ theme }) => theme.motion.slow} ${({ theme }) => theme.motion.easing}, box-shadow ${({ theme }) => theme.motion.slow} ${({ theme }) => theme.motion.easing};
  }
  .navbar.scrolled { border-bottom: 1px solid rgba(255,255,255,.1); background: rgba(10,10,10,.68); box-shadow: 0 .5rem 1.5rem rgba(0,0,0,.2); backdrop-filter: blur(18px) saturate(135%); -webkit-backdrop-filter: blur(18px) saturate(135%); }
  .navbar-logo { flex-shrink: 0; color: ${({ theme }) => theme.colors.accent}; cursor: pointer; font-size: clamp(1.3rem, 2.5vw, 1.75rem); font-weight: 900; letter-spacing: -.06em; }
  .navbar-links { display: flex; gap: clamp(.75rem, 2vw, 1.5rem); margin: 0; padding: 0; list-style: none; }
  .navbar-links li { position: relative; min-height: 2.75rem; display: flex; align-items: center; color: ${({ theme }) => theme.colors.textSecondary}; cursor: pointer; font-size: .875rem; font-weight: 600; transition: color ${({ theme }) => theme.motion.fast} ${({ theme }) => theme.motion.easing}; }
  .navbar-links li::after { position: absolute; right: 0; bottom: .35rem; left: 0; height: 2px; border-radius: 2px; background: ${({ theme }) => theme.colors.accent}; content: ''; transform: scaleX(0); transform-origin: center; transition: transform ${({ theme }) => theme.motion.fast} ${({ theme }) => theme.motion.easing}; }
  .navbar-links li:hover, .navbar-links li.active { color: ${({ theme }) => theme.colors.text}; }
  .navbar-links li.active::after { transform: scaleX(1); }
  .navbar-spacer { flex: 1; }
  .navbar-search-field { width: 13.75rem; }
  .navbar-search-icon { width: 2.75rem; height: 2.75rem; display: grid; place-items: center; color: ${({ theme }) => theme.colors.textSecondary}; background: transparent; cursor: pointer; border-radius: ${({ theme }) => theme.radii.medium}; }
  .navbar-search-icon:hover { color: ${({ theme }) => theme.colors.text}; background: rgba(255,255,255,.08); }

  .hero { position: relative; height: min(44rem, 84vh); min-height: 32rem; overflow: hidden; }
  .hero-image { object-fit: cover; object-position: center top; animation: hero-scale 900ms ${({ theme }) => theme.motion.entrance} both; }
  @keyframes hero-scale { from { opacity: .65; transform: scale(1.04); } to { opacity: 1; transform: scale(1); } }
  .hero-gradient { position: absolute; inset: 0; background: linear-gradient(90deg, rgba(0,0,0,.84), rgba(0,0,0,.26) 65%, transparent), linear-gradient(0deg, ${({ theme }) => theme.colors.background}, transparent 42%, rgba(0,0,0,.2)); }
  .hero-content { position: absolute; z-index: 1; bottom: clamp(4rem, 14vh, 8rem); left: 4%; width: min(36rem, 88%); animation: content-reveal 500ms ${({ theme }) => theme.motion.entrance} both; }
  @keyframes content-reveal { from { opacity: 0; transform: translateY(1rem); } to { opacity: 1; transform: translateY(0); } }
  .hero-badge { display: inline-flex; align-items: center; gap: .4rem; margin-bottom: .75rem; color: ${({ theme }) => theme.colors.accent}; font-size: .7rem; font-weight: 800; letter-spacing: .1em; text-transform: uppercase; }
  .hero-title { margin: 0 0 .75rem; font-size: clamp(2rem, 6vw, 4rem); line-height: 1.02; letter-spacing: -.04em; }
  .hero-meta, .modal-meta { display: flex; flex-wrap: wrap; gap: .5rem; margin-bottom: .875rem; }
  .hero-chip { padding: .3rem .6rem; border: 1px solid rgba(255,255,255,.16); border-radius: ${({ theme }) => theme.radii.small}; color: ${({ theme }) => theme.colors.textSecondary}; background: rgba(255,255,255,.1); font-size: .75rem; font-weight: 700; }
  .hero-overview { max-width: 36rem; margin: 0 0 1.25rem; color: ${({ theme }) => theme.colors.textSecondary}; font-size: .95rem; line-height: 1.55; display: -webkit-box; -webkit-line-clamp: 3; -webkit-box-orient: vertical; overflow: hidden; }
  .hero-actions, .modal-actions { display: flex; flex-wrap: wrap; gap: .75rem; }
  .btn { min-height: 2.75rem; display: inline-flex; align-items: center; justify-content: center; gap: .5rem; padding: .65rem 1.1rem; border-radius: ${({ theme }) => theme.radii.medium}; color: ${({ theme }) => theme.colors.text}; cursor: pointer; font-size: .875rem; font-weight: 700; transition: transform ${({ theme }) => theme.motion.fast} ${({ theme }) => theme.motion.easing}, background ${({ theme }) => theme.motion.fast} ${({ theme }) => theme.motion.easing}, filter ${({ theme }) => theme.motion.fast} ${({ theme }) => theme.motion.easing}; }
  .btn:hover { transform: translateY(-1px); filter: brightness(1.08); }
  .btn:active { transform: translateY(0) scale(.98); }
  .btn-primary { background: ${({ theme }) => theme.colors.accent}; }
  .btn-primary:hover { background: ${({ theme }) => theme.colors.accentStrong}; }
  .btn-secondary { border: 1px solid rgba(255,255,255,.15); background: rgba(255,255,255,.14); backdrop-filter: blur(8px); }
  .btn-secondary:hover { background: rgba(255,255,255,.22); }
  .btn-ghost { color: ${({ theme }) => theme.colors.textSecondary}; background: transparent; }

  .home-content { position: relative; z-index: 1; margin-top: -5rem; }
  .section-rail { position: relative; content-visibility: auto; contain-intrinsic-size: 0 20rem; margin-bottom: 2.75rem; }
  .section-header { display: flex; align-items: center; justify-content: space-between; gap: 1rem; padding: 0 4%; margin-bottom: .9rem; }
  .section-controls { display: flex; gap: .35rem; }
  .rail-arrow { width: 2.25rem; height: 2.25rem; display: grid; place-items: center; border: 1px solid ${({ theme }) => theme.colors.border}; border-radius: 50%; color: ${({ theme }) => theme.colors.textSecondary}; background: rgba(255,255,255,.06); cursor: pointer; transition: color ${({ theme }) => theme.motion.fast} ${({ theme }) => theme.motion.easing}, background ${({ theme }) => theme.motion.fast} ${({ theme }) => theme.motion.easing}, transform ${({ theme }) => theme.motion.fast} ${({ theme }) => theme.motion.easing}; }
  .rail-arrow:hover { color: #fff; background: rgba(255,255,255,.16); transform: scale(1.06); }
  .section-title { margin: 0; font-size: clamp(1.05rem, 2vw, 1.35rem); letter-spacing: -.02em; }
  .section-subtitle { margin: .25rem 0 0; color: ${({ theme }) => theme.colors.textMuted}; font-size: .72rem; }
  .continue-watching { margin-bottom: 2.75rem; }
  .continue-item { position: relative; flex: 0 0 clamp(7.5rem, 15vw, 10.625rem); }
  .continue-item .movie-tile { width: 100%; }
  .continue-episode { position: absolute; right: .35rem; bottom: .35rem; left: .35rem; z-index: 2; padding: .3rem .4rem; border: 1px solid rgba(255,255,255,.14); border-radius: ${({ theme }) => theme.radii.small}; color: #fff; background: rgba(0,0,0,.8); font-size: .6rem; font-weight: 700; text-align: center; }
  .section-see-all { display: flex; align-items: center; gap: .25rem; color: ${({ theme }) => theme.colors.textMuted}; cursor: pointer; font-size: .8rem; font-weight: 700; }
  .section-see-all:hover { color: ${({ theme }) => theme.colors.text}; }
  .rail-scroll { display: flex; gap: .85rem; padding: .45rem 4% 1.15rem; overflow-x: auto; scroll-snap-type: x mandatory; scrollbar-width: none; }
  .section-rail::after { position: absolute; right: 0; bottom: 0; width: 4%; height: 8rem; pointer-events: none; background: linear-gradient(90deg, transparent, ${({ theme }) => theme.colors.background}); content: ''; }
  .rail-scroll::-webkit-scrollbar, .season-tabs::-webkit-scrollbar { display: none; }
  .movie-tile { position: relative; flex: 0 0 clamp(7.5rem, 15vw, 10.625rem); overflow: hidden; border: 1px solid transparent; border-radius: ${({ theme }) => theme.radii.medium}; background: ${({ theme }) => theme.colors.surface}; scroll-snap-align: start; transition: transform ${({ theme }) => theme.motion.standard} ${({ theme }) => theme.motion.easing}, box-shadow ${({ theme }) => theme.motion.standard} ${({ theme }) => theme.motion.easing}, border-color ${({ theme }) => theme.motion.standard} ${({ theme }) => theme.motion.easing}; }
  .movie-tile-main { cursor: pointer; }
  .movie-tile-art { position: relative; aspect-ratio: 2 / 3; }
  .movie-tile { animation: card-reveal 420ms ${({ theme }) => theme.motion.entrance} both; }
  .movie-tile:nth-child(-n + 12) { animation-delay: calc((var(--card-index, 0)) * 35ms); }
  @keyframes card-reveal { from { opacity: 0; transform: translateY(.6rem); } to { opacity: 1; transform: translateY(0); } }
  .movie-tile-preview-active { border-color: rgba(255,255,255,.18); box-shadow: 0 .75rem 2.5rem rgba(0,0,0,.45); }
  .movie-tile-poster { object-fit: cover; }
  .movie-tile-fallback { position: absolute; inset: 0; display: flex; flex-direction: column; align-items: center; justify-content: center; gap: .5rem; padding: .75rem; color: ${({ theme }) => theme.colors.textSecondary}; background: radial-gradient(circle at 50% 25%, rgba(229,9,20,.38), transparent 48%), linear-gradient(145deg, #252525, #0d0d0d); text-align: center; }
  .movie-tile-fallback span { color: ${({ theme }) => theme.colors.accent}; font-size: clamp(2.5rem, 7vw, 4rem); font-weight: 900; line-height: 1; }
  .movie-tile-fallback strong { display: -webkit-box; overflow: hidden; font-size: .7rem; line-height: 1.35; -webkit-box-orient: vertical; -webkit-line-clamp: 2; }
  .movie-tile-rating { position: absolute; top: .5rem; left: .5rem; z-index: 1; padding: .25rem .4rem; border: 1px solid rgba(255,255,255,.18); border-radius: ${({ theme }) => theme.radii.small}; color: #fff; background: rgba(0,0,0,.68); font-size: .62rem; font-weight: 800; backdrop-filter: blur(6px); }
  .movie-tile-overlay { position: absolute; inset: 0; display: flex; align-items: flex-end; padding: .75rem; opacity: 0; background: linear-gradient(transparent 45%, rgba(0,0,0,.8)); transition: opacity ${({ theme }) => theme.motion.standard}; }
  .movie-tile-main:active { transform: scale(.98); }
  .movie-tile-play { width: 2.25rem; height: 2.25rem; display: grid; place-items: center; border-radius: 50%; color: #000; background: #fff; }
  .movie-tile-info { position: absolute; right: .6rem; bottom: .6rem; width: 2.25rem; height: 2.25rem; display: grid; place-items: center; border: 1px solid rgba(255,255,255,.3); border-radius: 50%; color: #fff; background: rgba(0,0,0,.6); cursor: pointer; }
  .movie-tile-poster-only { height: fit-content; }
  .movie-tile-poster-only .movie-tile-info { bottom: .6rem; }
  .movie-tile-title { overflow: hidden; padding: .5rem .6rem .65rem; color: ${({ theme }) => theme.colors.textSecondary}; font-size: .75rem; font-weight: 600; text-overflow: ellipsis; white-space: nowrap; }
  /* Expanded hover panel — isolated from default movie tiles */
  .trailer-preview {
    position: fixed;
    z-index: 150;
    width: 280px;
    max-width: calc(100vw - 24px);
    overflow: hidden;
    border: 1px solid rgba(255,255,255,.16);
    border-radius: 8px;
    background: #181818;
    box-shadow: 0 16px 48px rgba(0,0,0,.7);
    pointer-events: auto;
    animation: preview-in 300ms ease-out both;
  }
  .trailer-preview-media {
    position: relative;
    width: 100%;
    aspect-ratio: 16 / 9;
    overflow: hidden;
    background: #050505;
  }
  .trailer-preview-backdrop, .trailer-preview-iframe {
    position: absolute;
    inset: 0;
    width: 100%;
    height: 100%;
    border: 0;
    object-fit: cover;
  }
  .trailer-preview-iframe { z-index: 1; }
  .trailer-preview-shade {
    position: absolute;
    inset: 0;
    z-index: 2;
    background: linear-gradient(0deg, rgba(0,0,0,.65), transparent 55%);
    pointer-events: none;
  }
  .trailer-preview-loading, .trailer-preview-fallback {
    position: absolute;
    inset: 0;
    z-index: 3;
    display: grid;
    place-items: center;
    color: ${({ theme }) => theme.colors.textMuted};
    font-size: .72rem;
  }
  .trailer-preview-mute {
    position: absolute;
    right: 10px;
    bottom: 10px;
    z-index: 4;
    display: grid;
    place-items: center;
    width: 30px;
    height: 30px;
    padding: 0;
    border: 1px solid rgba(255,255,255,.45);
    border-radius: 50%;
    background: rgba(0,0,0,.7);
    color: #fff;
    cursor: pointer;
  }
  .trailer-preview-actions {
    display: flex;
    align-items: center;
    gap: 10px;
    padding: 16px 16px 12px;
  }
  .trailer-preview-actions .trailer-preview-play,
  .trailer-preview-actions .trailer-preview-icon,
  .trailer-preview-actions .trailer-preview-info {
    position: static;
    display: grid;
    place-items: center;
    flex: 0 0 34px;
    width: 34px;
    height: 34px;
    min-width: 0;
    padding: 0;
    border-radius: 50%;
    cursor: pointer;
    transition: background 180ms ease, border-color 180ms ease, transform 180ms ease;
  }
  .trailer-preview-actions .trailer-preview-play {
    border: 1px solid #fff;
    background: #fff;
    color: #141414;
  }
  .trailer-preview-actions .trailer-preview-icon,
  .trailer-preview-actions .trailer-preview-info {
    border: 1px solid #777;
    background: #242424;
    color: #fff;
  }
  .trailer-preview-actions .trailer-preview-info { margin-left: auto; }
  .trailer-preview-actions button:hover { transform: scale(1.08); }
  .trailer-preview-actions .trailer-preview-play:hover { background: #ddd; }
  .trailer-preview-actions .trailer-preview-icon:hover,
  .trailer-preview-actions .trailer-preview-info:hover {
    border-color: #fff;
    background: #383838;
  }
  .trailer-preview-meta {
    display: flex;
    align-items: center;
    flex-wrap: wrap;
    gap: 10px;
    margin: 0;
    padding: 0 16px 18px;
    color: #b3b3b3;
    font-size: 12px;
    line-height: 1.5;
  }
  .trailer-preview-match { color: #46d369; font-weight: 700; }
  .trailer-preview-badge {
    padding: 1px 6px;
    border: 1px solid #777;
    border-radius: 3px;
    color: #ccc;
    font-size: 10px;
    line-height: 1.4;
  }
  @keyframes preview-in {
    from { opacity: 0; transform: translateY(6px) scale(.96); }
    to { opacity: 1; transform: translateY(0) scale(1); }
  }
  @media (hover: hover) and (pointer: fine) {
    .movie-tile { transition: transform 300ms ease-out, box-shadow 300ms ease-out; }
    .movie-tile:hover { transform: scale(1.05) translateY(-.2rem); box-shadow: 0 .75rem 2.5rem rgba(0,0,0,.45); z-index: 2; }
    .movie-tile:hover .movie-tile-overlay, .movie-tile-preview-active .movie-tile-overlay { opacity: 1; }
    .movie-tile-preview-active { transform: scale(1.05) translateY(-.2rem); box-shadow: 0 .75rem 2.5rem rgba(0,0,0,.45); }
  }

  .search-bar { display: flex; align-items: center; gap: .6rem; margin: 0 4% 1.5rem; padding: .7rem .9rem; border: 1px solid ${({ theme }) => theme.colors.border}; border-radius: ${({ theme }) => theme.radii.large}; background: ${({ theme }) => theme.colors.surface}; }
  .search-bar:focus-within { border-color: rgba(229,9,20,.6); box-shadow: ${({ theme }) => theme.shadows.focus}; }
  .search-bar svg { flex-shrink: 0; color: ${({ theme }) => theme.colors.textMuted}; }
  .search-bar input { flex: 1; min-width: 0; border: 0; outline: 0; color: ${({ theme }) => theme.colors.text}; background: transparent; font-size: .95rem; }
  .search-bar input::placeholder { color: ${({ theme }) => theme.colors.textMuted}; }
  .search-view { min-height: 100vh; padding-top: 5rem; }
  .search-clear { display: grid; width: 2rem; height: 2rem; place-items: center; border-radius: 50%; color: ${({ theme }) => theme.colors.textMuted}; background: transparent; cursor: pointer; }
  .search-clear:hover { color: ${({ theme }) => theme.colors.text}; background: rgba(255,255,255,.08); }
  .search-empty { min-height: 50vh; }
  .search-empty-icon { font-size: 3rem; }
  .search-load-more { display: flex; justify-content: center; padding: 0 0 2.5rem; }
  .search-load-hint { color: ${({ theme }) => theme.colors.textMuted}; font-size: .75rem; }
  .search-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(8.5rem, 1fr)); gap: 1rem; padding: 0 4% 2rem; }
  .search-grid .movie-tile { width: 100%; }
  .search-grid .movie-tile:nth-child(-n + 12) { animation-delay: calc((var(--card-index, 0)) * 25ms); }

  .shimmer { position: relative; overflow: hidden; background: ${({ theme }) => theme.colors.shimmerFrom}; }
  .shimmer::after { position: absolute; inset: 0; background: linear-gradient(105deg, transparent 30%, rgba(255,255,255,.055) 47%, rgba(255,255,255,.09) 50%, rgba(255,255,255,.055) 53%, transparent 70%); content: ''; transform: translateX(-100%); animation: shimmer 2.4s ${({ theme }) => theme.motion.easing} infinite; }
  @keyframes shimmer { to { transform: translateX(100%); } }
  .skeleton-hero { height: min(42rem, 82vh); min-height: 32rem; }
  .skeleton-poster { width: clamp(7.5rem, 15vw, 10.625rem); aspect-ratio: 2 / 3; flex: 0 0 auto; border-radius: ${({ theme }) => theme.radii.medium}; }
  .skeleton-rail { margin-bottom: 2rem; }
  .skeleton-rail-header { margin: 0 4% .75rem; }
  .skeleton-heading { width: min(12rem, 38%); height: 1.25rem; border-radius: ${({ theme }) => theme.radii.small}; }
  .skeleton-rail-scroll { overflow: hidden; }
  .search-more-skeletons { display: grid; grid-template-columns: repeat(4, minmax(5rem, 7rem)); gap: .75rem; width: min(100%, 32rem); padding: .25rem 0 2.5rem; }
  .search-more-skeletons .skeleton-poster { width: 100%; }
  .episode-season-skeletons { overflow: hidden; }
  .episode-season-skeleton { display: block; width: 5.5rem; height: 2.5rem; flex: 0 0 auto; border-radius: ${({ theme }) => theme.radii.pill}; }
  .episode-card-skeleton { height: 4.5rem; border-radius: ${({ theme }) => theme.radii.medium}; }

  .modal-backdrop { position: fixed; inset: 0; z-index: 200; display: flex; align-items: center; justify-content: center; padding: 1rem; overflow-y: auto; background: rgba(0,0,0,.78); backdrop-filter: blur(5px); animation: fade-in 200ms ease; }
  @keyframes fade-in { from { opacity: 0; } to { opacity: 1; } }
  .modal-panel { width: min(100%, 53.75rem); max-height: 92vh; display: flex; flex-direction: column; overflow: hidden; border-radius: ${({ theme }) => theme.radii.large}; background: ${({ theme }) => theme.colors.surface}; box-shadow: ${({ theme }) => theme.shadows.modal}; animation: slide-up 220ms ease; }
  @keyframes slide-up { from { opacity: 0; transform: translateY(1rem); } to { opacity: 1; transform: translateY(0); } }
  .modal-hero { position: relative; height: clamp(13rem, 35vw, 21.25rem); flex-shrink: 0; }
  .modal-hero-gradient { position: absolute; inset: 0; background: linear-gradient(0deg, ${({ theme }) => theme.colors.surface}, transparent 72%); }
  .modal-hero-content { position: absolute; right: 1.5rem; bottom: 1.25rem; left: 1.5rem; }
  .modal-title { margin: 0; font-size: clamp(1.4rem, 4vw, 2rem); line-height: 1.1; }
  .modal-close { position: absolute; top: .875rem; right: .875rem; width: 2.75rem; height: 2.75rem; display: grid; place-items: center; border: 1px solid ${({ theme }) => theme.colors.border}; border-radius: 50%; color: ${({ theme }) => theme.colors.text}; background: rgba(15,15,15,.82); cursor: pointer; }
  .modal-close:hover { background: ${({ theme }) => theme.colors.surfaceRaised}; }
  .modal-body { flex: 1; overflow-y: auto; padding: 1.25rem 1.5rem 1.75rem; }
  .modal-actions { margin-bottom: 1.25rem; }
  .modal-overview { margin: 0 0 1.25rem; color: ${({ theme }) => theme.colors.textSecondary}; font-size: .9rem; line-height: 1.65; }
  .modal-section-title { margin: 0 0 .75rem; font-size: 1rem; }
  .season-tabs { display: flex; gap: .5rem; margin-bottom: .75rem; overflow-x: auto; scrollbar-width: none; }
  .season-tab { min-height: 2.5rem; flex-shrink: 0; padding: .45rem .85rem; border: 1px solid ${({ theme }) => theme.colors.border}; border-radius: ${({ theme }) => theme.radii.pill}; color: ${({ theme }) => theme.colors.textSecondary}; background: transparent; cursor: pointer; font-size: .8rem; font-weight: 700; }
  .season-tab.active, .season-tab:hover { border-color: ${({ theme }) => theme.colors.accent}; color: #fff; background: ${({ theme }) => theme.colors.accent}; }
  .episode-list { display: flex; flex-direction: column; gap: .5rem; }
  .episode-card { display: flex; gap: .75rem; padding: .625rem; border: 1px solid transparent; border-radius: ${({ theme }) => theme.radii.medium}; cursor: pointer; }
  .episode-card:hover { border-color: ${({ theme }) => theme.colors.border}; background: ${({ theme }) => theme.colors.surfaceRaised}; }
  .episode-still { width: 6.875rem; aspect-ratio: 16 / 9; flex-shrink: 0; object-fit: cover; border-radius: ${({ theme }) => theme.radii.small}; }
  .episode-info { min-width: 0; flex: 1; }
  .episode-code { margin-bottom: .2rem; color: ${({ theme }) => theme.colors.textMuted}; font-size: .7rem; font-weight: 700; }
  .episode-title { margin-bottom: .25rem; font-size: .875rem; font-weight: 700; }
  .episode-overview { display: -webkit-box; overflow: hidden; color: ${({ theme }) => theme.colors.textSecondary}; font-size: .75rem; line-height: 1.4; -webkit-line-clamp: 2; -webkit-box-orient: vertical; }

  .player-embed { width: 100%; aspect-ratio: 16 / 9; margin-bottom: .75rem; overflow: hidden; border-radius: ${({ theme }) => theme.radii.medium}; background: #000; }
  .player-embed iframe, .trailer-wrap iframe { width: 100%; height: 100%; border: 0; }
  .player-embed-placeholder { height: 100%; display: flex; flex-direction: column; align-items: center; justify-content: center; gap: .75rem; color: ${({ theme }) => theme.colors.textMuted}; }
  .player-embed-hint { margin: 0 0 1.5rem; color: ${({ theme }) => theme.colors.textMuted}; font-size: .75rem; }
  .source-list { display: flex; flex-direction: column; gap: .625rem; }
  .source-tile { display: flex; align-items: center; gap: .875rem; min-height: 3.5rem; padding: .75rem 1rem; border: 1px solid ${({ theme }) => theme.colors.border}; border-radius: ${({ theme }) => theme.radii.medium}; background: ${({ theme }) => theme.colors.surface}; cursor: pointer; }
  .source-tile:hover, .source-tile.selected { border-color: ${({ theme }) => theme.colors.accent}; background: rgba(229,9,20,.08); }
  .source-icon { width: 2.375rem; height: 2.375rem; display: grid; place-items: center; flex-shrink: 0; border-radius: ${({ theme }) => theme.radii.medium}; background: rgba(255,255,255,.06); }
  .source-name { font-size: .875rem; font-weight: 700; }
  .source-host { margin-top: .1rem; color: ${({ theme }) => theme.colors.textMuted}; font-size: .7rem; }
  .source-play-btn { width: 2rem; height: 2rem; display: grid; place-items: center; margin-left: auto; flex-shrink: 0; border-radius: 50%; color: #fff; }
  .trailer-wrap { aspect-ratio: 16 / 9; margin-bottom: 1.25rem; overflow: hidden; border-radius: ${({ theme }) => theme.radii.medium}; background: #000; }
  .error-state { min-height: 40vh; display: flex; flex-direction: column; align-items: center; justify-content: center; gap: .75rem; padding: 4rem 1.5rem; text-align: center; }
  .error-state-icon { font-size: 2.5rem; opacity: .5; }
  .error-state-title { margin: 0; font-size: 1rem; }
  .error-state-sub { margin: 0; color: ${({ theme }) => theme.colors.textSecondary}; font-size: .875rem; }
  .footer { padding: 2.5rem 4% 1.5rem; border-top: 1px solid ${({ theme }) => theme.colors.border}; }
  .footer-disclaimer { max-width: 40rem; margin: 0; color: ${({ theme }) => theme.colors.textMuted}; font-size: .75rem; line-height: 1.6; }

  .watch-page { min-height: 100vh; padding: 5rem 4% 3rem; background: ${({ theme }) => theme.colors.background}; animation: page-rise 360ms ${({ theme }) => theme.motion.entrance} both; }
  @keyframes page-rise { from { opacity: 0; transform: translateY(.5rem); } to { opacity: 1; transform: translateY(0); } }
  .watch-shell { width: min(100%, 75rem); margin: 0 auto; }
  .watch-topbar { display: flex; align-items: center; gap: .75rem; margin-bottom: .75rem; padding-bottom: .5rem; border-bottom: 1px solid ${({ theme }) => theme.colors.border}; }
  .watch-context { display: flex; min-width: 0; flex: 1; flex-direction: column; gap: .15rem; }
  .watch-context strong { overflow: hidden; color: ${({ theme }) => theme.colors.text}; font-size: .9rem; text-overflow: ellipsis; white-space: nowrap; }
  .watch-context span { color: ${({ theme }) => theme.colors.textMuted}; font-size: .7rem; }
  .watch-topbar-source { display: flex; align-items: center; gap: .6rem; min-width: min(24rem, 60%); }
  .watch-back { min-height: 2.75rem; display: inline-flex; align-items: center; gap: .4rem; padding: .55rem .8rem; border: 1px solid ${({ theme }) => theme.colors.border}; border-radius: ${({ theme }) => theme.radii.medium}; color: ${({ theme }) => theme.colors.textSecondary}; background: ${({ theme }) => theme.colors.surface}; cursor: pointer; font-size: .8rem; font-weight: 700; }
  .watch-back:hover { color: #fff; background: ${({ theme }) => theme.colors.surfaceRaised}; }
  .watch-player-wrap { position: relative; aspect-ratio: 16 / 9; overflow: hidden; border: 1px solid ${({ theme }) => theme.colors.border}; border-radius: ${({ theme }) => theme.radii.large}; background: #000; box-shadow: 0 1.5rem 4rem rgba(0,0,0,.35); }
  .watch-player-wrap iframe { width: 100%; height: 100%; border: 0; }
  .watch-player-caption { display: flex; justify-content: space-between; gap: 1rem; padding: .55rem .15rem 0; color: ${({ theme }) => theme.colors.textMuted}; font-size: .7rem; }
  .watch-player-caption-actions { display: inline-flex; align-items: center; gap: .65rem; }
  .watch-retry { padding: .2rem .45rem; border: 1px solid ${({ theme }) => theme.colors.border}; border-radius: ${({ theme }) => theme.radii.small}; color: ${({ theme }) => theme.colors.textSecondary}; background: transparent; cursor: pointer; font-size: .68rem; }
  .watch-retry:hover { border-color: ${({ theme }) => theme.colors.accent}; color: #fff; }
  .watch-player-skeleton { position: absolute; inset: 0; display: grid; place-items: center; background: linear-gradient(135deg, #101010, #1d1d1d); }
  .watch-player-skeleton span { color: ${({ theme }) => theme.colors.textMuted}; font-size: .8rem; }
  .watch-player-state { position: absolute; inset: 0; display: flex; flex-direction: column; align-items: center; justify-content: center; gap: .75rem; padding: 1rem; text-align: center; background: rgba(0,0,0,.72); }
  .watch-player-state p { max-width: 28rem; margin: 0; color: ${({ theme }) => theme.colors.textSecondary}; font-size: .85rem; line-height: 1.5; }
  .watch-details { display: grid; grid-template-columns: minmax(0, 1fr) minmax(15rem, 22rem); gap: 2rem; padding: 1.75rem 0 2.25rem; }
  .watch-episode-actions { display: flex; flex-wrap: wrap; gap: .5rem; margin-top: 1rem; }
  .watch-section-header { padding: 0; }
  .watch-skeleton-title { width: min(28rem, 80%); height: 2rem; margin-top: 1.5rem; }
  .watch-skeleton-copy { height: 5rem; margin-top: 1rem; }
  .watch-title { margin: 0 0 .6rem; font-size: clamp(1.5rem, 3vw, 2.35rem); letter-spacing: -.04em; }
  .watch-copy { color: ${({ theme }) => theme.colors.textSecondary}; font-size: .9rem; line-height: 1.65; }
  .watch-copy summary { color: #fff; cursor: pointer; font-weight: 700; }
  .watch-copy p { margin: .75rem 0 0; }
  .watch-selector { width: 100%; padding: 1.35rem; border: 1px solid ${({ theme }) => theme.colors.border}; border-radius: ${({ theme }) => theme.radii.large}; background: linear-gradient(135deg, ${({ theme }) => theme.colors.surfaceRaised}, ${({ theme }) => theme.colors.surface}); box-shadow: 0 .75rem 2rem rgba(0,0,0,.2); animation: content-reveal 360ms ${({ theme }) => theme.motion.entrance} both; }
  .watch-selector h2 { margin: 0 0 .75rem; font-size: .8rem; letter-spacing: .08em; text-transform: uppercase; }
  .watch-selector-heading { display: flex; align-items: flex-start; justify-content: space-between; gap: 1rem; }
  .watch-selector-heading p { margin: -.4rem 0 .8rem; color: ${({ theme }) => theme.colors.textMuted}; font-size: .72rem; }
  .watch-season-count { flex-shrink: 0; color: ${({ theme }) => theme.colors.textMuted}; font-size: .7rem; }
  .watch-selector-list { display: flex; flex-wrap: wrap; gap: .5rem; }
  .watch-season-skeletons { display: flex; flex-wrap: wrap; gap: .5rem; }
  .watch-season-skeleton { width: 5.5rem; height: 2.5rem; border-radius: ${({ theme }) => theme.radii.medium}; }
  .watch-selector-message { margin: .75rem 0 0; color: ${({ theme }) => theme.colors.textMuted}; font-size: .75rem; line-height: 1.45; }
  .watch-selector-button { min-height: 2.5rem; display: inline-flex; flex-direction: column; align-items: flex-start; gap: .1rem; padding: .45rem .7rem; border: 1px solid ${({ theme }) => theme.colors.border}; border-radius: ${({ theme }) => theme.radii.medium}; color: ${({ theme }) => theme.colors.textSecondary}; background: transparent; cursor: pointer; font-size: .75rem; font-weight: 700; }
  .watch-selector-button small { color: ${({ theme }) => theme.colors.textMuted}; font-size: .58rem; font-weight: 500; }
  .watch-selector-button:hover, .watch-selector-button.active { border-color: ${({ theme }) => theme.colors.accent}; color: #fff; background: ${({ theme }) => theme.colors.accent}; }
  .watch-episodes { display: grid; grid-template-columns: repeat(3, minmax(0, 1fr)); gap: .75rem; margin-top: 1rem; }
  .watch-episode { display: flex; align-items: center; gap: .7rem; min-height: 5.25rem; padding: .5rem; border: 1px solid transparent; border-radius: ${({ theme }) => theme.radii.medium}; color: ${({ theme }) => theme.colors.textSecondary}; background: rgba(255,255,255,.04); cursor: pointer; text-align: left; font-size: .75rem; }
  .watch-episode:hover, .watch-episode.active { border-color: ${({ theme }) => theme.colors.accent}; color: #fff; }
  .watch-episode { transition: background ${({ theme }) => theme.motion.fast} ${({ theme }) => theme.motion.easing}, border-color ${({ theme }) => theme.motion.fast} ${({ theme }) => theme.motion.easing}, transform ${({ theme }) => theme.motion.fast} ${({ theme }) => theme.motion.easing}; }
  .watch-episode:active { transform: scale(.99); }
  .watch-episode-art { position: relative; width: 7.5rem; aspect-ratio: 16 / 9; display: grid; place-items: center; flex: 0 0 auto; overflow: hidden; border-radius: ${({ theme }) => theme.radii.small}; background: linear-gradient(135deg, #292929, #111); }
  .watch-episode-art img { object-fit: cover; transition: transform ${({ theme }) => theme.motion.standard} ${({ theme }) => theme.motion.easing}; }
  .watch-episode:hover .watch-episode-art img, .watch-episode.active .watch-episode-art img { transform: scale(1.06); }
  .watch-episode-art-fallback { color: ${({ theme }) => theme.colors.textMuted}; font-size: 1rem; font-weight: 800; }
  .watch-episode-copy { min-width: 0; display: grid; gap: .2rem; flex: 1; }
  .watch-episode-copy strong { color: ${({ theme }) => theme.colors.textMuted}; font-size: .68rem; letter-spacing: .04em; text-transform: uppercase; }
  .watch-episode-copy span { overflow: hidden; color: ${({ theme }) => theme.colors.text}; font-size: .78rem; font-weight: 700; text-overflow: ellipsis; white-space: nowrap; }
  .watch-episode-play { width: 2rem; height: 2rem; display: grid; place-items: center; flex: 0 0 auto; border-radius: 50%; color: #fff; background: rgba(255,255,255,.1); transition: background ${({ theme }) => theme.motion.fast} ${({ theme }) => theme.motion.easing}, transform ${({ theme }) => theme.motion.fast} ${({ theme }) => theme.motion.easing}; }
  .watch-episode:hover .watch-episode-play, .watch-episode.active .watch-episode-play { background: ${({ theme }) => theme.colors.accent}; transform: scale(1.05); }
  .watch-episode-skeleton { min-height: 5.25rem; border-radius: ${({ theme }) => theme.radii.medium}; }
  .rail-load-more-tile { display: flex; align-items: center; justify-content: center; flex-direction: column; gap: .5rem; min-height: 14.0625rem; background: ${({ theme }) => theme.colors.surface}; cursor: pointer; color: ${({ theme }) => theme.colors.textMuted}; font-size: .75rem; font-weight: 700; }
  .rail-load-more-tile.shimmer { cursor: default; }
  .rail-loading-label { color: ${({ theme }) => theme.colors.textSecondary}; }
  .watch-sources { padding-bottom: 1.5rem; }
  .watch-sources-header { display: flex; align-items: center; justify-content: space-between; margin-bottom: .75rem; }
  .watch-sources-header h2 { margin: 0; font-size: 1rem; }
  .watch-source-select-wrap { display: flex; align-items: center; gap: .75rem; max-width: 34rem; }
  .watch-source-label { display: inline-flex; align-items: center; gap: .35rem; color: ${({ theme }) => theme.colors.textSecondary}; font-size: .8rem; font-weight: 700; white-space: nowrap; }
  .watch-source-dot { width: .45rem; height: .45rem; border-radius: 50%; background: #3ddc84; box-shadow: 0 0 .5rem rgba(61,220,132,.7); }
  .watch-source-select { min-height: 2.75rem; flex: 1; padding: .55rem .75rem; border: 1px solid ${({ theme }) => theme.colors.border}; border-radius: ${({ theme }) => theme.radii.medium}; color: ${({ theme }) => theme.colors.text}; background: ${({ theme }) => theme.colors.surface}; cursor: pointer; font-size: .8rem; transition: border-color ${({ theme }) => theme.motion.fast} ${({ theme }) => theme.motion.easing}, box-shadow ${({ theme }) => theme.motion.fast} ${({ theme }) => theme.motion.easing}; }
  .watch-source-select:focus { border-color: ${({ theme }) => theme.colors.accent}; outline: none; box-shadow: ${({ theme }) => theme.shadows.focus}; }
  .watch-recommendations { padding-top: 1.5rem; border-top: 1px solid ${({ theme }) => theme.colors.border}; animation: content-reveal 420ms ${({ theme }) => theme.motion.entrance} both; }
  .watch-recommendation-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(8.5rem, 1fr)); gap: 1rem; }
  .watch-recommendation-grid .movie-tile { width: 100%; }

  @media (max-width: 47.99rem) {
    .navbar-links { display: none; }
    .navbar { height: 3.75rem; }
    .navbar-search-field { display: none; }
    .hero { height: min(36rem, 78vh); min-height: 28rem; }
    .hero-content { bottom: 3.25rem; }
    .hero-gradient { background: linear-gradient(0deg, ${({ theme }) => theme.colors.background}, rgba(0,0,0,.1) 75%), linear-gradient(90deg, rgba(0,0,0,.65), transparent); }
    .home-content { margin-top: -2rem; }
    .search-grid { grid-template-columns: repeat(2, minmax(0, 1fr)); gap: .75rem; }
    .modal-backdrop { align-items: flex-start; padding: .5rem; }
    .modal-panel { max-height: calc(100vh - 1rem); }
    .modal-body { padding: 1rem; }
    .episode-still { width: 6rem; }
    .watch-page { padding: 4.5rem 1rem 2rem; }
    .watch-details { grid-template-columns: 1fr; gap: 1.25rem; padding-top: 1.25rem; }
    .watch-player-wrap { border-radius: ${({ theme }) => theme.radii.medium}; }
    .watch-recommendation-grid { grid-template-columns: repeat(2, minmax(0, 1fr)); gap: .75rem; }
    .watch-topbar { align-items: stretch; flex-direction: column; }
    .watch-topbar-source { width: 100%; max-width: none; }
    .watch-topbar-source .watch-source-select { min-width: 0; }
    .watch-source-select-wrap { align-items: stretch; flex-direction: column; gap: .4rem; }
    .watch-episodes { grid-template-columns: 1fr; }
    .watch-episode-art { width: 6.5rem; }
    .movie-tile:hover, .movie-tile-preview-active { transform: none; box-shadow: none; }
  }
  @media (max-width: 47.99rem) {
    .section-rail { margin-bottom: 1.25rem; }
    .rail-scroll { gap: .6rem; padding: .35rem 4% .75rem; }
    .movie-tile { flex: 0 0 clamp(9.5rem, 34vw, 11.5rem); }
    .rail-arrow { display: none; }
    .section-title { font-size: 1rem; }
    .section-subtitle { margin-top: .15rem; }
    .continue-item { flex: 0 0 clamp(8rem, 32vw, 10rem); }
    .continue-episode { font-size: .55rem; }
    .movie-tile-overlay { opacity: 0; }
    .movie-tile-play { width: 1.75rem; height: 1.75rem; }
    .movie-tile-info { width: 1.75rem; height: 1.75rem; }
  }
  @media (max-width: 26.5rem) {
    .movie-tile { flex: 0 0 10rem; }
    .continue-item { flex: 0 0 8.5rem; }
  }
`;
