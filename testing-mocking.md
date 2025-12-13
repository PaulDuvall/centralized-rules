---
inclusion: fileMatch
fileMatchPattern: '**/test_*.py'
---

# 🎭 Testing: Mocking External Dependencies

> **Purpose:** Comprehensive guide to mocking FFmpeg, MoviePy, Whisper, LLMs, and TTS APIs
>
> **When to use:** Writing unit tests that need to isolate code from external dependencies
>
> **See also:** [testing-overview.md](./testing-overview.md) | [testing-pipeline.md](./testing-pipeline.md)

## When to Mock

### Always Mock These in Unit Tests:

- ✅ External APIs (OpenAI, Anthropic, ElevenLabs)
- ✅ FFmpeg subprocess calls
- ✅ Whisper transcription (slow, requires API key)
- ✅ MoviePy video operations (for fast unit tests)
- ✅ Time-dependent functions (time.time(), datetime.now())

### Use Real Operations in Integration Tests:

- Use real FFmpeg with small test videos (1-5 seconds)
- Use real file system operations with `tmp_path` fixture
- Optionally use real APIs if keys available (mark with `@pytest.mark.skipif`)

---

## Basic Mocking Patterns

### Using unittest.mock

```python
from unittest.mock import Mock, patch, MagicMock
import pytest

# Mock function return values
@patch('src.phase3_voice.elevenlabs.generate')
def test_voice_generation(mock_generate):
    mock_generate.return_value = b'fake_audio_data'
    # Test code...

# Mock subprocess calls
@patch('subprocess.run')
def test_ffmpeg_call(mock_run):
    mock_run.return_value = Mock(returncode=0, stdout=b'', stderr=b'')
    # Test FFmpeg operation...

# Use pytest fixtures for common mocks
@pytest.fixture
def mock_whisper():
    with patch('whisper.load_model') as mock_model:
        mock_model.return_value.transcribe.return_value = {
            'segments': [{'text': 'test', 'start': 0.0, 'end': 1.0}]
        }
        yield mock_model

def test_transcription(mock_whisper):
    # Test code that uses Whisper...
    pass
```

---

## FFmpeg and ffmpeg-python Mocking

### Mocking ffmpeg-python Library

```python
import pytest
from unittest.mock import patch, MagicMock

@pytest.fixture
def mock_ffmpeg():
    """Mock ffmpeg-python library for audio extraction tests."""
    with patch('ffmpeg.input') as mock_input:
        # Create mock chain for ffmpeg operations
        mock_stream = MagicMock()
        mock_output = MagicMock()
        mock_stream.output.return_value = mock_output
        mock_output.overwrite_output.return_value = mock_output
        mock_output.run.return_value = None
        mock_input.return_value = mock_stream
        yield mock_input

def test_audio_extraction(mock_ffmpeg):
    """Test audio extraction with mocked FFmpeg."""
    from src.phase1_ingest import AudioExtractor

    extractor = AudioExtractor()
    result = extractor.extract("input.mp4", "output.mp3")

    assert result == "output.mp3"
    mock_ffmpeg.assert_called_once_with("input.mp4")
```

### Mocking FFmpeg Subprocess Calls

```python
import pytest
from unittest.mock import patch, Mock
import subprocess

@pytest.fixture
def mock_ffmpeg_subprocess():
    """Mock subprocess.run for FFmpeg command line calls."""
    with patch('subprocess.run') as mock_run:
        # Simulate successful FFmpeg execution
        mock_run.return_value = Mock(
            returncode=0,
            stdout=b'',
            stderr=b'ffmpeg version 4.4.2'
        )
        yield mock_run

def test_cfr_conversion(mock_ffmpeg_subprocess):
    """Test CFR conversion with mocked subprocess."""
    from src.phase4_assembly import convert_to_cfr

    result = convert_to_cfr("input.mp4")

    # Verify FFmpeg was called with correct arguments
    mock_ffmpeg_subprocess.assert_called_once()
    args = mock_ffmpeg_subprocess.call_args[0][0]
    assert 'ffmpeg' in args
    assert '-r' in args  # Frame rate flag
```

### Mocking ffprobe (Video Info Extraction)

```python
import pytest
from unittest.mock import patch
import json

@pytest.fixture
def mock_ffprobe():
    """Mock ffprobe for video metadata extraction."""
    with patch('subprocess.run') as mock_run:
        # Simulate ffprobe JSON output
        video_info = {
            'streams': [
                {
                    'codec_type': 'video',
                    'r_frame_rate': '30/1',
                    'width': 1920,
                    'height': 1080,
                    'codec_name': 'h264'
                },
                {
                    'codec_type': 'audio',
                    'sample_rate': '48000',
                    'codec_name': 'aac'
                }
            ],
            'format': {
                'duration': '10.0',
                'bit_rate': '5000000'
            }
        }
        mock_run.return_value.stdout = json.dumps(video_info).encode()
        mock_run.return_value.returncode = 0
        yield mock_run

def test_video_info_extraction(mock_ffprobe):
    """Test extracting video metadata."""
    from src.ffmpeg_utils import get_video_info

    info = get_video_info("test.mp4")

    assert info['width'] == 1920
    assert info['fps'] == 30.0
    mock_ffprobe.assert_called_once()
```

---

## MoviePy Mocking

### Mocking VideoFileClip

```python
import pytest
from unittest.mock import Mock, patch, MagicMock

@pytest.fixture
def mock_video_clip():
    """Mock MoviePy VideoFileClip for video assembly tests."""
    with patch('moviepy.editor.VideoFileClip') as mock_clip:
        # Create mock video clip with necessary attributes
        clip_instance = MagicMock()
        clip_instance.duration = 10.0
        clip_instance.fps = 30.0
        clip_instance.size = (1920, 1080)

        # Mock subclipping method
        clip_instance.subclipped.return_value = clip_instance
        clip_instance.subclip.return_value = clip_instance

        # Mock speed adjustment
        clip_instance.fx.return_value = clip_instance

        # Mock audio operations
        clip_instance.audio = MagicMock()
        clip_instance.set_audio.return_value = clip_instance

        mock_clip.return_value = clip_instance
        yield mock_clip

def test_video_clip_creation(mock_video_clip):
    """Test video clip processing with mocked MoviePy."""
    from moviepy.editor import VideoFileClip

    clip = VideoFileClip("test.mp4")

    assert clip.duration == 10.0
    assert clip.fps == 30.0
    assert clip.size == (1920, 1080)
```

### Mocking AudioFileClip

```python
@pytest.fixture
def mock_audio_clip():
    """Mock MoviePy AudioFileClip."""
    with patch('moviepy.editor.AudioFileClip') as mock_audio:
        audio_instance = MagicMock()
        audio_instance.duration = 5.0
        mock_audio.return_value = audio_instance
        yield mock_audio

def test_audio_clip_creation(mock_audio_clip):
    """Test audio clip with mocked MoviePy."""
    from moviepy.editor import AudioFileClip

    audio = AudioFileClip("test.mp3")
    assert audio.duration == 5.0
```

### Mocking Video Concatenation

```python
@pytest.fixture
def mock_moviepy_concat():
    """Mock MoviePy concatenation functions."""
    with patch('moviepy.editor.concatenate_videoclips') as mock_concat, \
         patch('moviepy.editor.VideoFileClip') as mock_video:

        # Setup video clip mock
        clip = MagicMock()
        clip.duration = 5.0
        clip.write_videofile = MagicMock()
        mock_video.return_value = clip

        # Setup concatenation result
        final_clip = MagicMock()
        final_clip.duration = 15.0
        final_clip.write_videofile = MagicMock()
        mock_concat.return_value = final_clip

        yield {'video': mock_video, 'concat': mock_concat}

def test_video_concatenation(mock_moviepy_concat):
    """Test concatenating multiple clips."""
    from moviepy.editor import VideoFileClip, concatenate_videoclips

    clips = [VideoFileClip("vid1.mp4"), VideoFileClip("vid2.mp4")]
    final = concatenate_videoclips(clips)

    assert final.duration == 15.0
```

---

## Whisper (Transcription) Mocking

### Basic Whisper Mock

```python
import pytest
from unittest.mock import patch, MagicMock

@pytest.fixture
def mock_whisper():
    """Mock Whisper transcription model."""
    with patch('whisper.load_model') as mock_model:
        # Create mock model instance
        model_instance = MagicMock()

        # Mock transcribe method with realistic output
        model_instance.transcribe.return_value = {
            'text': 'This is a test transcription.',
            'segments': [
                {
                    'id': 0,
                    'start': 0.0,
                    'end': 2.5,
                    'text': 'This is a test',
                    'tokens': [50364, 50365, 50366],
                    'temperature': 0.0
                },
                {
                    'id': 1,
                    'start': 2.5,
                    'end': 4.0,
                    'text': 'transcription.',
                    'tokens': [50367, 50368],
                    'temperature': 0.0
                }
            ],
            'language': 'en'
        }

        mock_model.return_value = model_instance
        yield mock_model

def test_whisper_transcription(mock_whisper):
    """Test transcription with mocked Whisper."""
    from src.phase1_ingest import WhisperTranscriber

    transcriber = WhisperTranscriber(model="base")
    result = transcriber.transcribe("test_audio.mp3")

    assert len(result['segments']) == 2
    assert result['language'] == 'en'
    mock_whisper.assert_called_once_with("base")
```

### Whisper with Multiple Segments

```python
@pytest.fixture
def mock_whisper_long_transcript():
    """Mock Whisper with longer transcript for testing edit decisions."""
    with patch('whisper.load_model') as mock_model:
        model_instance = MagicMock()
        model_instance.transcribe.return_value = {
            'segments': [
                {'id': 0, 'start': 0.0, 'end': 5.0, 'text': 'Installing dependencies'},
                {'id': 1, 'start': 5.0, 'end': 10.0, 'text': 'Waiting for installation'},
                {'id': 2, 'start': 10.0, 'end': 15.0, 'text': 'This is the important part'},
                {'id': 3, 'start': 15.0, 'end': 20.0, 'text': 'More boring waiting'},
                {'id': 4, 'start': 20.0, 'end': 25.0, 'text': 'Final important content'}
            ]
        }
        mock_model.return_value = model_instance
        yield mock_model
```

---

## LLM (OpenAI/Anthropic) Mocking

### Mocking OpenAI GPT-4

```python
import pytest
from unittest.mock import patch, MagicMock
import json

@pytest.fixture
def mock_openai_gpt():
    """Mock OpenAI GPT-4 API for director agent tests."""
    with patch('openai.chat.completions.create') as mock_chat:
        # Create mock response
        mock_response = MagicMock()

        # Mock edit plan JSON response
        edit_plan = {
            'actions': [
                {
                    'type': 'keep',
                    'start_time': 0.0,
                    'end_time': 5.0,
                    'text': 'Keep this important part',
                    'speed': 1.0
                },
                {
                    'type': 'cut',
                    'start_time': 5.0,
                    'end_time': 10.0,
                    'reason': 'Boring installation'
                },
                {
                    'type': 'speedup',
                    'start_time': 10.0,
                    'end_time': 15.0,
                    'speed': 3.0,
                    'text': 'Speed through this'
                }
            ]
        }

        mock_response.choices[0].message.content = json.dumps(edit_plan)
        mock_chat.return_value = mock_response
        yield mock_chat

def test_openai_edit_plan_generation(mock_openai_gpt):
    """Test edit plan generation with mocked GPT-4."""
    from src.phase2_director import DirectorAgent
    from src.models import TranscriptSegment

    segments = [
        TranscriptSegment(id=0, start=0.0, end=5.0, text="Important content"),
        TranscriptSegment(id=1, start=5.0, end=10.0, text="Installing..."),
    ]

    director = DirectorAgent(provider="openai")
    actions = director.generate_edit_plan(segments, "test.mp4")

    assert len(actions) == 3
    assert actions[0].type == 'keep'
    assert actions[1].type == 'cut'
    mock_openai_gpt.assert_called_once()
```

### Mocking Anthropic Claude

```python
@pytest.fixture
def mock_anthropic_claude():
    """Mock Anthropic Claude API for director agent tests."""
    with patch('anthropic.Anthropic') as mock_anthropic:
        # Create mock client
        client_instance = MagicMock()

        # Mock messages.create method
        mock_message = MagicMock()
        edit_plan = {
            'actions': [
                {'type': 'keep', 'start_time': 0.0, 'end_time': 5.0, 'text': 'Keep this'}
            ]
        }
        mock_message.content[0].text = json.dumps(edit_plan)
        client_instance.messages.create.return_value = mock_message

        mock_anthropic.return_value = client_instance
        yield mock_anthropic

def test_anthropic_edit_plan_generation(mock_anthropic_claude):
    """Test edit plan generation with mocked Claude."""
    from src.phase2_director import DirectorAgent

    director = DirectorAgent(provider="anthropic")
    # Test implementation...
```

---

## TTS (Text-to-Speech) Mocking

### Mocking ElevenLabs

```python
import pytest
from unittest.mock import patch, MagicMock

@pytest.fixture
def mock_elevenlabs():
    """Mock ElevenLabs API for voice generation tests."""
    with patch('elevenlabs.generate') as mock_gen:
        # Return fake audio bytes
        mock_gen.return_value = b'\x00\x01\x02\x03' * 1000
        yield mock_gen

def test_elevenlabs_voice_generation(mock_elevenlabs, tmp_path):
    """Test voice generation with ElevenLabs mock."""
    from src.phase3_voice import VoiceGenerator

    vg = VoiceGenerator(provider="elevenlabs")
    output_path = tmp_path / "test_audio.mp3"

    duration = vg.generate_audio("Test narration", str(output_path))

    assert output_path.exists()
    assert duration > 0
    mock_elevenlabs.assert_called_once()
```

### Mocking OpenAI TTS

```python
@pytest.fixture
def mock_openai_tts():
    """Mock OpenAI TTS API."""
    with patch('openai.audio.speech.create') as mock_tts:
        # Create mock response with audio content
        mock_response = MagicMock()
        mock_response.content = b'\x00\x01\x02\x03' * 1000
        mock_tts.return_value = mock_response
        yield mock_tts

def test_openai_tts_generation(mock_openai_tts, tmp_path):
    """Test voice generation with OpenAI TTS."""
    from src.phase3_voice import VoiceGenerator

    vg = VoiceGenerator(provider="openai")
    output_path = tmp_path / "voice.mp3"

    vg.generate_audio("Test text", str(output_path))

    assert output_path.exists()
    mock_openai_tts.assert_called_once()
```

---

## Combined Phase Mocking

### Phase 1 - Complete Mock Setup

```python
@pytest.fixture
def mock_phase1_dependencies():
    """Mock all Phase 1 external dependencies."""
    with patch('ffmpeg.input') as mock_ffmpeg, \
         patch('whisper.load_model') as mock_whisper:

        # Setup FFmpeg mock
        mock_stream = MagicMock()
        mock_stream.output().overwrite_output().run.return_value = None
        mock_ffmpeg.return_value = mock_stream

        # Setup Whisper mock
        mock_model = MagicMock()
        mock_model.transcribe.return_value = {
            'segments': [
                {'start': 0.0, 'end': 5.0, 'text': 'Test segment'}
            ]
        }
        mock_whisper.return_value = mock_model

        yield {'ffmpeg': mock_ffmpeg, 'whisper': mock_whisper}

def test_phase1_processor(mock_phase1_dependencies):
    """Test Phase 1 processor with all dependencies mocked."""
    from src.phase1_ingest import Phase1Processor

    processor = Phase1Processor(whisper_model="base")
    audio_path, segments = processor.process("input.mp4")

    assert len(segments) == 1
    assert segments[0].text == 'Test segment'
```

### Phase 3 - Voice Generation Complete Mock

```python
@pytest.fixture
def mock_phase3_dependencies():
    """Mock all Phase 3 dependencies."""
    with patch('elevenlabs.generate') as mock_elevenlabs, \
         patch('openai.audio.speech.create') as mock_openai_tts:

        # Mock ElevenLabs
        mock_elevenlabs.return_value = b'\x00\x01' * 1000

        # Mock OpenAI TTS
        mock_response = MagicMock()
        mock_response.content = b'\x00\x01' * 1000
        mock_openai_tts.return_value = mock_response

        yield {
            'elevenlabs': mock_elevenlabs,
            'openai_tts': mock_openai_tts
        }
```

### Phase 4 - Video Assembly Complete Mock

```python
@pytest.fixture
def mock_phase4_dependencies():
    """Mock all Phase 4 dependencies."""
    with patch('moviepy.editor.VideoFileClip') as mock_video, \
         patch('moviepy.editor.AudioFileClip') as mock_audio, \
         patch('moviepy.editor.concatenate_videoclips') as mock_concat, \
         patch('subprocess.run') as mock_subprocess:

        # Setup video clip mock
        video_clip = MagicMock()
        video_clip.duration = 30.0
        video_clip.fps = 30.0
        video_clip.subclip.return_value = video_clip
        mock_video.return_value = video_clip

        # Setup audio clip mock
        audio_clip = MagicMock()
        audio_clip.duration = 5.0
        mock_audio.return_value = audio_clip

        # Setup concatenation mock
        final_clip = MagicMock()
        final_clip.write_videofile = MagicMock()
        mock_concat.return_value = final_clip

        # Mock FFmpeg subprocess (for CFR conversion)
        mock_subprocess.return_value.returncode = 0

        yield {
            'video': mock_video,
            'audio': mock_audio,
            'concat': mock_concat,
            'subprocess': mock_subprocess
        }
```

---

## Best Practices

### ✅ DO:

- Mock at the boundary (external APIs, subprocess calls)
- Use pytest fixtures for reusable mocks
- Verify mocks were called (`mock.assert_called_once()`)
- Return realistic mock data (JSON structures, audio bytes)
- Test error paths by making mocks raise exceptions

### ❌ DON'T:

- Mock internal functions (test real implementation)
- Over-mock (makes tests brittle and hard to maintain)
- Forget to verify mock calls (could be passing for wrong reasons)
- Use mocks in integration tests (defeats the purpose)

---

## References

- **unittest.mock documentation**: https://docs.python.org/3/library/unittest.mock.html
- **pytest-mock plugin**: https://pytest-mock.readthedocs.io/
- **Related guides**: [testing-pipeline.md](./testing-pipeline.md), [testing-overview.md](./testing-overview.md)

---

**Last Updated:** 2025-12-10
**Python Version:** 3.11+
