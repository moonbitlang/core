# Review: moonbitlang/core/immut/array

**File:** `immut/array/pkg.generated.mbti`  
**Date:** 2025-10-09T09:58:08.962Z  
**Status:** ✓ Success

---

**API Assessment**  
- Comprehensive coverage for immutable array basics: creation (`new`, `make`, `from_array`, `from_iter`), access (`at`, `get`, `iter`), transformation (`map`, `fold`, `rev_fold`), and growth (`push`, `concat`).  
- Trait coverage (`Eq`, `Compare`, `Hash`, `Show`, `Add`, `@quickcheck.Arbitrary`) makes the type integrate well across the ecosystem.  
- Optionality of `at` vs `get` offers both strict and safe access patterns.

**Potential Issues**  
- `at` and `set` signatures imply they raise on out-of-bounds, but the interface doesn’t clarify whether they trap, raise, or silently handle errors.  
- `push`/`concat` on immutable arrays can be expensive; nothing hints at their complexity, which may surprise users.  
- Deprecated entries (`copy`, `fold_left`, `fold_right`) remain exported; consumers may still rely on them without seeing alternatives.

**Suggestions**  
- Document failure modes (or switch to returning `A?` / `Self[A]?`) for bounds-sensitive operations to make the API safer.  
- Consider adding lightweight builders or batched operations to offset the cost of repeated `push`/`concat`.  
- If deprecations stay visible, add explicit replacements in docs, or move them to a `deprecated.mbt` block to keep the primary surface clean.
