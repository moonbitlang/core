# Review: moonbitlang/core/immut/hashmap

**File:** `immut/hashmap/pkg.generated.mbti`  
**Date:** 2025-10-09T09:59:07.082Z  
**Status:** ✓ Success

---

**Findings**
- `HashMap::difference`, `HashMap::intersection`, `HashMap::intersection_with`, `HashMap::union`, and `HashMap::union_with` only constrain `K : Eq` (`immut/hashmap/pkg.generated.mbti:18`, `immut/hashmap/pkg.generated.mbti:32`, `immut/hashmap/pkg.generated.mbti:33`, `immut/hashmap/pkg.generated.mbti:51`, `immut/hashmap/pkg.generated.mbti:52`). These set operations need to hash keys from both operands; without `Hash`, callers can construct `HashMap`s (e.g., via `new`) whose keys are not hashable yet still invoke these functions, leading to either compile gaps in downstream code or subtle runtime assumptions.
- `HashMap::singleton` requires `K : Hash` but omits `Eq` (`immut/hashmap/pkg.generated.mbti:49`). Any collision handling still needs equality tests, and most other constructors (e.g., `add`, `from_array`) require both traits, so this asymmetry is surprising and risks misuse.

**API Assessment**
- Broadly complete immutable dictionary surface: bulk constructors (`from_iter`, `of`), structural updates (`add`, `remove`), rich iteration (`iter`, `iter2`, `keys`, `values`), and algebraic combinators (`union`, `intersection`, etc.). Deprecated aliases remain for legacy callers, and free-function aliases ease import ergonomics.

**Suggestions**
- Tighten trait bounds so every operation that inspects hashes requires `Hash` (and `Eq` where comparisons occur) for consistency and clearer expectations. In practice that means adding `Hash` to the set-operations above and adding `Eq` to `singleton`.
- Consider documenting or deprecating remaining legacy methods (`filter`, `map`, `fold`) in favor of the `*_with_key` variants in the main docs so users know which surface is preferred.
