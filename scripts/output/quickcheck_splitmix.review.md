# Review: moonbitlang/core/quickcheck/splitmix

**File:** `quickcheck/splitmix/pkg.generated.mbti`  
**Date:** 2025-10-09T10:00:42.890Z  
**Status:** ✓ Success

---

**API Design**
- `quickcheck/splitmix/pkg.generated.mbti:5` Top-level `new(seed?)` plus `Default` give an easy entry point and optional seeding matches common PRNG APIs; method set covers ints/floats plus splitting.
- `quickcheck/splitmix/pkg.generated.mbti:11-23` Consistent receiver-taking-by-value style suggests `RandomState` is copy-on-write; `Show` impl aids debugging.

**Issues**
- `quickcheck/splitmix/pkg.generated.mbti:14` A method named `next` that returns `Unit` is surprising—callers expect a value; likely either misnamed (e.g. `advance`) or should return the generated number.
- `quickcheck/splitmix/pkg.generated.mbti:19` `next_positive_int` promises positivity yet returns `Int`; users may expect `UInt` or at least clarity on whether zero can appear.
- `quickcheck/splitmix/pkg.generated.mbti:20` `next_two_uint` returning a tuple while other methods return scalars is asymmetrical; unclear why a single-call pair is special but other paired outputs (e.g. doubles) are absent.
- `quickcheck/splitmix/pkg.generated.mbti:5` + `13` Redundant constructors: keeping the free `new` while deprecating the method leaves surface area confusion; consumers may wonder which to use and when the deprecated entry will disappear.

**Suggestions**
- `quickcheck/splitmix/pkg.generated.mbti:14` Either rename to `advance` (if it only steps state) or return the same type as `next_uint64`; document behavior.
- `quickcheck/splitmix/pkg.generated.mbti:19` Clarify contract (e.g. rename to `next_nonzero_int`/`next_positive_uint`) or adjust return type to `UInt`.
- `quickcheck/splitmix/pkg.generated.mbti:20` Consider exposing symmetric helpers (e.g. `next_uintN`, `next_double_pair`) or clarifying why this pair method exists; otherwise keep surface minimal.
- `quickcheck/splitmix/pkg.generated.mbti:13` Plan to remove the deprecated `RandomState::new` soon or provide migration notes so the API surface stays tidy.

Potential next step: add doc comments in the implementation package to explain the intent behind `next`, `next_positive_int`, and `next_two_uint`.
