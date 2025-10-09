# Review: moonbitlang/core/result

**File:** `result/pkg.generated.mbti`  
**Date:** 2025-10-09T10:01:15.965Z  
**Status:** ✓ Success

---

**API Review**
- Public surface is unsurprising for a `Result` monad: bind/flatten/map/map_err plus rich unwrap family cover most ergonomics, and Compare/Arbitrary impls align with common expectations.

**Findings**
- `result/pkg.generated.mbti:10` `err` and `result/pkg.generated.mbti:13` `ok` are deprecated without an obvious replacement exposed in this interface, so consumers may be left guessing about the preferred constructor path.
- `result/pkg.generated.mbti:28` `Result::or(Self[T, E], T) -> T` reuses a name that usually returns another `Result`; returning the plain `T` duplicates `unwrap_or` but with a misleading label. Same concern for `result/pkg.generated.mbti:29` `or_else`, which mirrors `unwrap_or_else` but drops the `raise?` capability.
- `result/pkg.generated.mbti:31` `unwrap` and `result/pkg.generated.mbti:32` `unwrap_err` lack a `raise` effect in the signature; if they can abort on `Err`, the type should advertise it for consistency with `unwrap_or_error`.

**Suggestions**
- Provide or document the modern constructors (e.g., new block with recommended `Result.ok`/`Result.err` replacements) so the deprecation path is clear.
- Consider renaming `Result::or`/`or_else` to something that conveys their `unwrap` semantics, or alternatively return `Self` to match conventional `or` behavior.
- If `unwrap`/`unwrap_err` can raise/panic, mark them with the proper `raise` effect; if they cannot, clarify their guarantees in documentation to reassure users.
