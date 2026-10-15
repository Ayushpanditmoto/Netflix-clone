import type { Metadata } from 'next';
import './globals.css';
import Providers from '@/components/Providers';
import StyledComponentsRegistry from '@/lib/registry';

export const metadata: Metadata = {
  title: {
    default: 'Netflix Clone | Stream Movies & Series',
    template: '%s | Netflix Clone',
  },
  description:
    'Stream movies and TV series in a cinematic Netflix-style experience powered by TMDB metadata.',
  keywords: ['netflix', 'movies', 'series', 'streaming', 'TMDB'],
  icons: {
    icon: '/icon.svg',
    shortcut: '/icon.svg',
    apple: '/icon.svg',
  },
  openGraph: {
    title: 'Netflix Clone | Stream Movies & Series',
    description: 'Browse and watch trending movies and TV series.',
    type: 'website',
  },
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <head>
        <meta name="theme-color" content="#080808" />
      </head>
      <body>
        <StyledComponentsRegistry>
          <Providers>{children}</Providers>
        </StyledComponentsRegistry>
      </body>
    </html>
  );
}
