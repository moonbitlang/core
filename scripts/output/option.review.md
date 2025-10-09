# Review: moonbitlang/core/option

**File:** `option/pkg.generated.mbti`  
**Date:** 2025-10-09T10:00:13.802Z  
**Status:** ✓ Success

---

**API Assessment**  
- Overall mirrors familiar Option patterns: `map`, `bind`, `filter`, `iter`, and `unwrap_or*` cover common workflows without surprising signatures (`option/pkg.generated.mbti:12-34`).  
- Nullable + `raise?` annotations make error propagation explicit and consistent across combinators.

**Potential Issues**  
- `Option::or_error(T?, Err) -> T raise Err` forces eager construction of the error value even when the option is `some`; it can be expensive or stateful (`option/pkg.generated.mbti:31-32`).  
- Deprecations (`empty`, `some`, `or`, `or_else`, etc.) remain exposed in the interface and may confuse users about the preferred surface (`option/pkg.generated.mbti:9-29`).

**Suggestions**  
- Consider adding a lazy variant such as `or_error_else( () -> Err )` to defer error creation until it is actually needed.  
- Move or clearly document deprecated helpers in `deprecated.mbt` so downstream users know they are legacy and what to use instead.
