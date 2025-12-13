# Chaos Engineering for AI Systems

> **When to apply:** Production systems with high reliability requirements
> **Maturity Level:** Production only (not for MVP or Pre-Production)

Proactively test system resilience by intentionally injecting failures to discover weaknesses before they cause outages.

## Table of Contents

- [Overview](#overview)
- [Core Principles](#core-principles)
- [Getting Started](#getting-started)
- [Chaos Experiments for AI Systems](#chaos-experiments-for-ai-systems)
- [Running Chaos Experiments](#running-chaos-experiments)
- [Tools and Frameworks](#tools-and-frameworks)
- [Safety and Safeguards](#safety-and-safeguards)

---

## Overview

### What is Chaos Engineering?

**Definition:** The discipline of experimenting on a system to build confidence in its capability to withstand turbulent conditions in production.

**Core Idea:** Break things on purpose before they break on their own.

### Why Chaos Engineering?

**Traditional Approach:**
- Wait for failures to happen in production
- React when users report issues
- Hope nothing breaks during peak traffic

**Chaos Engineering:**
- Proactively find weaknesses
- Fix issues before users are impacted
- Build confidence in resilience
- Validate monitoring and alerting

### When to Use Chaos Engineering

**Required for:**
- ✅ Production systems with SLAs
- ✅ Distributed systems with multiple dependencies
- ✅ High-stakes applications (financial, healthcare, etc.)
- ✅ Systems with complex failure modes
- ✅ AI/ML systems with model dependencies

**Not needed for:**
- ❌ MVP/POC projects
- ❌ Pre-production systems
- ❌ Monolithic applications with simple failure modes
- ❌ Systems without production traffic

---

## Core Principles

### 1. Build a Hypothesis

**Template:**

```markdown
## Hypothesis

**Steady State:** System serves requests with 200ms p95 latency and 99.9% success rate

**Experiment:** Terminate 1 random EC2 instance in the cluster

**Expected Result:** System continues serving requests with < 300ms p95 latency and > 99.5% success rate

**Blast Radius:** Single availability zone, 10% of traffic
```

### 2. Vary Real-World Events

**Common Failure Modes:**

**Infrastructure:**
- Instance/container failures
- Network latency/packet loss
- Disk full/read-only filesystem
- CPU/memory exhaustion

**Dependencies:**
- Database unavailable
- API rate limiting
- Third-party service outage
- DNS failures

**AI-Specific:**
- Model serving latency spike
- Model endpoint unavailable
- Model returns invalid predictions
- Feature store unavailable

### 3. Run Experiments in Production

**Why Production?**
- Staging doesn't match production traffic patterns
- Load balancers, caches behave differently
- Real user impact reveals true resilience

**Safety First:**
- Start with smallest blast radius
- Have rollback plan ready
- Monitor closely during experiment
- Run during low-traffic periods initially

### 4. Automate to Run Continuously

**Goal:** Chaos as part of normal operations.

```yaml
# Example: Scheduled chaos experiments
# Run every Friday at 2pm (low traffic period)

weekly_chaos_experiments:
  - experiment: terminate_random_instance
    schedule: "Friday 14:00"
    blast_radius: "10%"
    duration: "5 minutes"

  - experiment: inject_latency
    schedule: "Friday 14:15"
    target: "database"
    latency: "100ms"
    duration: "5 minutes"
```

### 5. Minimize Blast Radius

**Progressive Expansion:**

```
Week 1: 1% of traffic, single AZ, 5 minutes
Week 2: 5% of traffic, single AZ, 10 minutes
Week 3: 10% of traffic, multi-AZ, 15 minutes
Week 4: 20% of traffic, multi-AZ, 30 minutes
```

---

## Getting Started

### Step 1: Define Steady State

**Identify Key Metrics:**

```python
from dataclasses import dataclass
from typing import List

@dataclass
class SteadyStateMetrics:
    """Baseline metrics that define system health"""

    # Performance metrics
    p95_latency_ms: float  # 95th percentile latency
    p99_latency_ms: float  # 99th percentile latency
    requests_per_second: float

    # Reliability metrics
    success_rate: float  # Percentage of successful requests
    error_rate: float    # Percentage of failed requests

    # Business metrics
    conversion_rate: float  # For e-commerce
    active_users: int

# Define acceptable ranges
STEADY_STATE = SteadyStateMetrics(
    p95_latency_ms=200.0,
    p99_latency_ms=500.0,
    requests_per_second=1000.0,
    success_rate=99.9,
    error_rate=0.1,
    conversion_rate=3.5,
    active_users=10000
)

# Acceptable deviation during chaos experiments
ACCEPTABLE_DEGRADATION = SteadyStateMetrics(
    p95_latency_ms=300.0,  # +50% latency acceptable
    p99_latency_ms=750.0,
    requests_per_second=950.0,  # -5% throughput acceptable
    success_rate=99.5,  # -0.4% success rate acceptable
    error_rate=0.5,
    conversion_rate=3.2,  # -8% conversion acceptable
    active_users=9500
)
```

### Step 2: Form a Hypothesis

```markdown
## Chaos Experiment: Database Failover

**Question:** What happens if our primary database fails?

**Hypothesis:**
- System will automatically failover to replica database
- Failover completes within 30 seconds
- Total error rate spike < 1% during failover
- Users experience < 5 seconds of degraded performance

**How to Test:**
1. Terminate primary RDS instance
2. Measure failover time
3. Monitor error rates and latency
4. Verify replica promotion

**Success Criteria:**
- [ ] Failover completes < 30 seconds
- [ ] No data loss
- [ ] Error rate returns to baseline within 1 minute
- [ ] No manual intervention required
```

### Step 3: Design the Experiment

```python
from enum import Enum
from dataclasses import dataclass
from datetime import datetime

class ExperimentStatus(Enum):
    PLANNED = "planned"
    RUNNING = "running"
    COMPLETED = "completed"
    ABORTED = "aborted"

@dataclass
class ChaosExperiment:
    """Chaos experiment configuration"""

    name: str
    hypothesis: str
    steady_state_metrics: SteadyStateMetrics
    target: str  # What to break (e.g., "database", "api", "model")
    failure_type: str  # How to break it (e.g., "terminate", "latency", "error")
    blast_radius: float  # Percentage of system affected (0.0 to 1.0)
    duration_seconds: int
    rollback_triggers: List[str]  # Auto-abort conditions

    # Execution tracking
    status: ExperimentStatus = ExperimentStatus.PLANNED
    started_at: datetime = None
    completed_at: datetime = None
    results: dict = None

# Example experiment
database_failover_experiment = ChaosExperiment(
    name="Database Primary Failover",
    hypothesis="System handles database failover with < 30s downtime",
    steady_state_metrics=STEADY_STATE,
    target="rds-primary",
    failure_type="terminate_instance",
    blast_radius=1.0,  # Affects entire system
    duration_seconds=300,  # 5 minutes
    rollback_triggers=[
        "error_rate > 5%",
        "p99_latency > 2000ms",
        "success_rate < 95%"
    ]
)
```

### Step 4: Run and Monitor

```python
import time
from datetime import datetime

def run_chaos_experiment(experiment: ChaosExperiment):
    """Execute chaos experiment with monitoring and safety checks"""

    print(f"🧪 Starting chaos experiment: {experiment.name}")
    experiment.status = ExperimentStatus.RUNNING
    experiment.started_at = datetime.now()

    try:
        # 1. Capture baseline metrics
        baseline = capture_metrics()
        print(f"📊 Baseline: {baseline}")

        # 2. Inject failure
        print(f"💥 Injecting failure: {experiment.failure_type} on {experiment.target}")
        failure_injection = inject_failure(experiment)

        # 3. Monitor during experiment
        start_time = time.time()
        while time.time() - start_time < experiment.duration_seconds:
            current_metrics = capture_metrics()

            # Check rollback triggers
            if should_abort(current_metrics, experiment.rollback_triggers):
                print("🚨 Abort trigger activated! Rolling back...")
                rollback_failure(failure_injection)
                experiment.status = ExperimentStatus.ABORTED
                return

            # Log metrics
            print(f"📈 Current: {current_metrics}")
            time.sleep(10)  # Check every 10 seconds

        # 4. Rollback failure
        print("✅ Experiment complete. Rolling back failure...")
        rollback_failure(failure_injection)

        # 5. Verify recovery
        time.sleep(30)  # Wait for recovery
        final_metrics = capture_metrics()

        # 6. Analyze results
        experiment.results = analyze_experiment_results(
            baseline=baseline,
            during=current_metrics,
            after=final_metrics,
            hypothesis=experiment.hypothesis
        )

        experiment.status = ExperimentStatus.COMPLETED
        experiment.completed_at = datetime.now()

        print(f"📋 Results: {experiment.results}")

    except Exception as e:
        print(f"❌ Experiment failed: {e}")
        rollback_failure(failure_injection)
        experiment.status = ExperimentStatus.ABORTED
        raise

def should_abort(current_metrics: SteadyStateMetrics, triggers: List[str]) -> bool:
    """Check if abort conditions are met"""
    for trigger in triggers:
        if eval_trigger(trigger, current_metrics):
            return True
    return False
```

---

## Chaos Experiments for AI Systems

### AI-Specific Failure Scenarios

**1. Model Serving Failures**

```python
chaos_experiment_model_serving = ChaosExperiment(
    name="Model Endpoint Unavailable",
    hypothesis="System falls back to cached predictions when model endpoint fails",
    target="model-serving-endpoint",
    failure_type="make_unavailable",
    blast_radius=0.1,  # 10% of model requests
    duration_seconds=300,
    rollback_triggers=["user_errors > 1%"]
)
```

**Fallback Strategy:**

```python
import asyncio
from typing import Optional

class ResilientModelClient:
    """Model client with fallback strategies"""

    def __init__(self, primary_endpoint: str, cache_ttl: int = 3600):
        self.primary_endpoint = primary_endpoint
        self.cache = {}
        self.cache_ttl = cache_ttl

    async def predict(self, input_data: dict) -> dict:
        """Predict with automatic fallback"""

        try:
            # Try primary model endpoint
            return await self._call_primary_model(input_data)

        except ModelEndpointUnavailable:
            # Fallback 1: Check cache
            cached_prediction = self._get_cached_prediction(input_data)
            if cached_prediction:
                log_metric("model_prediction_cache_hit", 1)
                return cached_prediction

            # Fallback 2: Use simple heuristic/rule-based system
            log_metric("model_prediction_fallback", 1)
            return self._fallback_prediction(input_data)

    def _fallback_prediction(self, input_data: dict) -> dict:
        """Simple rule-based fallback when model unavailable"""
        # Example: Recommend popular items instead of personalized
        return {
            "prediction": "popular_items",
            "confidence": 0.5,
            "fallback": True,
            "reason": "model_unavailable"
        }
```

**2. Feature Store Unavailable**

```python
chaos_experiment_feature_store = ChaosExperiment(
    name="Feature Store Outage",
    hypothesis="System uses stale features from cache when feature store fails",
    target="feature-store",
    failure_type="network_partition",
    blast_radius=0.2,
    duration_seconds=180,
    rollback_triggers=["prediction_quality_drop > 10%"]
)
```

**3. Model Latency Spike**

```python
chaos_experiment_model_latency = ChaosExperiment(
    name="Model Inference Latency Spike",
    hypothesis="System times out slow predictions and serves default recommendations",
    target="model-inference",
    failure_type="inject_latency",
    latency_ms=5000,  # Add 5 second delay
    blast_radius=0.1,
    duration_seconds=300,
    rollback_triggers=["p95_latency > 1000ms", "timeouts > 5%"]
)
```

**Timeout Protection:**

```python
import asyncio

async def predict_with_timeout(model_client, input_data, timeout_seconds=1.0):
    """Predict with timeout and fallback"""

    try:
        prediction = await asyncio.wait_for(
            model_client.predict(input_data),
            timeout=timeout_seconds
        )
        return prediction

    except asyncio.TimeoutError:
        log_metric("model_prediction_timeout", 1)
        # Return safe default instead of error
        return {
            "prediction": "default_recommendation",
            "confidence": 0.3,
            "timeout": True
        }
```

**4. Model Returns Invalid Predictions**

```python
chaos_experiment_corrupt_predictions = ChaosExperiment(
    name="Model Returns Corrupted Data",
    hypothesis="System validates predictions and rejects invalid outputs",
    target="model-output",
    failure_type="inject_corrupt_data",
    corruption_rate=0.05,  # 5% of predictions corrupted
    duration_seconds=180,
    rollback_triggers=["validation_failures > 10%"]
)
```

**Prediction Validation:**

```python
from pydantic import BaseModel, validator, ValidationError

class PredictionOutput(BaseModel):
    """Validated prediction output"""

    prediction: str
    confidence: float
    top_recommendations: List[str]

    @validator('confidence')
    def confidence_in_range(cls, v):
        if not 0.0 <= v <= 1.0:
            raise ValueError('Confidence must be between 0 and 1')
        return v

    @validator('top_recommendations')
    def has_recommendations(cls, v):
        if len(v) == 0:
            raise ValueError('Must have at least one recommendation')
        return v

def safe_model_predict(model_client, input_data):
    """Predict with output validation"""

    try:
        raw_prediction = model_client.predict(input_data)

        # Validate output schema
        validated = PredictionOutput(**raw_prediction)
        return validated.dict()

    except ValidationError as e:
        log_error("Invalid model output", error=str(e))
        # Return safe default instead of propagating invalid data
        return {
            "prediction": "fallback",
            "confidence": 0.4,
            "top_recommendations": ["default_item"]
        }
```

**5. Data Drift Simulation**

```python
chaos_experiment_data_drift = ChaosExperiment(
    name="Sudden Data Distribution Shift",
    hypothesis="Model drift detection triggers alert within 1 hour",
    target="input-features",
    failure_type="shift_distribution",
    shift_magnitude=2.0,  # 2 standard deviations
    duration_seconds=3600,  # 1 hour
    rollback_triggers=["prediction_confidence < 0.5"]
)
```

---

## Running Chaos Experiments

### Experiment Checklist

**Before Experiment:**
- [ ] Define hypothesis clearly
- [ ] Identify rollback triggers
- [ ] Set up monitoring dashboards
- [ ] Alert on-call team
- [ ] Schedule during low-traffic period
- [ ] Have rollback script ready
- [ ] Get stakeholder approval (if customer-facing)

**During Experiment:**
- [ ] Monitor metrics in real-time
- [ ] Watch for abort triggers
- [ ] Document observations
- [ ] Be ready to rollback immediately

**After Experiment:**
- [ ] Verify system recovered fully
- [ ] Analyze results
- [ ] Document findings
- [ ] Create action items for improvements
- [ ] Share learnings with team

### Example: Complete Experiment

```python
# Complete chaos experiment example

def run_complete_chaos_experiment():
    """Full example of chaos engineering workflow"""

    # 1. Define experiment
    experiment = ChaosExperiment(
        name="API Gateway Failure",
        hypothesis="Load balancer routes traffic to healthy instances when one fails",
        steady_state_metrics=STEADY_STATE,
        target="api-gateway-instance-1",
        failure_type="terminate",
        blast_radius=0.33,  # 1 of 3 instances
        duration_seconds=300,
        rollback_triggers=[
            "error_rate > 2%",
            "p95_latency > 500ms"
        ]
    )

    # 2. Notify team
    send_slack_message(
        channel="#chaos-engineering",
        message=f"🧪 Starting chaos experiment: {experiment.name}"
    )

    # 3. Capture baseline
    baseline_metrics = capture_metrics_for_duration(60)  # 1 min baseline

    # 4. Run experiment
    try:
        results = run_chaos_experiment(experiment)

        # 5. Analyze results
        if results["hypothesis_validated"]:
            print("✅ Hypothesis validated! System is resilient.")
        else:
            print("❌ Hypothesis NOT validated. Found weaknesses:")
            for weakness in results["weaknesses"]:
                print(f"  - {weakness}")
                create_jira_ticket(weakness)

    except ExperimentAborted as e:
        print(f"🚨 Experiment aborted: {e}")
        create_incident_report(experiment, e)

    # 6. Share results
    send_experiment_report(experiment)
```

---

## Tools and Frameworks

### Chaos Mesh (Kubernetes)

```yaml
# chaos-mesh-example.yaml
apiVersion: chaos-mesh.org/v1alpha1
kind: PodChaos
metadata:
  name: pod-failure-example
spec:
  action: pod-failure
  mode: one
  duration: "30s"
  selector:
    namespaces:
      - production
    labelSelectors:
      app: recommendation-service
```

### AWS Fault Injection Simulator

```yaml
# FIS experiment template
experiment:
  description: "Terminate EC2 instance"
  targets:
    ec2-instances:
      resourceType: "aws:ec2:instance"
      selectionMode: "COUNT(1)"
      resourceTags:
        Environment: "production"
        Service: "api-server"

  actions:
    terminate-instance:
      actionId: "aws:ec2:terminate-instances"
      targets:
        Instances: "ec2-instances"
      duration: "PT5M"

  stopConditions:
    - source: "aws:cloudwatch:alarm"
      value: "ErrorRateAlarm"
```

### Gremlin (SaaS Platform)

```python
from gremlin import GremlinClient

client = GremlinClient(api_key="...")

# Create latency attack
attack = client.create_attack(
    target="api-service",
    type="latency",
    magnitude=100,  # ms
    length=300,  # seconds
    percent=10  # affect 10% of traffic
)

# Monitor attack
status = client.get_attack_status(attack.id)
```

---

## Safety and Safeguards

### Guardrails

**1. Blast Radius Limits:**
```python
MAX_BLAST_RADIUS = {
    "mvp": 0.0,  # No chaos experiments
    "pre-production": 0.0,  # No chaos experiments
    "production": 0.20  # Max 20% of traffic
}

def validate_blast_radius(experiment: ChaosExperiment, env: str):
    max_allowed = MAX_BLAST_RADIUS[env]
    if experiment.blast_radius > max_allowed:
        raise ValueError(
            f"Blast radius {experiment.blast_radius} exceeds "
            f"limit {max_allowed} for {env}"
        )
```

**2. Required Approvals:**
```yaml
approval_requirements:
  blast_radius_10_percent: ["team_lead"]
  blast_radius_50_percent: ["team_lead", "engineering_manager"]
  customer_facing: ["team_lead", "product_manager"]
  production_database: ["team_lead", "cto"]
```

**3. Auto-Abort Triggers:**
```python
CRITICAL_ABORT_TRIGGERS = [
    "error_rate > 5%",
    "p99_latency > 5000ms",
    "success_rate < 90%",
    "active_users_drop > 20%",
    "revenue_drop > 10%"
]
```

---

## Related Resources

- See `base/testing-philosophy.md` for testing strategies
- See `base/operations-automation.md` for runbooks and automation
- See `cloud/*/well-architected.md` for resilience patterns
- See `base/metrics-standards.md` for monitoring

---

**Remember:** Chaos engineering is about learning, not breaking things. Start small, learn continuously, and build confidence in your system's resilience. The goal is not to prove your system is perfect, but to discover and fix weaknesses before they impact users.
