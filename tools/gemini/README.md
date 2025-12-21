# Gemini/Codegemma Tool Configuration

This directory contains Google Gemini and Codegemma-specific configurations and templates for the centralized rules system.

## Overview

**Gemini** is Google's family of multimodal AI models, and **Codegemma** is a specialized variant optimized for code generation and understanding. This integration provides development rules in a format optimized for Gemini-based coding assistants.

## Output Format

Gemini/Codegemma uses a `.gemini/` directory structure similar to Claude Code's approach:

**Structure:**
```
project-root/
└── .gemini/
    ├── rules.md              # Main instructions file (monolithic)
    ├── context.json          # Project context metadata
    └── rules/                # Optional hierarchical structure (future)
        ├── base/
        ├── languages/
        ├── frameworks/
        └── cloud/
```

**Current Implementation:**
- **Monolithic Format:** Single `.gemini/rules.md` file with all rules
- **Context Metadata:** Structured JSON with project configuration
- **Future-Ready:** Directory structure prepared for hierarchical rules

**Characteristics:**
- **Google-Optimized:** Formatted for Gemini's instruction following
- **Metadata-Rich:** Includes structured project context for better code generation
- **Extensible:** Ready for future hierarchical rule support
- **Clear Sections:** Organized by concern for easy parsing

## File Format

### rules.md

Main instructions file in markdown format:

```markdown
# Gemini Code Assistant - Development Rules

Project: {{PROJECT_NAME}}
Generated: {{TIMESTAMP}}
Source: https://github.com/PaulDuvall/centralized-rules

## Project Configuration

Languages: {{LANGUAGES}}
Frameworks: {{FRAMEWORKS}}
Cloud: {{CLOUD_PROVIDERS}}
Maturity: {{MATURITY_LEVEL}}

## Instructions for Gemini

When generating code for this project:
1. Follow the coding standards defined below
2. Apply security principles to all generated code
3. Include appropriate error handling
4. Generate tests for new functionality
5. Add comments for complex logic
6. Consider the project's maturity level requirements

## Base Development Rules

### Git Workflow
[Content from base/git-workflow.md]

### Code Quality
[Content from base/code-quality.md]

### Testing
[Content from base/testing-philosophy.md]

### Security
[Content from base/security-principles.md]

[... additional sections ...]
```

### context.json

Structured metadata for enhanced code generation:

```json
{
  "project": {
    "name": "{{PROJECT_NAME}}",
    "type": "{{PROJECT_TYPE}}",
    "maturity_level": "{{MATURITY_LEVEL}}"
  },
  "technologies": {
    "languages": ["python", "typescript"],
    "frameworks": ["fastapi", "react"],
    "cloud_providers": ["vercel"],
    "package_managers": ["pip", "npm"]
  },
  "standards": {
    "code_style": {
      "indent": 4,
      "max_line_length": 100,
      "quote_style": "double",
      "trailing_commas": true
    },
    "naming": {
      "variables": "snake_case",
      "functions": "snake_case",
      "classes": "PascalCase",
      "constants": "SCREAMING_SNAKE_CASE"
    },
    "testing": {
      "framework": "pytest",
      "coverage_threshold": 80,
      "required_for_pr": true
    }
  },
  "rules_version": "1.0.0",
  "sync_timestamp": "{{TIMESTAMP}}"
}
```

## Benefits

**Advantages:**
- **Google Ecosystem:** Optimized for Gemini and Codegemma models
- **Structured Context:** JSON metadata enables more precise code generation
- **Clear Instructions:** Explicit guidance for Gemini's instruction-following capabilities
- **Future-Proof:** Ready for hierarchical rule support when Gemini adds it

**Use Cases:**
- **Gemini API:** Use rules with Gemini API for code generation
- **Codegemma:** Specialized code model for faster, more accurate suggestions
- **Google IDEs:** Integration with Android Studio, IntelliJ (Google plugins)
- **Custom Tools:** Build custom Gemini-powered coding assistants

## File Generation

The sync script generates Gemini configuration:

```bash
# Generate Gemini rules and context
./sync-ai-rules.sh --tool gemini

# Gemini is included when using --tool all
./sync-ai-rules.sh --tool all
```

## Environment Detection

The sync script auto-detects Gemini environment via:

1. **Environment Variable:** `GEMINI_AI`
2. **Directory Presence:** `.gemini/` directory exists
3. **Config File:** `.gemini/config.json` exists

If detected, Gemini is automatically included in sync targets.

## Integration Approaches

### 1. Direct API Usage

```python
import google.generativeai as genai
import json

# Load project context
with open('.gemini/context.json') as f:
    context = json.load(f)

# Load rules
with open('.gemini/rules.md') as f:
    rules = f.read()

# Configure Gemini
genai.configure(api_key=os.environ['GEMINI_API_KEY'])
model = genai.GenerativeModel('gemini-pro')

# Generate code with context
prompt = f"""
Project Context: {json.dumps(context)}

Development Rules:
{rules}

Task: Create a new FastAPI endpoint for user authentication
"""

response = model.generate_content(prompt)
print(response.text)
```

### 2. Custom CLI Tool

```bash
# gemini-code - Custom CLI wrapper
#!/bin/bash

CONTEXT=$(cat .gemini/context.json)
RULES=$(cat .gemini/rules.md)

gemini-api \
  --system-context "$CONTEXT" \
  --instructions "$RULES" \
  --prompt "$1"
```

### 3. IDE Plugin

Create a custom plugin that:
- Loads `.gemini/rules.md` on project open
- Injects context from `context.json` into code generation requests
- Provides task-specific rule filtering (future enhancement)

## Customization

### Sync Configuration

Create `.ai/sync-config.json`:

```json
{
  "languages": ["python", "typescript"],
  "frameworks": ["fastapi", "react"],
  "cloud_providers": ["vercel"],
  "gemini_preferences": {
    "temperature": 0.7,
    "top_p": 0.9,
    "max_output_tokens": 2048,
    "instruction_style": "explicit",
    "include_examples": true
  }
}
```

### Custom Context

Add project-specific context to `context.json`:

```json
{
  "project": {
    "name": "my-app",
    "custom_context": {
      "business_domain": "e-commerce",
      "target_audience": "b2b",
      "compliance": ["GDPR", "PCI-DSS"],
      "accessibility": "WCAG 2.1 AA"
    }
  }
}
```

## Template Files

This directory contains:

- `template-rules.md` - Template structure for main rules file
- `template-context.json` - Template for project context metadata
- `instruction-patterns.md` - Effective instruction patterns for Gemini
- `examples/` - Example integrations and usage patterns

## Gemini-Specific Features

### Enhanced Code Generation

Gemini's multimodal capabilities enable:
- **Image-to-Code:** Generate code from UI mockups or diagrams
- **Code Explanations:** Natural language explanations of complex code
- **Code Translation:** Convert between languages following project conventions
- **Refactoring Suggestions:** Identify and fix code smells

### Instruction Following

Gemini excels at following explicit instructions. The rules format includes:
- **Numbered Steps:** Clear action items for code generation
- **Examples:** Concrete code examples for each pattern
- **Anti-Patterns:** Explicit "do not" instructions
- **Checklist Format:** Easy-to-follow validation criteria

### Context Understanding

`context.json` enables Gemini to:
- Understand project-wide conventions without repeating them
- Apply maturity-level requirements automatically
- Use correct package managers and tools
- Follow established naming conventions

## Comparison to Other Tools

| Feature | Gemini | Claude Code | Cursor | Copilot |
|---------|--------|-------------|--------|---------|
| **File Format** | Monolithic + JSON | Hierarchical/Mono | Monolithic | Monolithic |
| **Metadata** | Rich JSON context | Limited | None | Limited |
| **Progressive Disclosure** | Future | Yes (hierarchical) | No | No |
| **Multimodal** | Yes | Yes | No | Limited |
| **API Access** | Direct | Via API | Indirect | Limited |
| **Customization** | High | High | Medium | Medium |

**When to use Gemini:**
- You're using Google Cloud Platform
- You need multimodal capabilities (image, video, audio)
- You want rich structured context
- You're building custom code generation tools
- You need fast, cost-effective code generation (Codegemma)

**When to consider alternatives:**
- You need progressive disclosure now (→ Claude Code hierarchical)
- You prefer established IDE integrations (→ Copilot, Cursor)
- You want simpler setup (→ Cursor)

## Future Enhancements

**Planned Features:**
1. **Hierarchical Rules:** On-demand rule loading similar to Claude Code
2. **Smart Context:** Auto-generate context from codebase analysis
3. **Rule Versioning:** Track which rule version generated which code
4. **Performance Metrics:** Measure code quality by rule adherence
5. **IDE Plugins:** Native support in popular IDEs
6. **Multimodal Rules:** Include diagrams and screenshots in rules

## Examples

See `examples/` directory for:
- `simple-api-generation.py` - Basic API code generation
- `custom-cli-tool.sh` - Command-line code assistant
- `ide-plugin-skeleton/` - Starter template for IDE integration
- `batch-refactoring.py` - Bulk code refactoring script

## Related Documentation

- [Google Gemini Documentation](https://ai.google.dev/gemini-api/docs)
- [Codegemma Documentation](https://ai.google.dev/gemini-api/docs)
- [Centralized Rules Architecture](../../ARCHITECTURE.md)
- Centralized Rules on GitHub

## Support

- **Repository:** https://github.com/PaulDuvall/centralized-rules
- **Issues:** https://github.com/PaulDuvall/centralized-rules/issues
- **Gemini Support:** https://ai.google.dev/gemini-api/docs/support
- **Gemma on GitHub:** https://github.com/google-deepmind/gemma

---

*Gemini and Codegemma are products of Google LLC*
