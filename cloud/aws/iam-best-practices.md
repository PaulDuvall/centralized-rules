# AWS IAM Best Practices

> **When to apply:** All AWS infrastructure and application development

Comprehensive IAM guidance including policy as code, Cedar policy language, Open Policy Agent (OPA), policy testing, roles, SCPs, and permission boundaries.

## IAM Fundamentals

### Identity Types

- **Users:** Individual people/applications - avoid long-lived access keys
- **Groups:** Collections of users - attach policies to groups, not users
- **Roles:** Temporary credentials assumed by users/applications/services - **preferred for everything**
- **Service Roles:** AWS services (EC2, Lambda, ECS) - enable AWS API calls

### Policy Types

**Identity-Based (attached to users/groups/roles):**
```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Action": ["s3:GetObject", "s3:PutObject"],
    "Resource": "arn:aws:s3:::my-bucket/*"
  }]
}
```

**Resource-Based (attached to resources):**
```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": {"AWS": "arn:aws:iam::123456789012:role/MyRole"},
    "Action": "s3:GetObject",
    "Resource": "arn:aws:s3:::my-bucket/*"
  }]
}
```

**Trust Policy (who can assume role):**
```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": {"Service": "lambda.amazonaws.com"},
    "Action": "sts:AssumeRole"
  }]
}
```

## Policy as Code

### Rules

1. **Version control policies** - git with code review
2. **Automate testing** - validate before deployment
3. **Use reusable templates** - Terraform modules, CloudFormation macros
4. **Audit trail** - track all policy changes
5. **Validate syntax** - lint policies (Parliament, IAM Policy Simulator)

### Terraform Implementation

```hcl
# Policy document as code
data "aws_iam_policy_document" "app_s3_access" {
  statement {
    sid    = "AllowS3ReadWrite"
    effect = "Allow"
    actions   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
    resources = ["${aws_s3_bucket.app_bucket.arn}/*"]
  }

  statement {
    sid       = "AllowS3ListBucket"
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.app_bucket.arn]
  }
}

resource "aws_iam_policy" "app_s3_policy" {
  name   = "app-s3-access-policy"
  policy = data.aws_iam_policy_document.app_s3_access.json
}

resource "aws_iam_role_policy_attachment" "app_s3_attach" {
  role       = aws_iam_role.app_role.name
  policy_arn = aws_iam_policy.app_s3_policy.arn
}
```

**Reusable Module:**
```hcl
# modules/s3-access-policy/main.tf
variable "bucket_arn" { type = string }
variable "policy_name" { type = string }
variable "allow_delete" { type = bool; default = false }

locals {
  actions = var.allow_delete ?
    ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"] :
    ["s3:GetObject", "s3:PutObject"]
}

data "aws_iam_policy_document" "this" {
  statement {
    effect    = "Allow"
    actions   = local.actions
    resources = ["${var.bucket_arn}/*"]
  }
}

resource "aws_iam_policy" "this" {
  name   = var.policy_name
  policy = data.aws_iam_policy_document.this.json
}

output "policy_arn" { value = aws_iam_policy.this.arn }
```

## Cedar Policy Language

### Overview

Cedar is AWS's open-source policy language for fine-grained authorization (Amazon Verified Permissions, AWS Verified Access).

**Key Features:**
- Human-readable syntax
- Strongly typed with formal verification
- Separation of policy from code
- Supports RBAC and ABAC

### Basic Cedar Syntax

```cedar
// Allow admins any action
permit(principal in Group::"Admins", action, resource);

// Allow users to read their own data
permit(principal, action == Action::"read", resource)
when { principal == resource.owner };

// Deny delete on production
forbid(principal, action == Action::"delete", resource in Tag::"production");
```

### Cedar with Schema

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
    "actions": {"read": {}, "write": {}, "delete": {}}
  }
}
```

**Cedar Policies:**
```cedar
// Department-based access
permit(principal, action in [Action::"read", Action::"write"], resource)
when { principal.department == resource.department };

// Role-based access
permit(principal, action == Action::"delete", resource)
when { principal.role == "manager" };

// ABAC - deny confidential to non-admins
forbid(principal, action, resource)
when { resource.confidential == true && principal.role != "admin" };
```

### Cedar in Python

```python
from cedar_policy import Evaluator

evaluator = Evaluator(policies, schema)

request = {
    "principal": "User::\"alice\"",
    "action": "Action::\"read\"",
    "resource": "Document::\"doc123\"",
    "context": {}
}

decision = evaluator.is_authorized(request)  # ALLOW, DENY, or ERROR
```

## Open Policy Agent (OPA)

### Overview

General-purpose policy engine for IAM validation, enforcement, and application authorization.

**Use Cases:**
- Validate IAM policies before deployment
- Enforce organizational standards
- Application authorization decisions
- Kubernetes admission control

### Rego Policy Language

**IAM Validation Rules:**
```rego
package iam.validation

import future.keywords

# Deny wildcard resources
deny_wildcard_resources contains msg if {
  some statement in input.Statement
  statement.Resource == "*"
  msg := sprintf("Statement uses wildcard resource: %v", [statement.Sid])
}

# Require encryption for S3 writes
deny_unencrypted_s3 contains msg if {
  some statement in input.Statement
  is_s3_write_action(statement.Action)
  not requires_encryption(statement)
  msg := "S3 write operations must require encryption"
}

is_s3_write_action(action) if { startswith(action, "s3:Put") }

requires_encryption(statement) if {
  statement.Condition["StringEquals"]["s3:x-amz-server-side-encryption"]
}

# Deny missing required tags
deny_missing_tags contains msg if {
  not input.Tags
  msg := "Policy must have required tags"
}
```

### OPA in CI/CD

```bash
# Install OPA
brew install opa

# Test policy
opa eval -i policy.json -d validation.rego "data.iam.validation.deny"

# Run OPA server
opa run --server validation.rego

# Query via API
curl -X POST http://localhost:8181/v1/data/iam/validation/deny -d @policy.json
```

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
          chmod +x opa && sudo mv opa /usr/local/bin/

      - name: Validate Policies
        run: |
          for policy_file in policies/*.json; do
            violations=$(opa eval -i "$policy_file" -d opa/validation.rego \
              "data.iam.validation.deny" --format raw)
            if [ "$violations" != "[]" ]; then
              echo "Policy violations in $policy_file: $violations"
              exit 1
            fi
          done
```

## Policy Testing

### Rules

1. **Unit test policies** with moto (Python) or localstack
2. **Use IAM Policy Simulator** for real-world validation
3. **Lint policies** with Parliament before deployment
4. **Test least privilege** - verify denials work
5. **Automate tests** in CI/CD pipeline

### Unit Testing with moto

```python
import boto3
import pytest
from moto import mock_iam, mock_sts

@mock_iam
@mock_sts
def test_policy_allows_s3_read():
    iam = boto3.client('iam', region_name='us-east-1')

    policy_doc = {
        "Version": "2012-10-17",
        "Statement": [{
            "Effect": "Allow",
            "Action": ["s3:GetObject"],
            "Resource": "arn:aws:s3:::my-bucket/*"
        }]
    }

    policy = iam.create_policy(
        PolicyName='TestS3ReadPolicy',
        PolicyDocument=json.dumps(policy_doc)
    )

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

    # Verify role can be assumed
    sts = boto3.client('sts', region_name='us-east-1')
    response = sts.assume_role(
        RoleArn=role['Role']['Arn'],
        RoleSessionName='test-session'
    )

    assert response['Credentials']
```

### IAM Policy Simulator

```python
import boto3

iam = boto3.client('iam')

def test_policy(policy_arn, action, resource):
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
result = test_policy(
    policy_arn='arn:aws:iam::123456789012:policy/MyPolicy',
    action='s3:GetObject',
    resource='arn:aws:s3:::my-bucket/file.txt'
)

assert result['decision'] == 'allowed'
```

### Parliament Linter

```bash
# Install
pip install parliament

# Lint policy
parliament --file policy.json
```

```python
from parliament import analyze_policy_string

policy = """{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Action": "*",
    "Resource": "*"
  }]
}"""

findings = analyze_policy_string(policy)

for finding in findings:
    print(f"{finding.severity}: {finding.title}")
    print(f"  {finding.description}")
```

## IAM Roles and Assume Role

### Cross-Account Access

**Trust Policy (Account A - allows Account B):**
```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": {"AWS": "arn:aws:iam::111111111111:root"},
    "Action": "sts:AssumeRole",
    "Condition": {
      "StringEquals": {"sts:ExternalId": "unique-external-id-12345"}
    }
  }]
}
```

**Assume Role (Account B):**
```python
import boto3

sts = boto3.client('sts')

assumed_role = sts.assume_role(
    RoleArn='arn:aws:iam::222222222222:role/CrossAccountRole',
    RoleSessionName='cross-account-session',
    ExternalId='unique-external-id-12345',
    DurationSeconds=3600
)

credentials = assumed_role['Credentials']
s3 = boto3.client(
    's3',
    aws_access_key_id=credentials['AccessKeyId'],
    aws_secret_access_key=credentials['SecretAccessKey'],
    aws_session_token=credentials['SessionToken']
)
```

### Session Tags (ABAC)

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

# Policy using session tags
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

## Service Control Policies (SCPs)

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
        "aws:RequestedRegion": ["us-east-1", "us-west-2", "eu-west-1"]
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
      "StringNotEquals": {"s3:x-amz-server-side-encryption": "AES256"}
    }
  }]
}
```

## Permission Boundaries

### Limit Maximum Permissions

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["s3:*", "dynamodb:*", "sqs:*"],
      "Resource": "*"
    },
    {
      "Effect": "Deny",
      "Action": ["iam:*", "organizations:*", "account:*"],
      "Resource": "*"
    }
  ]
}
```

**Apply Boundary:**
```bash
aws iam create-role \
  --role-name DeveloperRole \
  --assume-role-policy-document file://trust-policy.json \
  --permissions-boundary arn:aws:iam::123456789012:policy/DeveloperBoundary
```

## IAM Best Practices Summary

### ✅ Do This

1. **Use Roles, Not Users** - IAM roles for EC2, Lambda, ECS with temporary credentials
2. **Least Privilege** - grant minimum permissions with conditions
3. **Enable MFA** - require for privileged operations
4. **Rotate Credentials** - every 90 days; prefer temporary credentials
5. **Use Policy Conditions** - IP, time, MFA, tag-based restrictions
6. **Monitor and Audit** - CloudTrail, Access Analyzer, IAM Access Analyzer

### ❌ Avoid This

1. Never hardcode credentials
2. Never use root account for daily operations
3. Never grant `*` permissions
4. Never share access keys
5. Never commit policies to public repos without review

## Related Resources

- AWS IAM Documentation: https://docs.aws.amazon.com/iam/
- Cedar Policy Language: https://www.cedarpolicy.com/
- Open Policy Agent: https://www.openpolicyagent.org/
- Parliament (IAM Linter): https://github.com/duo-labs/parliament
- IAM Policy Simulator: https://policysim.aws.amazon.com/
- See `cloud/aws/security-best-practices.md` for broader AWS security
- See `cloud/aws/well-architected.md` for ML security patterns
