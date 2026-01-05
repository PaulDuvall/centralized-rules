# Comprehensive CI/CD Best Practices

> **When to apply:** All projects using continuous integration and continuous deployment

Implementation-ready practices for robust, secure, and efficient CI/CD pipelines.

## Maturity Level Requirements

| Practice | MVP/POC | Pre-Production | Production |
|----------|---------|----------------|------------|
| Automated builds | ⚠️ Recommended | ✅ Required | ✅ Required |
| Automated tests in CI | ⚠️ Recommended | ✅ Required | ✅ Required |
| Linting in CI | ❌ Optional | ⚠️ Recommended | ✅ Required |
| Security scanning | ❌ Optional | ⚠️ Recommended | ✅ Required |
| Build artifacts | ❌ Optional | ⚠️ Recommended | ✅ Required |
| Automated deployment | ❌ Not needed | ⚠️ Recommended | ✅ Required |
| Deployment approval gates | ❌ Not needed | ⚠️ Recommended | ✅ Required |
| Blue-green/canary deployment | ❌ Not needed | ❌ Optional | ⚠️ Recommended |
| Rollback automation | ❌ Not needed | ⚠️ Recommended | ✅ Required |
| Performance testing in CI | ❌ Not needed | ❌ Optional | ⚠️ Recommended |
| Pipeline monitoring | ❌ Optional | ⚠️ Recommended | ✅ Required |

**Legend:** ✅ Required | ⚠️ Recommended | ❌ Optional

See `SUCCESS_METRICS.md` for DORA metrics (deployment frequency, lead time, MTTR, change failure rate).

## Pipeline Design

### 1. Pipeline as Code

Store pipeline configuration in version control.

```yaml
# .github/workflows/ci.yml
name: CI Pipeline
on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - run: npm test
```

### 2. Fail Fast

Run quick tests first, expensive tests last.

```yaml
jobs:
  lint:
    steps:
      - run: npm run lint  # Fast

  unit-tests:
    needs: lint
    steps:
      - run: npm test  # Medium

  integration-tests:
    needs: unit-tests
    steps:
      - run: npm run test:integration  # Slow
```

### 3. Parallel Execution

```yaml
jobs:
  test:
    runs-on: ${{ matrix.os }}
    strategy:
      matrix:
        os: [ubuntu-latest, windows-latest, macos-latest]
        node: [14, 16, 18]
    steps:
      - uses: actions/setup-node@v3
        with:
          node-version: ${{ matrix.node }}
      - run: npm test
```

### 4. Conditional Execution

```yaml
jobs:
  deploy:
    if: github.ref == 'refs/heads/main'
    steps:
      - run: ./deploy.sh

  preview-deploy:
    if: github.event_name == 'pull_request'
    steps:
      - run: ./deploy-preview.sh
```

---

## Build Automation

### 5. Single Command Build

```json
{
  "scripts": {
    "build": "npm run clean && npm run compile && npm run bundle",
    "clean": "rm -rf dist",
    "compile": "tsc",
    "bundle": "webpack --mode production"
  }
}
```

### 6. Reproducible Builds

Same inputs = same outputs, every time.

```dockerfile
FROM node:18.15.0-alpine3.17  # Specific version, not "latest"
COPY package-lock.json .
RUN npm ci  # Use ci, not install
```

### 7. Build Caching

```yaml
- uses: actions/cache@v3
  with:
    path: ~/.npm
    key: ${{ runner.os }}-node-${{ hashFiles('**/package-lock.json') }}
- run: npm ci
```

### 8. Build Artifacts

```yaml
jobs:
  build:
    steps:
      - run: npm run build
      - uses: actions/upload-artifact@v3
        with:
          name: dist
          path: dist/

  deploy:
    needs: build
    steps:
      - uses: actions/download-artifact@v3
        with:
          name: dist
      - run: ./deploy.sh
```

---

## Testing in CI/CD

### 9. Test Pyramid: 70% Unit, 20% Integration, 10% E2E

```yaml
jobs:
  unit-tests:
    steps:
      - run: pytest tests/unit

  integration-tests:
    needs: unit-tests
    steps:
      - run: pytest tests/integration

  e2e-tests:
    needs: integration-tests
    steps:
      - run: pytest tests/e2e  # Critical paths only
```

### 10. Production-Like Environment

```yaml
services:
  postgres:
    image: postgres:15
    env:
      POSTGRES_PASSWORD: test

jobs:
  test:
    container: python:3.11
    services:
      database: postgres
    steps:
      - run: pytest --postgres-url=postgresql://postgres:test@database/test
```

### 11. Coverage Enforcement

```yaml
- run: pytest --cov=src --cov-report=xml --cov-fail-under=80
- uses: codecov/codecov-action@v3
  with:
    fail_ci_if_error: true
```

---

## Deployment Strategies

| Strategy | Use Case | Downtime | Rollback Speed | Cost |
|----------|----------|----------|----------------|------|
| Blue-Green | Zero-downtime required | None | Instant | 2x infrastructure |
| Canary | Risk mitigation | None | Fast | 1.1-1.5x infrastructure |
| Rolling | Standard deployments | Brief | Medium | 1x infrastructure |
| Recreate | Non-critical apps | Yes | Slow | 1x infrastructure |

### 12. Blue-Green Deployment

Zero-downtime deployments.

```bash
# Deploy to green environment
deploy_to_green() {
  aws ecs update-service \
    --cluster production \
    --service app-green \
    --desired-count 3
}

# Switch traffic
switch_traffic() {
  aws elbv2 modify-listener \
    --listener-arn $LISTENER_ARN \
    --default-actions TargetGroupArn=$GREEN_TG_ARN
}
```

### 13. Canary Deployment

Gradually roll out to subset of users.

```yaml
# Kubernetes canary with Argo Rollouts
apiVersion: argoproj.io/v1alpha1
kind: Rollout
spec:
  replicas: 10
  strategy:
    canary:
      steps:
        - setWeight: 10
        - pause: {duration: 5m}
        - setWeight: 50
        - pause: {duration: 5m}
        - setWeight: 100
```

### 14. Automated Rollback

```yaml
- name: Deploy new version
  id: deploy
  run: ./deploy.sh v${{ github.run_number }}

- name: Run smoke tests
  id: smoke
  run: ./smoke-tests.sh
  continue-on-error: true

- name: Rollback on failure
  if: steps.smoke.outcome == 'failure'
  run: ./rollback.sh
```

### 15. Immutable Infrastructure

Never modify running instances, always replace.

```bash
# Bad: SSH and modify
ssh ec2-instance "apt-get update"

# Good: Build new AMI and replace
packer build ami.json
terraform apply
```

---

## Security in CI/CD

### 16. Least Privilege Access

```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Action": ["s3:PutObject", "s3:GetObject"],
    "Resource": "arn:aws:s3:::deployment-bucket/*"
  }]
}
```

### 17. No Hardcoded Secrets

```yaml
- uses: aws-actions/configure-aws-credentials@v2
  with:
    role-to-assume: arn:aws:iam::123456789012:role/GitHubActionsRole
    aws-region: us-east-1
```

### 18. Dependency Scanning

```yaml
- run: npm audit --audit-level=high
- uses: snyk/actions/node@master
  env:
    SNYK_TOKEN: ${{ secrets.SNYK_TOKEN }}
```

### 19. Container Image Scanning

```yaml
- run: docker build -t myapp:${{ github.sha }} .
- uses: aquasecurity/trivy-action@master
  with:
    image-ref: myapp:${{ github.sha }}
    severity: 'CRITICAL,HIGH'
    exit-code: '1'
```

### 20. SAST (Static Application Security Testing)

```yaml
- uses: github/codeql-action/analyze@v2
- uses: sonarsource/sonarqube-scan-action@master
  env:
    SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}
```

---

## Secrets Management

### 21. Use Secret Management Service

```yaml
- run: |
    DB_PASSWORD=$(aws secretsmanager get-secret-value \
      --secret-id prod/database/password \
      --query SecretString --output text)
    echo "::add-mask::$DB_PASSWORD"
    echo "DB_PASSWORD=$DB_PASSWORD" >> $GITHUB_ENV
```

### 22. Encrypt Secrets at Rest

```bash
aws secretsmanager create-secret \
  --name prod/api-key \
  --secret-string "super-secret-value" \
  --kms-key-id arn:aws:kms:us-east-1:123456789012:key/12345678
```

### 23. Environment-Specific Secrets

```yaml
jobs:
  deploy-dev:
    environment: development
    steps:
      - uses: aws-actions/configure-aws-credentials@v2
        with:
          role-to-assume: ${{ secrets.DEV_AWS_ROLE }}

  deploy-prod:
    environment: production
    steps:
      - uses: aws-actions/configure-aws-credentials@v2
        with:
          role-to-assume: ${{ secrets.PROD_AWS_ROLE }}
```

---

## Artifact Management

### 24. Version All Artifacts

```yaml
- run: |
    VERSION=$(git describe --tags --always)
    docker build -t myapp:$VERSION .
    docker tag myapp:$VERSION myapp:latest
```

### 25. Artifact Retention

```yaml
- uses: actions/upload-artifact@v3
  with:
    name: build-artifacts
    path: dist/
    retention-days: 30
```

### 26. Promote Artifacts Through Environments

Build once, promote through stages.

```bash
# Build in CI
docker build -t myapp:$VERSION .
docker push registry/myapp:$VERSION

# Deploy to dev (same artifact)
kubectl set image deployment/app app=registry/myapp:$VERSION

# Promote to prod (same artifact)
kubectl set image deployment/app app=registry/myapp:$VERSION -n production
```

---

## Performance Optimization

### 27. Multi-Stage Docker Builds

```dockerfile
# Build stage
FROM node:18-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
RUN npm run build

# Runtime stage (smaller)
FROM node:18-alpine
WORKDIR /app
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
CMD ["node", "dist/main.js"]
```

### 28. Parallel Test Execution

```yaml
- run: pytest -n auto  # Auto-detect CPU count
```

### 29. Skip Unnecessary Builds

```yaml
on:
  push:
    paths:
      - 'src/**'
      - 'package.json'
      - '.github/workflows/**'
```

---

## Monitoring and Observability

### 30. Pipeline Metrics

```yaml
- name: Send metrics
  if: always()
  run: |
    curl -X POST "https://api.datadoghq.com/api/v1/series" \
      -H "DD-API-KEY: ${{ secrets.DD_API_KEY }}" \
      -d '{
        "series": [{
          "metric": "cicd.pipeline.duration",
          "points": [["$(date +%s)", "${{ github.event.duration }}"]],
          "tags": ["status:${{ job.status }}"]
        }]
      }'
```

### 31. Deployment Notifications

```yaml
- uses: slackapi/slack-github-action@v1
  with:
    payload: |
      {
        "text": "Deployment to production completed",
        "blocks": [{
          "type": "section",
          "text": {
            "type": "mrkdwn",
            "text": "*Status:* ${{ job.status }}\n*Version:* ${{ github.sha }}"
          }
        }]
      }
  env:
    SLACK_WEBHOOK_URL: ${{ secrets.SLACK_WEBHOOK }}
```

---

## Best Practices Summary

### Build & Test
- Pipeline as code in version control
- Fail fast with parallel execution
- Matrix builds across OS/versions
- Reproducible builds with caching
- Test pyramid: 70% unit, 20% integration, 10% E2E
- Coverage enforcement (80%+ minimum)

### Deployment
- Blue-green for zero downtime
- Canary for gradual rollout
- Automated rollback on failure
- Immutable infrastructure
- Build once, deploy many times

### Security
- Least privilege for CI/CD roles
- No hardcoded secrets
- Dependency and container scanning
- SAST for code security
- Secret rotation every 90 days

### Operations
- Version all artifacts with SemVer
- Cache aggressively
- Multi-stage Docker builds
- Pipeline metrics and monitoring
- Deployment notifications

---

## Related Resources

- `base/12-factor-app.md` - Factor V (Build, Release, Run)
- `cloud/aws/security-best-practices.md` - AWS CI/CD security
- `base/testing-philosophy.md` - Testing strategies
- `/xcicd` - CI/CD automation command
