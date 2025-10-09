# Review: moonbitlang/core/array

**File:** `array/pkg.generated.mbti`  
**Date:** 2025-10-09T09:57:39.902Z  
**Status:** ✓ Success

---

**API Assessment**
- Surface covers the three array flavours comprehensively; higher-order helpers (`fold`, `map`, `rev_fold`) are exposed consistently and optional `raise?` effects make side-effects explicit.
- Byte-oriented unsafe extractors appear for all container flavours, which keeps low-level API uniform.
- Top-level `zip_with` complements the method-level zipping APIs, giving both functional and object-style entry points.

**Issues**
- `FixedArray::join` is limited to `Self[String] -> String`, while `Array::join` leverages `@string.ToStringView`; the trait-based form is more flexible, so the mismatch between `array/pkg.generated.mbti:28` and `array/pkg.generated.mbti:62` feels arbitrary.
- `FixedArray::from_iter(Iter[T]) -> Self[T]` (`array/pkg.generated.mbti:26`) may surprise users because the iterator length must match the fixed array size; the contract is unclear from the signature.
- `Array::zip_to_iter2` (`array/pkg.generated.mbti:79`) names and shapes its iterator differently from `ArrayView::iter2` (`array/pkg.generated.mbti:91`), which returns `(index, value)`; the API symmetry is hard to discern.

**Suggestions**
1. Align `FixedArray::join` with the trait-based signature used by `Array::join`, or document why strings-only is required (`array/pkg.generated.mbti:28`, `array/pkg.generated.mbti:62`).
2. Clarify `FixedArray::from_iter`’s expectations (length check, padding, truncation) via name or docs, or expose a safer `try_from_iter` that reports mismatches (`array/pkg.generated.mbti:26`).
3. Consider harmonising iterator-returning names—either rename `Array::zip_to_iter2` or offer `Array::iter2`/`Array::enumerate` to match the `ArrayView` vocabulary (`array/pkg.generated.mbti:79`, `array/pkg.generated.mbti:91`).
