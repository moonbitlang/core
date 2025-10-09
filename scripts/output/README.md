# Review Output Directory

This directory contains the saved review outputs for each `pkg.generated.mbti` file.

## Directory Structure

Each review is saved as a separate Markdown file named after the package:

```
output/
├── bytes.review.md
├── string.review.md
├── array.review.md
├── builtin.review.md
├── immut_array.review.md
└── ...
```

## File Naming Convention

The file names are derived from the package path:
- `bytes/pkg.generated.mbti` → `bytes.review.md`
- `string/pkg.generated.mbti` → `string.review.md`
- `immut/array/pkg.generated.mbti` → `immut_array.review.md`

Slashes in paths are replaced with underscores.

## Review File Format

Each review file contains:

```markdown
# Review: [package name]

**File:** `[path to mbti file]`  
**Date:** [ISO timestamp]  
**Status:** ✓ Success / ✗ Failed

---

[Review content from Codex]
```

## Usage Examples

### Browse reviews in your editor
```bash
# Open all reviews
cd scripts/output
ls *.review.md

# Open specific review
code bytes.review.md
```

### Search across reviews
```bash
# Find reviews mentioning specific terms
grep -r "potential issue" scripts/output/

# Find all deprecation warnings
grep -r "deprecated" scripts/output/

# Count total lines of feedback
wc -l scripts/output/*.review.md
```

### Compare reviews
```bash
# Compare two package reviews
diff scripts/output/bytes.review.md scripts/output/string.review.md
```

### Filter by date
```bash
# Find reviews from today
grep -l "$(date +%Y-%m-%d)" scripts/output/*.review.md
```

## Benefits

✅ **Persistent storage** - Reviews are saved and can be referenced later  
✅ **Easy navigation** - One file per package, easy to find  
✅ **Searchable** - Use grep, ripgrep, or your editor's search  
✅ **Diffable** - Track how reviews change over time  
✅ **Shareable** - Send specific reviews to team members  
✅ **Version control ready** - Can be committed if desired  

## Cleanup

To remove old reviews:

```bash
# Remove all reviews
rm -rf scripts/output/

# Remove specific review
rm scripts/output/bytes.review.md

# Remove reviews older than 7 days
find scripts/output -name "*.review.md" -mtime +7 -delete
```

## Integration with Git

The output directory is gitignored by default. If you want to commit reviews:

```bash
# Remove from gitignore
nano scripts/.gitignore  # Remove the output/ line

# Commit reviews
git add scripts/output/
git commit -m "Add API review for bytes package"
```

## Tips

1. **Review one by one**: Open each file in your editor and address issues
2. **Create issues**: Copy specific feedback into GitHub issues
3. **Track improvements**: Re-run reviews after changes and compare
4. **Share with team**: Send relevant review files to package maintainers
5. **Aggregate insights**: Use grep to find common issues across packages
