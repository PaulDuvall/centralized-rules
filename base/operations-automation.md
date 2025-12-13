# Operations Automation

> **When to apply:** Pre-Production and Production systems
> **Maturity Level:** Basic automation at Pre-Production, Full automation at Production

Automate operations tasks to reduce toil, improve reliability, and enable self-service through Infrastructure as Code, deployment automation, and operational runbooks.

## Table of Contents

- [Overview](#overview)
- [Infrastructure as Code](#infrastructure-as-code)
- [Deployment Automation](#deployment-automation)
- [Operational Runbooks](#operational-runbooks)
- [Self-Service Operations](#self-service-operations)
- [Monitoring and Alerting Automation](#monitoring-and-alerting-automation)
- [Anti-Patterns](#anti-patterns)

---

## Overview

### What is Operations Automation?

**Definition:** Automating repetitive operational tasks through code, scripts, and tooling to reduce manual effort, errors, and response time.

**Key Areas:**
- Infrastructure provisioning and management
- Application deployment and rollback
- Incident response and recovery
- Monitoring and alerting
- Backup and disaster recovery
- Security patching and updates

### Benefits

**Reliability:**
- Consistent execution (no human error)
- Repeatable processes
- Faster recovery from failures

**Efficiency:**
- Reduced manual toil
- Faster deployments
- Self-service capabilities

**Scale:**
- Manage many systems with small team
- Handle growth without linear headcount increase

---

## Infrastructure as Code

### Principles

**1. Everything as Code**

```hcl
# ✅ Infrastructure defined in code (Terraform)

resource "aws_instance" "web_server" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t3.medium"

  tags = {
    Name        = "web-server-${var.environment}"
    Environment = var.environment
    ManagedBy   = "terraform"
  }

  vpc_security_group_ids = [aws_security_group.web.id]

  user_data = templatefile("${path.module}/user-data.sh", {
    app_version = var.app_version
  })
}

resource "aws_security_group" "web" {
  name        = "web-server-sg"
  description = "Security group for web servers"

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
```

**2. Version Control Everything**

```bash
infrastructure/
├── terraform/
│   ├── modules/
│   │   ├── vpc/
│   │   ├── ecs/
│   │   └── rds/
│   ├── environments/
│   │   ├── dev/
│   │   ├── staging/
│   │   └── production/
│   └── main.tf
├── ansible/
│   └── playbooks/
└── kubernetes/
    └── manifests/
```

**3. Immutable Infrastructure**

```dockerfile
# Build once, deploy everywhere

FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

# Immutable: Same image used in dev, staging, production
# Configuration via environment variables
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
```

### Infrastructure Management

**Terraform Workflow:**

```bash
# 1. Plan changes (dry run)
terraform plan -out=tfplan

# 2. Review changes
# Terraform will create the following resources:
#   + aws_instance.web_server
#   + aws_security_group.web
#   ~ aws_rds_instance.main (update in-place)

# 3. Apply changes
terraform apply tfplan

# 4. Verify
terraform show
```

**State Management:**

```hcl
# terraform/backend.tf

terraform {
  backend "s3" {
    bucket         = "company-terraform-state"
    key            = "production/infrastructure.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-lock"
  }
}

# Benefits:
# - Shared state across team
# - Locking prevents concurrent modifications
# - Versioned state for rollback
```

---

## Deployment Automation

### Continuous Deployment Pipeline

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
      - name: Run tests
        run: npm test

  build:
    needs: test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Build Docker image
        run: |
          docker build -t app:${{ github.sha }} .
          docker tag app:${{ github.sha }} app:latest

      - name: Push to registry
        run: |
          echo ${{ secrets.DOCKER_PASSWORD }} | docker login -u ${{ secrets.DOCKER_USERNAME }} --password-stdin
          docker push app:${{ github.sha }}
          docker push app:latest

  deploy:
    needs: build
    runs-on: ubuntu-latest
    steps:
      - name: Deploy to ECS
        run: |
          aws ecs update-service \
            --cluster production \
            --service web-app \
            --force-new-deployment

      - name: Wait for deployment
        run: |
          aws ecs wait services-stable \
            --cluster production \
            --services web-app

      - name: Verify health
        run: |
          curl -f https://api.example.com/health || exit 1
```

### Deployment Strategies

**Blue-Green Deployment:**

```python
# deployment_manager.py

from dataclasses import dataclass
from typing import Literal

@dataclass
class Deployment:
    environment: Literal["blue", "green"]
    version: str
    healthy: bool
    traffic_weight: float  # 0.0 to 1.0

def blue_green_deploy(new_version: str):
    """
    Blue-Green deployment strategy

    1. Deploy new version to inactive environment
    2. Run health checks
    3. Switch traffic to new environment
    4. Keep old environment for quick rollback
    """

    # Current state
    blue = get_deployment("blue")
    green = get_deployment("green")

    # Determine which is active
    active = blue if blue.traffic_weight > 0 else green
    inactive = green if active == blue else blue

    # Deploy to inactive environment
    print(f"Deploying {new_version} to {inactive.environment}")
    deploy_to_environment(inactive.environment, new_version)

    # Health check
    if not health_check(inactive.environment):
        print("❌ Health check failed! Aborting deployment.")
        return False

    # Smoke tests
    if not run_smoke_tests(inactive.environment):
        print("❌ Smoke tests failed! Aborting deployment.")
        return False

    # Switch traffic
    print(f"Switching traffic to {inactive.environment}")
    set_traffic_weight(inactive.environment, 1.0)
    set_traffic_weight(active.environment, 0.0)

    print(f"✅ Deployment complete. {active.environment} kept for rollback.")
    return True

def rollback():
    """Instant rollback by switching traffic back"""
    blue = get_deployment("blue")
    green = get_deployment("green")

    # Switch to whichever has 0 traffic (the previous version)
    if blue.traffic_weight == 0:
        set_traffic_weight("blue", 1.0)
        set_traffic_weight("green", 0.0)
    else:
        set_traffic_weight("green", 1.0)
        set_traffic_weight("blue", 0.0)

    print("✅ Rolled back to previous version")
```

**Canary Deployment:**

```python
def canary_deploy(new_version: str):
    """
    Gradually shift traffic to new version

    1. Deploy new version
    2. Route 5% traffic to new version
    3. Monitor metrics
    4. Gradually increase to 100% or rollback
    """

    # Deploy new version
    deploy_version(new_version)

    # Progressive rollout
    canary_stages = [
        (5, 300),    # 5% for 5 minutes
        (25, 300),   # 25% for 5 minutes
        (50, 600),   # 50% for 10 minutes
        (100, 0),    # 100%
    ]

    for percentage, duration_seconds in canary_stages:
        print(f"Routing {percentage}% traffic to {new_version}")
        set_traffic_split(new_version, percentage / 100.0)

        # Monitor during canary period
        time.sleep(duration_seconds)
        metrics = get_canary_metrics(new_version)

        # Check for issues
        if metrics.error_rate > 1.0 or metrics.p95_latency > 500:
            print(f"❌ Canary failed! Error rate: {metrics.error_rate}%, Latency: {metrics.p95_latency}ms")
            rollback_to_previous_version()
            return False

    print(f"✅ Canary deployment successful")
    return True
```

### Automated Rollback

```python
# Auto-rollback on deployment failure

def deploy_with_auto_rollback(version: str):
    """Deploy with automatic rollback on failure"""

    # Save current version for rollback
    previous_version = get_current_version()

    try:
        # Deploy new version
        deploy_version(version)

        # Wait for rollout
        wait_for_rollout(timeout=300)

        # Health checks
        if not health_check():
            raise DeploymentError("Health check failed")

        # Monitor for 5 minutes
        for i in range(30):  # 30 x 10s = 5 min
            metrics = get_metrics()

            if metrics.error_rate > ACCEPTABLE_ERROR_RATE:
                raise DeploymentError(f"Error rate too high: {metrics.error_rate}%")

            if metrics.p95_latency > ACCEPTABLE_LATENCY:
                raise DeploymentError(f"Latency too high: {metrics.p95_latency}ms")

            time.sleep(10)

        print(f"✅ Deployment successful: {version}")
        return True

    except DeploymentError as e:
        print(f"❌ Deployment failed: {e}")
        print(f"🔄 Rolling back to {previous_version}")

        deploy_version(previous_version)
        wait_for_rollout(timeout=300)

        print(f"✅ Rollback complete")

        # Alert team
        send_alert(f"Deployment of {version} failed and was rolled back")

        return False
```

---

## Operational Runbooks

### What are Runbooks?

**Definition:** Step-by-step procedures for operational tasks, codified for automation where possible.

**Types:**
- Incident response (troubleshooting, mitigation)
- Routine maintenance (backups, updates)
- Deployment procedures
- Disaster recovery

### Runbook Structure

```markdown
# Runbook: High API Error Rate

## Symptoms
- Error rate > 1%
- Increased 5xx responses
- Customer reports of failures

## Impact
- User experience degraded
- Revenue impact if prolonged
- Severity: P1 (Critical)

## Diagnosis

### 1. Check Error Logs
```bash
# Get error summary
kubectl logs -l app=api-server --tail=1000 | grep ERROR | sort | uniq -c | sort -rn
```

### 2. Check Dependencies
```bash
# Database connectivity
pg_isready -h db.example.com

# Redis connectivity
redis-cli -h cache.example.com ping

# External API status
curl -I https://partner-api.example.com/health
```

### 3. Check Resources
```bash
# CPU and memory
kubectl top pods -l app=api-server

# Disk space
df -h
```

## Mitigation

### If Database is Down
```bash
# Promote read replica
aws rds promote-read-replica --db-instance-identifier replica-1
```

### If API Servers are Overloaded
```bash
# Scale up
kubectl scale deployment api-server --replicas=10
```

### If External Dependency is Down
```bash
# Enable circuit breaker
kubectl set env deployment/api-server ENABLE_CIRCUIT_BREAKER=true
```

## Resolution

Once mitigated, investigate root cause:
1. Review deployment history
2. Check for recent configuration changes
3. Analyze error patterns
4. Create post-incident report

## Prevention

- Add monitoring for dependency health
- Implement circuit breakers
- Set up auto-scaling policies
- Regular disaster recovery drills
```

### Automated Runbooks

```python
# runbook_automation.py

from dataclasses import dataclass
from typing import Callable, List

@dataclass
class RunbookStep:
    """Single step in automated runbook"""
    name: str
    action: Callable
    rollback: Callable = None
    timeout_seconds: int = 300

@dataclass
class Runbook:
    """Automated operational runbook"""
    name: str
    description: str
    steps: List[RunbookStep]

# Example: Database failover runbook
database_failover_runbook = Runbook(
    name="Database Failover to Replica",
    description="Automated failover when primary database is unhealthy",
    steps=[
        RunbookStep(
            name="Verify primary is down",
            action=lambda: check_database_health("primary"),
            timeout_seconds=30
        ),
        RunbookStep(
            name="Verify replica is healthy",
            action=lambda: check_database_health("replica"),
            timeout_seconds=30
        ),
        RunbookStep(
            name="Promote replica to primary",
            action=lambda: promote_replica("replica-1"),
            rollback=lambda: demote_replica("replica-1"),
            timeout_seconds=180
        ),
        RunbookStep(
            name="Update DNS to point to new primary",
            action=lambda: update_dns_record("db.example.com", get_replica_ip()),
            rollback=lambda: update_dns_record("db.example.com", get_primary_ip()),
            timeout_seconds=60
        ),
        RunbookStep(
            name="Restart application servers",
            action=lambda: restart_app_servers(),
            timeout_seconds=300
        ),
        RunbookStep(
            name="Verify application health",
            action=lambda: check_app_health(),
            timeout_seconds=120
        ),
    ]
)

def execute_runbook(runbook: Runbook):
    """Execute runbook with error handling and rollback"""

    completed_steps = []

    try:
        for step in runbook.steps:
            print(f"Executing: {step.name}")

            # Execute step with timeout
            result = run_with_timeout(step.action, step.timeout_seconds)

            if not result:
                raise RunbookError(f"Step failed: {step.name}")

            completed_steps.append(step)
            print(f"✅ {step.name}")

        print(f"✅ Runbook complete: {runbook.name}")
        return True

    except Exception as e:
        print(f"❌ Runbook failed: {e}")

        # Rollback completed steps in reverse order
        for step in reversed(completed_steps):
            if step.rollback:
                print(f"Rolling back: {step.name}")
                step.rollback()

        return False
```

---

## Self-Service Operations

### Developer Self-Service Tools

```python
# cli.py - Internal developer CLI tool

import click

@click.group()
def cli():
    """Company DevOps CLI - Self-service operations"""
    pass

@cli.command()
@click.argument('environment', type=click.Choice(['dev', 'staging', 'production']))
def deploy(environment):
    """Deploy application to environment"""

    # Validate permissions
    if environment == 'production' and not has_permission('deploy:production'):
        click.echo("❌ You don't have permission to deploy to production")
        return

    click.echo(f"Deploying to {environment}...")

    # Trigger deployment pipeline
    trigger_deployment(environment)

    click.echo(f"✅ Deployment triggered. Monitor at: https://dashboard.example.com")

@cli.command()
@click.argument('service')
def logs(service):
    """Tail logs for a service"""

    click.echo(f"Tailing logs for {service}...")
    stream_logs(service)

@cli.command()
@click.argument('service')
@click.argument('replicas', type=int)
def scale(service, replicas):
    """Scale service to N replicas"""

    if replicas > 20:
        click.confirm(f"Scaling to {replicas} replicas. Are you sure?", abort=True)

    click.echo(f"Scaling {service} to {replicas} replicas...")
    scale_service(service, replicas)
    click.echo("✅ Scaled")

@cli.command()
def status():
    """Show status of all services"""

    services = get_all_services()

    for service in services:
        status_icon = "✅" if service.healthy else "❌"
        click.echo(f"{status_icon} {service.name}: {service.replicas} replicas, {service.cpu_usage}% CPU")

if __name__ == '__main__':
    cli()
```

**Usage:**

```bash
# Deploy to staging
company-cli deploy staging

# View logs
company-cli logs api-server

# Scale service
company-cli scale api-server 5

# Check status
company-cli status
```

---

## Monitoring and Alerting Automation

### Automated Alert Response

```python
# alert_responder.py

from dataclasses import dataclass
from typing import Callable

@dataclass
class AlertRule:
    """Automated response to alert"""
    alert_name: str
    severity: str
    auto_remediate: bool
    remediation_action: Callable

alert_rules = [
    AlertRule(
        alert_name="HighMemoryUsage",
        severity="warning",
        auto_remediate=True,
        remediation_action=lambda: restart_pod_with_high_memory()
    ),
    AlertRule(
        alert_name="DiskSpaceCritical",
        severity="critical",
        auto_remediate=True,
        remediation_action=lambda: cleanup_old_logs()
    ),
    AlertRule(
        alert_name="DatabaseConnectionPoolExhausted",
        severity="critical",
        auto_remediate=True,
        remediation_action=lambda: increase_connection_pool_size()
    ),
]

def handle_alert(alert: dict):
    """Automated alert handling"""

    alert_name = alert["alert_name"]

    # Find matching rule
    rule = next((r for r in alert_rules if r.alert_name == alert_name), None)

    if not rule:
        # No automation, just notify humans
        send_pager_duty_alert(alert)
        return

    if rule.auto_remediate:
        print(f"Auto-remediating: {alert_name}")

        try:
            rule.remediation_action()
            print(f"✅ Auto-remediation successful")

            # Notify team of auto-remediation
            send_slack_message(
                f"Alert {alert_name} was automatically remediated"
            )

        except Exception as e:
            print(f"❌ Auto-remediation failed: {e}")

            # Escalate to humans
            send_pager_duty_alert(alert)
    else:
        # High severity, notify humans immediately
        send_pager_duty_alert(alert)
```

---

## Anti-Patterns

### ❌ Anti-Pattern 1: Manual Deployments

**Problem:** Deployments require manual steps.

```bash
# BAD: Manual deployment process
ssh production-server-1
cd /var/www/app
git pull
npm install
sudo systemctl restart app
# Repeat for 10 more servers...
# Inconsistent, error-prone, slow
```

**Solution:** Automate with CI/CD.

```yaml
# GOOD: Automated deployment
name: Deploy
on:
  push:
    branches: [main]
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Deploy
        run: ./deploy.sh production
```

### ❌ Anti-Pattern 2: Snowflake Servers

**Problem:** Each server configured manually, unique configuration.

**Solution:** Immutable infrastructure.

```dockerfile
# Define infrastructure as code
# Every server identical
# Deployed from same image
```

### ❌ Anti-Pattern 3: No Rollback Plan

**Problem:** Deployment fails, no way to quickly revert.

**Solution:** Always have rollback mechanism.

```python
# Before deployment
previous_version = get_current_version()

try:
    deploy(new_version)
except:
    deploy(previous_version)  # Auto-rollback
```

---

## Related Resources

- See `base/cicd-comprehensive.md` for CI/CD best practices
- See `base/metrics-standards.md` for monitoring
- See `cloud/*/well-architected.md` for cloud-specific operations
- See `base/chaos-engineering.md` for resilience testing

---

**Remember:** Automation reduces toil, improves reliability, and scales your team. Automate ruthlessly, but always have manual override capabilities for emergencies.
