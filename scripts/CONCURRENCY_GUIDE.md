# Code Review with Concurrency Control Example

This document explains how the concurrency control works in the mbti review scripts.

## How Concurrency Control Works

The scripts use a **sliding window** approach to limit concurrent API calls:

```
Files to review: [F1, F2, F3, F4, F5, F6, F7, F8, F9, F10]
Concurrency limit: 5

Timeline:
─────────────────────────────────────────────────────────

Time 0s:  Start reviewing F1, F2, F3, F4, F5
          [F1▶] [F2▶] [F3▶] [F4▶] [F5▶]
          
Time 2s:  F1 completes, F6 starts
          [F1✓] [F2▶] [F3▶] [F4▶] [F5▶] [F6▶]
          
Time 3s:  F3 completes, F7 starts
          [F1✓] [F2▶] [F3✓] [F4▶] [F5▶] [F6▶] [F7▶]
          
Time 4s:  F2 and F4 complete, F8 and F9 start
          [F1✓] [F2✓] [F3✓] [F4✓] [F5▶] [F6▶] [F7▶] [F8▶] [F9▶]
          
Time 5s:  F5 completes, F10 starts
          [F1✓] [F2✓] [F3✓] [F4✓] [F5✓] [F6▶] [F7▶] [F8▶] [F9▶] [F10▶]
          
Time 7s:  Remaining files complete
          [F1✓] [F2✓] [F3✓] [F4✓] [F5✓] [F6✓] [F7✓] [F8✓] [F9✓] [F10✓]
```

**Key Points:**
- Never more than 5 requests active at once
- New requests start immediately when a slot opens
- Total time depends on the slowest reviews in each batch
- Failed reviews don't block others

## Implementation Details

```javascript
async function processConcurrently(files, processor, concurrency) {
  const results = [];
  const executing = [];

  for (const file of files) {
    // Start a new review
    const promise = processor(file).then((result) => {
      results.push(result);
      // Remove from executing list when done
      executing.splice(executing.indexOf(promise), 1);
      return result;
    });

    executing.push(promise);

    // Wait if we've hit the concurrency limit
    if (executing.length >= concurrency) {
      await Promise.race(executing); // Wait for ANY to complete
    }
  }

  // Wait for all remaining to complete
  await Promise.all(executing);
  return results;
}
```

## Choosing the Right Concurrency

### Concurrency = 1 (Sequential)
- **Pros:** Safest for rate limits, predictable timing
- **Cons:** Slowest
- **Use when:** You have strict rate limits or want to be very conservative

### Concurrency = 5 (Default)
- **Pros:** Good balance of speed and safety
- **Cons:** None for most use cases
- **Use when:** Normal usage, recommended default

### Concurrency = 10+ (Aggressive)
- **Pros:** Fastest possible
- **Cons:** May hit rate limits, higher chance of errors
- **Use when:** You have high quota and need results quickly

## Example Usage

```bash
# Conservative approach (avoid hitting rate limits)
node scripts/review-mbti-files.mjs --changed --concurrency=2

# Default balanced approach
node scripts/review-mbti-files.mjs --changed

# Aggressive approach (if you have high API quota)
node scripts/review-mbti-files.mjs --all --concurrency=10

# Review just the bytes package
node scripts/review-mbti-files.mjs --files=bytes/pkg.generated.mbti

# See progress in real-time
node scripts/review-mbti-files.mjs --changed --verbose
```

## Error Handling

The scripts handle errors gracefully:
- Failed reviews are collected and reported at the end
- Failures don't stop other reviews
- You can retry failed files by passing them with `--files`

Example output:
```
✓ Reviewed 1/5: bytes/pkg.generated.mbti
✓ Reviewed 2/5: string/pkg.generated.mbti
✗ Failed 3/5: error/pkg.generated.mbti (API timeout)
✓ Reviewed 4/5: array/pkg.generated.mbti
✓ Reviewed 5/5: list/pkg.generated.mbti

SUMMARY
═══════════════════════════════════════
Total files: 5
Successful: 4
Failed: 1
Duration: 12.5s
Concurrency: 5

❌ Failed reviews:
  - error/pkg.generated.mbti: API timeout
```

## Performance Estimates

Based on typical API response times (~2-3 seconds per review):

| Files | Concurrency=1 | Concurrency=5 | Concurrency=10 |
|-------|---------------|---------------|----------------|
| 10    | ~25s          | ~6s           | ~3s            |
| 30    | ~75s          | ~18s          | ~9s            |
| 60    | ~150s (2.5m)  | ~36s          | ~18s           |

*Note: Actual times vary based on file size, API latency, and network conditions.*
