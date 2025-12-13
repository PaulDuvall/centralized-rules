# Vercel Reliability and Observability

> **When to apply:** Pre-Production and Production
> **Maturity Level:** Basic monitoring at Pre-Production, Full observability at Production

Monitoring, logging, alerting, and incident response for Vercel applications.

## Monitoring

### Vercel Analytics

```typescript
// app/layout.tsx

import { Analytics } from '@vercel/analytics/react';

export default function RootLayout({ children }) {
  return (
    <html>
      <body>
        {children}
        <Analytics />
      </body>
    </html>
  );
}
```

### Custom Metrics

```typescript
import { track } from '@vercel/analytics';

export function trackCheckout(amount: number) {
  track('checkout', {
    amount,
    currency: 'USD',
  });
}
```

## Logging

### Structured Logging

```typescript
export function logger(level: string, message: string, meta?: object) {
  console.log(
    JSON.stringify({
      level,
      message,
      timestamp: new Date().toISOString(),
      ...meta,
    })
  );
}

// Usage
logger('info', 'User logged in', { userId: '123' });
```

## Error Tracking

### Sentry Integration

```typescript
// sentry.client.config.ts

import * as Sentry from '@sentry/nextjs';

Sentry.init({
  dsn: process.env.NEXT_PUBLIC_SENTRY_DSN,
  environment: process.env.VERCEL_ENV,
  tracesSampleRate: 0.1,
});
```

## Alerting

### Vercel Monitoring

- Configure alerts in Vercel Dashboard
- Set thresholds for function errors
- Set thresholds for bandwidth usage

## Related Resources

- See `base/metrics-standards.md` for metrics patterns
- See `base/operations-automation.md` for incident response
