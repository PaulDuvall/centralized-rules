# AWS Well-Architected Framework for ML Workloads

> **When to apply:** All AWS-based ML/AI applications and infrastructure

Comprehensive guide to applying AWS Well-Architected Framework principles to machine learning and AI workloads.

## Table of Contents

- [Framework Overview](#framework-overview)
- [Operational Excellence](#operational-excellence)
- [Security](#security)
- [Reliability](#reliability)
- [Performance Efficiency](#performance-efficiency)
- [Cost Optimization](#cost-optimization)
- [Sustainability](#sustainability)

---

## Framework Overview

### The Six Pillars

AWS Well-Architected Framework provides best practices across six pillars, with specific considerations for ML workloads:

1. **Operational Excellence** - Run and monitor systems
2. **Security** - Protect data and systems
3. **Reliability** - Recover from failures
4. **Performance Efficiency** - Use resources efficiently
5. **Cost Optimization** - Avoid unnecessary costs
6. **Sustainability** - Minimize environmental impact

### ML-Specific Considerations

Machine learning workloads have unique requirements:
- **Data-intensive** - Large datasets for training
- **Compute-intensive** - GPU/specialized hardware
- **Model lifecycle** - Training, deployment, monitoring, retraining
- **Experimentation** - Multiple model versions, A/B testing
- **Drift detection** - Model and data drift over time

---

## Operational Excellence

### Design Principles

1. **Automate ML pipelines** - Training, evaluation, deployment
2. **Monitor model performance** - Track metrics, detect drift
3. **Document experiments** - Track hyperparameters, results
4. **Implement CI/CD for ML** - Automated model deployment
5. **Enable rapid iteration** - Quick experiment cycles

### ML Pipeline Automation

**Use AWS Services:**
- **SageMaker Pipelines** - Orchestrate ML workflows
- **Step Functions** - Complex workflow orchestration
- **Lambda** - Serverless data processing
- **EventBridge** - Event-driven automation

**Example: Automated Training Pipeline**

```python
import boto3
from sagemaker.workflow.pipeline import Pipeline
from sagemaker.workflow.steps import TrainingStep, ProcessingStep
from sagemaker.workflow.parameters import ParameterString

# Define pipeline parameters
training_data = ParameterString(
    name="TrainingData",
    default_value="s3://ml-bucket/training-data"
)

# Data processing step
from sagemaker.processing import ScriptProcessor

processor = ScriptProcessor(
    image_uri="python:3.9",
    role="arn:aws:iam::123456789:role/SageMakerRole",
    instance_count=1,
    instance_type="ml.m5.xlarge"
)

processing_step = ProcessingStep(
    name="PreprocessData",
    processor=processor,
    code="preprocess.py",
    inputs=[...],
    outputs=[...]
)

# Model training step
from sagemaker.estimator import Estimator

estimator = Estimator(
    image_uri="763104351884.dkr.ecr.us-west-2.amazonaws.com/pytorch-training:latest",
    role="arn:aws:iam::123456789:role/SageMakerRole",
    instance_count=1,
    instance_type="ml.p3.2xlarge"
)

training_step = TrainingStep(
    name="TrainModel",
    estimator=estimator,
    inputs={
        "training": processing_step.properties.ProcessingOutputConfig.Outputs["train"].S3Output.S3Uri
    }
)

# Create pipeline
pipeline = Pipeline(
    name="ml-training-pipeline",
    parameters=[training_data],
    steps=[processing_step, training_step]
)

# Execute pipeline
pipeline.upsert(role_arn="arn:aws:iam::123456789:role/SageMakerRole")
execution = pipeline.start()
```

### Model Monitoring

**CloudWatch Integration:**

```python
import boto3

cloudwatch = boto3.client('cloudwatch')

def log_model_metrics(model_version: str, accuracy: float, latency_ms: float):
    """Log model performance metrics to CloudWatch"""
    cloudwatch.put_metric_data(
        Namespace='MLModels',
        MetricData=[
            {
                'MetricName': 'ModelAccuracy',
                'Value': accuracy,
                'Unit': 'Percent',
                'Dimensions': [
                    {'Name': 'ModelVersion', 'Value': model_version}
                ]
            },
            {
                'MetricName': 'InferenceLatency',
                'Value': latency_ms,
                'Unit': 'Milliseconds',
                'Dimensions': [
                    {'Name': 'ModelVersion', 'Value': model_version}
                ]
            }
        ]
    )

# Create alarms
cloudwatch.put_metric_alarm(
    AlarmName='ModelAccuracyDegraded',
    ComparisonOperator='LessThanThreshold',
    EvaluationPeriods=2,
    MetricName='ModelAccuracy',
    Namespace='MLModels',
    Period=300,
    Statistic='Average',
    Threshold=90.0,
    ActionsEnabled=True,
    AlarmActions=['arn:aws:sns:us-west-2:123456789:ml-alerts']
)
```

### Experiment Tracking

**Use SageMaker Experiments:**

```python
from sagemaker.experiments import Run

with Run(
    experiment_name="model-optimization",
    run_name="hyperparameter-tuning-001",
    sagemaker_session=sagemaker_session
) as run:
    # Log parameters
    run.log_parameters({
        "learning_rate": 0.001,
        "batch_size": 32,
        "epochs": 10,
        "optimizer": "adam"
    })

    # Train model
    model = train_model(...)

    # Log metrics
    run.log_metric("accuracy", 0.95)
    run.log_metric("precision", 0.93)
    run.log_metric("recall", 0.94)

    # Log artifacts
    run.log_artifact("model.pkl", is_output=True)
```

---

## Security

### Design Principles

1. **Encrypt data** - At rest and in transit
2. **Implement least privilege** - Minimal IAM permissions
3. **Enable audit logging** - CloudTrail, access logs
4. **Secure model artifacts** - Protect trained models
5. **Validate inputs** - Prevent injection attacks

### Data Encryption

**S3 Encryption:**

```python
import boto3

s3 = boto3.client('s3')

# Server-side encryption with S3-managed keys
s3.put_object(
    Bucket='ml-training-data',
    Key='training-dataset.parquet',
    Body=data,
    ServerSideEncryption='AES256'
)

# Server-side encryption with KMS
s3.put_object(
    Bucket='ml-models',
    Key='model-v1.0.0.pkl',
    Body=model_bytes,
    ServerSideEncryption='aws:kms',
    SSEKMSKeyId='arn:aws:kms:us-west-2:123456789:key/abc123'
)

# Enable bucket encryption by default
s3.put_bucket_encryption(
    Bucket='ml-training-data',
    ServerSideEncryptionConfiguration={
        'Rules': [{
            'ApplyServerSideEncryptionByDefault': {
                'SSEAlgorithm': 'AES256'
            }
        }]
    }
)
```

### IAM Best Practices

**Least Privilege for SageMaker:**

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject"
      ],
      "Resource": [
        "arn:aws:s3:::ml-training-data/*",
        "arn:aws:s3:::ml-models/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "sagemaker:CreateTrainingJob",
        "sagemaker:DescribeTrainingJob"
      ],
      "Resource": "arn:aws:sagemaker:*:*:training-job/ml-*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:log-group:/aws/sagemaker/*"
    }
  ]
}
```

### Model Security

**Secure Model Deployment:**

```python
# VPC configuration for SageMaker endpoint
from sagemaker.model import Model

model = Model(
    model_data='s3://ml-models/model.tar.gz',
    role='arn:aws:iam::123456789:role/SageMakerRole',
    image_uri='763104351884.dkr.ecr.us-west-2.amazonaws.com/pytorch-inference:latest',
    vpc_config={
        'SecurityGroupIds': ['sg-12345678'],
        'Subnets': ['subnet-12345678', 'subnet-87654321']
    }
)

# Deploy with encryption
predictor = model.deploy(
    instance_type='ml.m5.large',
    initial_instance_count=1,
    kms_key_id='arn:aws:kms:us-west-2:123456789:key/abc123'
)
```

---

## Reliability

### Design Principles

1. **Implement fallback models** - Graceful degradation
2. **Version model artifacts** - Enable rollback
3. **Test model resilience** - Chaos engineering
4. **Monitor drift** - Detect model/data drift
5. **Automate recovery** - Self-healing systems

### Multi-Model Deployment

**Blue-Green Deployment:**

```python
from sagemaker.model import Model
from sagemaker.predictor import Predictor

# Deploy new model version (green)
new_model = Model(
    model_data='s3://ml-models/model-v2.0.0.tar.gz',
    role=role,
    image_uri=image_uri
)

green_endpoint = new_model.deploy(
    endpoint_name='ml-model-green',
    instance_type='ml.m5.large',
    initial_instance_count=2
)

# Test green endpoint
test_results = validate_model(green_endpoint)

if test_results['accuracy'] >= 0.95:
    # Switch traffic from blue to green
    update_endpoint_weights(
        blue_weight=0,
        green_weight=100
    )
else:
    # Rollback: delete green, keep blue
    green_endpoint.delete_endpoint()
```

### Canary Deployment:**

```python
import boto3

sagemaker = boto3.client('sagemaker')

# Update endpoint with traffic splitting
sagemaker.update_endpoint_weights_and_capacities(
    EndpointName='ml-model-production',
    DesiredWeightsAndCapacities=[
        {
            'VariantName': 'variant-1-v1',  # Old model
            'DesiredWeight': 90.0
        },
        {
            'VariantName': 'variant-2-v2',  # New model
            'DesiredWeight': 10.0
        }
    ]
)

# Monitor canary performance
import time

for _ in range(10):  # Monitor for 10 minutes
    metrics = get_variant_metrics('variant-2-v2')
    if metrics['error_rate'] > 0.05:
        # Rollback
        sagemaker.update_endpoint_weights_and_capacities(
            EndpointName='ml-model-production',
            DesiredWeightsAndCapacities=[
                {'VariantName': 'variant-1-v1', 'DesiredWeight': 100.0},
                {'VariantName': 'variant-2-v2', 'DesiredWeight': 0.0}
            ]
        )
        break
    time.sleep(60)
else:
    # Canary successful, full rollout
    sagemaker.update_endpoint_weights_and_capacities(
        EndpointName='ml-model-production',
        DesiredWeightsAndCapacities=[
            {'VariantName': 'variant-1-v1', 'DesiredWeight': 0.0},
            {'VariantName': 'variant-2-v2', 'DesiredWeight': 100.0}
        ]
    )
```

### Model Drift Detection

**SageMaker Model Monitor:**

```python
from sagemaker.model_monitor import DataCaptureConfig, ModelMonitor

# Enable data capture
data_capture_config = DataCaptureConfig(
    enable_capture=True,
    sampling_percentage=100,
    destination_s3_uri='s3://ml-monitoring/data-capture'
)

predictor.update_data_capture_config(data_capture_config)

# Create baseline
from sagemaker.model_monitor import DefaultModelMonitor

monitor = DefaultModelMonitor(
    role=role,
    instance_count=1,
    instance_type='ml.m5.xlarge',
    volume_size_in_gb=20,
    max_runtime_in_seconds=3600
)

baseline_job = monitor.suggest_baseline(
    baseline_dataset='s3://ml-training-data/baseline.csv',
    dataset_format={'csv': {'header': True}},
    output_s3_uri='s3://ml-monitoring/baseline',
    wait=True
)

# Schedule monitoring
from sagemaker.model_monitor import CronExpressionGenerator

monitor.create_monitoring_schedule(
    endpoint_name='ml-model-production',
    statistics=baseline_job.baseline_statistics(),
    constraints=baseline_job.suggested_constraints(),
    schedule_cron_expression=CronExpressionGenerator.hourly(),
    enable_cloudwatch_metrics=True
)
```

---

## Performance Efficiency

### Design Principles

1. **Right-size instances** - Match compute to workload
2. **Use GPU efficiently** - Batch inference, multi-model
3. **Optimize model size** - Quantization, pruning
4. **Cache predictions** - Reduce redundant inference
5. **Scale horizontally** - Auto-scaling for inference

### Instance Selection

**Training Instances:**

| Workload Type | Instance Type | Use Case |
|---------------|--------------|----------|
| Small datasets | ml.m5.xlarge | <1GB data, simple models |
| Medium datasets | ml.c5.4xlarge | 1-10GB data, CPU training |
| Large datasets | ml.p3.8xlarge | >10GB data, deep learning |
| Distributed | ml.p3dn.24xlarge | Multi-GPU, large models |

**Inference Instances:**

| Requirement | Instance Type | Use Case |
|-------------|--------------|----------|
| Low latency | ml.c5.xlarge | Real-time CPU inference |
| High throughput | ml.inf1.xlarge | Batch inference with Inferentia |
| GPU inference | ml.g4dn.xlarge | Deep learning inference |
| Multi-model | ml.m5.large | Hosting multiple models |

### Model Optimization

**Quantization:**

```python
import torch

# Convert float32 model to int8
model = torch.load('model.pth')

# Dynamic quantization
quantized_model = torch.quantization.quantize_dynamic(
    model,
    {torch.nn.Linear},
    dtype=torch.qint8
)

# Save quantized model (75% smaller)
torch.save(quantized_model.state_dict(), 'model_quantized.pth')
```

**Model Pruning:**

```python
import torch.nn.utils.prune as prune

# Prune 30% of weights
for module in model.modules():
    if isinstance(module, torch.nn.Linear):
        prune.l1_unstructured(module, name='weight', amount=0.3)

# Make pruning permanent
for module in model.modules():
    if isinstance(module, torch.nn.Linear):
        prune.remove(module, 'weight')
```

### Auto-Scaling

**SageMaker Endpoint Auto-Scaling:**

```python
import boto3

autoscaling = boto3.client('application-autoscaling')

# Register scalable target
autoscaling.register_scalable_target(
    ServiceNamespace='sagemaker',
    ResourceId='endpoint/ml-model-production/variant/AllTraffic',
    ScalableDimension='sagemaker:variant:DesiredInstanceCount',
    MinCapacity=1,
    MaxCapacity=10
)

# Configure scaling policy
autoscaling.put_scaling_policy(
    PolicyName='CPUUtilization-ScalingPolicy',
    ServiceNamespace='sagemaker',
    ResourceId='endpoint/ml-model-production/variant/AllTraffic',
    ScalableDimension='sagemaker:variant:DesiredInstanceCount',
    PolicyType='TargetTrackingScaling',
    TargetTrackingScalingPolicyConfiguration={
        'TargetValue': 70.0,  # Target 70% CPU utilization
        'PredefinedMetricSpecification': {
            'PredefinedMetricType': 'SageMakerVariantInvocationsPerInstance'
        },
        'ScaleInCooldown': 300,  # 5 minutes
        'ScaleOutCooldown': 60    # 1 minute
    }
)
```

---

## Cost Optimization

### Design Principles

1. **Use Spot instances** - Training on spot for 70% savings
2. **Optimize storage** - Lifecycle policies, compression
3. **Right-size resources** - Match instance type to workload
4. **Monitor costs** - Track spending, set budgets
5. **Implement auto-scaling** - Scale to demand

### Spot Instances for Training

**SageMaker Managed Spot:**

```python
from sagemaker.estimator import Estimator

estimator = Estimator(
    image_uri=image_uri,
    role=role,
    instance_count=1,
    instance_type='ml.p3.2xlarge',
    use_spot_instances=True,  # Use spot instances
    max_wait=7200,  # Max wait time (2 hours)
    max_run=3600,   # Max training time (1 hour)
    checkpoint_s3_uri='s3://ml-checkpoints/',  # Save checkpoints
    checkpoint_local_path='/opt/ml/checkpoints'
)

# Training will automatically resume from checkpoints if interrupted
estimator.fit('s3://ml-training-data/')
```

**Cost Savings:**

```
On-Demand ml.p3.2xlarge: $3.06/hour
Spot ml.p3.2xlarge: ~$0.92/hour (70% savings)
10-hour training job savings: $21.40
```

### S3 Lifecycle Policies

**Intelligent Tiering:**

```python
import boto3

s3 = boto3.client('s3')

# Configure lifecycle policy
s3.put_bucket_lifecycle_configuration(
    Bucket='ml-training-data',
    LifecycleConfiguration={
        'Rules': [
            {
                'Id': 'ArchiveOldData',
                'Status': 'Enabled',
                'Transitions': [
                    {
                        'Days': 30,
                        'StorageClass': 'STANDARD_IA'  # Infrequent Access
                    },
                    {
                        'Days': 90,
                        'StorageClass': 'GLACIER'  # Archive
                    }
                ],
                'Expiration': {
                    'Days': 365  # Delete after 1 year
                }
            }
        ]
    }
)
```

### Cost Monitoring

**AWS Budgets:**

```python
import boto3

budgets = boto3.client('budgets')

budgets.create_budget(
    AccountId='123456789',
    Budget={
        'BudgetName': 'ML-Monthly-Budget',
        'BudgetLimit': {
            'Amount': '1000',
            'Unit': 'USD'
        },
        'TimeUnit': 'MONTHLY',
        'BudgetType': 'COST',
        'CostFilters': {
            'Service': ['Amazon SageMaker', 'Amazon S3']
        }
    },
    NotificationsWithSubscribers=[
        {
            'Notification': {
                'NotificationType': 'ACTUAL',
                'ComparisonOperator': 'GREATER_THAN',
                'Threshold': 80,  # Alert at 80% of budget
                'ThresholdType': 'PERCENTAGE'
            },
            'Subscribers': [
                {
                    'SubscriptionType': 'EMAIL',
                    'Address': 'ml-team@example.com'
                }
            ]
        }
    ]
)
```

---

## Sustainability

### Design Principles

1. **Optimize model efficiency** - Smaller, faster models
2. **Use efficient instances** - Graviton processors
3. **Minimize data movement** - Co-locate compute and data
4. **Enable auto-shutdown** - Stop idle resources
5. **Monitor carbon footprint** - Track energy usage

### Efficient Model Training

**Reduce Training Time:**

```python
# Use distributed training
from sagemaker.pytorch import PyTorch

estimator = PyTorch(
    entry_point='train.py',
    role=role,
    instance_count=4,  # Distributed across 4 instances
    instance_type='ml.p3.8xlarge',
    framework_version='1.12',
    distribution={
        'smdistributed': {
            'dataparallel': {
                'enabled': True
            }
        }
    }
)

# Mixed precision training (faster, less energy)
# In train.py:
from torch.cuda.amp import autocast, GradScaler

scaler = GradScaler()

for batch in dataloader:
    with autocast():
        output = model(batch)
        loss = criterion(output, target)

    scaler.scale(loss).backward()
    scaler.step(optimizer)
    scaler.update()
```

### Carbon-Aware Scheduling

**Schedule training in low-carbon regions:**

```python
import boto3
from datetime import datetime, time

def get_low_carbon_region():
    """Get AWS region with lowest current carbon intensity"""
    # Use WattTime API or similar
    carbon_data = get_carbon_intensity_data()
    return min(carbon_data, key=lambda x: x['carbon_intensity'])['region']

def schedule_training_job(training_script: str):
    """Schedule training in optimal region/time"""
    region = get_low_carbon_region()

    sagemaker = boto3.client('sagemaker', region_name=region)

    # Schedule for off-peak hours (lower grid carbon)
    current_hour = datetime.now().hour
    if current_hour >= 22 or current_hour <= 6:
        # Run immediately during off-peak
        start_training_job(sagemaker, training_script)
    else:
        # Schedule for later
        schedule_for_off_peak(training_script)
```

---

## Best Practices Summary

### Operational Excellence
- ✅ Automate ML pipelines with SageMaker Pipelines
- ✅ Track experiments with SageMaker Experiments
- ✅ Monitor models with CloudWatch and Model Monitor
- ✅ Implement CI/CD for model deployment

### Security
- ✅ Encrypt data at rest (S3, EBS) and in transit (TLS)
- ✅ Use least privilege IAM policies
- ✅ Deploy models in VPC with security groups
- ✅ Enable CloudTrail logging for audit

### Reliability
- ✅ Version model artifacts in S3
- ✅ Implement blue-green or canary deployments
- ✅ Monitor for model and data drift
- ✅ Configure auto-scaling for endpoints

### Performance Efficiency
- ✅ Right-size training and inference instances
- ✅ Use GPU instances for deep learning
- ✅ Optimize models (quantization, pruning)
- ✅ Implement caching and batching

### Cost Optimization
- ✅ Use Spot instances for training (70% savings)
- ✅ Configure S3 lifecycle policies
- ✅ Right-size instances, scale to demand
- ✅ Monitor costs with AWS Budgets

### Sustainability
- ✅ Optimize model size and training time
- ✅ Use efficient instances (Graviton, Inferentia)
- ✅ Schedule training during off-peak hours
- ✅ Auto-shutdown idle resources

---

## Related Resources

- **AWS Well-Architected Tool:** https://aws.amazon.com/well-architected-tool/
- **ML Lens Whitepaper:** https://docs.aws.amazon.com/wellarchitected/latest/machine-learning-lens/
- See `base/12-factor-app.md` for application architecture
- See `base/architecture-principles.md` for design principles
- See `cloud/aws/iam-best-practices.md` for IAM security
