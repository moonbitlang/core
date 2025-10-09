# Review: moonbitlang/core/quickcheck

**File:** `quickcheck/pkg.generated.mbti`  
**Date:** 2025-10-09T10:00:34.571Z  
**Status:** ✓ Success

---

**API Notes**
- Minimal surface (`gen`, `samples`, `Arbitrary`) keeps usage straightforward while covering single-sample and bulk generation needs; default implementations for primitives give good out-of-the-box coverage (`quickcheck/pkg.generated.mbti:8`, `quickcheck/pkg.generated.mbti:10`, `quickcheck/pkg.generated.mbti:15`).

**Issues / Inconsistencies**
- `gen` accepts an optional RNG state, but `samples` does not, so bulk generation cannot be seeded/replayed in the same way (`quickcheck/pkg.generated.mbti:8`, `quickcheck/pkg.generated.mbti:10`).
- `Arbitrary` requires passing `@splitmix.RandomState`, leaking the internal RNG choice to every implementer; this couples third-party generators to the concrete engine and makes future RNG swaps breaking (`quickcheck/pkg.generated.mbti:15`).

**Improvements**
1. Add a seeded overload (or optional parameter) for `samples` so sampling and single generation share the same control surface.
2. Re-export `RandomState` or wrap it in a package-level type/trait so implementers are insulated from the concrete RNG and migrations stay source-compatible.
