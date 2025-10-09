# Review: moonbitlang/core/sorted_set

**File:** `sorted_set/pkg.generated.mbti`  
**Date:** 2025-10-09T10:01:19.158Z  
**Status:** ✓ Success

---

**Assessment**
- The surface in `sorted_set/pkg.generated.mbti` covers the expected ordered-set operations (construction, membership, set algebra, iteration) and keeps mutation-only functions (`add`, `remove`) separate from the pure ones, which makes the API easy to reason about.
- Generic constraints are consistently applied only where ordering is required, so callers aren’t forced to supply a comparator when it isn’t needed.

**Issues**
- `SortedSet::length` is marked `#alias(size, deprecated)` but the canonical `size` entry isn’t visible in the interface; this can confuse users and tooling that expect the non-deprecated name.
- Both `copy` and the deprecated `deep_clone` remain exported; without docs, it’s unclear whether `copy` is always deep (as the new name suggests) or whether there’s still a behavioral distinction.
- Several deprecations (`diff`, `intersect`, `deep_clone`, `length`) persist in the main namespace rather than being isolated (e.g., in `deprecated.mbt`), which keeps clutter in the primary API view.

**Suggestions**
- Ensure the canonical `size` signature is emitted (or remove the alias marker) so the preferred name is obvious to callers.
- If `copy` fully replaces `deep_clone`, consider moving the deprecated symbols into a dedicated `deprecated.mbt` file or documenting the intended transition inline.
- Add brief documentation or naming adjustments clarifying whether `copy` performs a deep copy to avoid ambiguity after deprecating `deep_clone`.
