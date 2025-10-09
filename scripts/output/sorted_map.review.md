# Review: moonbitlang/core/sorted_map

**File:** `sorted_map/pkg.generated.mbti`  
**Date:** 2025-10-09T10:01:24.852Z  
**Status:** ✓ Success

---

**Assessment**
- Public surface covers the expected Map basics plus ordered-friendly APIs (iterators, range) with consistent `Compare` bounds for order-sensitive operations (`sorted_map/pkg.generated.mbti:16-45`).
- Free-function aliases for constructors (`from_array`, `from_iter`, `of`, `new`) make creation ergonomic in multiple contexts (`sorted_map/pkg.generated.mbti:22-37`).
- Trait coverage (Default/Eq/Show/ToJson/QuickCheck) looks thoughtfully composed for both runtime and testing scenarios (`sorted_map/pkg.generated.mbti:47-52`).

**Potential Issues**
- `SortedMap::remove(Self, K) -> Unit` offers no feedback on whether the key existed (`sorted_map/pkg.generated.mbti:39-42`); users must pre-check with `contains`/`get`.
- `SortedMap::range(Self, K, K) -> Iter2[K, V]` exposes order slices but the interface gives no hint about bound inclusivity/exclusivity (`sorted_map/pkg.generated.mbti:38`), which could lead to misuse without consulting docs.
- Deprecated array-returning helpers remain exported (`keys`, `values`, alias `add`, alias `size`) (`sorted_map/pkg.generated.mbti:29-45`); without steering consumers toward iter-based replacements, they may linger in new code.

**Suggestions**
- Consider Returning an `Option[V]` or `Bool` from `remove` so callers can react without an extra lookup (or document the current silent behavior more clearly).
- Clarify `range` semantics via naming (`range_inclusive`, `range_open`) or accompanying docs/comments to reduce ambiguity.
- Reinforce deprecation by documenting preferred replacements (`keys_as_iter`, `values_as_iter`, `set`) in the main docs or by relocating legacy APIs to a dedicated deprecated module to discourage new usage.
