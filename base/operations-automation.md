# Operations Automation

> **When to apply:** Pre-Production and Production systems
> **Maturity Level:** Basic automation at Pre-Production, Full automation at Production

Automate operations tasks to reduce toil, improve reliability, and enable self-service.

## Key Areas

- Infrastructure provisioning and management
- Application deployment and rollback
- Incident response and recovery
- Monitoring and alerting
- Backup and disaster recovery
- Security patching and updates

## Infrastructure as Code

### Principles

**1. Everything as Code**
- Define all infrastructure in version-controlled code
- Use Terraform, CloudFormation, or similar tools
- Tag resources with `ManagedBy` metadata

**2. Version Control Everything**
- Store infrastructure code in git
- Organize by environments (dev, staging, production)
- Use modules for reusable components

**3. Immutable Infrastructure**
- Build once, deploy everywhere
- Same Docker image across all environments
- Configuration via environment variables

### Terraform Workflow

```bash
# 1. Plan changes (dry run)
terraform plan -out=tfplan

# 2. Review changes carefully

# 3. Apply changes
terraform apply tfplan

# 4. Verify
terraform show
```

### State Management

- Store state remotely (S3, Azure Blob)
- Enable locking to prevent concurrent modifications
- Version state for rollback capability

## Deployment Automation

### Continuous Deployment Pipeline

Automate: Test → Build → Deploy → Verify

```yaml
# .github/workflows/deploy.yml
name: Deploy to Production
on:
  push:
    branches: [main]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - run: npm test
  build:
    needs: test
    steps:
      - run: docker build -t app:${{ github.sha }} .
      - run: docker push app:${{ github.sha }}
  deploy:
    needs: build
    steps:
      - run: aws ecs update-service --cluster production --service web-app --force-new-deployment
      - run: aws ecs wait services-stable --cluster production --services web-app
      - run: curl -f https://api.example.com/health || exit 1
```

### Deployment Strategies

**Blue-Green:**
1. Deploy new version to inactive environment
2. Run health checks
3. Switch traffic to new environment
4. Keep old environment for quick rollback

**Canary:**
1. Deploy new version
2. Route 5% traffic, monitor
3. Gradually increase: 5% → 25% → 50% → 100%
4. Rollback if error rate or latency exceeds threshold

### Automated Rollback

Always have automated rollback on failure:
- Save previous version before deployment
- Monitor key metrics (error rate, latency)
- Auto-rollback if thresholds exceeded
- Alert team on rollback

## Operational Runbooks

### Runbook Structure

```markdown
# Runbook: [Problem]

## Symptoms
- List observable symptoms

## Impact
- User impact, severity level

## Diagnosis
- Commands to identify root cause

## Mitigation
- Steps to resolve immediately

## Prevention
- Long-term fixes
```

### Automated Runbooks

Codify runbooks as executable scripts:
- Define steps with rollback actions
- Execute with timeout limits
- Auto-rollback on failure
- Log all actions for audit

## Self-Service Operations

### Developer CLI Tools

Provide CLI for common operations:

```bash
company-cli deploy staging
company-cli logs api-server
company-cli scale api-server 5
company-cli status
```

**Benefits:**
- Developers self-serve
- Consistent operations
- Audit trail
- Permission-based access

## Monitoring and Alerting Automation

### Automated Alert Response

For routine alerts, automate remediation:

**Auto-remediate:**
- High memory usage → Restart pod
- Disk space critical → Cleanup logs
- Connection pool exhausted → Increase pool size

**Human escalation:**
- Critical alerts with no known fix
- Auto-remediation failed
- Complex incidents requiring judgment

## Anti-Patterns

### ❌ Manual Deployments
- Inconsistent, error-prone, slow
- **Solution:** Automate with CI/CD

### ❌ Snowflake Servers
- Each server configured differently
- **Solution:** Immutable infrastructure, identical servers

### ❌ No Rollback Plan
- Deployment fails, no way to revert
- **Solution:** Always have rollback mechanism
