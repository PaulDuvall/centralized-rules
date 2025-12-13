---
inclusion: fileMatch
fileMatchPattern: '**/{phase2_director,phase3_voice,phase1_ingest}.py'
---

# 🤖 AI/LLM Integration Guidelines

> **Purpose:** Best practices for integrating AI services (Whisper, GPT-4, Claude, ElevenLabs TTS)
>
> **When to use:** Working with Phase 1 (Whisper), Phase 2 (LLM edit planning), Phase 3 (TTS voice generation)
>
> **See also:** [performance-monitoring.md](./performance-monitoring.md) | [testing-mocking.md](./testing-mocking.md)

## AI Services in This Project

This project heavily relies on AI services for video optimization:

1. **Phase 1 - OpenAI Whisper**: Speech-to-text transcription
2. **Phase 2 - GPT-4/Claude**: Intelligent edit decision generation
3. **Phase 3 - ElevenLabs/OpenAI TTS**: Professional voice synthesis

Each service has unique characteristics, costs, and best practices.

---

## Phase 1: Whisper Transcription

### Service Options

**Local Whisper Model (Recommended for Development)**
- Cost: Free
- Speed: 1-3 minutes for 30-min video
- Quality: Excellent
- Setup: Requires `openai-whisper` package

**Whisper API**
- Cost: $0.006/minute (~$0.18 for 30-min video)
- Speed: 30-60 seconds for 30-min video
- Quality: Excellent
- Setup: Requires OpenAI API key

### Best Practices

#### 1. Use Local Model for Development

```python
import whisper

class WhisperTranscriber:
    """Transcribe audio using local Whisper model."""

    def __init__(self, model_name: str = "base"):
        """Initialize with Whisper model.

        Models: tiny, base, small, medium, large
        - tiny: Fastest, lowest quality
        - base: Good balance (recommended)
        - large: Best quality, slowest
        """
        self.model = whisper.load_model(model_name)

    def transcribe(self, audio_path: str) -> dict:
        """Transcribe audio file."""
        result = self.model.transcribe(
            audio_path,
            language="en",  # Force English for consistency
            task="transcribe",  # vs "translate"
            fp16=False  # Use CPU
        )
        return result
```

#### 2. Handle Transcription Errors Gracefully

```python
from typing import Optional

def transcribe_with_fallback(
    audio_path: str,
    primary_model: str = "base",
    fallback_model: str = "tiny"
) -> Optional[dict]:
    """Attempt transcription with fallback to smaller model."""
    try:
        transcriber = WhisperTranscriber(primary_model)
        return transcriber.transcribe(audio_path)
    except RuntimeError as e:
        # Out of memory, try smaller model
        if "out of memory" in str(e).lower():
            print(f"⚠️  {primary_model} OOM, falling back to {fallback_model}")
            transcriber = WhisperTranscriber(fallback_model)
            return transcriber.transcribe(audio_path)
        raise
    except Exception as e:
        print(f"❌ Transcription failed: {e}")
        return None
```

#### 3. Post-Process Transcripts

```python
def clean_transcript_segments(segments: list) -> list:
    """Clean and normalize transcript segments."""
    cleaned = []

    for seg in segments:
        # Remove empty or whitespace-only segments
        text = seg.get("text", "").strip()
        if not text:
            continue

        # Normalize timing
        start = max(0.0, float(seg.get("start", 0)))
        end = max(start, float(seg.get("end", 0)))

        # Fix common Whisper artifacts
        text = text.replace("[BLANK_AUDIO]", "")
        text = text.replace("...", ".")

        cleaned.append({
            "id": len(cleaned),
            "start": start,
            "end": end,
            "text": text
        })

    return cleaned
```

---

## Phase 2: LLM Edit Planning

### Prompt Engineering Principles

**The edit planning prompt is critical.** It determines video quality.

#### 1. Structured Prompts with Clear Instructions

```python
SYSTEM_PROMPT = """You are an expert video editor analyzing screencast transcripts.

Your task:
1. Identify boring sections (installations, waiting, repetition)
2. Suggest cuts, speedups, or rewrites
3. Generate professional narration for key sections

Output ONLY valid JSON with this structure:
{
  "actions": [
    {
      "type": "keep|cut|speedup|rewrite",
      "start_time": float,
      "end_time": float,
      "speed": float (for speedup, default 1.0),
      "text": "new narration" (for rewrite),
      "reason": "why this action was chosen"
    }
  ]
}

Rules:
- Cut installation/waiting (> 10 seconds of no valuable content)
- Speed up repetitive tasks (2-3x speed)
- Rewrite for clarity and professionalism
- Keep important explanations at 1x speed
- Total output should be 10-20% of original duration
"""
```

#### 2. Few-Shot Examples

```python
FEW_SHOT_EXAMPLES = [
    {
        "transcript": "Okay, so I'm going to install the dependencies... this might take a while...",
        "actions": [
            {
                "type": "cut",
                "start_time": 0.0,
                "end_time": 120.0,
                "reason": "Installation waiting time, no valuable content"
            }
        ]
    },
    {
        "transcript": "Let me show you this important concept. The key thing to understand is...",
        "actions": [
            {
                "type": "keep",
                "start_time": 0.0,
                "end_time": 30.0,
                "speed": 1.0,
                "reason": "Important explanation, keep at normal speed"
            }
        ]
    }
]
```

#### 3. Provider Abstraction

```python
from abc import ABC, abstractmethod
from typing import List, Dict, Any

class LLMProvider(ABC):
    """Abstract base for LLM providers."""

    @abstractmethod
    def generate_edit_plan(self, transcript: str, context: Dict[str, Any]) -> Dict:
        """Generate edit plan from transcript."""
        pass


class OpenAIProvider(LLMProvider):
    """OpenAI GPT-4 provider."""

    def __init__(self, api_key: str, model: str = "gpt-4o"):
        import openai
        self.client = openai.OpenAI(api_key=api_key)
        self.model = model

    def generate_edit_plan(self, transcript: str, context: Dict) -> Dict:
        """Generate edit plan using GPT-4."""
        response = self.client.chat.completions.create(
            model=self.model,
            messages=[
                {"role": "system", "content": SYSTEM_PROMPT},
                {"role": "user", "content": f"Transcript:\n{transcript}"}
            ],
            temperature=0.3,  # Lower = more consistent
            response_format={"type": "json_object"}  # Force JSON
        )

        return json.loads(response.choices[0].message.content)


class AnthropicProvider(LLMProvider):
    """Anthropic Claude provider."""

    def __init__(self, api_key: str, model: str = "claude-sonnet-4"):
        import anthropic
        self.client = anthropic.Anthropic(api_key=api_key)
        self.model = model

    def generate_edit_plan(self, transcript: str, context: Dict) -> Dict:
        """Generate edit plan using Claude."""
        response = self.client.messages.create(
            model=self.model,
            max_tokens=4096,
            messages=[
                {"role": "user", "content": f"{SYSTEM_PROMPT}\n\nTranscript:\n{transcript}"}
            ],
            temperature=0.3
        )

        return json.loads(response.content[0].text)
```

#### 4. Error Handling and Retries

```python
import time
from typing import Optional

def call_llm_with_retry(
    provider: LLMProvider,
    transcript: str,
    max_retries: int = 3,
    backoff_factor: float = 2.0
) -> Optional[Dict]:
    """Call LLM with exponential backoff retry."""

    for attempt in range(max_retries):
        try:
            return provider.generate_edit_plan(transcript, {})

        except json.JSONDecodeError as e:
            print(f"⚠️  Invalid JSON from LLM (attempt {attempt + 1}/{max_retries})")
            if attempt == max_retries - 1:
                raise

        except Exception as e:
            # Rate limit, network error, etc.
            if "rate_limit" in str(e).lower() and attempt < max_retries - 1:
                wait_time = backoff_factor ** attempt
                print(f"⏳ Rate limited, waiting {wait_time}s...")
                time.sleep(wait_time)
            else:
                raise

    return None
```

#### 5. Validate LLM Output

```python
from pydantic import BaseModel, Field, validator
from typing import Literal

class EditAction(BaseModel):
    """Validated edit action from LLM."""

    type: Literal["keep", "cut", "speedup", "rewrite"]
    start_time: float = Field(ge=0.0)
    end_time: float
    speed: float = Field(default=1.0, gt=0.0, le=10.0)
    text: Optional[str] = None
    reason: str

    @validator("end_time")
    def end_after_start(cls, v, values):
        if v <= values.get("start_time", 0):
            raise ValueError("end_time must be after start_time")
        return v

    @validator("text")
    def text_required_for_rewrite(cls, v, values):
        if values.get("type") == "rewrite" and not v:
            raise ValueError("text required for rewrite actions")
        return v


def validate_edit_plan(raw_plan: Dict) -> List[EditAction]:
    """Validate and parse LLM output."""
    try:
        actions = [EditAction(**action) for action in raw_plan.get("actions", [])]
        return actions
    except Exception as e:
        print(f"❌ Invalid edit plan from LLM: {e}")
        raise
```

### Cost Optimization

```python
# Use cheaper models when possible
MODELS_BY_COST = {
    "cheapest": "gpt-4o-mini",      # ~$0.05 per video
    "balanced": "gpt-4o",            # ~$0.32 per video
    "best": "claude-opus-4"          # ~$0.50 per video
}

def choose_model_by_budget(max_cost_per_video: float = 0.10) -> str:
    """Select model based on budget."""
    if max_cost_per_video < 0.10:
        return MODELS_BY_COST["cheapest"]
    elif max_cost_per_video < 0.40:
        return MODELS_BY_COST["balanced"]
    else:
        return MODELS_BY_COST["best"]
```

---

## Phase 3: TTS Voice Generation

### Service Options

**ElevenLabs**
- Cost: $0.30 per 1K characters (~$2.10 for typical video)
- Quality: Excellent, very natural
- Voices: Wide variety, customizable
- Rate Limits: Strict (watch for 429 errors)

**OpenAI TTS**
- Cost: $15 per 1M characters (~$0.21 for typical video)
- Quality: Very good, improving
- Voices: Limited but high quality
- Rate Limits: More generous

### Best Practices

#### 1. Pronunciation Dictionary

```python
import re
from typing import Dict

class PronunciationDictionary:
    """Apply pronunciation fixes for TTS."""

    DEFAULT_RULES = {
        # Technical terms
        "router": "rau-ter",
        "API": "ay-pee-eye",
        "CLI": "see-ell-eye",
        "GUI": "goo-ee",
        "SQL": "sequel",

        # Common mispronounciations
        "kubernetes": "koo-ber-net-eez",
        "nginx": "engine-x",
        "PostgreSQL": "post-gres sequel",

        # Acronyms
        "AWS": "ay-double-you-ess",
        "CI/CD": "see-eye see-dee",
        "REST": "rest",
    }

    def __init__(self, custom_rules: Dict[str, str] = None):
        self.rules = {**self.DEFAULT_RULES, **(custom_rules or {})}

    def apply(self, text: str, case_sensitive: bool = False) -> str:
        """Apply pronunciation fixes to text."""
        result = text

        for trigger, replacement in self.rules.items():
            if case_sensitive:
                result = result.replace(trigger, replacement)
            else:
                # Case-insensitive replacement
                pattern = re.compile(re.escape(trigger), re.IGNORECASE)
                result = pattern.sub(replacement, result)

        return result
```

#### 2. Provider Abstraction with Fallback

```python
class TTSProvider(ABC):
    """Abstract base for TTS providers."""

    @abstractmethod
    def generate_audio(self, text: str, output_path: str) -> float:
        """Generate audio, return duration in seconds."""
        pass


class VoiceGenerator:
    """Generate voice with automatic fallback."""

    def __init__(
        self,
        primary_provider: str = "elevenlabs",
        fallback_provider: str = "openai"
    ):
        self.pronunciation_dict = PronunciationDictionary()
        self.primary = self._init_provider(primary_provider)
        self.fallback = self._init_provider(fallback_provider)

    def generate_audio(self, text: str, output_path: str) -> float:
        """Generate audio with pronunciation fixes and fallback."""
        # Apply pronunciation fixes
        fixed_text = self.pronunciation_dict.apply(text)

        # Try primary provider
        try:
            return self.primary.generate_audio(fixed_text, output_path)
        except Exception as e:
            print(f"⚠️  Primary TTS failed: {e}, trying fallback...")

            # Try fallback provider
            try:
                return self.fallback.generate_audio(fixed_text, output_path)
            except Exception as e2:
                print(f"❌ Fallback TTS also failed: {e2}")
                raise
```

#### 3. Rate Limit Handling

```python
import time
from functools import wraps

def rate_limit_retry(max_retries: int = 3, base_delay: float = 5.0):
    """Decorator for handling TTS rate limits."""

    def decorator(func):
        @wraps(func)
        def wrapper(*args, **kwargs):
            for attempt in range(max_retries):
                try:
                    return func(*args, **kwargs)

                except Exception as e:
                    if "rate_limit" in str(e).lower() or "429" in str(e):
                        if attempt < max_retries - 1:
                            wait = base_delay * (2 ** attempt)  # Exponential backoff
                            print(f"⏳ Rate limited, waiting {wait}s...")
                            time.sleep(wait)
                        else:
                            raise
                    else:
                        raise

        return wrapper
    return decorator


class ElevenLabsProvider(TTSProvider):
    """ElevenLabs TTS with rate limit handling."""

    @rate_limit_retry(max_retries=3, base_delay=5.0)
    def generate_audio(self, text: str, output_path: str) -> float:
        """Generate audio with automatic retry on rate limits."""
        # ElevenLabs API call...
        pass
```

#### 4. Batch Generation Optimization

```python
from typing import List, Tuple

def batch_generate_narration(
    segments: List[Dict[str, str]],
    generator: VoiceGenerator,
    output_dir: Path
) -> List[Tuple[str, float]]:
    """Generate narration for multiple segments efficiently."""

    results = []

    for i, segment in enumerate(segments):
        output_path = output_dir / f"narration_{i:03d}.mp3"

        # Combine very short segments to reduce API calls
        if len(segment["text"]) < 50 and i < len(segments) - 1:
            # Combine with next segment
            combined_text = segment["text"] + " " + segments[i + 1]["text"]
            duration = generator.generate_audio(combined_text, str(output_path))
            results.append((str(output_path), duration))
            segments[i + 1] = {"text": ""}  # Mark as processed
        elif segment["text"]:  # Not empty
            duration = generator.generate_audio(segment["text"], str(output_path))
            results.append((str(output_path), duration))

    return results
```

---

## Testing AI Integrations

### Mocking AI Services

**Always mock in unit tests, optionally use real in integration tests.**

```python
import pytest
from unittest.mock import patch, MagicMock

@pytest.fixture
def mock_whisper():
    """Mock Whisper for fast tests."""
    with patch('whisper.load_model') as mock:
        instance = MagicMock()
        instance.transcribe.return_value = {
            'segments': [
                {'start': 0.0, 'end': 5.0, 'text': 'Test segment'}
            ]
        }
        mock.return_value = instance
        yield mock


@pytest.fixture
def mock_openai():
    """Mock OpenAI for deterministic tests."""
    with patch('openai.chat.completions.create') as mock:
        response = MagicMock()
        response.choices[0].message.content = json.dumps({
            'actions': [
                {'type': 'keep', 'start_time': 0.0, 'end_time': 5.0, 'reason': 'test'}
            ]
        })
        mock.return_value = response
        yield mock


@pytest.fixture
def mock_elevenlabs():
    """Mock ElevenLabs for tests."""
    with patch('elevenlabs.generate') as mock:
        mock.return_value = b'\x00\x01' * 1000  # Fake audio
        yield mock
```

### Integration Tests with Real APIs

```python
import os

@pytest.mark.integration
@pytest.mark.skipif(
    not os.getenv("OPENAI_API_KEY"),
    reason="No OpenAI API key"
)
def test_real_whisper_transcription(minimal_test_audio):
    """Integration test with real Whisper API (costs $0.006 per minute)."""
    transcriber = WhisperTranscriber("base")
    result = transcriber.transcribe(str(minimal_test_audio))

    assert "segments" in result
    # Audio may be silent, so segments could be empty
```

---

## Monitoring and Cost Tracking

### Log API Usage

```python
import json
from pathlib import Path
from datetime import datetime

class APIUsageLogger:
    """Track AI API usage and costs."""

    def __init__(self, log_file: Path = Path("api_usage.jsonl")):
        self.log_file = log_file

    def log_whisper_call(self, duration_seconds: float, model: str):
        """Log Whisper transcription."""
        cost = (duration_seconds / 60) * 0.006  # $0.006 per minute

        self._append_log({
            "timestamp": datetime.now().isoformat(),
            "service": "whisper",
            "model": model,
            "duration_seconds": duration_seconds,
            "estimated_cost": cost
        })

    def log_llm_call(self, provider: str, model: str, input_tokens: int, output_tokens: int):
        """Log LLM API call."""
        # Simplified cost calculation
        costs = {
            "gpt-4o": {"input": 2.50 / 1_000_000, "output": 10.00 / 1_000_000},
            "gpt-4o-mini": {"input": 0.15 / 1_000_000, "output": 0.60 / 1_000_000},
        }

        pricing = costs.get(model, {"input": 0, "output": 0})
        cost = (input_tokens * pricing["input"]) + (output_tokens * pricing["output"])

        self._append_log({
            "timestamp": datetime.now().isoformat(),
            "service": "llm",
            "provider": provider,
            "model": model,
            "input_tokens": input_tokens,
            "output_tokens": output_tokens,
            "estimated_cost": cost
        })

    def log_tts_call(self, provider: str, characters: int):
        """Log TTS API call."""
        costs = {
            "elevenlabs": 0.30 / 1000,
            "openai": 15.00 / 1_000_000
        }

        cost = characters * costs.get(provider, 0)

        self._append_log({
            "timestamp": datetime.now().isoformat(),
            "service": "tts",
            "provider": provider,
            "characters": characters,
            "estimated_cost": cost
        })

    def _append_log(self, entry: dict):
        """Append entry to JSONL log."""
        with open(self.log_file, 'a') as f:
            f.write(json.dumps(entry) + '\n')

    def total_cost(self) -> float:
        """Calculate total estimated cost."""
        if not self.log_file.exists():
            return 0.0

        total = 0.0
        with open(self.log_file) as f:
            for line in f:
                entry = json.loads(line)
                total += entry.get("estimated_cost", 0.0)

        return total
```

---

## Common AI Integration Issues

### Issue 1: Inconsistent LLM Outputs

**Problem:** LLM returns different edit plans for same transcript.

**Solution:**
```python
# Use lower temperature for consistency
response = client.chat.completions.create(
    model="gpt-4o",
    temperature=0.3,  # Lower = more deterministic (0.0-1.0)
    # ...
)
```

### Issue 2: Invalid JSON from LLM

**Problem:** LLM returns malformed JSON.

**Solution:**
```python
# Force JSON output format (OpenAI)
response = client.chat.completions.create(
    model="gpt-4o",
    response_format={"type": "json_object"},  # Force valid JSON
    # ...
)

# Validate with Pydantic
try:
    plan = EditPlan(**json.loads(response.content))
except ValidationError as e:
    # Handle validation errors
    pass
```

### Issue 3: TTS Pronunciation Errors

**Problem:** TTS mispronounces technical terms.

**Solution:**
```python
# Expand pronunciation dictionary
pronunciation_dict.add_rule("Kubernetes", "koo-ber-net-eez")

# Test pronunciation before batch processing
test_audio = generator.generate_audio("Test: Kubernetes cluster", "test.mp3")
# Listen and verify
```

### Issue 4: Rate Limit Errors

**Problem:** 429 errors from ElevenLabs or OpenAI.

**Solution:**
```python
# Implement exponential backoff
@rate_limit_retry(max_retries=5, base_delay=10.0)
def api_call():
    # ...
    pass

# Or switch to provider with higher limits
generator = VoiceGenerator(
    primary_provider="openai",  # More generous limits
    fallback_provider="elevenlabs"
)
```

### Issue 5: High API Costs

**Problem:** Costs exceeding budget.

**Solution:**
```python
# Use cheaper models
director = DirectorAgent(model="gpt-4o-mini")  # 10x cheaper than GPT-4o

# Use local Whisper instead of API
transcriber = WhisperTranscriber("base")  # Free vs $0.18 per video

# Cache results
if Path("edit_plan.json").exists():
    with open("edit_plan.json") as f:
        plan = json.load(f)
else:
    plan = director.generate_edit_plan(transcript)
    # Save for reuse
    with open("edit_plan.json", "w") as f:
        json.dump(plan, f)
```

---

## References

- **Performance monitoring**: [performance-monitoring.md](./performance-monitoring.md)
- **Testing mocks**: [testing-mocking.md](./testing-mocking.md)
- **API docs**: OpenAI, Anthropic, ElevenLabs official documentation
- **Pricing**: Check provider websites for current rates (prices change)

---

**Last Updated:** 2025-12-10
**Python Version:** 3.11+
**Primary AI Services:** OpenAI Whisper, GPT-4o, ElevenLabs, OpenAI TTS
