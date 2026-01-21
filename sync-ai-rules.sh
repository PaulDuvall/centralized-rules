#!/usr/bin/env bash

# sync-ai-rules.sh - Progressive Disclosure AI Rules Synchronization
#
# This script detects your project's language and framework, then dynamically
# loads only the relevant rules from a centralized rules repository.
#
# Usage:
#   ./sync-ai-rules.sh [--tool claude|cursor|copilot|gemini|all] [--dry-run] [--verbose]
#
# Examples:
#   ./sync-ai-rules.sh                    # Auto-detect and sync for all tools
#   ./sync-ai-rules.sh --tool claude      # Sync only for Claude
#   ./sync-ai-rules.sh --tool cursor      # Sync only for Cursor
#   ./sync-ai-rules.sh --tool gemini      # Sync only for Gemini/Codegemma
#   ./sync-ai-rules.sh --dry-run          # Preview merges without applying
#   ./sync-ai-rules.sh --verbose          # Show detailed override processing

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR

# Source shared libraries
# shellcheck source=lib/logging.sh
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/lib/logging.sh"
# shellcheck source=lib/detection.sh
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/lib/detection.sh"
# shellcheck source=lib/override.sh
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/lib/override.sh"
readonly RULES_REPO_URL="${AI_RULES_REPO:-https://raw.githubusercontent.com/PaulDuvall/centralized-rules/main}"

# Override processing options
DRY_RUN=false
VERBOSE=false
readonly RULES_DIR=".ai-rules"
readonly CACHE_DIR="${RULES_DIR}/.cache"

# NOTE: detect_language, detect_frameworks, detect_cloud_providers, and detect_tools
# are now provided by lib/detection.sh

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

# Load development tool rules
load_tool_rules() {
    local tool="$1"
    log_info "Loading $tool tool rules..."

    local tool_rule="tools/${tool}/issue-tracking.md"
    local output="${CACHE_DIR}/${tool_rule}"

    if download_rule "$tool_rule" "$output"; then
        log_success "Loaded ${tool} issue tracking rules"
    else
        log_warn "No tool rules for $tool"
    fi
}

# Generate hierarchical rule structure
generate_claude_rules_hierarchical() {
    log_info "Generating Claude Code rules (hierarchical structure)..."

    # Create directory structure
    mkdir -p .claude/rules/{base,languages,frameworks,cloud,tools}

    # Detect what was loaded for the index
    local languages_loaded
    local frameworks_loaded
    local tools_loaded
    read -ra languages_loaded <<< "$(detect_language)"
    read -ra frameworks_loaded <<< "$(detect_frameworks)"
    read -ra tools_loaded <<< "$(detect_tools)"

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

    # Copy tool rules
    for tool in "${tools_loaded[@]:-}"; do
        if [[ -n "$tool" ]] && [[ -d "${CACHE_DIR}/tools/${tool}" ]]; then
            mkdir -p ".claude/rules/tools/${tool}"
            cp -r "${CACHE_DIR}/tools/${tool}/"*.md ".claude/rules/tools/${tool}/" 2>/dev/null || true
        fi
    done

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

# Write AGENTS.md header section
write_agents_md_header() {
    local output="$1"
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
}

# Write detected configuration section
write_agents_md_detected_config() {
    local output="$1"
    shift
    local languages_loaded=("$@")

    if [[ ${#languages_loaded[@]} -gt 0 ]]; then
        echo "- Languages: ${languages_loaded[*]}" >> "$output"
    else
        echo "- Languages: None detected (base rules only)" >> "$output"
    fi

    if [[ ${#tools_loaded[@]} -gt 0 ]]; then
        echo "- Development Tools: ${tools_loaded[*]}" >> "$output"
    fi
}

# Write base rules table
write_agents_md_base_rules() {
    local output="$1"
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
}

# Write language-specific rules section
write_agents_md_language_rules() {
    local output="$1"
    shift
    local languages_loaded=("$@")

    if [[ ${#languages_loaded[@]} -eq 0 ]]; then
        return
    fi

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
}

# Write tool rules section
write_agents_md_tool_rules() {
    local output="$1"

    if [[ ${#tools_loaded[@]} -eq 0 ]]; then
        return
    fi

    cat >> "$output" <<'EOF'
### Development Tools

EOF

    if [[ " ${tools_loaded[*]} " =~ " beads " ]]; then
        cat >> "$output" <<'EOF'
**Beads (Issue Tracking):**
- `tools/beads/issue-tracking.md` - Session protocols, issue creation, workflow management
- **When to load**: Session start/end, issue tracking, discovered work patterns
- **Integration**: Works alongside git-workflow.md and TodoWrite tool

EOF
    fi
}

# Write usage examples section
write_agents_md_usage_examples() {
    local output="$1"
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

### Example 4: Beads Session Workflow (If .beads/ detected)

**User**: "Let's start working on the authentication feature"

**Your workflow**:
1. Identify: Session start with beads issue tracking
2. Load rules:
   ```
   Read .claude/rules/tools/beads/issue-tracking.md
   Read .claude/rules/base/git-workflow.md
   ```
3. Follow session start protocol:
   ```bash
   bd ready --json
   ```
4. Show available issues and help user claim work
5. During session: File discovered work with `bd create`
6. At session end: Follow "Land the Plane" protocol (sync, push, suggest next work)

**When to load beads rule:**
- User mentions "bd", "beads", "beas" (misspelling), or "session"
- Session start/end workflows
- Issue tracking tasks
- Discovered work patterns

**Token usage**: ~20K (beads rule alone), use selectively for session boundaries

---
EOF
}

# Write footer sections
write_agents_md_footer() {
    local output="$1"
    cat >> "$output" <<'EOF'

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
}

# Generate AGENTS.md entry point (refactored)
generate_agents_md() {
    local languages_loaded=("$@")
    local output=".claude/AGENTS.md"

    write_agents_md_header "$output"
    write_agents_md_detected_config "$output" "${languages_loaded[@]}"
    write_agents_md_base_rules "$output"
    write_agents_md_language_rules "$output" "${languages_loaded[@]}"
    write_agents_md_tool_rules "$output"
    write_agents_md_usage_examples "$output"
    write_agents_md_footer "$output"

    log_success "Generated $output"
}

# Write RULES.md header with progressive disclosure
write_rules_md_header() {
    cat <<'EOF'
# AI Development Rules

**Last updated:** $(date -u +"%Y-%m-%d %H:%M:%S UTC")

---

## 🎯 PROGRESSIVE DISCLOSURE: How to Use These Rules

This file contains multiple rule categories. **DO NOT apply all rules to every task.**

### Your Progressive Discovery Process

1. **Identify Task Context**
   - What language is the user working with? (file extensions, imports, syntax)
   - What framework is involved? (imports, config files, patterns)
   - What type of task? (testing, refactoring, new feature, bug fix, code review)

2. **Load ONLY Relevant Sections**
   - For Python code → Read 'Python Coding Standards' + 'Python Testing'
   - For React component → Read 'React Best Practices' + 'Typescript Coding Standards'
   - For testing tasks → Read 'Testing Philosophy' + language-specific testing
   - For code review → Read 'Code Quality' + language-specific standards

3. **Base Rules Application**
   - **Always consider:** Code Quality Standards, Security Principles
   - **Context-dependent:**
     * Git Workflow → Only for commit/PR tasks
     * Testing Philosophy → Only for testing tasks
     * 12-Factor App → Only for architecture/deployment discussions

4. **Discovery Pattern Examples**
   ```
   User: 'Review this Python function'
   → Load: Code Quality + Python Coding Standards

   User: 'Write pytest tests for this FastAPI endpoint'
   → Load: Testing Philosophy + Python Testing + FastAPI Best Practices

   User: 'Fix this React component's rendering'
   → Load: Code Quality + TypeScript Coding Standards + React Best Practices

   User: 'Help me commit these changes'
   → Load: Git Workflow + Code Quality
   ```

### 📋 Rule Index - This Project

**Detected Configuration:**
EOF
}

# Write detected configuration for RULES.md
write_rules_md_detected_config() {
    local languages_loaded=("$@")
    shift $#
    local frameworks_loaded=("$@")

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
}

# Write rule index table
write_rules_md_rule_index() {
    local languages_loaded=("$@")

    echo ""
    echo "**Available Rules Below:**"
    echo ""
    echo "| Category | When to Apply | Section Name |"
    echo "|----------|---------------|--------------|"

    # Try to use config file, fall back to hardcoded
    if [[ -f "${SCRIPT_DIR}/rules-config.json" ]] && command -v python3 &> /dev/null; then
        python3 <<PYTHON
import json
import sys

try:
    with open("${SCRIPT_DIR}/rules-config.json") as f:
        config = json.load(f)

    for rule in config.get("base_rules", []):
        print(f"| Base | {rule['when']} | {rule['name']} |")

    languages_loaded = "${languages_loaded[*]:-}".split()
    for lang_key in languages_loaded:
        if lang_key in config.get("languages", {}):
            lang = config["languages"][lang_key]
            for rule in lang.get("rules", []):
                print(f"| {lang['display_name']} | {rule['when']} | {rule['name']} |")

    frameworks_loaded = "${frameworks_loaded[*]:-}".split()
    for fw_key in frameworks_loaded:
        if fw_key in config.get("frameworks", {}):
            fw = config["frameworks"][fw_key]
            for rule in fw.get("rules", []):
                print(f"| {fw['display_name']} | {rule['when']} | {rule['name']} |")

except Exception as e:
    print("| Base | Every task | Code Quality |")
    print("| Base | Testing tasks | Testing Philosophy |")
    sys.exit(0)
PYTHON
    else
        write_rules_md_rule_index_fallback "${languages_loaded[@]}"
    fi
}

# Fallback rule index if Python or config unavailable
write_rules_md_rule_index_fallback() {
    local languages_loaded=("$@")
    shift $#
    local frameworks_loaded=("$@")

    echo "| Base | Every task | Code Quality |"
    echo "| Base | Security-relevant tasks | Security Principles |"
    echo "| Base | Testing tasks | Testing Philosophy |"
    echo "| Base | Commits/PRs | Git Workflow |"

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

    if [[ ${#frameworks_loaded[@]} -gt 0 ]] && [[ " ${frameworks_loaded[*]} " =~ " react " ]]; then
        echo "| React | React components | React Best Practices |"
    fi
    if [[ ${#frameworks_loaded[@]} -gt 0 ]] && [[ " ${frameworks_loaded[*]} " =~ " django " ]]; then
        echo "| Django | Django models/views/APIs | Django Best Practices |"
    fi
    if [[ ${#frameworks_loaded[@]} -gt 0 ]] && [[ " ${frameworks_loaded[*]} " =~ " fastapi " ]]; then
        echo "| FastAPI | FastAPI endpoints/models | Fastapi Best Practices |"
    fi
}

# Write token efficiency tips
write_rules_md_token_tips() {
    cat <<'EOF'

### 💡 Token Efficiency Tips

- **Start narrow**: Load base + specific language/framework only
- **Expand as needed**: Add more sections if task requires
- **Skip irrelevant**: Don't load React rules for Python backend work
- **Typical load**: 2-3 sections per task (not all 8+)

### ⚠️ Important

Loading ALL rules below will consume 30K-50K tokens. Be selective!
Your goal: Load ~10K-15K of relevant rules, leaving context for code.

---

# Development Rules

EOF
}

# Combine all cached rules into output
write_rules_md_combined_rules() {
    find "${CACHE_DIR}" -name "*.md" -type f | sort | while read -r file; do
        echo "## $(basename "$file" .md | sed 's/-/ /g' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) substr($i,2)}1')"
        echo ""
        cat "$file"
        echo ""
        echo "---"
        echo ""
    done
}

# Generate tool-specific output files (legacy monolithic format, refactored)
generate_claude_rules_monolithic() {
    log_info "Generating Claude Code rules (monolithic format)..."

    local output=".claude/RULES.md"
    mkdir -p .claude

    local languages_loaded
    local frameworks_loaded
    read -ra languages_loaded <<< "$(detect_language)"
    read -ra frameworks_loaded <<< "$(detect_frameworks)"

    {
        write_rules_md_header
        write_rules_md_detected_config "${languages_loaded[@]}" "${frameworks_loaded[@]}"
        write_rules_md_rule_index "${languages_loaded[@]}" "${frameworks_loaded[@]}"
        write_rules_md_token_tips
        write_rules_md_combined_rules
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

# Detect all project configuration
detect_all_project_config() {
    local languages_var=$1
    local frameworks_var=$2
    local cloud_providers_var=$3
    local tools_var=$4
    local maturity_level_var=$5

    # Use eval for bash 3.2 compatibility (no nameref support)
    while IFS= read -r line; do
        eval "${languages_var}+=(\"${line}\")"
    done < <(detect_language)

    while IFS= read -r line; do
        eval "${frameworks_var}+=(\"${line}\")"
    done < <(detect_frameworks)

    while IFS= read -r line; do
        eval "${cloud_providers_var}+=(\"${line}\")"
    done < <(detect_cloud_providers)

    while IFS= read -r line; do
        eval "${tools_var}+=(\"${line}\")"
    done < <(detect_tools)

    eval "${maturity_level_var}=\$(detect_maturity_level)"
}

# Log detected project configuration
log_detected_config() {
    local lang_count=$1
    shift
    local languages=()
    local frameworks=()

    # Extract languages
    local i
    for ((i=0; i<lang_count; i++)); do
        languages+=("$1")
        shift
    done

    # Remaining arguments are frameworks
    frameworks=("$@")

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

    if [[ ${#tools[@]} -gt 0 ]]; then
        log_info "Detected development tools: ${tools[*]}"
    fi

    log_info "Detected maturity level: $maturity_level"
    log_info "💡 Apply rigor appropriate for $maturity_level (see base/project-maturity-levels.md)"
    echo ""
}

# Load all rules based on detected configuration
load_all_detected_rules() {
    local lang_count=$1
    shift
    local languages=()
    local frameworks=()

    # Extract languages
    local i
    for ((i=0; i<lang_count; i++)); do
        languages+=("$1")
        shift
    done

    # Remaining arguments are frameworks
    frameworks=("$@")

    load_base_rules
    echo ""

    for lang in "${languages[@]:-}"; do
        [[ -n "$lang" ]] && load_language_rules "$lang"
        echo ""
    done

    for fw in "${frameworks[@]:-}"; do
        [[ -n "$fw" ]] && load_framework_rules "$fw"
        echo ""
    done

    for provider in "${cloud_providers[@]:-}"; do
        [[ -n "$provider" ]] && load_cloud_rules "$provider"
        echo ""
    done

    for dev_tool in "${tools[@]:-}"; do
        [[ -n "$dev_tool" ]] && load_tool_rules "$dev_tool"
        echo ""
    done
}

# Generate tool-specific outputs
generate_tool_specific_outputs() {
    local tool="$1"

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
}

# Apply local overrides to generated rules
# Args: $1 = tool name
apply_local_overrides() {
    local tool="$1"

    # Only apply to claude or all
    if [[ "$tool" != "claude" ]] && [[ "$tool" != "all" ]]; then
        return 0
    fi

    # Check if overrides exist
    if [[ "$(detect_local_overrides ".claude")" != "true" ]]; then
        [[ "$VERBOSE" == "true" ]] && log_info "No local overrides found"
        return 0
    fi

    log_info "Processing local overrides..."

    if [[ "$DRY_RUN" == "true" ]]; then
        preview_overrides ".claude"
    else
        process_overrides ".claude"
        log_success "Local overrides applied"
    fi
}

# Preview what overrides would be applied (dry-run)
# Args: $1 = claude directory
preview_overrides() {
    local claude_dir="$1"
    local override_dir="${claude_dir}/rules-local"
    local rules_dir="${claude_dir}/rules"

    local config
    config=$(load_override_config "$claude_dir")

    log_info "[DRY-RUN] Override preview:"

    # Find all local override files
    while IFS= read -r -d '' local_file; do
        local rel_path="${local_file#"$override_dir"/}"
        local central_file="${rules_dir}/${rel_path}"

        # Check if excluded
        if [[ "$(should_exclude_rule "$rel_path" "$config")" == "true" ]]; then
            echo "  SKIP (excluded): $rel_path"
            continue
        fi

        local strategy
        strategy=$(get_merge_strategy "$rel_path" "$config")

        if [[ -f "$central_file" ]]; then
            echo "  MERGE ($strategy): $rel_path"
        else
            echo "  ADD: $rel_path"
        fi
    done < <(find "$override_dir" -name "*.md" -type f ! -name ".*" -print0 2>/dev/null)

    log_info "[DRY-RUN] No changes made"
}

# Main sync function (refactored)
sync_rules() {
    local tool="${1:-all}"

    log_info "Starting AI rules synchronization..."
    if [[ "$DRY_RUN" == "true" ]]; then
        log_warn "Running in DRY-RUN mode - no changes will be made to overrides"
    fi
    echo ""

    mkdir -p "$CACHE_DIR"

    # Detect project configuration
    local languages=()
    local frameworks=()
    local cloud_providers=()
    local tools=()
    local maturity_level=""
    detect_all_project_config languages frameworks cloud_providers tools maturity_level

    # Log detected configuration
    log_detected_config "${#languages[@]}" "${languages[@]}" "${frameworks[@]}"

    # Load all detected rules
    load_all_detected_rules "${#languages[@]}" "${languages[@]}" "${frameworks[@]}"

    # Generate outputs for specified tool(s)
    generate_tool_specific_outputs "$tool"

    # Apply local overrides (after generating base rules)
    apply_local_overrides "$tool"

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
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --verbose)
            VERBOSE=true
            shift
            ;;
        --help|-h)
            echo "Usage: $0 [--tool claude|cursor|copilot|gemini|all] [--dry-run] [--verbose]"
            echo ""
            echo "Options:"
            echo "  --tool TOOL    Generate rules for specific tool (auto-detected if omitted)"
            echo "  --dry-run      Preview override merges without applying changes"
            echo "  --verbose      Show detailed override processing information"
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
            echo ""
            echo "Local Overrides:"
            echo "  Place rule overrides in .claude/rules-local/ with same structure as rules/"
            echo "  Configure merge behavior in .claude/rules-config.local.json"
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
