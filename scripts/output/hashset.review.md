# Review: moonbitlang/core/hashset

**File:** `hashset/pkg.generated.mbti`  
**Date:** 2025-10-09T09:58:22.424Z  
**Status:** ✓ Success

---

**API Review**  
- HashSet exposes the expected set operations (insert/remove/membership plus union/diff/intersection) and standard iteration helpers.  
- Constructors cover several common sources (empty with optional capacity, array, iter, fixed array), giving flexible creation paths.  
- Trait implementations (BitAnd/BitOr/BitXOr/Sub/Default/Show/ToJson/Arbitrary) make the type integrate well with the broader ecosystem.

**Issues & Inconsistencies**  
- `HashSet::length` is marked `#alias(size, deprecated)` but the primary `size` method does not appear in this interface (`hashset/pkg.generated.mbti:23`); users may wonder what to call instead.  
- `HashSet::copy` has no `Hash + Eq` (or other) constraint on `K` (`hashset/pkg.generated.mbti:10`), yet cloning every element typically requires at least `Clone`/`Copy`— worth confirming the semantics.

**Suggestions**  
1. Expose the intended replacement for `length` (`size`?) in the public interface so users can migrate cleanly.  
2. Clarify (in docs or signature bounds) how `HashSet::copy` duplicates elements, or add the appropriate trait requirements if element copies are deep.
