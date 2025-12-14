#!/bin/bash
# Validation script for sync-ai-rules.sh output
# Usage: validate-sync-output.sh --project-type=TYPE --scenario=SCENARIO --test-dir=DIR

set -e

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --project-type=*)
      PROJECT_TYPE="${1#*=}"
      shift
      ;;
    --scenario=*)
      SCENARIO="${1#*=}"
      shift
      ;;
    --test-dir=*)
      TEST_DIR="${1#*=}"
      shift
      ;;
    --name=*)
      NAME="${1#*=}"
      shift
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

# Validate required parameters
if [ -z "$PROJECT_TYPE" ] || [ -z "$SCENARIO" ] || [ -z "$TEST_DIR" ]; then
  echo "Usage: $0 --project-type=TYPE --scenario=SCENARIO --test-dir=DIR [--name=NAME]"
  exit 1
fi

cd "$TEST_DIR"

echo "=== Validating sync output for $PROJECT_TYPE (scenario: $SCENARIO) ==="

# Check AGENTS.md was generated
if [ ! -f .claude/AGENTS.md ]; then
  echo "ERROR: .claude/AGENTS.md not generated"
  exit 1
fi
echo "✓ AGENTS.md generated"

# Check progressive disclosure instructions present
if ! grep -q "DO NOT load all rule files at once" .claude/AGENTS.md; then
  echo "ERROR: Progressive disclosure warning missing"
  exit 1
fi
echo "✓ Progressive disclosure warning present"

# Check rules directory structure
if [ ! -d .claude/rules ]; then
  echo "ERROR: .claude/rules directory not created"
  exit 1
fi
echo "✓ Rules directory structure created"

# Validate scenario-specific rules are referenced
echo "Checking scenario-specific rules for: $SCENARIO"

case "$SCENARIO" in
  refactoring)
    if ! grep -qr "refactoring" .claude/rules/; then
      echo "WARNING: Refactoring scenario but no refactoring rules found"
    else
      echo "✓ Refactoring rules present"
    fi
    ;;
  performance|performance-critical)
    if ! grep -qr "performance\|optimization" .claude/; then
      echo "WARNING: Performance scenario but no performance rules found"
    else
      echo "✓ Performance rules present"
    fi
    ;;
  security)
    if ! grep -qr "security" .claude/rules/; then
      echo "WARNING: Security scenario but no security rules found"
    else
      echo "✓ Security rules present"
    fi
    ;;
  cloud-*|multi-cloud|serverless-azure)
    if ! grep -qr "aws\|gcp\|azure\|vercel\|cloud" .claude/rules/; then
      echo "WARNING: Cloud scenario but no cloud-specific rules found"
    else
      echo "✓ Cloud-specific rules present"
    fi
    ;;
  cicd)
    if ! grep -qr "ci.*cd\|cicd\|pipeline" .claude/; then
      echo "WARNING: CI/CD scenario but no CI/CD rules found"
    else
      echo "✓ CI/CD rules present"
    fi
    ;;
  microservices)
    if ! grep -qr "12-factor\|architecture\|microservice" .claude/; then
      echo "WARNING: Microservices scenario but no architecture rules found"
    else
      echo "✓ Architecture/microservices rules present"
    fi
    ;;
esac

# Check for cloud platform specific rules
if [ -f "vercel.json" ]; then
  if [ -d ".claude/rules/cloud/vercel" ]; then
    echo "✓ Vercel rules detected for Vercel project"
  else
    echo "WARNING: Vercel config found but no Vercel rules"
  fi
fi

if grep -q "boto3\|aws-sdk\|AWS" *.* 2>/dev/null; then
  if [ -d ".claude/rules/cloud/aws" ] || grep -qr "aws" .claude/rules/; then
    echo "✓ AWS rules detected for AWS project"
  else
    echo "WARNING: AWS dependencies found but no AWS rules"
  fi
fi

if grep -q "google-cloud\|gcp" *.* 2>/dev/null; then
  if grep -qr "gcp\|google.*cloud" .claude/; then
    echo "✓ GCP-related rules detected"
  else
    echo "WARNING: GCP dependencies found but no GCP rules"
  fi
fi

if grep -q "azure\|Microsoft.Azure" *.* 2>/dev/null; then
  if grep -qr "azure" .claude/; then
    echo "✓ Azure-related rules detected"
  else
    echo "WARNING: Azure dependencies found but no Azure rules"
  fi
fi

# Validate language-specific rules
# For polyglot projects, be lenient - warn instead of fail
IS_POLYGLOT="false"
if [ "$SCENARIO" == "polyglot" ]; then
  IS_POLYGLOT="true"
fi

if [ -f "pyproject.toml" ] || [ -f "requirements.txt" ]; then
  if [ -d ".claude/rules/languages/python" ]; then
    echo "✓ Python rules detected"
  else
    if [ "$IS_POLYGLOT" == "true" ]; then
      echo "WARNING: Python project but no Python rules (polyglot - non-fatal)"
    else
      echo "ERROR: Python project but no Python rules"
      exit 1
    fi
  fi
fi

if [ -f "package.json" ]; then
  if [ -d ".claude/rules/languages/typescript" ] || grep -q "typescript" .claude/rules/ -r; then
    echo "✓ TypeScript/JavaScript rules detected"
  else
    if [ "$IS_POLYGLOT" == "true" ]; then
      echo "WARNING: Node.js project but no TypeScript rules (polyglot - non-fatal)"
    else
      echo "ERROR: Node.js project but no TypeScript rules"
      exit 1
    fi
  fi
fi

if [ -f "go.mod" ]; then
  if [ -d ".claude/rules/languages/go" ]; then
    echo "✓ Go rules detected"
  else
    if [ "$IS_POLYGLOT" == "true" ]; then
      echo "WARNING: Go project but no Go rules (polyglot - non-fatal)"
    else
      echo "ERROR: Go project but no Go rules"
      exit 1
    fi
  fi
fi

if [ -f "Cargo.toml" ]; then
  if [ -d ".claude/rules/languages/rust" ]; then
    echo "✓ Rust rules detected"
  else
    if [ "$IS_POLYGLOT" == "true" ]; then
      echo "WARNING: Rust project but no Rust rules (polyglot - non-fatal)"
    else
      echo "ERROR: Rust project but no Rust rules"
      exit 1
    fi
  fi
fi

if [ -f "pom.xml" ] || ls *.csproj 2>/dev/null; then
  if [ -d ".claude/rules/languages/java" ] || [ -d ".claude/rules/languages/csharp" ]; then
    echo "✓ Java/C# rules detected"
  else
    echo "WARNING: JVM/.NET project but rules may be missing"
  fi
fi

# Check framework-specific rules
if grep -q "fastapi" pyproject.toml 2>/dev/null || grep -q "from fastapi" src/*.py 2>/dev/null; then
  if [ -d ".claude/rules/frameworks/fastapi" ]; then
    echo "✓ FastAPI rules detected"
  fi
fi

if grep -q "django" pyproject.toml requirements.txt 2>/dev/null; then
  if [ -d ".claude/rules/frameworks/django" ]; then
    echo "✓ Django rules detected"
  fi
fi

if grep -q '"react"' package.json 2>/dev/null; then
  if [ -d ".claude/rules/frameworks/react" ]; then
    echo "✓ React rules detected"
  fi
fi

if grep -q '"express"' package.json 2>/dev/null; then
  if [ -d ".claude/rules/frameworks/express" ]; then
    echo "✓ Express rules detected"
  fi
fi

if grep -q "spring-boot" pom.xml 2>/dev/null; then
  if [ -d ".claude/rules/frameworks/springboot" ]; then
    echo "✓ SpringBoot rules detected"
  fi
fi

echo "✅ All validations passed for ${NAME:-$PROJECT_TYPE}"
