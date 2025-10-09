# Review: moonbitlang/core/math

**File:** `math/pkg.generated.mbti`  
**Date:** 2025-10-09T10:00:03.482Z  
**Status:** ✓ Success

---

**API Assessment**  
- `math/pkg.generated.mbti` exposes a familiar, C-style math surface with broad Double/Float coverage for transcendental operations, plus bigint utilities; the optional `#as_free_fn` markers and deprecation tags signal thoughtful migration paths.

**Issues**  
- `math/pkg.generated.mbti:80` `log10` and `math/pkg.generated.mbti:82` `log2` only accept `Double`, whereas neighboring APIs ship paired `Double`/`Float` variants; this asymmetry forces callers working in `Float` to promote values.  
- `math/pkg.generated.mbti:45`, `math/pkg.generated.mbti:64`, `math/pkg.generated.mbti:100`, `math/pkg.generated.mbti:123` expose `ceil`/`floor`/`round`/`trunc` only for `Double`, again breaking the otherwise consistent dual-precision story.  
- `math/pkg.generated.mbti:70` `is_probable_prime` accepts an optional `iters` but `math/pkg.generated.mbti:97` `probable_prime` does not let callers tune iterations; users needing deterministic control must reimplement logic.  
- The deprecation of `maximum`/`minimum` (`math/pkg.generated.mbti:85`, `math/pkg.generated.mbti:88`) points to replacements that are not visible in this interface, leaving unclear guidance for migrating callers.

**Suggestions**  
- Add `log10f`, `log2f`, and float versions of the rounding helpers to keep parity with the rest of the Float surface.  
- Either mirror the `iters? : Int` knob on `probable_prime` or document the default iteration strategy to avoid surprises in cryptographic contexts.  
- Surface recommended replacements for the deprecated `maximum`/`minimum` (and confirm whether `const PI` fully replaces `let pi`) so users have a clear migration path.
