# Review: moonbitlang/core/bigint

**File:** `bigint/pkg.generated.mbti`  
**Date:** 2025-10-09T09:57:09.323Z  
**Status:** ✓ Success

---

**Assessment**
- Public surface offers comprehensive construction and conversion helpers plus standard arithmetic/bitwise traits, giving a predictable BigInt API (`bigint/pkg.generated.mbti:16`, `bigint/pkg.generated.mbti:22`, `bigint/pkg.generated.mbti:46`).

**Issues**
- Text/hex parsers return plain `Self`, so callers have no error channel for malformed input; that likely means hidden panics or sentinel values (`bigint/pkg.generated.mbti:22`, `bigint/pkg.generated.mbti:26`).
- Deprecation markers leave both `lsl` and `shl`/`shr` methods exported alongside the operator traits, which keeps legacy names visible and risks accidental reuse (`bigint/pkg.generated.mbti:30`, `bigint/pkg.generated.mbti:33`, `bigint/pkg.generated.mbti:35`, `bigint/pkg.generated.mbti:58`, `bigint/pkg.generated.mbti:60`).
- Comparison helpers exist for signed integers only, so unsigned callers must round-trip through `BigInt`, which is inconsistent with the provided `from_uint*` constructors (`bigint/pkg.generated.mbti:17`, `bigint/pkg.generated.mbti:28`, `bigint/pkg.generated.mbti:45`).

**Suggestions**
- Add fallible `Result`-returning variants (or document panic behavior) for string/hex parsing to make failure modes explicit (`bigint/pkg.generated.mbti:22`, `bigint/pkg.generated.mbti:26`).
- Move deprecated shift helpers into a dedicated `deprecated.mbt` (or hide them behind feature flags) to steer users toward the trait-based operators while still supporting legacy code (`bigint/pkg.generated.mbti:30`, `bigint/pkg.generated.mbti:33`, `bigint/pkg.generated.mbti:35`).
- Consider adding unsigned comparison helpers (e.g., `compare_uint`, `equal_uint`) for symmetry with existing constructors and to avoid wasteful conversions (`bigint/pkg.generated.mbti:27`, `bigint/pkg.generated.mbti:43`, `bigint/pkg.generated.mbti:45`).
