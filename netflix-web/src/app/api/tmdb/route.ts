import { NextRequest, NextResponse } from 'next/server';

const TMDB_API_KEY =
  process.env.NEXT_PUBLIC_TMDB_API_KEY ?? '9e7096a7575623aa30c66e9cc987e411';
const TMDB_BASE = 'https://api.themoviedb.org/3';

export async function GET(req: NextRequest) {
  const { searchParams } = req.nextUrl;

  // The client passes `path` as a query param e.g. /api/tmdb?path=/trending/all/week&...
  const path = searchParams.get('path');
  if (!path) {
    return NextResponse.json({ error: 'Missing path' }, { status: 400 });
  }

  // Forward all other params to TMDB (query, language, page, etc.)
  const tmdbParams = new URLSearchParams();
  tmdbParams.set('api_key', TMDB_API_KEY);
  tmdbParams.set('language', 'en-US');
  searchParams.forEach((value, key) => {
    if (key !== 'path') tmdbParams.set(key, value);
  });

  const tmdbUrl = `${TMDB_BASE}${path}?${tmdbParams.toString()}`;

  try {
    const res = await fetch(tmdbUrl, {
      next: { revalidate: 300 },
      headers: { Accept: 'application/json' },
    });

    if (!res.ok) {
      return NextResponse.json(
        { error: `TMDB error ${res.status}` },
        { status: res.status }
      );
    }

    const data = await res.json();
    return NextResponse.json(data, {
      headers: {
        'Cache-Control': 'public, s-maxage=300, stale-while-revalidate=600',
      },
    });
  } catch (err) {
    console.error('TMDB proxy error:', err);
    return NextResponse.json({ error: 'Failed to fetch from TMDB' }, { status: 502 });
  }
}
