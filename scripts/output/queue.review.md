# Review: moonbitlang/core/queue

**File:** `queue/pkg.generated.mbti`  
**Date:** 2025-10-09T10:00:31.498Z  
**Status:** ✓ Success

---

**API Review**
- `queue/pkg.generated.mbti:23` and `queue/pkg.generated.mbti:24` expose `unsafe_peek` / `unsafe_pop` that behave like the deprecated `*_exn` variants but aren’t themselves deprecated; this prolongs the “panic-on-empty” path instead of steering users to the safe optional-returning API.
- `queue/pkg.generated.mbti:29` publishes `typealias Queue as T`, introducing a highly-generic exported name that’s easy to collide with in downstream code and obscures the actual type being used.

**Suggestions**
- (1) Either deprecate the `unsafe_*` helpers alongside `*_exn`, or document clearly why both sets exist; ideally keep just the option-returning accessors in the public surface.
- (2) Drop or rename the public alias `T`; if an alias is required, give it a descriptive name so downstream packages can reference the queue type explicitly.
