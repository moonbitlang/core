# Deprecated Items Refactoring Summary

## Work Completed

### ✅ Array Package
- Successfully moved 3 deprecated functions from `view.mbt` to `deprecated.mbt`:
  - `View::rev_inplace`
  - `View::map_inplace`  
  - `View::mapi_inplace`
- All tests passing
- No interface changes (verified via .mbti files)

## Work Remaining

The refactoring process involves:
1. Finding all `#deprecated` blocks in non-deprecated.mbt files
2. Moving complete blocks (from `///|` to end of function/type) to deprecated.mbt
3. Preserving the exact block structure including comments
4. Running `moon fmt` and `moon info` after changes
5. Verifying tests still pass with `moon test`
6. Checking .mbti files for unexpected interface changes

## Packages Still Needing Refactoring

See `todo.md` for the complete list. Major packages include:
- **builtin**: Has many deprecated items across multiple files (string.mbt, iter.mbt, intrinsics.mbt, etc.)
- **deque, hashmap, hashset, list, queue**: Have deprecated items in types.mbt files
- **immut/** subpackages: Multiple packages with deprecated items
- **math, random, rational, result**: Various deprecated functions
- **sorted_map, sorted_set**: Deprecated items in types.mbt

## Refactoring Pattern

For each package with deprecated items in non-deprecated.mbt files:

1. Identify deprecated blocks using: `grep -l '#deprecated' *.mbt | grep -v deprecated.mbt`
2. For each file with deprecated items:
   - Extract complete blocks containing `#deprecated`
   - Move to deprecated.mbt (create if doesn't exist)
   - Ensure proper copyright header in deprecated.mbt
3. Run formatting and validation:
   ```bash
   moon fmt
   moon info  
   moon test
   git diff *.mbti  # Check for interface changes
   ```

## Notes
- MoonBit uses block-based organization with `///|` separators
- Each deprecated item should be moved as a complete block
- The deprecated.mbt files already exist in most packages
- Interface (.mbti) files should not change if refactoring is done correctly
