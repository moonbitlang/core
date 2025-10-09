# Review: moonbitlang/core/immut/internal/sparse_array

**File:** `immut/internal/sparse_array/pkg.generated.mbti`  
**Date:** 2025-10-09T09:59:01.158Z  
**Status:** ✓ Success

---

**Assessment**
- `SparseArray` offers a solid immutable-style surface (`add`, `remove`, `replace`, set-like ops) and mirrors `Bitset` helpers, so the core use cases appear covered (`immut/internal/sparse_array/pkg.generated.mbti:5-28`).
- Callback-based combinators (`map`, `each`, `filter`, `union`, etc.) support effectful code via `raise?`, which keeps the API flexible without exposing internals (`immut/internal/sparse_array/pkg.generated.mbti:21-28`).

**Issues**
- `SparseArray::filter` and `SparseArray::difference` both return `Self[X]?`, yet an empty sparse array is already representable via `empty()`. The extra option layer suggests an error state that is not documented or justified, making the signature confusing (`immut/internal/sparse_array/pkg.generated.mbti:19-22`).
- `Bitset::inner` is deprecated, but there is no non-deprecated alternative for extracting raw contents or iterating all set indices, nudging callers back to a deprecated API (`immut/internal/sparse_array/pkg.generated.mbti:12-17`).

**Suggestions**
1. Clarify the meaning of the `None` result (or drop it) for `SparseArray::filter`/`difference`; if it only signals “no surviving elements”, return a plain `SparseArray[X]` with `empty()` instead.
2. Provide a supported replacement for `Bitset::inner`, e.g., a safe iterator or an explicit constructor/extractor, so users can leave the deprecated path without losing functionality.
