# Review: moonbitlang/core/int

**File:** `int/pkg.generated.mbti`  
**Date:** 2025-10-09T09:59:28.469Z  
**Status:** ✓ Success

---

**Findings**
- int/pkg.generated.mbti:13 `Int::abs` cannot represent `abs(min_value)` in a two’s-complement `Int`; the API doesn’t clarify whether it traps, saturates, or wraps, so callers can’t reason about safety.
- int/pkg.generated.mbti:14-15 `to_be_bytes` / `to_le_bytes` expose only one-way conversions and return an unsized `Bytes`; without documenting the fixed width or offering `from_*` counterparts, consumers risk endian or length mismatches.

**Open Questions**
- What is the expected behavior when `Int::abs` receives `min_value`? (panic vs. wrap vs. return `Int`?)

**Suggestions**
- Document or change `Int::abs` to make the `min_value` edge case explicit—e.g., return a result type or note a possible panic.
- Either document the byte-length contract of `to_{be,le}_bytes` or refactor toward a single `to_bytes(endian)` plus symmetric `from_*` helpers so callers can reliably round-trip integers.
