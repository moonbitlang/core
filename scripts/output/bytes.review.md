# Review: moonbitlang/core/bytes

**File:** `bytes/pkg.generated.mbti`  
**Date:** 2025-10-09T09:57:14.339Z  
**Status:** ✓ Success

---

**API Assessment**
- Surface gives core builders (`from_*`, `to_*`) plus search, slicing, iteration—covers common byte needs.
- Clear split between safe (`get`, `sub`) and unchecked (`unsafe_extract_*`) primitives, with aliases for subscripting.
- BytesView includes numeric conversions, hashing, comparison traits—useful for read-only parsing.

**Potential Issues**
- `impl Hash for Bytes` without a matching `Eq`/`Compare` contract (`bytes/pkg.generated.mbti`) breaks the usual expectation that hashable types are equality-comparable.
- `Bytes` lacks a direct `length`/`len` accessor while `BytesView` has `length`; forces consumers to convert to a view or iterate just to get size.
- Redundant constructors: `Bytes::from_fixedarray` (with optional `len`) and `Bytes::of` both wrap `FixedArray[Byte]`, which can confuse users about recommended usage.

**Suggestions**
- Add `impl Eq` (and `Compare` if ordering is meaningful) for `Bytes`, or drop `Hash` until equality semantics are defined.
- Expose a `Bytes::length` (or `Bytes::len`) to align with `BytesView::length` and avoid needless conversions.
- Consolidate `Bytes::from_fixedarray`/`Bytes::of` into a single, clearly named constructor—perhaps keep one public function and deprecate the other for clarity.
