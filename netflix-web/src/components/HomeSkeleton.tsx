'use client';

export default function HomeSkeleton() {
  return (
    <div aria-label="Loading…" aria-busy="true">
      {/* Hero skeleton */}
      <div className="shimmer skeleton-hero" />

      {/* Rail skeletons */}
      {Array.from({ length: 4 }).map((_, i) => (
        <div className="skeleton-rail" key={i}>
          {/* Title */}
          <div className="skeleton-rail-header">
            <div className="shimmer skeleton-heading" />
          </div>
          {/* Items */}
          <div className="rail-scroll skeleton-rail-scroll">
            {Array.from({ length: 7 }).map((_, j) => (
              <div
                key={j}
                className="shimmer skeleton-poster"
              />
            ))}
          </div>
        </div>
      ))}
    </div>
  );
}
