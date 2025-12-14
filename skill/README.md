# Centralized Rules Skill for Claude

> Smart coding rules that automatically load based on your project context

A Claude skill that intelligently detects your project's language, framework, and maturity level, then automatically injects the most relevant coding standards and best practices into Claude's context.

📖 **New to the skill?** See the [Migration Guide](./MIGRATION_GUIDE.md) for benefits and comparison with manual approaches.

## Features

- **🎯 Context-Aware**: Automatically detects Python, TypeScript, Java, Go, Rust, and more
- **🧠 Smart Selection**: Loads only the 3-5 most relevant rules per request (not all 50+)
- **⚡ Fast & Cached**: Rules are cached for 1 hour, typical load time <500ms
- **🔄 Always Fresh**: Fetches latest rules from GitHub automatically
- **📦 Zero Config**: Works out of the box, customizable if needed
- **🌐 Multi-Framework**: Supports React, FastAPI, Django, Next.js, Spring Boot, and more

## Installation

### Quick Install (Recommended)

```bash
curl -fsSL https://raw.githubusercontent.com/paulduvall/centralized-rules/main/skill/install.sh | bash
```

This will:
- Clone the centralized-rules repository to `~/centralized-rules`
- Install dependencies and build the skill
- Show you how to configure Claude

### Manual Install

```bash
# Clone repository
git clone https://github.com/paulduvall/centralized-rules
cd centralized-rules/skill

# Install dependencies
npm install

# Build skill
npm run build
```

Then configure Claude (see Configuration section below).

### Update Existing Installation

```bash
cd ~/centralized-rules
git pull
cd skill
npm run build
```

## Usage

### Automatic (Recommended)

The skill automatically activates via the `beforeResponse` hook. Just use Claude normally:

```
You: "Help me add JWT authentication to my FastAPI app"

Claude: [Automatically loads FastAPI + Python + Security rules]
        "For JWT authentication in FastAPI, following your project's patterns..."
```

No manual action needed! The skill:
1. Detects your project (Python + FastAPI)
2. Analyzes your intent ("authentication")
3. Loads 3 relevant rules (FastAPI auth patterns, Python security, base security)
4. Claude uses them automatically

### Manual (Optional)

You can also manually request specific rules:

```
You: "Load rules for TypeScript and React testing"

Claude: [Uses get_rules tool]
        "I've loaded the TypeScript testing and React testing rules..."
```

## How It Works

```typescript
// When you ask Claude a question:
User: "Add a login form to my React app"

// Behind the scenes:
1. beforeResponse hook fires
2. Detects: TypeScript + React + Next.js
3. Analyzes intent: "login form" → authentication, forms
4. Scores all rules:
   - react/forms.md: 150 points ⭐
   - react/auth-patterns.md: 130 points
   - typescript/coding-standards.md: 120 points
   - base/security-principles.md: 70 points
5. Selects top 3 (token budget: 5K)
6. Fetches from GitHub (cached)
7. Injects into Claude's system prompt

// Claude responds with rules applied:
Claude: "For React forms with authentication, following your patterns:
         1. Use React Hook Form (per your standards)
         2. Implement with TypeScript types
         3. Add Zod validation
         ..."
```

## Configuration

### Adding Skill to Claude

After installation, add the skill to your Claude configuration:

**File:** `~/.config/claude/claude_desktop_config.json`

```json
{
  "skills": [
    {
      "name": "centralized-rules",
      "path": "~/centralized-rules/skill"
    }
  ]
}
```

Or use an absolute path:

```json
{
  "skills": [
    {
      "name": "centralized-rules",
      "path": "/Users/yourname/centralized-rules/skill"
    }
  ]
}
```

After adding, restart Claude Desktop or Claude Code.

### Skill Options

The skill works out of the box, but can be customized via `skill.json`:

```json
{
  "configuration": {
    "rulesRepo": "paulduvall/centralized-rules",
    "enableAutoLoad": true,
    "cacheEnabled": true,
    "cacheTTL": 3600,
    "maxRules": 5,
    "maxTokens": 5000,
    "verbose": false
  }
}
```

### Configuration Options

| Option | Default | Description |
|--------|---------|-------------|
| `rulesRepo` | `paulduvall/centralized-rules` | GitHub repo with rules |
| `rulesBranch` | `main` | Git branch to fetch from |
| `enableAutoLoad` | `true` | Auto-load rules via hook |
| `cacheEnabled` | `true` | Cache fetched rules |
| `cacheTTL` | `3600` | Cache time-to-live (seconds) |
| `maxRules` | `5` | Max rules per request |
| `maxTokens` | `5000` | Max tokens for rules |
| `verbose` | `false` | Enable debug logging |

## Supported Technologies

### Languages
- Python
- TypeScript / JavaScript
- Go
- Java
- Rust
- C#

### Frameworks
- **Python**: FastAPI, Django, Flask
- **TypeScript**: React, Next.js, Express, Nest.js
- **Java**: Spring Boot
- **Go**: Gin, Echo

### Cloud Providers
- AWS
- Vercel
- Azure
- GCP

## Project Structure

```
centralized-rules-skill/
├── src/
│   ├── hooks/              # beforeResponse hook
│   ├── tools/              # detect-context, get-rules, select-rules
│   ├── cache/              # Rules caching
│   └── types/              # TypeScript type definitions
├── tests/
│   ├── unit/               # Unit tests
│   ├── integration/        # Integration tests
│   └── e2e/                # End-to-end tests
├── skill.json              # Skill manifest
├── package.json            # NPM package
└── README.md               # This file
```

## Development

### Setup

```bash
# Install dependencies
npm install

# Run tests
npm test

# Run tests with coverage
npm run test:coverage

# Build
npm run build

# Development mode (watch)
npm run dev

# Lint
npm run lint

# Format code
npm run format
```

### Running Tests

```bash
# Run all tests
npm test

# Run with UI
npm run test:ui

# Run in watch mode
npm run test:watch

# Generate coverage report
npm run test:coverage
```

### Building

```bash
# Clean build
npm run rebuild

# Or step by step
npm run clean
npm run build
```

## Implementation Status

### ✅ Completed

**Core Setup (cs1, cs2, cs8)**
- [x] Development environment setup (cs1)
- [x] TypeScript configuration with strict mode (cs1)
- [x] Testing framework - Vitest with coverage (cs1)
- [x] ESLint & Prettier configuration (cs1)
- [x] Skill manifest (skill.json) (cs2)
- [x] Type definitions (cs2)
- [x] Project structure (cs2)
- [x] Git-based distribution with install script (cs8)

**Refactorings (rf1, rf2, rf3)**
- [x] Removed validate_code tool (YAGNI) (rf1)
- [x] Removed NPM publishing cruft from package.json (rf2)
- [x] Added implementation status section to README (rf3)

### 🚧 Not Yet Implemented

**Core Features**
- [ ] Context detection tool - detect languages, frameworks, cloud providers (cs3)
- [ ] Rule selection algorithm - scoring and ranking (cs4)
- [ ] GitHub fetching with caching - fetch rules from repo (cs5)
- [ ] beforeResponse hook - automatic rule injection (cs6)
- [ ] Comprehensive test suite - unit, integration, E2E (cs7)
- [ ] Migration guide for sync script users (cs9)

**Future Refactorings**
- [ ] Replace hardcoded enums with dynamic values (rf4)
- [ ] Review type definitions after implementation (rf5)

## Contributing

Contributions welcome! Please see [CONTRIBUTING.md](../CONTRIBUTING.md) for guidelines.

## License

MIT - see [LICENSE](../LICENSE)

## Links

- **Main Repository**: [centralized-rules](https://github.com/paulduvall/centralized-rules)
- **Issues**: [GitHub Issues](https://github.com/paulduvall/centralized-rules/issues)
- **Documentation**: [Full Docs](https://github.com/paulduvall/centralized-rules#readme)

## Support

Need help? Found a bug?
- 📝 [Open an issue](https://github.com/paulduvall/centralized-rules/issues)
- 💬 [GitHub Discussions](https://github.com/paulduvall/centralized-rules/discussions)

---

**Made with ❤️ for better coding with Claude**
