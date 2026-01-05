# Chaos Engineering for AI Systems

> **When to apply:** Production systems with high reliability requirements
> **Maturity Level:** Production only (not for MVP or Pre-Production)

Proactively test system resilience by intentionally injecting failures to discover weaknesses before they cause outages.

## Overview

**Definition:** The discipline of experimenting on a system to build confidence in its capability to withstand turbulent conditions in production.

**Core Idea:** Break things on purpose before they break on their own.

### When to Use Chaos Engineering

**Required for:**
- ✅ Production systems with SLAs
- ✅ Distributed systems with multiple dependencies
- ✅ High-stakes applications (financial, healthcare)
- ✅ AI/ML systems with model dependencies

**Not needed for:**
- ❌ MVP/POC projects
- ❌ Pre-production systems
- ❌ Monolithic applications with simple failure modes

---

## Core Principles

### 1. Build a Hypothesis

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
- CPU/memory exhaustion

**Dependencies:**
- Database unavailable
- API rate limiting
- Third-party service outage

**AI-Specific:**
- Model serving latency spike
- Model endpoint unavailable
- Model returns invalid predictions
- Feature store unavailable

### 3. Run Experiments in Production

**Why Production?**
- Staging doesn't match production traffic patterns
- Real user impact reveals true resilience

**Safety First:**
- Start with smallest blast radius
- Have rollback plan ready
- Monitor closely during experiment
- Run during low-traffic periods initially

### 4. Minimize Blast Radius

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

```python
from dataclasses import dataclass

@dataclass
class SteadyStateMetrics:
    """Baseline metrics that define system health"""
    p95_latency_ms: float
    p99_latency_ms: float
    requests_per_second: float
    success_rate: float
    error_rate: float

STEADY_STATE = SteadyStateMetrics(
    p95_latency_ms=200.0,
    p99_latency_ms=500.0,
    requests_per_second=1000.0,
    success_rate=99.9,
    error_rate=0.1
)

ACCEPTABLE_DEGRADATION = SteadyStateMetrics(
    p95_latency_ms=300.0,  # +50% acceptable
    p99_latency_ms=750.0,
    requests_per_second=950.0,  # -5% acceptable
    success_rate=99.5,
    error_rate=0.5
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
    target: str
    failure_type: str
    blast_radius: float  # 0.0 to 1.0
    duration_seconds: int
    rollback_triggers: List[str]
    status: ExperimentStatus = ExperimentStatus.PLANNED

database_failover_experiment = ChaosExperiment(
    name="Database Primary Failover",
    hypothesis="System handles database failover with < 30s downtime",
    target="rds-primary",
    failure_type="terminate_instance",
    blast_radius=1.0,
    duration_seconds=300,
    rollback_triggers=[
        "error_rate > 5%",
        "p99_latency > 2000ms",
        "success_rate < 95%"
    ]
)
```

### Step 4: Run and Monitor

```python
def run_chaos_experiment(experiment: ChaosExperiment):
    """Execute chaos experiment with monitoring and safety checks"""

    print(f"Starting chaos experiment: {experiment.name}")
    experiment.status = ExperimentStatus.RUNNING

    try:
        # 1. Capture baseline metrics
        baseline = capture_metrics()

        # 2. Inject failure
        print(f"Injecting failure: {experiment.failure_type} on {experiment.target}")
        failure_injection = inject_failure(experiment)

        # 3. Monitor during experiment
        start_time = time.time()
        while time.time() - start_time < experiment.duration_seconds:
            current_metrics = capture_metrics()

            # Check rollback triggers
            if should_abort(current_metrics, experiment.rollback_triggers):
                print("Abort trigger activated! Rolling back...")
                rollback_failure(failure_injection)
                experiment.status = ExperimentStatus.ABORTED
                return

            print(f"Current: {current_metrics}")
            time.sleep(10)

        # 4. Rollback failure
        print("Experiment complete. Rolling back failure...")
        rollback_failure(failure_injection)

        # 5. Analyze results
        experiment.status = ExperimentStatus.COMPLETED

    except Exception as e:
        print(f"Experiment failed: {e}")
        rollback_failure(failure_injection)
        experiment.status = ExperimentStatus.ABORTED
        raise
```

---

## Chaos Experiments for AI Systems

### 1. Model Serving Failures

```python
class ResilientModelClient:
    """Model client with fallback strategies"""

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
        return {
            "prediction": "popular_items",
            "confidence": 0.5,
            "fallback": True,
            "reason": "model_unavailable"
        }
```

### 2. Model Latency Spike

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
        return {
            "prediction": "default_recommendation",
            "confidence": 0.3,
            "timeout": True
        }
```

### 3. Model Returns Invalid Predictions

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

def safe_model_predict(model_client, input_data):
    """Predict with output validation"""

    try:
        raw_prediction = model_client.predict(input_data)
        validated = PredictionOutput(**raw_prediction)
        return validated.dict()

    except ValidationError as e:
        log_error("Invalid model output", error=str(e))
        return {
            "prediction": "fallback",
            "confidence": 0.4,
            "top_recommendations": ["default_item"]
        }
```

---

## Experiment Checklist

**Before Experiment:**
- [ ] Define hypothesis clearly
- [ ] Identify rollback triggers
- [ ] Set up monitoring dashboards
- [ ] Alert on-call team
- [ ] Schedule during low-traffic period
- [ ] Have rollback script ready

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

---

## Tools and Frameworks

### Chaos Mesh (Kubernetes)

```yaml
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
experiment:
  description: "Terminate EC2 instance"
  targets:
    ec2-instances:
      resourceType: "aws:ec2:instance"
      selectionMode: "COUNT(1)"
  actions:
    terminate-instance:
      actionId: "aws:ec2:terminate-instances"
      duration: "PT5M"
  stopConditions:
    - source: "aws:cloudwatch:alarm"
      value: "ErrorRateAlarm"
```

---

## Safety and Safeguards

### Guardrails

**1. Blast Radius Limits:**

```python
MAX_BLAST_RADIUS = {
    "mvp": 0.0,
    "pre-production": 0.0,
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

**2. Auto-Abort Triggers:**

```python
CRITICAL_ABORT_TRIGGERS = [
    "error_rate > 5%",
    "p99_latency > 5000ms",
    "success_rate < 90%",
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

**Remember:** Chaos engineering is about learning, not breaking things. Start small, learn continuously, and build confidence in your system's resilience.
