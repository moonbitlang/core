# Review: moonbitlang/core/immut/hashset

**File:** `immut/hashset/pkg.generated.mbti`  
**Date:** 2025-10-09T09:58:42.840Z  
**Status:** ✓ Success

---

Solid functional set API: covers creation (`new`, `of`, `from_*`), membership (`contains`, `is_empty`, `length`), iteration (`iter`, `each`), and set algebra (`union`, `intersection`, `difference`) with the expected typeclass instances.

Potential issues:
- `HashSet::difference`, `HashSet::intersection`, and `HashSet::union` constrain their element type with `Eq` only, while every constructor/update already needs both `Eq + Hash`. Building the result of these operations inevitably hashes the elements, so callers with an element type that lacks `Hash` would get a compile-time failure inside the implementation rather than at the call site. That’s inconsistent with the rest of the interface and makes the API surface misleading.

Suggestions:
- Tighten the bounds on `difference`, `intersection`, and `union` to `K : Eq + Hash` so their signatures reflect the actual requirements and stay consistent with the rest of the set API.
