---
inclusion: always
---

# 🔒 Security Guidelines

> **Icon:** 🔒 Used when handling API keys, secrets, user data, or security-sensitive operations
>
> **📋 Related:** .env management, AWS SSM, API authentication
>
> This document defines security best practices for the screencast optimizer project.

This project handles multiple API keys, user video content, and external service integrations. Security must be a top priority.

## API Key Management

### Required API Keys

This project requires several external API keys:
- **OPENAI_API_KEY** - For Whisper transcription and GPT-4 narration rewriting (optional: Anthropic as fallback)
- **ANTHROPIC_API_KEY** - For Claude narration rewriting (optional: alternative to OpenAI)
- **ELEVENLABS_API_KEY** - For voice synthesis (optional: OpenAI TTS as fallback)

### ⚠️ CRITICAL RULE: Never Commit API Keys

**MANDATORY:** API keys and secrets must NEVER be committed to git.

### The Rule:
- ✅ Store API keys in `.env` file (gitignored)
- ✅ Use `os.getenv()` to read environment variables
- ✅ Validate that required keys are present at startup
- ✅ Document required keys in `.env.example` (without real values)
- ✅ Consider AWS SSM Parameter Store for production deployments

### Environment Variable Pattern

**Example:**
```python
import os
from typing import Optional

def get_required_env(key: str) -> str:
    """Get required environment variable or raise error.

    Args:
        key: Environment variable name

    Returns:
        Value of environment variable

    Raises:
        ValueError: If environment variable is not set
    """
    value = os.getenv(key)
    if not value:
        raise ValueError(
            f'{key} not set | '
            f'Remediation: Add {key}=your_key_here to .env file'
        )
    return value

def get_optional_env(key: str) -> Optional[str]:
    """Get optional environment variable.

    Args:
        key: Environment variable name

    Returns:
        Value of environment variable or None if not set
    """
    return os.getenv(key)

# Usage
OPENAI_API_KEY = get_required_env('OPENAI_API_KEY')
ANTHROPIC_API_KEY = get_optional_env('ANTHROPIC_API_KEY')  # Fallback provider
```

### .env File Structure

```bash
# .env (gitignored)
OPENAI_API_KEY=sk-xxxxxxxxxxxxxxxxxxxxx
ANTHROPIC_API_KEY=sk-ant-xxxxxxxxxxxxx
ELEVENLABS_API_KEY=xxxxxxxxxxxxxxxxxx

# Optional: Voice preferences
DEFAULT_VOICE_ID=wevlkhfRsG0ND2D2pQHq
TTS_PROVIDER=elevenlabs  # or 'openai'
LLM_PROVIDER=openai      # or 'anthropic'
```

### .env.example Template

```bash
# .env.example (committed to git)
# Copy this to .env and fill in your API keys

# OpenAI API (required for Whisper transcription, optional for TTS/LLM)
OPENAI_API_KEY=sk-your-openai-key-here

# Anthropic API (optional, alternative LLM provider)
ANTHROPIC_API_KEY=sk-ant-your-anthropic-key-here

# ElevenLabs API (optional, alternative TTS provider)
ELEVENLABS_API_KEY=your-elevenlabs-key-here

# Voice preferences (optional)
DEFAULT_VOICE_ID=wevlkhfRsG0ND2D2pQHq
TTS_PROVIDER=elevenlabs
LLM_PROVIDER=openai
```

### Checking for Leaked Keys

```bash
# Before committing, verify no secrets in git
git diff | grep -E "(sk-|sk-ant-|[A-Z0-9]{32})"

# Use git-secrets or similar tools
git secrets --scan

# Check .env is gitignored
git check-ignore .env  # Should output: .env
```

## AWS SSM Parameter Store Integration

### Why Use AWS SSM?

The project supports storing API keys in AWS Systems Manager Parameter Store:
- Centralized secret management
- No `.env` files to manage
- Automatic rotation support
- Audit logging of access

### Implementation (from run.sh)

```bash
# run.sh lines 17-48
# Automatically detects AWS SSO and loads from SSM
if aws sts get-caller-identity &>/dev/null; then
    OPENAI_API_KEY=$(aws ssm get-parameter --name "/screencast-optimizer/OPENAI_API_KEY" --with-decryption --query 'Parameter.Value' --output text 2>/dev/null)
    # ... similar for other keys ...
fi
```

### Setting Up SSM Parameters

```bash
# Store API keys in AWS SSM
aws ssm put-parameter \
    --name "/screencast-optimizer/OPENAI_API_KEY" \
    --value "sk-your-key-here" \
    --type "SecureString" \
    --description "OpenAI API key for screencast optimizer"

# Read parameter (to verify)
aws ssm get-parameter \
    --name "/screencast-optimizer/OPENAI_API_KEY" \
    --with-decryption
```

### Fallback Strategy

The project uses a graceful fallback:
1. Try AWS SSM Parameter Store (if AWS credentials present)
2. Fall back to `.env` file
3. Fall back to environment variables
4. Raise error if required keys not found

## GitHub Actions Secrets

### Storing Secrets in CI/CD

For GitHub Actions (`.github/workflows/ci.yml`):
1. Go to repository Settings → Secrets and variables → Actions
2. Add secrets:
   - `OPENAI_API_KEY`
   - `ANTHROPIC_API_KEY` (if needed)
   - `ELEVENLABS_API_KEY` (if needed)

### Using Secrets in Workflows

```yaml
# .github/workflows/ci.yml
jobs:
  test:
    runs-on: ubuntu-latest
    env:
      OPENAI_API_KEY: ${{ secrets.OPENAI_API_KEY }}
      ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
    steps:
      - name: Run tests
        run: pytest tests/
```

### ⚠️ Important: Don't Log Secrets

```python
# ❌ BAD: Logs API key
print(f"Using API key: {OPENAI_API_KEY}")

# ✅ GOOD: Masks API key
print(f"Using API key: {OPENAI_API_KEY[:7]}...")

# ✅ BETTER: Just confirm presence
print("✓ OPENAI_API_KEY configured")
```

## User Content Security

### Video Data Privacy

User videos contain potentially sensitive content:
- Screen recordings may show private data
- Transcriptions contain spoken content
- Generated manifests contain video metadata

### Security Practices:
- ✅ Process videos locally by default (not uploaded to external servers)
- ✅ Only send audio/transcripts to AI services, not video files
- ✅ Delete temporary files after processing (audio, intermediate clips)
- ✅ Don't log user content (transcription text, narration)
- ✅ Inform users about data sent to external APIs (Whisper, GPT-4, ElevenLabs)

### Temporary File Cleanup

```python
import tempfile
from pathlib import Path

def process_video_safely(video_path: Path) -> Path:
    """Process video with automatic cleanup of temporary files."""
    temp_dir = Path(tempfile.mkdtemp(prefix='screencast_'))

    try:
        # Extract audio to temp directory
        audio_path = temp_dir / "audio.wav"
        extract_audio(video_path, audio_path)

        # Transcribe audio
        transcript = transcribe_audio(audio_path)

        # Process and generate output
        output_path = generate_final_video(video_path, transcript)

        return output_path

    finally:
        # Always clean up temporary files
        if temp_dir.exists():
            shutil.rmtree(temp_dir)
            print(f"✓ Cleaned up temporary files in {temp_dir}")
```

## Input Validation and Path Security

### Prevent Path Traversal

```python
from pathlib import Path

def validate_video_path(user_input: str) -> Path:
    """Validate and sanitize user-provided video path.

    Args:
        user_input: User-provided path string

    Returns:
        Validated Path object

    Raises:
        ValueError: If path is invalid or dangerous
    """
    # Resolve to absolute path (prevents relative path attacks)
    path = Path(user_input).resolve()

    # Check file exists
    if not path.exists():
        raise ValueError(f"File not found: {path}")

    # Check it's actually a file
    if not path.is_file():
        raise ValueError(f"Path is not a file: {path}")

    # Validate extension
    allowed_extensions = {'.mp4', '.mov', '.avi', '.mkv', '.webm'}
    if path.suffix.lower() not in allowed_extensions:
        raise ValueError(
            f"Unsupported file type: {path.suffix}. "
            f"Allowed: {', '.join(allowed_extensions)}"
        )

    return path
```

### Subprocess Command Injection Prevention

```python
import subprocess
from pathlib import Path

def safe_ffmpeg_call(input_path: Path, output_path: Path) -> None:
    """Safely call FFmpeg with validated paths.

    NEVER use shell=True - it allows command injection!
    """
    # ❌ UNSAFE: Command injection vulnerability
    # os.system(f'ffmpeg -i {input_path} {output_path}')

    # ✅ SAFE: List arguments, no shell expansion
    subprocess.run(
        [
            'ffmpeg',
            '-i', str(input_path),
            '-vn',  # No video
            '-acodec', 'pcm_s16le',
            '-ar', '16000',
            str(output_path)
        ],
        capture_output=True,
        check=True,
        timeout=300,
        # shell=False is default - never set shell=True!
    )
```

## Dependency Security

### Regular Security Audits

```bash
# Check for known vulnerabilities in dependencies
pip install safety
safety check --json

# Or use pip-audit
pip install pip-audit
pip-audit
```

### Keep Dependencies Updated

```bash
# Update dependencies
pip list --outdated

# Update specific package
pip install --upgrade package-name

# Regenerate requirements.txt
pip freeze > requirements.txt
```

### Pinning Versions

```text
# requirements.txt - pin major versions for security
openai>=1.0.0,<2.0.0
anthropic>=0.18.0,<1.0.0
moviepy>=1.0.3,<2.0.0
# ... but allow patch updates for security fixes
```

## Rate Limiting and API Abuse Prevention

### Respect API Rate Limits

```python
import time
from typing import Callable, TypeVar, Any

T = TypeVar('T')

def retry_with_exponential_backoff(
    func: Callable[..., T],
    max_retries: int = 3,
    initial_delay: float = 1.0
) -> T:
    """Retry function with exponential backoff for rate limits.

    Args:
        func: Function to retry
        max_retries: Maximum number of retries
        initial_delay: Initial delay in seconds

    Returns:
        Result of successful function call

    Raises:
        Exception: If all retries exhausted
    """
    delay = initial_delay

    for attempt in range(max_retries):
        try:
            return func()
        except Exception as e:
            if 'rate_limit' in str(e).lower() and attempt < max_retries - 1:
                print(f"Rate limit hit, retrying in {delay}s...")
                time.sleep(delay)
                delay *= 2  # Exponential backoff
            else:
                raise

    raise Exception(f"Failed after {max_retries} retries")
```

### Cost Monitoring

```python
def estimate_api_costs(video_duration_minutes: float) -> dict:
    """Estimate API costs for processing a video.

    Args:
        video_duration_minutes: Video duration in minutes

    Returns:
        Dictionary of estimated costs per service
    """
    costs = {
        'whisper': video_duration_minutes * 0.006,  # $0.006/min
        'gpt4': 0.30,  # Roughly $0.30 per video
        'elevenlabs': (video_duration_minutes * 0.3),  # $0.30 per min of narration
    }
    costs['total'] = sum(costs.values())

    return costs
```

## Security Checklist

Before deploying or sharing code:

- [ ] No API keys in code or git history
- [ ] `.env` file is gitignored
- [ ] `.env.example` template provided
- [ ] Required environment variables validated at startup
- [ ] No secrets logged to console or files
- [ ] User video content handled privately
- [ ] Temporary files cleaned up after processing
- [ ] Subprocess calls use list args (not shell=True)
- [ ] File paths validated and sanitized
- [ ] Dependencies checked for vulnerabilities
- [ ] GitHub Actions secrets configured (if applicable)
- [ ] AWS SSM parameters configured (if using AWS)

## References

**Related Steering Files:**
- [coding-standards.md](./coding-standards.md) - Input validation, subprocess security
- [cicd-workflow.md](./cicd-workflow.md) - GitHub Actions secrets, CI security
- [data-conventions.md](./data-conventions.md) - Environment variable loading
- [ai-integration.md](./ai-integration.md) - API key usage with AI services

**Project Files:**
- `run.sh` - AWS SSM integration implementation (lines 17-48)
- `.env.example` - Template for environment variables
- `.gitignore` - Ensures `.env` is not committed

**External Resources:**
- [OWASP Top 10](https://owasp.org/www-project-top-ten/) - Common security vulnerabilities
- [AWS SSM Parameter Store](https://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-parameter-store.html)
- [GitHub Actions Secrets](https://docs.github.com/en/actions/security-guides/encrypted-secrets)
