# AWS Well-Architected Framework for ML Workloads

> **When to apply:** All AWS-based ML/AI applications and infrastructure

Apply AWS Well-Architected Framework principles to machine learning workloads across six pillars: Operational Excellence, Security, Reliability, Performance Efficiency, Cost Optimization, and Sustainability.

## ML-Specific Considerations

- **Data-intensive:** Large datasets for training
- **Compute-intensive:** GPU/specialized hardware requirements
- **Model lifecycle:** Training, deployment, monitoring, retraining
- **Experimentation:** Multiple model versions, A/B testing
- **Drift detection:** Model and data drift monitoring

## Operational Excellence

### Rules

1. **Automate ML pipelines** using SageMaker Pipelines or Step Functions for training, evaluation, and deployment
2. **Track experiments** with SageMaker Experiments - log parameters, metrics, and artifacts for every run
3. **Monitor model performance** with CloudWatch - track accuracy, latency, and drift metrics
4. **Implement CI/CD for ML** - automate model deployment with version control

### Implementation

**SageMaker Pipeline:**
```python
from sagemaker.workflow.pipeline import Pipeline
from sagemaker.workflow.steps import TrainingStep, ProcessingStep

# Define processing and training steps
processing_step = ProcessingStep(name="PreprocessData", ...)
training_step = TrainingStep(name="TrainModel", ...)

# Create and execute pipeline
pipeline = Pipeline(
    name="ml-training-pipeline",
    steps=[processing_step, training_step]
)
pipeline.upsert(role_arn=role_arn)
pipeline.start()
```

**CloudWatch Monitoring:**
```python
import boto3

cloudwatch = boto3.client('cloudwatch')

def log_model_metrics(model_version: str, accuracy: float, latency_ms: float):
    cloudwatch.put_metric_data(
        Namespace='MLModels',
        MetricData=[
            {
                'MetricName': 'ModelAccuracy',
                'Value': accuracy,
                'Unit': 'Percent',
                'Dimensions': [{'Name': 'ModelVersion', 'Value': model_version}]
            },
            {
                'MetricName': 'InferenceLatency',
                'Value': latency_ms,
                'Unit': 'Milliseconds',
                'Dimensions': [{'Name': 'ModelVersion', 'Value': model_version}]
            }
        ]
    )
```

**Experiment Tracking:**
```python
from sagemaker.experiments import Run

with Run(experiment_name="model-optimization", run_name="hpo-001") as run:
    run.log_parameters({"learning_rate": 0.001, "batch_size": 32})
    model = train_model(...)
    run.log_metric("accuracy", 0.95)
    run.log_artifact("model.pkl", is_output=True)
```

## Security

### Rules

1. **Encrypt all data** at rest (S3, EBS) and in transit (TLS/HTTPS)
2. **Use least privilege IAM policies** - grant minimum required permissions
3. **Enable audit logging** with CloudTrail for all API calls
4. **Secure model artifacts** in encrypted S3 with KMS
5. **Validate inputs** to prevent injection attacks

### Implementation

**S3 Encryption:**
```python
s3 = boto3.client('s3')

# Upload with KMS encryption
s3.put_object(
    Bucket='ml-models',
    Key='model-v1.0.0.pkl',
    Body=model_bytes,
    ServerSideEncryption='aws:kms',
    SSEKMSKeyId='arn:aws:kms:region:account:key/key-id'
)

# Enable default bucket encryption
s3.put_bucket_encryption(
    Bucket='ml-training-data',
    ServerSideEncryptionConfiguration={
        'Rules': [{'ApplyServerSideEncryptionByDefault': {'SSEAlgorithm': 'AES256'}}]
    }
)
```

**Least Privilege IAM Policy:**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["s3:GetObject", "s3:PutObject"],
      "Resource": ["arn:aws:s3:::ml-training-data/*", "arn:aws:s3:::ml-models/*"]
    },
    {
      "Effect": "Allow",
      "Action": ["sagemaker:CreateTrainingJob", "sagemaker:DescribeTrainingJob"],
      "Resource": "arn:aws:sagemaker:*:*:training-job/ml-*"
    }
  ]
}
```

**VPC Model Deployment:**
```python
model = Model(
    model_data='s3://ml-models/model.tar.gz',
    role=role_arn,
    image_uri=image_uri,
    vpc_config={'SecurityGroupIds': ['sg-xxx'], 'Subnets': ['subnet-xxx']}
)

predictor = model.deploy(
    instance_type='ml.m5.large',
    initial_instance_count=1,
    kms_key_id='arn:aws:kms:region:account:key/key-id'
)
```

## Reliability

### Rules

1. **Version model artifacts** in S3 for rollback capability
2. **Implement blue-green or canary deployments** for safe model updates
3. **Monitor for drift** using SageMaker Model Monitor
4. **Auto-scale endpoints** based on traffic
5. **Test model resilience** before production

### Implementation

**Blue-Green Deployment:**
```python
# Deploy new version
green_endpoint = new_model.deploy(endpoint_name='ml-model-green', ...)

# Validate
if validate_model(green_endpoint)['accuracy'] >= 0.95:
    update_endpoint_weights(blue_weight=0, green_weight=100)
else:
    green_endpoint.delete_endpoint()  # Rollback
```

**Canary Deployment:**
```python
sagemaker.update_endpoint_weights_and_capacities(
    EndpointName='ml-model-production',
    DesiredWeightsAndCapacities=[
        {'VariantName': 'v1', 'DesiredWeight': 90.0},  # Old
        {'VariantName': 'v2', 'DesiredWeight': 10.0}   # New (canary)
    ]
)
```

**Drift Detection:**
```python
from sagemaker.model_monitor import DefaultModelMonitor, DataCaptureConfig

# Enable data capture
predictor.update_data_capture_config(DataCaptureConfig(
    enable_capture=True,
    sampling_percentage=100,
    destination_s3_uri='s3://ml-monitoring/data-capture'
))

# Create baseline
monitor = DefaultModelMonitor(role=role, instance_type='ml.m5.xlarge')
baseline_job = monitor.suggest_baseline(
    baseline_dataset='s3://ml-training-data/baseline.csv',
    output_s3_uri='s3://ml-monitoring/baseline'
)

# Schedule monitoring
monitor.create_monitoring_schedule(
    endpoint_name='ml-model-production',
    statistics=baseline_job.baseline_statistics(),
    constraints=baseline_job.suggested_constraints(),
    schedule_cron_expression='rate(1 hour)'
)
```

## Performance Efficiency

### Rules

1. **Right-size instances** - match compute to workload requirements
2. **Use GPU efficiently** - batch inference, optimize utilization
3. **Optimize model size** - quantization, pruning for faster inference
4. **Cache predictions** to reduce redundant computation
5. **Auto-scale horizontally** for variable load

### Instance Selection

**Training:**
- Small datasets (<1GB): `ml.m5.xlarge`
- Medium datasets (1-10GB): `ml.c5.4xlarge`
- Large datasets (>10GB, DL): `ml.p3.8xlarge`
- Distributed training: `ml.p3dn.24xlarge`

**Inference:**
- Low latency CPU: `ml.c5.xlarge`
- Batch inference: `ml.inf1.xlarge` (Inferentia)
- GPU inference: `ml.g4dn.xlarge`
- Multi-model hosting: `ml.m5.large`

### Implementation

**Model Quantization:**
```python
import torch

model = torch.load('model.pth')

# Dynamic quantization (int8)
quantized_model = torch.quantization.quantize_dynamic(
    model, {torch.nn.Linear}, dtype=torch.qint8
)

torch.save(quantized_model.state_dict(), 'model_quantized.pth')  # 75% smaller
```

**Auto-Scaling:**
```python
autoscaling = boto3.client('application-autoscaling')

# Register target
autoscaling.register_scalable_target(
    ServiceNamespace='sagemaker',
    ResourceId='endpoint/ml-model-production/variant/AllTraffic',
    ScalableDimension='sagemaker:variant:DesiredInstanceCount',
    MinCapacity=1,
    MaxCapacity=10
)

# Scaling policy
autoscaling.put_scaling_policy(
    PolicyName='CPUUtilization-ScalingPolicy',
    ServiceNamespace='sagemaker',
    ResourceId='endpoint/ml-model-production/variant/AllTraffic',
    ScalableDimension='sagemaker:variant:DesiredInstanceCount',
    PolicyType='TargetTrackingScaling',
    TargetTrackingScalingPolicyConfiguration={
        'TargetValue': 70.0,
        'PredefinedMetricSpecification': {
            'PredefinedMetricType': 'SageMakerVariantInvocationsPerInstance'
        }
    }
)
```

## Cost Optimization

### Rules

1. **Use Spot instances for training** - 70% cost savings
2. **Implement S3 lifecycle policies** - move old data to cheaper storage
3. **Right-size resources** - avoid over-provisioning
4. **Monitor costs** with AWS Budgets and Cost Explorer
5. **Auto-scale to demand** - scale down during low traffic

### Implementation

**Spot Instance Training:**
```python
estimator = Estimator(
    image_uri=image_uri,
    role=role,
    instance_type='ml.p3.2xlarge',
    use_spot_instances=True,
    max_wait=7200,
    max_run=3600,
    checkpoint_s3_uri='s3://ml-checkpoints/',
    checkpoint_local_path='/opt/ml/checkpoints'
)

estimator.fit('s3://ml-training-data/')  # Auto-resumes from checkpoints
```

**S3 Lifecycle Policy:**
```python
s3.put_bucket_lifecycle_configuration(
    Bucket='ml-training-data',
    LifecycleConfiguration={
        'Rules': [{
            'Id': 'ArchiveOldData',
            'Status': 'Enabled',
            'Transitions': [
                {'Days': 30, 'StorageClass': 'STANDARD_IA'},
                {'Days': 90, 'StorageClass': 'GLACIER'}
            ],
            'Expiration': {'Days': 365}
        }]
    }
)
```

**Cost Monitoring:**
```python
budgets = boto3.client('budgets')

budgets.create_budget(
    AccountId='123456789',
    Budget={
        'BudgetName': 'ML-Monthly-Budget',
        'BudgetLimit': {'Amount': '1000', 'Unit': 'USD'},
        'TimeUnit': 'MONTHLY',
        'BudgetType': 'COST',
        'CostFilters': {'Service': ['Amazon SageMaker', 'Amazon S3']}
    },
    NotificationsWithSubscribers=[{
        'Notification': {
            'NotificationType': 'ACTUAL',
            'ComparisonOperator': 'GREATER_THAN',
            'Threshold': 80,
            'ThresholdType': 'PERCENTAGE'
        },
        'Subscribers': [{'SubscriptionType': 'EMAIL', 'Address': 'ml-team@example.com'}]
    }]
)
```

## Sustainability

### Rules

1. **Optimize model efficiency** - smaller, faster models reduce energy
2. **Use efficient instances** - Graviton processors, Inferentia chips
3. **Minimize data movement** - co-locate compute and storage
4. **Enable auto-shutdown** for idle resources
5. **Schedule training** during off-peak hours when grid carbon is lower

### Implementation

**Distributed Training (faster = less energy):**
```python
estimator = PyTorch(
    entry_point='train.py',
    instance_count=4,
    instance_type='ml.p3.8xlarge',
    distribution={'smdistributed': {'dataparallel': {'enabled': True}}}
)
```

**Mixed Precision Training:**
```python
from torch.cuda.amp import autocast, GradScaler

scaler = GradScaler()

for batch in dataloader:
    with autocast():  # Automatic mixed precision (FP16/FP32)
        output = model(batch)
        loss = criterion(output, target)
    scaler.scale(loss).backward()
    scaler.step(optimizer)
    scaler.update()
```

## Best Practices Checklist

### Operational Excellence
- [ ] Automate ML pipelines with SageMaker Pipelines
- [ ] Track experiments with SageMaker Experiments
- [ ] Monitor models with CloudWatch and Model Monitor
- [ ] Implement CI/CD for model deployment

### Security
- [ ] Encrypt data at rest (S3, EBS) and in transit (TLS)
- [ ] Use least privilege IAM policies
- [ ] Deploy models in VPC with security groups
- [ ] Enable CloudTrail logging

### Reliability
- [ ] Version model artifacts in S3
- [ ] Implement blue-green or canary deployments
- [ ] Monitor for model and data drift
- [ ] Configure auto-scaling for endpoints

### Performance Efficiency
- [ ] Right-size training and inference instances
- [ ] Use GPU instances for deep learning
- [ ] Optimize models (quantization, pruning)
- [ ] Implement caching and batching

### Cost Optimization
- [ ] Use Spot instances for training (70% savings)
- [ ] Configure S3 lifecycle policies
- [ ] Right-size instances, scale to demand
- [ ] Monitor costs with AWS Budgets

### Sustainability
- [ ] Optimize model size and training time
- [ ] Use efficient instances (Graviton, Inferentia)
- [ ] Schedule training during off-peak hours
- [ ] Auto-shutdown idle resources

## Related Resources

- AWS Well-Architected Tool: https://aws.amazon.com/well-architected-tool/
- ML Lens Whitepaper: https://docs.aws.amazon.com/wellarchitected/latest/machine-learning-lens/
- See `base/12-factor-app.md` for application architecture
- See `cloud/aws/iam-best-practices.md` for IAM security
