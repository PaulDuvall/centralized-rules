---
inclusion: fileMatch
fileMatchPattern: '**/test_*.py'
---

# 🎬 Testing: Fixtures and Test Data

> **Purpose:** Creating test videos, audio files, and managing pytest fixtures
>
> **When to use:** Need sample media files for tests, want to share fixtures across test files
>
> **See also:** [testing-overview.md](./testing-overview.md) | [testing-pipeline.md](./testing-pipeline.md)

## Test Data Philosophy

- **Use minimal test media** - 1-5 seconds duration, < 1MB file size
- **Generate dynamically** - Create fixtures in tests using FFmpeg
- **Share via conftest.py** - Reusable fixtures for all test files
- **Use tmp_path** - Pytest's built-in temporary directory fixture

---

## Creating Test Videos with FFmpeg

### Minimal 1-Second Test Video

```python
import pytest
import subprocess
from pathlib import Path

@pytest.fixture
def minimal_test_video(tmp_path: Path) -> Path:
    """Create a minimal 1-second test video using FFmpeg.

    Creates a 1920x1080 video with:
    - Duration: 1 second
    - FPS: 30
    - Codec: H.264
    - Size: ~50KB
    - Audio: 440Hz sine wave
    """
    video_path = tmp_path / "test_video.mp4"

    cmd = [
        "ffmpeg",
        "-f", "lavfi",
        "-i", "testsrc=duration=1:size=1920x1080:rate=30",
        "-f", "lavfi",
        "-i", "sine=frequency=440:duration=1",
        "-c:v", "libx264",
        "-preset", "ultrafast",
        "-c:a", "aac",
        "-t", "1",
        str(video_path)
    ]

    subprocess.run(cmd, capture_output=True, check=True)
    assert video_path.exists()
    return video_path
```

### Test Video with Different Resolutions

```python
@pytest.fixture
def hd_test_video(tmp_path: Path) -> Path:
    """Create 720p test video."""
    video_path = tmp_path / "hd_video.mp4"

    cmd = [
        "ffmpeg",
        "-f", "lavfi",
        "-i", "testsrc=duration=2:size=1280x720:rate=30",
        "-f", "lavfi",
        "-i", "sine=frequency=440:duration=2",
        "-c:v", "libx264",
        "-preset", "ultrafast",
        "-c:a", "aac",
        "-t", "2",
        str(video_path)
    ]

    subprocess.run(cmd, capture_output=True, check=True)
    return video_path

@pytest.fixture
def sd_test_video(tmp_path: Path) -> Path:
    """Create 480p test video."""
    video_path = tmp_path / "sd_video.mp4"

    cmd = [
        "ffmpeg",
        "-f", "lavfi",
        "-i", "testsrc=duration=1:size=640x480:rate=24",
        "-f", "lavfi",
        "-i", "sine=frequency=440:duration=1",
        "-c:v", "libx264",
        "-preset", "ultrafast",
        "-c:a", "aac",
        "-t", "1",
        str(video_path)
    ]

    subprocess.run(cmd, capture_output=True, check=True)
    return video_path
```

### Variable Frame Rate (VFR) Video

```python
@pytest.fixture
def variable_frame_rate_video(tmp_path: Path) -> Path:
    """Create a VFR video for CFR conversion testing."""
    video_path = tmp_path / "vfr_video.mp4"

    cmd = [
        "ffmpeg",
        "-f", "lavfi",
        "-i", "testsrc=duration=2:size=1280x720:rate=30",
        "-vf", "setpts='if(lt(N,30),PTS,PTS+0.5)'",  # Create VFR
        "-c:v", "libx264",
        "-t", "2",
        str(video_path)
    ]

    subprocess.run(cmd, capture_output=True, check=True)
    return video_path
```

---

## Creating Test Audio Files

### Minimal Test Audio (1 Second)

```python
@pytest.fixture
def minimal_test_audio(tmp_path: Path) -> Path:
    """Create a minimal test audio file (1 second, 440Hz tone)."""
    audio_path = tmp_path / "test_audio.mp3"

    cmd = [
        "ffmpeg",
        "-f", "lavfi",
        "-i", "sine=frequency=440:duration=1",
        "-c:a", "libmp3lame",
        "-b:a", "128k",
        str(audio_path)
    ]

    subprocess.run(cmd, capture_output=True, check=True)
    assert audio_path.exists()
    return audio_path
```

### Audio with Speech-Like Patterns

```python
@pytest.fixture
def test_audio_with_speech_pattern(tmp_path: Path) -> Path:
    """Create test audio with synthesized speech pattern.

    Uses FFmpeg's sine wave to create speech-like patterns
    for testing transcription logic (without actual speech).
    """
    audio_path = tmp_path / "speech_pattern.wav"

    cmd = [
        "ffmpeg",
        "-f", "lavfi",
        "-i", "sine=frequency=200:duration=0.5,sine=frequency=400:duration=0.5",
        "-c:a", "pcm_s16le",
        "-ar", "16000",  # 16kHz (Whisper input rate)
        str(audio_path)
    ]

    subprocess.run(cmd, capture_output=True, check=True)
    return audio_path
```

### WAV Audio for Precise Testing

```python
@pytest.fixture
def wav_test_audio(tmp_path: Path) -> Path:
    """Create uncompressed WAV audio for precise testing."""
    audio_path = tmp_path / "test_audio.wav"

    cmd = [
        "ffmpeg",
        "-f", "lavfi",
        "-i", "sine=frequency=440:duration=2",
        "-c:a", "pcm_s16le",
        "-ar", "44100",  # CD quality sample rate
        str(audio_path)
    ]

    subprocess.run(cmd, capture_output=True, check=True)
    return audio_path
```

---

## pytest Fixture Patterns

### Basic Fixture Structure

```python
import pytest
from pathlib import Path

@pytest.fixture
def sample_manifest() -> dict:
    """Provide a minimal valid manifest for testing."""
    return {
        'video_path': '/path/to/video.mp4',
        'metadata': {
            'duration': 30.0,
            'fps': 30.0
        },
        'actions': [
            {
                'type': 'keep',
                'start_time': 0.0,
                'end_time': 10.0,
                'text': 'Important content'
            }
        ]
    }

@pytest.fixture
def sample_video_path(tmp_path: Path) -> Path:
    """Provide path to a sample video (may not exist, for path testing)."""
    return tmp_path / "sample_video.mp4"
```

### Fixture Scopes

```python
@pytest.fixture(scope="session")
def shared_test_video(tmp_path_factory):
    """Create video once for entire test session.

    Use session scope for expensive fixtures that don't need to be
    recreated for each test.
    """
    tmp_path = tmp_path_factory.mktemp("videos")
    video_path = tmp_path / "shared_video.mp4"

    # Create video...
    cmd = ["ffmpeg", "-f", "lavfi", "-i", "testsrc=duration=5:size=1920x1080:rate=30",
           "-c:v", "libx264", "-preset", "ultrafast", "-t", "5", str(video_path)]
    subprocess.run(cmd, capture_output=True, check=True)

    return video_path


@pytest.fixture(scope="function")
def per_test_video(tmp_path: Path):
    """Create new video for each test (default scope)."""
    video_path = tmp_path / "test_video.mp4"
    # Create video...
    return video_path
```

### Autouse Fixtures

```python
@pytest.fixture(autouse=True)
def setup_and_teardown():
    """Setup before and teardown after each test automatically."""
    # Setup code
    print("\nSetting up test environment")

    yield  # Test runs here

    # Teardown code
    print("Cleaning up test environment")


@pytest.fixture(autouse=True)
def mock_expensive_operations():
    """Automatically mock expensive operations for all tests."""
    with patch('subprocess.run') as mock_run:
        mock_run.return_value.returncode = 0
        yield mock_run
```

### Parametrized Fixtures

```python
@pytest.fixture(params=["elevenlabs", "openai"])
def tts_provider(request):
    """Test with multiple TTS providers."""
    return request.param

def test_voice_generation_all_providers(tts_provider):
    """Test runs once for each provider."""
    from src.phase3_voice import VoiceGenerator

    vg = VoiceGenerator(provider=tts_provider)
    # Test implementation...


@pytest.fixture(params=[
    (1920, 1080, 30),  # Full HD 30fps
    (1280, 720, 60),   # HD 60fps
    (640, 480, 24)     # SD 24fps
])
def video_resolution(request):
    """Test with multiple video resolutions."""
    width, height, fps = request.param
    return {"width": width, "height": height, "fps": fps}
```

---

## Sharing Fixtures with conftest.py

### Creating conftest.py

Create `tests/conftest.py` to share fixtures across all test files:

```python
"""Shared pytest fixtures for all tests."""

import pytest
from pathlib import Path
from unittest.mock import patch, MagicMock
import subprocess
import json


@pytest.fixture(scope="session")
def fixtures_dir() -> Path:
    """Get the fixtures directory."""
    return Path(__file__).parent / "fixtures"


@pytest.fixture
def minimal_test_video(tmp_path: Path) -> Path:
    """Create a minimal 1-second test video."""
    video_path = tmp_path / "test_video.mp4"
    cmd = [
        "ffmpeg", "-f", "lavfi",
        "-i", "testsrc=duration=1:size=1920x1080:rate=30",
        "-f", "lavfi", "-i", "sine=frequency=440:duration=1",
        "-c:v", "libx264", "-preset", "ultrafast",
        "-c:a", "aac", "-t", "1", str(video_path)
    ]
    subprocess.run(cmd, capture_output=True, check=True)
    return video_path


@pytest.fixture
def mock_whisper():
    """Mock Whisper for all tests."""
    with patch('whisper.load_model') as mock_model:
        mock_instance = MagicMock()
        mock_instance.transcribe.return_value = {
            'segments': [
                {'start': 0.0, 'end': 5.0, 'text': 'Test transcription'}
            ]
        }
        mock_model.return_value = mock_instance
        yield mock_model


@pytest.fixture
def mock_openai():
    """Mock OpenAI API for all tests."""
    with patch('openai.chat.completions.create') as mock_chat:
        mock_response = MagicMock()
        mock_response.choices[0].message.content = json.dumps({
            'actions': [{'type': 'keep', 'start_time': 0.0, 'end_time': 5.0}]
        })
        mock_chat.return_value = mock_response
        yield mock_chat


@pytest.fixture
def mock_elevenlabs():
    """Mock ElevenLabs for all tests."""
    with patch('elevenlabs.generate') as mock_gen:
        mock_gen.return_value = b'\x00\x01' * 1000
        yield mock_gen


@pytest.fixture
def sample_transcript():
    """Provide sample transcript segments for testing."""
    from src.models import TranscriptSegment
    return [
        TranscriptSegment(id=0, start=0.0, end=5.0, text="Hello world"),
        TranscriptSegment(id=1, start=5.0, end=10.0, text="Installing packages"),
        TranscriptSegment(id=2, start=10.0, end=15.0, text="Important content")
    ]
```

### Using Shared Fixtures

Any test file can now use these fixtures:

```python
# tests/test_phase1_ingest.py

def test_phase1_with_shared_fixtures(minimal_test_video, mock_whisper):
    """Test uses fixtures from conftest.py automatically."""
    from src.phase1_ingest import Phase1Processor

    processor = Phase1Processor()
    # Test implementation...
```

---

## Static Fixture Files

### When to Use Static Fixtures

Use static files when:
- Fixture generation is expensive
- Need specific video characteristics (codec, format)
- Testing file parsing/validation (not generation)

### Creating Static Fixtures Directory

```bash
# Create fixtures directory
mkdir -p tests/fixtures

# Generate a 1-second test video (run once)
ffmpeg -f lavfi -i testsrc=duration=1:size=1920x1080:rate=30 \
       -f lavfi -i sine=frequency=440:duration=1 \
       -c:v libx264 -preset ultrafast -c:a aac -t 1 \
       tests/fixtures/sample_1sec.mp4

# Generate a 5-second test video for integration tests
ffmpeg -f lavfi -i testsrc=duration=5:size=1920x1080:rate=30 \
       -f lavfi -i sine=frequency=440:duration=5 \
       -c:v libx264 -preset ultrafast -c:a aac -t 5 \
       tests/fixtures/sample_5sec.mp4

# Generate test audio
ffmpeg -f lavfi -i sine=frequency=440:duration=2 \
       -c:a libmp3lame -b:a 128k \
       tests/fixtures/sample_audio.mp3
```

### Using Static Fixtures

```python
import pytest
from pathlib import Path
import shutil

@pytest.fixture(scope="session")
def fixtures_dir() -> Path:
    """Get the fixtures directory path."""
    return Path(__file__).parent / "fixtures"


@pytest.fixture
def sample_video_file(fixtures_dir: Path, tmp_path: Path) -> Path:
    """Copy sample video fixture to temp directory.

    This allows tests to modify the video without affecting the original.
    """
    source = fixtures_dir / "sample_1sec.mp4"
    if not source.exists():
        pytest.skip(f"Fixture file not found: {source}")

    dest = tmp_path / "sample_video.mp4"
    shutil.copy(source, dest)
    return dest


def test_with_static_fixture(sample_video_file):
    """Test using static fixture file."""
    assert sample_video_file.exists()
    # Test video processing...
```

---

## Using tmp_path for Temporary Files

### tmp_path Fixture (Built-in pytest)

```python
def test_with_tmp_path(tmp_path):
    """pytest provides tmp_path fixture automatically.

    tmp_path is a pathlib.Path object pointing to a temporary directory
    that is cleaned up after the test.
    """
    # Create test file in temp directory
    test_file = tmp_path / "test.txt"
    test_file.write_text("test content")

    assert test_file.exists()
    assert test_file.read_text() == "test content"

    # tmp_path is automatically cleaned up after test


def test_video_output(tmp_path):
    """Use tmp_path for video output paths."""
    from src.phase4_assembly import VideoAssembler

    output_path = tmp_path / "output_video.mp4"
    assembler = VideoAssembler("input.mp4")
    # Generate video to tmp_path...

    assert output_path.exists()
```

### tmp_path_factory (Session-scoped)

```python
@pytest.fixture(scope="session")
def session_temp_dir(tmp_path_factory):
    """Create temp directory that persists across test session."""
    return tmp_path_factory.mktemp("session_data")


def test_using_session_temp(session_temp_dir):
    """Multiple tests can share this directory."""
    test_file = session_temp_dir / "shared.txt"
    test_file.write_text("shared data")
```

---

## Testing Without External APIs

### Skipping Tests When API Keys Missing

```python
import os
import pytest

@pytest.mark.skipif(
    not os.getenv("OPENAI_API_KEY"),
    reason="No OpenAI API key available"
)
def test_real_transcription(minimal_test_audio):
    """Integration test with real Whisper API."""
    from src.phase1_ingest import WhisperTranscriber

    transcriber = WhisperTranscriber("base")
    segments = transcriber.transcribe(str(minimal_test_audio))
    assert len(segments) >= 0


@pytest.mark.skipif(
    not all([
        os.getenv("OPENAI_API_KEY"),
        os.getenv("ELEVENLABS_API_KEY")
    ]),
    reason="Missing required API keys"
)
def test_full_pipeline_real_apis(minimal_test_video):
    """Test requiring multiple API keys."""
    # Test implementation...
```

### Conditional Fixtures

```python
@pytest.fixture
def whisper_client():
    """Provide real or mocked Whisper based on API key availability."""
    if os.getenv("OPENAI_API_KEY"):
        # Return real Whisper client
        import whisper
        return whisper.load_model("base")
    else:
        # Return mock
        mock = MagicMock()
        mock.transcribe.return_value = {'segments': []}
        return mock
```

---

## Best Practices

### ✅ DO:

- Generate test videos dynamically with FFmpeg
- Use minimal durations (1-5 seconds)
- Share fixtures via `conftest.py`
- Use `tmp_path` for temporary files
- Clean up test data automatically
- Skip expensive tests when API keys unavailable

### ❌ DON'T:

- Commit large video files to git
- Use real user videos in tests
- Leave test files on disk after tests
- Generate fixtures that take > 1 second to create
- Make integration tests depend on network resources

---

## References

- **pytest fixtures documentation**: https://docs.pytest.org/en/stable/fixture.html
- **FFmpeg test sources**: https://ffmpeg.org/ffmpeg-filters.html#testsrc
- **Related guides**: [testing-overview.md](./testing-overview.md), [testing-pipeline.md](./testing-pipeline.md)

---

**Last Updated:** 2025-12-10
**Python Version:** 3.11+
**Dependencies:** pytest, FFmpeg (for fixture generation)
