# Gemini/Codegemma Configuration

Google Gemini and Codegemma-specific configurations for the centralized rules system.

## Overview

**Gemini** is Google's multimodal AI model family. **Codegemma** is a specialized variant optimized for code generation. This integration provides development rules in a format optimized for Gemini-based coding assistants.

## Output Format

`.gemini/` directory structure with monolithic rules and structured metadata.

**Structure:**
```
project-root/
└── .gemini/
    ├── rules.md              # Main instructions file (monolithic)
    ├── context.json          # Project context metadata
    └── rules/                # Optional hierarchical (future)
        ├── base/
        ├── languages/
        ├── frameworks/
        └── cloud/
```

**Current Implementation:**
- **Monolithic Format:** Single `.gemini/rules.md` file
- **Context Metadata:** Structured JSON with project configuration
- **Future-Ready:** Directory prepared for hierarchical rules

**Characteristics:**
- Google-optimized formatting for Gemini's instruction following
- Metadata-rich structured project context for better generation
- Extensible for future hierarchical rule support
- Organized by concern for easy parsing

## File Format

### rules.md

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
1. Follow coding standards defined below
2. Apply security principles to all code
3. Include appropriate error handling
4. Generate tests for new functionality
5. Add comments for complex logic
6. Consider project maturity level

## Base Development Rules

### Git Workflow
[Content from base/git-workflow.md]

### Code Quality
[Content from base/code-quality.md]
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
      "quote_style": "double"
    },
    "naming": {
      "variables": "snake_case",
      "functions": "snake_case",
      "classes": "PascalCase"
    },
    "testing": {
      "framework": "pytest",
      "coverage_threshold": 80
    }
  }
}
```

## Benefits & Use Cases

**Advantages:**
- Google ecosystem optimized
- Structured JSON context enables precise code generation
- Clear instructions for Gemini's instruction-following
- Future-proof for hierarchical rules

**Use Cases:**
- Gemini API for code generation
- Codegemma for faster, accurate suggestions
- Google IDEs (Android Studio, IntelliJ with Google plugins)
- Custom Gemini-powered coding assistants

## File Generation

```bash
# Generate Gemini rules and context
./sync-ai-rules.sh --tool gemini

# Included when using --tool all
./sync-ai-rules.sh --tool all
```

## Environment Detection

Auto-detects Gemini via:
1. Environment variable: `GEMINI_AI`
2. Directory presence: `.gemini/` exists
3. Config file: `.gemini/config.json` exists

## Integration Approaches

### 1. Direct API Usage

```python
import google.generativeai as genai
import json

# Load context and rules
with open('.gemini/context.json') as f:
    context = json.load(f)
with open('.gemini/rules.md') as f:
    rules = f.read()

# Configure Gemini
genai.configure(api_key=os.environ['GEMINI_API_KEY'])
model = genai.GenerativeModel('gemini-pro')

# Generate code with context
prompt = f"""
Project Context: {json.dumps(context)}
Development Rules: {rules}
Task: Create a new FastAPI endpoint for user authentication
"""
response = model.generate_content(prompt)
```

### 2. Custom CLI Tool

```bash
#!/bin/bash
CONTEXT=$(cat .gemini/context.json)
RULES=$(cat .gemini/rules.md)

gemini-api \
  --system-context "$CONTEXT" \
  --instructions "$RULES" \
  --prompt "$1"
```

### 3. IDE Plugin

Create a plugin that:
- Loads `.gemini/rules.md` on project open
- Injects context from `context.json` into requests
- Provides task-specific rule filtering (future)

## Customization

### Sync Configuration

`.ai/sync-config.json`:

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

- `template-rules.md` - Template for main rules file
- `template-context.json` - Template for project metadata
- `instruction-patterns.md` - Effective instruction patterns for Gemini
- `examples/` - Example integrations and usage patterns

## Gemini-Specific Features

### Enhanced Code Generation

- **Image-to-Code:** Generate code from UI mockups or diagrams
- **Code Explanations:** Natural language explanations of complex code
- **Code Translation:** Convert between languages following project conventions
- **Refactoring Suggestions:** Identify and fix code smells

### Instruction Following

Rules format includes:
- **Numbered Steps:** Clear action items
- **Examples:** Concrete code examples
- **Anti-Patterns:** Explicit "do not" instructions
- **Checklist Format:** Easy-to-follow validation criteria

### Context Understanding

`context.json` enables Gemini to:
- Understand project-wide conventions without repetition
- Apply maturity-level requirements automatically
- Use correct package managers and tools
- Follow established naming conventions

## Comparison

| Feature | Gemini | Claude Code | Cursor | Copilot |
|---------|--------|-------------|--------|---------|
| **File Format** | Monolithic + JSON | Hierarchical/Mono | Monolithic | Monolithic |
| **Metadata** | Rich JSON | Limited | None | Limited |
| **Progressive Disclosure** | Future | Yes | No | No |
| **Multimodal** | Yes | Yes | No | Limited |
| **API Access** | Direct | Via API | Indirect | Limited |
| **Customization** | High | High | Medium | Medium |

**When to use Gemini:**
- Using Google Cloud Platform
- Need multimodal capabilities (image, video, audio)
- Want rich structured context
- Building custom code generation tools
- Need fast, cost-effective code generation (Codegemma)

**When to consider alternatives:**
- Need progressive disclosure now → Claude Code hierarchical
- Prefer established IDE integrations → Copilot, Cursor
- Want simpler setup → Cursor

## Future Enhancements

1. **Hierarchical Rules:** On-demand rule loading like Claude Code
2. **Smart Context:** Auto-generate context from codebase analysis
3. **Rule Versioning:** Track which rule version generated which code
4. **Performance Metrics:** Measure code quality by rule adherence
5. **IDE Plugins:** Native support in popular IDEs
6. **Multimodal Rules:** Include diagrams and screenshots

## Examples

See `examples/` directory for:
- `simple-api-generation.py` - Basic API code generation
- `custom-cli-tool.sh` - Command-line code assistant
- `ide-plugin-skeleton/` - Starter for IDE integration
- `batch-refactoring.py` - Bulk code refactoring script

## Related Documentation

- [Google Gemini Documentation](https://ai.google.dev/gemini-api/docs)
- [Codegemma Documentation](https://ai.google.dev/gemini-api/docs)
- [Centralized Rules Architecture](../../ARCHITECTURE.md)

## Support

- **Repository:** https://github.com/PaulDuvall/centralized-rules
- **Issues:** https://github.com/PaulDuvall/centralized-rules/issues
- **Gemini Support:** https://ai.google.dev/gemini-api/docs/support
- **Gemma on GitHub:** https://github.com/google-deepmind/gemma

---

*Gemini and Codegemma are products of Google LLC*
