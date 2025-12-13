---
inclusion: always
---

# 🔧 Refactoring Workflow

> **Icon:** 🔧 Used when checking code quality, refactoring, or improving structure
>
> **📋 Source of Truth:** [metrics-and-limits.md](./metrics-and-limits.md) → Code Quality Limits
>
> This document defines the mandatory refactoring workflow that must be followed after completing each task. These rules work in conjunction with the testing guidelines to ensure high code quality.

## ⚠️ CRITICAL RULE: Refactor Before Moving Forward

**MANDATORY:** You must NEVER move to the next task or mark a task as complete without performing a refactoring review and cleanup.

**AUTOMATIC ENFORCEMENT:** After writing ANY code, you MUST immediately:
1. Check function length (max 20 lines)
2. Check file length (max 300 lines)
3. Refactor if needed
4. Run tests
5. Commit refactoring separately
6. THEN mark task complete

**NO EXCEPTIONS:** This happens automatically for EVERY task, not just when asked.

### The Rule:

- ✅ All code must meet quality standards before moving forward
- ✅ All code must be refactored before marking a task complete
- ✅ All code must pass the refactoring checklist before claiming work is done

### Task Completion Workflow:

```
Task N: Implement feature X
  ├─ 1. Write code ✅
  ├─ 2. Write tests ✅
  ├─ 3. Run tests ✅ PASSED
  ├─ 4. 🔧 REFACTOR CODE ⚠️ MANDATORY AUTOMATIC STEP
  │   ├─ 🔧 Check function length (max 20 lines) - SHOW IN RESPONSE
  │   ├─ 🔧 Check file length (max 300 lines) - SHOW IN RESPONSE
  │   ├─ 🔧 Remove code duplication
  │   ├─ 📐 Add proper type hints
  │   ├─ 📐 Add error handling
  │   ├─ 📐 Add docstrings
  │   └─ ✅ Verify all standards met
  ├─ 5. 🧪 Run tests again ✅ PASSED (pytest)
  ├─ 6. 📐 Run type checker ✅ NO ERRORS (mypy)
  ├─ 7. 📝 Commit refactoring (if changes made)
  └─ 8. ✅ Mark task complete

Task N+1: Can now proceed ✅
```

**ICONS MUST BE SHOWN:** Use 🔧 icon when performing refactoring checks to make it visible.

## Refactoring Checklist

Before marking any task complete, verify ALL of these items:

### 1. Function Length
- [ ] **All functions are ≤ 20 lines** (defined in [metrics-and-limits.md](./metrics-and-limits.md))
- [ ] Long functions broken into smaller, focused functions
- [ ] Each function has a single, clear responsibility

**Why:** Short functions are easier to test, understand, and maintain.

**Example:**
```python
# ❌ Too long (>20 lines)
def process_video(video_path: str) -> dict:
    # 50 lines of validation, FFmpeg, transcription, AI calls, rendering...
    pass

# ✅ Refactored into focused functions
def validate_video_file(video_path: str) -> Path:
    """Validate video file exists and is correct format."""
    pass

def extract_audio_track(video_path: Path) -> Path:
    """Extract audio from video using FFmpeg."""
    pass

def transcribe_audio(audio_path: Path) -> list[dict]:
    """Transcribe audio to text with timestamps."""
    pass

def generate_edit_plan(transcript: list[dict]) -> dict:
    """Generate editing decisions using AI."""
    pass
```

### 2. File Length
- [ ] **All files are ≤ 300 lines** (defined in [metrics-and-limits.md](./metrics-and-limits.md))
- [ ] Large files split into logical modules
- [ ] Related functionality grouped together

**Why:** Large files are hard to navigate and indicate poor separation of concerns.

### 3. Type Safety
- [ ] **All functions have type hints** (PEP 484)
- [ ] All function parameters have explicit types
- [ ] All function return types are explicit
- [ ] Use modern Python type syntax (list[T], dict[K, V], not List[T], Dict[K, V])

**Example:**
```python
# ❌ Missing type hints
def process_manifest(data):
    return [item['text'] for item in data['actions']]

# ✅ Explicit type hints
def process_manifest(data: dict[str, list[dict]]) -> list[str]:
    """Extract text from manifest actions."""
    return [item['text'] for item in data['actions']]

# ✅ Even better: Use Pydantic for complex types
from pydantic import BaseModel

class EditAction(BaseModel):
    text: str
    start_time: float
    end_time: float

def process_manifest(data: dict[str, list[EditAction]]) -> list[str]:
    """Extract text from validated manifest actions."""
    return [action.text for action in data['actions']]
```

### 4. Error Handling
- [ ] **All functions that can fail have try/except** (severity: error)
- [ ] Catch specific exceptions (avoid bare `except:`)
- [ ] Error messages are descriptive and actionable
- [ ] Errors include remediation guidance
- [ ] Errors are logged with context

**Example:**
```python
# ❌ No error handling
def extract_audio(video_path: Path) -> Path:
    subprocess.run(['ffmpeg', '-i', str(video_path), 'audio.wav'])
    return Path('audio.wav')

# ✅ Proper error handling
def extract_audio(video_path: Path) -> Path:
    """Extract audio from video with comprehensive error handling."""
    try:
        result = subprocess.run(
            ['ffmpeg', '-i', str(video_path), '-vn', 'audio.wav'],
            capture_output=True,
            check=True,
            timeout=300
        )
        return Path('audio.wav')
    except subprocess.CalledProcessError as e:
        logger.error(f'FFmpeg extraction failed: {e.stderr.decode()}')
        raise VideoProcessingError(
            f"Failed to extract audio from {video_path.name}: {e.stderr.decode()} | "
            f"Remediation: Check video file format and FFmpeg installation"
        ) from e
    except subprocess.TimeoutExpired:
        raise VideoProcessingError(
            f"Audio extraction timed out after 5 minutes | "
            f"Remediation: Video file may be too large or corrupted"
        )
```

### 5. Code Duplication (DRY Principle)
- [ ] No duplicated code blocks
- [ ] Common logic extracted into shared functions
- [ ] Magic numbers/strings extracted into constants
- [ ] Repeated patterns abstracted

**Example (from RVA epic screencast-optimizer-rva.5):**
```python
# ❌ Duplicated FFmpeg FPS detection
# Before: Duplicated in phase4_assembly.py and concat_utils.py
def detect_fps_in_phase4(video_path: Path) -> float:
    result = subprocess.run(['ffprobe', '-v', 'error', ...])
    # Parse FPS...

def detect_fps_in_concat(video_path: Path) -> float:
    result = subprocess.run(['ffprobe', '-v', 'error', ...])
    # Parse FPS... (same logic!)

# ✅ Extracted to shared module (src/ffmpeg_utils.py)
def detect_frame_rate(video_path: Path) -> float:
    """Detect video frame rate using ffprobe.

    Works across all modules - single source of truth.
    """
    result = subprocess.run(
        ['ffprobe', '-v', 'error', '-select_streams', 'v:0',
         '-show_entries', 'stream=r_frame_rate', '-of', 'json',
         str(video_path)],
        capture_output=True,
        check=True
    )
    data = json.loads(result.stdout)
    return _parse_fps_string(data['streams'][0]['r_frame_rate'])
```

### 6. Documentation
- [ ] All public functions have docstrings (PEP 257)
- [ ] Complex logic has inline comments
- [ ] Edge cases are documented
- [ ] Examples provided for complex functions

**Example:**
```python
def calculate_video_duration(manifest: dict) -> float:
    """Calculate total duration of edited video from manifest.

    Sums the duration of all 'keep' and 'speedup' actions, adjusting
    for speedup factors. 'cut' and 'rewrite' actions are excluded.

    Args:
        manifest: Edit manifest with 'actions' list containing edit decisions.
                 Each action must have 'type', 'start_time', 'end_time'.

    Returns:
        Total duration in seconds as a float.

    Raises:
        ValueError: If manifest is missing required fields.
        ValueError: If action times are invalid (start >= end).

    Examples:
        >>> manifest = {
        ...     'actions': [
        ...         {'type': 'keep', 'start_time': 0.0, 'end_time': 10.0},
        ...         {'type': 'speedup', 'start_time': 10.0, 'end_time': 20.0,
        ...          'speedup_factor': 2.0}
        ...     ]
        ... }
        >>> calculate_video_duration(manifest)
        15.0  # 10 seconds + (10 seconds / 2.0 speedup)
    """
    total_duration = 0.0
    for action in manifest['actions']:
        if action['type'] in ['keep', 'speedup']:
            duration = action['end_time'] - action['start_time']
            speedup = action.get('speedup_factor', 1.0)
            total_duration += duration / speedup
    return total_duration
```
export function calculateWeightedScore(
  automatedScore: number,
  judgeScores: number[]
): number {
  if (automatedScore < 0 || automatedScore > 40) {
    throw new Error('Automated score must be between 0 and 40');
  }
  
  const judgeAverage = judgeScores.reduce((a, b) => a + b, 0) / judgeScores.length;
  return automatedScore + judgeAverage;
}
```

### 7. Naming Conventions
- [ ] Variables have meaningful, descriptive names
- [ ] Functions use verb phrases (e.g., `calculateScore`, `validateInput`)
- [ ] Boolean variables use `is`, `has`, `should` prefixes
- [ ] Constants use UPPER_SNAKE_CASE

**Example:**
```python
# ❌ Poor naming
d = datetime.now()
x = calc_thing(d)
def do_stuff(a): pass

# ✅ Clear naming (PEP 8 snake_case)
current_timestamp = datetime.now()
expiration_time = calculate_expiration_time(current_timestamp)
def validate_session_token(token: str) -> bool: pass

# ✅ Boolean variables
is_valid = validate_token(token)
has_audio = check_audio_track(video_path)
should_speedup = frame_rate > 30

# ✅ Constants
MAX_VIDEO_DURATION_SECONDS = 3600
DEFAULT_FRAME_RATE = 30.0
WHISPER_MODEL_NAME = "base"
```

### 8. Single Responsibility Principle
- [ ] Each function does one thing well
- [ ] Each class has one reason to change
- [ ] No "god functions" that do everything
- [ ] Clear separation of concerns

### 9. Unused Code
- [ ] No unused imports
- [ ] No commented-out code
- [ ] No dead code paths
- [ ] No unused variables

### 10. Security & Best Practices
- [ ] No hardcoded secrets or API keys
- [ ] Input validation on all user data
- [ ] Parameterized queries (no string concatenation)
- [ ] Proper authentication/authorization checks

## When to Refactor

### Always Refactor:
- ✅ After completing any task
- ✅ Before marking a task as complete
- ✅ After adding new functionality
- ✅ After fixing bugs
- ✅ Before committing code

### Refactor Immediately If:
- ⚠️ Function exceeds 20 lines
- ⚠️ File exceeds 300 lines
- ⚠️ You see duplicated code
- ⚠️ Missing type hints
- ⚠️ Missing error handling
- ⚠️ Missing docstrings

## Refactoring Process

### Step 1: Review Code Quality
```bash
# Run type checker
mypy src/

# Run linter
ruff check src/ tests/

# Auto-format code
black src/ tests/
```

### Step 2: Apply Refactoring Checklist
Go through each item in the checklist above and fix any issues.

### Step 3: Verify Tests Still Pass
```bash
pytest -v
```

### Step 4: Verify No New Errors
```bash
# Check type hints again
mypy src/

# Verify linting passes
ruff check src/ tests/
```

### Step 5: Commit Refactored Code
```bash
git add -A
git commit -m "refactor: improve code quality after task X"
git push origin main
```

## Integration with Task Workflow

### Complete Task Workflow:

1. **Implement** - Write the code for the task
2. **Test** - Write and run tests (must pass)
3. **Refactor** - Apply refactoring checklist (mandatory)
4. **Verify** - Run tests again, check diagnostics
5. **Commit** - Commit with descriptive message
6. **Complete** - Mark task as complete

### Never Do This:

```
Task 1: Implement feature X
  ├─ Write code ✅
  ├─ Write tests ✅
  ├─ Run tests ✅ PASSED
  └─ Mark task complete ❌ WRONG! Skipped refactoring!

Task 2: Start next task ❌ WRONG! Previous task not properly complete!
```

## Reporting Status

When reporting task completion, confirm refactoring:

- ✅ "Task complete - all tests passing, code refactored"
- ✅ "Task complete - refactored to meet all quality standards"
- ❌ "Task complete" (without mentioning refactoring)
- ✅ "Task in progress - implementing, will refactor before completion"

## Common Refactoring Patterns

### Pattern 1: Extract Function
```typescript
// Before: Long function
function processOrder(order: Order) {
  // 10 lines of validation
  // 10 lines of calculation
  // 10 lines of database
  // 10 lines of notification
}

// After: Extracted functions
function processOrder(order: Order): void {
  validateOrder(order);
  const total = calculateOrderTotal(order);
  saveOrder(order, total);
  notifyCustomer(order);
}
```

### Pattern 2: Extract Constant
```typescript
// Before: Magic numbers
if (score > 80) { }
if (attempts < 3) { }

// After: Named constants
const PASSING_SCORE = 80;
const MAX_RETRY_ATTEMPTS = 3;

if (score > PASSING_SCORE) { }
if (attempts < MAX_RETRY_ATTEMPTS) { }
```

### Pattern 3: Replace Type with Interface
```typescript
// Before: Inline types
function createUser(data: { name: string; email: string; age: number }) { }

// After: Named interface
interface UserData {
  name: string;
  email: string;
  age: number;
}

function createUser(data: UserData): void { }
```

### Pattern 4: Add Error Handling
```typescript
// Before: No error handling
async function fetchData() {
  const response = await fetch(url);
  return response.json();
}

// After: Proper error handling
async function fetchData(): Promise<Data> {
  try {
    const response = await fetch(url);
    if (!response.ok) {
      throw new Error(`HTTP ${response.status}: ${response.statusText}`);
    }
    return await response.json();
  } catch (error) {
    console.error('Fetch failed:', error);
    throw new Error('Failed to fetch data | Remediation: Check network and API endpoint');
  }
}
```

## Why This Matters

### Benefits of Mandatory Refactoring:
- 🎯 **Maintainability** - Clean code is easier to modify
- 🐛 **Fewer Bugs** - Simple code has fewer hiding places for bugs
- 📖 **Readability** - Clear code is self-documenting
- 🧪 **Testability** - Small functions are easier to test
- 🚀 **Velocity** - Clean code speeds up future development
- 👥 **Collaboration** - Consistent code is easier for teams

### Costs of Skipping Refactoring:
- 💸 **Technical Debt** - Accumulates and slows development
- 🐌 **Slower Development** - Messy code takes longer to modify
- 🐛 **More Bugs** - Complex code hides bugs
- 😤 **Frustration** - Developers hate working with messy code
- 🔥 **Rewrites** - Eventually code becomes unmaintainable

## Exceptions

### When You Can Skip Refactoring:
- ❌ **NEVER** - There are no valid exceptions
- Even for "quick fixes" or "temporary code"
- Even for "prototype" or "POC" code
- Even when "under time pressure"

### Why No Exceptions:
- "Temporary" code becomes permanent
- Technical debt compounds quickly
- Quality standards must be consistent
- Refactoring later is harder than refactoring now

## References

**Python Style Guides:**
- PEP 8 - Python code style
- PEP 257 - Docstring conventions

**Related Guidelines:**
- [testing-overview.md](./testing-overview.md) - Testing requirements
- [coding-standards.md](./coding-standards.md) - Python coding standards
- [metrics-and-limits.md](./metrics-and-limits.md) - Function/file length limits

**Real Examples from RVA Epic:**
- screencast-optimizer-rva.1 - Refactored VideoAssembler.assemble() (126→20 lines)
- screencast-optimizer-rva.5 - Created ffmpeg_utils.py (eliminated duplication)
- screencast-optimizer-rva.6 - Created config/constants.py (centralized magic numbers)

**Tools:**
- `mypy` - Type checking
- `ruff` - Fast Python linter
- `black` - Code formatter
- `pytest` - Test runner
