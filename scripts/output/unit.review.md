# Review: moonbitlang/core/unit

**File:** `unit/pkg.generated.mbti`  
**Date:** 2025-10-09T10:01:59.141Z  
**Status:** ✓ Success

---

`unit/pkg.generated.mbti` looks cohesive for a standard unit type: `default()` plus `Unit::to_string`, and trait impls for `Compare`, `Default`, `Hash`.

Findings  
- `unit/pkg.generated.mbti:5` – Exposed free function `default()` duplicates `Default for Unit`; unless a historical alias is required, it’s unusual to keep both and risks diverging behavior if one changes.

Suggestions  
- If compatibility allows, consider deprecating the standalone `default()` and rely on `Default::default()` to keep the API minimal.

Residual risk: without implementations or usage we can’t confirm `default()` stays aligned with the trait impl, so worth double-checking tests or documentation.
