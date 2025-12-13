# Vercel Security Best Practices

> **When to apply:** All Vercel deployments
> **Maturity Level:** Pre-Production and Production

Security best practices for Vercel applications including deployment protection, headers, WAF, and access control.

## Security Headers

### Recommended Headers

```json
{
  "headers": [
    {
      "source": "/(.*)",
      "headers": [
        {
          "key": "X-DNS-Prefetch-Control",
          "value": "on"
        },
        {
          "key": "Strict-Transport-Security",
          "value": "max-age=63072000; includeSubDomains; preload"
        },
        {
          "key": "X-Frame-Options",
          "value": "SAMEORIGIN"
        },
        {
          "key": "X-Content-Type-Options",
          "value": "nosniff"
        },
        {
          "key": "X-XSS-Protection",
          "value": "1; mode=block"
        },
        {
          "key": "Referrer-Policy",
          "value": "origin-when-cross-origin"
        },
        {
          "key": "Content-Security-Policy",
          "value": "default-src 'self'; script-src 'self' 'unsafe-eval' 'unsafe-inline'; style-src 'self' 'unsafe-inline';"
        }
      ]
    }
  ]
}
```

## Authentication and Access Control

### Vercel Authentication

**Enable for production previews:**
- Vercel Dashboard → Settings → Deployment Protection
- Enable "Vercel Authentication"
- Add allowed email domains

### Middleware-Based Protection

```typescript
// middleware.ts

import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';

export function middleware(request: NextRequest) {
  // Check authentication
  const token = request.cookies.get('auth-token');

  if (!token) {
    return NextResponse.redirect(new URL('/login', request.url));
  }

  // Add security headers
  const response = NextResponse.next();
  response.headers.set('X-Frame-Options', 'DENY');

  return response;
}

export const config = {
  matcher: '/dashboard/:path*',
};
```

## Input Validation

```typescript
import { z } from 'zod';

const UserSchema = z.object({
  email: z.string().email(),
  age: z.number().min(0).max(150),
});

export async function POST(request: Request) {
  try {
    const body = await request.json();
    const validated = UserSchema.parse(body);

    // Safe to use validated data
    return Response.json({ success: true });
  } catch (error) {
    return Response.json({ error: 'Invalid input' }, { status: 400 });
  }
}
```

## Related Resources

- See `base/security-principles.md` for general security
- See `cloud/vercel/deployment-best-practices.md` for deployments
