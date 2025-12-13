---
inclusion: fileMatch
fileMatchPattern: '**/*.py'
---

# 📊 Performance Monitoring

> **Purpose:** Track video processing performance, API costs, and system resource usage
>
> **When to use:** Optimizing performance, tracking costs, benchmarking, identifying bottlenecks
>
> **See also:** [metrics-and-limits.md](./metrics-and-limits.md)

## Performance Philosophy

Video processing is inherently resource-intensive. The goal is not to optimize prematurely, but to:

1. **Measure first** - Understand where time and money are spent
2. **Set baselines** - Know what "normal" performance looks like
3. **Identify bottlenecks** - Focus optimization efforts where they matter
4. **Track costs** - API calls cost money, monitor spending
5. **Accept trade-offs** - Sometimes slower is fine if it's cheaper or more reliable

---

## Phase-by-Phase Performance Characteristics

### Phase 1: Ingest & Transcription

**Typical Performance:**
- Audio extraction (FFmpeg): 2-5 seconds for 30-min video
- Whisper transcription: 1-3 minutes for 30-min video (using local model)
- Whisper API: 30-60 seconds for 30-min video (but costs $0.18)

**Bottlenecks:**
- Whisper transcription is the slowest step
- Local Whisper model: CPU-bound, benefits from faster CPU
- Whisper API: Network-bound, depends on upload speed

**Metrics to Track:**
```python
{
    "phase": "phase1_ingest",
    "video_duration_seconds": 1800,  # 30 minutes
    "audio_extraction_time": 3.2,
    "transcription_time": 125.4,
    "transcription_method": "local",  # or "api"
    "whisper_model": "base",
    "total_time": 128.6,
    "segments_generated": 342
}
```

**Optimization Opportunities:**
- Use Whisper API for faster results (trade time for money)
- Use smaller Whisper model (`tiny` vs `base`) for faster transcription
- Process multiple videos in parallel (Phase 1 is independent)

---

### Phase 2: Director (Edit Planning)

**Typical Performance:**
- LLM API call: 10-30 seconds for 30-min video transcript
- Cost: ~$0.30 per 30-min video (GPT-4o)

**Bottlenecks:**
- LLM response time varies (rate limits, API load)
- Longer transcripts = more tokens = higher cost and slower response

**Metrics to Track:**
```python
{
    "phase": "phase2_director",
    "transcript_segments": 342,
    "transcript_tokens": 8450,
    "llm_provider": "openai",
    "llm_model": "gpt-4o",
    "api_call_time": 18.3,
    "tokens_used": {
        "prompt": 8450,
        "completion": 1200,
        "total": 9650
    },
    "estimated_cost": 0.32,
    "actions_generated": 45,
    "total_time": 18.8
}
```

**Optimization Opportunities:**
- Use cheaper models (GPT-4o-mini vs GPT-4o) if quality is acceptable
- Cache edit plans for similar video patterns
- Batch process multiple videos to amortize overhead

---

### Phase 3: Voice Generation

**Typical Performance:**
- ElevenLabs: ~10-15 seconds per minute of narration
- OpenAI TTS: ~5-10 seconds per minute of narration
- Cost: ElevenLabs ~$3.00 per 10 min, OpenAI TTS ~$0.15 per 10 min

**Bottlenecks:**
- API rate limits (ElevenLabs has strict limits)
- Network upload/download of audio
- Number of narration segments (each is a separate API call)

**Metrics to Track:**
```python
{
    "phase": "phase3_voice",
    "narration_segments": 12,
    "total_narration_duration": 420.5,  # seconds
    "tts_provider": "elevenlabs",
    "voice_id": "wevlkhfRsG0ND2D2pQHq",
    "api_calls": 12,
    "total_api_time": 85.3,
    "estimated_cost": 2.10,
    "pronunciation_fixes_applied": 8,
    "total_time": 87.1
}
```

**Optimization Opportunities:**
- Use OpenAI TTS instead of ElevenLabs (10x cheaper, similar quality)
- Reduce narration segments by combining short ones
- Pre-generate common narration phrases and cache
- Use pronunciation dictionary to reduce retry costs

---

### Phase 4: Video Assembly

**Typical Performance:**
- CFR conversion: 30-60 seconds for 30-min video
- Video rendering (MoviePy): 10-20 minutes for 30-min video
- Final video typically 10-30% of original duration

**Bottlenecks:**
- MoviePy rendering is extremely CPU/GPU intensive
- CFR conversion requires re-encoding video
- Writing final video to disk

**Metrics to Track:**
```python
{
    "phase": "phase4_assembly",
    "input_video_duration": 1800,
    "input_video_size_mb": 450,
    "cfr_conversion_time": 42.5,
    "clip_creation_time": 15.2,
    "rendering_time": 720.3,  # 12 minutes
    "output_video_duration": 180,  # 3 minutes (90% reduction)
    "output_video_size_mb": 45,
    "compression_ratio": 0.9,  # 90% reduction
    "fps": 30,
    "resolution": "1920x1080",
    "total_time": 778.0
}
```

**Optimization Opportunities:**
- Use faster FFmpeg presets (`ultrafast` vs `medium`)
- Lower output resolution if acceptable (1080p → 720p)
- Reduce output bitrate if quality is acceptable
- Use GPU-accelerated encoding if available
- Process multiple videos in parallel (separate processes)

---

## End-to-End Pipeline Performance

### Typical 30-Minute Video Processing

```
Phase 1 (Ingest):       ~2 minutes   (local Whisper)
Phase 2 (Director):     ~20 seconds  (GPT-4o)
Phase 3 (Voice):        ~90 seconds  (ElevenLabs)
Phase 4 (Assembly):     ~12 minutes  (MoviePy rendering)
─────────────────────────────────────────────────
Total:                  ~15 minutes

Output:                 3-minute video (90% reduction)
```

### Cost Breakdown (30-Minute Video)

```
Whisper API (optional):  $0.18
GPT-4o (edit plan):      $0.32
ElevenLabs TTS:          $2.10
─────────────────────────────────
Total:                   $2.60 per video

Alternative (cheaper):
Whisper local:           $0.00
GPT-4o-mini:             $0.05
OpenAI TTS:              $0.21
─────────────────────────────────
Total:                   $0.26 per video (10x cheaper)
```

---

## Monitoring Implementation

### Adding Performance Logging

```python
import time
from pathlib import Path
import json
from typing import Dict, Any

class PerformanceMonitor:
    """Track performance metrics across pipeline phases."""

    def __init__(self, metrics_file: Path = Path("metrics.jsonl")):
        self.metrics_file = metrics_file
        self.start_time = None
        self.phase_metrics = {}

    def start_phase(self, phase_name: str):
        """Start timing a phase."""
        self.start_time = time.time()
        self.current_phase = phase_name

    def end_phase(self, additional_metrics: Dict[str, Any] = None):
        """End timing and record metrics."""
        elapsed = time.time() - self.start_time

        metrics = {
            "phase": self.current_phase,
            "timestamp": time.time(),
            "elapsed_seconds": elapsed,
            **(additional_metrics or {})
        }

        # Append to JSONL metrics file
        with open(self.metrics_file, 'a') as f:
            f.write(json.dumps(metrics) + '\n')

        return metrics


# Usage in Phase 1
monitor = PerformanceMonitor()
monitor.start_phase("phase1_ingest")

# ... do audio extraction and transcription ...

monitor.end_phase({
    "video_duration": video_duration,
    "audio_extraction_time": audio_time,
    "transcription_time": transcription_time,
    "segments_generated": len(segments),
    "whisper_model": model_name
})
```

### Estimating API Costs

```python
class CostEstimator:
    """Estimate API costs for video processing."""

    # Pricing as of 2025-12 (update as needed)
    PRICES = {
        "whisper_api": 0.006 / 60,  # $0.006 per minute
        "gpt4o": {
            "input": 2.50 / 1_000_000,   # $2.50 per 1M input tokens
            "output": 10.00 / 1_000_000  # $10.00 per 1M output tokens
        },
        "gpt4o_mini": {
            "input": 0.15 / 1_000_000,
            "output": 0.60 / 1_000_000
        },
        "elevenlabs": 0.30 / 1000,  # $0.30 per 1K characters
        "openai_tts": 15.00 / 1_000_000  # $15.00 per 1M characters
    }

    @classmethod
    def estimate_whisper_cost(cls, audio_duration_seconds: float) -> float:
        """Estimate Whisper API cost."""
        minutes = audio_duration_seconds / 60
        return minutes * cls.PRICES["whisper_api"]

    @classmethod
    def estimate_llm_cost(cls, input_tokens: int, output_tokens: int,
                          model: str = "gpt4o") -> float:
        """Estimate LLM API cost."""
        pricing = cls.PRICES[model]
        input_cost = input_tokens * pricing["input"]
        output_cost = output_tokens * pricing["output"]
        return input_cost + output_cost

    @classmethod
    def estimate_tts_cost(cls, text: str, provider: str = "elevenlabs") -> float:
        """Estimate TTS API cost."""
        chars = len(text)
        if provider == "elevenlabs":
            return chars * cls.PRICES["elevenlabs"]
        elif provider == "openai":
            return chars * cls.PRICES["openai_tts"]

    @classmethod
    def estimate_video_cost(cls, video_duration_seconds: float,
                           transcript_tokens: int = None,
                           narration_chars: int = None) -> Dict[str, float]:
        """Estimate total cost for processing a video."""
        # Estimate transcript tokens if not provided (rough: 1 token per second)
        if transcript_tokens is None:
            transcript_tokens = int(video_duration_seconds * 1.5)

        # Estimate narration length if not provided (rough: 30% of transcript)
        if narration_chars is None:
            narration_chars = transcript_tokens * 4 * 0.3  # tokens to chars

        return {
            "whisper_api": cls.estimate_whisper_cost(video_duration_seconds),
            "gpt4o": cls.estimate_llm_cost(transcript_tokens, 1000, "gpt4o"),
            "gpt4o_mini": cls.estimate_llm_cost(transcript_tokens, 1000, "gpt4o_mini"),
            "elevenlabs": cls.estimate_tts_cost("x" * narration_chars, "elevenlabs"),
            "openai_tts": cls.estimate_tts_cost("x" * narration_chars, "openai")
        }


# Usage
cost_estimate = CostEstimator.estimate_video_cost(1800)  # 30 minutes
print(f"Estimated cost: ${sum(cost_estimate.values()):.2f}")
```

### Batch Processing Metrics

```python
class BatchMetrics:
    """Track metrics across batch video processing."""

    def __init__(self):
        self.video_metrics = []

    def add_video(self, video_id: str, metrics: Dict[str, Any]):
        """Add metrics for a processed video."""
        self.video_metrics.append({
            "video_id": video_id,
            "timestamp": time.time(),
            **metrics
        })

    def summary(self) -> Dict[str, Any]:
        """Generate batch processing summary."""
        total_videos = len(self.video_metrics)
        total_time = sum(v.get("total_time", 0) for v in self.video_metrics)
        total_cost = sum(v.get("estimated_cost", 0) for v in self.video_metrics)

        return {
            "total_videos": total_videos,
            "total_processing_time": total_time,
            "average_time_per_video": total_time / total_videos if total_videos else 0,
            "total_estimated_cost": total_cost,
            "average_cost_per_video": total_cost / total_videos if total_videos else 0,
            "videos_per_hour": 3600 / (total_time / total_videos) if total_videos and total_time else 0
        }
```

---

## Performance Benchmarking

### Setting Baselines

Create a standard test video and measure performance:

```bash
# Create 5-minute test video
ffmpeg -f lavfi -i testsrc=duration=300:size=1920x1080:rate=30 \
       -f lavfi -i sine=frequency=440:duration=300 \
       -c:v libx264 -preset ultrafast -c:a aac -t 300 \
       tests/benchmarks/benchmark_5min.mp4

# Run full pipeline and capture metrics
./run.sh optimize tests/benchmarks/benchmark_5min.mp4 --metrics-output benchmark_metrics.json
```

**Baseline Metrics (on reference hardware):**
```json
{
  "hardware": {
    "cpu": "Apple M1 Pro",
    "ram": "16GB",
    "storage": "SSD"
  },
  "video": {
    "duration": 300,
    "resolution": "1920x1080",
    "fps": 30
  },
  "performance": {
    "phase1_time": 35.2,
    "phase2_time": 8.1,
    "phase3_time": 28.5,
    "phase4_time": 180.3,
    "total_time": 252.1
  },
  "cost": {
    "total": 0.87
  }
}
```

### Performance Regression Testing

```python
def check_performance_regression(current_metrics: Dict, baseline_metrics: Dict,
                                 threshold: float = 0.2) -> bool:
    """Check if performance has regressed beyond threshold."""
    baseline_time = baseline_metrics["performance"]["total_time"]
    current_time = current_metrics["performance"]["total_time"]

    regression = (current_time - baseline_time) / baseline_time

    if regression > threshold:
        print(f"⚠️  Performance regression detected: {regression*100:.1f}% slower")
        print(f"   Baseline: {baseline_time:.1f}s, Current: {current_time:.1f}s")
        return False

    return True
```

---

## When to Optimize

### ✅ Optimize When:

- Processing time exceeds user expectations (> 1 hour for 30-min video)
- API costs are unsustainable for your use case
- Batch processing takes days instead of hours
- You're hitting API rate limits
- System resources are maxed out (100% CPU, OOM errors)

### ❌ Don't Optimize When:

- Current performance is acceptable
- Optimization would add significant complexity
- The bottleneck is external (API latency you can't control)
- You're optimizing based on assumptions rather than measurements
- The code hasn't been profiled yet

### Optimization Priority

1. **First:** Measure and identify actual bottlenecks
2. **Second:** Pick low-hanging fruit (config changes, provider selection)
3. **Third:** Optimize the slowest phase (usually Phase 4 rendering)
4. **Fourth:** Consider architectural changes (parallel processing, caching)
5. **Last:** Micro-optimizations (code-level performance tuning)

---

## Common Performance Issues

### Issue: Phase 4 Rendering Too Slow

**Symptoms:** Video rendering takes > 30 minutes for 30-min input

**Solutions:**
- Use faster FFmpeg preset (`-preset ultrafast`)
- Lower output resolution (1080p → 720p)
- Reduce output bitrate
- Enable hardware acceleration (if available)
- Process videos in parallel (multiple cores)

### Issue: API Rate Limits

**Symptoms:** ElevenLabs/OpenAI API calls failing with 429 errors

**Solutions:**
- Add retry logic with exponential backoff
- Reduce concurrent API calls
- Switch to provider with higher limits
- Batch process during off-peak hours

### Issue: Out of Memory During Rendering

**Symptoms:** Python process killed, MoviePy crashes

**Solutions:**
- Process shorter segments at a time
- Use lower resolution preview for editing
- Reduce frame cache size in MoviePy
- Add swap space or increase RAM

### Issue: High API Costs

**Symptoms:** Spending > $5 per video processed

**Solutions:**
- Use local Whisper instead of API ($0 vs $0.18)
- Use GPT-4o-mini instead of GPT-4o ($0.05 vs $0.32)
- Use OpenAI TTS instead of ElevenLabs ($0.21 vs $2.10)
- Cache edit plans for similar videos
- Review prompt efficiency (reduce tokens)

---

## Profiling Tools

### Python Profiling

```bash
# Profile entire pipeline
python -m cProfile -o profile.stats run_pipeline.py video.mp4

# Analyze with snakeviz
pip install snakeviz
snakeviz profile.stats
```

### Memory Profiling

```bash
# Install memory profiler
pip install memory-profiler

# Profile specific function
python -m memory_profiler phase4_assembly.py
```

### FFmpeg Performance

```bash
# Add timing info to FFmpeg commands
ffmpeg -i input.mp4 -report output.mp4
# Check ffmpeg-*.log for performance details
```

---

## References

- **Metrics and limits**: [metrics-and-limits.md](./metrics-and-limits.md) - Quality gates, performance targets
- **AI integration**: [ai-integration.md](./ai-integration.md) - API cost optimization, rate limiting
- **CI/CD monitoring**: [cicd-workflow.md](./cicd-workflow.md) - Performance tracking in CI
- **Testing**: [testing-pipeline.md](./testing-pipeline.md) - Performance testing strategies
- **Pipeline architecture**: [ARCHITECTURE.md](../../docs/ARCHITECTURE.md)
- **API pricing**: Check OpenAI, Anthropic, ElevenLabs websites for current rates

---

**Last Updated:** 2025-12-10
**Python Version:** 3.11+
**Performance Target:** < 20 minutes for 30-minute video, < $3 API cost
