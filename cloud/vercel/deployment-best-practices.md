# Vercel Deployment Best Practices

> **When to apply:** All projects deploying to Vercel platform
> **Platform:** Vercel (Next.js, React, Vue, Svelte, etc.)
> **Focus:** Build configuration, deployment workflows, production readiness

Best practices for deploying applications to Vercel with optimal configuration, CI/CD integration, and production-grade deployment strategies.

## Project Configuration (vercel.json)

### Basic Configuration

\`\`\`json
{
  "buildCommand": "npm run build",
  "devCommand": "npm run dev",
  "installCommand": "npm install",
  "outputDirectory": "dist"
}
\`\`\`

### Environment-Specific Settings

\`\`\`json
{
  "env": {
    "API_URL": "@api_url_production"
  },
  "build": {
    "env": {
      "NODE_ENV": "production"
    }
  }
}
\`\`\`

See full file at: https://vercel.com/docs/project-configuration

## CI/CD Integration with GitHub Actions

### Preview Deployments Workflow

\`\`\`yaml
name: Vercel Preview
on: pull_request

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: npm ci
      - run: npm test
      - run: npx vercel build --token=\${{ secrets.VERCEL_TOKEN }}
      - run: npx vercel deploy --prebuilt --token=\${{ secrets.VERCEL_TOKEN }}
\`\`\`

## Production Checklist

- ✅ Enable Web Application Firewall (WAF)
- ✅ Configure function memory and duration limits
- ✅ Set up Rolling Releases for gradual rollouts
- ✅ Configure environment variables securely
- ✅ Enable preview deployments for all PRs
- ✅ Set up automatic deployments from git

## References

- **Vercel Docs:** https://vercel.com/docs
- **Build Config:** https://vercel.com/docs/builds/configure-a-build
- **GitHub Actions:** https://vercel.com/kb/guide/how-can-i-use-github-actions-with-vercel
- **Production Checklist:** https://vercel.com/docs/production-checklist
