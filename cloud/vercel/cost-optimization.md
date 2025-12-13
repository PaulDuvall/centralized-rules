# Vercel Cost Optimization

> **When to apply:** Pre-Production and Production
> **Maturity Level:** Awareness at all levels, Active optimization at Production

Cost optimization strategies for Vercel including usage management, spend alerts, and optimization techniques.

## Understanding Vercel Pricing

### Key Cost Drivers

1. **Bandwidth:** Data transfer out
2. **Function Execution:** Serverless function invocations and duration
3. **Edge Middleware:** Edge function executions
4. **Build Minutes:** CI/CD build time

## Cost Optimization Strategies

### Reduce Bandwidth

**Image Optimization:**

```typescript
// Use Next.js Image component (automatic optimization)
import Image from 'next/image';

<Image src="/large.jpg" width={800} height={600} quality={75} />
```

**Enable Compression:**

```javascript
// next.config.js
module.exports = {
  compress: true,
};
```

### Optimize Function Execution

**Edge Functions (cheaper than serverless):**

```typescript
// middleware.ts runs on Edge (cheaper)

export function middleware(request: NextRequest) {
  // Simple logic on Edge
  return NextResponse.next();
}
```

**Reduce Cold Starts:**

```typescript
// Keep functions warm with minimal code
export const config = {
  runtime: 'edge', // Faster, cheaper
};
```

### Optimize Builds

**Incremental Builds:**

```javascript
// Only rebuild what changed
module.exports = {
  experimental: {
    incrementalCacheHandlerPath: './cache-handler.js',
  },
};
```

**Cache Dependencies:**

```yaml
# .github/workflows/deploy.yml

- uses: actions/cache@v3
  with:
    path: ~/.npm
    key: ${{ runner.os }}-node-${{ hashFiles('**/package-lock.json') }}
```

## Spend Alerts

**Configure in Vercel Dashboard:**
1. Settings → Usage
2. Set spend limit
3. Configure email alerts
4. Review usage weekly

## Monitoring Costs

```bash
# Check current usage
vercel billing

# View detailed breakdown
vercel billing --json
```

## Related Resources

- See `cloud/vercel/performance-optimization.md` for performance
- See `base/metrics-standards.md` for cost metrics
