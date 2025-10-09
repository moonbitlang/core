# Review Output Feature - Summary

## What Changed

Both review scripts now **automatically save** each review to individual Markdown files in the `scripts/output/` directory.

## File Structure

```
scripts/
├── list-mbti-files.mjs        # Updated with file saving
├── review-mbti-files.mjs      # Updated with file saving
└── output/
    ├── README.md              # Documentation for output directory
    ├── bytes.review.md        # Example: bytes package review
    ├── string.review.md       # Example: string package review
    ├── array.review.md        # Example: array package review
    └── ...                    # One file per package
```

## File Naming

Reviews are named after their package path:
- `bytes/pkg.generated.mbti` → `bytes.review.md`
- `string/pkg.generated.mbti` → `string.review.md`
- `immut/array/pkg.generated.mbti` → `immut_array.review.md`

## Progress Output

Now shows where each review is saved:

```bash
✓ [1/8] bytes/pkg.generated.mbti (2.34s, ETA: 16s) → scripts/output/bytes.review.md
✓ [2/8] string/pkg.generated.mbti (2.87s, ETA: 15s) → scripts/output/string.review.md
✗ [3/8] error/pkg.generated.mbti (0.52s, ETA: 12s) → scripts/output/error.review.md
```

Even failed reviews are saved with error information.

## Review File Format

Each `.review.md` file contains:

```markdown
# Review: moonbitlang/core/bytes

**File:** `bytes/pkg.generated.mbti`  
**Date:** 2025-10-09T12:34:56.789Z  
**Status:** ✓ Success

---

[Codex review content with API assessment, issues, and suggestions]
```

## Benefits

### 1. Persistent Storage
- Reviews don't disappear after script finishes
- Can reference them later
- Build up a knowledge base over time

### 2. Easy Navigation
- One file per package
- Simple filenames matching package names
- Can open directly in any editor

### 3. Searchable
```bash
# Find all mentions of "deprecated"
grep -r "deprecated" scripts/output/

# Find reviews with potential issues
grep -r "potential issue" scripts/output/

# Search for specific package
grep -l "bytes" scripts/output/*.md
```

### 4. Diffable
```bash
# Compare two reviews
diff scripts/output/bytes.review.md scripts/output/string.review.md

# Track changes over time (if committed)
git diff HEAD~1 scripts/output/bytes.review.md
```

### 5. Shareable
```bash
# Send specific review to teammate
cat scripts/output/bytes.review.md | pbcopy

# Attach to GitHub issue
gh issue create --body-file scripts/output/bytes.review.md
```

### 6. Batch Processing
```bash
# Extract all suggestions
grep -A 5 "Suggestions:" scripts/output/*.md > all_suggestions.txt

# Count reviews with issues
grep -l "Potential Issues:" scripts/output/*.md | wc -l

# Create summary of all ratings
grep "Rating:" scripts/output/*.md
```

## Workflow Examples

### Review → Fix → Verify
```bash
# 1. Run review
node scripts/review-mbti-files.mjs --files=bytes/pkg.generated.mbti

# 2. Read and implement suggestions
code scripts/output/bytes.review.md

# 3. Make changes to bytes package
# ...

# 4. Re-run review to verify improvements
node scripts/review-mbti-files.mjs --files=bytes/pkg.generated.mbti

# 5. Compare before/after (if reviews committed)
git diff scripts/output/bytes.review.md
```

### Bulk Review for Documentation
```bash
# 1. Review all packages
node scripts/review-mbti-files.mjs --all --concurrency=5

# 2. Extract all API design issues
grep -B 2 -A 5 "API Design" scripts/output/*.md > api_issues.txt

# 3. Create tracking issues from reviews
for file in scripts/output/*.md; do
  package=$(basename "$file" .review.md)
  echo "Creating issue for $package..."
  # gh issue create --title "API review: $package" --body-file "$file"
done
```

### PR Review Integration
```bash
# 1. Review only changed files
node scripts/review-mbti-files.mjs --changed

# 2. Check which reviews have concerns
grep -l "Potential Issues:" scripts/output/*.md

# 3. Add review comments to PR
for file in scripts/output/*.md; do
  echo "## $(basename "$file")"
  cat "$file"
  echo ""
done > pr_review.md
```

## Git Integration

By default, `output/` is gitignored. To track reviews:

```bash
# Remove from gitignore
sed -i '' '/output\//d' scripts/.gitignore

# Commit reviews
git add scripts/output/
git commit -m "Add API reviews for bytes and string packages"

# Track review changes over time
git log -p scripts/output/bytes.review.md
```

## Cleanup

```bash
# Remove all reviews
rm -rf scripts/output/*.review.md

# Remove specific review
rm scripts/output/bytes.review.md

# Remove old reviews (older than 7 days)
find scripts/output -name "*.review.md" -mtime +7 -delete

# Keep only latest N reviews
ls -t scripts/output/*.review.md | tail -n +11 | xargs rm
```

## Summary of Changes

### Modified Files:
1. `scripts/list-mbti-files.mjs` - Added `saveReviewToFile()` function
2. `scripts/review-mbti-files.mjs` - Added `saveReviewToFile()` function

### New Files:
1. `scripts/output/README.md` - Documentation for output directory
2. `scripts/output/bytes.review.example.md` - Example review file
3. `scripts/.gitignore` - Added output/ to gitignore

### Key Functions Added:
```javascript
async function saveReviewToFile(result) {
  // Creates output directory if needed
  // Generates filename from package path
  // Writes formatted Markdown with review
  // Returns path to saved file
}
```

### Progress Logging Updated:
```javascript
// Before
console.log(`✓ [1/8] bytes/pkg.generated.mbti (2.34s, ETA: 16s)`)

// After
console.log(`✓ [1/8] bytes/pkg.generated.mbti (2.34s, ETA: 16s) → scripts/output/bytes.review.md`)
```

## Next Steps

1. **Run a test review** (with 1-2 files to avoid API charges):
   ```bash
   node scripts/review-mbti-files.mjs --files=bytes/pkg.generated.mbti
   cat scripts/output/bytes.review.md
   ```

2. **Review changed files** from your PR:
   ```bash
   node scripts/review-mbti-files.mjs --changed --concurrency=3
   ```

3. **Browse and address issues** in saved reviews:
   ```bash
   ls scripts/output/
   code scripts/output/
   ```

4. **Decide on git tracking**: Keep reviews gitignored or commit them for history.
