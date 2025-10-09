# Review: moonbitlang/core/int64

**File:** `int64/pkg.generated.mbti`  
**Date:** 2025-10-09T09:59:28.848Z  
**Status:** ✓ Success

---

- Solid minimal surface covering creation, limits, byte conversion, and hashing for `Int64`; naming is consistent and discoverable (`to_be_bytes`/`to_le_bytes`), and exposing `min_value`/`max_value` as constants keeps usage straightforward.
- `Int64::abs` on `int64/pkg.generated.mbti` likely overflows on `min_value`; callers get no signal whether it panics, clamps, or wraps. `Int64::from_int` and free `from_int(Int)` also omit overflow semantics—unclear whether they trap, saturate, or truncate when the source `Int` exceeds the `Int64` range.
- Consider documenting or adjusting the behavior of `abs` and the two `from_int` entry points (e.g., returning an `Option`/`Result`, or naming them `checked_…`/`wrapping_…`). If both `from_int` variants remain, explain why the free function is needed alongside the inherent method. A `from_be_bytes`/`from_le_bytes` counterpart would make the byte-conversion story symmetrical.
