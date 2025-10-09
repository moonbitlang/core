# Review: moonbitlang/core/double/internal/ryu

**File:** `double/internal/ryu/pkg.generated.mbti`  
**Date:** 2025-10-09T09:57:35.637Z  
**Status:** ✓ Success

---

- `double/internal/ryu/pkg.generated.mbti:4` Exposed surface is a single helper `ryu_to_string(Double) -> String`, which keeps the internal Ryu encoder narrowly scoped—sensible for an internal package.
- `double/internal/ryu/pkg.generated.mbti:4` Potential gap: no surface-level clues about formatting specifics (rounding mode, NaN/inf handling, locale). Callers must infer behavior from implementation, which can lead to misuse.
- Suggest documenting the exact formatting guarantees (IEEE 754 compliance, shortest-roundtrip, special-value output) in the parent package or via comments in the interface generator, so downstream internal callers understand when to prefer this over other conversions.
