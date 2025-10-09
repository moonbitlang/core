# Review: moonbitlang/core/immut/sorted_map

**File:** `immut/sorted_map/pkg.generated.mbti`  
**Date:** 2025-10-09T09:59:49.292Z  
**Status:** ✓ Success

---

**API Review**
- Comprehensive surface for construction, querying, and traversal; aliases for deprecated names ease migration (`immut/sorted_map/pkg.generated.mbti:15-71`).

**Issues**
- `SortedMap::contains` lacks a `K : Compare` bound while other lookup-style helpers such as `get` and `at` require it, which makes the signature inconsistent and may surprise users (`immut/sorted_map/pkg.generated.mbti:19`).
- `SortedMap::new` is marked as a free function but omits the `K : Compare` constraint that every other constructor-style function carries, leaving ambiguity about when a user must supply the comparator (`immut/sorted_map/pkg.generated.mbti:53`).
- A large set of deprecated members still lives in the primary interface instead of a dedicated `deprecated.mbt`, so the generated API remains noisy and harder to scan (`immut/sorted_map/pkg.generated.mbti:22-50`).

**Suggestions**
- Add the missing `Compare` bound (or document why it is unnecessary) on `contains` to match the rest of the lookup API.
- Require `K : Compare` on `new` (or provide a parallel `unsafe_new` with rationale) so constructors present a uniform contract.
- Move deprecated definitions into a separate `deprecated.mbt` module to keep the main interface lean while still exposing them for compatibility.
