# Review: moonbitlang/core/test

**File:** `test/pkg.generated.mbti`  
**Date:** 2025-10-09T10:01:51.088Z  
**Status:** ✓ Success

---

- API still reads like a thin testing DSL, but the public surface mixes current and deprecated helpers, which makes it feel cluttered and harder to know what to use (`test/pkg.generated.mbti:5`, `:23`).
- `is_not` only bounds `Show`, yet it must compare two values; lacking `Eq` feels inconsistent with `eq`/`ne` and may hide type errors (`test/pkg.generated.mbti:17`).
- Free function `new` constructs `T` but is not namespaced as `T::new`, unlike the rest of the struct API, so discovery/composability suffers (`test/pkg.generated.mbti:27`).
- Snapshot helper requires both `loc` and `args_loc` autofill attributes, which is consistent, but `same_object` needlessly requires `Show` just to check identity (`test/pkg.generated.mbti:30`).
- Deprecated methods on `T` (e.g., `T::bench`) remain exposed; consider moving them to `deprecated.mbt` to align with the project convention (`test/pkg.generated.mbti:36`).

Suggestions:
1. Tighten trait bounds: add `Eq` to `is_not` (and drop `Show` from `same_object` if not needed).
2. Promote a `T::new` constructor (or alias) and discourage the free `new`.
3. Segregate deprecated helpers into `deprecated.mbt` so consumers see a cleaner core API.
