# Review: moonbitlang/core/float

**File:** `float/pkg.generated.mbti`  
**Date:** 2025-10-09T09:58:03.763Z  
**Status:** ✓ Success

---

**API Notes**
- `float/pkg.generated.mbti` exposes the expected numeric utilities: zero-ish `default`, IEEE‑754 constants, and standard math helpers (`abs`, `ceil`, `floor`, `round`, `trunc`, `pow`), plus hashing/show impls.  
- Optional parameters on `Float::is_close` let callers fine‑tune tolerance without overloading.

**Potential Issues**
- `Float::to_int` (`float/pkg.generated.mbti`) returns an `Int` without signalling what happens for NaN, infinities, or values outside the integer range—risk of silent UB or truncation surprises.  
- `is_close` lists `relative_tolerance` before `absolute_tolerance`; most libraries favor the opposite order, so callers may guess wrong when using named/positional args.

**Suggestions**
1. Clarify or split `to_int` (e.g., document clamping/rounding rules or provide checked variants).
2. Consider reordering `is_close` parameters (absolute first) or requiring named arguments to reduce call-site ambiguity.
3. If feasible, add symmetric constructors (`from_be_bytes`, etc.) to complement the byte-conversion helpers.
