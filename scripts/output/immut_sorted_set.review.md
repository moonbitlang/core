# Review: moonbitlang/core/immut/sorted_set

**File:** `immut/sorted_set/pkg.generated.mbti`  
**Date:** 2025-10-09T10:00:03.505Z  
**Status:** ✓ Success

---

**API Assessment**
- Comprehensive immutable-set surface in `immut/sorted_set/pkg.generated.mbti` with standard constructors, set algebra, traversal, and JSON/QuickCheck support; consistent persistent semantics via `Self[A]` results; optional variants exist for many partial operations.

**Issues**
- `SortedSet::max` / `SortedSet::min` (`immut/sorted_set/pkg.generated.mbti:40`, `immut/sorted_set/pkg.generated.mbti:42`) return bare `A`; calling them on an empty set will likely trap, but the signature gives no hint of that precondition.
- `SortedSet::remove_min` (`immut/sorted_set/pkg.generated.mbti:49`) both drops the removed element and provides no failure signalling, forcing callers to fetch `min` separately and handle emptiness twice.
- `SortedSet::new` (`immut/sorted_set/pkg.generated.mbti:45`) constructs an empty set without requiring `A : Compare`; it lets users form `SortedSet` values whose element type can’t satisfy core operations like `add`, which may be surprising.

**Suggestions**
- Annotate partial operations (`min`, `max`, `remove_min`) with `raise?`, or otherwise document/enforce their preconditions so misuse is visible at compile time.
- Offer a variant of `remove_min` that returns the removed element (e.g. `(A?, Self[A])`) to avoid redundant lookups and make emptiness explicit.
- Consider tightening constructor bounds (or clearly documenting why they’re loose) so only comparable element types can inhabit `SortedSet[A]`.
