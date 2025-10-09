# Review: moonbitlang/core/string/regex/internal/regex_impl

**File:** `string/regex/internal/regex_impl/pkg.generated.mbti`  
**Date:** 2025-10-09T10:01:44.602Z  
**Status:** ✓ Success

---

**API Review**
- **Assessment**: Compact surface with a single constructor (`compile`) and a small `Regexp` method set (`string/regex/internal/regex_impl/pkg.generated.mbti:5`, `string/regex/internal/regex_impl/pkg.generated.mbti:44-50`). `MatchResult` helpers cover common queries (`before`, `after`, `groups`, `matched`) (`string/regex/internal/regex_impl/pkg.generated.mbti:36-41`), so the high-level flow feels complete.
- **Issues**: Publicly exposing the entire `MatchResult` struct makes internal bookkeeping (`captures`, `names`) part of the ABI (`string/regex/internal/regex_impl/pkg.generated.mbti:29-35`). Argument types mix `StringView` and `String`; `Regexp::group_by_name`/`group_names` return owning `String`, unlike the rest of the API (`string/regex/internal/regex_impl/pkg.generated.mbti:47-49`). `Regexp::execute` always returns a `MatchResult` even on failure, whereas `match_` is optional; the semantic distinction is unclear (`string/regex/internal/regex_impl/pkg.generated.mbti:44-50`). Deprecated `execute_with_remainder` lingers without a replacement path (`string/regex/internal/regex_impl/pkg.generated.mbti:46`).
- **Suggestions**: Consider keeping `MatchResult` internals private and exposing only accessor methods, so representation changes stay compatible. Standardize parameters and return types on `StringView` (or introduce a dedicated flag type) for consistency. Clarify or consolidate `execute` vs `match_`—perhaps have one return an option and document behavior—or provide naming that communicates their difference. If `execute_with_remainder` is obsolete, move it to your `deprecated.mbt` or document its successor to guide users.
