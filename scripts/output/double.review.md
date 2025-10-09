# Review: moonbitlang/core/double

**File:** `double/pkg.generated.mbti`  
**Date:** 2025-10-09T09:57:51.824Z  
**Status:** ✓ Success

---

**API Notes**
- Balanced coverage of constants and predicates: classification helpers (`is_nan`, `is_inf`, `signum`) and rounding utilities look coherent with the rest of the numeric core (`double/pkg.generated.mbti:21`–`double/pkg.generated.mbti:51`).
- Having both a package-level `from_int` and an associated `Double::from_int` is consistent with other MoonBit modules but feels redundant unless both entry points serve distinct ergonomics (`double/pkg.generated.mbti:5`, `double/pkg.generated.mbti:28`).

**Possible Issues**
- `Double::inf(Int)` remains exposed even while deprecated; the `Int` parameter is confusing alongside the constant `infinity`, and keeping it in the primary interface instead of a dedicated deprecated surface increases the chance of accidental use (`double/pkg.generated.mbti:29`–`double/pkg.generated.mbti:31`, `double/pkg.generated.mbti:7`).
- `Double::to_uint` is the sole lossy conversion back to integers; without `to_int` or a fallible variant, it is unclear how negative values or large magnitudes are handled, which could surprise API users (`double/pkg.generated.mbti:49`).
- Optional arguments on `Double::is_close` lack documented defaults in the interface, so callers cannot infer what happens when they omit tolerances (`double/pkg.generated.mbti:32`).

**Suggestions**
1. Either move deprecated members such as `Double::inf`, `Double::min_normal`, and `Double::nan` into a dedicated `deprecated.mbt` or document clearly why they must stay in the main interface.
2. Clarify or complement `Double::to_uint` with a documented contract (clamping, truncation, errors) and consider adding a signed counterpart for symmetry.
3. Document the default tolerances for `Double::is_close` (or surface overloads without optionals) so users know the comparison policy without digging into the implementation.
