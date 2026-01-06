# AWS Security Best Practices

> **When to apply:** All AWS-based applications and infrastructure

Comprehensive security guidelines for AWS workloads covering IAM, secrets management, OIDC authentication, network security, data protection, monitoring, and AI/ML security.

## IAM Best Practices

### Rules

1. **Grant least privilege** - minimum permissions required for each task
2. **Use IAM roles, not access keys** - for all AWS infrastructure (EC2, ECS, Lambda)
3. **Require MFA** for all human users and privileged operations
4. **Use policy conditions** for fine-grained control (IP, time, MFA, tags)
5. **Rotate credentials** every 90 days; prefer temporary credentials
6. **Apply Service Control Policies (SCPs)** for organization-wide guardrails

### Implementation

**Least Privilege Policy:**
```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Action": ["s3:GetObject", "s3:PutObject"],
    "Resource": "arn:aws:s3:::my-bucket/uploads/*"
  }]
}
```

**Enforce MFA:**
```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Deny",
    "Action": "*",
    "Resource": "*",
    "Condition": {
      "BoolIfExists": {"aws:MultiFactorAuthPresent": "false"}
    }
  }]
}
```

**Fine-Grained Conditions:**
```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Action": "s3:*",
    "Resource": "arn:aws:s3:::my-bucket/*",
    "Condition": {
      "IpAddress": {"aws:SourceIp": "203.0.113.0/24"},
      "StringEquals": {"s3:x-amz-server-side-encryption": "AES256"}
    }
  }]
}
```

**Service Control Policy (SCP):**
```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Deny",
    "Action": "ec2:RunInstances",
    "Resource": "*",
    "Condition": {
      "StringNotEquals": {
        "ec2:InstanceType": ["t3.micro", "t3.small", "t3.medium"]
      }
    }
  }]
}
```

## Secrets Management

### Rules

1. **Never commit secrets** to code or version control
2. **Store secrets** in AWS Secrets Manager or Parameter Store
3. **Rotate secrets automatically** every 30-90 days
4. **Use IAM roles** to access secrets, not hardcoded credentials
5. **Encrypt secrets** with KMS keys

### Implementation

**Store Secret:**
```bash
# Secrets Manager
aws secretsmanager create-secret \
  --name prod/myapp/database \
  --secret-string '{"username":"admin","password":"SuperSecret123!"}' \
  --rotation-lambda-arn arn:aws:lambda:region:account:function:RotationFunction \
  --rotation-rules AutomaticallyAfterDays=30
```

**Retrieve Secret:**
```python
import boto3
import json

def get_secret(secret_name, region="us-east-1"):
    client = boto3.client('secretsmanager', region_name=region)
    response = client.get_secret_value(SecretId=secret_name)
    return json.loads(response['SecretString'])

# Usage
db_creds = get_secret('prod/myapp/database')
db_url = f"postgresql://{db_creds['username']}:{db_creds['password']}@host/db"
```

**Parameter Store (for non-sensitive config):**
```bash
# Standard parameter (free)
aws ssm put-parameter \
  --name /myapp/prod/api-endpoint \
  --value "https://api.example.com" \
  --type String

# Secure parameter (encrypted)
aws ssm put-parameter \
  --name /myapp/prod/database-password \
  --value "SuperSecret123!" \
  --type SecureString \
  --key-id alias/aws/ssm
```

```python
import boto3

ssm = boto3.client('ssm')

def get_parameter(name, decrypt=True):
    response = ssm.get_parameter(Name=name, WithDecryption=decrypt)
    return response['Parameter']['Value']
```

## OIDC for GitHub Actions

### Rules

1. **Use OIDC instead of long-lived credentials** for CI/CD
2. **Restrict OIDC trust policies** by repository, branch, or environment
3. **Apply least privilege** to OIDC role permissions
4. **Use external IDs** for cross-account access

### Implementation

**Create OIDC Provider:**
```bash
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com \
  --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1
```

**Trust Policy (restrict by repo):**
```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": {
      "Federated": "arn:aws:iam::123456789012:oidc-provider/token.actions.githubusercontent.com"
    },
    "Action": "sts:AssumeRoleWithWebIdentity",
    "Condition": {
      "StringEquals": {"token.actions.githubusercontent.com:aud": "sts.amazonaws.com"},
      "StringLike": {"token.actions.githubusercontent.com:sub": "repo:my-org/my-repo:*"}
    }
  }]
}
```

**GitHub Actions Workflow:**
```yaml
name: Deploy to AWS

on:
  push:
    branches: [main]

permissions:
  id-token: write  # Required for OIDC
  contents: read

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v2
        with:
          role-to-assume: arn:aws:iam::123456789012:role/GitHubActionsDeployRole
          aws-region: us-east-1

      - name: Deploy to S3
        run: |
          aws s3 sync ./build s3://my-deployment-bucket/
          aws cloudfront create-invalidation --distribution-id EDFDVBD6EXAMPLE --paths "/*"
```

**Advanced Conditions:**
```json
{
  "Condition": {
    "StringEquals": {
      "token.actions.githubusercontent.com:sub": "repo:my-org/my-repo:ref:refs/heads/main"
    }
  }
}
```

## Network Security

### Rules

1. **Use private subnets** for application and data tiers
2. **Apply least privilege** to security groups - no 0.0.0.0/0 ingress
3. **Use NACLs** for defense in depth
4. **Enable VPC Flow Logs** for network monitoring
5. **Use VPC endpoints** (PrivateLink) to avoid internet traffic

### Implementation

**Security Group (least privilege):**
```json
{
  "GroupDescription": "Application server security group",
  "IpPermissions": [{
    "IpProtocol": "tcp",
    "FromPort": 443,
    "ToPort": 443,
    "SourceSecurityGroupId": "sg-loadbalancer"
  }],
  "IpPermissionsEgress": [{
    "IpProtocol": "tcp",
    "FromPort": 443,
    "ToPort": 443,
    "DestinationSecurityGroupId": "sg-database"
  }]
}
```

**VPC Endpoint (avoid internet):**
```bash
aws ec2 create-vpc-endpoint \
  --vpc-id vpc-12345678 \
  --service-name com.amazonaws.us-east-1.s3 \
  --route-table-ids rtb-12345678
```

## Data Protection

### Rules

1. **Encrypt data at rest** - S3, RDS, EBS with KMS
2. **Encrypt data in transit** - enforce TLS 1.2+ for all traffic
3. **Enable default encryption** on S3 buckets
4. **Deny unencrypted uploads** with bucket policies
5. **Enable versioning and MFA delete** for critical S3 buckets

### Implementation

**S3 Bucket Encryption:**
```bash
aws s3api put-bucket-encryption \
  --bucket my-secure-bucket \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "aws:kms",
        "KMSMasterKeyID": "arn:aws:kms:region:account:key/key-id"
      },
      "BucketKeyEnabled": true
    }]
  }'
```

**Deny Unencrypted Uploads:**
```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Deny",
    "Principal": "*",
    "Action": "s3:PutObject",
    "Resource": "arn:aws:s3:::my-secure-bucket/*",
    "Condition": {
      "StringNotEquals": {"s3:x-amz-server-side-encryption": "aws:kms"}
    }
  }]
}
```

**Enforce HTTPS Only:**
```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Deny",
    "Principal": "*",
    "Action": "s3:*",
    "Resource": "arn:aws:s3:::my-bucket/*",
    "Condition": {
      "Bool": {"aws:SecureTransport": "false"}
    }
  }]
}
```

**RDS Encryption:**
```yaml
DBInstance:
  Type: AWS::RDS::DBInstance
  Properties:
    StorageEncrypted: true
    KmsKeyId: !GetAtt EncryptionKey.Arn
```

## Monitoring and Compliance

### Rules

1. **Enable CloudTrail** in all regions with log file validation
2. **Enable GuardDuty** for threat detection
3. **Enable AWS Config** for compliance monitoring
4. **Enable Security Hub** for centralized security findings
5. **Configure alerts** for security events (SNS/email)

### Implementation

**CloudTrail:**
```bash
aws cloudtrail create-trail \
  --name my-organization-trail \
  --s3-bucket-name my-cloudtrail-bucket \
  --is-multi-region-trail \
  --enable-log-file-validation \
  --kms-key-id arn:aws:kms:region:account:key/key-id

aws cloudtrail start-logging --name my-organization-trail
```

**GuardDuty:**
```bash
aws guardduty create-detector \
  --enable \
  --finding-publishing-frequency FIFTEEN_MINUTES
```

**AWS Config Rule:**
```yaml
ConfigRule:
  Type: AWS::Config::ConfigRule
  Properties:
    ConfigRuleName: s3-bucket-encryption-enabled
    Source:
      Owner: AWS
      SourceIdentifier: S3_BUCKET_SERVER_SIDE_ENCRYPTION_ENABLED
```

**Security Hub:**
```bash
aws securityhub enable-security-hub --enable-default-standards
```

## AI/ML Security

### Rules

1. **Encrypt model artifacts** with KMS in S3
2. **Deploy models in VPC** with security groups
3. **Anonymize PII** in training data
4. **Use private VPC endpoints** for SageMaker
5. **Monitor model access** with CloudTrail

### Implementation

**Encrypt Model Storage:**
```python
s3.upload_file(
    'model.pkl',
    'my-ml-models',
    'production/model-v1.0.0.pkl',
    ExtraArgs={
        'ServerSideEncryption': 'aws:kms',
        'SSEKMSKeyId': 'arn:aws:kms:region:account:key/key-id'
    }
)
```

**VPC Model Deployment:**
```python
response = sagemaker.create_model(
    ModelName='secure-model',
    PrimaryContainer={
        'Image': 'account.dkr.ecr.region.amazonaws.com/my-model:latest',
        'ModelDataUrl': 's3://my-models/model.tar.gz'
    },
    ExecutionRoleArn='arn:aws:iam::account:role/SageMakerRole',
    VpcConfig={
        'SecurityGroupIds': ['sg-12345678'],
        'Subnets': ['subnet-12345678', 'subnet-87654321']
    }
)
```

**Data Anonymization:**
```python
import hashlib

def anonymize_pii(data):
    return {
        'user_id': hashlib.sha256(data['email'].encode()).hexdigest(),
        'age_bracket': (data['age'] // 10) * 10,
        'location': data['country'],
        'purchase_history': data['purchase_history']
    }
```

## Security Checklist

### IAM & Access
- [ ] All users have MFA enabled
- [ ] No root account access keys exist
- [ ] IAM roles used instead of access keys for applications
- [ ] Least privilege policies enforced
- [ ] Regular access review (90 days)

### Secrets & Encryption
- [ ] No secrets in code or environment variables
- [ ] Secrets stored in Secrets Manager or Parameter Store
- [ ] Automatic secret rotation enabled
- [ ] Encryption at rest for S3, RDS, EBS
- [ ] TLS/HTTPS enforced for all traffic

### Network
- [ ] Application tier in private subnets
- [ ] Security groups follow least privilege
- [ ] NACLs configured for defense in depth
- [ ] VPC Flow Logs enabled
- [ ] No unrestricted (0.0.0.0/0) ingress rules

### Monitoring & Compliance
- [ ] CloudTrail enabled in all regions
- [ ] GuardDuty enabled
- [ ] AWS Config monitoring compliance
- [ ] Security Hub aggregating findings
- [ ] Automated alerting configured

### CI/CD Security
- [ ] OIDC authentication for GitHub Actions
- [ ] No long-lived credentials in CI/CD
- [ ] Deployment roles with time-limited access
- [ ] Secrets injected at runtime, not build time

## Related Resources

- AWS Security Best Practices: https://aws.amazon.com/architecture/security-identity-compliance/
- AWS Well-Architected Security Pillar: https://docs.aws.amazon.com/wellarchitected/latest/security-pillar/
- See `cloud/aws/well-architected.md` for ML-specific security
- See `cloud/aws/iam-best-practices.md` for detailed policy guidance
