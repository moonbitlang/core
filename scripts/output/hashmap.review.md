# Review: moonbitlang/core/hashmap

**File:** `hashmap/pkg.generated.mbti`  
**Date:** 2025-10-09T09:58:23.237Z  
**Status:** ✓ Success

---

**API Assessment**  
- Coverage is solid: construction (`new`, `from_array`, `from_iter`, `of`), lookup variants (`at`, `get`, fallbacks), mutation (`set`, `remove`, `retain`, `clear`), traversal (`iter`, `iter2`, `each`, `eachi`, `keys`, `values`), conversion (`to_array`, `map`, `copy`).  
- Trait coverage (`Default`, `Eq`, `Show`, `ToJson`, `quickcheck::Arbitrary`) makes the type easy to integrate and test.  
- Operator aliases (`_[ _ ]`, `_[_]=_`) align with familiar map ergonomics.

**Potential Issues**  
- `HashMap::remove` returns `Unit`, so callers can’t tell if a key existed; most map APIs surface a bool or removed value for clarity.  
- `HashMap::map` is value-only; the name may suggest key/value transformation—even though keys stay fixed, which could mislead users expecting a general map over `(K, V)`.  
- `HashMap::at` (alias `_[_]`) returns bare `V` and likely panics on missing keys. That’s standard for indexing, but the documentation should make the panic contract explicit.  
- Alias `size` is marked deprecated, but users only see that via the attribute; consider reinforcing this in docs or migration notes.  
- `copy` implies full duplication; without context on cost or mutability semantics, users might misuse it for cheap clones.

**Suggestions**  
1. Consider returning `Bool` or `V?` from `remove` (or adding `remove_entry`) to signal success.  
2. Rename `map` to `map_values` or document prominently that keys are untouched; alternatively add a separate value mapper to avoid overloaded expectations.  
3. Document panic behavior for `at`/`_[ _ ]` and the intended replacement for deprecated `size`.
