# Review: moonbitlang/core/tuple

**File:** `tuple/pkg.generated.mbti`  
**Date:** 2025-10-09T10:01:59.590Z  
**Status:** ✓ Success

---

**Findings**
- `tuple/pkg.generated.mbti:7-33` exposes only deprecated tuple helpers (`curry`, `map_*`, `pair`, `swap`, etc.), but there are no newer alternatives in the interface, so callers still rely on APIs that you intended to retire. Consider either removing them from the public surface or surfacing a recommended replacement before deprecating.
- `tuple/pkg.generated.mbti:36-66` implements `Default` for tuples of arity 2–16, yet `@quickcheck.Arbitrary` only exists up to arity 7. The mismatch makes tuple sizes ≥8 impossible to generate via QuickCheck even though `Default` supports them. If this is accidental, extend `Arbitrary`; if intentional, document the limit so users don’t assume broader coverage.

**Suggestions**
1. Decide whether to publish non-deprecated tuple helpers (or move the old ones into a `deprecated` package) so consumers know what to use instead.
2. Align trait coverage—either add `@quickcheck.Arbitrary` implementations through 16 elements or add notes explaining why arity 8+ are unsupported.
