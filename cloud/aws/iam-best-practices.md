# AWS IAM Best Practices

> **When to apply:** All AWS infrastructure and application development

Comprehensive guide to AWS Identity and Access Management (IAM) best practices, including policy as code, Cedar policy language, Open Policy Agent (OPA), and IAM testing strategies.

## Table of Contents

- [IAM Fundamentals](#iam-fundamentals)
- [Policy as Code](#policy-as-code)
- [Cedar Policy Language](#cedar-policy-language)
- [Open Policy Agent (OPA)](#open-policy-agent-opa)
- [Policy Testing](#policy-testing)
- [IAM Roles and Assume Role](#iam-roles-and-assume-role)
- [Service Control Policies](#service-control-policies)
- [Permission Boundaries](#permission-boundaries)
- [IAM Best Practices](#iam-best-practices)

---

## IAM Fundamentals

### Identity Types

**Users:**
- Represents individual people or applications
- **Avoid:** Long-lived access keys
- **Prefer:** Temporary credentials via roles

**Groups:**
- Collections of users
- Attach policies to groups, not individual users
- Simplifies permission management

**Roles:**
- Assumed by users, applications, or services
- Temporary credentials
- **Best Practice:** Use roles for everything

**Service Roles:**
- Assigned to AWS services (EC2, Lambda, ECS)
- Enable services to make AWS API calls

### Policy Types

**Identity-Based Policies:**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["s3:GetObject", "s3:PutObject"],
      "Resource": "arn:aws:s3:::my-bucket/*"
    }
  ]
}
```

**Resource-Based Policies:**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {"AWS": "arn:aws:iam::123456789012:role/MyRole"},
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::my-bucket/*"
    }
  ]
}
```

**Trust Policies (Assume Role):**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {"Service": "lambda.amazonaws.com"},
      "Action": "sts:AssumeRole"
    }
  ]
}
```

---

## Policy as Code

### Why Policy as Code?

**Benefits:**
- Version control for policies
- Code review process
- Automated testing
- Consistent policy application
- Audit trail of changes
- Reusable policy templates

### Terraform IAM Policies

**policy.tf:**
```hcl
# Data source for policy document
data "aws_iam_policy_document" "app_s3_access" {
  statement {
    sid = "AllowS3ReadWrite"
    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject"
    ]

    resources = [
      "${aws_s3_bucket.app_bucket.arn}/*"
    ]
  }

  statement {
    sid = "AllowS3ListBucket"
    effect = "Allow"

    actions = ["s3:ListBucket"]

    resources = [aws_s3_bucket.app_bucket.arn]
  }
}

# Create policy from document
resource "aws_iam_policy" "app_s3_policy" {
  name        = "app-s3-access-policy"
  description = "Allow application to read/write to S3 bucket"
  policy      = data.aws_iam_policy_document.app_s3_access.json
}

# Attach to role
resource "aws_iam_role_policy_attachment" "app_s3_attach" {
  role       = aws_iam_role.app_role.name
  policy_arn = aws_iam_policy.app_s3_policy.arn
}
```

### CloudFormation IAM Policies

```yaml
Resources:
  AppS3Policy:
    Type: AWS::IAM::Policy
    Properties:
      PolicyName: AppS3AccessPolicy
      PolicyDocument:
        Version: '2012-10-17'
        Statement:
          - Sid: AllowS3ReadWrite
            Effect: Allow
            Action:
              - s3:GetObject
              - s3:PutObject
              - s3:DeleteObject
            Resource: !Sub '${AppBucket.Arn}/*'
          - Sid: AllowS3ListBucket
            Effect: Allow
            Action: s3:ListBucket
            Resource: !GetAtt AppBucket.Arn
      Roles:
        - !Ref AppRole

  AppRole:
    Type: AWS::IAM::Role
    Properties:
      AssumeRolePolicyDocument:
        Version: '2012-10-17'
        Statement:
          - Effect: Allow
            Principal:
              Service: lambda.amazonaws.com
            Action: sts:AssumeRole
```

### Policy Templates with Variables

**Terraform Modules:**
```hcl
# modules/s3-access-policy/main.tf
variable "bucket_arn" {
  description = "ARN of S3 bucket"
  type        = string
}

variable "policy_name" {
  description = "Name of IAM policy"
  type        = string
}

variable "allow_delete" {
  description = "Allow delete operations"
  type        = bool
  default     = false
}

locals {
  actions = var.allow_delete ? [
    "s3:GetObject",
    "s3:PutObject",
    "s3:DeleteObject"
  ] : [
    "s3:GetObject",
    "s3:PutObject"
  ]
}

data "aws_iam_policy_document" "this" {
  statement {
    effect = "Allow"
    actions = local.actions
    resources = ["${var.bucket_arn}/*"]
  }
}

resource "aws_iam_policy" "this" {
  name   = var.policy_name
  policy = data.aws_iam_policy_document.this.json
}

output "policy_arn" {
  value = aws_iam_policy.this.arn
}

# Usage
module "app_s3_policy" {
  source = "./modules/s3-access-policy"

  bucket_arn   = aws_s3_bucket.app_bucket.arn
  policy_name  = "app-s3-policy"
  allow_delete = false
}
```

---

## Cedar Policy Language

### What is Cedar?

Cedar is AWS's open-source policy language designed for fine-grained authorization. It's used in Amazon Verified Permissions and AWS Verified Access.

**Key Features:**
- Human-readable syntax
- Strongly typed
- Formal verification
- Separation of policy from code
- Supports RBAC and ABAC

### Cedar Policy Syntax

**Basic Policy:**
```cedar
// Allow admins to perform any action
permit(
  principal in Group::"Admins",
  action,
  resource
);

// Allow users to read their own data
permit(
  principal,
  action == Action::"read",
  resource
) when {
  principal == resource.owner
};

// Deny delete operations on production resources
forbid(
  principal,
  action == Action::"delete",
  resource in Tag::"production"
);
```

### Cedar with AWS Verified Permissions

**Schema Definition:**
```json
{
  "MyApp": {
    "entityTypes": {
      "User": {
        "shape": {
          "type": "Record",
          "attributes": {
            "department": {"type": "String"},
            "role": {"type": "String"}
          }
        }
      },
      "Document": {
        "shape": {
          "type": "Record",
          "attributes": {
            "owner": {"type": "EntityOrCommon", "name": "User"},
            "confidential": {"type": "Boolean"}
          }
        }
      }
    },
    "actions": {
      "read": {},
      "write": {},
      "delete": {}
    }
  }
}
```

**Cedar Policies:**
```cedar
// Department-based access
permit(
  principal,
  action in [Action::"read", Action::"write"],
  resource
) when {
  principal.department == resource.department
};

// Role-based access
permit(
  principal,
  action == Action::"delete",
  resource
) when {
  principal.role == "manager"
};

// Attribute-based access control
forbid(
  principal,
  action,
  resource
) when {
  resource.confidential == true &&
  principal.role != "admin"
};
```

### Using Cedar in Applications

**Python with Cedar:**
```python
from cedar_policy_validator import validate_policy

# Define policy
policy = """
permit(
  principal == User::"alice",
  action == Action::"read",
  resource in Folder::"shared"
);
"""

# Validate policy against schema
result = validate_policy(policy, schema)
if result.is_valid:
    print("Policy is valid")
else:
    print(f"Policy errors: {result.errors}")

# Evaluate authorization request
from cedar_policy import Evaluator

evaluator = Evaluator(policies, schema)

request = {
    "principal": "User::\"alice\"",
    "action": "Action::\"read\"",
    "resource": "Document::\"doc123\"",
    "context": {}
}

decision = evaluator.is_authorized(request)
# Returns: ALLOW, DENY, or ERROR
```

---

## Open Policy Agent (OPA)

### What is OPA?

Open Policy Agent is a general-purpose policy engine that works with AWS IAM and other systems.

**Use Cases:**
- Validate IAM policies before deployment
- Enforce organizational policy standards
- Authorization decisions in applications
- Kubernetes admission control

### OPA Policy Language (Rego)

**Basic Rego Policy:**
```rego
package aws.iam

# Deny policies that allow FullAccess
deny[msg] {
  policy := input.policy
  statement := policy.Statement[_]
  statement.Effect == "Allow"
  statement.Action == "*"

  msg := "Policy grants full access (*), which violates least privilege"
}

# Deny policies without resource restrictions
deny[msg] {
  policy := input.policy
  statement := policy.Statement[_]
  statement.Effect == "Allow"
  statement.Resource == "*"

  msg := sprintf("Statement allows access to all resources: %v", [statement])
}

# Require MFA for admin actions
deny[msg] {
  policy := input.policy
  statement := policy.Statement[_]
  is_admin_action(statement.Action)
  not has_mfa_condition(statement)

  msg := "Admin actions must require MFA"
}

is_admin_action(action) {
  admin_actions := ["iam:*", "ec2:*", "s3:Delete*"]
  action == admin_actions[_]
}

has_mfa_condition(statement) {
  statement.Condition["Bool"]["aws:MultiFactorAuthPresent"] == "true"
}
```

### IAM Policy Validation with OPA

**policy_validation.rego:**
```rego
package iam.validation

import future.keywords

# Rule: Policies must not use wildcard (*) for resources
deny_wildcard_resources contains msg if {
  some statement in input.Statement
  statement.Resource == "*"
  msg := sprintf("Statement uses wildcard resource: %v", [statement.Sid])
}

# Rule: S3 policies must enforce encryption
deny_unencrypted_s3 contains msg if {
  some statement in input.Statement
  is_s3_write_action(statement.Action)
  not requires_encryption(statement)

  msg := "S3 write operations must require encryption"
}

is_s3_write_action(action) if {
  startswith(action, "s3:Put")
}

is_s3_write_action(actions) if {
  some action in actions
  startswith(action, "s3:Put")
}

requires_encryption(statement) if {
  statement.Condition["StringEquals"]["s3:x-amz-server-side-encryption"]
}

# Rule: Enforce tagging requirements
deny_missing_tags contains msg if {
  not input.Tags
  msg := "Policy must have required tags"
}

deny_missing_required_tag[tag] {
  required_tags := ["Environment", "Owner", "CostCenter"]
  tag := required_tags[_]
  not input.Tags[tag]
}
```

**Testing Policies with OPA:**
```bash
# Install OPA
brew install opa

# Test policy against input
opa eval -i policy.json -d policy_validation.rego \
  "data.iam.validation.deny_wildcard_resources"

# Run OPA server
opa run --server policy_validation.rego

# Query via API
curl -X POST http://localhost:8181/v1/data/iam/validation/deny_wildcard_resources \
  -d @policy.json
```

### OPA in CI/CD Pipeline

**GitHub Actions:**
```yaml
name: Validate IAM Policies

on: [pull_request]

jobs:
  validate-policies:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Install OPA
        run: |
          curl -L -o opa https://openpolicyagent.org/downloads/latest/opa_linux_amd64
          chmod +x opa
          sudo mv opa /usr/local/bin/

      - name: Validate IAM Policies
        run: |
          for policy_file in policies/*.json; do
            echo "Validating $policy_file"
            opa eval -i "$policy_file" -d opa/iam_validation.rego \
              "data.iam.validation.deny" --format pretty
          done

      - name: Check for policy violations
        run: |
          violations=$(opa eval -i policies/app_policy.json \
            -d opa/iam_validation.rego \
            "data.iam.validation.deny" --format raw)

          if [ "$violations" != "[]" ]; then
            echo "Policy violations found:"
            echo "$violations"
            exit 1
          fi
```

---

## Policy Testing

### Unit Testing IAM Policies

**Python with moto:**
```python
import boto3
import pytest
from moto import mock_iam, mock_sts

@mock_iam
@mock_sts
def test_policy_allows_s3_read():
    """Test that policy allows S3 read operations"""
    iam = boto3.client('iam', region_name='us-east-1')

    # Create policy
    policy_document = {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Effect": "Allow",
                "Action": ["s3:GetObject"],
                "Resource": "arn:aws:s3:::my-bucket/*"
            }
        ]
    }

    policy = iam.create_policy(
        PolicyName='TestS3ReadPolicy',
        PolicyDocument=json.dumps(policy_document)
    )

    # Create role and attach policy
    trust_policy = {
        "Version": "2012-10-17",
        "Statement": [{
            "Effect": "Allow",
            "Principal": {"Service": "lambda.amazonaws.com"},
            "Action": "sts:AssumeRole"
        }]
    }

    role = iam.create_role(
        RoleName='TestRole',
        AssumeRolePolicyDocument=json.dumps(trust_policy)
    )

    iam.attach_role_policy(
        RoleName='TestRole',
        PolicyArn=policy['Policy']['Arn']
    )

    # Simulate policy evaluation
    sts = boto3.client('sts', region_name='us-east-1')
    response = sts.assume_role(
        RoleArn=role['Role']['Arn'],
        RoleSessionName='test-session'
    )

    assert response['Credentials']

@mock_iam
def test_policy_denies_delete_operations():
    """Test that policy correctly denies delete operations"""
    iam = boto3.client('iam', region_name='us-east-1')

    policy_document = {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Effect": "Allow",
                "Action": ["s3:GetObject", "s3:PutObject"],
                "Resource": "*"
            },
            {
                "Effect": "Deny",
                "Action": ["s3:DeleteObject"],
                "Resource": "*"
            }
        ]
    }

    # Validate policy structure
    response = iam.create_policy(
        PolicyName='TestNoDeletePolicy',
        PolicyDocument=json.dumps(policy_document)
    )

    # Check policy has both allow and deny statements
    policy_version = iam.get_policy_version(
        PolicyArn=response['Policy']['Arn'],
        VersionId='v1'
    )

    statements = json.loads(
        policy_version['PolicyVersion']['Document']
    )['Statement']

    assert len(statements) == 2
    assert any(s['Effect'] == 'Deny' for s in statements)
```

### AWS IAM Policy Simulator

```python
import boto3

iam = boto3.client('iam')

def test_policy_with_simulator(policy_arn, action, resource):
    """Test policy using AWS IAM Policy Simulator"""
    response = iam.simulate_principal_policy(
        PolicySourceArn=policy_arn,
        ActionNames=[action],
        ResourceArns=[resource]
    )

    result = response['EvaluationResults'][0]

    return {
        'action': result['EvalActionName'],
        'decision': result['EvalDecision'],  # allowed, explicitDeny, implicitDeny
        'matched_statements': result.get('MatchedStatements', [])
    }

# Usage
result = test_policy_with_simulator(
    policy_arn='arn:aws:iam::123456789012:policy/MyPolicy',
    action='s3:GetObject',
    resource='arn:aws:s3:::my-bucket/file.txt'
)

assert result['decision'] == 'allowed'
```

### Parliament - IAM Policy Linter

```bash
# Install Parliament
pip install parliament

# Lint IAM policy
parliament --file policy.json

# Example output:
# MEDIUM - Statement allows "*" action
# LOW - Statement is missing a Sid
```

**Python Usage:**
```python
from parliament import analyze_policy_string

policy = """
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Action": "*",
    "Resource": "*"
  }]
}
"""

findings = analyze_policy_string(policy)

for finding in findings:
    print(f"{finding.severity}: {finding.title}")
    print(f"  {finding.description}")
```

---

## IAM Roles and Assume Role

### Cross-Account Access

**Trust Policy (Account A):**
```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": {
      "AWS": "arn:aws:iam::111111111111:root"
    },
    "Action": "sts:AssumeRole",
    "Condition": {
      "StringEquals": {
        "sts:ExternalId": "unique-external-id-12345"
      }
    }
  }]
}
```

**Assuming Role (Account B):**
```python
import boto3

sts = boto3.client('sts')

assumed_role = sts.assume_role(
    RoleArn='arn:aws:iam::222222222222:role/CrossAccountRole',
    RoleSessionName='cross-account-session',
    ExternalId='unique-external-id-12345',
    DurationSeconds=3600
)

# Use temporary credentials
credentials = assumed_role['Credentials']
s3 = boto3.client(
    's3',
    aws_access_key_id=credentials['AccessKeyId'],
    aws_secret_access_key=credentials['SecretAccessKey'],
    aws_session_token=credentials['SessionToken']
)
```

### Session Tags and ABAC

```python
# Assume role with session tags
assumed_role = sts.assume_role(
    RoleArn='arn:aws:iam::123456789012:role/MyRole',
    RoleSessionName='session-with-tags',
    Tags=[
        {'Key': 'Project', 'Value': 'ProjectA'},
        {'Key': 'Environment', 'Value': 'production'}
    ]
)

# Policy using session tags (ABAC)
policy = {
    "Version": "2012-10-17",
    "Statement": [{
        "Effect": "Allow",
        "Action": "s3:*",
        "Resource": "*",
        "Condition": {
            "StringEquals": {
                "s3:ExistingObjectTag/Project": "${aws:PrincipalTag/Project}",
                "s3:ExistingObjectTag/Environment": "${aws:PrincipalTag/Environment}"
            }
        }
    }]
}
```

---

## Service Control Policies

### Organization-Wide Guardrails

**Deny Specific Regions:**
```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Deny",
    "Action": "*",
    "Resource": "*",
    "Condition": {
      "StringNotEquals": {
        "aws:RequestedRegion": [
          "us-east-1",
          "us-west-2",
          "eu-west-1"
        ]
      }
    }
  }]
}
```

**Require Encryption:**
```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Sid": "DenyUnencryptedS3Uploads",
    "Effect": "Deny",
    "Action": "s3:PutObject",
    "Resource": "*",
    "Condition": {
      "StringNotEquals": {
        "s3:x-amz-server-side-encryption": "AES256"
      }
    }
  }]
}
```

---

## Permission Boundaries

### Limit Maximum Permissions

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:*",
        "dynamodb:*",
        "sqs:*"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Deny",
      "Action": [
        "iam:*",
        "organizations:*",
        "account:*"
      ],
      "Resource": "*"
    }
  ]
}
```

**Apply Permission Boundary:**
```bash
aws iam create-role \
  --role-name DeveloperRole \
  --assume-role-policy-document file://trust-policy.json \
  --permissions-boundary arn:aws:iam::123456789012:policy/DeveloperBoundary
```

---

## IAM Best Practices

### ✅ Do This

1. **Use Roles, Not Users**
   - IAM roles for EC2, Lambda, ECS, Fargate
   - Temporary credentials via STS

2. **Principle of Least Privilege**
   - Grant minimum permissions needed
   - Use conditions to restrict further

3. **Enable MFA**
   - Require MFA for privileged operations
   - MFA delete for S3 buckets

4. **Rotate Credentials**
   - Rotate access keys every 90 days
   - Use temporary credentials when possible

5. **Use Policy Conditions**
   - IP restrictions
   - Time-based access
   - MFA requirements
   - Tag-based access

6. **Monitor and Audit**
   - CloudTrail for API logging
   - Access Analyzer for external access
   - IAM Access Analyzer for unused permissions

### ❌ Avoid This

1. **Never Hardcode Credentials**
2. **Never Use Root Account**
3. **Never Grant \* Permissions**
4. **Never Share Access Keys**
5. **Never Commit Policies to Public Repos Without Review**

---

## Related Resources

- See `cloud/aws/security-best-practices.md` for broader AWS security
- See `cloud/aws/well-architected.md` for ML security patterns
- **AWS IAM Documentation:** https://docs.aws.amazon.com/IAM/
- **Cedar Policy Language:** https://www.cedarpolicy.com/
- **Open Policy Agent:** https://www.openpolicyagent.org/
- **Parliament (IAM Linter):** https://github.com/duo-labs/parliament
- **IAM Policy Simulator:** https://policysim.aws.amazon.com/
