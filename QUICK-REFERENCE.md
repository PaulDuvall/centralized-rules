# Quick Reference - Steering Rules Cheat Sheet

**Purpose:** One-page summary of all critical rules for rapid context loading.

---

## 🚨 Critical Rules (Never Violate)

### 1. Never Proceed with Failing Tests
```bash
# ALWAYS run before moving forward
pytest tests/ -v
# Coverage must be ≥ 80%
pytest --cov=src --cov-report=term
```
**Rule:** All tests must pass before marking work complete or moving to next task.

### 2. Refactor Before Moving Forward
**Checklist:**
- [ ] Functions ≤ 20 lines
- [ ] Files ≤ 300 lines
- [ ] Complexity ≤ 10 per function
- [ ] Type hints on all functions
- [ ] No duplicate code

### 3. Green CI/CD is Non-Negotiable
**Rule:** Fix failing GitHub Actions immediately. Never leave CI in failed state.

---

## 📊 Key Metrics (Single Source of Truth)

### Code Quality Limits
| Metric | Limit | Tool |
|--------|-------|------|
| Function length | ≤ 20 lines | Manual review |
| File length | ≤ 300 lines | Manual review |
| Complexity | ≤ 10 | ruff |
| Test coverage | ≥ 80% | pytest-cov |
| Branch coverage | ≥ 90% | pytest-cov |

### Video Processing Performance (30-min input)
| Phase | Target | Acceptable Range |
|-------|--------|------------------|
| Phase 1 (Ingest) | ~2 min | 1-5 min |
| Phase 2 (Director) | ~20 sec | 10-60 sec |
| Phase 3 (Voice) | ~90 sec | 30-180 sec |
| Phase 4 (Assembly) | ~12 min | 5-20 min |
| **Total** | **~15 min** | **10-25 min** |

### API Costs (30-min video)
| Service | Expensive | Budget-Friendly |
|---------|-----------|-----------------|
| Whisper | $0.18 (API) | $0.00 (local) |
| LLM | $0.32 (GPT-4o) | $0.05 (GPT-4o-mini) |
| TTS | $2.10 (ElevenLabs) | $0.21 (OpenAI) |
| **Total** | **$2.60** | **$0.26** |

**Budget Recommendation:** < $0.50 per video

---

## 🧪 Testing Quick Commands

```bash
# Run all tests
pytest tests/ -v

# Run with coverage
pytest --cov=src --cov-report=html
open htmlcov/index.html

# Run only fast tests (skip expensive operations)
pytest -m "not slow" -v

# Run specific test file
pytest tests/test_pronunciation.py -v

# Run tests in parallel
pytest -n auto

# Run with specific marker
pytest -m "unit" -v          # Unit tests only
pytest -m "integration" -v   # Integration tests only
pytest -m "video" -v         # Video processing tests
```

---

## 🔧 Common Workflows

### Starting a New Feature
1. Create feature branch: `git checkout -b feature/description`
2. Read relevant steering files (see navigation table below)
3. Write failing test first (TDD Red phase)
4. Implement minimal code to pass test (TDD Green phase)
5. Refactor (check metrics)
6. Commit with descriptive message
7. Push and create PR

### Before Marking Task Complete
- [ ] All tests pass locally
- [ ] Coverage ≥ 80%
- [ ] Refactoring checklist complete
- [ ] No TypeScript/linter warnings
- [ ] Code committed and pushed
- [ ] CI/CD is green

### Git Commit Message Format
```bash
git commit -m "type: Brief description

Detailed explanation of what changed and why.

- Bullet points for multiple changes
- Reference issue numbers if applicable

Co-Authored-By: Name <email>"
```

**Types:** `feat`, `fix`, `refactor`, `docs`, `test`, `chore`

---

## 📍 Navigation: Which File Do I Need?

| Your Task | Read This File | Why |
|-----------|---------------|-----|
| Writing tests | [testing-overview.md](./testing-overview.md) | Entry point with navigation |
| Mocking FFmpeg/AI | [testing-mocking.md](./testing-mocking.md) | Mock patterns for external deps |
| Testing pipeline phases | [testing-pipeline.md](./testing-pipeline.md) | Phase 1-4 test strategies |
| Creating test fixtures | [testing-fixtures.md](./testing-fixtures.md) | Generate test videos/audio |
| pytest configuration | [testing-configuration.md](./testing-configuration.md) | Markers, coverage, CI setup |
| Refactoring code | [refactoring-workflow.md](./refactoring-workflow.md) | Mandatory refactoring steps |
| Code style/patterns | [coding-standards.md](./coding-standards.md) | Python patterns, type hints |
| Check metrics/limits | [metrics-and-limits.md](./metrics-and-limits.md) | All numeric thresholds |
| Git commits/branches | [git-workflow.md](./git-workflow.md) | Commit messages, branching |
| CI/CD setup | [cicd-workflow.md](./cicd-workflow.md) | GitHub Actions, video in CI |
| Performance tracking | [performance-monitoring.md](./performance-monitoring.md) | Track costs, benchmarks |
| Working with AI services | [ai-integration.md](./ai-integration.md) | Whisper, LLM, TTS patterns |
| JSON manifests/data | [data-conventions.md](./data-conventions.md) | Pydantic models, config |
| API keys/secrets | [security.md](./security.md) | .env, AWS SSM, secrets |

---

## 🤖 AI Integration Quick Reference

### Whisper (Transcription)
```python
# Local Whisper (free, slower)
import whisper
model = whisper.load_model("base")
result = model.transcribe("audio.mp3")

# API Whisper (paid, faster)
from openai import OpenAI
client = OpenAI()
with open("audio.mp3", "rb") as f:
    transcript = client.audio.transcriptions.create(
        model="whisper-1",
        file=f
    )
```

### LLM (Edit Planning)
```python
# OpenAI
from openai import OpenAI
client = OpenAI()
response = client.chat.completions.create(
    model="gpt-4o",
    messages=[{"role": "system", "content": SYSTEM_PROMPT},
              {"role": "user", "content": transcript}]
)

# Anthropic
from anthropic import Anthropic
client = Anthropic()
response = client.messages.create(
    model="claude-sonnet-4",
    max_tokens=4096,
    messages=[{"role": "user", "content": transcript}],
    system=SYSTEM_PROMPT
)
```

### TTS (Voice Synthesis)
```python
# ElevenLabs (expensive, high quality)
from elevenlabs import generate, save
audio = generate(text=narration, voice="Adam")
save(audio, "output.mp3")

# OpenAI TTS (cheaper, good quality)
from openai import OpenAI
client = OpenAI()
response = client.audio.speech.create(
    model="tts-1",
    voice="alloy",
    input=narration
)
response.stream_to_file("output.mp3")
```

---

## 🔒 Security Quick Rules

### API Key Management
```bash
# NEVER commit secrets
# Use .env (gitignored)
cp .env.example .env
# Edit .env with your keys

# Or use AWS SSM (optional)
./run.sh  # Auto-detects AWS SSO and loads from SSM
```

### Pre-commit Checklist
- [ ] No API keys in code
- [ ] No hardcoded secrets
- [ ] `.env` is gitignored
- [ ] Sensitive data not in test fixtures

---

## 📄 Data Conventions Quick Reference

### Manifest Structure (EditManifest)
```python
from pydantic import BaseModel

class EditAction(BaseModel):
    action: str  # "cut", "keep", "speedup", "narrate"
    start: float  # Timestamp in seconds
    end: float
    narration: str | None = None
    speed: float = 1.0

class EditManifest(BaseModel):
    video_path: str
    duration: float
    actions: list[EditAction]
```

### Configuration Files
- `config/videos.json` - Video library (gitignored)
- `config/pronunciation_rules.json` - TTS pronunciation fixes
- `.env` - API keys (gitignored)

---

## 🎯 Common Scenarios

### Scenario 1: Test is Failing
1. Read error message carefully
2. Run single test: `pytest tests/test_file.py::test_name -v`
3. Add `import pdb; pdb.set_trace()` to debug
4. Fix the code (not the test, unless test is wrong)
5. Verify: `pytest tests/ -v`

### Scenario 2: Code is Too Complex
1. Check complexity: `ruff check src/`
2. Extract functions (each < 20 lines)
3. Use descriptive names
4. Add type hints
5. Verify tests still pass

### Scenario 3: CI/CD is Failing
1. Check GitHub Actions tab
2. Read error logs
3. Reproduce locally: `pytest tests/ -v`
4. Fix and push immediately
5. Never leave CI red overnight

### Scenario 4: Need to Mock External Service
1. Read [testing-mocking.md](./testing-mocking.md)
2. Use `@patch` decorator
3. Create mock with expected behavior
4. Verify mock is called correctly
5. Test passes without real API calls

---

## 🚀 Performance Optimization Tips

### When to Optimize
- ❌ Don't optimize prematurely
- ✅ Do optimize when:
  - Phase exceeds acceptable range (see metrics above)
  - API costs exceed budget ($0.50/video)
  - User reports slowness

### How to Optimize
1. **Measure first**: Use PerformanceMonitor class
2. **Identify bottleneck**: Which phase is slow?
3. **Optimize bottleneck**:
   - Phase 1: Use local Whisper instead of API
   - Phase 2: Use GPT-4o-mini instead of GPT-4o
   - Phase 3: Use OpenAI TTS instead of ElevenLabs
   - Phase 4: Optimize FFmpeg settings, reduce resolution
4. **Measure again**: Verify improvement
5. **Document**: Update performance metrics

---

## 📋 Icon System

When you see these icons in steering files:

- 🧪 **Testing** - Running tests, coverage
- 🔧 **Refactoring** - Code quality, complexity
- 📝 **Git** - Commits, branches, PRs
- 🚦 **CI/CD** - GitHub Actions, builds
- 📐 **Coding Standards** - Type safety, patterns
- 🔒 **Security** - API keys, secrets
- 📄 **Data** - JSON manifests, models
- 📊 **Performance** - Speed, costs
- 🤖 **AI Integration** - Whisper, LLM, TTS

---

## 🔗 External Resources

**Python:**
- [PEP 8](https://peps.python.org/pep-0008/) - Python style guide
- [PEP 257](https://peps.python.org/pep-0257/) - Docstring conventions
- [pytest docs](https://docs.pytest.org) - Testing framework

**Video Processing:**
- [FFmpeg docs](https://ffmpeg.org/documentation.html) - Video manipulation
- [MoviePy docs](https://zulko.github.io/moviepy/) - Python video editing

**AI Services:**
- [OpenAI API](https://platform.openai.com/docs) - Whisper, GPT, TTS
- [Anthropic API](https://docs.anthropic.com) - Claude
- [ElevenLabs API](https://elevenlabs.io/docs) - Voice synthesis

**CI/CD:**
- [GitHub Actions](https://docs.github.com/en/actions) - Workflow automation

---

## 💡 Pro Tips

1. **Progressive Disclosure**: Don't read all steering files. Use the navigation table to find what you need.
2. **Test First**: Write failing test → implement → refactor → commit
3. **Small Commits**: Commit every 30-60 minutes, not at end of day
4. **Mock Everything**: Don't call real APIs in tests
5. **Use Local Whisper**: Save $0.18 per video, only use API if speed matters
6. **Budget Path**: Local Whisper + GPT-4o-mini + OpenAI TTS = $0.26 per video

---

**Last Updated:** 2025-12-10
**Quick Reference Version:** 1.0
**For detailed guidance, see individual steering files in this directory**
