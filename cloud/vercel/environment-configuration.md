# Vercel Environment Configuration

> **When to apply:** All Vercel projects
> **Maturity Level:** All levels (essential from MVP onwards)

Best practices for managing environment variables, secrets, and environment-specific configuration on Vercel.

## Environment Variables

### Setting Environment Variables

**Via Vercel Dashboard:**
1. Project Settings → Environment Variables
2. Add key-value pairs
3. Select environments: Production, Preview, Development
4. Save changes

**Via CLI:**

```bash
# Add environment variable
vercel env add API_KEY

# Pull environment variables locally
vercel env pull .env.local

# List all environment variables
vercel env ls
```

### Environment Types

**Production:**
- Used for production deployments (`main` branch)
- Requires highest security
- No debug/development features

**Preview:**
- Used for pull request previews
- Can use staging/test credentials
- May include debug features

**Development:**
- Used locally with `vercel dev`
- Safe to include in `.env.local` (gitignored)

### Best Practices

```bash
# ✅ GOOD: Descriptive names, proper scoping

# Public (NEXT_PUBLIC_* exposed to browser)
NEXT_PUBLIC_API_URL=https://api.example.com
NEXT_PUBLIC_ANALYTICS_ID=UA-123456

# Private (server-side only)
DATABASE_URL=postgresql://user:pass@host:5432/db
API_SECRET_KEY=secret_key_here
STRIPE_SECRET_KEY=sk_live_...

# ❌ BAD: Generic names, unclear purpose
URL=https://something.com
KEY=abc123
SECRET=xyz789
```

## Secrets Management

### Sensitive Data

**Never commit secrets:**

```bash
# .gitignore
.env*.local
.env.production
secrets.json
```

**Use Vercel Environment Variables for:**
- API keys
- Database credentials
- OAuth secrets
- Third-party service tokens
- Encryption keys

### Accessing Secrets in Code

```typescript
// lib/config.ts

export const config = {
  // Public (browser-safe)
  publicApiUrl: process.env.NEXT_PUBLIC_API_URL,

  // Private (server-side only)
  databaseUrl: process.env.DATABASE_URL,
  apiSecret: process.env.API_SECRET_KEY,
  stripeKey: process.env.STRIPE_SECRET_KEY,
} as const;

// Validate required variables at build time
Object.entries(config).forEach(([key, value]) => {
  if (!value) {
    throw new Error(`Missing required environment variable: ${key}`);
  }
});
```

## Environment Separation

### Development

```bash
# .env.development.local
NEXT_PUBLIC_API_URL=http://localhost:3001
DATABASE_URL=postgresql://localhost:5432/dev_db
ENABLE_DEBUG=true
```

### Preview/Staging

**Vercel Dashboard:**
- Use separate staging database
- Use test API keys
- Enable feature flags for testing

### Production

**Vercel Dashboard:**
- Use production database (read replicas)
- Use live API keys
- Disable debug features
- Enable all monitoring

## Related Resources

- See `cloud/vercel/security-practices.md` for security
- See `cloud/vercel/deployment-best-practices.md` for deployments
- See `base/configuration-management.md` for config patterns
