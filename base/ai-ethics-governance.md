# AI Ethics and Governance

> **When to apply:** All AI/ML projects from development through production
> **Maturity Level:** Awareness at MVP, Policies at Pre-Production, Full Governance at Production

Establish ethical guidelines, governance frameworks, and responsible AI practices to ensure AI systems are fair, transparent, accountable, and aligned with organizational values.

## Table of Contents

- [Overview](#overview)
- [Core Ethical Principles](#core-ethical-principles)
- [Fairness and Bias Mitigation](#fairness-and-bias-mitigation)
- [Transparency and Explainability](#transparency-and-explainability)
- [Privacy and Data Protection](#privacy-and-data-protection)
- [Accountability and Oversight](#accountability-and-oversight)
- [Safety and Security](#safety-and-security)
- [Governance Framework](#governance-framework)
- [Compliance and Regulations](#compliance-and-regulations)

---

## Overview

### Why AI Ethics and Governance Matter

AI systems can have significant societal impact. Without proper governance, they risk:
- **Discriminating** against protected groups
- **Violating privacy** through misuse of personal data
- **Causing harm** through unexpected behaviors
- **Eroding trust** in your organization
- **Creating legal liability** through non-compliance

**Benefits of robust AI governance:**
- Reduced risk of bias and discrimination
- Increased user trust and adoption
- Legal and regulatory compliance
- Better alignment with organizational values
- Early detection of ethical issues
- Sustainable AI practices

### Maturity-Based Approach

**MVP/POC:**
- ⚠️ Awareness of ethical considerations
- Basic privacy protections
- Document intended use cases
- Avoid sensitive applications

**Pre-Production:**
- ✅ Fairness assessment and bias testing
- Privacy impact assessment
- Basic explainability requirements
- Ethics review process
- Incident response plan

**Production:**
- ✅ Comprehensive governance framework
- Continuous fairness monitoring
- Full audit trail and transparency
- Ethics board oversight
- Regular compliance audits
- Public accountability mechanisms

---

## Core Ethical Principles

### 1. Human-Centered AI

**Principle:** AI systems should augment and empower humans, not replace or harm them.

**Implementation:**
- Clearly define human oversight requirements
- Design AI to support human decision-making
- Provide mechanisms for human intervention
- Respect human autonomy and agency

**Example: Loan Approval System**

```python
from dataclasses import dataclass
from enum import Enum

class DecisionType(Enum):
    AI_APPROVED = "ai_approved"
    AI_REJECTED = "ai_rejected"
    HUMAN_REVIEW_REQUIRED = "human_review_required"

@dataclass
class LoanDecision:
    decision_type: DecisionType
    confidence_score: float
    reasoning: str
    requires_human_review: bool

def make_loan_decision(application: LoanApplication) -> LoanDecision:
    """AI-assisted loan decision with human oversight"""

    # AI makes prediction
    score = loan_model.predict_score(application)
    risk = loan_model.assess_risk(application)

    # High-stakes decisions require human review
    if application.amount > 100000:
        return LoanDecision(
            decision_type=DecisionType.HUMAN_REVIEW_REQUIRED,
            confidence_score=score,
            reasoning="High-value loans require human review",
            requires_human_review=True
        )

    # Low confidence requires human review
    if score < 0.7:
        return LoanDecision(
            decision_type=DecisionType.HUMAN_REVIEW_REQUIRED,
            confidence_score=score,
            reasoning="Confidence below threshold, needs review",
            requires_human_review=True
        )

    # Clear cases can be automated
    if score > 0.9 and risk == "low":
        return LoanDecision(
            decision_type=DecisionType.AI_APPROVED,
            confidence_score=score,
            reasoning="High confidence, low risk applicant",
            requires_human_review=False
        )

    # Default to human review for edge cases
    return LoanDecision(
        decision_type=DecisionType.HUMAN_REVIEW_REQUIRED,
        confidence_score=score,
        reasoning="Edge case, human judgment needed",
        requires_human_review=True
    )
```

### 2. Fairness and Non-Discrimination

**Principle:** AI systems must not discriminate against individuals or groups based on protected characteristics.

**Protected Characteristics (vary by jurisdiction):**
- Race, ethnicity, national origin
- Gender, gender identity
- Age
- Disability
- Religion
- Sexual orientation
- Socioeconomic status

**Requirements:**
- Assess disparate impact across demographic groups
- Test for proxy discrimination (indirect discrimination)
- Document fairness metrics and thresholds
- Implement bias mitigation strategies

### 3. Transparency and Explainability

**Principle:** Stakeholders should understand how AI systems make decisions.

**Transparency Levels:**

**Level 1: Process Transparency** - How the system works
- What data is used
- What type of model
- What problem it solves
- Who built and maintains it

**Level 2: Decision Transparency** - Why a specific decision was made
- Key factors that influenced the decision
- Which features mattered most
- Confidence level of the prediction

**Level 3: Algorithmic Transparency** - Technical details
- Model architecture and hyperparameters
- Training data characteristics
- Performance metrics and limitations

**Example: Explainable Predictions**

```python
from typing import Dict, List
import shap

@dataclass
class ExplainablePrediction:
    """Prediction with explanation"""
    prediction: str
    confidence: float
    explanation: str
    top_factors: List[Dict[str, float]]

def predict_with_explanation(features: dict) -> ExplainablePrediction:
    """Make prediction with human-readable explanation"""

    # Make prediction
    prediction = model.predict([features])[0]
    confidence = model.predict_proba([features])[0].max()

    # Calculate SHAP values for explainability
    explainer = shap.TreeExplainer(model)
    shap_values = explainer.shap_values([features])

    # Get top contributing factors
    feature_importance = []
    for feature_name, shap_value in zip(features.keys(), shap_values[0]):
        feature_importance.append({
            "feature": feature_name,
            "value": features[feature_name],
            "impact": float(shap_value)
        })

    # Sort by absolute impact
    top_factors = sorted(
        feature_importance,
        key=lambda x: abs(x["impact"]),
        reverse=True
    )[:5]

    # Generate human-readable explanation
    explanation = generate_explanation(prediction, top_factors)

    return ExplainablePrediction(
        prediction=prediction,
        confidence=confidence,
        explanation=explanation,
        top_factors=top_factors
    )

def generate_explanation(prediction: str, factors: List[Dict]) -> str:
    """Convert feature importance to natural language"""
    if prediction == "approved":
        explanation = "This application was approved primarily because: "
    else:
        explanation = "This application was declined primarily because: "

    reasons = []
    for factor in factors[:3]:  # Top 3 factors
        feature = factor["feature"]
        value = factor["value"]
        impact = factor["impact"]

        if feature == "credit_score":
            if impact > 0:
                reasons.append(f"strong credit score ({value})")
            else:
                reasons.append(f"low credit score ({value})")
        elif feature == "income":
            if impact > 0:
                reasons.append(f"high income (${value:,.0f})")
            else:
                reasons.append(f"insufficient income (${value:,.0f})")

    return explanation + ", ".join(reasons)
```

### 4. Privacy by Design

**Principle:** Protect individual privacy throughout the AI lifecycle.

**Privacy Requirements:**
- Minimize data collection (collect only what's necessary)
- Anonymize or pseudonymize personal data
- Implement data retention policies
- Respect user consent and preferences
- Enable data deletion (right to be forgotten)
- Secure data in transit and at rest

**Example: Privacy-Preserving ML**

```python
import hashlib
from datetime import datetime, timedelta

class PrivacyPreservingDataset:
    """Dataset with privacy protections built-in"""

    def __init__(self, retention_days: int = 90):
        self.retention_days = retention_days
        self.data = []

    def add_record(self, record: dict):
        """Add record with automatic anonymization"""

        # Pseudonymize personally identifiable information
        anonymized_record = {
            "user_id": self._pseudonymize(record.get("email", "")),
            "age_bucket": self._bucketize_age(record.get("age")),
            "location": record.get("city"),  # City OK, not full address
            "timestamp": datetime.now(),
            # Include only necessary features
            "feature_1": record.get("feature_1"),
            "feature_2": record.get("feature_2"),
            # DON'T store: email, name, address, SSN, etc.
        }

        self.data.append(anonymized_record)

    def _pseudonymize(self, identifier: str) -> str:
        """One-way hash for pseudonymization"""
        return hashlib.sha256(identifier.encode()).hexdigest()[:16]

    def _bucketize_age(self, age: int) -> str:
        """Generalize age to reduce identifiability"""
        if age < 25:
            return "18-24"
        elif age < 35:
            return "25-34"
        elif age < 50:
            return "35-49"
        else:
            return "50+"

    def cleanup_old_data(self):
        """Implement data retention policy"""
        cutoff_date = datetime.now() - timedelta(days=self.retention_days)
        self.data = [
            record for record in self.data
            if record["timestamp"] > cutoff_date
        ]
        print(f"✓ Removed records older than {self.retention_days} days")
```

### 5. Safety and Robustness

**Principle:** AI systems should be safe, reliable, and perform as intended.

**Safety Requirements:**
- Validate inputs and outputs
- Handle edge cases gracefully
- Monitor for anomalies
- Implement fail-safes
- Test adversarial scenarios

---

## Fairness and Bias Mitigation

### Sources of Bias

**1. Historical Bias** - Training data reflects past discrimination
- Example: Hiring models trained on biased historical hiring decisions

**2. Representation Bias** - Training data doesn't represent all users
- Example: Facial recognition trained primarily on one demographic

**3. Measurement Bias** - Proxy variables correlate with protected attributes
- Example: ZIP code as proxy for race

**4. Aggregation Bias** - One model doesn't fit all subgroups equally
- Example: Medical diagnosis model optimized for majority population

### Fairness Metrics

**Common Fairness Metrics:**

```python
from sklearn.metrics import confusion_matrix
import numpy as np

def calculate_fairness_metrics(y_true, y_pred, sensitive_attribute):
    """Calculate fairness metrics across demographic groups"""

    results = {}

    for group in np.unique(sensitive_attribute):
        mask = sensitive_attribute == group
        group_y_true = y_true[mask]
        group_y_pred = y_pred[mask]

        # Confusion matrix
        tn, fp, fn, tp = confusion_matrix(group_y_true, group_y_pred).ravel()

        # Statistical parity: P(Y_pred=1 | group)
        positive_rate = (y_pred[mask] == 1).mean()

        # Equal opportunity: TPR parity
        tpr = tp / (tp + fn) if (tp + fn) > 0 else 0

        # Predictive parity: PPV parity
        ppv = tp / (tp + fp) if (tp + fp) > 0 else 0

        results[group] = {
            "positive_rate": positive_rate,
            "true_positive_rate": tpr,
            "positive_predictive_value": ppv,
            "sample_size": mask.sum()
        }

    # Check for disparate impact
    groups = list(results.keys())
    if len(groups) == 2:
        ratio = (results[groups[0]]["positive_rate"] /
                 results[groups[1]]["positive_rate"])

        # 80% rule: ratio should be >= 0.8
        results["disparate_impact_ratio"] = ratio
        results["passes_80_percent_rule"] = ratio >= 0.8

    return results

# Example usage
fairness_report = calculate_fairness_metrics(
    y_true=labels,
    y_pred=predictions,
    sensitive_attribute=demographics["gender"]
)

print("Fairness Analysis:")
for group, metrics in fairness_report.items():
    if isinstance(metrics, dict):
        print(f"\n{group}:")
        print(f"  Positive Rate: {metrics['positive_rate']:.2%}")
        print(f"  True Positive Rate: {metrics['true_positive_rate']:.2%}")
```

### Bias Mitigation Strategies

**Pre-Processing (Fix Training Data):**
- Re-sample to balance demographic groups
- Re-weight examples to reduce bias
- Synthetic data generation

**In-Processing (Train Fair Models):**
- Add fairness constraints to objective function
- Adversarial debiasing
- Regularization for fairness

**Post-Processing (Adjust Predictions):**
- Calibrate predictions per group
- Adjust decision thresholds by group
- Reject predictions with high bias risk

**Example: Threshold Adjustment**

```python
def fair_threshold_classifier(model, X, sensitive_attr, fairness_metric="equal_opportunity"):
    """Adjust decision thresholds per group to achieve fairness"""

    # Get prediction probabilities
    probabilities = model.predict_proba(X)[:, 1]

    # Find optimal threshold per group
    thresholds = {}
    for group in np.unique(sensitive_attr):
        mask = sensitive_attr == group
        group_probs = probabilities[mask]

        # Optimize threshold for this group
        thresholds[group] = find_optimal_threshold(
            group_probs,
            fairness_metric=fairness_metric
        )

    # Apply group-specific thresholds
    predictions = np.zeros(len(X))
    for group, threshold in thresholds.items():
        mask = sensitive_attr == group
        predictions[mask] = (probabilities[mask] >= threshold).astype(int)

    return predictions
```

---

## Transparency and Explainability

### Model Documentation

**Model Card Template:**

```markdown
# Model Card: [Model Name]

## Model Details
- **Model Type:** Gradient Boosting Classifier
- **Version:** 2.1.0
- **Date:** 2025-12-13
- **Developers:** Data Science Team
- **License:** Internal Use Only

## Intended Use
- **Primary Uses:** Customer churn prediction
- **Primary Users:** Customer success team
- **Out-of-Scope Uses:** Credit decisions, hiring, legal judgments

## Training Data
- **Datasets:** Customer interaction logs (2023-2025)
- **Size:** 1.2M customers
- **Preprocessing:** Anonymized, 90-day retention

## Performance
- **Overall Accuracy:** 87%
- **AUC-ROC:** 0.91
- **Evaluated On:** Holdout test set (20% of data, stratified by demographics)

## Fairness Evaluation
- **Demographic Parity:** Passes 80% rule across gender and age groups
- **Equal Opportunity:** TPR within 5% across all groups
- **Mitigation:** Post-processing threshold adjustment

## Limitations
- Lower accuracy for new customers (< 30 days tenure)
- Requires minimum 10 interaction events
- Not validated for B2B customers

## Ethical Considerations
- Predictions used to prioritize outreach, not deny service
- Human review required before account actions
- Monthly fairness audits conducted
```

---

## Privacy and Data Protection

### Data Minimization

**Principle:** Collect only the data you need.

**Checklist:**
- [ ] Document why each feature is necessary
- [ ] Remove features with minimal predictive value
- [ ] Use aggregated/anonymized data where possible
- [ ] Implement automatic data deletion

### Differential Privacy

**Technique:** Add noise to protect individual privacy.

```python
import numpy as np

def laplace_mechanism(value: float, sensitivity: float, epsilon: float) -> float:
    """
    Add Laplace noise for differential privacy

    Args:
        value: True value to protect
        sensitivity: Maximum change from adding/removing one record
        epsilon: Privacy budget (smaller = more privacy)

    Returns:
        Noisy value that preserves differential privacy
    """
    scale = sensitivity / epsilon
    noise = np.random.laplace(0, scale)
    return value + noise

# Example: Release aggregate statistics with privacy
def private_average_age(ages: list, epsilon: float = 0.1) -> float:
    """Calculate average age with differential privacy"""
    true_avg = np.mean(ages)
    sensitivity = 100.0  # Max age in range
    return laplace_mechanism(true_avg, sensitivity, epsilon)
```

---

## Accountability and Oversight

### AI Ethics Review Board

**Purpose:** Provide oversight and governance for AI projects.

**Composition:**
- Technical experts (data scientists, engineers)
- Domain experts (business stakeholders)
- Ethics experts (ethicists, legal, compliance)
- Diverse representation (various perspectives)

**Responsibilities:**
- Review high-risk AI projects before deployment
- Approve ethical guidelines and policies
- Investigate ethics complaints
- Conduct regular audits
- Recommend policy updates

### Review Process

**Required for Ethics Review:**
- ✅ AI systems making decisions about people
- ✅ Use of sensitive personal data
- ✅ High-stakes domains (healthcare, finance, criminal justice)
- ✅ Public-facing AI systems
- ✅ Novel or experimental AI techniques

**Review Template:**

```yaml
# AI Ethics Review Request

Project: Customer Churn Prediction Model
Submission Date: 2025-12-13
Team: Data Science - Customer Success

Risk Assessment:
  Impact Level: Medium
  User Impact: Affects customer outreach prioritization
  Data Sensitivity: Medium (behavioral data, no financial/health)
  Decision Type: Recommendation (human-in-the-loop)

Ethical Considerations:
  Fairness:
    - Tested across gender, age, geography
    - Passes 80% rule for statistical parity
    - Equal opportunity within 5% across groups

  Transparency:
    - Model card published internally
    - SHAP explanations available per prediction
    - Customer success team trained on limitations

  Privacy:
    - Data anonymized (no PII)
    - 90-day retention policy
    - Compliant with GDPR/CCPA

  Safety:
    - Model monitored for drift
    - Human review required for high-value customers
    - Incident response plan documented

Mitigation Measures:
  - Monthly fairness audits
  - Quarterly model retraining with bias assessment
  - Customer opt-out mechanism
  - Regular stakeholder feedback

Approval Status: [PENDING REVIEW]
Reviewers: [Ethics Board Members]
```

---

## Safety and Security

### Adversarial Robustness

**Threat:** Attackers manipulate inputs to fool the model.

```python
def detect_adversarial_input(input_features: dict, model) -> bool:
    """Detect potentially adversarial inputs"""

    # Check for out-of-distribution inputs
    if is_out_of_distribution(input_features):
        log_security_event("Out-of-distribution input detected")
        return True

    # Check for suspicious patterns
    if has_suspicious_patterns(input_features):
        log_security_event("Suspicious input pattern detected")
        return True

    # Check prediction confidence
    prediction_prob = model.predict_proba([input_features])[0].max()
    if prediction_prob < 0.5:  # Uncertainty suggests adversarial
        log_security_event("Low confidence prediction, possible attack")
        return True

    return False
```

### Model Security

**Best Practices:**
- Don't expose model internals via API
- Rate limit predictions to prevent model extraction
- Log all predictions for audit trail
- Monitor for unusual prediction patterns
- Implement input validation
- Use secure model serving infrastructure

---

## Governance Framework

### AI Lifecycle Governance

```mermaid
Development → Ethics Review → Testing → Approval → Deployment → Monitoring → Audit
```

**Stage 1: Development**
- Document intended use and limitations
- Assess bias and fairness risks
- Privacy impact assessment

**Stage 2: Ethics Review**
- Submit to ethics board (if high-risk)
- Address review feedback
- Obtain approval before deployment

**Stage 3: Testing**
- Fairness testing across demographics
- Adversarial robustness testing
- Performance validation

**Stage 4: Deployment**
- Publish model card
- Implement monitoring
- Train users on limitations

**Stage 5: Monitoring**
- Continuous fairness monitoring
- Model drift detection
- Incident tracking

**Stage 6: Audit**
- Regular compliance audits
- Fairness audits
- Security assessments
- Update governance based on findings

---

## Compliance and Regulations

### Key Regulations

**GDPR (European Union):**
- Right to explanation for automated decisions
- Data minimization requirements
- Consent for data processing
- Right to be forgotten

**CCPA (California):**
- Disclosure of data collection
- Opt-out mechanisms
- Data deletion rights

**AI-Specific Regulations:**
- EU AI Act (risk-based approach)
- Algorithmic accountability laws
- Sector-specific regulations (finance, healthcare)

### Compliance Checklist

```yaml
GDPR Compliance:
  - [ ] Lawful basis for data processing documented
  - [ ] Privacy notice provided to users
  - [ ] Consent mechanism implemented (where required)
  - [ ] Data subject rights enabled (access, deletion, portability)
  - [ ] Automated decision-making disclosed
  - [ ] DPIA conducted for high-risk processing

Ethical AI:
  - [ ] Fairness assessment completed
  - [ ] Bias mitigation implemented
  - [ ] Explainability requirements met
  - [ ] Human oversight defined
  - [ ] Incident response plan documented
  - [ ] Regular audits scheduled
```

---

## Related Resources

- See `base/testing-philosophy.md` for ML testing strategies
- See `base/ai-model-lifecycle.md` for model management
- See `base/metrics-standards.md` for monitoring fairness metrics
- See `cloud/*/security-practices.md` for security best practices

---

**Remember:** AI ethics is not a checkbox exercise. It requires continuous vigilance, regular audits, and genuine commitment to responsible AI practices throughout the entire lifecycle.
