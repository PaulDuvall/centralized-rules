# Vercel Performance Optimization

> **When to apply:** All Vercel deployments
> **Maturity Level:** MVP to Production (increasing optimization at higher maturity)

Performance optimization strategies for Vercel including caching, Core Web Vitals, function optimization, and regional configuration.

## Core Web Vitals

### Target Metrics

- **LCP (Largest Contentful Paint):** < 2.5s
- **FID (First Input Delay):** < 100ms
- **CLS (Cumulative Layout Shift):** < 0.1

### Optimization Techniques

**Image Optimization:**

```jsx
import Image from 'next/image';

export function OptimizedImage() {
  return (
    <Image
      src="/hero.jpg"
      alt="Hero"
      width={1200}
      height={600}
      priority // Load above the fold images first
      placeholder="blur" // Show blur while loading
      sizes="(max-width: 768px) 100vw, 50vw"
    />
  );
}
```

**Font Optimization:**

```javascript
// next.config.js
module.exports = {
  optimizeFonts: true,
};
```

## Caching Strategy

### Edge Caching

```typescript
// app/api/data/route.ts

export async function GET() {
  const data = await fetchData();

  return Response.json(data, {
    headers: {
      'Cache-Control': 'public, s-maxage=3600, stale-while-revalidate=86400',
    },
  });
}
```

### ISR (Incremental Static Regeneration)

```typescript
// app/blog/[slug]/page.tsx

export const revalidate = 3600; // Revalidate every hour

export async function generateStaticParams() {
  const posts = await getPosts();
  return posts.map((post) => ({ slug: post.slug }));
}
```

## Function Optimization

### Edge Functions

```typescript
// middleware.ts (runs on Edge)

export function middleware(request: NextRequest) {
  // Fast, global execution
  const country = request.geo?.country || 'US';

  return NextResponse.rewrite(new URL(`/${country}`, request.url));
}
```

### Bundle Size Optimization

```javascript
// next.config.js
module.exports = {
  experimental: {
    optimizePackageImports: ['lodash', 'date-fns'],
  },
};
```

## Related Resources

- See `base/testing-philosophy.md` for performance testing
- See `cloud/vercel/deployment-best-practices.md` for builds
