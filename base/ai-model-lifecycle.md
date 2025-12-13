# AI Model Lifecycle Management

> **When to apply:** All AI/ML projects from development through production
> **Maturity Level:** Pre-Production and Production (lifecycle awareness for MVP)

Manage AI/ML models through their complete lifecycle: development, training, evaluation, deployment, monitoring, and retraining.

## Table of Contents

- [Overview](#overview)
- [Lifecycle Phases](#lifecycle-phases)
- [Model Versioning](#model-versioning)
- [Performance Monitoring](#performance-monitoring)
- [Model Drift Detection](#model-drift-detection)
- [Retraining Strategy](#retraining-strategy)
- [Model Registry](#model-registry)
- [Deployment Patterns](#deployment-patterns)
- [Rollback and Recovery](#rollback-and-recovery)

---

## Overview

### The AI Model Lifecycle

Unlike traditional software, AI models degrade over time as the world changes. Effective lifecycle management ensures models remain accurate, performant, and aligned with business objectives.

**Key Challenges:**
- **Model drift** - Performance degrades as real-world data shifts
- **Versioning complexity** - Track models, data, code, and hyperparameters
- **Deployment risk** - New models can perform worse than old ones
- **Monitoring difficulty** - Traditional metrics insufficient for ML
- **Retraining decisions** - When and how to retrain

**Benefits of Lifecycle Management:**
- Detect and mitigate model degradation early
- Reproduce and debug model behavior
- Safe deployment with rollback capability
- Continuous improvement through retraining
- Clear audit trail for compliance

---

## Lifecycle Phases

### 1. Experimentation

**Goal:** Explore problem space, validate feasibility

**Activities:**
- Problem definition and success metrics
- Exploratory data analysis (EDA)
- Feature engineering experiments
- Algorithm selection
- Baseline model development

**Tracking Requirements:**
- Log experiment metadata (dataset, features, algorithm)
- Track hyperparameters and configurations
- Record metrics (accuracy, precision, recall, etc.)
- Version datasets used

**Tools:**
- Jupyter notebooks for exploration
- MLflow or Weights & Biases for experiment tracking
- Git for code versioning
- DVC (Data Version Control) for dataset versioning

**Example: Experiment Tracking**

```python
import mlflow
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import accuracy_score, f1_score

# Start experiment
mlflow.set_experiment("customer-churn-prediction")

with mlflow.start_run(run_name="random-forest-v1"):
    # Log parameters
    params = {
        "n_estimators": 100,
        "max_depth": 10,
        "min_samples_split": 5,
        "random_state": 42
    }
    mlflow.log_params(params)

    # Train model
    model = RandomForestClassifier(**params)
    model.fit(X_train, y_train)

    # Evaluate
    y_pred = model.predict(X_test)
    accuracy = accuracy_score(y_test, y_pred)
    f1 = f1_score(y_test, y_pred)

    # Log metrics
    mlflow.log_metrics({
        "accuracy": accuracy,
        "f1_score": f1,
        "train_size": len(X_train),
        "test_size": len(X_test)
    })

    # Log model
    mlflow.sklearn.log_model(model, "model")

    # Log dataset metadata
    mlflow.log_param("dataset_version", "2025-12-13")
    mlflow.log_param("features", len(X_train.columns))
```

---

### 2. Training

**Goal:** Produce production-ready model candidate

**Activities:**
- Train on full dataset
- Hyperparameter optimization
- Cross-validation
- Model selection
- Performance benchmarking

**Requirements:**
- Reproducible training pipeline
- Versioned training data
- Documented hyperparameters
- Training metrics logged
- Model artifacts saved

**Example: Versioned Training Pipeline**

```python
from dataclasses import dataclass
from typing import Dict, Any
import hashlib
import json

@dataclass
class TrainingConfig:
    """Immutable training configuration"""
    model_type: str
    hyperparameters: Dict[str, Any]
    dataset_version: str
    feature_set: str
    random_seed: int

    def to_dict(self) -> dict:
        return {
            "model_type": self.model_type,
            "hyperparameters": self.hyperparameters,
            "dataset_version": self.dataset_version,
            "feature_set": self.feature_set,
            "random_seed": self.random_seed
        }

    def config_hash(self) -> str:
        """Generate unique hash for this configuration"""
        config_str = json.dumps(self.to_dict(), sort_keys=True)
        return hashlib.sha256(config_str.encode()).hexdigest()[:8]

# Define training configuration
config = TrainingConfig(
    model_type="random_forest",
    hyperparameters={
        "n_estimators": 100,
        "max_depth": 10,
        "min_samples_split": 5
    },
    dataset_version="2025-12-13-v1",
    feature_set="baseline_features_v2",
    random_seed=42
)

# Use config hash for model versioning
model_version = f"v1.0.0-{config.config_hash()}"
print(f"Training model: {model_version}")

# Save configuration with model
with open(f"models/{model_version}/config.json", "w") as f:
    json.dump(config.to_dict(), f, indent=2)
```

---

### 3. Evaluation

**Goal:** Validate model meets business requirements

**Activities:**
- Evaluate on holdout test set
- Business metric validation
- Fairness and bias testing
- Performance profiling (latency, memory)
- A/B test planning

**Metrics to Track:**

**Model Metrics:**
- Accuracy, precision, recall, F1 score
- ROC AUC, PR AUC
- Confusion matrix
- Per-class performance
- Confidence calibration

**Business Metrics:**
- Revenue impact
- User engagement
- Cost savings
- Customer satisfaction
- Conversion rates

**Operational Metrics:**
- Inference latency (p50, p95, p99)
- Memory usage
- Throughput (predictions/second)
- Model size

**Fairness Metrics:**
- Demographic parity
- Equal opportunity
- Disparate impact
- Performance across subgroups

**Example: Comprehensive Evaluation**

```python
from sklearn.metrics import classification_report, roc_auc_score
import numpy as np
import time

def evaluate_model(model, X_test, y_test, X_test_metadata):
    """Comprehensive model evaluation"""
    results = {}

    # 1. Model performance metrics
    y_pred = model.predict(X_test)
    y_proba = model.predict_proba(X_test)[:, 1]

    results["classification_report"] = classification_report(y_test, y_pred)
    results["roc_auc"] = roc_auc_score(y_test, y_proba)

    # 2. Operational metrics
    start = time.time()
    _ = model.predict(X_test[:1000])
    elapsed = time.time() - start
    results["inference_latency_ms"] = (elapsed / 1000) * 1000

    # 3. Fairness evaluation (example: gender)
    for gender in ["male", "female"]:
        mask = X_test_metadata["gender"] == gender
        if mask.sum() > 0:
            gender_auc = roc_auc_score(y_test[mask], y_proba[mask])
            results[f"auc_{gender}"] = gender_auc

    # 4. Confidence calibration
    results["mean_confidence"] = np.mean(np.max(model.predict_proba(X_test), axis=1))

    return results
```

---

### 4. Deployment

**Goal:** Safely release model to production

**Activities:**
- Model registration and tagging
- Canary or blue-green deployment
- Feature flag configuration
- Production monitoring setup
- Rollback plan preparation

**Deployment Strategies:**

**Shadow Deployment:**
- Run new model alongside old model
- Log predictions from both
- Compare performance before switching traffic

**Canary Deployment:**
- Route small percentage of traffic to new model (e.g., 5%)
- Monitor metrics closely
- Gradually increase traffic if successful
- Rollback immediately if issues detected

**Blue-Green Deployment:**
- Deploy new model to green environment
- Validate thoroughly
- Switch all traffic at once
- Keep blue environment for instant rollback

**Example: Canary Deployment**

```python
import random
from typing import Optional

class ModelRouter:
    """Route traffic between model versions"""

    def __init__(self,
                 champion_model,
                 challenger_model,
                 canary_percentage: float = 0.05):
        self.champion = champion_model
        self.challenger = challenger_model
        self.canary_pct = canary_percentage
        self.champion_metrics = []
        self.challenger_metrics = []

    def predict(self, X) -> tuple[Any, str]:
        """Route prediction to champion or challenger"""
        use_challenger = random.random() < self.canary_pct

        if use_challenger:
            prediction = self.challenger.predict(X)
            model_version = "challenger"
            self.challenger_metrics.append({
                "prediction": prediction,
                "timestamp": datetime.now()
            })
        else:
            prediction = self.champion.predict(X)
            model_version = "champion"
            self.champion_metrics.append({
                "prediction": prediction,
                "timestamp": datetime.now()
            })

        # Log routing decision
        log_prediction(
            model_version=model_version,
            input=X,
            prediction=prediction
        )

        return prediction, model_version

    def get_canary_health(self) -> dict:
        """Check if canary is performing well"""
        # Compare error rates, latency, etc.
        return {
            "champion_predictions": len(self.champion_metrics),
            "challenger_predictions": len(self.challenger_metrics),
            "canary_percentage": self.canary_pct
        }
```

---

### 5. Monitoring

**Goal:** Detect issues and degradation in production

**Monitor:**

**Model Performance:**
- Prediction accuracy (if labels become available)
- Prediction distribution shifts
- Confidence scores
- Error rates

**Data Quality:**
- Input feature distributions
- Missing value rates
- Out-of-range values
- Data drift

**System Performance:**
- Inference latency
- Throughput
- Error rates (API errors, timeouts)
- Resource utilization (CPU, memory)

**Example: Production Monitoring**

```python
import prometheus_client as prom
from datetime import datetime
import numpy as np

# Prometheus metrics
prediction_latency = prom.Histogram(
    'model_prediction_latency_seconds',
    'Time spent making predictions',
    buckets=[0.001, 0.005, 0.01, 0.05, 0.1, 0.5, 1.0]
)

prediction_confidence = prom.Histogram(
    'model_prediction_confidence',
    'Confidence scores of predictions',
    buckets=[0.5, 0.6, 0.7, 0.8, 0.9, 0.95, 0.99]
)

prediction_counter = prom.Counter(
    'model_predictions_total',
    'Total number of predictions',
    ['model_version', 'prediction_class']
)

class MonitoredModel:
    """Model wrapper with monitoring"""

    def __init__(self, model, version: str):
        self.model = model
        self.version = version
        self.recent_predictions = []

    @prediction_latency.time()
    def predict(self, X):
        """Make prediction with monitoring"""
        # Predict
        prediction = self.model.predict(X)
        proba = self.model.predict_proba(X)

        # Log metrics
        confidence = np.max(proba, axis=1)[0]
        prediction_confidence.observe(confidence)
        prediction_counter.labels(
            model_version=self.version,
            prediction_class=str(prediction[0])
        ).inc()

        # Store for drift detection
        self.recent_predictions.append({
            "timestamp": datetime.now(),
            "prediction": prediction[0],
            "confidence": confidence,
            "features": X
        })

        # Alert on low confidence
        if confidence < 0.6:
            alert_low_confidence(self.version, confidence, X)

        return prediction
```

---

## Model Versioning

### Semantic Versioning for Models

Use semantic versioning: `MAJOR.MINOR.PATCH`

- **MAJOR:** Breaking changes (different features, incompatible API)
- **MINOR:** New capabilities (additional features, better performance)
- **PATCH:** Bug fixes (training bug fixes, minor improvements)

**Example:**
- `v1.0.0` - Initial production model
- `v1.1.0` - Added 5 new features, improved accuracy
- `v1.1.1` - Fixed feature scaling bug
- `v2.0.0` - Complete architecture change (LSTM to Transformer)

### What to Version

**Always version together:**
1. Model artifact (weights, parameters)
2. Training code and configuration
3. Training dataset (version or hash)
4. Feature engineering code
5. Preprocessing pipeline
6. Evaluation metrics and results

**Version Metadata:**

```yaml
# model-v1.2.0/metadata.yaml
model_version: "1.2.0"
model_type: "gradient_boosting"
framework: "xgboost==2.0.0"

training:
  date: "2025-12-13"
  dataset_version: "2025-12-01-v3"
  training_samples: 1000000
  validation_samples: 200000
  test_samples: 200000
  training_duration_hours: 2.5

hyperparameters:
  learning_rate: 0.1
  max_depth: 6
  n_estimators: 100
  subsample: 0.8

features:
  count: 42
  feature_set_version: "v2"
  categorical_features: 8
  numerical_features: 34

performance:
  test_accuracy: 0.92
  test_f1: 0.89
  test_auc: 0.95
  inference_latency_p95_ms: 15

deployment:
  deployed_at: "2025-12-14T10:00:00Z"
  deployed_by: "ci-cd-pipeline"
  environment: "production"
  replicas: 3
```

---

## Performance Monitoring

### Real-Time Monitoring

**Key Metrics:**

1. **Prediction Quality** (if ground truth available)
   - Accuracy over time windows
   - Error distribution
   - Precision/recall trends

2. **Prediction Behavior** (always available)
   - Prediction distribution (should match training)
   - Confidence distribution
   - Feature value ranges

3. **System Health**
   - Latency (p50, p95, p99)
   - Throughput
   - Error rates
   - Resource usage

**Example: Monitoring Dashboard Metrics**

```python
from dataclasses import dataclass
from datetime import datetime, timedelta
import numpy as np

@dataclass
class ModelHealthMetrics:
    """Metrics for model health monitoring"""
    time_window: timedelta

    # Prediction metrics
    total_predictions: int
    avg_confidence: float
    low_confidence_rate: float  # % predictions < 0.6 confidence

    # Distribution metrics
    prediction_distribution: dict  # class -> count
    prediction_entropy: float  # Measure of distribution spread

    # Performance metrics
    p50_latency_ms: float
    p95_latency_ms: float
    p99_latency_ms: float
    error_rate: float

    # Feature drift metrics
    feature_drift_score: float  # 0-1, higher = more drift
    drifted_features: list[str]

    def is_healthy(self) -> tuple[bool, list[str]]:
        """Check if model is healthy"""
        issues = []

        if self.low_confidence_rate > 0.15:
            issues.append(f"High low-confidence rate: {self.low_confidence_rate:.2%}")

        if self.p95_latency_ms > 100:
            issues.append(f"High p95 latency: {self.p95_latency_ms:.1f}ms")

        if self.error_rate > 0.01:
            issues.append(f"High error rate: {self.error_rate:.2%}")

        if self.feature_drift_score > 0.3:
            issues.append(f"Significant feature drift: {self.feature_drift_score:.2f}")

        if len(self.drifted_features) > 5:
            issues.append(f"{len(self.drifted_features)} features show drift")

        return len(issues) == 0, issues
```

---

## Model Drift Detection

### Types of Drift

**1. Data Drift (Covariate Shift)**
- Input feature distributions change
- Example: User demographics shift over time
- Detection: Compare feature distributions to training baseline

**2. Concept Drift**
- Relationship between features and target changes
- Example: What makes a good recommendation changes
- Detection: Monitor prediction accuracy (if labels available)

**3. Label Drift (Prior Probability Shift)**
- Distribution of target variable changes
- Example: Churn rate increases seasonally
- Detection: Compare prediction distribution to training

### Drift Detection Methods

**Statistical Tests:**
- Kolmogorov-Smirnov test (continuous features)
- Chi-squared test (categorical features)
- Population Stability Index (PSI)

**Example: PSI Calculation**

```python
import numpy as np

def calculate_psi(expected: np.ndarray, actual: np.ndarray, bins: int = 10) -> float:
    """
    Calculate Population Stability Index

    PSI < 0.1: No significant change
    PSI < 0.2: Small change
    PSI >= 0.2: Significant change (retrain recommended)
    """
    # Create bins
    breakpoints = np.percentile(expected, np.linspace(0, 100, bins + 1))

    # Calculate distributions
    expected_dist = np.histogram(expected, bins=breakpoints)[0] / len(expected)
    actual_dist = np.histogram(actual, bins=breakpoints)[0] / len(actual)

    # Avoid division by zero
    expected_dist = np.where(expected_dist == 0, 0.0001, expected_dist)
    actual_dist = np.where(actual_dist == 0, 0.0001, actual_dist)

    # Calculate PSI
    psi = np.sum((actual_dist - expected_dist) * np.log(actual_dist / expected_dist))

    return psi

# Example usage
training_feature_values = np.random.normal(0, 1, 10000)
production_feature_values = np.random.normal(0.2, 1.1, 1000)  # Slight drift

psi = calculate_psi(training_feature_values, production_feature_values)
print(f"PSI: {psi:.3f}")

if psi >= 0.2:
    print("⚠️ Significant drift detected - consider retraining")
elif psi >= 0.1:
    print("⚠️ Small drift detected - monitor closely")
else:
    print("✅ No significant drift")
```

---

## Retraining Strategy

### When to Retrain

**Trigger Retraining When:**
1. ✅ Model performance degrades below threshold
2. ✅ Significant data drift detected (PSI > 0.2)
3. ✅ Low confidence predictions exceed threshold (> 15%)
4. ✅ Scheduled retraining interval reached
5. ✅ New labeled data available
6. ✅ Business requirements change

**Example: Retraining Decision Logic**

```python
from dataclasses import dataclass
from datetime import datetime, timedelta
from enum import Enum

class RetrainReason(Enum):
    PERFORMANCE_DEGRADATION = "performance_degradation"
    DATA_DRIFT = "data_drift"
    SCHEDULED = "scheduled"
    LOW_CONFIDENCE = "low_confidence"
    NEW_DATA = "new_data_available"

@dataclass
class RetrainingPolicy:
    """Define when to retrain model"""
    min_accuracy_threshold: float = 0.85
    max_psi_threshold: float = 0.2
    max_low_confidence_rate: float = 0.15
    retraining_interval_days: int = 30
    min_new_samples_for_retrain: int = 10000

def should_retrain(
    current_metrics: ModelHealthMetrics,
    baseline_accuracy: float,
    days_since_training: int,
    new_labeled_samples: int,
    policy: RetrainingPolicy
) -> tuple[bool, list[RetrainReason]]:
    """Determine if model should be retrained"""
    reasons = []

    # Check performance (if accuracy available)
    if baseline_accuracy and baseline_accuracy < policy.min_accuracy_threshold:
        reasons.append(RetrainReason.PERFORMANCE_DEGRADATION)

    # Check data drift
    if current_metrics.feature_drift_score > policy.max_psi_threshold:
        reasons.append(RetrainReason.DATA_DRIFT)

    # Check low confidence rate
    if current_metrics.low_confidence_rate > policy.max_low_confidence_rate:
        reasons.append(RetrainReason.LOW_CONFIDENCE)

    # Check scheduled retraining
    if days_since_training >= policy.retraining_interval_days:
        reasons.append(RetrainReason.SCHEDULED)

    # Check new data availability
    if new_labeled_samples >= policy.min_new_samples_for_retrain:
        reasons.append(RetrainReason.NEW_DATA)

    should_retrain = len(reasons) > 0
    return should_retrain, reasons
```

### Retraining Process

1. **Collect new training data**
   - Combine historical data with new labeled examples
   - Apply data quality checks
   - Version the new dataset

2. **Retrain with same or improved architecture**
   - Use existing hyperparameters as starting point
   - Optionally: hyperparameter optimization
   - Version new model

3. **Evaluate new model**
   - Compare to current production model
   - Ensure improvement on relevant metrics
   - Test on edge cases

4. **Deploy via canary**
   - Start with small traffic percentage
   - Monitor closely for regressions
   - Gradually increase traffic

5. **Promote or rollback**
   - Promote if successful
   - Rollback if issues detected
   - Document decision and learnings

---

## Model Registry

### Centralized Model Management

**Model Registry Benefits:**
- Single source of truth for all models
- Track lineage (code, data, parameters)
- Manage model stages (staging, production, archived)
- Enable governance and compliance
- Facilitate collaboration

**Example: MLflow Model Registry**

```python
import mlflow
from mlflow.tracking import MlflowClient

client = MlflowClient()

# Register model from a run
run_id = "abc123"
model_uri = f"runs:/{run_id}/model"

mlflow.register_model(
    model_uri=model_uri,
    name="customer-churn-predictor",
    tags={
        "team": "data-science",
        "use_case": "churn_prediction",
        "framework": "xgboost"
    }
)

# Transition model to production
client.transition_model_version_stage(
    name="customer-churn-predictor",
    version=3,
    stage="Production",
    archive_existing_versions=True  # Move old production model to archived
)

# Add description
client.update_model_version(
    name="customer-churn-predictor",
    version=3,
    description="Improved model with 5 new features. "
                "Training accuracy: 0.92, Test AUC: 0.95"
)
```

---

## Deployment Patterns

### Pattern 1: Versioned API Endpoints

```python
from fastapi import FastAPI
import mlflow

app = FastAPI()

# Load different model versions
models = {
    "v1": mlflow.pyfunc.load_model("models:/customer-churn/1"),
    "v2": mlflow.pyfunc.load_model("models:/customer-churn/2"),
}

@app.post("/predict/v1")
def predict_v1(data: dict):
    return {"prediction": models["v1"].predict([data])[0]}

@app.post("/predict/v2")
def predict_v2(data: dict):
    return {"prediction": models["v2"].predict([data])[0]}

@app.post("/predict")  # Latest/production version
def predict_latest(data: dict):
    return {"prediction": models["v2"].predict([data])[0]}
```

### Pattern 2: Feature Flag Based Routing

```python
from fastapi import FastAPI, Header
import mlflow

app = FastAPI()
champion_model = mlflow.pyfunc.load_model("models:/customer-churn/Production")
challenger_model = mlflow.pyfunc.load_model("models:/customer-churn/Staging")

@app.post("/predict")
def predict(data: dict, x_use_challenger: bool = Header(False)):
    """Route based on header flag"""
    if x_use_challenger:
        model = challenger_model
        version = "challenger"
    else:
        model = champion_model
        version = "champion"

    prediction = model.predict([data])[0]

    return {
        "prediction": prediction,
        "model_version": version
    }
```

---

## Rollback and Recovery

### Instant Rollback Capability

**Requirements:**
- Keep previous model version deployed
- Traffic routing capability
- Monitoring to detect issues
- Automated or one-click rollback

**Example: Rollback Script**

```bash
#!/bin/bash
# rollback-model.sh

set -e

MODEL_NAME="customer-churn-predictor"
CURRENT_VERSION=$(mlflow models get-latest-versions -n "$MODEL_NAME" -s Production | jq -r '.[0].version')
PREVIOUS_VERSION=$((CURRENT_VERSION - 1))

echo "Current production version: $CURRENT_VERSION"
echo "Rolling back to version: $PREVIOUS_VERSION"

# Confirm
read -p "Proceed with rollback? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Rollback cancelled"
    exit 1
fi

# Archive current version
mlflow models transition-model-version-stage \
    -n "$MODEL_NAME" \
    -v "$CURRENT_VERSION" \
    -s Archived

# Promote previous version
mlflow models transition-model-version-stage \
    -n "$MODEL_NAME" \
    -v "$PREVIOUS_VERSION" \
    -s Production

# Restart model service
kubectl rollout restart deployment/model-service

echo "✅ Rollback complete to version $PREVIOUS_VERSION"
```

---

## Related Resources

- See `base/metrics-standards.md` for monitoring best practices
- See `base/testing-philosophy.md` for ML model testing
- See `cloud/aws/well-architected.md` for ML workload patterns
- See `base/operations-automation.md` for deployment automation

---

**Remember:** ML models are living systems. Continuous monitoring, evaluation, and retraining are essential for long-term success.
