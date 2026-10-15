import { createGlobalStyle } from 'styled-components';

export const theme = {
  colors: {
    accent: '#e50914',
    accentStrong: '#b20710',
    background: '#080808',
    surface: '#141414',
    surfaceRaised: '#1f1f1f',
    text: '#fff',
    textSecondary: 'rgba(255, 255, 255, 0.72)',
    textMuted: 'rgba(255, 255, 255, 0.46)',
    border: 'rgba(255, 255, 255, 0.12)',
    shimmerFrom: '#191919',
    shimmerTo: '#292929',
  },
  space: {
    micro: '0.25rem',
    small: '0.5rem',
    compact: '0.75rem',
    standard: '1rem',
    section: '1.5rem',
    large: '2rem',
    major: '3rem',
    huge: '4rem',
  },
  radii: {
    small: '0.375rem',
    medium: '0.625rem',
    large: '0.875rem',
    pill: '999px',
  },
  shadows: {
    card: '0 0.75rem 2rem rgba(0, 0, 0, 0.42)',
    modal: '0 1.5rem 5rem rgba(0, 0, 0, 0.72)',
    focus: '0 0 0 3px rgba(229, 9, 20, 0.26)',
  },
  motion: {
    micro: '140ms',
    fast: '180ms',
    standard: '240ms',
    slow: '360ms',
    easing: 'cubic-bezier(0.22, 1, 0.36, 1)',
    entrance: 'cubic-bezier(0.16, 1, 0.3, 1)',
  },
  breakpoints: {
    tablet: '48rem',
    desktop: '64rem',
    wide: '90rem',
  },
  zIndices: {
    content: 1,
    header: 100,
    modal: 200,
  },
} as const;

export type AppTheme = typeof theme;

export const GlobalStyle = createGlobalStyle`
  *, *::before, *::after {
    box-sizing: border-box;
  }

  :root {
    color-scheme: dark;
    --netflix-red: ${({ theme }) => theme.colors.accent};
    --text-primary: ${({ theme }) => theme.colors.text};
    --text-secondary: ${({ theme }) => theme.colors.textSecondary};
    --text-muted: ${({ theme }) => theme.colors.textMuted};
    --bg-card: ${({ theme }) => theme.colors.surface};
    --border: ${({ theme }) => theme.colors.border};
  }

  html {
    background: ${({ theme }) => theme.colors.background};
    color: ${({ theme }) => theme.colors.text};
    font-family: Inter, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
    scroll-behavior: smooth;
    -webkit-font-smoothing: antialiased;
  }

  body {
    min-width: 320px;
    min-height: 100vh;
    margin: 0;
    overflow-x: hidden;
    background: ${({ theme }) => theme.colors.background};
  }

  button, input {
    font: inherit;
  }

  button {
    border: 0;
  }

  button, [role="button"] {
    -webkit-tap-highlight-color: transparent;
  }

  :focus-visible {
    outline: 2px solid ${({ theme }) => theme.colors.accent};
    outline-offset: 3px;
  }

  ::selection {
    background: ${({ theme }) => theme.colors.accent};
    color: #fff;
  }

  ::-webkit-scrollbar {
    width: 0.375rem;
    height: 0.375rem;
  }

  ::-webkit-scrollbar-track {
    background: transparent;
  }

  ::-webkit-scrollbar-thumb {
    border-radius: ${({ theme }) => theme.radii.pill};
    background: rgba(255, 255, 255, 0.18);
  }

  @media (prefers-reduced-motion: reduce) {
    *, *::before, *::after {
      scroll-behavior: auto !important;
      animation-duration: 0.01ms !important;
      animation-iteration-count: 1 !important;
      transition-duration: 0.01ms !important;
    }
  }
`;
