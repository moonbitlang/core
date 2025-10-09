# Progress Logging Example

When you run the review scripts, you'll now see detailed progress information:

## Example Output

```bash
$ node scripts/review-mbti-files.mjs --changed --concurrency=5

🔍 Starting mbti file review...

Found 8 changed mbti file(s)
Using concurrency limit: 5

✓ [1/8] bytes/pkg.generated.mbti (2.34s, ETA: 16s)
✓ [2/8] string/pkg.generated.mbti (2.87s, ETA: 15s)
✓ [3/8] array/pkg.generated.mbti (1.95s, ETA: 12s)
✗ [4/8] error/pkg.generated.mbti (0.52s, ETA: 9s)
✓ [5/8] list/pkg.generated.mbti (3.12s, ETA: 7s)
✓ [6/8] hashmap/pkg.generated.mbti (2.45s, ETA: 5s)
✓ [7/8] buffer/pkg.generated.mbti (2.78s, ETA: 2s)
✓ [8/8] json/pkg.generated.mbti (2.21s, ETA: 0s)

════════════════════════════════════════════════════════════════════════════════
REVIEW RESULTS
════════════════════════════════════════════════════════════════════════════════

────────────────────────────────────────────────────────────────────────────────
📦 moonbitlang/core/bytes (bytes/pkg.generated.mbti)
────────────────────────────────────────────────────────────────────────────────

The API design is well-structured with clear separation between Bytes and 
BytesView. The repeat function is a nice addition...

[... rest of review ...]

════════════════════════════════════════════════════════════════════════════════
SUMMARY
════════════════════════════════════════════════════════════════════════════════
Total files: 8
Successful: 7
Failed: 1
Duration: 18.24s
Concurrency: 5

❌ Failed reviews:
  - error/pkg.generated.mbti: API timeout
```

## Progress Information Explained

Each line shows:

```
✓ [3/8] array/pkg.generated.mbti (1.95s, ETA: 12s)
│   │    │                        │       │
│   │    │                        │       └─ Estimated time to completion
│   │    │                        └─ Time taken for this file
│   │    └─ File path (relative to project root)
│   └─ Progress counter (completed/total)
└─ Status (✓ success, ✗ failure)
```

### Status Indicators:
- **✓** Green checkmark - Review completed successfully
- **✗** Red X - Review failed (error, timeout, etc.)

### Timing Information:
- **File time** - How long this specific file took to review
- **ETA** - Estimated time remaining based on average review time
  - Updates dynamically as reviews complete
  - Gets more accurate as more files are processed

## Benefits of Progress Logging

1. **Visibility** - See which files are being reviewed in real-time
2. **Performance** - Identify slow reviews that might need optimization
3. **Errors** - Immediately see which files failed (without waiting for summary)
4. **Planning** - ETA helps you decide if you have time to wait or should reduce scope
5. **Debugging** - File times help identify API performance issues

## Example Scenarios

### Fast reviews (small files):
```
✓ [1/10] bool/pkg.generated.mbti (0.89s, ETA: 8s)
✓ [2/10] byte/pkg.generated.mbti (0.76s, ETA: 6s)
✓ [3/10] unit/pkg.generated.mbti (0.81s, ETA: 6s)
```

### Slow reviews (large files or API delays):
```
✓ [4/10] builtin/pkg.generated.mbti (5.23s, ETA: 24s)
✓ [5/10] string/pkg.generated.mbti (4.87s, ETA: 19s)
```

### Mixed success/failure:
```
✓ [6/10] array/pkg.generated.mbti (2.34s, ETA: 10s)
✗ [7/10] error/pkg.generated.mbti (0.21s, ETA: 7s)  # Failed quickly
✓ [8/10] json/pkg.generated.mbti (3.12s, ETA: 6s)
```

## Concurrency in Action

With `--concurrency=5`, you'll see reviews completing out of order as different files finish at different times:

```
✓ [1/10] file1 (2.1s, ETA: 18s)  # Started first
✓ [3/10] file3 (1.8s, ETA: 14s)  # Finished before file2!
✓ [2/10] file2 (2.9s, ETA: 14s)  # Took longer
✓ [4/10] file4 (2.2s, ETA: 12s)
✓ [5/10] file5 (1.5s, ETA: 9s)
```

This is normal and shows the concurrency is working - files don't wait for previous files to finish.
