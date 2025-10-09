# MBTI Review Scripts - Quick Start

## TL;DR

Two ways to review `pkg.generated.mbti` files with Codex SDK. **All reviews are automatically saved to `scripts/output/` directory.**

### Option 1: Using the integrated list script
```bash
# Review all files with concurrency limit of 5 (won't spam API)
node scripts/list-mbti-files.mjs --review

# Review with lower concurrency (more conservative)
node scripts/list-mbti-files.mjs --review --concurrency=3
```

### Option 2: Using the dedicated review script
```bash
# Review only changed files
node scripts/review-mbti-files.mjs --changed

# Review specific files
node scripts/review-mbti-files.mjs --files=bytes/pkg.generated.mbti,string/pkg.generated.mbti

# Review all with custom concurrency
node scripts/review-mbti-files.mjs --all --concurrency=3 --verbose
```

## Key Features

✅ **Concurrency Control**: Default limit of 5 prevents API spam  
✅ **Smart Queueing**: New reviews start as soon as slots open  
✅ **Progress Tracking**: See which files are being reviewed  
✅ **Error Handling**: Failed reviews don't block others  
✅ **Flexible Targeting**: Review all, changed, or specific files  
✅ **Persistent Storage**: Reviews saved to `scripts/output/` directory  
✅ **Individual Files**: One .md file per package for easy navigation  

## Review Output

Reviews are saved as Markdown files in `scripts/output/`:

```
scripts/output/
├── bytes.review.md
├── string.review.md
├── array.review.md
└── ...
```

**Example progress output:**
```
✓ [1/8] bytes/pkg.generated.mbti (2.34s, ETA: 16s) → scripts/output/bytes.review.md
✓ [2/8] string/pkg.generated.mbti (2.87s, ETA: 15s) → scripts/output/string.review.md
```

## Files Created

1. **`list-mbti-files.mjs`** - List AND review mbti files (integrated)
2. **`review-mbti-files.mjs`** - Dedicated review script with more options
3. **`LIST_MBTI_README.md`** - Full documentation
4. **`CONCURRENCY_GUIDE.md`** - Detailed concurrency explanation

## Common Workflows

**Review recently changed interfaces:**
```bash
node scripts/review-mbti-files.mjs --changed
# Reviews saved to scripts/output/
```

**Review specific package you're working on:**
```bash
node scripts/review-mbti-files.mjs --files=bytes/pkg.generated.mbti
# Review saved to scripts/output/bytes.review.md
```

**Browse saved reviews:**
```bash
# List all reviews
ls scripts/output/

# Open specific review
code scripts/output/bytes.review.md

# Search for issues across all reviews
grep -r "potential issue" scripts/output/
```

**Full codebase review (use with caution on quota):**
```bash
node scripts/review-mbti-files.mjs --all --concurrency=3
# All 60 reviews saved to scripts/output/
```

**List files without reviewing:**
```bash
node scripts/list-mbti-files.mjs
node scripts/list-mbti-files.mjs --count
node scripts/list-mbti-files.mjs --json
```

## Why Concurrency Control?

Without concurrency limits, reviewing 60 files would fire 60 simultaneous API requests:
- ❌ May hit rate limits
- ❌ May exceed quota quickly  
- ❌ May cause API errors
- ❌ Wasteful of resources

With concurrency=5:
- ✅ Max 5 requests at once
- ✅ Respects rate limits
- ✅ Predictable quota usage
- ✅ Still reasonably fast

## Configuration

Default concurrency is **5**, which is a good balance. Adjust based on your needs:

```bash
--concurrency=1   # Very conservative (sequential)
--concurrency=3   # Conservative  
--concurrency=5   # Balanced (default)
--concurrency=8   # Aggressive
--concurrency=10  # Very aggressive (may hit limits)
```

See `CONCURRENCY_GUIDE.md` for detailed explanation and performance estimates.
