---
inclusion: fileMatch
fileMatchPattern: '**/test_*.py'
---

# 🔧 Testing: 4-Phase Pipeline

> **Purpose:** Testing strategies for Phase 1-4 video processing pipeline
>
> **When to use:** Writing tests for pipeline components, phase processors, or end-to-end workflows
>
> **See also:** [testing-mocking.md](./testing-mocking.md) | [testing-fixtures.md](./testing-fixtures.md)

## Pipeline Architecture Recap

The screencast optimizer uses a **4-phase metadata-driven pipeline**:

1. **Phase 1 (Ingest)**: Extract audio → Whisper transcription with timestamps
2. **Phase 2 (Director)**: LLM analyzes transcript → generates edit decisions (JSON manifest)
3. **Phase 3 (Voice)**: TTS generates new narration → applies pronunciation fixes
4. **Phase 4 (Assembly)**: MoviePy renders final video with cuts/speedups/new audio

**Testing Philosophy**: Test each phase independently with mocked dependencies, then test integration.

---

## Phase 1: Ingest & Transcription

### What Phase 1 Does

- Extracts audio from video using FFmpeg
- Transcribes audio using OpenAI Whisper
- Returns timestamped transcript segments

### Unit Test - Audio Extraction (Mocked FFmpeg)

```python
import pytest
from unittest.mock import patch, MagicMock
from pathlib import Path

@pytest.fixture
def mock_ffmpeg():
    """Mock ffmpeg-python for audio extraction."""
    with patch('ffmpeg.input') as mock_input:
        mock_stream = MagicMock()
        mock_output = MagicMock()
        mock_stream.output.return_value = mock_output
        mock_output.overwrite_output.return_value = mock_output
        mock_output.run.return_value = None
        mock_input.return_value = mock_stream
        yield mock_input

def test_phase1_audio_extraction(mock_ffmpeg, tmp_path):
    """Test audio extraction in isolation."""
    from src.phase1_ingest import AudioExtractor

    extractor = AudioExtractor()
    output_path = str(tmp_path / "audio.mp3")
    result = extractor.extract("input.mp4", output_path)

    assert Path(result).name == "audio.mp3"
    mock_ffmpeg.assert_called_once_with("input.mp4")
```

### Unit Test - Transcription (Mocked Whisper)

```python
@pytest.fixture
def mock_whisper():
    """Mock Whisper transcription."""
    with patch('whisper.load_model') as mock_model:
        model_instance = MagicMock()
        model_instance.transcribe.return_value = {
            'segments': [
                {'id': 0, 'start': 0.0, 'end': 5.0, 'text': 'Hello world'},
                {'id': 1, 'start': 5.0, 'end': 10.0, 'text': 'This is a test'}
            ],
            'language': 'en'
        }
        mock_model.return_value = model_instance
        yield mock_model

def test_phase1_transcription(mock_whisper):
    """Test transcription logic with mocked Whisper."""
    from src.phase1_ingest import WhisperTranscriber

    transcriber = WhisperTranscriber(model="base")
    result = transcriber.transcribe("test_audio.mp3")

    assert len(result['segments']) == 2
    assert result['segments'][0]['text'] == 'Hello world'
    mock_whisper.assert_called_once_with("base")
```

### Integration Test - Phase 1 End-to-End

```python
def test_phase1_integration(minimal_test_video, mock_whisper, tmp_path):
    """Test Phase 1 with real video but mocked Whisper.

    Uses real FFmpeg for audio extraction, mocked Whisper for transcription.
    """
    from src.phase1_ingest import Phase1Processor

    processor = Phase1Processor(whisper_model="base")
    audio_path, segments = processor.process(
        video_path=str(minimal_test_video),
        output_dir=str(tmp_path)
    )

    # Verify audio was extracted
    assert Path(audio_path).exists()
    assert Path(audio_path).suffix in ['.mp3', '.wav']

    # Verify segments from mock
    assert len(segments) == 2
    assert all(hasattr(s, 'text') for s in segments)
```

### Testing Without API Keys

```python
import os

@pytest.mark.skipif(
    not os.getenv("OPENAI_API_KEY"),
    reason="No OpenAI API key available"
)
def test_phase1_real_whisper(minimal_test_audio):
    """Integration test with real Whisper API (slow, requires key)."""
    from src.phase1_ingest import WhisperTranscriber

    transcriber = WhisperTranscriber("base")
    result = transcriber.transcribe(str(minimal_test_audio))

    # Audio fixture may be silent, so segments might be empty
    assert 'segments' in result
```

---

## Phase 2: Director (Edit Planning)

### What Phase 2 Does

- Analyzes transcript segments
- Uses GPT-4/Claude to generate edit decisions
- Returns structured edit actions (keep, cut, speedup, rewrite)

### Unit Test - Edit Plan Generation (Mocked LLM)

```python
import json
from unittest.mock import patch, MagicMock

@pytest.fixture
def mock_openai():
    """Mock OpenAI GPT-4 for edit plan generation."""
    with patch('openai.chat.completions.create') as mock_chat:
        mock_response = MagicMock()
        edit_plan = {
            'actions': [
                {
                    'type': 'keep',
                    'start_time': 0.0,
                    'end_time': 5.0,
                    'text': 'Important content',
                    'speed': 1.0
                },
                {
                    'type': 'cut',
                    'start_time': 5.0,
                    'end_time': 10.0,
                    'reason': 'Installation wait time'
                }
            ]
        }
        mock_response.choices[0].message.content = json.dumps(edit_plan)
        mock_chat.return_value = mock_response
        yield mock_chat

def test_phase2_edit_plan_generation(mock_openai):
    """Test edit plan generation with mocked GPT."""
    from src.phase2_director import DirectorAgent
    from src.models import TranscriptSegment

    segments = [
        TranscriptSegment(id=0, start=0.0, end=5.0, text='Important content'),
        TranscriptSegment(id=1, start=5.0, end=10.0, text='Installing packages...')
    ]

    director = DirectorAgent(provider="openai")
    actions = director.generate_edit_plan(segments, "input.mp4")

    assert len(actions) == 2
    assert actions[0].type == 'keep'
    assert actions[1].type == 'cut'
    mock_openai.assert_called_once()
```

### Testing Provider Fallback

```python
def test_phase2_provider_fallback(mock_openai):
    """Test that director falls back to alternative provider on error."""
    from src.phase2_director import DirectorAgent

    # Make OpenAI fail
    mock_openai.side_effect = Exception("API Error")

    # Should fall back to Anthropic (if configured)
    with patch('anthropic.Anthropic') as mock_anthropic:
        mock_message = MagicMock()
        mock_message.content[0].text = json.dumps({'actions': []})
        mock_anthropic.return_value.messages.create.return_value = mock_message

        director = DirectorAgent(provider="openai")
        # Test fallback behavior...
```

### Testing Manifest Validation

```python
def test_phase2_manifest_validation():
    """Test that invalid edit plans are rejected."""
    from src.phase2_director import DirectorAgent
    from src.models import EditAction

    director = DirectorAgent()

    # Test invalid action type
    with pytest.raises(ValueError):
        action = EditAction(type='invalid', start_time=0.0, end_time=5.0)

    # Test negative time
    with pytest.raises(ValueError):
        action = EditAction(type='keep', start_time=-1.0, end_time=5.0)

    # Test end before start
    with pytest.raises(ValueError):
        action = EditAction(type='keep', start_time=10.0, end_time=5.0)
```

### Integration Test - Real LLM

```python
@pytest.mark.integration
@pytest.mark.skipif(not os.getenv("OPENAI_API_KEY"), reason="No API key")
def test_phase2_real_llm(sample_transcript):
    """Integration test with real LLM (expensive, slow)."""
    from src.phase2_director import DirectorAgent

    director = DirectorAgent(provider="openai")
    actions = director.generate_edit_plan(sample_transcript, "test.mp4")

    assert len(actions) > 0
    assert all(hasattr(a, 'type') for a in actions)
    assert all(a.type in ['keep', 'cut', 'speedup', 'rewrite'] for a in actions)
```

---

## Phase 3: Voice Generation

### What Phase 3 Does

- Applies pronunciation corrections to narration text
- Generates audio using ElevenLabs or OpenAI TTS
- Returns audio file path and duration

### Unit Test - Pronunciation Application

```python
def test_phase3_pronunciation_rules():
    """Test that pronunciations are applied correctly."""
    from src.phase3_voice import PronunciationDictionary

    pd = PronunciationDictionary()

    # Test specific pronunciation rules
    text = "The router handles API requests"
    result = pd.apply(text)

    assert "rau-ter" in result.lower()
    assert "ay-pee-eye" in result.lower()
```

### Unit Test - Voice Generation (Mocked TTS)

```python
@pytest.fixture
def mock_elevenlabs():
    """Mock ElevenLabs TTS."""
    with patch('elevenlabs.generate') as mock_gen:
        mock_gen.return_value = b'\x00\x01' * 1000  # Fake audio bytes
        yield mock_gen

def test_phase3_voice_generation(mock_elevenlabs, tmp_path):
    """Test voice generation with mocked ElevenLabs."""
    from src.phase3_voice import VoiceGenerator

    vg = VoiceGenerator(provider="elevenlabs")
    output_path = tmp_path / "voice.mp3"

    duration = vg.generate_audio("Test narration", str(output_path))

    assert output_path.exists()
    assert duration > 0
    mock_elevenlabs.assert_called_once()
```

### Testing Provider Selection

```python
def test_phase3_provider_selection(mock_elevenlabs, mock_openai_tts):
    """Test that correct TTS provider is used."""
    from src.phase3_voice import VoiceGenerator

    # Test ElevenLabs
    vg_eleven = VoiceGenerator(provider="elevenlabs")
    # Should call ElevenLabs mock

    # Test OpenAI
    vg_openai = VoiceGenerator(provider="openai")
    # Should call OpenAI TTS mock
```

### Integration Test - Pronunciation Flow

```python
def test_phase3_pronunciation_integration():
    """Test that pronunciations are applied before TTS."""
    from src.phase3_voice import VoiceGenerator

    vg = VoiceGenerator()

    # Test text with known pronunciation rules
    text = "The router handles requests"
    processed = vg.pronunciation_dict.apply(text)

    # Verify pronunciation was applied
    assert "rau-ter" in processed.lower()
    assert "router" not in processed.lower()
```

---

## Phase 4: Video Assembly

### What Phase 4 Does

- Converts video to CFR (Constant Frame Rate) if needed
- Creates video clips based on edit actions
- Applies speed changes, cuts, and new audio
- Renders final optimized video

### Unit Test - Frame Alignment

```python
def test_phase4_frame_alignment():
    """Test frame alignment calculation (pure logic, no I/O)."""
    from src.phase4_assembly import frame_align_duration

    # Test with 30 fps
    assert frame_align_duration(5.234, 30.0) == pytest.approx(5.233, abs=0.001)

    # Test with 60 fps
    assert frame_align_duration(5.234, 60.0) == pytest.approx(5.233, abs=0.001)
```

### Unit Test - CFR Conversion (Mocked FFmpeg)

```python
@patch('subprocess.run')
def test_phase4_cfr_conversion_mocked(mock_run, tmp_path):
    """Test CFR conversion with mocked subprocess."""
    from src.phase4_assembly import convert_to_cfr

    # Mock successful FFmpeg execution
    mock_run.return_value.returncode = 0

    result = convert_to_cfr("input.mp4")

    # Verify FFmpeg was called
    mock_run.assert_called_once()
    args = mock_run.call_args[0][0]
    assert 'ffmpeg' in args
    assert '-r' in args  # Frame rate flag
```

### Integration Test - CFR Conversion (Real FFmpeg)

```python
def test_phase4_cfr_conversion_real(minimal_test_video):
    """Test CFR conversion with real FFmpeg."""
    from src.phase4_assembly import convert_to_cfr

    cfr_path = convert_to_cfr(str(minimal_test_video))

    assert Path(cfr_path).exists()
    # Could verify frame rate with ffprobe if needed
```

### Unit Test - Video Assembly (Mocked MoviePy)

```python
@pytest.fixture
def mock_moviepy():
    """Mock MoviePy for video assembly."""
    with patch('moviepy.editor.VideoFileClip') as mock_video, \
         patch('moviepy.editor.AudioFileClip') as mock_audio, \
         patch('moviepy.editor.concatenate_videoclips') as mock_concat:

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

        # Setup concatenation
        final_clip = MagicMock()
        final_clip.write_videofile = MagicMock()
        mock_concat.return_value = final_clip

        yield {
            'video': mock_video,
            'audio': mock_audio,
            'concat': mock_concat
        }

def test_phase4_video_assembler(mock_moviepy, tmp_path):
    """Test video assembly with mocked MoviePy."""
    from src.phase4_assembly import VideoAssembler
    from src.models import EditAction

    actions = [
        EditAction(type='keep', start_time=0.0, end_time=5.0, text='Keep this'),
        EditAction(type='cut', start_time=5.0, end_time=10.0),
        EditAction(type='speedup', start_time=10.0, end_time=15.0, speed=3.0)
    ]

    assembler = VideoAssembler("input.mp4")
    result = assembler.assemble(actions, str(tmp_path / "output.mp4"))

    # Verify MoviePy was used
    mock_moviepy['video'].assert_called()
    mock_moviepy['concat'].assert_called_once()
```

### Testing Error Handling

```python
@patch('subprocess.run')
def test_phase4_ffmpeg_error_handling(mock_run):
    """Test FFmpeg error handling in Phase 4."""
    from src.phase4_assembly import convert_to_cfr
    import subprocess

    # Simulate FFmpeg failure
    mock_run.side_effect = subprocess.CalledProcessError(1, 'ffmpeg')

    with pytest.raises(subprocess.CalledProcessError):
        convert_to_cfr("nonexistent.mp4")
```

---

## End-to-End Pipeline Testing

### Full Pipeline - All Mocked

```python
@pytest.mark.integration
def test_full_pipeline_mocked(
    minimal_test_video,
    mock_whisper,
    mock_openai,
    mock_elevenlabs,
    mock_moviepy,
    tmp_path
):
    """Test complete pipeline with all external dependencies mocked.

    This verifies the integration between phases without costly API calls.
    """
    from src.pipeline import ScreencastOptimizer

    optimizer = ScreencastOptimizer(
        whisper_model="base",
        llm_provider="openai",
        voice_provider="elevenlabs"
    )

    manifest_path = optimizer.optimize(
        video_path=str(minimal_test_video),
        output_dir=str(tmp_path)
    )

    # Verify manifest was created
    assert Path(manifest_path).exists()

    # Verify manifest structure
    with open(manifest_path) as f:
        manifest = json.load(f)
        assert 'actions' in manifest
        assert 'metadata' in manifest
        assert len(manifest['actions']) > 0
```

### Full Pipeline - Real APIs (Expensive)

```python
@pytest.mark.integration
@pytest.mark.expensive
@pytest.mark.skipif(
    not all([
        os.getenv("OPENAI_API_KEY"),
        os.getenv("ELEVENLABS_API_KEY")
    ]),
    reason="Missing API keys for full integration test"
)
def test_full_pipeline_real(minimal_test_video, tmp_path):
    """Full end-to-end test with real APIs (slow, expensive).

    Only runs when all API keys are available.
    Use minimal test video to reduce costs.
    """
    from src.pipeline import ScreencastOptimizer

    optimizer = ScreencastOptimizer()
    result = optimizer.optimize(
        video_path=str(minimal_test_video),
        output_dir=str(tmp_path)
    )

    # Verify output video exists
    assert Path(result).exists()

    # Verify output video is smaller than input (optimization worked)
    from src.ffmpeg_utils import get_video_info
    input_info = get_video_info(str(minimal_test_video))
    output_info = get_video_info(result)

    assert output_info['duration'] <= input_info['duration']
```

### Testing Phase Independence

```python
def test_phases_can_run_independently(minimal_test_video, tmp_path):
    """Test that phases can be run independently and resumed.

    This tests the manifest-driven architecture - you should be able to
    run phases 1-3 to generate a manifest, then run phase 4 separately.
    """
    from src.pipeline import ScreencastOptimizer

    optimizer = ScreencastOptimizer()

    # Run phases 1-3 only (generate manifest)
    manifest_path = optimizer.plan_only(
        video_path=str(minimal_test_video),
        output_dir=str(tmp_path)
    )

    assert Path(manifest_path).exists()

    # Later, run phase 4 from existing manifest
    output_video = optimizer.render_from_manifest(
        manifest_path=manifest_path,
        output_dir=str(tmp_path)
    )

    assert Path(output_video).exists()
```

---

## Testing Best Practices

### Phase Testing Strategy

1. **Unit tests with mocks** - Fast, isolate logic
2. **Integration tests with small fixtures** - Verify phase outputs
3. **End-to-end with mocks** - Verify phase integration
4. **Selective real API tests** - Expensive, mark with `@pytest.mark.expensive`

### Coverage Targets by Phase

- **Phase 1**: 80%+ (mock FFmpeg/Whisper)
- **Phase 2**: 90%+ (mock LLM, test validation logic)
- **Phase 3**: 90%+ (mock TTS, test pronunciation rules 100%)
- **Phase 4**: 70%+ (complex video ops, focus on logic not rendering)

### Common Pitfalls

❌ **Don't** make real API calls in unit tests
❌ **Don't** test with large videos (slow, expensive)
❌ **Don't** test rendering quality (subjective, hard to verify)

✅ **Do** mock external dependencies
✅ **Do** use minimal test fixtures (1-5 seconds)
✅ **Do** test edit decision logic and structure

---

## References

- **Mocking patterns**: [testing-mocking.md](./testing-mocking.md)
- **Test fixtures**: [testing-fixtures.md](./testing-fixtures.md)
- **pytest configuration**: [testing-configuration.md](./testing-configuration.md)
- **Architecture docs**: [ARCHITECTURE.md](../../docs/ARCHITECTURE.md)

---

**Last Updated:** 2025-12-10
**Python Version:** 3.11+
**Pipeline:** 4-phase metadata-driven architecture
