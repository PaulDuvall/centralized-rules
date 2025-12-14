# Repository Audit Agent

Automated analysis and quality assurance for the centralized rules repository.

## Features

- **Project Context Detection**: Automatically detects languages, frameworks, cloud providers, and maturity level
- **Rules Selection**: Intelligent selection of relevant rules based on project context
- **MECE Analysis**: Checks for content overlaps and coverage gaps (Mutually Exclusive, Collectively Exhaustive)
- **File Disposition**: Analyzes obsolete and redundant files
- **Multiple Audit Depths**: Quick, Standard, and Full modes

## Installation

### Prerequisites

- Python 3.11 or higher

### Setup

1. Create a virtual environment:
```bash
python3 -m venv venv
source venv/bin/activate  # On Unix/macOS
# or
venv\Scripts\activate  # On Windows
```

2. Install dependencies:
```bash
pip install -r requirements.txt
```

## Usage

### Basic Usage

Run a quick audit of the repository:
```bash
python3 core.py --repo ../.. --depth quick
```

### Audit Depths

**Quick Mode** (fastest):
- Project context detection
- Rules selection report
- No MECE analysis
- No file disposition

```bash
python3 core.py --repo ../.. --depth quick
```

**Standard Mode** (recommended):
- All quick mode features
- MECE content analysis
- File disposition analysis

```bash
python3 core.py --repo ../.. --depth standard
```

**Full Mode** (most comprehensive):
- All standard mode features
- Accuracy audit with citations (planned)

```bash
python3 core.py --repo ../.. --depth full
```

### Output

The audit generates a JSON report with:
- Project context (languages, frameworks, cloud, maturity)
- Rules selection report with reasoning
- MECE analysis (overlaps and gaps)
- File disposition recommendations

Example output:
```bash
🔍 Repository Audit Agent Starting...
📁 Repository: ../..
⚙️  Audit Depth: standard

[1/6] 🎯 Detecting project context...
      Languages: python, typescript
      Frameworks: fastapi, react
      Cloud: aws
      Maturity: production

[2/6] 📋 Generating rules selection report...
      Total rules available: 49
      Rules selected: 12
      Estimated tokens: 14400
      Selection efficiency: 24.5%

[3/6] 🗺️  Creating MECE content map...
      Files analyzed: 49
      Overlaps found: 31
      Coverage gaps: 3
      MECE score: 29% - Needs Improvement

[4/6] ⏭️  Skipping accuracy audit (not full mode)

[5/6] 🗂️  Analyzing file disposition...
      Files classified: 5

[6/6] 📝 Generating final reports...
✅ Audit complete!

📄 Report saved to: audit-report-20251214-151720.json
```

## Running Tests

### Setup Test Environment

```bash
# Activate virtual environment
source venv/bin/activate

# Install test dependencies (if not already installed)
pip install pytest
```

### Run Tests

```bash
# Run all tests
python3 -m pytest test_audit_agent.py -v

# Run specific test class
python3 -m pytest test_audit_agent.py::TestRulesParser -v

# Run with coverage
python3 -m pytest test_audit_agent.py --cov=. --cov-report=html
```

### Test Structure

- `TestRulesParser`: Tests for rules parsing and selection
- `TestMECEAnalyzer`: Tests for MECE content analysis
- `TestAuditAgent`: Tests for core audit functionality
- `TestIntegration`: End-to-end integration tests

## Modules

### core.py
Main orchestrator that runs the complete audit pipeline.

**Key Classes:**
- `AuditAgent`: Main audit orchestrator
- `ProjectContext`: Detected project information
- `AuditConfig`: Audit configuration
- `AuditResult`: Complete audit results

### rules_parser.py
Parses rules from index.json and AGENTS.md.

**Key Classes:**
- `RulesParser`: Parse and analyze rules
- `RuleMetadata`: Metadata for a single rule

**Key Methods:**
- `parse_index()`: Parse rules index
- `parse_agents_md()`: Extract rules from AGENTS.md
- `generate_selection_report()`: Generate comprehensive selection report

### mece_analyzer.py
Analyzes content for MECE compliance.

**Key Classes:**
- `MECEAnalyzer`: Analyze repository for overlaps and gaps
- `ContentAnalysis`: Analysis of a single file
- `OverlapReport`: Content overlap between files
- `GapReport`: Coverage gap report

**Key Methods:**
- `analyze()`: Run complete MECE analysis
- `_find_overlaps()`: Find content overlaps
- `_find_gaps()`: Find coverage gaps

## GitHub Actions Integration

The audit agent can be run automatically via GitHub Actions.

See `.github/workflows/audit-agent.yml` for the workflow configuration.

**Triggers:**
- Weekly on Mondays at 9 AM UTC
- Manual workflow dispatch

**Outputs:**
- Audit report artifact (retained for 90 days)
- GitHub issue for actionable findings
- PR comment (when triggered by PR)

## Architecture

```
┌─────────────────────────────────────────┐
│         AuditAgent (core.py)            │
│                                         │
│  1. Detect project context              │
│  2. Generate rules selection report     │
│  3. Create MECE content map             │
│  4. Run accuracy audit (future)         │
│  5. Analyze file disposition            │
│  6. Generate outputs                    │
└─────────────────────────────────────────┘
           │              │
           ▼              ▼
  ┌──────────────┐  ┌──────────────┐
  │ RulesParser  │  │ MECEAnalyzer │
  │              │  │              │
  │ - Parse      │  │ - Overlaps   │
  │   index      │  │ - Gaps       │
  │ - Select     │  │ - MECE score │
  │   rules      │  │              │
  └──────────────┘  └──────────────┘
```

## Future Enhancements

- **Accuracy Audit**: Verify rule citations and references
- **Beads Task Generation**: Automatically create tasks for findings
- **Patch Suggestions**: Generate PR suggestions for improvements
- **AI-Powered Analysis**: Use LLM to analyze rule quality
- **Trend Tracking**: Track MECE scores over time
- **Custom Rule Sets**: Support for project-specific rule configurations

## Contributing

See the main repository [CONTRIBUTING.md](../../CONTRIBUTING.md) for guidelines.

## License

MIT - see [LICENSE](../../LICENSE)
