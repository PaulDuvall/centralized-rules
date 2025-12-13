---
inclusion: fileMatch
fileMatchPattern: '{config/*.json,**/*manifest*.json,src/models.py}'
---

# 📄 Data Conventions

> **Icon:** 📄 Used when working with JSON manifests, config files, or data structures
>
> **📋 Related:** Pydantic models, JSON Schema validation
>
> This document defines conventions for data formats, configuration files, and manifest structures in the screencast optimizer project.

This project is **manifest-driven**: all editing decisions are stored as JSON that can be inspected, modified, and re-rendered.

## Manifest-Driven Architecture

### The Core Principle

**All edit decisions are represented as JSON manifests** that serve as the single source of truth for video processing:

1. **Phase 1** (Ingest) → Generates audio + transcript metadata
2. **Phase 2** (Director) → Generates **edit manifest** (JSON)
3. **Phase 3** (Voice) → Adds audio files to manifest
4. **Phase 4** (Assembly) → Renders video from manifest

### Why Manifests?

- ✅ **Inspectable** - Human-readable JSON
- ✅ **Editable** - Manually tweak before rendering
- ✅ **Reproducible** - Re-render without re-running phases 1-3
- ✅ **Testable** - Validate manifest structure before expensive rendering
- ✅ **Debuggable** - See exactly what the AI decided

## Manifest Structure

### Edit Manifest Schema

Defined in `src/models.py` using Pydantic:

```python
from pydantic import BaseModel, Field
from typing import Literal

class EditAction(BaseModel):
    """Single edit action in the manifest."""
    type: Literal["keep", "cut", "speedup", "rewrite"]
    start_time: float = Field(ge=0)
    end_time: float = Field(ge=0)
    speedup_factor: float = Field(default=1.0, gt=0)
    new_narration: str | None = None
    new_narration_audio: str | None = None  # Path to audio file

class EditManifest(BaseModel):
    """Complete edit manifest for video optimization."""
    video_path: str
    audio_path: str | None = None
    transcript: list[dict]  # Whisper segments
    actions: list[EditAction]
    metadata: dict = Field(default_factory=dict)
```

### Example Manifest

```json
{
  "video_path": "/path/to/input.mp4",
  "audio_path": "/path/to/audio.wav",
  "transcript": [
    {
      "text": "Let me show you how to install this package",
      "start": 0.0,
      "end": 3.5
    },
    {
      "text": "First we'll run npm install",
      "start": 3.5,
      "end": 5.2
    }
  ],
  "actions": [
    {
      "type": "keep",
      "start_time": 0.0,
      "end_time": 3.5,
      "speedup_factor": 1.0
    },
    {
      "type": "cut",
      "start_time": 3.5,
      "end_time": 45.0,
      "comment": "Cut boring installation wait"
    },
    {
      "type": "rewrite",
      "start_time": 45.0,
      "end_time": 48.0,
      "new_narration": "The package installed successfully.",
      "new_narration_audio": "/path/to/audio_segment_001.mp3"
    },
    {
      "type": "speedup",
      "start_time": 48.0,
      "end_time": 60.0,
      "speedup_factor": 3.0
    }
  ],
  "metadata": {
    "generated_at": "2025-12-10T10:00:00",
    "llm_provider": "openai",
    "model": "gpt-4o"
  }
}
```

## Configuration Files

### Video Library (`config/videos.json`)

**Status:** Gitignored (user-specific)

```json
{
  "videos": [
    {
      "id": "tutorial-001",
      "name": "AWS Lambda Tutorial",
      "path": "/Users/user/Videos/lambda-tutorial.mp4",
      "description": "Introduction to AWS Lambda",
      "tags": ["aws", "serverless", "lambda"],
      "priority": 1
    },
    {
      "id": "tutorial-002",
      "name": "Docker Basics",
      "path": "/Users/user/Videos/docker-intro.mp4",
      "priority": 2
    }
  ]
}
```

**Conventions:**
- ✅ Each video has a unique `id`
- ✅ `path` is absolute path to video file
- ✅ `priority` determines batch processing order
- ✅ Optional: `tags`, `description`, `metadata`

### Pronunciation Rules (`config/pronunciation_rules.json`)

**Status:** Version controlled

```json
[
  {
    "trigger": "router",
    "pattern": "(?i)\\brouters?\\b",
    "replacement": "rau-ter",
    "description": "Fix 'router' pronunciation"
  },
  {
    "trigger": "ascii",
    "pattern": "(?i)\\bascii\\b",
    "replacement": "azkey",
    "description": "Fix 'ASCII' pronunciation"
  },
  {
    "trigger": "database",
    "pattern": "(?i)\\bdatabase\\b",
    "replacement": "data base",
    "description": "Add pause between 'data' and 'base'"
  }
]
```

**Conventions:**
- ✅ `trigger` - Simple lowercase word for matching
- ✅ `pattern` - Regex pattern (case-insensitive flag `(?i)`)
- ✅ `replacement` - Phonetic spelling for TTS
- ✅ `description` - Human-readable explanation
- ✅ Use word boundaries `\\b` in patterns

### Environment Configuration (`.env`)

**Status:** Gitignored (contains secrets)

See [security.md](./security.md) for API key management.

```bash
# Required
OPENAI_API_KEY=sk-...

# Optional providers
ANTHROPIC_API_KEY=sk-ant-...
ELEVENLABS_API_KEY=...

# Optional preferences
DEFAULT_VOICE_ID=wevlkhfRsG0ND2D2pQHq
TTS_PROVIDER=elevenlabs
LLM_PROVIDER=openai
```

## Pydantic Data Models

### Why Pydantic?

- ✅ **Validation** - Automatic type checking and value validation
- ✅ **Serialization** - Easy JSON conversion
- ✅ **Documentation** - Self-documenting with Field descriptions
- ✅ **IDE Support** - Full autocomplete and type hints

### Model Patterns

**Example from `src/models.py`:**

```python
from pydantic import BaseModel, Field, field_validator
from pathlib import Path

class VideoMetadata(BaseModel):
    """Metadata for a video file."""
    path: Path
    duration: float = Field(gt=0, description="Duration in seconds")
    frame_rate: float = Field(gt=0, description="FPS")
    resolution: tuple[int, int]

    @field_validator('path')
    @classmethod
    def validate_path_exists(cls, v: Path) -> Path:
        """Ensure video file exists."""
        if not v.exists():
            raise ValueError(f"Video file not found: {v}")
        return v

    @field_validator('resolution')
    @classmethod
    def validate_resolution(cls, v: tuple[int, int]) -> tuple[int, int]:
        """Ensure resolution is positive."""
        width, height = v
        if width <= 0 or height <= 0:
            raise ValueError(f"Invalid resolution: {width}x{height}")
        return v
```

### Model Usage

```python
# Load from JSON
with open('manifest.json', 'r') as f:
    data = json.load(f)
    manifest = EditManifest(**data)  # Validates automatically

# Save to JSON
with open('manifest.json', 'w') as f:
    json.dump(manifest.model_dump(), f, indent=2)

# Validate fields
try:
    action = EditAction(
        type="keep",
        start_time=0.0,
        end_time=-5.0  # Invalid!
    )
except ValidationError as e:
    print(f"Validation error: {e}")
```

## JSON Conventions

### File Naming
- ✅ Use `.json` extension
- ✅ Use snake_case for filenames: `edit_manifest.json`
- ✅ Include context in name: `tutorial_001_manifest.json`
- ✅ Version if needed: `manifest_v2.json`

### Formatting
- ✅ Use 2-space indentation
- ✅ Sort keys alphabetically (where order doesn't matter)
- ✅ Use trailing commas in arrays/objects (for cleaner diffs)
- ✅ Include schema version in metadata

### Timestamps
- ✅ Use ISO 8601 format: `"2025-12-10T10:30:00-05:00"`
- ✅ Store in UTC when possible
- ✅ Include timezone offset for user-facing times

### File Paths in JSON
- ✅ Use absolute paths by default
- ✅ Use forward slashes `/` even on Windows (Python Path handles conversion)
- ✅ Validate paths exist when loading
- ✅ Document whether paths are required to exist

## Data Validation

### Manifest Validation

```python
def validate_manifest(manifest: EditManifest) -> list[str]:
    """Validate manifest integrity.

    Returns:
        List of validation errors (empty if valid)
    """
    errors = []

    # Check video file exists
    if not Path(manifest.video_path).exists():
        errors.append(f"Video file not found: {manifest.video_path}")

    # Check actions are sequential
    for i, action in enumerate(manifest.actions):
        if action.start_time >= action.end_time:
            errors.append(
                f"Action {i}: start_time >= end_time "
                f"({action.start_time} >= {action.end_time})"
            )

        # Check no overlaps
        if i > 0:
            prev_action = manifest.actions[i - 1]
            if action.start_time < prev_action.end_time:
                errors.append(
                    f"Action {i}: overlaps with previous action "
                    f"({action.start_time} < {prev_action.end_time})"
                )

    # Check audio files exist for rewrite actions
    for i, action in enumerate(manifest.actions):
        if action.type == "rewrite" and action.new_narration_audio:
            if not Path(action.new_narration_audio).exists():
                errors.append(
                    f"Action {i}: Audio file not found: "
                    f"{action.new_narration_audio}"
                )

    return errors
```

### Configuration Validation

```python
def load_video_config(config_path: Path) -> dict:
    """Load and validate video configuration.

    Args:
        config_path: Path to videos.json

    Returns:
        Validated config dictionary

    Raises:
        ValueError: If config is invalid
    """
    if not config_path.exists():
        raise ValueError(f"Config file not found: {config_path}")

    with open(config_path, 'r') as f:
        config = json.load(f)

    # Validate structure
    if 'videos' not in config:
        raise ValueError("Config missing 'videos' key")

    # Validate each video
    seen_ids = set()
    for i, video in enumerate(config['videos']):
        # Required fields
        if 'id' not in video:
            raise ValueError(f"Video {i}: missing 'id'")
        if 'path' not in video:
            raise ValueError(f"Video {i}: missing 'path'")

        # Unique IDs
        if video['id'] in seen_ids:
            raise ValueError(f"Duplicate video ID: {video['id']}")
        seen_ids.add(video['id'])

        # Path exists
        if not Path(video['path']).exists():
            raise ValueError(
                f"Video {video['id']}: file not found at {video['path']}"
            )

    return config
```

## Testing Data Structures

### Fixture Manifests

Create minimal test manifests in `tests/fixtures/`:

```python
# tests/fixtures/manifests.py
def minimal_manifest() -> dict:
    """Minimal valid manifest for testing."""
    return {
        "video_path": "/tmp/test.mp4",
        "actions": [
            {"type": "keep", "start_time": 0.0, "end_time": 10.0}
        ]
    }

def complex_manifest() -> dict:
    """Complex manifest with all action types."""
    return {
        "video_path": "/tmp/test.mp4",
        "audio_path": "/tmp/audio.wav",
        "transcript": [
            {"text": "Hello", "start": 0.0, "end": 1.0}
        ],
        "actions": [
            {"type": "keep", "start_time": 0.0, "end_time": 2.0},
            {"type": "cut", "start_time": 2.0, "end_time": 5.0},
            {
                "type": "rewrite",
                "start_time": 5.0,
                "end_time": 7.0,
                "new_narration": "New text",
                "new_narration_audio": "/tmp/audio_001.mp3"
            },
            {
                "type": "speedup",
                "start_time": 7.0,
                "end_time": 10.0,
                "speedup_factor": 2.0
            }
        ]
    }
```

### Property-Based Testing

Use hypothesis to generate test manifests:

```python
from hypothesis import given, strategies as st

@given(
    start=st.floats(min_value=0, max_value=100),
    end=st.floats(min_value=0, max_value=100)
)
def test_action_time_validation(start: float, end: float):
    """Test that actions validate time ranges."""
    if start >= end:
        # Should raise validation error
        with pytest.raises(ValidationError):
            EditAction(type="keep", start_time=start, end_time=end)
    else:
        # Should succeed
        action = EditAction(type="keep", start_time=start, end_time=end)
        assert action.start_time < action.end_time
```

## Best Practices

### Data Integrity
- ✅ Always validate manifests before rendering
- ✅ Use Pydantic models for automatic validation
- ✅ Include schema version in manifests for migration
- ✅ Log validation errors with context

### Error Handling
- ✅ Provide clear error messages for invalid data
- ✅ Include remediation guidance
- ✅ Fail early on validation errors (don't start rendering)

### Performance
- ✅ Cache loaded configurations
- ✅ Use lazy loading for large manifests
- ✅ Stream large JSON files if needed

### Backward Compatibility
- ✅ Add optional fields (don't remove required ones)
- ✅ Provide defaults for new fields
- ✅ Support migration from old manifest versions

## References

**Related Steering Files:**
- [security.md](./security.md) - Environment variable management, API key handling
- [testing-fixtures.md](./testing-fixtures.md) - Testing data structures and manifests
- [coding-standards.md](./coding-standards.md) - Pydantic model patterns
- [ai-integration.md](./ai-integration.md) - Manifest generation from LLMs

**Project Files:**
- `src/models.py` - Pydantic data models (EditAction, EditManifest)
- `config/pronunciation_rules.json` - Pronunciation configuration
- `config/videos.example.json` - Video library template
- [ARCHITECTURE.md](../../docs/ARCHITECTURE.md) - Manifest-driven architecture explanation
