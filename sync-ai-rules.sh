#!/usr/bin/env bash

# sync-ai-rules.sh - Progressive Disclosure AI Rules Synchronization
#
# This script detects your project's language and framework, then dynamically
# loads only the relevant rules from a centralized rules repository.
#
# Usage:
#   ./sync-ai-rules.sh [--tool claude|cursor|copilot|gemini|all]
#
# Examples:
#   ./sync-ai-rules.sh                    # Auto-detect and sync for all tools
#   ./sync-ai-rules.sh --tool claude      # Sync only for Claude
#   ./sync-ai-rules.sh --tool cursor      # Sync only for Cursor
#   ./sync-ai-rules.sh --tool gemini      # Sync only for Gemini/Codegemma

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RULES_REPO_URL="${AI_RULES_REPO:-https://raw.githubusercontent.com/PaulDuvall/centralized-rules/main}"
RULES_DIR=".ai-rules"
CACHE_DIR="${RULES_DIR}/.cache"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

log_success() {
    echo -e "${GREEN}✓${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}⚠${NC} $1"
}

log_error() {
    echo -e "${RED}✗${NC} $1" >&2
}

# Detect project language
detect_language() {
    local languages=()

    # Python
    if [[ -f "pyproject.toml" ]] || [[ -f "setup.py" ]] || [[ -f "requirements.txt" ]]; then
        languages+=("python")
    fi

    # TypeScript/JavaScript
    if [[ -f "package.json" ]]; then
        if grep -q '"typescript"' package.json 2>/dev/null; then
            languages+=("typescript")
        else
            languages+=("javascript")
        fi
    fi

    # Go
    if [[ -f "go.mod" ]]; then
        languages+=("go")
    fi

    # Java
    if [[ -f "pom.xml" ]] || [[ -f "build.gradle" ]] || [[ -f "build.gradle.kts" ]]; then
        languages+=("java")
    fi

    # C#
    if [[ -f "*.csproj" ]] || [[ -f "*.sln" ]]; then
        languages+=("csharp")
    fi

    # Ruby
    if [[ -f "Gemfile" ]]; then
        languages+=("ruby")
    fi

    # Rust
    if [[ -f "Cargo.toml" ]]; then
        languages+=("rust")
    fi

    echo "${languages[@]:-}"
}

# Detect frameworks
detect_frameworks() {
    local frameworks=()

    # Python frameworks
    if [[ -f "requirements.txt" ]] || [[ -f "pyproject.toml" ]]; then
        grep -qi "django" requirements.txt pyproject.toml 2>/dev/null && frameworks+=("django")
        grep -qi "fastapi" requirements.txt pyproject.toml 2>/dev/null && frameworks+=("fastapi")
        grep -qi "flask" requirements.txt pyproject.toml 2>/dev/null && frameworks+=("flask")
    fi

    # JavaScript/TypeScript frameworks
    if [[ -f "package.json" ]]; then
        grep -q '"react"' package.json 2>/dev/null && frameworks+=("react")
        grep -q '"next"' package.json 2>/dev/null && frameworks+=("nextjs")
        grep -q '"vue"' package.json 2>/dev/null && frameworks+=("vue")
        grep -q '"express"' package.json 2>/dev/null && frameworks+=("express")
        grep -q '"nestjs"' package.json 2>/dev/null && frameworks+=("nestjs")
    fi

    # Go frameworks
    if [[ -f "go.mod" ]]; then
        grep -q "gin-gonic/gin" go.mod 2>/dev/null && frameworks+=("gin")
        grep -q "gofiber/fiber" go.mod 2>/dev/null && frameworks+=("fiber")
    fi

    # Java frameworks
    if [[ -f "pom.xml" ]] || [[ -f "build.gradle" ]]; then
        grep -q "spring-boot" pom.xml build.gradle 2>/dev/null && frameworks+=("springboot")
    fi

    echo "${frameworks[@]:-}"
}

# Detect cloud providers
detect_cloud_providers() {
    local providers=()

    # Vercel
    if [[ -f "vercel.json" ]] || [[ -d ".vercel" ]]; then
        providers+=("vercel")
    fi

    # AWS
    if [[ -f ".aws-sam" ]] || [[ -d "cdk.out" ]] || [[ -f "serverless.yml" ]]; then
        providers+=("aws")
    fi

    # Azure
    if [[ -f "azure-pipelines.yml" ]] || [[ -d ".azure" ]]; then
        providers+=("azure")
    fi

    # GCP
    if [[ -f "app.yaml" ]] || [[ -f "cloudbuild.yaml" ]]; then
        providers+=("gcp")
    fi

    echo "${providers[@]:-}"
}

# Detect project maturity level
detect_maturity_level() {
    local production_indicators=0
    local preproduction_indicators=0

    # Production indicators (need 3+ for production level)
    # CI/CD with deployment
    if [[ -d ".github/workflows" ]] || [[ -d ".gitlab-ci.yml" ]] || [[ -d ".circleci" ]]; then
        ((production_indicators++))
    fi

    # Production environment files
    if [[ -f ".env.production" ]] || [[ -f "config/production.yml" ]]; then
        ((production_indicators++))
    fi

    # Monitoring/observability
    if grep -rq "sentry\|datadog\|newrelic\|prometheus" . 2>/dev/null; then
        ((production_indicators++))
    fi

    # Security scanning
    if [[ -f ".github/workflows/security.yml" ]] || grep -rq "snyk\|dependabot" .github 2>/dev/null; then
        ((production_indicators++))
    fi

    # Pre-production indicators (need 2+ for pre-production level)
    # Testing framework present
    if [[ -f "pytest.ini" ]] || [[ -f "jest.config.js" ]] || [[ -f "vitest.config.ts" ]] || grep -q "\"test\":" package.json 2>/dev/null; then
        ((preproduction_indicators++))
    fi

    # CI/CD present (even if basic)
    if [[ -d ".github/workflows" ]] || [[ -f ".gitlab-ci.yml" ]] || [[ -f "Jenkinsfile" ]]; then
        ((preproduction_indicators++))
    fi

    # Linting configuration
    if [[ -f ".eslintrc.json" ]] || [[ -f ".eslintrc.js" ]] || [[ -f "pylintrc" ]] || [[ -f ".pylintrc" ]] || [[ -f "pyproject.toml" ]]; then
        ((preproduction_indicators++))
    fi

    # Determine maturity level
    if [[ $production_indicators -ge 3 ]]; then
        echo "production"
    elif [[ $preproduction_indicators -ge 2 ]]; then
        echo "pre-production"
    else
        echo "mvp-poc"
    fi
}

# Download rule file from repository
download_rule() {
    local rule_path="$1"
    local output_path="$2"

    mkdir -p "$(dirname "$output_path")"

    if command -v curl &> /dev/null; then
        curl -fsSL "${RULES_REPO_URL}/${rule_path}" -o "$output_path" 2>/dev/null
    elif command -v wget &> /dev/null; then
        wget -q "${RULES_REPO_URL}/${rule_path}" -O "$output_path" 2>/dev/null
    else
        log_error "Neither curl nor wget found. Please install one of them."
        exit 1
    fi
}

# Load base rules (always loaded)
load_base_rules() {
    log_info "Loading base universal rules..."

    local base_rules=(
        # Core workflow
        "base/git-workflow.md"
        "base/code-quality.md"
        "base/development-workflow.md"

        # Testing & quality
        "base/testing-philosophy.md"
        "base/testing-atdd.md"
        "base/refactoring-patterns.md"

        # Architecture & design
        "base/architecture-principles.md"
        "base/12-factor-app.md"
        "base/specification-driven-development.md"

        # Security & operations
        "base/security-principles.md"
        "base/cicd-comprehensive.md"
        "base/configuration-management.md"
        "base/metrics-standards.md"
        "base/operations-automation.md"

        # AI development
        "base/ai-assisted-development.md"
        "base/ai-ethics-governance.md"
        "base/ai-model-lifecycle.md"
        "base/knowledge-management.md"
        "base/parallel-development.md"

        # Advanced practices
        "base/chaos-engineering.md"
        "base/lean-development.md"
        "base/tool-design.md"
        "base/project-maturity-levels.md"
    )

    for rule in "${base_rules[@]}"; do
        local output="${CACHE_DIR}/${rule}"
        if download_rule "$rule" "$output"; then
            log_success "Loaded $(basename "$rule")"
        else
            log_warn "Failed to load $(basename "$rule")"
        fi
    done
}

# Load language-specific rules
load_language_rules() {
    local language="$1"
    log_info "Loading $language rules..."

    local lang_rules=(
        "languages/${language}/coding-standards.md"
        "languages/${language}/testing.md"
    )

    for rule in "${lang_rules[@]}"; do
        local output="${CACHE_DIR}/${rule}"
        if download_rule "$rule" "$output"; then
            log_success "Loaded $(basename "$rule")"
        else
            log_warn "No $(basename "$rule") for $language"
        fi
    done
}

# Load framework-specific rules
load_framework_rules() {
    local framework="$1"
    log_info "Loading $framework framework rules..."

    local fw_rule="frameworks/${framework}/best-practices.md"
    local output="${CACHE_DIR}/${fw_rule}"

    if download_rule "$fw_rule" "$output"; then
        log_success "Loaded ${framework} best practices"
    else
        log_warn "No framework rules for $framework"
    fi
}

# Load cloud provider rules
load_cloud_rules() {
    local provider="$1"
    log_info "Loading $provider cloud rules..."

    local cloud_rules=(
        "cloud/${provider}/deployment-best-practices.md"
        "cloud/${provider}/environment-configuration.md"
        "cloud/${provider}/security-practices.md"
        "cloud/${provider}/performance-optimization.md"
        "cloud/${provider}/reliability-observability.md"
        "cloud/${provider}/cost-optimization.md"
    )

    for rule in "${cloud_rules[@]}"; do
        local output="${CACHE_DIR}/${rule}"
        if download_rule "$rule" "$output"; then
            log_success "Loaded $(basename "$rule")"
        else
            log_warn "No $(basename "$rule") for $provider"
        fi
    done
}

# Generate hierarchical rule structure
generate_claude_rules_hierarchical() {
    log_info "Generating Claude Code rules (hierarchical structure)..."

    # Create directory structure
    mkdir -p .claude/rules/{base,languages,frameworks,cloud}

    # Detect what was loaded for the index
    local languages_loaded
    local frameworks_loaded
    read -ra languages_loaded <<< "$(detect_language)"
    read -ra frameworks_loaded <<< "$(detect_frameworks)"

    # Copy base rules
    if [[ -d "${CACHE_DIR}/base" ]]; then
        cp -r "${CACHE_DIR}/base/"*.md .claude/rules/base/ 2>/dev/null || true
    fi

    # Copy language rules
    for lang in "${languages_loaded[@]:-}"; do
        if [[ -n "$lang" ]] && [[ -d "${CACHE_DIR}/languages/${lang}" ]]; then
            mkdir -p ".claude/rules/languages/${lang}"
            cp -r "${CACHE_DIR}/languages/${lang}/"*.md ".claude/rules/languages/${lang}/" 2>/dev/null || true
        fi
    done

    # Copy framework rules
    for fw in "${frameworks_loaded[@]:-}"; do
        if [[ -n "$fw" ]] && [[ -d "${CACHE_DIR}/frameworks/${fw}" ]]; then
            mkdir -p ".claude/rules/frameworks/${fw}"
            cp -r "${CACHE_DIR}/frameworks/${fw}/"*.md ".claude/rules/frameworks/${fw}/" 2>/dev/null || true
        fi
    done

    # Copy cloud rules if any
    if [[ -d "${CACHE_DIR}/cloud" ]]; then
        cp -r "${CACHE_DIR}/cloud/"* .claude/rules/cloud/ 2>/dev/null || true
    fi

    # Generate index.json
    generate_rule_index "${languages_loaded[@]:-}" "${frameworks_loaded[@]:-}"

    # Generate AGENTS.md entry point
    generate_agents_md "${languages_loaded[@]:-}" "${frameworks_loaded[@]:-}"

    log_success "Generated .claude/AGENTS.md and .claude/rules/"
}

# Generate rule index JSON
generate_rule_index() {
    local languages_loaded=("$@")
    local output=".claude/rules/index.json"

    if [[ -f "${SCRIPT_DIR}/rules-config.json" ]] && command -v python3 &> /dev/null; then
        python3 <<PYTHON
import json
import os

try:
    with open("${SCRIPT_DIR}/rules-config.json") as f:
        config = json.load(f)

    languages_loaded = [l for l in "${languages_loaded[@]:-}".split() if l]

    index = {
        "generated_at": "$(date -u +"%Y-%m-%d %H:%M:%S UTC")",
        "detected": {
            "languages": languages_loaded,
            "frameworks": []
        },
        "rules": {
            "base": [],
            "languages": {},
            "frameworks": {}
        }
    }

    # Base rules
    for rule in config.get("base_rules", []):
        index["rules"]["base"].append({
            "name": rule["name"],
            "file": ".claude/rules/" + rule["file"],
            "when": rule["when"],
            "always_load": rule.get("always_load", False)
        })

    # Language rules
    for lang_key in languages_loaded:
        if lang_key in config.get("languages", {}):
            lang = config["languages"][lang_key]
            index["rules"]["languages"][lang_key] = {
                "display_name": lang["display_name"],
                "rules": []
            }
            for rule in lang.get("rules", []):
                index["rules"]["languages"][lang_key]["rules"].append({
                    "name": rule["name"],
                    "file": ".claude/rules/" + rule["file"],
                    "when": rule["when"]
                })

    with open("${output}", "w") as f:
        json.dump(index, f, indent=2)

except Exception as e:
    print(f"Warning: Could not generate index.json: {e}")
PYTHON
    fi
}

# Generate AGENTS.md entry point
generate_agents_md() {
    local languages_loaded=("$@")
    local output=".claude/AGENTS.md"

    cat > "$output" <<'EOF'
# Development Agent Configuration

**Last updated:** $(date -u +"%Y-%m-%d %H:%M:%S UTC")

## 🎯 Progressive Disclosure Rule System

This directory contains development rules organized hierarchically for **on-demand loading**.

**DO NOT load all rule files at once.** Use progressive disclosure to load only relevant rules.

---

## 📁 Directory Structure

```
.claude/rules/
├── base/              # Universal rules (language-agnostic)
├── languages/         # Language-specific rules
├── frameworks/        # Framework-specific rules
├── cloud/             # Cloud provider rules
└── index.json         # Machine-readable rule index
```

---

## 🔍 Discovery Process

### Step 1: Analyze User Request

Identify from the user's question:
- **Language**: Python (.py), TypeScript (.ts/.tsx), Go (.go), etc.
- **Framework**: React, FastAPI, Django, Express, etc.
- **Task type**: Testing, refactoring, code review, new feature, etc.

### Step 2: Load Relevant Rules

Use the **Read tool** to load specific rule files:

**For every task:**
```
Read .claude/rules/base/code-quality.md
```

**For language-specific tasks:**
```
Python code → Read .claude/rules/languages/python/coding-standards.md
TypeScript  → Read .claude/rules/languages/typescript/coding-standards.md
Go code     → Read .claude/rules/languages/go/coding-standards.md
```

**For framework-specific tasks:**
```
FastAPI → Read .claude/rules/frameworks/fastapi/best-practices.md
React   → Read .claude/rules/frameworks/react/best-practices.md
Django  → Read .claude/rules/frameworks/django/best-practices.md
```

**For testing tasks:**
```
Read .claude/rules/base/testing-philosophy.md
Read .claude/rules/languages/{language}/testing.md
```

### Step 3: Announce What You Loaded

Show visual feedback:

```markdown
📚 **Rules Loaded for This Task:**
✓ Code Quality (.claude/rules/base/code-quality.md)
✓ Python Coding Standards (.claude/rules/languages/python/coding-standards.md)
✓ FastAPI Best Practices (.claude/rules/frameworks/fastapi/best-practices.md)
```

---

## 📋 Rule Index - This Project

**Detected Configuration:**
EOF

    # Add detected languages and frameworks
    if [[ ${#languages_loaded[@]} -gt 0 ]]; then
        echo "- Languages: ${languages_loaded[*]}" >> "$output"
    else
        echo "- Languages: None detected (base rules only)" >> "$output"
    fi

    cat >> "$output" <<'EOF'

**Available Rules:**

### Base Rules (Always Available)

| Rule | File | When to Use |
|------|------|-------------|
| Code Quality | `base/code-quality.md` | Every task |
| Testing Philosophy | `base/testing-philosophy.md` | Testing tasks |
| Security Principles | `base/security-principles.md` | Security-relevant tasks |
| Git Workflow | `base/git-workflow.md` | Commits/PRs |
| Architecture Principles | `base/architecture-principles.md` | Architecture discussions |
| 12-Factor App | `base/12-factor-app.md` | Deployment/SaaS |
| Refactoring Patterns | `base/refactoring-patterns.md` | Refactoring tasks |

EOF

    # Add language rules if detected
    if [[ ${#languages_loaded[@]} -gt 0 ]]; then
        cat >> "$output" <<'EOF'
### Language-Specific Rules

EOF
        if [[ " ${languages_loaded[*]} " =~ " python " ]]; then
            cat >> "$output" <<'EOF'
**Python:**
- `languages/python/coding-standards.md` - Type hints, PEP 8, mypy
- `languages/python/testing.md` - pytest, fixtures, mocking

EOF
        fi

        if [[ " ${languages_loaded[*]} " =~ " typescript " ]]; then
            cat >> "$output" <<'EOF'
**TypeScript:**
- `languages/typescript/coding-standards.md` - Strict mode, ESLint, Prettier
- `languages/typescript/testing.md` - Jest, Vitest, React Testing Library

EOF
        fi

        if [[ " ${languages_loaded[*]} " =~ " go " ]]; then
            cat >> "$output" <<'EOF'
**Go:**
- `languages/go/coding-standards.md` - Effective Go, conventions
- `languages/go/testing.md` - Table-driven tests, testify

EOF
        fi
    fi

    cat >> "$output" <<'EOF'

---

## 💡 Usage Examples

### Example 1: Python Testing Task

**User**: "Write pytest tests for this function"

**Your workflow**:
1. Identify: Python + Testing task
2. Load rules:
   ```
   Read .claude/rules/base/testing-philosophy.md
   Read .claude/rules/languages/python/testing.md
   ```
3. Announce:
   ```
   📚 Rules Loaded: Testing Philosophy + Python Testing
   ```
4. Apply rules and write tests

**Token usage**: ~15K (vs 45K if loading all rules)

---

### Example 2: React Component Review

**User**: "Review this React component"

**Your workflow**:
1. Identify: TypeScript + React + Code Review
2. Load rules:
   ```
   Read .claude/rules/base/code-quality.md
   Read .claude/rules/languages/typescript/coding-standards.md
   Read .claude/rules/frameworks/react/best-practices.md
   ```
3. Announce:
   ```
   📚 Rules Loaded: Code Quality + TypeScript Standards + React Best Practices
   ```
4. Review against loaded rules

**Token usage**: ~18K (60% savings)

---

### Example 3: Multi-Language Project

**User**: "Review the Python API and React frontend"

**Your workflow**:
1. Identify: Python + TypeScript + FastAPI + React
2. Load rules:
   ```
   # Backend
   Read .claude/rules/base/code-quality.md
   Read .claude/rules/languages/python/coding-standards.md
   Read .claude/rules/frameworks/fastapi/best-practices.md

   # Frontend
   Read .claude/rules/languages/typescript/coding-standards.md
   Read .claude/rules/frameworks/react/best-practices.md
   ```
3. Announce what's loaded for each part
4. Apply appropriate rules to each codebase

---

## 📊 Token Efficiency

**Before (monolithic .claude/RULES.md):**
- All rules loaded: ~45K tokens
- Available for code: ~55K tokens

**After (hierarchical .claude/rules/):**
- Selective loading: ~12-18K tokens (2-3 files)
- Available for code: ~82-88K tokens
- **Improvement: 60-80% more context for code!**

---

## 🔧 Advanced: Using index.json

For programmatic rule discovery:

```bash
# See all available rules
cat .claude/rules/index.json | jq '.rules'

# Find rules for a specific language
cat .claude/rules/index.json | jq '.rules.languages.python'

# List all base rules
cat .claude/rules/index.json | jq '.rules.base[] | .name'
```

---

## ⚠️ Important Guidelines

1. **Start Narrow**: Load base + 1-2 specific rules
2. **Expand as Needed**: Add more if task requires
3. **Always Announce**: Show which rules you loaded
4. **Cite Sources**: Reference specific rules when making recommendations
5. **Stay Focused**: Don't load unrelated rules

**Goal**: Load ~10-15K of relevant rules, leaving 85-90K for code analysis.

---

## 🆘 Troubleshooting

**Q: What if no rules match the task?**
A: Load `base/code-quality.md` as a safe default.

**Q: Should I load all base rules?**
A: No! Only load relevant base rules for the task type.

**Q: What about commits/git tasks?**
A: Load `base/git-workflow.md` specifically for those tasks.

**Q: Can I load multiple language rules?**
A: Yes, for multi-language projects, load rules for each language used.

---

*Generated by progressive disclosure sync system*
EOF

    log_success "Generated $output"
}

# Generate tool-specific output files (legacy monolithic format)
generate_claude_rules_monolithic() {
    log_info "Generating Claude Code rules (monolithic format)..."

    local output=".claude/RULES.md"
    mkdir -p .claude

    # Detect what was loaded for the index
    local languages_loaded
    local frameworks_loaded
    read -ra languages_loaded <<< "$(detect_language)"
    read -ra frameworks_loaded <<< "$(detect_frameworks)"

    {
        echo "# AI Development Rules"
        echo ""
        echo "**Last updated:** $(date -u +"%Y-%m-%d %H:%M:%S UTC")"
        echo ""
        echo "---"
        echo ""
        echo "## 🎯 PROGRESSIVE DISCLOSURE: How to Use These Rules"
        echo ""
        echo "This file contains multiple rule categories. **DO NOT apply all rules to every task.**"
        echo ""
        echo "### Your Progressive Discovery Process"
        echo ""
        echo "1. **Identify Task Context**"
        echo "   - What language is the user working with? (file extensions, imports, syntax)"
        echo "   - What framework is involved? (imports, config files, patterns)"
        echo "   - What type of task? (testing, refactoring, new feature, bug fix, code review)"
        echo ""
        echo "2. **Load ONLY Relevant Sections**"
        echo "   - For Python code → Read 'Python Coding Standards' + 'Python Testing'"
        echo "   - For React component → Read 'React Best Practices' + 'Typescript Coding Standards'"
        echo "   - For testing tasks → Read 'Testing Philosophy' + language-specific testing"
        echo "   - For code review → Read 'Code Quality' + language-specific standards"
        echo ""
        echo "3. **Base Rules Application**"
        echo "   - **Always consider:** Code Quality Standards, Security Principles"
        echo "   - **Context-dependent:**"
        echo "     * Git Workflow → Only for commit/PR tasks"
        echo "     * Testing Philosophy → Only for testing tasks"
        echo "     * 12-Factor App → Only for architecture/deployment discussions"
        echo ""
        echo "4. **Discovery Pattern Examples**"
        echo "   \`\`\`"
        echo "   User: 'Review this Python function'"
        echo "   → Load: Code Quality + Python Coding Standards"
        echo ""
        echo "   User: 'Write pytest tests for this FastAPI endpoint'"
        echo "   → Load: Testing Philosophy + Python Testing + FastAPI Best Practices"
        echo ""
        echo "   User: 'Fix this React component's rendering'"
        echo "   → Load: Code Quality + TypeScript Coding Standards + React Best Practices"
        echo ""
        echo "   User: 'Help me commit these changes'"
        echo "   → Load: Git Workflow + Code Quality"
        echo "   \`\`\`"
        echo ""
        echo "### 📋 Rule Index - This Project"
        echo ""
        echo "**Detected Configuration:**"
        if [[ ${#languages_loaded[@]} -gt 0 ]]; then
            echo "- Languages: ${languages_loaded[*]}"
        else
            echo "- Languages: None detected (base rules only)"
        fi
        if [[ ${#frameworks_loaded[@]} -gt 0 ]]; then
            echo "- Frameworks: ${frameworks_loaded[*]}"
        else
            echo "- Frameworks: None detected"
        fi
        echo ""
        echo "**Available Rules Below:**"
        echo ""
        echo "| Category | When to Apply | Section Name |"
        echo "|----------|---------------|--------------|"

        # Generate rule index from config file (if exists) or fallback to hardcoded
        if [[ -f "${SCRIPT_DIR}/rules-config.json" ]] && command -v python3 &> /dev/null; then
            # Use Python to parse JSON and generate table
            python3 <<PYTHON
import json
import sys

try:
    with open("${SCRIPT_DIR}/rules-config.json") as f:
        config = json.load(f)

    # Base rules
    for rule in config.get("base_rules", []):
        print(f"| Base | {rule['when']} | {rule['name']} |")

    # Language rules
    languages_loaded = "${languages_loaded[*]:-}".split()
    for lang_key in languages_loaded:
        if lang_key in config.get("languages", {}):
            lang = config["languages"][lang_key]
            for rule in lang.get("rules", []):
                print(f"| {lang['display_name']} | {rule['when']} | {rule['name']} |")

    # Framework rules
    frameworks_loaded = "${frameworks_loaded[*]:-}".split()
    for fw_key in frameworks_loaded:
        if fw_key in config.get("frameworks", {}):
            fw = config["frameworks"][fw_key]
            for rule in fw.get("rules", []):
                print(f"| {fw['display_name']} | {rule['when']} | {rule['name']} |")

except Exception as e:
    # Fallback to basic output
    print("| Base | Every task | Code Quality |")
    print("| Base | Testing tasks | Testing Philosophy |")
    sys.exit(0)
PYTHON
        else
            # Fallback if config doesn't exist or no Python
            echo "| Base | Every task | Code Quality |"
            echo "| Base | Security-relevant tasks | Security Principles |"
            echo "| Base | Testing tasks | Testing Philosophy |"
            echo "| Base | Commits/PRs | Git Workflow |"

            # Languages
            if [[ ${#languages_loaded[@]} -gt 0 ]] && [[ " ${languages_loaded[*]} " =~ " python " ]]; then
                echo "| Python | Python files (.py) | Python Coding Standards |"
                echo "| Python | Python testing | Python Testing |"
            fi
            if [[ ${#languages_loaded[@]} -gt 0 ]] && [[ " ${languages_loaded[*]} " =~ " typescript " ]]; then
                echo "| TypeScript | TypeScript files (.ts, .tsx) | Typescript Coding Standards |"
                echo "| TypeScript | TypeScript testing | Typescript Testing |"
            fi
            if [[ ${#languages_loaded[@]} -gt 0 ]] && [[ " ${languages_loaded[*]} " =~ " go " ]]; then
                echo "| Go | Go files (.go) | Go Coding Standards |"
                echo "| Go | Go testing | Go Testing |"
            fi

            # Frameworks
            if [[ ${#frameworks_loaded[@]} -gt 0 ]] && [[ " ${frameworks_loaded[*]} " =~ " react " ]]; then
                echo "| React | React components | React Best Practices |"
            fi
            if [[ ${#frameworks_loaded[@]} -gt 0 ]] && [[ " ${frameworks_loaded[*]} " =~ " django " ]]; then
                echo "| Django | Django models/views/APIs | Django Best Practices |"
            fi
            if [[ ${#frameworks_loaded[@]} -gt 0 ]] && [[ " ${frameworks_loaded[*]} " =~ " fastapi " ]]; then
                echo "| FastAPI | FastAPI endpoints/models | Fastapi Best Practices |"
            fi
        fi
        echo ""
        echo "### 💡 Token Efficiency Tips"
        echo ""
        echo "- **Start narrow**: Load base + specific language/framework only"
        echo "- **Expand as needed**: Add more sections if task requires"
        echo "- **Skip irrelevant**: Don't load React rules for Python backend work"
        echo "- **Typical load**: 2-3 sections per task (not all 8+)"
        echo ""
        echo "### ⚠️ Important"
        echo ""
        echo "Loading ALL rules below will consume 30K-50K tokens. Be selective!"
        echo "Your goal: Load ~10K-15K of relevant rules, leaving context for code."
        echo ""
        echo "---"
        echo ""
        echo "# Development Rules"
        echo ""

        # Combine all cached rules
        find "${CACHE_DIR}" -name "*.md" -type f | sort | while read -r file; do
            echo "## $(basename "$file" .md | sed 's/-/ /g' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) substr($i,2)}1')"
            echo ""
            cat "$file"
            echo ""
            echo "---"
            echo ""
        done
    } > "$output"

    log_success "Generated $output"
}

generate_cursor_rules() {
    log_info "Generating Cursor rules..."

    local output=".cursorrules"

    {
        echo "# AI Development Rules (Cursor)"
        echo "# Last updated: $(date -u +"%Y-%m-%d %H:%M:%S UTC")"
        echo ""

        # Combine all cached rules
        find "${CACHE_DIR}" -name "*.md" -type f | sort | while read -r file; do
            cat "$file"
            echo ""
        done
    } > "$output"

    log_success "Generated $output"
}

generate_copilot_rules() {
    log_info "Generating GitHub Copilot rules..."

    local output=".github/copilot-instructions.md"
    mkdir -p .github

    {
        echo "# GitHub Copilot Instructions"
        echo ""
        echo "Last updated: $(date -u +"%Y-%m-%d %H:%M:%S UTC")"
        echo ""

        # Combine all cached rules
        find "${CACHE_DIR}" -name "*.md" -type f | sort | while read -r file; do
            cat "$file"
            echo ""
        done
    } > "$output"

    log_success "Generated $output"
}

generate_gemini_rules() {
    log_info "Generating Gemini/Codegemma rules..."

    local rules_output=".gemini/rules.md"
    local context_output=".gemini/context.json"
    mkdir -p .gemini

    # Generate rules.md
    {
        echo "# Gemini Code Assistant - Development Rules"
        echo ""
        echo "**Generated:** $(date -u +"%Y-%m-%d %H:%M:%S UTC")"
        echo "**Source:** https://github.com/PaulDuvall/centralized-rules"
        echo ""
        echo "## Project Configuration"
        echo ""

        # Combine all cached rules
        find "${CACHE_DIR}" -name "*.md" -type f | sort | while read -r file; do
            cat "$file"
            echo ""
        done
    } > "$rules_output"

    # Generate context.json
    {
        echo "{"
        echo "  \"version\": \"1.0.0\","
        echo "  \"generated\": \"$(date -u +"%Y-%m-%d %H:%M:%S UTC")\","
        echo "  \"project\": {"
        echo "    \"name\": \"$(basename "$(pwd)")\","
        echo "    \"type\": \"development\""
        echo "  },"
        echo "  \"technologies\": {"
        echo "    \"languages\": $(printf '%s\n' "${languages[@]:-}" | jq -R . | jq -s .),"
        echo "    \"frameworks\": $(printf '%s\n' "${frameworks[@]:-}" | jq -R . | jq -s .),"
        echo "    \"cloud_providers\": $(printf '%s\n' "${cloud_providers[@]:-}" | jq -R . | jq -s .)"
        echo "  },"
        echo "  \"maturity_level\": \"$maturity_level\","
        echo "  \"rules_source\": {"
        echo "    \"repository\": \"https://github.com/PaulDuvall/centralized-rules\","
        echo "    \"last_sync\": \"$(date -u +"%Y-%m-%d %H:%M:%S UTC")\""
        echo "  }"
        echo "}"
    } > "$context_output"

    log_success "Generated $rules_output"
    log_success "Generated $context_output"
}

# Main sync function
sync_rules() {
    local tool="${1:-all}"

    log_info "Starting AI rules synchronization..."
    echo ""

    # Create cache directory
    mkdir -p "$CACHE_DIR"

    # Detect project configuration
    local languages
    mapfile -t languages < <(detect_language)
    local frameworks
    mapfile -t frameworks < <(detect_frameworks)
    local cloud_providers
    mapfile -t cloud_providers < <(detect_cloud_providers)
    local maturity_level
    maturity_level=$(detect_maturity_level)

    if [[ ${#languages[@]} -eq 0 ]]; then
        log_warn "No recognized language detected. Loading base rules only."
    else
        log_info "Detected languages: ${languages[*]}"
    fi

    if [[ ${#frameworks[@]} -gt 0 ]]; then
        log_info "Detected frameworks: ${frameworks[*]}"
    fi

    if [[ ${#cloud_providers[@]} -gt 0 ]]; then
        log_info "Detected cloud providers: ${cloud_providers[*]}"
    fi

    log_info "Detected maturity level: $maturity_level"
    log_info "💡 Apply rigor appropriate for $maturity_level (see base/project-maturity-levels.md)"
    echo ""

    # Load base rules (always)
    load_base_rules
    echo ""

    # Load language-specific rules
    for lang in "${languages[@]:-}"; do
        [[ -n "$lang" ]] && load_language_rules "$lang"
        echo ""
    done

    # Load framework-specific rules
    for fw in "${frameworks[@]:-}"; do
        [[ -n "$fw" ]] && load_framework_rules "$fw"
        echo ""
    done

    # Load cloud provider rules
    for provider in "${cloud_providers[@]:-}"; do
        [[ -n "$provider" ]] && load_cloud_rules "$provider"
        echo ""
    done

    # Generate tool-specific outputs
    case "$tool" in
        claude)
            generate_claude_rules_hierarchical
            ;;
        cursor)
            generate_cursor_rules
            ;;
        copilot)
            generate_copilot_rules
            ;;
        gemini)
            generate_gemini_rules
            ;;
        all)
            generate_claude_rules_hierarchical
            generate_cursor_rules
            generate_copilot_rules
            generate_gemini_rules
            ;;
        *)
            log_error "Unknown tool: $tool"
            log_error "Supported tools: claude, cursor, copilot, gemini, all"
            exit 1
            ;;
    esac

    echo ""
    log_success "Synchronization complete!"
    log_info "Rules cached in: $CACHE_DIR"
}

# Auto-detect AI tool environment
detect_ai_tool() {
    # Check environment variables for AI tool detection
    if [[ -n "${CLAUDE_CODE_VERSION:-}" ]] || [[ -d ".claude" ]]; then
        echo "claude"
    elif [[ -n "${CURSOR_VERSION:-}" ]] || [[ -f ".cursorrules" ]]; then
        echo "cursor"
    elif [[ -n "${GITHUB_COPILOT:-}" ]] || [[ -d ".github/copilot-instructions.md" ]]; then
        echo "copilot"
    elif [[ -n "${GEMINI_AI:-}" ]] || [[ -d ".gemini" ]]; then
        echo "gemini"
    else
        # Default to all if no specific tool detected
        echo "all"
    fi
}

# Parse command-line arguments
tool=""
while [[ $# -gt 0 ]]; do
    case $1 in
        --tool)
            tool="$2"
            shift 2
            ;;
        --help|-h)
            echo "Usage: $0 [--tool claude|cursor|copilot|gemini|all]"
            echo ""
            echo "Options:"
            echo "  --tool TOOL    Generate rules for specific tool (auto-detected if omitted)"
            echo "  --help, -h     Show this help message"
            echo ""
            echo "Supported tools: claude, cursor, copilot, gemini, all"
            echo ""
            echo "Auto-detection:"
            echo "  - Claude Code: Checks for CLAUDE_CODE_VERSION env var or .claude/ directory"
            echo "  - Cursor: Checks for CURSOR_VERSION env var or .cursorrules file"
            echo "  - GitHub Copilot: Checks for GITHUB_COPILOT env var"
            echo "  - Gemini: Checks for GEMINI_AI env var or .gemini/ directory"
            echo "  - Defaults to 'all' if no tool detected"
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Auto-detect if not specified
if [[ -z "$tool" ]]; then
    tool=$(detect_ai_tool)
    log_info "Auto-detected AI tool: $tool"
fi

# Run sync
sync_rules "$tool"
