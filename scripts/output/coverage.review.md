# Review: moonbitlang/core/coverage

**File:** `coverage/pkg.generated.mbti`  
**Date:** 2025-10-09T09:57:27.939Z  
**Status:** ✓ Success

---

**Assessment**
- Extremely small surface: global `end()` and `track()` plus `CoverageCounter` with `new`/`incr` and `Show`. Focused but opaque—callers get no insight into lifecycle or state beyond printing.

**Potential Issues**
- `CoverageCounter::incr(Self, Int)` consumes `Self`; if `Self` isn’t a lightweight handle, increments may act on a copy and lose state.
- `track(String, CoverageCounter) -> Unit` offers no return value or feedback; unclear whether it clones, mutates, or owns the counter.
- `end()` with no parameters/return value is ambiguous—unclear which counters or session it affects.
- No accessor to read a counter’s value; callers must rely on `Show`, which is unusual for programmatic use.
- Lack of docs makes sequencing (must `track` follow `new`? when to `end`?) and ownership rules unclear.

**Suggestions**
- Clarify parameter passing and mutability: accept counters by reference or provide docs guaranteeing value semantics.
- Consider returning status/data from `track` or exposing a `value()` accessor on `CoverageCounter`.
- Rename or document `end()` to make its scope explicit (e.g., `finalize_session()`).
- Provide minimal usage guidance in docs or through API naming to communicate lifecycle expectations.
