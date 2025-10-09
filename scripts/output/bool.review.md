# Review: moonbitlang/core/bool

**File:** `bool/pkg.generated.mbti`  
**Date:** 2025-10-09T09:56:31.658Z  
**Status:** ✓ Success

---

**Assessment**
- API stays minimal: Bool exposes only numeric conversion helpers plus `Hash`, so surface is easy to understand and keeps implementation choices private.

**Issues / Oddities**
- Conversion set feels uneven: we have `to_int`, `to_int16`, `to_int64` but no explicit `to_int8`/`to_int32`; similar gaps on the unsigned side (`to_uint8`/`to_uint32`).
- Method naming mixes generic and bit-width forms (`to_uint` vs `to_uint16`/`to_uint64`), which could hint at inconsistent semantics if `UInt` is not simply an alias for one of the fixed-width types.

**Suggestions**
- Consider adding the missing sized conversions (8/32-bit) or clarifying why they are excluded; otherwise remove the 16-bit variants to keep the API tight.
- Align naming: if `UInt` is the canonical machine word, ensure docs (or naming) make the relationship to the fixed-width versions obvious.
