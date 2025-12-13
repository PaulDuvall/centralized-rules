# Vercel Deployment Best Practices

> **When to apply:** All Vercel deployments
> **Maturity Level:** MVP to Production

Best practices for deploying applications on Vercel, including build configuration, deployment strategies, and production readiness checklist.

## Table of Contents

- [Build Configuration](#build-configuration)
- [Deployment Strategies](#deployment-strategies)
- [Production Checklist](#production-checklist)
- [Preview Deployments](#preview-deployments)
- [Rollback and Recovery](#rollback-and-recovery)

---

## Build Configuration

### Project Configuration

**vercel.json:**

```json
{
  "buildCommand": "npm run build",
  "devCommand": "npm run dev",
  "installCommand": "npm install",
  "framework": "nextjs",
  "outputDirectory": ".next",

  "build": {
    "env": {
      "NEXT_PUBLIC_API_URL": "@api-url",
      "DATABASE_URL": "@database-url"
    }
  },

  "headers": [
    {
      "source": "/(.*)",
      "headers": [
        {
          "key": "X-Content-Type-Options",
          "value": "nosniff"
        },
        {
          "key": "X-Frame-Options",
          "value": "DENY"
        },
        {
          "key": "X-XSS-Protection",
          "value": "1; mode=block"
        }
      ]
    }
  ],

  "redirects": [
    {
      "source": "/old-page",
      "destination": "/new-page",
      "permanent": true
    }
  ],

  "rewrites": [
    {
      "source": "/api/:path*",
      "destination": "https://api.example.com/:path*"
    }
  ]
}
```

### Environment-Specific Builds

```bash
# Development
vercel env pull .env.development.local

# Preview (staging)
vercel --env preview

# Production
vercel --prod
```

### Build Optimization

**next.config.js:**

```javascript
module.exports = {
  // Minimize bundle size
  swcMinify: true,

  // Image optimization
  images: {
    domains: ['cdn.example.com'],
    formats: ['image/avif', 'image/webp'],
  },

  // Reduce build output
  output: 'standalone',

  // Performance optimizations
  compiler: {
    removeConsole: process.env.NODE_ENV === 'production',
  },

  // Webpack optimizations
  webpack: (config, { isServer }) => {
    if (!isServer) {
      config.resolve.fallback = {
        fs: false,
        net: false,
        tls: false,
      };
    }
    return config;
  },
};
```

---

## Deployment Strategies

### Git-Based Deployments

**Automatic deployments from Git:**

- **Production:** Deploys from `main` branch
- **Preview:** Deploys from feature branches
- **Development:** Local with `vercel dev`

**Branch configuration:**

```json
{
  "git": {
    "deploymentEnabled": {
      "main": true,
      "staging": true,
      "*": false
    }
  }
}
```

### Manual Deployments

```bash
# Deploy to preview
vercel

# Deploy to production
vercel --prod

# Deploy specific directory
vercel ./dist --prod

# Deploy with build env
vercel --build-env DATABASE_URL=postgresql://...
```

### Deployment Protection

**Enable deployment protection for production:**

1. Vercel Dashboard → Settings → Deployment Protection
2. Enable "Vercel Authentication"
3. Add allowed email domains
4. Require authentication for production previews

---

## Production Checklist

### Pre-Launch Checklist

```markdown
## Domain and DNS
- [ ] Custom domain configured
- [ ] SSL certificate provisioned (automatic)
- [ ] DNS records verified
- [ ] www redirect configured

## Performance
- [ ] Image optimization enabled
- [ ] Font optimization configured
- [ ] Bundle size analyzed (< 200KB initial load)
- [ ] Core Web Vitals passing (Lighthouse score > 90)
- [ ] Edge caching configured

## Security
- [ ] Environment variables in Vercel dashboard (not in code)
- [ ] Security headers configured
- [ ] CORS policies defined
- [ ] Rate limiting implemented
- [ ] Input validation on all forms

## Monitoring
- [ ] Analytics enabled (Vercel Analytics or third-party)
- [ ] Error tracking configured (Sentry, etc.)
- [ ] Uptime monitoring setup
- [ ] Performance monitoring active
- [ ] Alerts configured

## Compliance
- [ ] Privacy policy published
- [ ] Cookie consent implemented (if required)
- [ ] GDPR compliance verified (if applicable)
- [ ] Terms of service published

## Testing
- [ ] E2E tests passing
- [ ] Lighthouse CI integrated
- [ ] Preview deployments tested
- [ ] Mobile responsiveness verified
- [ ] Cross-browser testing completed

## Backup and Recovery
- [ ] Database backups configured
- [ ] Deployment rollback tested
- [ ] Incident response plan documented
```

### Production Build Validation

```javascript
// scripts/validate-build.js

const fs = require('fs');
const path = require('path');

function validateBuild() {
  const buildDir = path.join(__dirname, '../.next');

  // Check build directory exists
  if (!fs.existsSync(buildDir)) {
    console.error('❌ Build directory not found');
    process.exit(1);
  }

  // Check bundle sizes
  const mainBundlePath = path.join(buildDir, 'static/chunks/main.js');
  if (fs.existsSync(mainBundlePath)) {
    const size = fs.statSync(mainBundlePath).size;
    const maxSize = 200 * 1024; // 200KB

    if (size > maxSize) {
      console.error(`❌ Main bundle too large: ${Math.round(size/1024)}KB (max ${Math.round(maxSize/1024)}KB)`);
      process.exit(1);
    }
  }

  // Check for required environment variables
  const required = ['NEXT_PUBLIC_API_URL', 'DATABASE_URL'];
  const missing = required.filter(key => !process.env[key]);

  if (missing.length > 0) {
    console.error(`❌ Missing environment variables: ${missing.join(', ')}`);
    process.exit(1);
  }

  console.log('✅ Build validation passed');
}

validateBuild();
```

---

## Preview Deployments

### Feature Branch Previews

**Automatic preview URLs:**

```
https://project-git-feature-branch-team.vercel.app
```

**Benefits:**
- Test features before merging
- Share with stakeholders
- Run E2E tests against preview
- Verify database migrations

### Preview Environment Configuration

```javascript
// lib/config.js

export function getConfig() {
  const isProduction = process.env.VERCEL_ENV === 'production';
  const isPreview = process.env.VERCEL_ENV === 'preview';

  return {
    apiUrl: isProduction
      ? 'https://api.example.com'
      : isPreview
      ? 'https://api-staging.example.com'
      : 'http://localhost:3001',

    enableAnalytics: isProduction,
    enableDebugMode: !isProduction,
  };
}
```

### Preview Deployment Comments

**Enable GitHub integration:**

Vercel automatically comments on PRs with:
- Preview URL
- Deployment status
- Build logs link
- Performance metrics

---

## Rollback and Recovery

### Rollback to Previous Deployment

**Via Dashboard:**
1. Go to Deployments
2. Find previous successful deployment
3. Click "Promote to Production"

**Via CLI:**

```bash
# List recent deployments
vercel ls

# Promote specific deployment
vercel promote [deployment-url]

# Or rollback via alias
vercel alias set [previous-deployment-url] production-domain.com
```

### Automated Rollback on Failure

**GitHub Actions:**

```yaml
name: Deploy with Auto-Rollback

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Deploy to Vercel
        id: deploy
        run: |
          URL=$(vercel --prod --token=${{ secrets.VERCEL_TOKEN }})
          echo "url=$URL" >> $GITHUB_OUTPUT

      - name: Health Check
        run: |
          sleep 30  # Wait for deployment
          STATUS=$(curl -o /dev/null -s -w "%{http_code}" ${{ steps.deploy.outputs.url }}/api/health)
          if [ $STATUS -ne 200 ]; then
            echo "Health check failed with status $STATUS"
            exit 1
          fi

      - name: Rollback on Failure
        if: failure()
        run: |
          PREV_URL=$(vercel ls --token=${{ secrets.VERCEL_TOKEN }} | grep READY | sed -n '2p' | awk '{print $1}')
          vercel promote $PREV_URL --token=${{ secrets.VERCEL_TOKEN }}
```

---

## Related Resources

- See `cloud/vercel/environment-configuration.md` for env setup
- See `cloud/vercel/performance-optimization.md` for performance
- See `cloud/vercel/security-practices.md` for security hardening
- See `base/cicd-comprehensive.md` for CI/CD patterns

---

**Remember:** Vercel's automatic deployments are powerful, but always validate builds, test preview deployments, and have a rollback plan ready for production.
