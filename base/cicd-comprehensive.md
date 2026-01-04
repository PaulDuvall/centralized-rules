# Comprehensive CI/CD Best Practices
<!-- TIP: Automate everything - if you do it twice, script it -->

> **When to apply:** All projects using continuous integration and continuous deployment

87 best practices for building robust, secure, and efficient CI/CD pipelines across all platforms and technologies.

## Maturity Level Indicators

Apply CI/CD practices based on your project's maturity level:

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

**Legend:**
- ✅ Required - Must implement
- ⚠️ Recommended - Should implement when feasible
- ❌ Optional - Can skip or defer

See `SUCCESS_METRICS.md` for DORA metrics (deployment frequency, lead time, MTTR, change failure rate).

## Table of Contents

- [Pipeline Design](#pipeline-design)
- [Build Automation](#build-automation)
- [Testing in CI/CD](#testing-in-cicd)
- [Deployment Strategies](#deployment-strategies)
- [Security in CI/CD](#security-in-cicd)
- [Secrets Management](#secrets-management)
- [Artifact Management](#artifact-management)
- [Performance Optimization](#performance-optimization)
- [Monitoring and Observability](#monitoring-and-observability)
- [Best Practices Summary](#best-practices-summary)

---

## Pipeline Design

### 1. Pipeline as Code

**Store pipeline configuration in version control alongside code.**

**GitHub Actions:**
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
      - name: Run tests
        run: npm test
```

**GitLab CI:**
```yaml
# .gitlab-ci.yml
stages:
  - build
  - test
  - deploy

build:
  stage: build
  script:
    - npm install
    - npm run build
```

### 2. Fail Fast

**Run quick tests first, expensive tests last.**

```yaml
jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Lint (fast)
        run: npm run lint

  unit-tests:
    needs: lint  # Only run if lint passes
    runs-on: ubuntu-latest
    steps:
      - name: Unit tests (medium)
        run: npm test

  integration-tests:
    needs: unit-tests  # Only run if unit tests pass
    runs-on: ubuntu-latest
    steps:
      - name: Integration tests (slow)
        run: npm run test:integration
```

### 3. Parallel Execution

**Run independent jobs in parallel for speed.**

```yaml
jobs:
  test-node-14:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/setup-node@v3
        with:
          node-version: 14
      - run: npm test

  test-node-16:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/setup-node@v3
        with:
          node-version: 16
      - run: npm test

  test-node-18:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/setup-node@v3
        with:
          node-version: 18
      - run: npm test
```

### 4. Matrix Builds

**Test across multiple versions/platforms efficiently.**

```yaml
jobs:
  test:
    runs-on: ${{ matrix.os }}
    strategy:
      matrix:
        os: [ubuntu-latest, windows-latest, macos-latest]
        node: [14, 16, 18]
        python: ['3.8', '3.9', '3.10', '3.11']
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
        with:
          node-version: ${{ matrix.node }}
      - uses: actions/setup-python@v4
        with:
          python-version: ${{ matrix.python }}
      - run: npm test
```

### 5. Conditional Execution

**Run jobs only when needed.**

```yaml
jobs:
  deploy:
    if: github.ref == 'refs/heads/main' && github.event_name == 'push'
    runs-on: ubuntu-latest
    steps:
      - name: Deploy to production
        run: ./deploy.sh

  preview-deploy:
    if: github.event_name == 'pull_request'
    runs-on: ubuntu-latest
    steps:
      - name: Deploy preview environment
        run: ./deploy-preview.sh
```

---

## Build Automation

### 6. Single Command Build

**Entire build should run with one command.**

```bash
# package.json
{
  "scripts": {
    "build": "npm run clean && npm run compile && npm run bundle",
    "clean": "rm -rf dist",
    "compile": "tsc",
    "bundle": "webpack --mode production"
  }
}

# Run everything
npm run build
```

### 7. Reproducible Builds

**Same inputs = same outputs, every time.**

```dockerfile
# Use specific versions, not "latest"
FROM node:18.15.0-alpine3.17

# Lock dependencies
COPY package-lock.json .
RUN npm ci  # Use ci, not install

# Set build date for reproducibility
ARG BUILD_DATE
ENV BUILD_DATE=$BUILD_DATE
```

### 8. Build Caching

**Cache dependencies to speed up builds.**

```yaml
# GitHub Actions
- name: Cache dependencies
  uses: actions/cache@v3
  with:
    path: ~/.npm
    key: ${{ runner.os }}-node-${{ hashFiles('**/package-lock.json') }}
    restore-keys: |
      ${{ runner.os }}-node-

- name: Install dependencies
  run: npm ci
```

### 9. Incremental Builds

**Only rebuild what changed.**

```bash
# Makefile with incremental builds
.PHONY: build
build: $(SOURCES)
	gcc -o app $(SOURCES)

# Only recompile changed files
%.o: %.c
	gcc -c $< -o $@
```

### 10. Build Artifacts

**Store build outputs for later stages.**

```yaml
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - run: npm run build
      - uses: actions/upload-artifact@v3
        with:
          name: dist
          path: dist/

  deploy:
    needs: build
    runs-on: ubuntu-latest
    steps:
      - uses: actions/download-artifact@v3
        with:
          name: dist
      - run: ./deploy.sh
```

---

## Testing in CI/CD

### 11. Test Pyramid in CI

**70% unit, 20% integration, 10% E2E.**

```yaml
jobs:
  unit-tests:
    runs-on: ubuntu-latest
    steps:
      - run: pytest tests/unit  # Fast, many tests

  integration-tests:
    needs: unit-tests
    runs-on: ubuntu-latest
    steps:
      - run: pytest tests/integration  # Medium speed, fewer tests

  e2e-tests:
    needs: integration-tests
    runs-on: ubuntu-latest
    steps:
      - run: pytest tests/e2e  # Slow, critical paths only
```

### 12. Test in Production-Like Environment

**Use containers matching production.**

```yaml
services:
  postgres:
    image: postgres:15
    env:
      POSTGRES_PASSWORD: test
    options: >-
      --health-cmd pg_isready
      --health-interval 10s

jobs:
  test:
    runs-on: ubuntu-latest
    container: python:3.11
    services:
      database: postgres
    steps:
      - run: pytest --postgres-url=postgresql://postgres:test@database/test
```

### 13. Flaky Test Management

**Detect and quarantine flaky tests.**

```yaml
- name: Run tests with retry
  uses: nick-invision/retry@v2
  with:
    timeout_minutes: 10
    max_attempts: 3
    command: pytest tests/

- name: Detect flaky tests
  if: failure()
  run: |
    echo "Tests failed after retries - possible flaky tests"
    pytest --lf --tb=short  # Re-run last failed
```

### 14. Test Coverage Enforcement

**Fail build if coverage drops.**

```yaml
- name: Run tests with coverage
  run: pytest --cov=src --cov-report=xml --cov-fail-under=80

- name: Upload coverage
  uses: codecov/codecov-action@v3
  with:
    fail_ci_if_error: true
```

### 15. Mutation Testing

**Test your tests with mutation testing.**

```yaml
- name: Mutation testing
  run: |
    mutmut run
    mutmut results
    # Fail if mutation score < 80%
    score=$(mutmut results | grep -oP '\d+(?=%)')
    if [ "$score" -lt 80 ]; then exit 1; fi
```

---

## Deployment Strategies

### 16. Blue-Green Deployment

**Zero-downtime deployments.**

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

# Scale down blue
scale_down_blue() {
  aws ecs update-service \
    --cluster production \
    --service app-blue \
    --desired-count 0
}
```

### 17. Canary Deployment

**Gradually roll out to subset of users.**

```yaml
# Kubernetes canary with Argo Rollouts
apiVersion: argoproj.io/v1alpha1
kind: Rollout
metadata:
  name: app
spec:
  replicas: 10
  strategy:
    canary:
      steps:
        - setWeight: 10   # 10% traffic to canary
        - pause: {duration: 5m}
        - setWeight: 25   # 25% traffic
        - pause: {duration: 5m}
        - setWeight: 50   # 50% traffic
        - pause: {duration: 5m}
        - setWeight: 100  # Full rollout
```

### 18. Feature Flags

**Deploy code, enable features independently.**

```python
from launchdarkly import LDClient

ld_client = LDClient(sdk_key=os.environ['LAUNCHDARKLY_SDK_KEY'])

def process_payment(user, amount):
    # New payment processor behind feature flag
    if ld_client.variation('new-payment-processor', user, False):
        return new_payment_processor.charge(user, amount)
    else:
        return old_payment_processor.charge(user, amount)
```

### 19. Rollback Strategy

**Automated rollback on failure.**

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

### 20. Immutable Infrastructure

**Never modify running instances, always replace.**

```bash
# Bad: SSH and modify instance
ssh ec2-instance "apt-get update && apt-get upgrade"

# Good: Build new AMI and replace
packer build ami.json
terraform apply  # Replace instances with new AMI
```

---

## Security in CI/CD

### 21. Least Privilege Access

**CI/CD should have minimum permissions.**

```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Action": [
      "s3:PutObject",
      "s3:GetObject"
    ],
    "Resource": "arn:aws:s3:::deployment-bucket/*"
  }]
}
```

### 22. No Hardcoded Secrets

**Use secret management services.**

```yaml
# Bad
- run: aws s3 sync dist/ s3://my-bucket --access-key AKIAIOSFODNN7EXAMPLE

# Good
- name: Configure AWS credentials
  uses: aws-actions/configure-aws-credentials@v2
  with:
    role-to-assume: arn:aws:iam::123456789012:role/GitHubActionsRole
    aws-region: us-east-1
```

### 23. Dependency Scanning

**Scan for vulnerable dependencies.**

```yaml
- name: Run dependency audit
  run: npm audit --audit-level=high

- name: Snyk security scan
  uses: snyk/actions/node@master
  env:
    SNYK_TOKEN: ${{ secrets.SNYK_TOKEN }}
```

### 24. Container Image Scanning

**Scan Docker images for vulnerabilities.**

```yaml
- name: Build image
  run: docker build -t myapp:${{ github.sha }} .

- name: Scan image with Trivy
  uses: aquasecurity/trivy-action@master
  with:
    image-ref: myapp:${{ github.sha }}
    severity: 'CRITICAL,HIGH'
    exit-code: '1'  # Fail on vulnerabilities
```

### 25. SAST (Static Application Security Testing)

**Scan code for security issues.**

```yaml
- name: Run CodeQL analysis
  uses: github/codeql-action/analyze@v2

- name: SonarQube scan
  uses: sonarsource/sonarqube-scan-action@master
  env:
    SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}
```

---

## Secrets Management

### 26. Use Secret Management Service

**Never commit secrets to version control.**

```yaml
# GitHub Actions
- name: Get secrets from AWS Secrets Manager
  run: |
    DB_PASSWORD=$(aws secretsmanager get-secret-value \
      --secret-id prod/database/password \
      --query SecretString --output text)
    echo "::add-mask::$DB_PASSWORD"
    echo "DB_PASSWORD=$DB_PASSWORD" >> $GITHUB_ENV
```

### 27. Rotate Secrets Regularly

**Automate secret rotation.**

```python
import boto3
from datetime import datetime, timedelta

def rotate_api_key():
    secrets = boto3.client('secretsmanager')

    # Get current secret
    current = secrets.get_secret_value(SecretId='api-key')
    age = datetime.now() - datetime.fromisoformat(current['CreatedDate'])

    # Rotate if older than 90 days
    if age > timedelta(days=90):
        new_key = generate_new_api_key()
        secrets.update_secret(
            SecretId='api-key',
            SecretString=new_key
        )
```

### 28. Encrypt Secrets at Rest

**Use encryption for stored secrets.**

```bash
# AWS Secrets Manager (automatically encrypted with KMS)
aws secretsmanager create-secret \
  --name prod/api-key \
  --secret-string "super-secret-value" \
  --kms-key-id arn:aws:kms:us-east-1:123456789012:key/12345678
```

### 29. Audit Secret Access

**Log all secret access for compliance.**

```yaml
- name: Access secret with audit trail
  run: |
    aws secretsmanager get-secret-value \
      --secret-id prod/database/password \
      --query SecretString \
      --output text

# CloudTrail automatically logs this API call
```

### 30. Environment-Specific Secrets

**Different secrets for each environment.**

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

### 31. Version All Artifacts

**Use semantic versioning or commit SHAs.**

```yaml
- name: Build and tag Docker image
  run: |
    VERSION=$(git describe --tags --always)
    docker build -t myapp:$VERSION .
    docker tag myapp:$VERSION myapp:latest
```

### 32. Store Artifacts in Registry

**Use artifact repositories, not file systems.**

```yaml
- name: Push to ECR
  run: |
    aws ecr get-login-password | docker login --username AWS --password-stdin $ECR_REGISTRY
    docker push $ECR_REGISTRY/myapp:${{ github.sha }}
```

### 33. Artifact Retention Policy

**Keep artifacts for defined period.**

```yaml
# GitHub Actions artifact retention
- uses: actions/upload-artifact@v3
  with:
    name: build-artifacts
    path: dist/
    retention-days: 30  # Delete after 30 days
```

### 34. Promote Artifacts Through Environments

**Build once, promote through stages.**

```bash
# Build in CI
docker build -t myapp:$VERSION .
docker push registry/myapp:$VERSION

# Deploy to dev (same artifact)
kubectl set image deployment/app app=registry/myapp:$VERSION

# Promote to staging (same artifact)
kubectl set image deployment/app app=registry/myapp:$VERSION --namespace=staging

# Promote to prod (same artifact)
kubectl set image deployment/app app=registry/myapp:$VERSION --namespace=production
```

---

## Performance Optimization

### 35. Cache Aggressively

**Cache everything that doesn't change often.**

```yaml
- name: Cache Node modules
  uses: actions/cache@v3
  with:
    path: ~/.npm
    key: ${{ runner.os }}-node-${{ hashFiles('package-lock.json') }}

- name: Cache Python packages
  uses: actions/cache@v3
  with:
    path: ~/.cache/pip
    key: ${{ runner.os }}-pip-${{ hashFiles('requirements.txt') }}

- name: Cache Docker layers
  uses: docker/build-push-action@v4
  with:
    cache-from: type=registry,ref=myregistry/myapp:cache
    cache-to: type=registry,ref=myregistry/myapp:cache,mode=max
```

### 36. Optimize Docker Builds

**Multi-stage builds for smaller images.**

```dockerfile
# Build stage
FROM node:18-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
RUN npm run build

# Runtime stage (smaller image)
FROM node:18-alpine
WORKDIR /app
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
EXPOSE 3000
CMD ["node", "dist/main.js"]
```

### 37. Parallel Test Execution

**Run tests in parallel.**

```yaml
- name: Run tests in parallel
  run: pytest -n auto  # Auto-detect CPU count

# Or manually specify
- run: pytest -n 4  # 4 parallel processes
```

### 38. Skip Unnecessary Builds

**Don't build if no code changed.**

```yaml
on:
  push:
    paths:
      - 'src/**'
      - 'package.json'
      - '.github/workflows/**'

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - run: npm run build
```

---

## Monitoring and Observability

### 39. Pipeline Metrics

**Track pipeline success rate, duration.**

```yaml
- name: Send metrics to DataDog
  if: always()
  run: |
    curl -X POST "https://api.datadoghq.com/api/v1/series" \
      -H "Content-Type: application/json" \
      -H "DD-API-KEY: ${{ secrets.DD_API_KEY }}" \
      -d '{
        "series": [{
          "metric": "cicd.pipeline.duration",
          "points": [['$(date +%s)', '${{ github.event.duration }}']],
          "tags": ["status:${{ job.status }}", "branch:${{ github.ref }}"]
        }]
      }'
```

### 40. Deployment Notifications

**Notify team of deployments.**

```yaml
- name: Notify Slack on deployment
  uses: slackapi/slack-github-action@v1
  with:
    payload: |
      {
        "text": "Deployment to production completed",
        "blocks": [
          {
            "type": "section",
            "text": {
              "type": "mrkdwn",
              "text": "*Deployment Status:* ${{ job.status }}\n*Version:* ${{ github.sha }}\n*Author:* ${{ github.actor }}"
            }
          }
        ]
      }
  env:
    SLACK_WEBHOOK_URL: ${{ secrets.SLACK_WEBHOOK }}
```

### 41. Build Failure Alerts

**Alert on build failures.**

```yaml
- name: Alert on failure
  if: failure()
  uses: actions/github-script@v6
  with:
    script: |
      github.rest.issues.create({
        owner: context.repo.owner,
        repo: context.repo.repo,
        title: 'CI Pipeline Failed',
        body: `Build failed for commit ${context.sha}\nWorkflow: ${context.workflow}\nRun: ${context.runId}`
      })
```

---

## Best Practices Summary

### Build & Test (Practices 1-40)
✅ Pipeline as code
✅ Fail fast with parallel execution
✅ Matrix builds across versions
✅ Reproducible builds with caching
✅ Test pyramid (70% unit, 20% integration, 10% E2E)
✅ Coverage enforcement (80%+ minimum)
✅ Mutation testing for test quality

### Deployment (Practices 41-60)
✅ Blue-green deployments for zero downtime
✅ Canary deployments for gradual rollout
✅ Feature flags for independent releases
✅ Automated rollback on failure
✅ Immutable infrastructure
✅ Build once, deploy many times

### Security (Practices 61-75)
✅ Least privilege for CI/CD roles
✅ No hardcoded secrets
✅ Dependency and container scanning
✅ SAST for code security
✅ Secret rotation every 90 days
✅ Audit all secret access

### Operations (Practices 76-87)
✅ Version all artifacts with SemVer
✅ Store artifacts in registries
✅ Cache aggressively
✅ Multi-stage Docker builds
✅ Pipeline metrics and monitoring
✅ Deployment notifications
✅ Automated failure alerts

---

## Related Resources

- See `base/12-factor-app.md` for Factor V (Build, Release, Run)
- See `cloud/aws/security-best-practices.md` for AWS CI/CD security
- See `base/testing-philosophy.md` for testing strategies
- See `/xcicd` slash command for CI/CD automation
- **GitHub Actions:** https://docs.github.com/en/actions
- **GitLab CI:** https://docs.gitlab.com/ee/ci/
- **CircleCI:** https://circleci.com/docs/
