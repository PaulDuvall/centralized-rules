# AWS Security Best Practices

> **When to apply:** All AWS-based applications and infrastructure

Comprehensive security guidelines for AWS workloads, covering IAM, secrets management, OIDC authentication, and security best practices for AI/ML systems.

## Table of Contents

- [IAM Best Practices](#iam-best-practices)
- [Secrets Management](#secrets-management)
- [OIDC for GitHub Actions](#oidc-for-github-actions)
- [Network Security](#network-security)
- [Data Protection](#data-protection)
- [Monitoring and Compliance](#monitoring-and-compliance)
- [AI/ML Security](#aiml-security)

---

## IAM Best Practices

### Principle of Least Privilege

**Rule:** Grant only the minimum permissions required to perform a task.

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
      "Resource": "arn:aws:s3:::my-bucket/uploads/*"
    }
  ]
}
```

**Anti-pattern:**
```json
{
  "Effect": "Allow",
  "Action": "s3:*",  // ❌ Too broad
  "Resource": "*"     // ❌ Applies to all buckets
}
```

### Use IAM Roles, Not Access Keys

**Rule:** Always use IAM roles for applications running on AWS infrastructure.

**Good (EC2, ECS, Lambda):**
```yaml
# ECS Task Definition
TaskRoleArn: arn:aws:iam::123456789012:role/MyAppRole

# Role policy attached to ECS task
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["dynamodb:Query", "dynamodb:GetItem"],
      "Resource": "arn:aws:dynamodb:us-east-1:123456789012:table/Users"
    }
  ]
}
```

**Bad (hardcoded credentials):**
```python
# ❌ Never do this
aws_access_key_id = "AKIAIOSFODNN7EXAMPLE"
aws_secret_access_key = "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
```

### Multi-Factor Authentication (MFA)

**Rule:** Require MFA for all human users, especially for privileged operations.

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Deny",
      "Action": "*",
      "Resource": "*",
      "Condition": {
        "BoolIfExists": {
          "aws:MultiFactorAuthPresent": "false"
        }
      }
    }
  ]
}
```

### IAM Policy Best Practices

**1. Use Managed Policies for Common Patterns:**
```bash
# AWS managed policies (use when appropriate)
aws iam attach-role-policy \
  --role-name MyAppRole \
  --policy-arn arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess
```

**2. Create Custom Policies for Specific Needs:**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowLoggingToCloudWatch",
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:us-east-1:123456789012:log-group:/aws/lambda/my-function:*"
    }
  ]
}
```

**3. Use Conditions for Fine-Grained Control:**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "s3:*",
      "Resource": "arn:aws:s3:::my-bucket/*",
      "Condition": {
        "IpAddress": {
          "aws:SourceIp": "203.0.113.0/24"
        },
        "StringEquals": {
          "s3:x-amz-server-side-encryption": "AES256"
        }
      }
    }
  ]
}
```

### Service Control Policies (SCPs)

**Rule:** Use SCPs in AWS Organizations to set permission guardrails.

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Deny",
      "Action": [
        "ec2:RunInstances"
      ],
      "Resource": "*",
      "Condition": {
        "StringNotEquals": {
          "ec2:InstanceType": [
            "t3.micro",
            "t3.small",
            "t3.medium"
          ]
        }
      }
    }
  ]
}
```

---

## Secrets Management

### AWS Secrets Manager

**Rule:** Store all application secrets in AWS Secrets Manager or Parameter Store, never in code.

**Storing Secrets:**
```bash
# Create a secret
aws secretsmanager create-secret \
  --name prod/myapp/database \
  --description "Production database credentials" \
  --secret-string '{"username":"admin","password":"SuperSecret123!"}'

# Store secret with automatic rotation
aws secretsmanager create-secret \
  --name prod/myapp/api-key \
  --secret-string "my-secret-api-key" \
  --rotation-lambda-arn arn:aws:lambda:us-east-1:123456789012:function:MyRotationFunction \
  --rotation-rules AutomaticallyAfterDays=30
```

**Retrieving Secrets in Application:**

**Python:**
```python
import boto3
import json
from botocore.exceptions import ClientError

def get_secret(secret_name, region_name="us-east-1"):
    """Retrieve secret from AWS Secrets Manager"""
    session = boto3.session.Session()
    client = session.client(
        service_name='secretsmanager',
        region_name=region_name
    )

    try:
        get_secret_value_response = client.get_secret_value(
            SecretId=secret_name
        )
    except ClientError as e:
        raise e

    # Parse and return secret
    secret = get_secret_value_response['SecretString']
    return json.loads(secret)

# Usage
db_credentials = get_secret('prod/myapp/database')
db_url = f"postgresql://{db_credentials['username']}:{db_credentials['password']}@db-host/mydb"
```

**Node.js:**
```javascript
const AWS = require('aws-sdk');

async function getSecret(secretName, region = 'us-east-1') {
  const client = new AWS.SecretsManager({ region });

  try {
    const data = await client.getSecretValue({ SecretId: secretName }).promise();
    return JSON.parse(data.SecretString);
  } catch (error) {
    throw error;
  }
}

// Usage
const dbCreds = await getSecret('prod/myapp/database');
const dbUrl = `postgresql://${dbCreds.username}:${dbCreds.password}@db-host/mydb`;
```

### AWS Systems Manager Parameter Store

**Rule:** Use Parameter Store for configuration values and non-sensitive parameters.

**Standard Parameters (free):**
```bash
# Store configuration
aws ssm put-parameter \
  --name /myapp/prod/api-endpoint \
  --value "https://api.example.com" \
  --type String

# Retrieve in application
aws ssm get-parameter --name /myapp/prod/api-endpoint --query 'Parameter.Value' --output text
```

**SecureString Parameters (encrypted):**
```bash
# Store encrypted secret
aws ssm put-parameter \
  --name /myapp/prod/database-password \
  --value "SuperSecret123!" \
  --type SecureString \
  --key-id alias/aws/ssm

# Retrieve with decryption
aws ssm get-parameter \
  --name /myapp/prod/database-password \
  --with-decryption \
  --query 'Parameter.Value' \
  --output text
```

**Python Integration:**
```python
import boto3

ssm = boto3.client('ssm', region_name='us-east-1')

def get_parameter(name, decrypt=True):
    """Get parameter from Parameter Store"""
    response = ssm.get_parameter(
        Name=name,
        WithDecryption=decrypt
    )
    return response['Parameter']['Value']

# Usage
api_endpoint = get_parameter('/myapp/prod/api-endpoint')
db_password = get_parameter('/myapp/prod/database-password', decrypt=True)
```

### Secret Rotation

**Rule:** Rotate secrets automatically every 30-90 days.

```python
# Lambda function for secret rotation
import boto3
import json

def lambda_handler(event, context):
    """Rotate database password"""
    service_client = boto3.client('secretsmanager')
    arn = event['SecretId']
    token = event['ClientRequestToken']
    step = event['Step']

    if step == "createSecret":
        # Generate new password
        new_password = generate_secure_password()
        service_client.put_secret_value(
            SecretId=arn,
            ClientRequestToken=token,
            SecretString=json.dumps({"password": new_password}),
            VersionStages=['AWSPENDING']
        )

    elif step == "setSecret":
        # Update database with new password
        pending_secret = get_secret_version(arn, "AWSPENDING", token)
        update_database_password(pending_secret['password'])

    elif step == "testSecret":
        # Test new password works
        pending_secret = get_secret_version(arn, "AWSPENDING", token)
        test_database_connection(pending_secret['password'])

    elif step == "finishSecret":
        # Finalize rotation
        service_client.update_secret_version_stage(
            SecretId=arn,
            VersionStage='AWSCURRENT',
            MoveToVersionId=token,
            RemoveFromVersionId=get_current_version(arn)
        )
```

---

## OIDC for GitHub Actions

### Why OIDC Instead of Access Keys

**Traditional (insecure):**
```yaml
# ❌ Storing AWS credentials as GitHub secrets
- name: Configure AWS credentials
  uses: aws-actions/configure-aws-credentials@v2
  with:
    aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
    aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
```

**OIDC (secure, no long-lived credentials):**
```yaml
# ✅ Using OIDC with IAM role assumption
- name: Configure AWS credentials
  uses: aws-actions/configure-aws-credentials@v2
  with:
    role-to-assume: arn:aws:iam::123456789012:role/GitHubActionsRole
    aws-region: us-east-1
```

### Setting Up OIDC for GitHub Actions

**1. Create OIDC Identity Provider in AWS:**
```bash
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com \
  --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1
```

**2. Create IAM Role for GitHub Actions:**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::123456789012:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:my-org/my-repo:*"
        }
      }
    }
  ]
}
```

**3. Attach Permissions Policy to Role:**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:GetObject",
        "cloudfront:CreateInvalidation"
      ],
      "Resource": [
        "arn:aws:s3:::my-deployment-bucket/*",
        "arn:aws:cloudfront::123456789012:distribution/EDFDVBD6EXAMPLE"
      ]
    }
  ]
}
```

**4. Use in GitHub Actions Workflow:**
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

### Advanced OIDC Conditions

**Restrict by Branch:**
```json
{
  "Condition": {
    "StringEquals": {
      "token.actions.githubusercontent.com:sub": "repo:my-org/my-repo:ref:refs/heads/main"
    }
  }
}
```

**Restrict by Environment:**
```json
{
  "Condition": {
    "StringLike": {
      "token.actions.githubusercontent.com:sub": "repo:my-org/my-repo:environment:production"
    }
  }
}
```

**Multiple Repositories:**
```json
{
  "Condition": {
    "StringLike": {
      "token.actions.githubusercontent.com:sub": [
        "repo:my-org/repo1:*",
        "repo:my-org/repo2:*",
        "repo:my-org/repo3:*"
      ]
    }
  }
}
```

---

## Network Security

### VPC Security Best Practices

**1. Use Private Subnets for Application Tier:**
```yaml
# CloudFormation example
PrivateSubnet:
  Type: AWS::EC2::Subnet
  Properties:
    VpcId: !Ref VPC
    CidrBlock: 10.0.1.0/24
    MapPublicIpOnLaunch: false  # No public IPs
    AvailabilityZone: us-east-1a

# Application servers in private subnet
AppServer:
  Type: AWS::EC2::Instance
  Properties:
    SubnetId: !Ref PrivateSubnet
    SecurityGroupIds:
      - !Ref AppSecurityGroup
```

**2. Security Groups - Principle of Least Privilege:**
```json
{
  "GroupDescription": "Application server security group",
  "IpPermissions": [
    {
      "IpProtocol": "tcp",
      "FromPort": 443,
      "ToPort": 443,
      "SourceSecurityGroupId": "sg-loadbalancer"  // Only from ALB
    }
  ],
  "IpPermissionsEgress": [
    {
      "IpProtocol": "tcp",
      "FromPort": 443,
      "ToPort": 443,
      "DestinationSecurityGroupId": "sg-database"  // Only to DB
    }
  ]
}
```

**3. Network ACLs as Defense in Depth:**
```yaml
NetworkAcl:
  Type: AWS::EC2::NetworkAcl
  Properties:
    VpcId: !Ref VPC

InboundRule:
  Type: AWS::EC2::NetworkAclEntry
  Properties:
    NetworkAclId: !Ref NetworkAcl
    RuleNumber: 100
    Protocol: 6  # TCP
    RuleAction: allow
    CidrBlock: 10.0.0.0/16  # Internal VPC only
    PortRange:
      From: 443
      To: 443
```

### VPN and Private Connectivity

**AWS PrivateLink for Service Access:**
```bash
# Create VPC endpoint for S3
aws ec2 create-vpc-endpoint \
  --vpc-id vpc-12345678 \
  --service-name com.amazonaws.us-east-1.s3 \
  --route-table-ids rtb-12345678

# No internet gateway required for S3 access
```

---

## Data Protection

### Encryption at Rest

**S3 Bucket Encryption:**
```bash
# Enable default encryption
aws s3api put-bucket-encryption \
  --bucket my-secure-bucket \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "aws:kms",
        "KMSMasterKeyID": "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"
      },
      "BucketKeyEnabled": true
    }]
  }'

# Deny unencrypted uploads
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Deny",
      "Principal": "*",
      "Action": "s3:PutObject",
      "Resource": "arn:aws:s3:::my-secure-bucket/*",
      "Condition": {
        "StringNotEquals": {
          "s3:x-amz-server-side-encryption": "aws:kms"
        }
      }
    }
  ]
}
```

**RDS Encryption:**
```yaml
DBInstance:
  Type: AWS::RDS::DBInstance
  Properties:
    Engine: postgres
    StorageEncrypted: true
    KmsKeyId: !GetAtt EncryptionKey.Arn
```

**EBS Encryption:**
```yaml
LaunchTemplate:
  Type: AWS::EC2::LaunchTemplate
  Properties:
    LaunchTemplateData:
      BlockDeviceMappings:
        - DeviceName: /dev/xvda
          Ebs:
            Encrypted: true
            KmsKeyId: !Ref KMSKey
            VolumeSize: 100
            VolumeType: gp3
```

### Encryption in Transit

**Enforce HTTPS Only:**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Deny",
      "Principal": "*",
      "Action": "s3:*",
      "Resource": "arn:aws:s3:::my-bucket/*",
      "Condition": {
        "Bool": {
          "aws:SecureTransport": "false"
        }
      }
    }
  ]
}
```

**Application Load Balancer SSL/TLS:**
```yaml
Listener:
  Type: AWS::ElasticLoadBalancingV2::Listener
  Properties:
    DefaultActions:
      - Type: forward
        TargetGroupArn: !Ref TargetGroup
    LoadBalancerArn: !Ref LoadBalancer
    Port: 443
    Protocol: HTTPS
    Certificates:
      - CertificateArn: !Ref ACMCertificate
    SslPolicy: ELBSecurityPolicy-TLS-1-2-2017-01  # TLS 1.2+
```

---

## Monitoring and Compliance

### CloudTrail

**Rule:** Enable CloudTrail in all regions for audit logging.

```bash
# Create trail
aws cloudtrail create-trail \
  --name my-organization-trail \
  --s3-bucket-name my-cloudtrail-bucket \
  --is-multi-region-trail \
  --enable-log-file-validation \
  --kms-key-id arn:aws:kms:us-east-1:123456789012:key/12345678

# Start logging
aws cloudtrail start-logging --name my-organization-trail
```

### GuardDuty

**Enable Threat Detection:**
```bash
aws guardduty create-detector \
  --enable \
  --finding-publishing-frequency FIFTEEN_MINUTES
```

### AWS Config

**Monitor Configuration Compliance:**
```yaml
ConfigRule:
  Type: AWS::Config::ConfigRule
  Properties:
    ConfigRuleName: s3-bucket-encryption-enabled
    Source:
      Owner: AWS
      SourceIdentifier: S3_BUCKET_SERVER_SIDE_ENCRYPTION_ENABLED
```

### Security Hub

**Centralized Security Findings:**
```bash
aws securityhub enable-security-hub \
  --enable-default-standards
```

---

## AI/ML Security

### Model Artifact Protection

**Secure Model Storage:**
```python
# Encrypt model artifacts with KMS
import boto3

s3 = boto3.client('s3')
s3.upload_file(
    'model.pkl',
    'my-ml-models',
    'production/model-v1.0.0.pkl',
    ExtraArgs={
        'ServerSideEncryption': 'aws:kms',
        'SSEKMSKeyId': 'arn:aws:kms:us-east-1:123456789012:key/12345678'
    }
)
```

### Training Data Security

**Data Anonymization:**
```python
import hashlib

def anonymize_pii(data):
    """Anonymize personally identifiable information"""
    return {
        'user_id': hashlib.sha256(data['email'].encode()).hexdigest(),
        'age_bracket': (data['age'] // 10) * 10,  # Group into decades
        'location': data['country'],  # Country only, not exact location
        # Include non-PII features
        'purchase_history': data['purchase_history']
    }
```

### Inference Endpoint Security

**Private VPC Endpoints for SageMaker:**
```python
import boto3

sagemaker = boto3.client('sagemaker')

# Create model with VPC configuration
response = sagemaker.create_model(
    ModelName='secure-model',
    PrimaryContainer={
        'Image': 'account.dkr.ecr.region.amazonaws.com/my-model:latest',
        'ModelDataUrl': 's3://my-models/model.tar.gz'
    },
    ExecutionRoleArn='arn:aws:iam::123456789012:role/SageMakerRole',
    VpcConfig={
        'SecurityGroupIds': ['sg-12345678'],
        'Subnets': ['subnet-12345678', 'subnet-87654321']
    }
)
```

---

## Security Checklist

Use this checklist for AWS security review:

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

---

## Related Resources

- **AWS Security Best Practices:** https://aws.amazon.com/security/best-practices/
- **AWS Well-Architected Security Pillar:** https://docs.aws.amazon.com/wellarchitected/latest/security-pillar/
- **IAM Best Practices:** https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html
- See `cloud/aws/well-architected.md` for ML-specific security
- See `cloud/aws/iam-best-practices.md` for detailed policy guidance
- See `base/12-factor-app.md` for application security principles
